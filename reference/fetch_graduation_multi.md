# Fetch Graduation Rate Data for Multiple Years

Downloads graduation rate data for multiple years and combines into
single data frame.

## Usage

``` r
fetch_graduation_multi(
  end_years,
  tidy = TRUE,
  timeframe = "4-Year rate",
  use_cache = TRUE
)
```

## Arguments

- end_years:

  Vector of academic year ends

- tidy:

  Return long-format tidy data? Default TRUE

- timeframe:

  Cohort timeframe: "4-Year rate" (default), "5-Year rate", or "6-Year
  rate"

- use_cache:

  Use cached data if available? Default TRUE

## Value

Data frame with graduation rate data for all requested years

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 5 years of data
grad_5yr <- fetch_graduation_multi(2020:2024)

# Get all available years
all_years <- fetch_graduation_multi(get_available_grad_years())
} # }
```
