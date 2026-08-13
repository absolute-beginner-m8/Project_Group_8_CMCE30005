library(dplyr)
library(tidyverse)
library(janitor)  
library(lubridate)  
library(recipes)     
library(kableExtra)
library(stargazer)
library(AER)
library(scales)

# Import Data
listing_airbnb <- read.csv("AirBnb_files/listings_airbnb.csv")
calender_airbnb <- read.csv("AirBnb_files/calendar_airbnb.csv")
reviews_airbnb <- read.csv("AirBnb_files/reviews_airbnb.csv")
