# Load libraries
library(dplyr)
library(tidyverse)
library(lubridate)
library(quantmod)
library(tidyr)
library(ggplot2)
library(scales)
library(gt)
library(stringdist)

# Set working directory and load professional theme
source("visualization_theme.R")

# Ensure organized output folders exist
dir.create("Graphs/R_Plots_PDF", recursive = TRUE, showWarnings = FALSE)
dir.create("Data_Outputs/CSV", recursive = TRUE, showWarnings = FALSE)

# Now read files
new_vehicles <- read_csv("../Raw_Datasets/monthly_new_vehicle_registration_may2023_2026.csv")
transfer_vehicles <- read_csv("../Raw_Datasets/monthly_vehicle_transfers_may2023_2026.csv")
make_mapping <- read_csv("../Raw_Datasets/complete_vehicle_mapping.csv")

# Transfer file uses different column names than the new-vehicle file
# (CD_MAKE_VEH1/TOTAL1/month_year vs CD_MAKE_VEH/TOTAL/data_month_year).
# Rename here so the shared clean_and_standardize() function below works for both.
transfer_vehicles <- transfer_vehicles %>%
  rename(
    CD_MAKE_VEH = CD_MAKE_VEH1,
    TOTAL = TOTAL1,
    data_month_year = month_year
  )

# Data cleaning & Standardlization 
clean_and_standardize <- function(data, make_mapping) {
  data %>%
    # Fix dates - make time based calculations possible by converting all dates into YYYY-MM-DD format
    mutate(data_month_year = as.Date(paste0(data_month_year, "01"), format = "%Y%m%d")) %>%
    
    # Standardize raw vehicle codes to catch more matches
    mutate(
      CD_MAKE_VEH_raw = CD_MAKE_VEH,  # Keep original for reference
      CD_MAKE_VEH = CD_MAKE_VEH %>%
        str_squish() %>%               # Remove extra spaces
        str_to_upper() %>%             # Convert to uppercase
        str_remove_all("[^A-Z0-9 ]")   # Remove special characters
    ) %>%
    
    # Join with make mapping
    left_join( # keep all records even if no match found 
      make_mapping %>% select(CD_MAKE_VEH, CD_MAKE_VEH_CLEAN, Category),
      by = "CD_MAKE_VEH"
    ) %>%
    
    # Use cleaned name, fallback to original if no match
    mutate(
      make_standard = coalesce(CD_MAKE_VEH_CLEAN, CD_MAKE_VEH),
      Category = coalesce(Category, "Unknown")
    ) %>% # unknown categories default to "Unknown"
    
    # Standardize text
    mutate(
      make_clean = make_standard %>% str_to_upper() %>% str_squish(),
      model_clean = CD_MODEL_VEH %>% str_to_upper() %>% str_squish(),
      colour_clean = CD_CLR_BDY_VEH_P %>% str_to_upper() %>% str_squish()
    ) %>%
    
    # Remove formatting errors in models
    mutate(
      model_clean = model_clean %>%
        str_remove_all("^[^A-Z0-9]+") %>% # remove leading non-alphanumeric
        str_remove_all("[^A-Z0-9]+$") # remove trailling non-alphanumeric 
    ) %>%
    
    # Extract year and month - for easy aggregation 
    mutate(
      transfer_year = year(data_month_year),
      transfer_month = month(data_month_year) # useful for trend analysis 
    ) %>% 
    
    select(CD_MAKE_VEH_raw, CD_MAKE_VEH, make_standard, Category, CD_MODEL_VEH, model_clean, 
           CD_CLR_BDY_VEH_P, colour_clean, NB_YEAR_MFC_VEH, 
           data_month_year, transfer_year, transfer_month, TOTAL, everything())
}

# Apply cleaning
new_clean <- clean_and_standardize(new_vehicles, make_mapping)
transfer_clean <- clean_and_standardize(transfer_vehicles, make_mapping)


# Detect unmatched codes & Apply fuzzy matching 
# Find unmatched makes in transfers
unmatched_transfer_codes <- transfer_clean %>% 
  filter(is.na(CD_MAKE_VEH_CLEAN)) %>% 
  distinct(CD_MAKE_VEH) %>%
  arrange(CD_MAKE_VEH)

unmatched_transfer_count <- nrow(unmatched_transfer_codes)

# Find unmatched makes in new vehicles
unmatched_new_codes <- new_clean %>% 
  filter(is.na(CD_MAKE_VEH_CLEAN)) %>% 
  distinct(CD_MAKE_VEH) %>%
  arrange(CD_MAKE_VEH)

unmatched_new_count <- nrow(unmatched_new_codes)

print(paste("Unmatched codes in transfers:", unmatched_transfer_count))
print(paste("Unmatched codes in new vehicles:", unmatched_new_count))

# Show unmatched codes if any
if (unmatched_transfer_count > 0) {
  print("Unmatched transfer codes:")
  print(unmatched_transfer_codes)
  
  affected_records <- transfer_clean %>%
    semi_join(unmatched_transfer_codes, by = "CD_MAKE_VEH") %>%
    nrow()
  print(paste("Records affected:", affected_records))
}

# Below section (fuzzy matching algorithm) aim to handle codes that don't exist in the mapping table (reference: Claude AI, Haiku 4.5)
# ============ FUZZY MATCHING FOR REMAINING UNKNOWNS ============ 
if (unmatched_transfer_count > 0) {
  print("\nApplying fuzzy matching...")
  
  # Get known makes from mapping
  known_makes <- make_mapping %>% 
    distinct(CD_MAKE_VEH) %>% 
    pull(CD_MAKE_VEH)
  
  # Find closest matches for each unmatched code
  fuzzy_matches <- tibble(
    unmatched_code = unmatched_transfer_codes$CD_MAKE_VEH
  ) %>%
    mutate(
      # Find the closest matching known make
      matched_make = map_chr(unmatched_code, 
                             ~known_makes[which.min(stringdist(., known_makes))]), # calculate the Levenshtein distance & find the closest match 
      # Calculate similarity (0-1)
      similarity_score = map_dbl(unmatched_code,
                                 ~1 - (min(stringdist(., known_makes)) / max(nchar(.), nchar(known_makes)))) # normalise to 0-1 range
    ) %>%
    filter(similarity_score > 0.7)  # Only high confidence matches (using 0.7 as the threshold)
  
  if (nrow(fuzzy_matches) > 0) {
    print("Fuzzy matches found:")
    print(fuzzy_matches)
    
    # Create supplementary mapping
    fuzzy_mapping <- fuzzy_matches %>%
      select(unmatched_code, matched_make) %>%
      left_join(
        make_mapping %>% select(CD_MAKE_VEH, CD_MAKE_VEH_CLEAN),
        by = c("matched_make" = "CD_MAKE_VEH")
      ) %>%
      rename(CD_MAKE_VEH = unmatched_code)
    
    # Apply to transfer data
    transfer_clean <- transfer_clean %>%
      left_join(fuzzy_mapping %>% select(CD_MAKE_VEH, CD_MAKE_VEH_CLEAN), 
                by = "CD_MAKE_VEH", suffix = c("", "_fuzzy")) %>%
      mutate(
        CD_MAKE_VEH_CLEAN = coalesce(CD_MAKE_VEH_CLEAN, CD_MAKE_VEH_CLEAN_fuzzy),
        make_standard = coalesce(CD_MAKE_VEH_CLEAN, CD_MAKE_VEH)
      ) %>%
      select(-CD_MAKE_VEH_CLEAN_fuzzy)
    
    print("✓ Fuzzy matches applied to transfers")
  } else {
    print("No high-confidence fuzzy matches found (< 0.7 threshold)")
  }
}

# Same for new vehicles
if (unmatched_new_count > 0) {
  print("\nApplying fuzzy matching to new vehicles...")
  
  known_makes <- make_mapping %>% 
    distinct(CD_MAKE_VEH) %>% 
    pull(CD_MAKE_VEH)
  
  fuzzy_matches_new <- tibble(
    unmatched_code = unmatched_new_codes$CD_MAKE_VEH
  ) %>%
    mutate(
      matched_make = map_chr(unmatched_code, 
                             ~known_makes[which.min(stringdist(., known_makes))]),
      similarity_score = map_dbl(unmatched_code,
                                 ~1 - (min(stringdist(., known_makes)) / max(nchar(.), nchar(known_makes))))
    ) %>%
    filter(similarity_score > 0.7)
  
  if (nrow(fuzzy_matches_new) > 0) {
    fuzzy_mapping_new <- fuzzy_matches_new %>%
      select(unmatched_code, matched_make) %>%
      left_join(
        make_mapping %>% select(CD_MAKE_VEH, CD_MAKE_VEH_CLEAN),
        by = c("matched_make" = "CD_MAKE_VEH")
      ) %>%
      rename(CD_MAKE_VEH = unmatched_code)
    
    new_clean <- new_clean %>%
      left_join(fuzzy_mapping_new %>% select(CD_MAKE_VEH, CD_MAKE_VEH_CLEAN), 
                by = "CD_MAKE_VEH", suffix = c("", "_fuzzy")) %>%
      mutate(
        CD_MAKE_VEH_CLEAN = coalesce(CD_MAKE_VEH_CLEAN, CD_MAKE_VEH_CLEAN_fuzzy),
        make_standard = coalesce(CD_MAKE_VEH_CLEAN, CD_MAKE_VEH)
      ) %>%
      select(-CD_MAKE_VEH_CLEAN_fuzzy)
    
    print("✓ Fuzzy matches applied to new vehicles")
  }
}

# Final check
final_unmatched_transfer <- transfer_clean %>% 
  filter(is.na(CD_MAKE_VEH_CLEAN)) %>% 
  n_distinct(.$CD_MAKE_VEH)

final_unmatched_new <- new_clean %>% 
  filter(is.na(CD_MAKE_VEH_CLEAN)) %>% 
  n_distinct(.$CD_MAKE_VEH)

print(paste("\nFinal unmatched in transfers:", final_unmatched_transfer))
print(paste("Final unmatched in new vehicles:", final_unmatched_new))
# ============================================================================

# Filter & Engineer features 
# Keep only vehicles from 2010 onwards
transfer_clean <- transfer_clean %>%
  filter(NB_YEAR_MFC_VEH >= 2010)

# Remove NA models and empty strings
transfer_clean <- transfer_clean %>%
  filter(
    !is.na(model_clean),
    str_squish(model_clean) != ""
  )

new_clean <- new_clean %>%
  filter(
    !is.na(model_clean),
    str_squish(model_clean) != ""
  )

# Calculate market share and filter to top 95%
make_volume_transfer <- transfer_clean %>%
  group_by(make_standard) %>%
  summarise(total_transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(total_transfers)) %>%
  mutate(
    market_share = total_transfers / sum(total_transfers),
    cumulative_share = cumsum(market_share)
  )

top_makes_95_transfer <- make_volume_transfer %>%
  filter(lag(cumulative_share, default = 0) < 0.95) %>%
  pull(make_standard)

transfer_top_makes <- transfer_clean %>%
  filter(make_standard %in% top_makes_95_transfer)

# Same for new vehicles
make_volume_new <- new_clean %>%
  group_by(make_standard) %>%
  summarise(total_transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(total_transfers)) %>%
  mutate(
    market_share = total_transfers / sum(total_transfers),
    cumulative_share = cumsum(market_share)
  )

top_makes_95_new <- make_volume_new %>%
  filter(lag(cumulative_share, default = 0) < 0.95) %>%
  pull(make_standard)

new_top_makes <- new_clean %>%
  filter(make_standard %in% top_makes_95_new)


# Feature Engineering - Vehicle Age
transfer_top_makes <- transfer_top_makes %>%
  mutate(
    vehicle_age = transfer_year - NB_YEAR_MFC_VEH,
    age_bucket = case_when(
      vehicle_age <= 2 ~ "0-2 years",
      vehicle_age <= 6 ~ "3-6 years",
      vehicle_age <= 9 ~ "7-9 years",
      vehicle_age <= 12 ~ "10-12 years",
      vehicle_age <= 16 ~ "13-16 years",
      TRUE ~ NA_character_
    ),
    age_bucket = factor(age_bucket, 
                        levels = c("0-2 years", "3-6 years", "7-9 years", 
                                   "10-12 years", "13-16 years"))
  )

# Analysis - Market Activity 
# Monthly transfer volume
used_monthly <- transfer_top_makes %>%
  group_by(data_month_year) %>%
  summarise(transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop")

# Top 15 makes by total transfers
top_makes <- transfer_top_makes %>%
  group_by(make_standard) %>%
  summarise(transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(transfers)) %>%
  slice_head(n = 15)

# Top 20 models
top_models <- transfer_top_makes %>%
  group_by(make_standard, model_clean) %>%
  summarise(transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(transfers)) %>%
  slice_head(n = 20) %>%
  mutate(vehicle = paste(make_standard, model_clean))


# Analysis - Growth & Trends 
# Year-over-year for new registrations
new_yearly <- new_top_makes %>%
  group_by(make_standard, model_clean, transfer_year) %>%
  summarise(registrations = sum(TOTAL, na.rm = TRUE), .groups = "drop") %>%
  group_by(make_standard, model_clean) %>%
  mutate(
    growth = (registrations - lag(registrations)) / lag(registrations) * 100
  ) %>%
  ungroup()

# Recent activity (last 12 months)
latest_date <- max(transfer_top_makes$data_month_year)

recent_12 <- transfer_top_makes %>%
  filter(data_month_year > latest_date %m-% months(12)) %>%
  group_by(make_standard, model_clean) %>%
  summarise(recent_transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop")

previous_12 <- transfer_top_makes %>%
  filter(
    data_month_year > latest_date %m-% months(24),
    data_month_year <= latest_date %m-% months(12)
  ) %>%
  group_by(make_standard, model_clean) %>%
  summarise(previous_transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop")

# Growth analysis
model_growth <- recent_12 %>%
  left_join(previous_12, by = c("make_standard", "model_clean")) %>%
  mutate(
    growth = (recent_transfers - previous_transfers) / previous_transfers * 100,
    vehicle = paste(make_standard, model_clean)
  ) %>%
  filter(!is.na(growth), previous_transfers > 0)


# =========================================================
# VISUALIZATION - REFACTORED WITH CONSISTENT BLUE THEME
# =========================================================

# 1. Monthly transfer volume trend (Time Series)
monthly_transfers_plot <- used_monthly %>%
  plot_time_series(
    x_var = data_month_year,
    y_var = transfers,
    title = "Monthly Used Vehicle Transfers",
    subtitle = "Top 95% makes, vehicles manufactured 2010+"
  )

export_plot(monthly_transfers_plot, "Graphs/R_Plots_PDF/01_monthly_transfers.pdf", width = 10, height = 6)

# 2. Top 15 makes (Horizontal Bar Chart)
top_makes_plot <- top_makes %>%
  plot_horizontal_bars(
    x_var = make_standard,
    y_var = transfers,
    fill_var = transfers,
    title = "Top 15 Vehicle Makes by Transfers",
    subtitle = "Total transfers volume",
    n_top = 15
  )

export_plot(top_makes_plot, "Graphs/R_Plots_PDF/02_top_makes.pdf", width = 10, height = 7)

# 3. Top 20 models (Horizontal Bar Chart)
top_models_plot <- top_models %>%
  plot_horizontal_bars(
    x_var = vehicle,
    y_var = transfers,
    fill_var = transfers,
    title = "Top 20 Vehicle Models by Transfers",
    subtitle = "Total transfers volume",
    n_top = 20
  )

export_plot(top_models_plot, "Graphs/R_Plots_PDF/03_top_models.pdf", width = 10, height = 9)

# 4. Top 5 models trends over time (Time Series with Groups)
top_5_models <- transfer_top_makes %>%
  group_by(make_standard, model_clean) %>%
  summarise(transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(transfers)) %>%
  slice_head(n = 5) %>%
  mutate(vehicle = paste(make_standard, model_clean)) %>%
  pull(vehicle)

model_trends <- transfer_top_makes %>%
  mutate(vehicle = paste(make_standard, model_clean)) %>%
  filter(vehicle %in% top_5_models) %>%
  group_by(data_month_year, vehicle) %>%
  summarise(transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop")

top_5_plot <- model_trends %>%
  plot_time_series(
    x_var = data_month_year,
    y_var = transfers,
    group_var = vehicle,
    title = "Transfer Trends - Top 5 Models",
    subtitle = "Monthly transfers by vehicle model"
  )

export_plot(top_5_plot, "Graphs/R_Plots_PDF/04_top_5_trends.pdf", width = 11, height = 6)

# 5. Growth vs popularity (Scatter Plot)
growth_plot <- model_growth %>%
  plot_scatter(
    x_var = previous_transfers,
    y_var = growth,
    color_var = recent_transfers,
    title = "Growth vs Popularity",
    subtitle = "Models with high activity + growth = opportunity"
  )

export_plot(growth_plot, "Graphs/R_Plots_PDF/05_growth_vs_popularity.pdf", width = 10, height = 7)

# 6. Vehicle age distribution (Distribution Plot)
age_distribution <- transfer_top_makes %>%
  group_by(age_bucket) %>%
  summarise(transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop")

age_dist_plot <- age_distribution %>%
  ggplot(aes(x = age_bucket, y = transfers)) +
  geom_col(fill = blue_palette$primary, width = 0.7) +
  labs(
    title = "Used-Vehicle Transfers by Age",
    subtitle = "Distribution across vehicle age buckets",
    x = "Vehicle age",
    y = "Transfers"
  ) +
  scale_y_continuous(labels = comma) +
  theme_report(grid_type = "y")

export_plot(age_dist_plot, "Graphs/R_Plots_PDF/06_age_distribution.pdf", width = 10, height = 6)

# 7. Age profile by major makes (Stacked Bar Chart)
top_makes_list <- top_makes %>% pull(make_standard)

age_by_make <- transfer_top_makes %>%
  filter(make_standard %in% top_makes_list) %>%
  group_by(make_standard, age_bucket) %>%
  summarise(transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop") %>%
  group_by(make_standard) %>%
  mutate(percentage = transfers / sum(transfers) * 100) %>%
  ungroup()

age_by_make_plot <- age_by_make %>%
  ggplot(aes(x = reorder(make_standard, percentage), y = percentage, fill = age_bucket)) +
  geom_col(position = "stack", width = 0.7) +
  coord_flip() +
  scale_fill_manual(
    name = "Vehicle Age",
    values = c(
      "0-2 years" = blue_palette$primary,
      "3-6 years" = blue_palette$secondary,
      "7-9 years" = blue_palette$highlight,
      "10-12 years" = blue_palette$accent,
      "13-16 years" = blue_palette$light_bg
    )
  ) +
  labs(
    title = "Vehicle Age Distribution by Make",
    subtitle = "Top 15 makes - age composition of transfers",
    x = NULL,
    y = "Share of transfers (%)",
    fill = "Vehicle Age"
  ) +
  theme_report(grid_type = "x", legend_pos = "bottom")

export_plot(age_by_make_plot, "Graphs/R_Plots_PDF/07_age_by_make.pdf", width = 11, height = 8)

# 8. New vehicle registrations trend (Time Series)
new_monthly <- new_top_makes %>%
  group_by(data_month_year) %>%
  summarise(registrations = sum(TOTAL, na.rm = TRUE), .groups = "drop")

new_reg_plot <- new_monthly %>%
  plot_time_series(
    x_var = data_month_year,
    y_var = registrations,
    title = "Monthly New Vehicle Registrations",
    subtitle = "Top 95% makes"
  )

export_plot(new_reg_plot, "Graphs/R_Plots_PDF/08_new_registrations.pdf", width = 10, height = 6)

# =========================================================
# SUMMARY REPORTS 
# =========================================================

# Market share summary - transfers
transfer_summary <- transfer_top_makes %>%
  group_by(make_standard) %>%
  summarise(
    total_transfers = sum(TOTAL, na.rm = TRUE),
    avg_age = mean(vehicle_age, na.rm = TRUE),
    models = n_distinct(model_clean),
    .groups = "drop"
  ) %>%
  arrange(desc(total_transfers)) %>%
  mutate(market_share_pct = round(total_transfers / sum(total_transfers) * 100, 2))

print("\nTransfer Market Summary (Top 20):")
print(head(transfer_summary, 20))

# New vehicle summary
new_summary <- new_top_makes %>%
  group_by(make_standard) %>%
  summarise(
    total_registrations = sum(TOTAL, na.rm = TRUE),
    models = n_distinct(model_clean),
    .groups = "drop"
  ) %>%
  arrange(desc(total_registrations)) %>%
  mutate(market_share_pct = round(total_registrations / sum(total_registrations) * 100, 2))

print("\nNew Vehicle Summary (Top 20):")
print(head(new_summary, 20))

# Save key datasets
write_csv(transfer_summary, "Data_Outputs/CSV/01_transfer_make_summary.csv")
write_csv(new_summary, "Data_Outputs/CSV/02_new_vehicle_summary.csv")
write_csv(model_growth, "Data_Outputs/CSV/03_model_growth_analysis.csv")
write_csv(new_yearly, "Data_Outputs/CSV/04_new_registrations_yearly.csv")
write_csv(top_models, "Data_Outputs/CSV/05_top_20_models.csv")

print("\n✓ All visualizations complete and saved with consistent blue theme")
