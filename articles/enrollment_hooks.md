# 10 Insights from Wisconsin School Enrollment Data

``` r
library(wischooldata)
library(dplyr)
library(tidyr)
library(ggplot2)

theme_set(theme_minimal(base_size = 14))
```

This vignette explores Wisconsin’s public school enrollment data,
surfacing key trends and demographic patterns across the Badger State’s
school system.

------------------------------------------------------------------------

## 1. Wisconsin educates nearly 850,000 students

Wisconsin public schools serve a substantial student population, with
enrollment spread across urban centers and rural dairy country alike.

``` r
enr <- fetch_enr_multi(2018:2025)

state_totals <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  mutate(change = n_students - lag(n_students),
         pct_change = round(change / lag(n_students) * 100, 2))

state_totals
```

``` r
ggplot(state_totals, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#C5050C") +
  geom_point(size = 3, color = "#C5050C") +
  scale_y_continuous(labels = scales::comma, limits = c(0, NA)) +
  labs(
    title = "Wisconsin Public School Enrollment (2018-2025)",
    subtitle = "Tracking enrollment trends across the Badger State",
    x = "School Year (ending)",
    y = "Total Enrollment"
  )
```

------------------------------------------------------------------------

## 2. Milwaukee dominates the enrollment landscape

Milwaukee Public Schools is by far the largest district, serving over
70,000 students—more than the next five districts combined.

``` r
enr_2025 <- fetch_enr(2025)

top_10 <- enr_2025 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  head(10) |>
  select(district_name, n_students)

top_10
```

``` r
top_10 |>
  mutate(district_name = forcats::fct_reorder(district_name, n_students)) |>
  ggplot(aes(x = n_students, y = district_name)) +
  geom_col(fill = "#C5050C") +
  scale_x_continuous(labels = scales::comma) +
  labs(
    title = "Wisconsin's 10 Largest School Districts (2025)",
    x = "Total Enrollment",
    y = NULL
  )
```

------------------------------------------------------------------------

## 3. Milwaukee’s demographics differ sharply from the state

Milwaukee Public Schools is majority Black and Hispanic, while the state
as a whole remains predominantly white—a stark urban-rural divide.

``` r
demographics <- enr_2025 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian", "multiracial", "native_american")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(subgroup, n_students, pct) |>
  arrange(desc(n_students))

demographics
```

``` r
demographics |>
  mutate(subgroup = forcats::fct_reorder(subgroup, n_students)) |>
  ggplot(aes(x = n_students, y = subgroup, fill = subgroup)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Wisconsin Student Demographics (2025)",
    subtitle = "Statewide racial/ethnic composition",
    x = "Number of Students",
    y = NULL
  )
```

------------------------------------------------------------------------

## 4. Wisconsin’s 12 CESAs organize regional services

Wisconsin divides into 12 Cooperative Educational Service Agencies
(CESAs) that provide support services to districts. Enrollment varies
widely by region.

``` r
cesa_totals <- enr_2025 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         !is.na(cesa)) |>
  group_by(cesa) |>
  summarize(
    n_districts = n_distinct(district_id),
    total_students = sum(n_students, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(total_students))

cesa_totals
```

``` r
cesa_totals |>
  mutate(cesa = forcats::fct_reorder(as.factor(cesa), total_students)) |>
  ggplot(aes(x = total_students, y = cesa)) +
  geom_col(fill = "#282728") +
  scale_x_continuous(labels = scales::comma) +
  labs(
    title = "Enrollment by CESA Region (2025)",
    subtitle = "Wisconsin's 12 Cooperative Educational Service Agencies",
    x = "Total Enrollment",
    y = "CESA"
  )
```

------------------------------------------------------------------------

## 5. Suburban Madison and Milwaukee are growing

While Milwaukee Public Schools has declined, suburban districts like
Waukesha, Elmbrook, and Madison Metropolitan have grown or held steady.

``` r
growth <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         end_year %in% c(2018, 2025)) |>
  group_by(district_id, district_name) |>
  filter(n() == 2) |>
  summarize(
    y2018 = n_students[end_year == 2018],
    y2025 = n_students[end_year == 2025],
    pct_change = round((y2025 / y2018 - 1) * 100, 1),
    .groups = "drop"
  ) |>
  filter(y2018 > 5000) |>
  arrange(desc(pct_change)) |>
  head(10)

growth
```

``` r
growth |>
  mutate(district_name = forcats::fct_reorder(district_name, pct_change)) |>
  ggplot(aes(x = pct_change, y = district_name, fill = pct_change > 0)) +
  geom_col(show.legend = FALSE) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40") +
  scale_fill_manual(values = c("TRUE" = "#0479A8", "FALSE" = "#C5050C")) +
  labs(
    title = "Enrollment Change in Large Districts (2018-2025)",
    subtitle = "Districts with 5,000+ students in 2018",
    x = "Percent Change",
    y = NULL
  )
```

------------------------------------------------------------------------

## 6. Milwaukee’s enrollment has declined significantly

Milwaukee Public Schools has lost thousands of students over the past
decade, driven by choice programs, charter schools, and population
shifts.

``` r
milwaukee <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Milwaukee", district_name, ignore.case = TRUE),
         !grepl("Suburban|Area", district_name, ignore.case = TRUE))

milwaukee_summary <- milwaukee |>
  select(end_year, district_name, n_students) |>
  arrange(district_name, end_year)

milwaukee_summary
```

------------------------------------------------------------------------

## 7. Wisconsin has a strong 4K (four-year-old kindergarten) program

Wisconsin’s 4K program enrolls tens of thousands of four-year-olds,
reflecting the state’s investment in early childhood education.

``` r
grade_breakdown <- enr_2025 |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("PK4", "PK", "K", "01", "09", "12")) |>
  select(grade_level, n_students) |>
  arrange(match(grade_level, c("PK4", "PK", "K", "01", "09", "12")))

grade_breakdown
```

------------------------------------------------------------------------

## 8. Rural dairy country districts are small but numerous

Wisconsin has hundreds of small rural districts, many in the state’s
famous dairy farming regions. Most have fewer than 1,000 students.

``` r
size_distribution <- enr_2025 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  mutate(size_category = case_when(
    n_students < 500 ~ "Under 500",
    n_students < 1000 ~ "500-999",
    n_students < 2500 ~ "1,000-2,499",
    n_students < 5000 ~ "2,500-4,999",
    n_students < 10000 ~ "5,000-9,999",
    TRUE ~ "10,000+"
  )) |>
  mutate(size_category = factor(size_category,
    levels = c("Under 500", "500-999", "1,000-2,499", "2,500-4,999", "5,000-9,999", "10,000+"))) |>
  count(size_category) |>
  mutate(pct = round(n / sum(n) * 100, 1))

size_distribution
```

------------------------------------------------------------------------

## 9. Green Bay anchors northeastern Wisconsin

Green Bay Area Public Schools is the largest district in northeastern
Wisconsin, serving the region’s industrial and shipping hub.

``` r
fox_valley <- enr_2025 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Green Bay|Appleton|Oshkosh|Fond du Lac", district_name, ignore.case = TRUE)) |>
  select(district_name, n_students) |>
  arrange(desc(n_students))

fox_valley
```

------------------------------------------------------------------------

## 10. Hispanic enrollment is growing statewide

Hispanic students are the fastest-growing demographic group in
Wisconsin, particularly in southeastern Wisconsin and agricultural
communities.

``` r
hispanic_trend <- enr |>
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic") |>
  select(end_year, n_students, pct) |>
  mutate(pct = round(pct * 100, 1))

hispanic_trend
```

------------------------------------------------------------------------

## Summary

Wisconsin’s school enrollment data reveals:

- **Urban-rural divide**: Milwaukee dominates enrollment but differs
  demographically from the rest of the state
- **Suburban growth**: Districts around Madison and Milwaukee are
  growing while the urban cores decline
- **Early childhood focus**: Wisconsin’s 4K program shows commitment to
  early education
- **Small district heritage**: Hundreds of tiny rural districts serve
  dairy country communities
- **Demographic change**: Hispanic enrollment is growing, reshaping the
  state’s student population

These patterns shape education policy across the Badger State.

------------------------------------------------------------------------

*Data sourced from the Wisconsin Department of Public Instruction.*
