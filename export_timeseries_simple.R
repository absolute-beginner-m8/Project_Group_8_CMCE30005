library(dplyr)
library(tidyverse)

transfer_vehicles <- read_csv("Raw_Datasets/monthly_vehicle_transfers_may2023_2026.csv")
make_mapping <- read_csv("Raw_Datasets/complete_vehicle_mapping.csv")

transfer_vehicles <- transfer_vehicles %>%
  rename(data_month_year = month_year, CD_MAKE_VEH = CD_MAKE_VEH1, TOTAL = TOTAL1) %>%
  mutate(data_month_year = as.Date(paste0(data_month_year, "01"), format = "%Y%m%d"))

transfer_clean <- transfer_vehicles %>%
  left_join(make_mapping %>% select(CD_MAKE_VEH, CD_MAKE_VEH_CLEAN), by = "CD_MAKE_VEH") %>%
  mutate(make_standard = coalesce(CD_MAKE_VEH_CLEAN, CD_MAKE_VEH))

transfer_timeseries <- transfer_clean %>%
  group_by(data_month_year) %>%
  summarise(total_transfers = sum(TOTAL, na.rm = TRUE), .groups = "drop") %>%
  arrange(data_month_year)

write_csv(transfer_timeseries, "outputs/CSVs/transfers_cleaned_timeseries.csv")

print("Complete")
print(head(transfer_timeseries))
