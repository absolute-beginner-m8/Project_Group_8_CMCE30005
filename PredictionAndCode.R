library(dplyr)
library(tidyverse)
library(lubridate)
library(quantmod)
library(tidyr)
library(ggplot2)
library(scales)
library(gt)
library(stringr)

# Import Data
new_vehicles <- read_csv("monthly_new.csv")
transfer_vehicles <- read_csv("monthly_transfers.csv")

# View a breakdown of the vehicles 
type_vehicles <- new_vehicles %>%
  count(CD_MAKE_VEH, sort = TRUE)

# View a breakdown of the model 
model_type <- new_vehicles %>%
  count(CD_MODEL_VEH, sort = TRUE)

# View a breakdown of the vehicle -- transfer market
tranfer_amount <- transfer_vehicles %>%
  count(CD_MAKE_VEH1, sort = TRUE)


## Clean up the data 


# Fix the dates in new vehicles
new_vehicles <- new_vehicles %>% 
  mutate(data_month_year = as.Date(paste0(data_month_year, "01"), format = "%Y%m%d"))

# Fix dates in the transfer 
transfer_vehicles <- transfer_vehicles %>% 
  mutate(month_year = as.Date(paste0(month_year, "01"), format = "%Y%m%d"))


# Lets see all the different types of colours -- new vehicles
new_vehicles %>% 
  count(CD_CLR_BDY_VEH_P, sort = TRUE) %>% 
  print(n = Inf)

# Lets see all the different types of colours -- transfer vehicles
transfer_vehicles %>% 
  count(CD_CLR_BDY_VEH_P, sort = TRUE) %>% 
  print(n = Inf)

transfer_vehicles <- transfer_vehicles %>% 
  drop_na(CD_CLR_BDY_VEH_P)

transfer_vehicles %>% 
  count(CD_CLR_BDY_VEH_P, sort = TRUE) %>% 
  print(n = Inf)

# All the colours line up 

# Lets see all the different years -- new vehicles 
new_vehicles %>% 
  count(NB_YEAR_MFC_VEH, sort = TRUE) %>% 
  print(n = Inf)

# Lets see all the different years -- transfer vehicles 
transfer_vehicles %>% 
  count(NB_YEAR_MFC_VEH) %>% 
  print(n = Inf)

## We have dates very early on -- how many cars do we have left if we cut off the date
transfer_vehicles %>% 
  filter(NB_YEAR_MFC_VEH > 2000) %>% 
  summarise(NB_YEAR_MFC_VEH = n()) ## We have 977,855

transfer_vehicles %>% 
  filter(NB_YEAR_MFC_VEH > 2010) %>% 
  summarise(NB_YEAR_MFC_VEH = n())



## Want to only see cars from the last 15 years
transfer_vehicles_2010 <- transfer_vehicles %>%
  filter(NB_YEAR_MFC_VEH >= 2010) 

# So now how many NA values do we get for model 
transfer_vehicles_2010 %>% 
  summarise(na_count = sum(is.na(CD_MODEL_VEH))) ## 4159 -- better than 8425

grouped_transfer <- transfer_vehicles_2010 %>% 
  group_by(CD_MODEL_VEH, CD_MAKE_VEH1) %>% 
  summarise(count = n())


## What if we only use the top 20 makes 
top_20_makes <- transfer_vehicles %>% 
  filter(NB_YEAR_MFC_VEH >= 2010) %>% 
  count(CD_MAKE_VEH1, sort = TRUE) %>% 
  slice_head(n = 30)

top_20_data <- transfer_vehicles %>% 
  filter(CD_MAKE_VEH1 %in% top_20_makes$CD_MAKE_VEH1, 
         NB_YEAR_MFC_VEH >= 2010)


## Starting to clean the data

# Rename variables for new 
new_clean <- new_vehicles
transfer_clean <- transfer_vehicles_2010


# Understand and view the data
names(new_clean)
names(transfer_clean)

str(new_clean)
str(transfer_clean)

summary(new_clean)
summary(transfer_clean)

# Number of unique values 
n_distinct(new_clean$CD_MAKE_VEH)
n_distinct(new_clean$CD_MODEL_VEH)
n_distinct(new_clean$CD_CLR_BDY_VEH_P)

n_distinct(transfer_clean$CD_MAKE_VEH1)
n_distinct(transfer_clean$CD_MODEL_VEH)
n_distinct(transfer_clean$CD_CLR_BDY_VEH_P)


## Standardise text for new 
new_clean <- new_clean %>%
  mutate(
    make_clean = CD_MAKE_VEH %>%
      str_to_upper() %>%
      str_squish(),
    
    model_clean = CD_MODEL_VEH %>%
      str_to_upper() %>%
      str_squish(),
    
    colour_clean = CD_CLR_BDY_VEH_P %>%
      str_to_upper() %>%
      str_squish()
  )

## Standardise text for transfers
transfer_clean <- transfer_clean %>%
  mutate(
    make_clean = CD_MAKE_VEH1 %>%
      str_to_upper() %>%
      str_squish(),
    
    model_clean = CD_MODEL_VEH %>%
      str_to_upper() %>%
      str_squish(),
    
    colour_clean = CD_CLR_BDY_VEH_P %>%
      str_to_upper() %>%
      str_squish()
  )

## Standardise text for colour 
new_clean <- new_clean %>%
  mutate(
    colour_clean = CD_CLR_BDY_VEH_P %>%
      str_to_upper() %>%
      str_squish()
  )

transfer_clean <- transfer_clean %>%
  mutate(
    colour_clean = CD_CLR_BDY_VEH_P %>%
      str_to_upper() %>%
      str_squish()
  )

# Finding messy data 
new_clean %>%
  count(make_clean, sort = TRUE) %>% 
  print(n = Inf)

transfer_clean %>%
  count(make_clean, sort = TRUE) %>% 
  print(n = Inf)

## Remove obvious formatting errors 
new_clean <- new_clean %>%
  mutate(
    model_clean = model_clean %>%
      str_remove_all("^[^A-Z0-9]+") %>%
      str_remove_all("[^A-Z0-9]+$")
  )


transfer_clean <- transfer_clean %>%
  mutate(
    model_clean = model_clean %>%
      str_remove_all("^[^A-Z0-9]+") %>%
      str_remove_all("[^A-Z0-9]+$")
  )

# Observe the data 
new_clean %>%
  count(make_clean, sort = TRUE) %>% 
  print(n = Inf)

transfer_clean %>%
  count(make_clean, sort = TRUE) %>% 
  print(n = Inf)

new_clean %>% 
  filter(make_clean == "")


##### Important -- mapping table of any errors 
make_map <- tribble(
  ~make_clean,      ~make_standard,
  "B M W", "BMW",
  "MERC B", "MERCEDES-BENZ",
  "M G", "MG",
  "HYNDAI", "HYUNDAI",
  "VOLKS", "VOLKSWAGEN",
  "MITSUB", "MITSUBISHI",
  "G WALL", "GWM",
  "KAWASA", "KAWASAKI",
  "PORSCH", "PORSCHE",
  "H DAV", "HARLEY-DAVIDSON",
  "B Y D", "BYD",
  "K T M", "KTM",
  "L ROV", "LAND ROVER",
  "REN", "RENAULT",
  "KENWTH", "KENWORTH",
  "TRIUM", "TRIUMPH",
  "PEUG", "PEUGEOT",
  "J DEER", "JOHN DEERE",
  "POLEST", "POLESTAR",
  "ALFA R", "ALFA ROMEO",
  "R ROV", "LAND ROVER",
  "FERRAR", "FERRARI",
  "ASTON", "ASTON MARTIN",
  "G M C", "GMC",
  "KTM", "KTM",
  "LAMB G", "LAMBORGHINI",
  "LAMBR", "LAMBORGHINI",
  "MC LRN", "MCLAREN",
  "PISTA", "FERRARI",
  "S W M", "SWM",
  "E VOLV", "VOLVO",
  "B M C", "GMC",
  "LUIGON", "LIUGONG",
  "GMSV", "GM",
  "CHRYS", "CHRYSLER",
  "BENZNA", "MERCEDES-BENZ",
  "LIUGON", "LIUGONG",
  "LIUGNG", "LIUGONG",
  "BUICK", "BUICK",
  "GOLDEN", "HOLDEN",
  "GWM", "GWM",
  "IKONIC", "HYUNDAI",
  "INFNTI", "INFINITI",
  "J C B", "JCB",
  "MUSTNG", "FORD",
  "G WELL", "GWM",
  "MAYBAC", "MERCEDES-BENZ",
  "ALPINA", "BMW",
  "SWIFT", "SUZUKI",
  "LANCER", "MITSUBISHI",
  "GOLDON", "HOLDEN",
  "DATSUN", "NISSAN",
  "CHLNGER", "DODGE"
  
  
  
)

new_clean <- new_clean %>%
  left_join(make_map, by = "make_clean")

transfer_clean <- transfer_clean %>%
  left_join(make_map, by = "make_clean")


# And now we need to change the NA values that weren't mapped 
new_clean <- new_clean %>%
  mutate(
    make_standard = coalesce(make_standard, make_clean)
  )

transfer_clean <- transfer_clean %>%
  mutate(
    make_standard = coalesce(make_standard, make_clean)
  )


# Calculate total activity by make for transfer market 
make_volume_transfer <- transfer_clean %>%
  group_by(make_standard) %>%
  summarise(
    total_transfers = sum(TOTAL1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_transfers))

# Now we can calculate the market share 
make_volume_transfer <- make_volume_transfer %>%
  mutate(
    market_share = round(total_transfers / sum(total_transfers), 5),
    cumulative_share = cumsum(market_share)
  )

# We want to do the same for new car registrations 
make_volume_new <- new_clean %>%
  group_by(make_standard) %>%
  summarise(
    total_transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_transfers))

# Now we can calculate the market share 
make_volume_new <- make_volume_new %>%
  mutate(
    market_share = round(total_transfers / sum(total_transfers), 5),
    cumulative_share = cumsum(market_share)
  )

##### So what we're doing is working out the market share, sorting from largest to smallest, calculating cumulative share then when we get to 95% cumulative (inclusive) applying the cutoff 
# Now we want to apply a threshold of 95% -- so we see the top 95% of car makes 

top_makes_95 <- make_volume_transfer %>%
  filter(
    lag(cumulative_share, default = 0) < 0.95
  )

top_new_makes_95 <- make_volume_new %>%
  filter(
    lag(cumulative_share, default = 0) < 0.95
  )

## Now we can filter our actual dataset 
transfer_top_makes <- transfer_clean %>%
  semi_join(
    top_makes_95,
    by = "make_standard"
  )


new_top_makes <- new_clean %>%
  semi_join(
    top_new_makes_95,
    by = "make_standard"
  )


## Now further cleaning -- drop all NA and blank values in model 
transfer_top_makes <- transfer_top_makes %>%
  filter(
    !is.na(model_clean),
    str_squish(model_clean) != ""
  )

new_top_makes <- new_top_makes %>%
  filter(
    !is.na(model_clean),
    str_squish(model_clean) != ""
  )

# Look at the models and their volume 
model_volume <- transfer_top_makes %>%
  group_by(make_standard, model_clean) %>%
  summarise(
    total_transfers = sum(TOTAL1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(make_standard, desc(total_transfers))


## Now we want to see what cutoff to use -- top 75% -- need at least 12 to be included 
summary(model_volume$total_transfers)

quantile(
  model_volume$total_transfers,
  probs = c(0.50, 0.75, 0.90, 0.95),
  na.rm = TRUE
)



# Now for new vehicles 
new_model_volume <- new_top_makes %>%
  group_by(make_standard, model_clean) %>%
  summarise(
    total_transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(make_standard, desc(total_transfers))

## Now we want to see what cutoff to use -- top 75% -- need at least 11 to be included 
summary(new_model_volume$total_transfers)

quantile(
  new_model_volume$total_transfers,
  probs = c(0.50, 0.75, 0.90, 0.95),
  na.rm = TRUE
)


## At this stage we use -- transfer_top_makes and new_top_makes

# Now we want to make dates into year and month 
transfer_top_makes <- transfer_top_makes %>%
  mutate(
    transfer_year = year(month_year),
    transfer_month = month(month_year)
  )

new_top_makes <- new_top_makes %>%
  mutate(
    transfer_year = year(data_month_year),
    transfer_month = month(data_month_year)
  )

# Now we can data engineer -- make vehicle age -- dont need for new since they're new cars 
transfer_top_makes <- transfer_top_makes %>%
  mutate(
    vehicle_age = transfer_year - NB_YEAR_MFC_VEH
  )

summary(transfer_top_makes$vehicle_age)



## Now we can make buckets 
transfer_top_makes <- transfer_top_makes %>%
  mutate(
    age_bucket = case_when(
      vehicle_age <= 2 ~ "0-2 years",
      vehicle_age <= 6 ~ "3-6 years",
      vehicle_age <= 9 ~ "7-9 years",
      vehicle_age <= 12 ~ "10-12 years",
      vehicle_age <= 16 ~ "13-16 years",
      TRUE ~ NA_character_
    )
  )

# Make them ordered 
transfer_top_makes <- transfer_top_makes %>%
  mutate(
    age_bucket = factor(
      age_bucket,
      levels = c(
        "0-2 years",
        "3-6 years",
        "7-9 years",
        "10-12 years",
        "13-16 years"
      )
    )
  )



# Look at age distribution
transfer_top_makes %>%
  count(age_bucket)


transfer_top_makes %>%
  group_by(age_bucket) %>%
  summarise(
    transfers = sum(TOTAL1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    percentage = transfers / sum(transfers) * 100
  )


age_by_make <- transfer_top_makes %>%
  group_by(make_standard, age_bucket) %>%
  summarise(
    transfers = sum(TOTAL1, na.rm = TRUE),
    .groups = "drop"
  )

# Age of the vehicle by the make 
age_by_make <- age_by_make %>%
  group_by(make_standard) %>%
  mutate(
    percentage = transfers / sum(transfers) * 100
  ) %>%
  ungroup()

# Cumulative transfers by model
transfer_model_volume <- transfer_top_makes %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  summarise(
    total_transfers = sum(TOTAL1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_transfers))

# Top 20
head(transfer_model_volume, 20)


summary(transfer_model_volume$total_transfers)


quantile(
  transfer_model_volume$total_transfers,
  probs = c(
    0.50,
    0.75,
    0.90,
    0.95,
    0.99
  ),
  na.rm = TRUE
)


# Market share by model 
transfer_model_volume <- transfer_model_volume %>%
  mutate(
    market_share = total_transfers /
      sum(total_transfers) * 100
  )

# Recent activity - last 12 months 
recent_transfers <- transfer_top_makes %>%
  filter(
    month_year >
      max(month_year) %m-% months(12)
  )

# Recent - last 12 months 
recent_model_volume <- recent_transfers %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  summarise(
    recent_transfers = sum(TOTAL1, na.rm = TRUE),
    .groups = "drop"
  )

# Combine total and recent 
transfer_opportunity <- transfer_model_volume %>%
  left_join(
    recent_model_volume,
    by = c("make_standard", "model_clean")
  )

# Growth last 12 months vs recent 12 months 
previous_transfers <- transfer_top_makes %>%
  filter(
    month_year >
      max(month_year) %m-% months(24),
    month_year <=
      max(month_year) %m-% months(12)
  ) %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  summarise(
    previous_transfers = sum(TOTAL1, na.rm = TRUE),
    .groups = "drop"
  )


transfer_opportunity <- transfer_opportunity %>%
  left_join(
    previous_transfers,
    by = c("make_standard", "model_clean")
  ) %>%
  mutate(
    growth = (
      recent_transfers - previous_transfers
    ) / previous_transfers * 100
  )


# Now do the same for new vehicles 
new_model_volume <- new_top_makes %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  summarise(
    total_registrations = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_registrations))

new_model_volume %>%
  head(20)

# Year on year analysis 
new_yearly <- new_top_makes %>%
  group_by(
    make_standard,
    model_clean,
    transfer_year
  ) %>%
  summarise(
    registrations = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(
    make_standard,
    model_clean,
    transfer_year
  )


new_yearly <- new_yearly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  mutate(
    growth = (
      registrations - lag(registrations)
    ) / lag(registrations) * 100
  ) %>%
  ungroup()



## More analytics 

transfer_model_volume <- transfer_model_volume %>%
  mutate(
    market_share = round(total_transfers / sum(total_transfers), 5),
    cumulative_share = cumsum(market_share)
  )

t95_model <- transfer_model_volume %>%
  filter(lag(cumulative_share, default = 0) < 0.96) #(includes all 95%)


## ChatGPT code 
# =========================================================
# TOP 95% OF MODELS BY TOTAL TRANSFER VOLUME
# =========================================================

# Aggregate total transfers for each make + model
# across ALL years and months
transfer_model_volume <- transfer_top_makes %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  summarise(
    total_transfers = sum(TOTAL1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_transfers))


# Calculate market share and cumulative market share
transfer_model_volume <- transfer_model_volume %>%
  mutate(
    market_share = total_transfers / sum(total_transfers),
    cumulative_share = cumsum(market_share)
  )


# Keep models until cumulative market share reaches 95%
# Includes the model that crosses the 95% threshold
t95_model <- transfer_model_volume %>%
  filter(
    lag(cumulative_share, default = 0) < 0.96
  )


# Apply the top-95% model threshold back to the
# original detailed transfer dataset
# This keeps ALL years and months for the selected models
transfer_top_95 <- transfer_top_makes %>%
  semi_join(
    t95_model,
    by = c(
      "make_standard",
      "model_clean"
    )
  )



# =========================================================
# 1. CREATE MONTHLY MAKE + MODEL DATASET
# =========================================================

transfer_monthly <- transfer_top_95 %>%
  group_by(
    make_standard,
    model_clean,
    transfer_year,
    transfer_month
  ) %>%
  summarise(
    transfers = sum(TOTAL1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(
    make_standard,
    model_clean,
    transfer_year,
    transfer_month
  )


# =========================================================
# 2. VEHICLE CHARACTERISTICS BY MAKE + MODEL + MONTH
# =========================================================

vehicle_features <- transfer_top_95 %>%
  group_by(
    make_standard,
    model_clean,
    transfer_year,
    transfer_month
  ) %>%
  summarise(
    
    # Total demand
    transfers = sum(TOTAL1, na.rm = TRUE),
    
    # Vehicle age
    average_vehicle_age = weighted.mean(
      vehicle_age,
      w = TOTAL1,
      na.rm = TRUE
    ),
    
    median_vehicle_age = median(
      vehicle_age,
      na.rm = TRUE
    ),
    
    youngest_vehicle = min(
      vehicle_age,
      na.rm = TRUE
    ),
    
    oldest_vehicle = max(
      vehicle_age,
      na.rm = TRUE
    ),
    
    # Manufacturing year
    average_manufacture_year = weighted.mean(
      NB_YEAR_MFC_VEH,
      w = TOTAL1,
      na.rm = TRUE
    ),
    
    # Number of different colours
    number_of_colours = n_distinct(
      colour_clean
    ),
    
    .groups = "drop"
  )


dominant_colour <- transfer_top_95 %>%
  group_by(
    make_standard,
    model_clean,
    transfer_year,
    transfer_month,
    colour_clean
  ) %>%
  summarise(
    colour_transfers = sum(TOTAL1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(
    make_standard,
    model_clean,
    transfer_year,
    transfer_month
  ) %>%
  slice_max(
    colour_transfers,
    n = 1,
    with_ties = FALSE
  ) %>%
  ungroup() %>%
  select(
    make_standard,
    model_clean,
    transfer_year,
    transfer_month,
    dominant_colour = colour_clean
  )

vehicle_features <- vehicle_features %>%
  left_join(
    dominant_colour,
    by = c(
      "make_standard",
      "model_clean",
      "transfer_year",
      "transfer_month"
    )
  )


## Create lagged demand 
transfer_monthly <- vehicle_features %>%
  mutate(
    date = as.Date(
      paste(
        transfer_year,
        transfer_month,
        "01",
        sep = "-"
      )
    )
  ) %>%
  arrange(
    make_standard,
    model_clean,
    date
  )
transfer_monthly <- transfer_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  arrange(date) %>%
  mutate(
    
    # Previous month's demand
    transfers_lag_1 = lag(transfers, 1),
    
    # Demand 3 months ago
    transfers_lag_3 = lag(transfers, 3),
    
    # Demand 6 months ago
    transfers_lag_6 = lag(transfers, 6),
    
    # Demand 12 months ago
    transfers_lag_12 = lag(transfers, 12)
    
  ) %>%
  ungroup()


## Rolling demand 
library(slider)

transfer_monthly <- transfer_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  arrange(date) %>%
  mutate(
    
    rolling_3m = slide_dbl(
      lag(transfers),
      sum,
      .before = 2,
      .complete = TRUE
    ),
    
    rolling_6m = slide_dbl(
      lag(transfers),
      sum,
      .before = 5,
      .complete = TRUE
    ),
    
    rolling_12m = slide_dbl(
      lag(transfers),
      sum,
      .before = 11,
      .complete = TRUE
    )
    
  ) %>%
  ungroup()

# Growth features 
transfer_monthly <- transfer_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  arrange(date) %>%
  mutate(
    
    growth_3m = (
      rolling_3m -
        lag(rolling_3m, 3)
    ) /
      lag(rolling_3m, 3) * 100,
    
    growth_6m = (
      rolling_6m -
        lag(rolling_6m, 6)
    ) /
      lag(rolling_6m, 6) * 100
    
  ) %>%
  ungroup()

# Create our target
transfer_monthly <- transfer_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  arrange(date) %>%
  mutate(
    
    target_6m = slide_dbl(
      lead(transfers),
      sum,
      .before = 5,
      .complete = TRUE
    )
    
  ) %>%
  ungroup()

# 12 month target
transfer_monthly <- transfer_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  arrange(date) %>%
  mutate(
    
    target_12m = slide_dbl(
      lead(transfers),
      sum,
      .before = 11,
      .complete = TRUE
    )
    
  ) %>%
  ungroup()


#### remove all groups with NA
ml_data <- transfer_monthly %>%
  filter(
    !is.na(rolling_12m),
    !is.na(target_6m)
  )



#### Fixing issue of limited time frame
# =========================================================
# 16. CREATE MONTHLY MODEL-LEVEL DATASET
# =========================================================

model_monthly <- transfer_top_95 %>%
  mutate(
    date = floor_date(month_year, "month")
  ) %>%
  group_by(
    make_standard,
    model_clean,
    date
  ) %>%
  summarise(
    
    # Total number of vehicles transferred
    transfers = sum(TOTAL1, na.rm = TRUE),
    
    # Average age of transferred vehicles
    avg_vehicle_age = weighted.mean(
      vehicle_age,
      TOTAL1,
      na.rm = TRUE
    ),
    
    # Average manufacture year
    avg_mfg_year = weighted.mean(
      NB_YEAR_MFC_VEH,
      TOTAL1,
      na.rm = TRUE
    ),
    
    # Number of different colours transferred
    n_colours = n_distinct(
      colour_clean[!is.na(colour_clean)]
    ),
    
    .groups = "drop"
  )

# =========================================================
# 17. CREATE COMPLETE MONTHLY TIMELINE
# =========================================================

all_months <- seq(
  from = as.Date("2024-05-01"),
  to   = as.Date("2026-05-01"),
  by   = "month"
)

model_monthly <- model_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  complete(
    date = all_months
  ) %>%
  ungroup()

# =========================================================
# 18. FILL ZERO-DEMAND MONTHS
# =========================================================

model_monthly <- model_monthly %>%
  mutate(
    transfers = replace_na(transfers, 0)
  )

model_monthly <- model_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  arrange(date) %>%
  fill(
    avg_vehicle_age,
    avg_mfg_year,
    n_colours,
    .direction = "down"
  ) %>%
  ungroup()

# =========================================================
# 19. DATE FEATURES
# =========================================================

model_monthly <- model_monthly %>%
  mutate(
    transfer_year = year(date),
    transfer_month = month(date)
  )

model_monthly <- model_monthly %>%
  mutate(
    month_sin = sin(2 * pi * transfer_month / 12),
    month_cos = cos(2 * pi * transfer_month / 12)
  )

# =========================================================
# 20. LAG FEATURES
# =========================================================

model_monthly <- model_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  arrange(date) %>%
  mutate(
    
    lag_1 = lag(transfers, 1),
    
    lag_3 = lag(transfers, 3),
    
    lag_6 = lag(transfers, 6),
    
    lag_12 = lag(transfers, 12)
    
  ) %>%
  ungroup()

# =========================================================
# 21. ROLLING DEMAND FEATURES
# =========================================================

model_monthly <- model_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  arrange(date) %>%
  mutate(
    
    rolling_3m = slide_dbl(
      lag(transfers),
      sum,
      .before = 2,
      .complete = TRUE
    ),
    
    rolling_6m = slide_dbl(
      lag(transfers),
      sum,
      .before = 5,
      .complete = TRUE
    ),
    
    rolling_12m = slide_dbl(
      lag(transfers),
      sum,
      .before = 11,
      .complete = TRUE
    )
    
  ) %>%
  ungroup()


# =========================================================
# 22. FIXED GROWTH FEATURES
# =========================================================

model_monthly <- model_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  arrange(date) %>%
  mutate(
    
    # 3-month growth
    growth_3m = case_when(
      lag(rolling_3m, 3) == 0 & rolling_3m > 0 ~ NA_real_,
      lag(rolling_3m, 3) == 0 & rolling_3m == 0 ~ 0,
      TRUE ~ (
        rolling_3m - lag(rolling_3m, 3)
      ) / lag(rolling_3m, 3)
    ),
    
    # 6-month growth
    growth_6m = case_when(
      lag(rolling_6m, 6) == 0 & rolling_6m > 0 ~ NA_real_,
      lag(rolling_6m, 6) == 0 & rolling_6m == 0 ~ 0,
      TRUE ~ (
        rolling_6m - lag(rolling_6m, 6)
      ) / lag(rolling_6m, 6)
    )
    
  ) %>%
  ungroup()

# =========================================================
# 22B. HANDLE ZERO-DEMAND GROWTH
# =========================================================

model_monthly <- model_monthly %>%
  mutate(
    
    emerging_3m = if_else(
      lag(rolling_3m, 3) == 0 &
        rolling_3m > 0,
      1,
      0,
      missing = 0
    ),
    
    emerging_6m = if_else(
      lag(rolling_6m, 6) == 0 &
        rolling_6m > 0,
      1,
      0,
      missing = 0
    )
    
  )

# =========================================================
# 23. FUTURE 6-MONTH TARGET
# =========================================================

model_monthly <- model_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  arrange(date) %>%
  mutate(
    
    target_6m = slide_dbl(
      lead(transfers),
      sum,
      .before = 5,
      .complete = TRUE
    )
    
  ) %>%
  ungroup()

# =========================================================
# 24. FUTURE 12-MONTH TARGET
# =========================================================

model_monthly <- model_monthly %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  arrange(date) %>%
  mutate(
    
    target_12m = slide_dbl(
      lead(transfers),
      sum,
      .before = 11,
      .complete = TRUE
    )
    
  ) %>%
  ungroup()

# =========================================================
# 25. INSPECT FEATURE DATASET
# =========================================================

model_monthly %>%
  select(
    make_standard,
    model_clean,
    date,
    transfers,
    lag_1,
    lag_3,
    lag_6,
    lag_12,
    rolling_3m,
    rolling_6m,
    rolling_12m,
    growth_3m,
    growth_6m,
    target_6m,
    target_12m
  ) %>%
  arrange(
    make_standard,
    model_clean,
    date
  ) %>%
  head(30)

range(model_monthly$date)



# =========================================================
# 26. PREPARE ML DATASET
# =========================================================

ml_data <- model_monthly %>%
  select(
    make_standard,
    model_clean,
    date,
    
    transfer_year,
    transfer_month,
    month_sin,
    month_cos,
    
    avg_vehicle_age,
    avg_mfg_year,
    n_colours,
    
    lag_1,
    lag_3,
    lag_6,
    lag_12,
    
    rolling_3m,
    rolling_6m,
    rolling_12m,
    
    target_6m
  ) %>%
  filter(
    !is.na(target_6m),
    !is.na(lag_1),
    !is.na(lag_3),
    !is.na(lag_6),
    !is.na(lag_12),
    !is.na(rolling_3m),
    !is.na(rolling_6m),
    !is.na(rolling_12m)
  )

# Check the usable modelling period
range(ml_data$date)

# Number of observations
nrow(ml_data)

# Check remaining missing values
colSums(is.na(ml_data))

sapply(
  ml_data,
  function(x) sum(is.infinite(x))
)

# =========================================================
# 27. CHECK DATA SIZE
# =========================================================

ml_data %>%
  summarise(
    first_date = min(date),
    last_date = max(date),
    observations = n(),
    models = n_distinct(
      paste(make_standard, model_clean)
    )
  )

ml_data %>%
  count(date) %>%
  arrange(date) %>% 
  print(n = 25)

# =========================================================
# 28. TIME-BASED TRAIN / TEST SPLIT
# =========================================================

test_start <- max(ml_data$date) %m-% months(5)

train_data <- ml_data %>%
  filter(date < test_start)

test_data <- ml_data %>%
  filter(date >= test_start)

range(train_data$date)
range(test_data$date)

nrow(train_data)
nrow(test_data)


# =========================================================
# 29. EVALUATION FUNCTION
# =========================================================

calculate_metrics <- function(actual, predicted) {
  
  mae <- mean(
    abs(actual - predicted)
  )
  
  rmse <- sqrt(
    mean((actual - predicted)^2)
  )
  
  r2 <- 1 -
    sum((actual - predicted)^2) /
    sum((actual - mean(actual))^2)
  
  data.frame(
    MAE = mae,
    RMSE = rmse,
    R2 = r2
  )
}


# =========================================================
# 30. BASELINE
# =========================================================

baseline_predictions <- test_data$rolling_6m

baseline_metrics <- calculate_metrics(
  test_data$target_6m,
  baseline_predictions
)

baseline_metrics

# =========================================================
# CHECK TRAIN / TEST DATA
# =========================================================

dim(train_data)
dim(test_data)

colSums(is.na(train_data))
colSums(is.na(test_data))

sapply(
  train_data,
  function(x) {
    if (is.numeric(x)) sum(is.infinite(x)) else 0
  }
)
## Fixe the NA values
train_data <- train_data %>%
  filter(
    !is.na(avg_vehicle_age),
    !is.na(avg_mfg_year),
    !is.na(n_colours)
  )

test_data <- test_data %>%
  filter(
    !is.na(avg_vehicle_age),
    !is.na(avg_mfg_year),
    !is.na(n_colours)
  )

colSums(is.na(train_data))
colSums(is.na(test_data))
# =========================================================
# 31. LINEAR REGRESSION
# =========================================================

## Getting errors because our training dataset has never seen ATTO 1, ELEXIO, MG4 UR, MYL LR 
## But they appear in our test dataset -- new models introduced in 2026 and our training data never trained on them 
## So we will remove them for now 

linear_model <- lm(
  target_6m ~
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = train_data
)

linear_model

linear_predictions <- predict(
  linear_model,
  newdata = test_data
)



linear_metrics <- calculate_metrics(
  test_data$target_6m,
  linear_predictions
)

linear_metrics

head(linear_predictions)
length(linear_predictions)
nrow(test_data)

# =========================================================
# 32. Decision Trees
# =========================================================


library(rpart)

tree_model <- rpart(
  target_6m ~
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = train_data,
  method = "anova",
  control = rpart.control(
    maxdepth = 5,
    minsplit = 20,
    cp = 0.01
  )
)

tree_predictions <- predict(
  tree_model,
  newdata = test_data
)

tree_metrics <- calculate_metrics(
  test_data$target_6m,
  tree_predictions
)

tree_metrics

# =========================================================
# 33. Random Forest
# =========================================================
library(ranger)

rf_model <- ranger(
  target_6m ~
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = train_data,
  num.trees = 500,
  mtry = 5,
  min.node.size = 10,
  importance = "impurity"
)

rf_predictions <- predict(
  rf_model,
  data = test_data
)$predictions

rf_metrics <- calculate_metrics(
  test_data$target_6m,
  rf_predictions
)

rf_metrics

# =========================================================
# 34. XGBoost
# =========================================================

library(xgboost)

x_formula <- ~
  transfer_year +
  transfer_month +
  month_sin +
  month_cos +
  avg_vehicle_age +
  avg_mfg_year +
  n_colours +
  lag_1 +
  lag_3 +
  lag_6 +
  lag_12 +
  rolling_3m +
  rolling_6m +
  rolling_12m

X_train <- model.matrix(
  x_formula,
  data = train_data
)[, -1]

X_test <- model.matrix(
  x_formula,
  data = test_data
)[, -1]

y_train <- train_data$target_6m
y_test <- test_data$target_6m


xgb_model <- xgboost(
  data = X_train,
  label = y_train,
  objective = "reg:squarederror",
  nrounds = 300,
  max_depth = 4,
  learning_rate = 0.05,
  min_child_weight = 5,
  subsample = 0.8,
  colsample_bytree = 0.8,
  verbose = 0
)

xgb_predictions <- predict(
  xgb_model,
  X_test
)

xgb_metrics <- calculate_metrics(
  y_test,
  xgb_predictions
)

xgb_metrics

### Inspect predictors

xgb_check <- test_data %>%
  select(
    make_standard,
    model_clean,
    date,
    target_6m
  ) %>%
  mutate(
    prediction = xgb_predictions,
    error = target_6m - prediction,
    abs_error = abs(error)
  ) %>%
  arrange(desc(abs_error))

xgb_check %>%
  slice_head(n = 10)

## Inspect for linear 
linear_check <- test_data %>%
  select(
    make_standard,
    model_clean,
    date,
    target_6m
  ) %>%
  mutate(
    prediction = linear_predictions,
    error = target_6m - prediction,
    abs_error = abs(error)
  ) %>%
  arrange(desc(abs_error))

linear_check %>%
  slice_head(n = 10)



# =========================================================
# HANDLE UNSEEN MAKE-MODEL COMBINATIONS
# =========================================================

# Create combined make-model identifier
train_data <- train_data %>%
  mutate(
    make_model = paste(make_standard, model_clean, sep = "_")
  )

test_data <- test_data %>%
  mutate(
    make_model = paste(make_standard, model_clean, sep = "_")
  )

# Make sure they are characters while we recode
train_data$make_model <- as.character(train_data$make_model)
test_data$make_model <- as.character(test_data$make_model)

# Models that existed during training
known_models <- unique(train_data$make_model)

# Any model not seen during training becomes OTHER
test_data <- test_data %>%
  mutate(
    make_model = if_else(
      make_model %in% known_models,
      make_model,
      "OTHER"
    )
  )

# IMPORTANT:
# Add OTHER as an actual training category
train_data$make_model <- factor(
  train_data$make_model,
  levels = c(known_models, "OTHER")
)

test_data$make_model <- factor(
  test_data$make_model,
  levels = c(known_models, "OTHER")
)

# =========================================================
# Linear Regression
# =========================================================
linear_model_new <- lm(
  target_6m ~
    make_standard +
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = train_data
)

linear_predictions_new <- predict(
  linear_model_new,
  newdata = test_data
)

linear_metrics_new <- calculate_metrics(
  test_data$target_6m,
  linear_predictions_new
)

linear_metrics_new

formula(linear_model_new)
formula(linear_model)

linear_predictions_new <- predict(
  linear_model_new,
  newdata = test_data
)

head(linear_predictions_new)

head(
  data.frame(
    old = predict(linear_model, newdata = test_data),
    new = predict(linear_model_new, newdata = test_data)
  )
)
# =========================================================
# Decision Tree
# =========================================================
library(rpart)

tree_model_new <- rpart(
  target_6m ~
    make_standard +
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = train_data,
  method = "anova",
  control = rpart.control(
    maxdepth = 5,
    minsplit = 20,
    cp = 0.01
  )
)

tree_predictions_new <- predict(
  tree_model_new,
  newdata = test_data
)

tree_metrics_new <- calculate_metrics(
  test_data$target_6m,
  tree_predictions_new
)

tree_metrics_new
# =========================================================
# Random Forest
# =========================================================
library(ranger)

rf_model_new <- ranger(
  target_6m ~
    make_standard +
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = train_data,
  num.trees = 500,
  mtry = 5,
  min.node.size = 10,
  importance = "impurity"
)

rf_predictions_new <- predict(
  rf_model_new,
  data = test_data
)$predictions

rf_metrics_new <- calculate_metrics(
  test_data$target_6m,
  rf_predictions_new
)

rf_metrics_new
# =========================================================
# XGBoost
# =========================================================
library(xgboost)

x_formula_new <- ~
  make_standard +
  transfer_year +
  transfer_month +
  month_sin +
  month_cos +
  avg_vehicle_age +
  avg_mfg_year +
  n_colours +
  lag_1 +
  lag_3 +
  lag_6 +
  lag_12 +
  rolling_3m +
  rolling_6m +
  rolling_12m

X_train_new <- model.matrix(
  x_formula_new,
  data = train_data
)[, -1]

X_test_new <- model.matrix(
  x_formula_new,
  data = test_data
)[, -1]

y_train <- train_data$target_6m
y_test <- test_data$target_6m

xgb_model_new <- xgboost(
  data = X_train_new,
  label = y_train,
  objective = "reg:squarederror",
  nrounds = 300,
  max_depth = 4,
  learning_rate = 0.05,
  min_child_weight = 5,
  subsample = 0.8,
  colsample_bytree = 0.8,
  verbose = 0
)

xgb_predictions_new <- predict(
  xgb_model_new,
  X_test_new
)

xgb_metrics_new <- calculate_metrics(
  y_test,
  xgb_predictions_new
)

xgb_metrics_new

# =========================================================
# Results
# =========================================================
results <- bind_rows(
  data.frame(
    Model = "Baseline",
    baseline_metrics
  ),
  data.frame(
    Model = "Linear Regression",
    linear_metrics_new
  ),
  data.frame(
    Model = "Decision Tree",
    tree_metrics_new
  ),
  data.frame(
    Model = "Random Forest",
    rf_metrics_new
  ),
  data.frame(
    Model = "XGBoost",
    xgb_metrics_new
  )
) %>%
  arrange(RMSE)

results




# -----------------------------
# Numerical features
# -----------------------------

library(nnet)

numeric_features <- c(
  "transfer_year",
  "transfer_month",
  "month_sin",
  "month_cos",
  "avg_vehicle_age",
  "avg_mfg_year",
  "n_colours",
  "lag_1",
  "lag_3",
  "lag_6",
  "lag_12",
  "rolling_3m",
  "rolling_6m",
  "rolling_12m"
)

# -----------------------------
# Scale using TRAINING data only
# -----------------------------

train_means <- sapply(
  train_data[numeric_features],
  mean,
  na.rm = TRUE
)

train_sds <- sapply(
  train_data[numeric_features],
  sd,
  na.rm = TRUE
)

train_nn <- train_data

test_nn <- test_data

train_nn[numeric_features] <- sweep(
  train_nn[numeric_features],
  2,
  train_means,
  "-"
)

train_nn[numeric_features] <- sweep(
  train_nn[numeric_features],
  2,
  train_sds,
  "/"
)

test_nn[numeric_features] <- sweep(
  test_nn[numeric_features],
  2,
  train_means,
  "-"
)

test_nn[numeric_features] <- sweep(
  test_nn[numeric_features],
  2,
  train_sds,
  "/"
)
x_formula_nn <- ~
  make_standard +
  transfer_year +
  transfer_month +
  month_sin +
  month_cos +
  avg_vehicle_age +
  avg_mfg_year +
  n_colours +
  lag_1 +
  lag_3 +
  lag_6 +
  lag_12 +
  rolling_3m +
  rolling_6m +
  rolling_12m

X_train_nn <- model.matrix(
  x_formula_nn,
  data = train_nn
)[, -1]

X_test_nn <- model.matrix(
  x_formula_nn,
  data = test_nn
)[, -1]

dim(X_train_nn)
dim(X_test_nn)

set.seed(42)

nn_model <- nnet(
  x = X_train_nn,
  y = train_nn$target_6m,
  size = 10,
  decay = 0.1,
  maxit = 1000,
  linout = TRUE,
  trace = FALSE
)

nn_predictions <- predict(
  nn_model,
  X_test_nn
)

nn_metrics <- calculate_metrics(
  test_nn$target_6m,
  nn_predictions
)

nn_metrics

results <- data.frame(
  Model = c(
    "Linear Regression",
    "Random Forest",
    "Baseline",
    "XGBoost",
    "Decision Tree",
    "Neural Network"
  ),
  
  MAE = c(
    linear_metrics_new$MAE,
    rf_metrics_new$MAE,
    baseline_metrics$MAE,
    xgb_metrics_new$MAE,
    tree_metrics_new$MAE,
    nn_metrics$MAE
  ),
  
  RMSE = c(
    linear_metrics_new$RMSE,
    rf_metrics_new$RMSE,
    baseline_metrics$RMSE,
    xgb_metrics_new$RMSE,
    tree_metrics_new$RMSE,
    nn_metrics$RMSE
  ),
  
  R2 = c(
    linear_metrics_new$R2,
    rf_metrics_new$R2,
    baseline_metrics$R2,
    xgb_metrics_new$R2,
    tree_metrics_new$R2,
    nn_metrics$R2
  )
)

results <- results %>%
  arrange(RMSE)

results


### Now to combat issue of not knowing the model 
### Split into models we know and new models 
### We will create separate predictive models 
ml_data_model <- model_monthly %>%
  select(
    make_standard,
    model_clean,
    date,
    transfer_year,
    transfer_month,
    month_sin,
    month_cos,
    avg_vehicle_age,
    avg_mfg_year,
    n_colours,
    lag_1,
    lag_3,
    lag_6,
    lag_12,
    rolling_3m,
    rolling_6m,
    rolling_12m,
    target_6m
  ) %>%
  filter(
    !is.na(target_6m),
    !is.na(lag_1),
    !is.na(lag_3),
    !is.na(lag_6),
    !is.na(lag_12),
    !is.na(rolling_3m),
    !is.na(rolling_6m),
    !is.na(rolling_12m),
    !is.na(avg_vehicle_age),
    !is.na(avg_mfg_year),
    !is.na(n_colours)
  )

# New make + model 
ml_data_model <- ml_data_model %>%
  mutate(
    make_model = paste(
      make_standard,
      model_clean,
      sep = "_"
    )
  )

# Train and test split 
test_start_model <- max(ml_data_model$date) %m-% months(5)

train_data_model <- ml_data_model %>%
  filter(date < test_start_model)

test_data_model <- ml_data_model %>%
  filter(date >= test_start_model)

# Unseen models remove them 
known_make_models <- unique(
  train_data_model$make_model
)

# New dataset with what we know 
test_data_model_known <- test_data_model %>%
  filter(
    make_model %in% known_make_models
  )

# Models excluded 
test_data_model_new <- test_data_model %>%
  filter(
    !make_model %in% known_make_models
  )

nrow(test_data_model)
nrow(test_data_model_known)
nrow(test_data_model_new) # 17 new models 

table(
  test_data_model$make_model %in% known_make_models
)

# make sure variables are factors 
train_data_model <- train_data_model %>%
  mutate(
    make_standard = factor(make_standard),
    make_model = factor(make_model)
  )

test_data_model_known <- test_data_model_known %>%
  mutate(
    make_standard = factor(
      make_standard,
      levels = levels(train_data_model$make_standard)
    ),
    make_model = factor(
      make_model,
      levels = levels(train_data_model$make_model)
    )
  )

sum(is.na(train_data_model))
sum(is.na(test_data_model_known))

# individual make model combinations 
length(unique(train_data_model$make_model))

# =========================================================
# Linear Regression
# =========================================================
linear_model_model <- lm(
  target_6m ~
    make_standard +
    make_model +
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = train_data_model
)


linear_predictions_model <- predict(
  linear_model_model,
  newdata = test_data_model_known
)


linear_metrics_model <- calculate_metrics(
  test_data_model_known$target_6m,
  linear_predictions_model
)

linear_metrics_model

# =========================================================
# Decision Tree
# =========================================================
library(rpart)

tree_model_model <- rpart(
  target_6m ~
    make_standard +
    make_model +
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = train_data_model,
  method = "anova",
  control = rpart.control(
    maxdepth = 5,
    minsplit = 20,
    cp = 0.01
  )
)

tree_predictions_model <- predict(
  tree_model_model,
  newdata = test_data_model_known
)

tree_metrics_model <- calculate_metrics(
  test_data_model_known$target_6m,
  tree_predictions_model
)

tree_metrics_model
# =========================================================
# Random Forest
# =========================================================
library(ranger)

rf_model_model <- ranger(
  target_6m ~
    make_standard +
    make_model +
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = train_data_model,
  num.trees = 500,
  mtry = 5,
  min.node.size = 10,
  importance = "impurity"
)

rf_predictions_model <- predict(
  rf_model_model,
  data = test_data_model_known
)$predictions

rf_metrics_model <- calculate_metrics(
  test_data_model_known$target_6m,
  rf_predictions_model
)

rf_metrics_model
# =========================================================
# XGBoost
# =========================================================
library(xgboost)

x_formula_model <- ~
  make_standard +
  make_model +
  transfer_year +
  transfer_month +
  month_sin +
  month_cos +
  avg_vehicle_age +
  avg_mfg_year +
  n_colours +
  lag_1 +
  lag_3 +
  lag_6 +
  lag_12 +
  rolling_3m +
  rolling_6m +
  rolling_12m

X_train_model <- model.matrix(
  x_formula_model,
  data = train_data_model
)[, -1]

X_test_model <- model.matrix(
  x_formula_model,
  data = test_data_model_known
)[, -1]


dim(X_train_model)
dim(X_test_model)

y_train_model <- train_data_model$target_6m

y_test_model <- test_data_model_known$target_6m

xgb_model_model <- xgboost(
  data = X_train_model,
  label = y_train_model,
  objective = "reg:squarederror",
  nrounds = 500,
  max_depth = 4,
  learning_rate = 0.1,
  min_child_weight = 5,
  subsample = 0.8,
  colsample_bytree = 0.8,
  verbose = 0
)

xgb_predictions_model <- predict(
  xgb_model_model,
  X_test_model
)

xgb_metrics_model <- calculate_metrics(
  y_test_model,
  xgb_predictions_model
)

xgb_metrics_model


# =========================================================
# Results
# =========================================================
results_model <- data.frame(
  Model = c(
    "Linear Regression",
    "Decision Tree",
    "Random Forest",
    "XGBoost"
  ),
  
  MAE = c(
    linear_metrics_model$MAE,
    tree_metrics_model$MAE,
    rf_metrics_model$MAE,
    xgb_metrics_model$MAE
  ),
  
  RMSE = c(
    linear_metrics_model$RMSE,
    tree_metrics_model$RMSE,
    rf_metrics_model$RMSE,
    xgb_metrics_model$RMSE
  ),
  
  R2 = c(
    linear_metrics_model$R2,
    tree_metrics_model$R2,
    rf_metrics_model$R2,
    xgb_metrics_model$R2
  )
)

results_model <- results_model %>%
  arrange(RMSE)

results_model

# =========================================================
# Ranking
# =========================================================
final_ranking <- test_data_model_known %>%
  select(
    date,
    make_standard,
    model_clean
  ) %>%
  mutate(
    predicted_demand = linear_predictions_model
  ) %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  summarise(
    average_predicted_demand = mean(
      predicted_demand,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(average_predicted_demand)
  ) %>%
  mutate(
    rank = row_number()
  )

final_ranking %>%
  head(20)


## prediction with actual 
ranking_comparison <- test_data_model_known %>%
  select(
    date,
    make_standard,
    model_clean,
    target_6m
  ) %>%
  mutate(
    predicted_demand = linear_predictions_model
  ) %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  summarise(
    predicted_6m = mean(
      predicted_demand,
      na.rm = TRUE
    ),
    actual_6m = mean(
      target_6m,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  arrange(desc(predicted_6m)) %>%
  mutate(
    predicted_rank = row_number()
  ) %>%
  arrange(desc(actual_6m)) %>%
  mutate(
    actual_rank = row_number()
  ) %>%
  arrange(predicted_rank)

ranking_comparison %>%
  head(20)


# ---------------------------------------------------------
# FINAL LINEAR REGRESSION MODEL
# Train using all observations where target_6m is known
# ---------------------------------------------------------

final_train_data <- model_monthly %>%
  filter(
    !is.na(target_6m),
    !is.na(lag_1),
    !is.na(lag_3),
    !is.na(lag_6),
    !is.na(lag_12),
    !is.na(rolling_3m),
    !is.na(rolling_6m),
    !is.na(rolling_12m),
    !is.na(avg_vehicle_age),
    !is.na(avg_mfg_year),
    !is.na(n_colours)
  ) %>%
  mutate(
    make_standard = factor(make_standard),
    make_model = factor(
      paste(make_standard, model_clean, sep = "_")
    )
  )

final_linear_model <- lm(
  target_6m ~
    make_standard +
    make_model +
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = final_train_data
)

# ---------------------------------------------------------
# FUTURE FORECAST DATA
# Latest available month
# ---------------------------------------------------------

latest_date <- max(model_monthly$date, na.rm = TRUE)

future_data <- model_monthly %>%
  filter(date == latest_date) %>%
  filter(
    !is.na(lag_1),
    !is.na(lag_3),
    !is.na(lag_6),
    !is.na(lag_12),
    !is.na(rolling_3m),
    !is.na(rolling_6m),
    !is.na(rolling_12m),
    !is.na(avg_vehicle_age),
    !is.na(avg_mfg_year),
    !is.na(n_colours)
  ) %>%
  mutate(
    make_standard = factor(
      make_standard,
      levels = levels(final_train_data$make_standard)
    ),
    make_model = factor(
      paste(as.character(make_standard), model_clean, sep = "_"),
      levels = levels(final_train_data$make_model)
    )
  )

# Models in the latest month that the model has never seen before

new_models <- future_data %>%
  filter(is.na(make_model)) %>%
  select(
    make_standard,
    model_clean
  ) %>%
  distinct()

new_models


future_data_known <- future_data %>%
  filter(!is.na(make_model))

future_predictions <- predict(
  final_linear_model,
  newdata = future_data_known
)

future_ranking <- future_data_known %>%
  select(
    make_standard,
    model_clean,
    date
  ) %>%
  mutate(
    predicted_6m = as.numeric(future_predictions)
  ) %>%
  arrange(desc(predicted_6m)) %>%
  mutate(
    rank = row_number()
  )
future_ranking <- future_ranking %>%
  rename(
    forecast_start = date,
    future_forecast = predicted_6m
  )

head(future_ranking, 20)

future_ranking <- future_ranking %>%
  mutate(
    future_forecast = round(future_forecast, 0)
  )

head(future_ranking, 20)



## Correlation 
cor(
  ranking_comparison$predicted_rank,
  ranking_comparison$actual_rank,
  method = "spearman"
)

top10_predicted <- ranking_comparison %>%
  filter(predicted_rank <= 10)

top10_actual <- ranking_comparison %>%
  filter(actual_rank <= 10)

top10_overlap <- intersect(
  paste(top10_predicted$make_standard,
        top10_predicted$model_clean),
  paste(top10_actual$make_standard,
        top10_actual$model_clean)
)

length(top10_overlap)



#### Tuning random forest 
library(ranger)

rf_grid <- expand.grid(
  mtry = c(3, 5, 8, 12),
  min.node.size = c(5, 10, 20, 40),
  sample.fraction = c(0.7, 0.9, 1.0)
)

rf_results <- data.frame()

for (i in 1:nrow(rf_grid)) {
  
  model <- ranger(
    target_6m ~
      make_standard +
      make_model +
      transfer_year +
      transfer_month +
      month_sin +
      month_cos +
      avg_vehicle_age +
      avg_mfg_year +
      n_colours +
      lag_1 +
      lag_3 +
      lag_6 +
      lag_12 +
      rolling_3m +
      rolling_6m +
      rolling_12m,
    data = train_data_model,
    num.trees = 500,
    mtry = rf_grid$mtry[i],
    min.node.size = rf_grid$min.node.size[i],
    sample.fraction = rf_grid$sample.fraction[i],
    importance = "impurity"
  )
  
  predictions <- predict(
    model,
    data = test_data_model_known
  )$predictions
  
  metrics <- calculate_metrics(
    test_data_model_known$target_6m,
    predictions
  )
  
  rf_results <- rbind(
    rf_results,
    data.frame(
      mtry = rf_grid$mtry[i],
      min.node.size = rf_grid$min.node.size[i],
      sample.fraction = rf_grid$sample.fraction[i],
      MAE = metrics$MAE,
      RMSE = metrics$RMSE,
      R2 = metrics$R2
    )
  )
}

rf_results <- rf_results %>%
  arrange(RMSE)


head(rf_results, 10) 

### Update the code with the tuned hyper parameters for random forest 

# =========================================================
# 1. FINAL TRAINING DATA
# =========================================================

final_train_data <- model_monthly %>%
  filter(
    !is.na(target_6m),
    !is.na(lag_1),
    !is.na(lag_3),
    !is.na(lag_6),
    !is.na(lag_12),
    !is.na(rolling_3m),
    !is.na(rolling_6m),
    !is.na(rolling_12m),
    !is.na(avg_vehicle_age),
    !is.na(avg_mfg_year),
    !is.na(n_colours)
  ) %>%
  mutate(
    make_standard = factor(make_standard),
    make_model = factor(
      paste(make_standard, model_clean, sep = "_")
    )
  )


# =========================================================
# 2. FINAL LINEAR REGRESSION
# =========================================================

final_linear_model <- lm(
  target_6m ~
    make_standard +
    make_model +
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = final_train_data
)


# =========================================================
# 3. FINAL TUNED RANDOM FOREST
# =========================================================

library(ranger)

final_rf_model <- ranger(
  target_6m ~
    make_standard +
    make_model +
    transfer_year +
    transfer_month +
    month_sin +
    month_cos +
    avg_vehicle_age +
    avg_mfg_year +
    n_colours +
    lag_1 +
    lag_3 +
    lag_6 +
    lag_12 +
    rolling_3m +
    rolling_6m +
    rolling_12m,
  data = final_train_data,
  num.trees = 500,
  mtry = 8,
  min.node.size = 5,
  sample.fraction = 0.7,
  importance = "impurity"
)

# =========================================================
# 4. LATEST AVAILABLE DATA
# =========================================================

latest_date <- max(
  model_monthly$date,
  na.rm = TRUE
)

future_data <- model_monthly %>%
  filter(date == latest_date) %>%
  filter(
    !is.na(lag_1),
    !is.na(lag_3),
    !is.na(lag_6),
    !is.na(lag_12),
    !is.na(rolling_3m),
    !is.na(rolling_6m),
    !is.na(rolling_12m),
    !is.na(avg_vehicle_age),
    !is.na(avg_mfg_year),
    !is.na(n_colours)
  ) %>%
  mutate(
    make_standard = factor(
      make_standard,
      levels = levels(final_train_data$make_standard)
    ),
    make_model = factor(
      paste(
        as.character(make_standard),
        model_clean,
        sep = "_"
      ),
      levels = levels(final_train_data$make_model)
    )
  )

# =========================================================
# 5. KNOWN MAKE-MODELS ONLY
# =========================================================

future_data_known <- future_data %>%
  filter(!is.na(make_model))

# =========================================================
# 6. FUTURE PREDICTIONS
# =========================================================

linear_future_predictions <- predict(
  final_linear_model,
  newdata = future_data_known
)

rf_future_predictions <- predict(
  final_rf_model,
  data = future_data_known
)$predictions

# =========================================================
# 7. COMBINE BOTH FORECASTS
# =========================================================

future_forecasts <- future_data_known %>%
  select(
    make_standard,
    model_clean,
    date,
    rolling_6m
  ) %>%
  mutate(
    linear_predicted_6m = as.numeric(
      linear_future_predictions
    ),
    
    rf_predicted_6m = as.numeric(
      rf_future_predictions
    )
  )

# =========================================================
# 8A. LINEAR REGRESSION - ABSOLUTE DEMAND RANKING
# =========================================================

linear_absolute_ranking <- future_forecasts %>%
  arrange(desc(linear_predicted_6m)) %>%
  mutate(
    rank = row_number()
  ) %>%
  select(
    rank,
    make_standard,
    model_clean,
    date,
    linear_predicted_6m
  )

head(linear_absolute_ranking, 20)

# =========================================================
# 8B. RANDOM FOREST - ABSOLUTE DEMAND RANKING
# =========================================================

rf_absolute_ranking <- future_forecasts %>%
  arrange(desc(rf_predicted_6m)) %>%
  mutate(
    rank = row_number()
  ) %>%
  select(
    rank,
    make_standard,
    model_clean,
    date,
    rf_predicted_6m
  )

head(rf_absolute_ranking, 20)

# =========================================================
# 9A. LINEAR REGRESSION - CHANGE RANKING
# =========================================================

linear_change_ranking <- future_forecasts %>%
  mutate(
    change_6m = linear_predicted_6m - rolling_6m
  ) %>%
  arrange(desc(change_6m)) %>%
  mutate(
    rank = row_number()
  ) %>%
  select(
    rank,
    make_standard,
    model_clean,
    date,
    rolling_6m,
    linear_predicted_6m,
    change_6m
  )

head(linear_change_ranking, 20)

# =========================================================
# 9B. RANDOM FOREST - CHANGE RANKING
# =========================================================

rf_change_ranking <- future_forecasts %>%
  mutate(
    change_6m = rf_predicted_6m - rolling_6m
  ) %>%
  arrange(desc(change_6m)) %>%
  mutate(
    rank = row_number()
  ) %>%
  select(
    rank,
    make_standard,
    model_clean,
    date,
    rolling_6m,
    rf_predicted_6m,
    change_6m
  )

head(rf_change_ranking, 20)

