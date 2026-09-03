library(dplyr)
library(tidyverse)
library(lubridate)
library(quantmod)
library(tidyr)
library(ggplot2)
library(scales)
library(gt)

# Import Data
new_vehicles <- read_csv("monthly_new.csv")


## Next part is just for car make for new registrations 

# View the data
head(new_vehicles)

# Group by the make and see total 
total_grouped_vehicles <- new_vehicles %>% 
  group_by(CD_MAKE_VEH) %>% 
  summarise(New_registrations = sum(TOTAL)) %>% 
  arrange(desc(New_registrations))

# Change the dates to actual usable values 
new_vehicles <- new_vehicles %>%
  mutate(data_month_year = as.Date(paste0(data_month_year, "01"), format = "%Y%m%d"))

# Now view the data
head(new_vehicles)

# Now lets group the vehicles into make and month -- top 10 of each month desc
rank_grouped_vehicles_month <- new_vehicles %>% 
  group_by(CD_MAKE_VEH, data_month_year) %>% 
  summarise(
    New_registrations = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>% 
  group_by(data_month_year) %>% 
  mutate(
    Rank = min_rank(desc(New_registrations))
  ) %>% 
  filter(Rank <= 10) %>% 
  ungroup() %>% 
  arrange(desc(data_month_year), Rank) %>% 
  select(Rank, CD_MAKE_VEH, data_month_year, New_registrations)

# Graphically 
ggplot(rank_grouped_vehicles_month, 
       aes(x = data_month_year, 
           y = New_registrations, 
           colour = CD_MAKE_VEH,
           group = CD_MAKE_VEH)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Top 10 Vehicle Makes by New Registrations",
    x = "Month",
    y = "New registrations",
    colour = "Make"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )


# Graphically - alternatively 

top_makes <- new_vehicles %>%
  group_by(CD_MAKE_VEH) %>%
  summarise(
    total = sum(TOTAL, na.rm = TRUE)
  ) %>%
  slice_max(total, n = 10) %>%
  pull(CD_MAKE_VEH)

graph_data <- new_vehicles %>%
  filter(CD_MAKE_VEH %in% top_makes) %>%
  group_by(CD_MAKE_VEH, data_month_year) %>%
  summarise(
    New_registrations = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  )

new_rego_trends <- ggplot(graph_data,
       aes(
         x = data_month_year,
         y = New_registrations,
         colour = CD_MAKE_VEH,
         group = CD_MAKE_VEH
       )) +
  geom_line(linewidth = 1) +
  labs(
    title = "New Vehicle Registrations",
    subtitle = "Monthly registrations for the 10 largest makes",
    x = "Month",
    y = "New registrations",
    colour = "Make"
  ) +
  theme_minimal()

ggsave("new_rego_trends.pdf", plot = last_plot(), path = getwd())

# Heat map 
ggplot(
  rank_grouped_vehicles_month,
  aes(
    x = data_month_year,
    y = reorder(CD_MAKE_VEH, New_registrations),
    fill = New_registrations
  )
) +
  geom_tile() +
  labs(
    title = "Top 10 Vehicle Makes by Month",
    subtitle = "Monthly new vehicle registrations",
    x = "Month",
    y = "Vehicle make",
    fill = "Registrations"
  ) +
  theme_minimal()


# More plotting 
grouped_vehicles_month <- new_vehicles %>% 
  group_by(CD_MAKE_VEH, data_month_year) %>% 
  summarise(
    New_registrations = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>% 
  group_by(data_month_year) %>% 
  mutate(
    Rank = rank(-New_registrations, ties.method = "min")
  ) %>% 
  filter(Rank <= 5) %>% 
  ungroup()

ggplot(
  grouped_vehicles_month,
  aes(
    x = data_month_year,
    y = Rank,
    colour = CD_MAKE_VEH,
    group = CD_MAKE_VEH
  )
) +
  geom_line(linewidth = 1) +
  geom_point() +
  scale_y_reverse(breaks = 1:10) +
  labs(
    title = "Top Vehicle Makes by Monthly Ranking",
    subtitle = "Rank based on new vehicle registrations",
    x = "Month",
    y = "Rank",
    colour = "Make"
  ) +
  theme_minimal()


## Now to include the car models 
make_and_model_group <- new_vehicles %>% 
  group_by(CD_MAKE_VEH, CD_MODEL_VEH, data_month_year) %>% 
  summarise(
    New_registrations = sum(TOTAL, na.rm = TRUE),
    .groups = "drop"
  ) %>% 
  group_by(data_month_year) %>% 
  mutate(
    Rank = min_rank(desc(New_registrations))
  ) %>% 
  filter(Rank <= 10) %>% 
  ungroup() %>% 
  arrange(desc(data_month_year), Rank) %>% 
  select(Rank, CD_MAKE_VEH, CD_MODEL_VEH, data_month_year, New_registrations)


# Graphing above 
model_rank_data <- make_and_model_group %>%
  arrange(data_month_year, Rank)

ggplot(
  model_rank_data,
  aes(
    x = data_month_year,
    y = Rank,
    colour = CD_MODEL_VEH,
    group = CD_MODEL_VEH
  )
) +
  geom_line(linewidth = 1) +
  geom_point() +
  scale_y_reverse(breaks = 1:10) +
  labs(
    title = "Top 10 Vehicle Models by Monthly Ranking",
    subtitle = "Rank based on new vehicle registrations",
    x = "Month",
    y = "Rank",
    colour = "Model"
  ) +
  theme_minimal()


# Latest month graphed 
latest_models <- make_and_model_group %>%
  filter(data_month_year == max(data_month_year)) %>%
  arrange(Rank)

ggplot(
  latest_models,
  aes(
    x = reorder(CD_MODEL_VEH, New_registrations),
    y = New_registrations
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top 10 Vehicle Models",
    subtitle = paste("New registrations —", max(latest_models$data_month_year)),
    x = "Model",
    y = "New registrations"
  ) +
  theme_minimal()





















