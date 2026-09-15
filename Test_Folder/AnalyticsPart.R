library(dplyr)
library(tidyverse)
library(lubridate)
library(ggplot2)
library(scales)

print("Loading cleaned data with standardized makes...")
new_vehicles <- read_csv("outputs/CSVs/registrations_cleaned_records.csv")
transfer_vehicles <- read_csv("outputs/CSVs/transfers_cleaned_records.csv")

print(paste("Transfers:", nrow(transfer_vehicles), "records"))
print("Data source: CLEANED with fuzzy-matched makes")

transfer_vehicles_2010 <- transfer_vehicles %>%
  filter(NB_YEAR_MFC_VEH >= 2010)

new_clean <- new_vehicles
transfer_clean <- transfer_vehicles_2010

transfer_clean <- transfer_clean %>%
  mutate(
    model_clean = CD_MODEL_VEH %>% str_to_upper() %>% str_squish() %>%
      str_remove_all("^[^A-Z0-9]+") %>% str_remove_all("[^A-Z0-9]+$"),
    colour_clean = CD_CLR_BDY_VEH_P %>% str_to_upper() %>% str_squish()
  )

new_clean <- new_clean %>%
  mutate(
    model_clean = CD_MODEL_VEH %>% str_to_upper() %>% str_squish() %>%
      str_remove_all("^[^A-Z0-9]+") %>% str_remove_all("[^A-Z0-9]+$"),
    colour_clean = CD_CLR_BDY_VEH_P %>% str_to_upper() %>% str_squish()
  )

make_volume_transfer <- transfer_clean %>%
  group_by(make_standard) %>%
  summarise(total_transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(total_transfers)) %>%
  mutate(market_share = round(total_transfers / sum(total_transfers), 5),
         cumulative_share = cumsum(market_share))

top_makes_95 <- make_volume_transfer %>%
  filter(lag(cumulative_share, default = 0) < 0.95)

transfer_top_makes <- transfer_clean %>%
  semi_join(top_makes_95, by = "make_standard") %>%
  filter(!is.na(model_clean), str_squish(model_clean) != "") %>%
  mutate(transfer_year = year(data_month_year), transfer_month = month(data_month_year),
         vehicle_age = transfer_year - NB_YEAR_MFC_VEH,
         age_bucket = case_when(
           vehicle_age <= 2 ~ "0-2 years", vehicle_age <= 6 ~ "3-6 years",
           vehicle_age <= 9 ~ "7-9 years", vehicle_age <= 12 ~ "10-12 years",
           vehicle_age <= 16 ~ "13-16 years", TRUE ~ NA_character_
         ),
         age_bucket = factor(age_bucket, levels = c("0-2 years", "3-6 years", "7-9 years", "10-12 years", "13-16 years")))

used_monthly <- transfer_top_makes %>%
  group_by(data_month_year) %>%
  summarise(transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop")

ggplot(used_monthly, aes(x = data_month_year, y = transfers)) +
  geom_line(linewidth = 1) +
  labs(title = "Monthly Victorian Used-Vehicle Transfers (CLEANED DATA)",
       x = NULL, y = "Number of transfers") +
  scale_y_continuous(labels = comma) + theme_minimal()

top_makes <- transfer_top_makes %>%
  group_by(make_standard) %>%
  summarise(transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(transfers)) %>% slice_head(n = 15)

ggplot(top_makes, aes(x = reorder(make_standard, transfers), y = transfers)) +
  geom_col() + coord_flip() +
  labs(title = "Top 15 Vehicle Makes (CLEANED DATA)", x = NULL, y = "Total transfers") +
  scale_y_continuous(labels = comma) + theme_minimal()

print("ANALYSIS COMPLETE - Using cleaned data with standardized makes")
