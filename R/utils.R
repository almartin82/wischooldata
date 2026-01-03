# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
NULL


#' Convert to numeric, handling suppression markers
#'
#' Wisconsin DPI uses various markers for suppressed data (*, <5, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "N/A", "NA", "", "--", "**")] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Get available years for Wisconsin enrollment data
#'
#' Returns the range of years for which enrollment data is available.
#' Wisconsin DPI provides data through multiple systems:
#' - Published Excel files: 1997-2016
#' - WISEdash ZIP/CSV files: 2006-present
#'
#' @return A vector of available years
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  # Published Excel data: 1997-2016
  # WISEdash data: 2006-present (overlaps)
  # Effective range: 1997-current
  1997:2024
}


#' Get the data format era for a given year
#'
#' Wisconsin enrollment data comes from different systems depending on the year:
#' - Era 1 (Published/PEM files): 1997-2005 - Excel files from published-enrollment-data
#' - Era 2 (WISEdash): 2006-present - ZIP/CSV files from WISEdash
#'
#' NOTE: WISEdash files are available back to 2005-06 school year.
#' PEM files for 2012-2016 no longer exist on DPI website (404 errors).
#' We use WISEdash for all years 2006+.
#'
#' @param end_year School year end
#' @return Character string indicating the era
#' @keywords internal
get_data_era <- function(end_year) {
  if (end_year < 1997) {
    stop("Data not available before 1997")
  } else if (end_year <= 2005) {
    return("published")
  } else {
    return("wisedash")
  }
}


#' Build school year string from end year
#'
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @return Formatted school year string (e.g., "2023-24")
#' @keywords internal
format_school_year <- function(end_year) {
  start_year <- end_year - 1
  paste0(start_year, "-", substr(as.character(end_year), 3, 4))
}
