# Wisconsin School Data Expansion Research

**Last Updated:** 2026-01-04 **Theme Researched:** Graduation Rates

## Data Sources Found

### Source 1: WISEdash High School Completion (2010-2024) - PRIMARY

- **URL Pattern:**
  `https://dpi.wi.gov/sites/default/files/wise/downloads/hs_completion_certified_{YYYY-YY}.zip`
- **HTTP Status:** All return 200
- **Format:** ZIP containing CSV file + layout file + disclaimer
- **Years Available:** 2009-10 through 2023-24 (15 years)
- **Access:** Direct download, no auth required
- **Update Frequency:** Annual (certified data released ~March following
  school year)

### Source 2: Legacy Rates (2008-2012)

- **URL Pattern:**
  `https://dpi.wi.gov/sites/default/files/wise/downloads/hs_completion_legacy_rates_certified_{YYYY-YY}.zip`
- **HTTP Status:** 200 for 2007-08 through 2011-12
- **Format:** ZIP containing CSV file
- **Years Available:** 2007-08 through 2011-12 (5 years, overlaps with
  WISEdash)
- **Note:** Uses different methodology (“legacy rates by age 21” vs
  “adjusted cohort rates”)

### Source 3: Historical Statewide (1970-2003)

- **URL:**
  `https://dpi.wi.gov/sites/default/files/wise/downloads/statewide_graduation_rates_1969-70_to_2002-03.zip`
- **HTTP Status:** 200
- **Format:** ZIP containing Excel file (grdrtwis.xls)
- **Years Available:** 1969-70 through 2002-03
- **Note:** Statewide aggregates only, no district/school breakdowns

## URL Verification Summary

| Year Range | File Pattern                        | HTTP Status |
|------------|-------------------------------------|-------------|
| 2023-24    | hs_completion_certified_2023-24.zip | 200         |
| 2022-23    | hs_completion_certified_2022-23.zip | 200         |
| 2021-22    | hs_completion_certified_2021-22.zip | 200         |
| 2020-21    | hs_completion_certified_2020-21.zip | 200         |
| 2019-20    | hs_completion_certified_2019-20.zip | 200         |
| 2018-19    | hs_completion_certified_2018-19.zip | 200         |
| 2017-18    | hs_completion_certified_2017-18.zip | 200         |
| 2016-17    | hs_completion_certified_2016-17.zip | 200         |
| 2015-16    | hs_completion_certified_2015-16.zip | 200         |
| 2014-15    | hs_completion_certified_2014-15.zip | 200         |
| 2013-14    | hs_completion_certified_2013-14.zip | 200         |
| 2012-13    | hs_completion_certified_2012-13.zip | 200         |
| 2011-12    | hs_completion_certified_2011-12.zip | 200         |
| 2010-11    | hs_completion_certified_2010-11.zip | 200         |
| 2009-10    | hs_completion_certified_2009-10.zip | 200         |

## Schema Analysis

### Column Names (Consistent 2009-2024)

| Column            | Description            | Example Value                                              |
|-------------------|------------------------|------------------------------------------------------------|
| SCHOOL_YEAR       | School year            | “2023-24”                                                  |
| AGENCY_TYPE       | Entity type            | “School District”, “Public school”                         |
| CHARTER_IND       | Charter indicator      | “Yes”, “No”                                                |
| CESA              | CESA region code       | “01” through “12”                                          |
| COUNTY            | County name            | “Milwaukee”, “Dane”                                        |
| DISTRICT_CODE     | 4-digit district code  | “3619” (Milwaukee)                                         |
| SCHOOL_CODE       | 4-digit school code    | “0413”, “” for district-level                              |
| GRADE_GROUP       | School grade group     | “\[All\]”, “High School”                                   |
| DISTRICT_NAME     | District name          | “Milwaukee”                                                |
| SCHOOL_NAME       | School name            | “\[Districtwide\]”, “East High”                            |
| COHORT            | Cohort graduation year | “2024”                                                     |
| COMPLETION_STATUS | Completion outcome     | See below                                                  |
| GROUP_BY          | Subgroup category      | “All Students”, “Gender”, “Race/Ethnicity”                 |
| GROUP_BY_VALUE    | Subgroup value         | “Female”, “Hispanic”, “EL”                                 |
| TIMEFRAME         | Rate timeframe         | “4-Year rate”, “5-Year rate”, “6-Year rate”, “7-Year rate” |
| COHORT_COUNT      | Total in cohort        | “65585”                                                    |
| STUDENT_COUNT     | Count in this status   | “59716”                                                    |

### Schema Changes Noted

#### COMPLETION_STATUS Values

**2016-17 to 2023-24 (Current Format):** - Completed - Regular High
School Diploma - Completed - High School Equivalency Diploma -
Completed - Other High School Completion Credential - Not Completed -
Continuing Toward Completion - Not Completed - Not Continuing - Not
Completed - Not Known to be Continuing Toward Completion - Not
Completed - Reached Maximum Age - `*` (suppressed)

**2009-10 to 2015-16 (Legacy Format):** - Completed - Regular -
Completed - HSED - Completed - Other - Not Completed - Continuing - Not
Completed - Not Continuing - Not Completed - Max Age - `*` (suppressed)

#### Subgroup Changes

| Subgroup          | Pre-2019 Value           | 2019+ Value        |
|-------------------|--------------------------|--------------------|
| English Learner   | “ELL Status” / “ELL/LEP” | “EL Status” / “EL” |
| Gender Non-binary | Not available            | Added 2022-23      |
| Pacific Islander  | Not separate pre-2010    | Separate 2010+     |
| Two or More Races | Not available pre-2010   | Added 2010+        |

### ID System

- **District Code:** 4 digits, left-padded with zeros (e.g., “0007”,
  “3619”)
- **School Code:** 4 digits within district, “0000” or empty for
  district-level
- **Statewide:** District Code = “0000”, School Code = “”
- **CESA Regions:** 01-12 (Cooperative Educational Service Agencies)

### Known Data Issues

1.  **2015-16 Data Errors:** DPI acknowledges uncorrected errors in
    2015-16 graduation data (per WISEdash documentation)
2.  **Suppressed Values:** `*` indicates suppressed due to small cell
    size (\<5 students)
3.  **Non-binary Gender:** Only available 2022-23+
4.  **Methodology Difference:** WISEdash uses “adjusted cohort rates” vs
    legacy “by age 21” - rates not directly comparable

## Time Series Heuristics

### Statewide Benchmarks

| Year    | Cohort Size | 4-Yr Graduates | Grad Rate |
|---------|-------------|----------------|-----------|
| 2009-10 | 72,059      | 61,736         | 85.6%     |
| 2012-13 | 66,808      | 58,778         | 87.9%     |
| 2015-16 | 63,270      | 55,826         | 88.2%     |
| 2018-19 | 66,051      | 59,466         | 90.0%     |
| 2021-22 | 65,906      | 59,519         | 90.3%     |
| 2023-24 | 65,585      | 59,716         | 91.0%     |

### Expected Ranges

| Metric            | Expected Range  | Red Flag If          |
|-------------------|-----------------|----------------------|
| Statewide cohort  | 63,000 - 73,000 | \<60,000 or \>75,000 |
| 4-year grad rate  | 85% - 92%       | \<80% or \>95%       |
| District count    | 380 - 400       | \<370 or \>410       |
| YoY cohort change | +/- 5%          | \>10% change         |
| YoY rate change   | +/- 2%          | \>5% change          |

### Major Districts for Validation

| District             | Code | 2023-24 Cohort | Typical Cohort Range |
|----------------------|------|----------------|----------------------|
| Milwaukee            | 3619 | 5,182          | 5,000 - 6,000        |
| Madison Metropolitan | 3269 | 1,944          | 1,800 - 2,200        |
| Green Bay Area       | 2289 | 1,100+         | 1,000 - 1,300        |
| Appleton Area        | 0147 | 900+           | 800 - 1,100          |

## Recommended Implementation

### Priority: HIGH

- Graduation rates are core education accountability data
- Data is clean, well-structured, and consistent
- Complements existing enrollment data

### Complexity: MEDIUM

- Schema is consistent (minor value changes)
- Multiple timeframes (4/5/6/7-year rates)
- Multiple completion statuses
- Subgroup handling needs normalization

### Estimated Files to Create/Modify:

1.  `R/get_raw_graduation.R` - Download and parse raw data
2.  `R/process_graduation.R` - Standardize schema across years
3.  `R/tidy_graduation.R` - Transform to long format
4.  `R/fetch_graduation.R` - Main user-facing function
5.  `tests/testthat/test-pipeline-graduation.R` - Live tests
6.  `tests/testthat/test-graduation-fidelity.R` - Raw data fidelity
    tests

### Implementation Steps:

1.  Create `get_raw_grad()` to download ZIP and parse CSV
2.  Create `process_grad()` to normalize COMPLETION_STATUS values across
    eras
3.  Create `tidy_grad()` to pivot to long format with subgroups
4.  Create `fetch_grad()` as main entry point
5.  Add `get_available_grad_years()` utility
6.  Write comprehensive tests

### Tidy Output Schema (Proposed)

``` r
# Each row represents one subgroup within one timeframe at one entity
tibble(
  end_year,           # int: School year end (e.g., 2024)
  type,               # chr: "State", "District", "Campus"
  district_id,        # chr: 4-digit district code
  campus_id,          # chr: 4-digit school code (NA for district)
  district_name,      # chr: District name
  campus_name,        # chr: School name or NA
  county,             # chr: County name
  cesa,               # chr: CESA region code
  charter_flag,       # chr: "Yes"/"No"
  cohort_year,        # int: Expected graduation year
  timeframe,          # chr: "4-Year", "5-Year", "6-Year", "7-Year"
  completion_status,  # chr: Standardized status
  subgroup,           # chr: "all", "male", "female", "white", etc.
  cohort_n,           # int: Cohort count
  n_students,         # int: Students in this status
  rate                # dbl: n_students / cohort_n
)
```

## Test Requirements

### Raw Data Fidelity Tests Needed

``` r
# 2023-24 Statewide
expect_equal(cohort_n, 65585)  # Statewide, 4-Year, All Students
expect_equal(regular_diploma_n, 59716)

# 2023-24 Milwaukee District
expect_equal(cohort_n, 5182)   # Milwaukee, 4-Year, All Students
expect_equal(regular_diploma_n, 3521)

# 2023-24 Madison Metropolitan
expect_equal(cohort_n, 1944)   # Madison, 4-Year, All Students
expect_equal(regular_diploma_n, 1633)

# 2015-16 Statewide (legacy format test)
expect_equal(cohort_n, 63270)
expect_equal(regular_diploma_n, 55826)
```

### Data Quality Checks

1.  **Rate bounds:** All rates should be 0-1 (or 0-100 if percent)
2.  **Cohort consistency:** Cohort count should match sum of all
    completion statuses
3.  **No negative values:** All counts \>= 0
4.  **No Inf/NaN:** Division by zero handled
5.  **Suppression handling:** `*` values converted to NA, not 0

### Cross-Year Consistency Tests

``` r
# Statewide cohort should be in expected range
expect_true(cohort_n >= 63000 & cohort_n <= 73000)

# 4-year graduation rate should be 85-92%
expect_true(grad_rate >= 0.85 & grad_rate <= 0.92)

# District count should be ~390
district_count <- length(unique(data$district_id))
expect_true(district_count >= 380 & district_count <= 400)
```

## Additional Notes

### Attendance/Dropout Data

- Also available at `attendance_dropouts_certified_{YYYY-YY}.zip`
- Could complement graduation rates
- Separate expansion opportunity

### Private School Graduation

- Available at `private_graduates_certified_{YYYY-YY}.zip`
- Back to 1996-97
- Separate data structure, could be future expansion

### API Access

- WISEdash is dashboard-only (no public API)
- Direct file downloads are the correct approach
