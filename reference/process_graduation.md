# Process Raw Graduation Data

Processes raw WI DPI data into standardized format. Filters to regular
high school diplomas and converts data types.

## Usage

``` r
process_graduation(raw_data, end_year, timeframe = "4-Year rate")
```

## Arguments

- raw_data:

  Raw data from get_raw_graduation()

- end_year:

  Academic year end

- timeframe:

  Cohort timeframe ("4-Year rate", "5-Year rate", or "6-Year rate")

## Value

Data frame with standardized column names
