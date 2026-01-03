# Get the data format era for a given year

Wisconsin enrollment data comes from different systems depending on the
year:

- Era 1 (Published/PEM files): 1997-2005 - Excel files from
  published-enrollment-data

- Era 2 (WISEdash): 2006-present - ZIP/CSV files from WISEdash

## Usage

``` r
get_data_era(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Character string indicating the era

## Details

NOTE: WISEdash files are available back to 2005-06 school year. PEM
files for 2012-2016 no longer exist on DPI website (404 errors). We use
WISEdash for all years 2006+.
