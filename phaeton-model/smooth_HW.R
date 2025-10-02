setwd("C:/Users/mvink/Documents/Git_repos/RespiCast-Covid19")

library(tidyverse)
library(tidyquant)
library(timetk)
library(sweep)
library(forecast)

####### Get current forecast info
fc_info <- read.csv("supporting-files/forecasting_weeks.csv") %>%
  filter(is_latest == "True") %>%
  mutate(origin_date = as.Date(origin_date, format = "%Y-%m-%d"),
         target_end_date = as.Date(target_end_date, format = "%Y-%m-%d"))






data <- read.csv("target-data/latest-hospital_admissions.csv") %>%
  mutate(location = as.factor(location),
         truth_date = as.Date(truth_date, format="%Y-%m-%d"))

# Remove locations with too few observations
min_obs = 104

data_nest <- data %>%
  filter(! location %in% names(which(table(data$location) < min_obs))) %>%
  group_by(location) %>%
  nest()

# Visualize
ggplot(data, aes(x = truth_date, y = value, group = location)) +
  geom_line(aes(color = location), size = 0.75) +
  geom_point(aes(color = location), size = 2) +
  labs(title = "Weekly covid cases") +
  theme_minimal()

# Create time series per location
data_ts <- data_nest %>%
  mutate(data.ts = map(.x = data,
                       .f = tk_ts,
                       select = value,
                       start = c(2021, 06, 27),
                       freq = 52))

# Smooth time series using HoltWinters
data_fit <- data_ts %>%
  mutate(fit.HoltWinters = map(.x = data.ts,
                               .f = HoltWinters))

tidydata <- data_fit %>%
  mutate(tidy = map(fit.HoltWinters, sw_tidy)) %>%
  unnest(tidy) %>%
  spread(key = location, value = estimate)

# Error metrics for fitted estimates
glancedata <- data_fit %>%
  mutate(glance = map(fit.HoltWinters, sw_glance)) %>%
  unnest(glance) %>%
  select(c(1, 5,6,10:16))

augmentdata <- data_fit %>%
  mutate(augment = map(fit.HoltWinters, 
                       sw_augment, 
                       timetk_idx = TRUE, 
                       rename_index = "date")) %>%
  unnest(augment)

# Visualize residuals
augmentdata %>%
  ggplot(aes(x = date, y = .resid, group = location)) +
  geom_hline(yintercept = 0, color = "grey40") +
  geom_line(color = palette_light()[[2]]) +
  geom_smooth(method = "loess") +
  labs(title = "Covid cases by location",
       subtitle = "HoltWinters model residuals", x = "") +
  theme_minimal() +
  facet_wrap( ~location, scale = "free_y", ncol = 4) + 
  scale_x_date(date_labels = "%Y")


# Forecasting
data_fc <- data_fit %>%
  mutate(forecast.HoltWinters = map(fit.HoltWinters, forecast, h=12))

data_fc_tidy <- data_fc %>%
  mutate(sweep = map(forecast.HoltWinters, sw_sweep, timetk_idx = TRUE)) %>%
  unnest(sweep)

# Visualize forecasts
data_fc_tidy %>%
  ggplot(aes(x = index, y = value, color = key, group = location)) +
  geom_ribbon(aes(ymin = lo.95, ymax = hi.95), 
              fill = "#D5DBFF", color = NA, size = 0) +
  geom_ribbon(aes(ymin = lo.80, ymax = hi.80, fill = key), 
              fill = "#596DD5", color = NA, size = 0, alpha = 0.8) +
  geom_line() +
  labs(title = "Covid cases by location",
       subtitle = "HoltWinters model forecasts",
       x = "", y = "Units") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  facet_wrap(~ location, scales = "free_y", ncol = 3) +
  theme_tq() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Save forecast predictions
forecasts <- data_fc_tidy %>%
  filter(key == "forecast") %>%
  select(location, index, value, lo.95, hi.95) %>%
  rename(target_end_date = index) %>%
  filter(target_end_date %in% fc_info$target_end_date) %>%
  mutate(origin_date = fc_info[1, "origin_date"],
         target = "hospital admissions") %>%
  select(target, location, origin_date, target_end_date, value, lo.95, hi.95) 

forecasts_long <- forecasts %>%
  pivot_longer(cols = c("value", "lo.95", "hi.95"),
               names_to = "output_type_id",
               values_to = "value") %>%
  mutate(output_type = ifelse(output_type_id == "value", "median", "quantile"),
         output_type_id = case_when(
           output_type_id == "value" ~ NA,
           output_type_id == "lo.95" ~ 0.05,
           output_type_id == "hi.95" ~ 0.95
         )) %>%
  left_join(fc_info[c("target_end_date", "horizon")],
            by = join_by(target_end_date))


