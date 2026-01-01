# Get available years for Wisconsin enrollment data

Returns the range of years for which enrollment data is available.
Wisconsin DPI provides data through multiple systems:

- Published Excel files: 1997-2016

- WISEdash ZIP/CSV files: 2006-present

## Usage

``` r
get_available_years()
```

## Value

A vector of available years

## Examples

``` r
get_available_years()
#>  [1] 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011
#> [16] 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025
```
