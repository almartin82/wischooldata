# Fetch Wisconsin High School Graduation Rate Data

Downloads and returns Wisconsin DPI high school graduation rate data.
Data includes cohort counts, graduate counts, and graduation rates for
all schools, districts, and the statewide total.

## Usage

``` r
fetch_graduation(
  end_year,
  tidy = TRUE,
  timeframe = "4-Year rate",
  use_cache = TRUE
)
```

## Arguments

- end_year:

  Academic year end (e.g., 2024 for 2023-24 school year)

- tidy:

  Return long-format tidy data? Default TRUE

- timeframe:

  Cohort timeframe: "4-Year rate" (default), "5-Year rate", or "6-Year
  rate"

- use_cache:

  Use cached data if available? Default TRUE

## Value

Data frame with graduation rate data

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 graduation rates (2023-24 school year)
grad_2024 <- fetch_graduation(2024)

# Get multiple years
library(purrr)
grad_multi <- map_dfr(2020:2024, ~fetch_graduation(.x))

# Get 5-year graduation rate instead of 4-year
grad_5yr <- fetch_graduation(2024, timeframe = "5-Year rate")

# Get raw format (closer to source)
grad_raw <- fetch_graduation(2024, tidy = FALSE)
} # }
```
