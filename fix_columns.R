library(dplyr)
library(tidyverse)

print("📥 Loading data...")
new_vehicles <- read_csv("Raw_Datasets/monthly_new_vehicle_registration_may2023_2026.csv")
transfer_vehicles <- read_csv("Raw_Datasets/monthly_vehicle_transfers_may2023_2026.csv")
make_mapping <- read_csv("Raw_Datasets/complete_vehicle_mapping.csv")

print("🔄 Renaming columns...")
transfer_vehicles <- transfer_vehicles %>%
  rename(
    data_month_year = month_year,
    CD_MAKE_VEH = CD_MAKE_VEH1,
    TOTAL = TOTAL1
  )

new_vehicles <- new_vehicles %>%
  rename(
    data_month_year = month_year
  )

print("✓ Column names fixed:")
print(names(transfer_vehicles))

print("\n✓ Ready! Now update Suhan's script with these column names")
