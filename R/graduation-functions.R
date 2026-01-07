# Wisconsin Graduation Rate Data Functions
# Source: Wisconsin DPI WISEdash High School Completion Data
# URL Pattern: https://dpi.wi.gov/sites/default/files/wise/downloads/hs_completion_certified_YYYY-YY.zip
# Years Available: 2009-10 through 2023-24 (cohort years 2010-2024)

# ==============================================================================
# URL Builder
# ==============================================================================

#' Build Graduation Data URL
#'
#' Constructs the download URL for Wisconsin DPI high school completion data.
#'
#' @param end_year Academic year end (e.g., 2024 for 2023-24 school year)
#' @return Character URL to ZIP file
#' @keywords internal
build_grad_url <- function(end_year) {

  # Validate year
  if (!end_year %in% get_available_grad_years()) {
    stop("Graduation data not available for ", end_year,
         "\nAvailable years: ",
         paste(get_available_grad_years(), collapse = ", "))
  }

  # Convert cohort year to school year range
  start_year <- end_year - 1
  school_year <- paste0(start_year, "-", substr(end_year, 3, 4))

  # Build URL
  url <- paste0(
    "https://dpi.wi.gov/sites/default/files/wise/downloads/",
    "hs_completion_certified_", school_year, ".zip"
  )

  return(url)
}

# ==============================================================================
# Available Years
# ==============================================================================

#' Get Available Graduation Years
#'
#' Returns vector of years for which graduation rate data is available.
#'
#' @return Integer vector of cohort years (e.g., 2010:2024)
#' @export
get_available_grad_years <- function() {
  2010:2024
}

# ==============================================================================
# Raw Data Download
# ==============================================================================

#' Download Raw Graduation Rate Data
#'
#' Downloads and parses Wisconsin DPI high school completion CSV data from ZIP file.
#'
#' @param end_year Academic year end (e.g., 2024 for 2023-24 school year)
#' @param cache_dir Directory to cache downloaded files (NULL uses tempdir)
#' @return Data frame with raw graduation data as provided by WI DPI
#' @keywords internal
get_raw_graduation <- function(end_year, cache_dir = NULL) {

  # Validate year
  if (!end_year %in% get_available_grad_years()) {
    stop("Graduation data not available for ", end_year,
         "\nAvailable years: ",
         paste(get_available_grad_years(), collapse = ", "))
  }

  # Build URL
  url <- build_grad_url(end_year)

  # Set up cache directory
  if (is.null(cache_dir)) {
    cache_dir <- tempdir()
  }

  # Download ZIP file
  temp_zip <- file.path(cache_dir, paste0("hs_completion_", end_year, ".zip"))

  if (!file.exists(temp_zip)) {
    tryCatch({
      utils::download.file(url, temp_zip, mode = "wb", quiet = TRUE)
    }, error = function(e) {
      stop("Failed to download graduation data for ", end_year, ": ", e$message)
    })
  }

  # Extract ZIP
  temp_dir <- file.path(cache_dir, paste0("hs_completion_", end_year))
  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
    utils::unzip(temp_zip, exdir = temp_dir)
  }

  # Find CSV file (exclude layout file)
  csv_files <- list.files(temp_dir, pattern = "\\.csv$", full.names = TRUE)
  data_file <- csv_files[!grepl("layout", csv_files)][1]

  if (is.na(data_file)) {
    stop("Could not find data CSV in ZIP file")
  }

  # Read CSV
  raw <- readr::read_csv(data_file, show_col_types = FALSE)

  return(raw)
}

# ==============================================================================
# Processing
# ==============================================================================

#' Process Raw Graduation Data
#'
#' Processes raw WI DPI data into standardized format.
#' Filters to regular high school diplomas and converts data types.
#'
#' @param raw_data Raw data from get_raw_graduation()
#' @param end_year Academic year end
#' @param timeframe Cohort timeframe ("4-Year rate", "5-Year rate", or "6-Year rate")
#' @return Data frame with standardized column names
#' @keywords internal
process_graduation <- function(raw_data, end_year, timeframe = "4-Year rate") {

  # Validate timeframe
  valid_timeframes <- c("4-Year rate", "5-Year rate", "6-Year rate")
  if (!timeframe %in% valid_timeframes) {
    stop("Invalid timeframe: ", timeframe,
         "\nValid options: ",
         paste(valid_timeframes, collapse = ", "))
  }

  # Determine completion status based on era
  # Pre-2017: "Completed - Regular"
  # 2017+: "Completed - Regular High School Diploma"
  if (end_year < 2017) {
    completion_filter <- "Completed - Regular"
  } else {
    completion_filter <- "Completed - Regular High School Diploma"
  }

  # Filter to regular diplomas only (standard graduation rate)
  processed <- raw_data |>
    dplyr::filter(
      COMPLETION_STATUS == completion_filter,
      TIMEFRAME == timeframe
    ) |>
    dplyr::mutate(
      cohort_count = as.integer(COHORT_COUNT),
      student_count = as.integer(STUDENT_COUNT)
    )

  # Handle suppressed values
  processed <- processed |>
    dplyr::mutate(
      cohort_count = dplyr::if_else(GROUP_BY_VALUE == "[Data Suppressed]",
                                     NA_integer_, cohort_count),
      student_count = dplyr::if_else(GROUP_BY_VALUE == "[Data Suppressed]",
                                      NA_integer_, student_count)
    )

  # Validate required columns exist
  required_cols <- c("DISTRICT_CODE", "SCHOOL_CODE", "COHORT_COUNT", "STUDENT_COUNT")
  missing_cols <- setdiff(required_cols, names(processed))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }

  return(processed)
}

# ==============================================================================
# Tidy Transformation
# ==============================================================================

#' Tidy Graduation Data
#'
#' Converts processed graduation data into long-format tidy data frame.
#'
#' @param processed_data Processed data from process_graduation()
#' @param end_year Academic year end
#' @return Long-format tibble with standard schema
#' @keywords internal
tidy_graduation <- function(processed_data, end_year) {

  tidy <- processed_data |>
    dplyr::mutate(
      end_year = as.integer(COHORT),
      district_id = DISTRICT_CODE,
      district_name = DISTRICT_NAME,
      school_id = SCHOOL_CODE,
      school_name = SCHOOL_NAME,
      subgroup = GROUP_BY_VALUE,
      cohort_type = TIMEFRAME
    ) |>
    # Calculate graduation rate
    dplyr::mutate(grad_rate = student_count / cohort_count) |>
    # Add type flags
    dplyr::mutate(
      is_state = district_id == "0000",
      is_district = !is_state & SCHOOL_NAME == "[Districtwide]",
      is_school = !is_state & SCHOOL_NAME != "[Districtwide]"
    ) |>
    # Select standard columns
    dplyr::select(
      end_year,
      district_id,
      district_name,
      school_id,
      school_name,
      subgroup,
      cohort_type,
      cohort_count,
      graduate_count = student_count,
      grad_rate,
      is_state,
      is_district,
      is_school
    )

  return(tidy)
}

# ==============================================================================
# User-Facing Function
# ==============================================================================

#' Fetch Wisconsin High School Graduation Rate Data
#'
#' Downloads and returns Wisconsin DPI high school graduation rate data.
#' Data includes cohort counts, graduate counts, and graduation rates
#' for all schools, districts, and the statewide total.
#'
#' @param end_year Academic year end (e.g., 2024 for 2023-24 school year)
#' @param tidy Return long-format tidy data? Default TRUE
#' @param timeframe Cohort timeframe: "4-Year rate" (default), "5-Year rate", or "6-Year rate"
#' @param use_cache Use cached data if available? Default TRUE
#' @return Data frame with graduation rate data
#' @export
#'
#' @examples
#' \dontrun{
#' # Get 2024 graduation rates (2023-24 school year)
#' grad_2024 <- fetch_graduation(2024)
#'
#' # Get multiple years
#' library(purrr)
#' grad_multi <- map_dfr(2020:2024, ~fetch_graduation(.x))
#'
#' # Get 5-year graduation rate instead of 4-year
#' grad_5yr <- fetch_graduation(2024, timeframe = "5-Year rate")
#'
#' # Get raw format (closer to source)
#' grad_raw <- fetch_graduation(2024, tidy = FALSE)
#' }
fetch_graduation <- function(end_year, tidy = TRUE, timeframe = "4-Year rate",
                             use_cache = TRUE) {

  # Set cache directory
  cache_dir <- if (use_cache) NULL else tempdir()

  # Get raw data
  raw <- get_raw_graduation(end_year, cache_dir = cache_dir)

  # Process
  processed <- process_graduation(raw, end_year, timeframe = timeframe)

  # Tidy if requested
  if (tidy) {
    return(tidy_graduation(processed, end_year))
  } else {
    return(processed)
  }
}

# ==============================================================================
# Multi-Year Helper
# ==============================================================================

#' Fetch Graduation Rate Data for Multiple Years
#'
#' Downloads graduation rate data for multiple years and combines into single data frame.
#'
#' @param end_years Vector of academic year ends
#' @param tidy Return long-format tidy data? Default TRUE
#' @param timeframe Cohort timeframe: "4-Year rate" (default), "5-Year rate", or "6-Year rate"
#' @param use_cache Use cached data if available? Default TRUE
#' @return Data frame with graduation rate data for all requested years
#' @export
#'
#' @examples
#' \dontrun{
#' # Get 5 years of data
#' grad_5yr <- fetch_graduation_multi(2020:2024)
#'
#' # Get all available years
#' all_years <- fetch_graduation_multi(get_available_grad_years())
#' }
fetch_graduation_multi <- function(end_years, tidy = TRUE, timeframe = "4-Year rate",
                                    use_cache = TRUE) {

  purrr::map_dfr(end_years, ~fetch_graduation(.x, tidy = tidy,
                                                timeframe = timeframe,
                                                use_cache = use_cache))
}

# ==============================================================================
# Global Variables Declaration
# ==============================================================================

# Declare non-standard evaluation variables for R CMD check
utils::globalVariables(c(
  "COHORT",
  "COHORT_COUNT",
  "COMPLETION_STATUS",
  "DISTRICT_CODE",
  "DISTRICT_NAME",
  "GROUP_BY_VALUE",
  "SCHOOL_CODE",
  "SCHOOL_NAME",
  "STUDENT_COUNT",
  "TIMEFRAME",
  "campus_id",
  "campus_name",
  "cohort_count",
  "cohort_type",
  "count",
  "demo_col",
  "grad_rate",
  "group_by",
  "group_count",
  "is_district",
  "is_school",
  "is_state",
  "student_count"
))
