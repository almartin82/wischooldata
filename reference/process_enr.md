# Process raw Wisconsin DPI enrollment data

Transforms raw DPI data into a standardized schema. Handles both
WISEdash (long format) and published Excel (wide format) data.

## Usage

``` r
process_enr(raw_data, end_year)
```

## Arguments

- raw_data:

  Data frame from get_raw_enr

- end_year:

  School year end

## Value

Processed data frame with standardized columns
