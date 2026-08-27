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
  count(CD_MAKE_VEH, sort = TRUE)


## Clean up the data 


# Fix the dates in new vehicles
new_vehicles <- new_vehicles %>% 
  mutate(data_month_year = as.Date(paste0(data_month_year, "01"), format = "%Y%m%d"))

# Fix dates in the transfer 
transfer_vehicles <- transfer_vehicles %>% 
  mutate(data_month_year = as.Date(paste0(data_month_year, "01"), format = "%Y%m%d"))


# Lets see all the different types of colours -- new vehicles
new_vehicles %>% 
  count(CD_CLR_BDY_VEH_P, sort = TRUE) %>% 
  print(n = Inf)

# Lets see all the different types of colours -- transfer vehicles
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
  group_by(CD_MODEL_VEH, CD_MAKE_VEH) %>% 
  summarise(count = n())


## What if we only use the top 20 makes 
top_20_makes <- transfer_vehicles %>% 
  filter(NB_YEAR_MFC_VEH >= 2010) %>% 
  count(CD_MAKE_VEH, sort = TRUE) %>% 
  slice_head(n = 30)

top_20_data <- transfer_vehicles %>% 
  filter(CD_MAKE_VEH %in% top_20_makes$CD_MAKE_VEH, 
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

n_distinct(transfer_clean$CD_MAKE_VEH)
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
    total_transfers = sum(TOTAL, na.rm = TRUE),
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
    total_transfers = sum(TOTAL, na.rm = TRUE),
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
    transfer_year = year(data_month_year),
    transfer_month = month(data_month_year)
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
    transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    percentage = transfers / sum(transfers) * 100
  )


age_by_make <- transfer_top_makes %>%
  group_by(make_standard, age_bucket) %>%
  summarise(
    transfers = sum(TOTAL, na.rm = TRUE),
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
    total_transfers = sum(TOTAL, na.rm = TRUE),
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
    data_month_year >
      max(data_month_year) %m-% months(12)
  )

# Recent - last 12 months 
recent_model_volume <- recent_transfers %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  summarise(
    recent_transfers = sum(TOTAL, na.rm = TRUE),
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
    data_month_year >
      max(data_month_year) %m-% months(24),
    data_month_year <=
      max(data_month_year) %m-% months(12)
  ) %>%
  group_by(
    make_standard,
    model_clean
  ) %>%
  summarise(
    previous_transfers = sum(TOTAL, na.rm = TRUE),
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




### Now for the graphs 
used_monthly <- transfer_top_makes %>%
  group_by(data_month_year) %>%
  summarise(
    transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  )

ggplot(used_monthly, aes(x = data_month_year, y = transfers)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Monthly Victorian Used-Vehicle Transfers",
    subtitle = "Vehicles manufactured from 2010 onwards and major makes",
    x = NULL,
    y = "Number of transfers"
  ) +
  scale_y_continuous(labels = comma) +
  theme_minimal()

## Top 15 makes
top_makes <- transfer_top_makes %>%
  group_by(make_standard) %>%
  summarise(
    transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(transfers)) %>%
  slice_head(n = 15)

ggplot(top_makes,
       aes(x = reorder(make_standard, transfers),
           y = transfers)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top 15 Vehicle Makes by Used-Vehicle Transfers",
    x = NULL,
    y = "Total transfers"
  ) +
  scale_y_continuous(labels = comma) +
  theme_minimal()

## Top 20 models 
top_models <- transfer_top_makes %>%
  group_by(make_standard, model_clean) %>%
  summarise(
    transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(transfers)) %>%
  slice_head(n = 20) %>%
  mutate(
    vehicle = paste(make_standard, model_clean)
  )

ggplot(top_models,
       aes(x = reorder(vehicle, transfers),
           y = transfers)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top 20 Vehicle Models by Used-Vehicle Transfers",
    x = NULL,
    y = "Total transfers"
  ) +
  scale_y_continuous(labels = comma) +
  theme_minimal()


## top used models - transfers
top_10_models <- transfer_top_makes %>%
  group_by(make_standard, model_clean) %>%
  summarise(
    transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(transfers)) %>%
  slice_head(n = 5) %>%
  mutate(
    vehicle = paste(make_standard, model_clean)
  ) %>%
  pull(vehicle)

model_trends <- transfer_top_makes %>%
  mutate(
    vehicle = paste(make_standard, model_clean)
  ) %>%
  filter(vehicle %in% top_10_models) %>%
  group_by(data_month_year, vehicle) %>%
  summarise(
    transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  )

transfer_trends_plot <- ggplot(model_trends,
       aes(x = data_month_year,
           y = transfers,
           group = vehicle,
           colour = vehicle)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "Used-Vehicle Transfer Trends",
    subtitle = "For the top 5 most popular models",
    x = NULL,
    y = "Monthly transfers",
    colour = "Vehicle"
  ) +
  scale_y_continuous(labels = comma) +
  scale_colour_brewer(palette = "Set2") +   # or scale_colour_viridis_d()
  theme(plot.title = element_text(hjust = 0.1))+
  theme_minimal()

# ggsave("transfer_trends_plot.pdf", plot = last_plot(), path = getwd())

# Recent popularity
recent_cutoff <- max(transfer_top_makes$data_month_year) %m-% months(12)

recent_models <- transfer_top_makes %>%
  filter(data_month_year > recent_cutoff) %>%
  group_by(make_standard, model_clean) %>%
  summarise(
    recent_transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(recent_transfers)) %>%
  slice_head(n = 15) %>%
  mutate(
    vehicle = paste(make_standard, model_clean)
  )

ggplot(recent_models,
       aes(x = reorder(vehicle, recent_transfers),
           y = recent_transfers)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Most Popular Used Vehicles in the Most Recent 12 Months",
    x = NULL,
    y = "Transfers"
  ) +
  scale_y_continuous(labels = comma) +
  theme_minimal()

## Growth and popularity
latest_date <- max(transfer_top_makes$data_month_year)

recent_12 <- transfer_top_makes %>%
  filter(
    data_month_year > data_month_year %m-% months(12)
  ) %>%
  group_by(make_standard, model_clean) %>%
  summarise(
    recent_transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  )

previous_12 <- transfer_top_makes %>%
  filter(
    data_month_year > latest_date %m-% months(24),
    data_month_year <= latest_date %m-% months(12)
  ) %>%
  group_by(make_standard, model_clean) %>%
  summarise(
    previous_transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  )

model_growth <- recent_12 %>%
  left_join(
    previous_12,
    by = c("make_standard", "model_clean")
  ) %>%
  mutate(
    growth = (recent_transfers - previous_transfers) /
      previous_transfers * 100,
    vehicle = paste(make_standard, model_clean)
  ) %>%
  filter(
    !is.na(growth),
    previous_transfers > 0
  )

ggplot(
  model_growth,
  aes(
    x = previous_transfers,
    y = growth
  )
) +
  geom_point(alpha = 0.5) +
  labs(
    title = "Used-Vehicle Popularity vs Recent Growth",
    subtitle = "Models with stronger activity and growth may represent more attractive stocking opportunities",
    x = "Previous 12-month transfers",
    y = "Growth in transfers (%)"
  ) +
  theme_minimal()

## Age of vehicles 
age_distribution <- transfer_top_makes %>%
  group_by(age_bucket) %>%
  summarise(
    transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  )

ggplot(age_distribution,
       aes(x = age_bucket, y = transfers)) +
  geom_col() +
  labs(
    title = "Used-Vehicle Transfers by Vehicle Age",
    x = "Vehicle age",
    y = "Transfers"
  ) +
  scale_y_continuous(labels = comma) +
  theme_minimal()


# Age profile of major makes 
age_make <- transfer_top_makes %>%
  group_by(make_standard, age_bucket) %>%
  summarise(
    transfers = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(make_standard) %>%
  mutate(
    percentage = transfers / sum(transfers) * 100
  ) %>%
  ungroup() %>%
  filter(
    make_standard %in% top_makes$make_standard
  )

age_trend_plot <- ggplot(
  age_make,
  aes(
    x = reorder(make_standard, percentage),
    y = percentage,
    fill = age_bucket
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Vehicle Age Profile Across Major Makes",
    x = NULL,
    y = "Share of transfers (%)",
    fill = "Vehicle age"
  ) +
  theme_minimal()

ggsave("age_trend_plot.pdf", plot = last_plot(), path = getwd())

## Age mix of cars transferred
top_makes <- transfer_top_makes %>%
  group_by(make_standard) %>%
  summarise(total = sum(TOTAL, na.rm = TRUE)) %>%
  arrange(desc(total)) %>% 
  slice_max(total, n = 20) %>%
  pull(make_standard)
  
age_by_make_filtered <- age_by_make %>%
  filter(make_standard %in% top_makes)

age_mix_plot <- ggplot(age_by_make_filtered,
       aes(x = make_standard,
           y = percentage,
           fill = age_bucket)) +
  geom_col(position = "stack") +
  labs(
    title = "Vehicle Age Distribution by Make",
    subtitle = "Age the cars of top 20 brands are transferred",
    x = NULL,
    y = "Share of transfers (%)",
    fill = "Vehicle Age"
  ) +
  scale_fill_brewer(palette = "RdYlBu", direction = -1) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("age_mix_plot.pdf", plot = last_plot(), path = getwd())







## More analytics 

transfer_model_volume <- transfer_model_volume %>%
  mutate(
    market_share = round(total_transfers / sum(total_transfers), 5),
    cumulative_share = cumsum(market_share)
  )

t95_model <- transfer_model_volume %>%
  filter(
    lag(market_share, default = 0) < 0.95
    )





