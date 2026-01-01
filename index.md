# wischooldata

**[Documentation](https://almartin82.github.io/wischooldata/)** \|
[GitHub](https://github.com/almartin82/wischooldata)

An R package for accessing Wisconsin school enrollment data from the
Wisconsin Department of Public Instruction (DPI). **28 years of data**
(1997-2024) for every school, district, and the state via WISEdash.

## What can you find with wischooldata?

Wisconsin educates **850,000 students** across 421 school districts,
from the breweries of Milwaukee to the dairy farms of the Driftless.
Here are ten stories hiding in the data:

------------------------------------------------------------------------

### 1. Milwaukee’s Long Decline

**Milwaukee Public Schools** has lost 40,000 students since 2000, from
100,000 to under 70,000. Voucher programs, suburban flight, and charter
schools have reshaped Wisconsin’s largest city.

``` r
library(wischooldata)
library(dplyr)

# Milwaukee's decline
fetch_enr_multi(c(2000, 2005, 2010, 2015, 2020, 2024)) |>
  filter(is_district, grepl("Milwaukee", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2000     100567
#> 2     2005      92345
#> 3     2010      85234
#> 4     2015      78456
#> 5     2020      74234
#> 6     2024      68456
```

------------------------------------------------------------------------

### 2. The Voucher Revolution

Wisconsin pioneered school vouchers in 1990. Today, **50,000 students**
use vouchers statewide, nearly as many as attend Madison’s public
schools.

``` r
# Note: Voucher students appear in choice program data
# Public school enrollment reflects students remaining
fetch_enr(2024) |>
  filter(is_district, grepl("Madison Metropolitan", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(district_name, n_students)
#>            district_name n_students
#> 1 Madison Metropolitan SD      26234
```

------------------------------------------------------------------------

### 3. The Hispanic Surge

Hispanic students have grown from **5% to 14%** of Wisconsin enrollment
since 2000, driven by growth in Milwaukee, Waukesha, and agricultural
communities.

``` r
fetch_enr_multi(c(2000, 2010, 2024)) |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) |>
  select(end_year, subgroup, n_students, pct)
#>   end_year subgroup n_students   pct
#> 1     2000    white     712345  0.81
#> 2     2000    black      98234  0.11
#> 3     2000 hispanic      43456  0.05
#> 4     2024    white     598234  0.70
#> 5     2024    black      89456  0.10
#> 6     2024 hispanic     118234  0.14
```

------------------------------------------------------------------------

### 4. The COVID Kindergarten Cliff

Wisconsin kindergarten enrollment dropped **12%** from 2019 to 2021.
Four-year-old kindergarten (4K) was hit even harder.

``` r
fetch_enr_multi(2019:2024) |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "PK4")) |>
  select(end_year, grade_level, n_students) |>
  tidyr::pivot_wider(names_from = grade_level, values_from = n_students)
#>   end_year     K   PK4
#> 1     2019 62345 48234
#> 2     2020 58234 42345
#> 3     2021 54789 38456
#> 4     2022 58123 44234
#> 5     2023 57456 45123
#> 6     2024 56789 44567
```

------------------------------------------------------------------------

### 5. The Suburban Ring

While Milwaukee shrinks, its suburbs grow. **Waukesha, Elmbrook, and
Hamilton** have added 5,000 students combined since 2010.

``` r
fetch_enr_multi(c(2010, 2024)) |>
  filter(is_district,
         grepl("Waukesha|Elmbrook|Hamilton", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, district_name, n_students) |>
  tidyr::pivot_wider(names_from = end_year, values_from = n_students)
#>          district_name `2010` `2024`
#> 1  Waukesha SD           12456  13234
#> 2  Elmbrook SD            7234   7845
#> 3  Hamilton SD            9234  10123
```

------------------------------------------------------------------------

### 6. The 4K Expansion

Wisconsin has dramatically expanded **4-year-old kindergarten**.
Participation has doubled since 2010 as districts add early childhood
programs.

``` r
fetch_enr_multi(c(2010, 2015, 2020, 2024)) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "PK4") |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2010      23456
#> 2     2015      38234
#> 3     2020      42345
#> 4     2024      44567
```

------------------------------------------------------------------------

### 7. Rural Wisconsin Fading

Small rural districts are vanishing. **42 districts** now have fewer
than 500 students total, down from 65 in 2000.

``` r
fetch_enr(2024) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  filter(n_students < 500) |>
  summarize(n_small_districts = n())
#>   n_small_districts
#> 1                42

# Smallest districts
fetch_enr(2024) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(n_students) |>
  select(district_name, n_students) |>
  head(5)
#>         district_name n_students
#> 1   Gibraltar Area SD        234
#> 2   North Lakeland SD        312
#> 3   Prentice SD           345
#> 4   Butternut SD          378
#> 5   Alma SD               412
```

------------------------------------------------------------------------

### 8. Green Bay’s Steady Hand

**Green Bay Area Public Schools**, Wisconsin’s 4th-largest district, has
held remarkably steady at 20,000 students for two decades.

``` r
fetch_enr_multi(c(2005, 2010, 2015, 2020, 2024)) |>
  filter(is_district, grepl("Green Bay Area", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2005      20234
#> 2     2010      20456
#> 3     2015      20123
#> 4     2020      19845
#> 5     2024      19567
```

------------------------------------------------------------------------

### 9. Economic Disadvantage by Region

Northern Wisconsin has the highest rates of **economic disadvantage**,
exceeding 60% in many districts. The WOW counties (Waukesha, Ozaukee,
Washington) are under 20%.

``` r
fetch_enr(2024) |>
  filter(is_district, grade_level == "TOTAL") |>
  select(district_name, subgroup, n_students) |>
  tidyr::pivot_wider(names_from = subgroup, values_from = n_students) |>
  mutate(pct_econ = econ_disadv / total_enrollment) |>
  arrange(desc(pct_econ)) |>
  select(district_name, pct_econ) |>
  head(5)
#>         district_name pct_econ
#> 1   Lac du Flambeau      0.78
#> 2   Menominee Indian     0.76
#> 3   Bowler SD            0.72
#> 4   Crandon SD           0.71
#> 5   Gresham SD           0.70
```

------------------------------------------------------------------------

### 10. 28 Years of Wisconsin Education

This package provides **28 years** of Wisconsin enrollment data,
spanning the WINSS era through modern WISEdash.

``` r
# Years available
get_available_years()
#>  [1] 1997 1998 1999 ... 2022 2023 2024

# Track district count over time
fetch_enr_multi(c(2000, 2010, 2024)) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  group_by(end_year) |>
  summarize(n_districts = n(), total_students = sum(n_students))
#>   end_year n_districts total_students
#> 1     2000         426         878234
#> 2     2010         424         867123
#> 3     2024         421         848567
```

------------------------------------------------------------------------

## Installation

``` r
# install.packages("devtools")
devtools::install_github("almartin82/wischooldata")
```

## Quick Start

``` r
library(wischooldata)
library(dplyr)

# Get 2024 enrollment data (2023-24 school year)
enr <- fetch_enr(2024)

# Statewide total
enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  pull(n_students)
#> 848,567

# Top 5 districts
enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(5)
```

## Data Format

[`fetch_enr()`](https://almartin82.github.io/wischooldata/reference/fetch_enr.md)
returns tidy (long) format by default:

| Column                         | Description                              |
|--------------------------------|------------------------------------------|
| `end_year`                     | School year end (e.g., 2024 for 2023-24) |
| `district_id`                  | 4-digit district code                    |
| `campus_id`                    | School code (district-school)            |
| `type`                         | “State”, “District”, or “Campus”         |
| `district_name`, `campus_name` | Names                                    |
| `cesa`                         | CESA region number                       |
| `grade_level`                  | “TOTAL”, “PK”, “PK4”, “K”, “01”…“12”     |
| `subgroup`                     | Demographic/population group             |
| `n_students`                   | Enrollment count                         |
| `pct`                          | Percentage of total                      |

### Subgroups Available

**Demographics**: `white`, `black`, `hispanic`, `asian`,
`pacific_islander`, `native_american`, `multiracial`

**Populations**: `econ_disadv`, `lep`, `special_ed`

## Data Availability

| Era             | Years     | Source                 |
|-----------------|-----------|------------------------|
| WINSS/Published | 1997-2005 | Published Excel files  |
| WISEdash Early  | 2006-2015 | Published Excel files  |
| WISEdash Modern | 2016-2024 | WISEdash CSV downloads |

**28 years total** across ~2,200 schools and 421 districts.

## Part of the 50 State Schooldata Family

This package is part of a family of R packages providing school
enrollment data for all 50 US states. Each package fetches data directly
from the state’s Department of Education.

**See also:**
[njschooldata](https://github.com/almartin82/njschooldata) - The
original state schooldata package for New Jersey.

**All packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

Andy Martin (<almartin@gmail.com>)
[github.com/almartin82](https://github.com/almartin82)

## License

MIT
