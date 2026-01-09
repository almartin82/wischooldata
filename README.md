# wischooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/wischooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/wischooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/wischooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/wischooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/wischooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/wischooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/wischooldata/)** | [GitHub](https://github.com/almartin82/wischooldata)

Fetch and analyze Wisconsin school enrollment data from the Wisconsin Department of Public Instruction (DPI) in R or Python. **28 years of data** (1997-2024) for every school, district, and the state via WISEdash.

## What can you find with wischooldata?

Wisconsin educates students across 421 school districts, from the breweries of Milwaukee to the dairy farms of the Driftless. Explore enrollment trends, demographic patterns, and regional differences across 28 years of data (1997-2024).

For detailed insights and examples, see the [enrollment hooks vignette](https://almartin82.github.io/wischooldata/articles/enrollment_hooks.html).

---

## Enrollment Visualizations

<img src="https://almartin82.github.io/wischooldata/articles/enrollment_hooks_files/figure-html/statewide-chart-1.png" alt="Wisconsin statewide enrollment trends" width="600">

<img src="https://almartin82.github.io/wischooldata/articles/enrollment_hooks_files/figure-html/top-districts-chart-1.png" alt="Top Wisconsin districts" width="600">

See the [full vignette](https://almartin82.github.io/wischooldata/articles/enrollment_hooks.html) for more insights.

## Installation

```r
# install.packages("devtools")
devtools::install_github("almartin82/wischooldata")
```

## Quick Start

### R

```r
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

### Python

```python
import pywischooldata as wi

# Get 2024 enrollment data (2023-24 school year)
df = wi.fetch_enr(2024)

# Statewide total
state_total = df[(df['is_state']) &
                 (df['subgroup'] == 'total_enrollment') &
                 (df['grade_level'] == 'TOTAL')]['n_students'].values[0]
print(state_total)
#> 848567

# Top 5 districts
districts = df[(df['is_district']) &
               (df['subgroup'] == 'total_enrollment') &
               (df['grade_level'] == 'TOTAL')]
print(districts.nlargest(5, 'n_students')[['district_name', 'n_students']])
```

## Data Format

`fetch_enr()` returns tidy (long) format by default:

| Column | Description |
|--------|-------------|
| `end_year` | School year end (e.g., 2024 for 2023-24) |
| `district_id` | 4-digit district code |
| `campus_id` | School code (district-school) |
| `type` | "State", "District", or "Campus" |
| `district_name`, `campus_name` | Names |
| `cesa` | CESA region number |
| `grade_level` | "TOTAL", "PK", "PK4", "K", "01"..."12" |
| `subgroup` | Demographic/population group |
| `n_students` | Enrollment count |
| `pct` | Percentage of total |

### Subgroups Available

**Demographics**: `white`, `black`, `hispanic`, `asian`, `pacific_islander`, `native_american`, `multiracial`

**Populations**: `econ_disadv`, `lep`, `special_ed`

## Data Availability

| Era | Years | Source |
|-----|-------|--------|
| WINSS/Published | 1997-2005 | Published Excel files |
| WISEdash Early | 2006-2015 | Published Excel files |
| WISEdash Modern | 2016-2024 | WISEdash CSV downloads |

**28 years total** across ~2,200 schools and 421 districts.

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

Andy Martin (almartin@gmail.com)
[github.com/almartin82](https://github.com/almartin82)

## License

MIT
