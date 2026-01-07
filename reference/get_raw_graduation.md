# Download Raw Graduation Rate Data

Downloads and parses Wisconsin DPI high school completion CSV data from
ZIP file.

## Usage

``` r
get_raw_graduation(end_year, cache_dir = NULL)
```

## Arguments

- end_year:

  Academic year end (e.g., 2024 for 2023-24 school year)

- cache_dir:

  Directory to cache downloaded files (NULL uses tempdir)

## Value

Data frame with raw graduation data as provided by WI DPI
