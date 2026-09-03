library(dplyr)
library(tidyverse)
library(lubridate)
library(quantmod)
library(tidyr)
library(ggplot2)
library(scales)
library(gt)


# Import Data
transfer_vehicles <- read_csv("monthly_transfers.csv")

# View the data 
head(transfer_vehicles)

# Count how many NA vehicle models there are
sum(is.na(transfer_vehicles$CD_MODEL_VEH)) ## We have 8425 NA models

transfer_vehicles %>% 
  filter(TOTAL < 5) %>% 
  summarise(na_count = sum(is.na(CD_MODEL_VEH))) ## 8265 NA models have a total of less than 5

# Group by the vehicles with NA values and their make and year 
na_values <- transfer_vehicles %>% 
  filter(is.na(CD_MODEL_VEH)) %>% 
  group_by(CD_MAKE_VEH, NB_YEAR_MFC_VEH) %>% 
  summarise(na_count = n()) %>% 
  arrange(desc(na_count))

# Count how many NA vehicles makes there are
sum(is.na(transfer_vehicles$CD_MAKE_VEH)) ## There are 0 -- clean data sets



















