# Process WISEdash enrollment data (2016+)

WISEdash data is in long format with one row per school/grade/group
combination. This function pivots to wide format matching the standard
schema.

## Usage

``` r
process_wisedash_enr(df, end_year)
```

## Arguments

- df:

  Raw WISEdash data frame

- end_year:

  School year end

## Value

Processed data frame

## Details

The data structure has:

- GROUP_BY: Disability, Race/Ethnicity, Gender, Economic Status, EL
  Status, etc.

- GROUP_BY_VALUE: Specific values (e.g., "White", "Male", "Economically
  Disadvantaged")

- GROUP_COUNT: Total enrollment for the grade/school (used as
  denominator)

- STUDENT_COUNT: Count for the specific subgroup
