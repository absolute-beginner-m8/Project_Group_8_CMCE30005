library(dplyr)
library(tidyverse)
library(lubridate)

transfer_vehicles <- read_csv("Raw_Datasets/monthly_vehicle_transfers_may2023_2026.csv")
new_vehicles <- read_csv("Raw_Datasets/monthly_new_vehicle_registration_may2023_2026.csv")
make_mapping <- read_csv("Raw_Datasets/complete_vehicle_mapping.csv")
transfer_vehicles <- transfer_vehicles %>%
  rename(data_month_year = month_year, CD_MAKE_VEH = CD_MAKE_VEH1, TOTAL = TOTAL1) %>%
  mutate(data_month_year = as.Date(paste0(data_month_year, "01"), format = "%Y%m%d"))
transfer_vehicles <- transfer_vehicles %>%
  left_join(make_mapping %>% select(CD_MAKE_VEH, CD_MAKE_VEH_CLEAN), by = "CD_MAKE_VEH") %>%
  mutate(make_standard = coalesce(CD_MAKE_VEH_CLEAN, CD_MAKE_VEH))
new_vehicles <- new_vehicles %>%
  mutate(data_month_year = as.Date(paste0(data_month_year, "01"), format = "%Y%m%d")) %>%
  left_join(make_mapping %>% select(CD_MAKE_VEH, CD_MAKE_VEH_CLEAN), by = "CD_MAKE_VEH") %>%
  mutate(make_standard = coalesce(CD_MAKE_VEH_CLEAN, CD_MAKE_VEH))
write_csv(transfer_vehicles, "outputs/CSVs/transfers_cleaned_records.csv")
write_csv(new_vehicles, "outputs/CSVs/registrations_cleaned_records.csv")
