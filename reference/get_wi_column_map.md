# Get column mappings for Wisconsin enrollment data

Returns a list mapping Wisconsin DPI column names to standardized names.
Column names vary by era and file type.

## Usage

``` r
get_wi_column_map(era = "wisedash_modern")
```

## Arguments

- era:

  Data era ("winss", "wisedash_early", "wisedash_modern")

## Value

Named list of column mappings
