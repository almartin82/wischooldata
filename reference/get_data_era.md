# Get the data format era for a given year

Wisconsin enrollment data comes from different systems depending on the
year:

- Era 1 (WINSS/Published): 1997-2005 - Excel files from
  published-enrollment-data

- Era 2 (WISEdash Early): 2006-2015 - Excel files from
  published-enrollment-data or WISEdash

- Era 3 (WISEdash Modern): 2016-present - ZIP/CSV files from WISEdash

## Usage

``` r
get_data_era(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Character string indicating the era
