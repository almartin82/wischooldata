## ----setup, include=FALSE-----------------------------------------------------
# Skip execution during R CMD check / CI builds (no network access)
NOT_CRAN <- identical(Sys.getenv("NOT_CRAN"), "true")

knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  message = FALSE,
  warning = FALSE,
  fig.width = 8,
  fig.height = 5,
  eval = NOT_CRAN
)

## ----load-packages------------------------------------------------------------
# library(wischooldata)
# library(dplyr)
# library(tidyr)
# library(ggplot2)
# 
# theme_set(theme_minimal(base_size = 14))

## ----statewide-data-----------------------------------------------------------
# enr <- fetch_enr_multi(2018:2025)
# 
# state_totals <- enr |>
#   filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
#   select(end_year, n_students) |>
#   mutate(change = n_students - lag(n_students),
#          pct_change = round(change / lag(n_students) * 100, 2))
# 
# state_totals

## ----statewide-chart----------------------------------------------------------
# ggplot(state_totals, aes(x = end_year, y = n_students)) +
#   geom_line(linewidth = 1.2, color = "#C5050C") +
#   geom_point(size = 3, color = "#C5050C") +
#   scale_y_continuous(labels = scales::comma, limits = c(0, NA)) +
#   labs(
#     title = "Wisconsin Public School Enrollment (2018-2025)",
#     subtitle = "Tracking enrollment trends across the Badger State",
#     x = "School Year (ending)",
#     y = "Total Enrollment"
#   )

## ----top-districts-data-------------------------------------------------------
# enr_2025 <- fetch_enr(2025)
# 
# top_10 <- enr_2025 |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
#   arrange(desc(n_students)) |>
#   head(10) |>
#   select(district_name, n_students)
# 
# top_10

## ----top-districts-chart------------------------------------------------------
# top_10 |>
#   mutate(district_name = forcats::fct_reorder(district_name, n_students)) |>
#   ggplot(aes(x = n_students, y = district_name)) +
#   geom_col(fill = "#C5050C") +
#   scale_x_continuous(labels = scales::comma) +
#   labs(
#     title = "Wisconsin's 10 Largest School Districts (2025)",
#     x = "Total Enrollment",
#     y = NULL
#   )

## ----demographics-data--------------------------------------------------------
# demographics <- enr_2025 |>
#   filter(is_state, grade_level == "TOTAL",
#          subgroup %in% c("hispanic", "white", "black", "asian", "multiracial", "native_american")) |>
#   mutate(pct = round(pct * 100, 1)) |>
#   select(subgroup, n_students, pct) |>
#   arrange(desc(n_students))
# 
# demographics

## ----demographics-chart-------------------------------------------------------
# demographics |>
#   mutate(subgroup = forcats::fct_reorder(subgroup, n_students)) |>
#   ggplot(aes(x = n_students, y = subgroup, fill = subgroup)) +
#   geom_col(show.legend = FALSE) +
#   geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
#   scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
#   scale_fill_brewer(palette = "Set2") +
#   labs(
#     title = "Wisconsin Student Demographics (2025)",
#     subtitle = "Statewide racial/ethnic composition",
#     x = "Number of Students",
#     y = NULL
#   )

## ----regional-data------------------------------------------------------------
# cesa_totals <- enr_2025 |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
#          !is.na(cesa)) |>
#   group_by(cesa) |>
#   summarize(
#     n_districts = n_distinct(district_id),
#     total_students = sum(n_students, na.rm = TRUE),
#     .groups = "drop"
#   ) |>
#   arrange(desc(total_students))
# 
# cesa_totals

## ----regional-chart-----------------------------------------------------------
# cesa_totals |>
#   mutate(cesa = forcats::fct_reorder(as.factor(cesa), total_students)) |>
#   ggplot(aes(x = total_students, y = cesa)) +
#   geom_col(fill = "#282728") +
#   scale_x_continuous(labels = scales::comma) +
#   labs(
#     title = "Enrollment by CESA Region (2025)",
#     subtitle = "Wisconsin's 12 Cooperative Educational Service Agencies",
#     x = "Total Enrollment",
#     y = "CESA"
#   )

## ----growth-data--------------------------------------------------------------
# growth <- enr |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
#          end_year %in% c(2018, 2025)) |>
#   group_by(district_id, district_name) |>
#   filter(n() == 2) |>
#   summarize(
#     y2018 = n_students[end_year == 2018],
#     y2025 = n_students[end_year == 2025],
#     pct_change = round((y2025 / y2018 - 1) * 100, 1),
#     .groups = "drop"
#   ) |>
#   filter(y2018 > 5000) |>
#   arrange(desc(pct_change)) |>
#   head(10)
# 
# growth

## ----growth-chart-------------------------------------------------------------
# growth |>
#   mutate(district_name = forcats::fct_reorder(district_name, pct_change)) |>
#   ggplot(aes(x = pct_change, y = district_name, fill = pct_change > 0)) +
#   geom_col(show.legend = FALSE) +
#   geom_vline(xintercept = 0, linetype = "dashed", color = "gray40") +
#   scale_fill_manual(values = c("TRUE" = "#0479A8", "FALSE" = "#C5050C")) +
#   labs(
#     title = "Enrollment Change in Large Districts (2018-2025)",
#     subtitle = "Districts with 5,000+ students in 2018",
#     x = "Percent Change",
#     y = NULL
#   )

## ----milwaukee-trend----------------------------------------------------------
# milwaukee <- enr |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
#          grepl("Milwaukee", district_name, ignore.case = TRUE),
#          !grepl("Suburban|Area", district_name, ignore.case = TRUE))
# 
# milwaukee_summary <- milwaukee |>
#   select(end_year, district_name, n_students) |>
#   arrange(district_name, end_year)
# 
# milwaukee_summary

## ----four-k-------------------------------------------------------------------
# grade_breakdown <- enr_2025 |>
#   filter(is_state, subgroup == "total_enrollment",
#          grade_level %in% c("PK4", "PK", "K", "01", "09", "12")) |>
#   select(grade_level, n_students) |>
#   arrange(match(grade_level, c("PK4", "PK", "K", "01", "09", "12")))
# 
# grade_breakdown

## ----small-districts----------------------------------------------------------
# size_distribution <- enr_2025 |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
#   mutate(size_category = case_when(
#     n_students < 500 ~ "Under 500",
#     n_students < 1000 ~ "500-999",
#     n_students < 2500 ~ "1,000-2,499",
#     n_students < 5000 ~ "2,500-4,999",
#     n_students < 10000 ~ "5,000-9,999",
#     TRUE ~ "10,000+"
#   )) |>
#   mutate(size_category = factor(size_category,
#     levels = c("Under 500", "500-999", "1,000-2,499", "2,500-4,999", "5,000-9,999", "10,000+"))) |>
#   count(size_category) |>
#   mutate(pct = round(n / sum(n) * 100, 1))
# 
# size_distribution

## ----green-bay----------------------------------------------------------------
# fox_valley <- enr_2025 |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
#          grepl("Green Bay|Appleton|Oshkosh|Fond du Lac", district_name, ignore.case = TRUE)) |>
#   select(district_name, n_students) |>
#   arrange(desc(n_students))
# 
# fox_valley

## ----hispanic-growth----------------------------------------------------------
# hispanic_trend <- enr |>
#   filter(is_state, grade_level == "TOTAL", subgroup == "hispanic") |>
#   select(end_year, n_students, pct) |>
#   mutate(pct = round(pct * 100, 1))
# 
# hispanic_trend

