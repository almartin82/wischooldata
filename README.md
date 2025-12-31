# wischooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/wischooldata/workflows/R-CMD-check/badge.svg)](https://github.com/almartin82/wischooldata/actions)
<!-- badges: end -->

An R package for fetching and analyzing Wisconsin public school enrollment data from the Wisconsin Department of Public Instruction (DPI).

## Installation

```r
# Install from GitHub
# install.packages("devtools")
devtools::install_github("almartin82/wischooldata")
```

## Quick Start

```r
library(wischooldata)

# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# Get wide format (one row per school)
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2024)

# Filter to state totals
state_totals <- enr_2024 %>%
  dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")
```

## Data Availability

### Years Available

| Era | Years | Source | Notes |
|-----|-------|--------|-------|
| WINSS/Published | 1997-2005 | Published Excel files | Historical data |
| WISEdash Early | 2006-2015 | Published Excel files | Transition period |
| WISEdash Modern | 2016-present | WISEdash CSV downloads | Current system |

**Total coverage: 1997 to present (28+ years)**

### Data Sources

- **WISEdash Data Files**: https://dpi.wi.gov/wisedash/download-files
- **Published Enrollment Data**: https://dpi.wi.gov/cst/published-enrollment-data
- **WINSS Historical Files**: https://dpi.wi.gov/wisedash/download-files/winss-historical

### Available Demographics

| Demographic | 1997-2009 | 2010-2015 | 2016+ |
|-------------|-----------|-----------|-------|
| Total Enrollment | Yes | Yes | Yes |
| By Grade (PK-12) | Yes | Yes | Yes |
| White | Yes | Yes | Yes |
| Black | Yes | Yes | Yes |
| Hispanic | Yes | Yes | Yes |
| Asian | Combined* | Yes | Yes |
| Pacific Islander | Combined* | Yes | Yes |
| American Indian | Yes | Yes | Yes |
| Two or More Races | No | Yes | Yes |
| Male/Female | Yes | Yes | Yes |
| Economically Disadvantaged | Varies | Yes | Yes |
| English Learners | Varies | Yes | Yes |
| Students with Disabilities | Varies | Yes | Yes |

\* Asian and Pacific Islander combined before 2010

### Wisconsin ID System

Wisconsin uses a hierarchical identifier system:

- **District Code**: 4 digits (e.g., "3269" for Madison Metropolitan School District)
- **School Code**: District + School number (e.g., "3269-0280")
- **CESA**: Cooperative Educational Service Agency (12 regions in Wisconsin)

### Key Districts

| District | Code | 2023 Enrollment |
|----------|------|-----------------|
| Milwaukee | 3619 | ~70,000 |
| Madison Metropolitan | 3269 | ~27,000 |
| Green Bay Area | 2415 | ~20,000 |
| Kenosha | 2289 | ~20,000 |
| Racine | 4620 | ~18,000 |

## Output Schema

### Wide Format (`tidy = FALSE`)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end (2024 = 2023-24) |
| type | character | "State", "District", or "Campus" |
| district_id | character | 4-digit district code |
| campus_id | character | School code (NA for districts) |
| district_name | character | District name |
| campus_name | character | School name (NA for districts) |
| county | character | County name |
| cesa | character | CESA region number |
| charter_flag | character | Charter indicator |
| row_total | integer | Total enrollment |
| white, black, hispanic, asian, native_american, pacific_islander, multiracial | integer | Race/ethnicity counts |
| male, female | integer | Gender counts |
| econ_disadv, lep, special_ed | integer | Special population counts |
| grade_pk | integer | Pre-Kindergarten enrollment (includes K3) |
| grade_pk4 | integer | 4-Year-Old Kindergarten (4K) enrollment |
| grade_k through grade_12 | integer | Grade-level enrollment |

### Tidy Format (`tidy = TRUE`, default)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end |
| type | character | Aggregation level |
| district_id | character | District code |
| campus_id | character | School code |
| district_name | character | District name |
| campus_name | character | School name |
| grade_level | character | "TOTAL", "PK", "PK4", "K", "01"-"12" |
| subgroup | character | "total_enrollment", demographic name |
| n_students | integer | Student count |
| pct | numeric | Percentage (0-1 scale) |
| is_state | logical | State-level row |
| is_district | logical | District-level row |
| is_campus | logical | Campus-level row |
| is_charter | logical | Charter school |

## Known Caveats

1. **Asian/Pacific Islander**: Combined into single category before 2010-11
2. **Two or More Races**: Not available before 2010-11
3. **Economic Disadvantage**: Definition and collection methods vary by year
4. **Small Cell Suppression**: Counts <5 may be suppressed for privacy
5. **Charter Schools**: Reporting methods have evolved over time
6. **4K Programs**: Wisconsin's 4-Year-Old Kindergarten (4K) enrollment is reported separately as grade_pk4/PK4
7. **K3 Programs**: 3-Year-Old Kindergarten programs are combined with Pre-K in grade_pk

## Related Packages

This package is part of a family of state school data packages:

- [txschooldata](https://github.com/almartin82/txschooldata) - Texas
- [ilschooldata](https://github.com/almartin82/ilschooldata) - Illinois
- [nyschooldata](https://github.com/almartin82/nyschooldata) - New York
- [paschooldata](https://github.com/almartin82/paschooldata) - Pennsylvania
- [ohschooldata](https://github.com/almartin82/ohschooldata) - Ohio
- [caschooldata](https://github.com/almartin82/caschooldata) - California

## License
MIT
