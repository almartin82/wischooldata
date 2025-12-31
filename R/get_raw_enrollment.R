# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from
# Wisconsin Department of Public Instruction (DPI).
#
# Data sources:
# - Published Excel files (1997-2016): Direct download from DPI
# - WISEdash ZIP/CSV files (2006-present): Download from WISEdash data files
#
# Wisconsin ID System:
# - District Code: 4 digits (e.g., 3619 for Madison Metropolitan)
# - School Code: District Code + 4-digit school number (e.g., 3619-0280)
# - CESA (Cooperative Educational Service Agency): 12 regions in Wisconsin
#
# ==============================================================================

#' Download raw enrollment data from Wisconsin DPI
#'
#' Downloads school and district enrollment data from Wisconsin DPI.
#' Uses WISEdash CSV files for 2016+ and published Excel files for earlier years.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return Data frame with enrollment data
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year
  available_years <- get_available_years()
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between ", min(available_years), " and ", max(available_years),
      ". Got: ", end_year
    ))
  }

  message(paste("Downloading Wisconsin DPI enrollment data for", end_year, "..."))

  # Determine which download function to use based on era
  era <- get_data_era(end_year)

  if (era == "wisedash_modern") {
    # 2016+ uses WISEdash ZIP/CSV files
    df <- download_wisedash_enrollment(end_year)
  } else {
    # 1997-2015 uses published Excel files
    df <- download_published_enrollment(end_year)
  }

  df$end_year <- end_year
  df
}


#' Download WISEdash enrollment data (2016+)
#'
#' Downloads enrollment data from WISEdash data files. These are ZIP files
#' containing CSV data with enrollment by grade level.
#'
#' @param end_year School year end (2016+)
#' @return Data frame with enrollment data
#' @keywords internal
download_wisedash_enrollment <- function(end_year) {

  message("  Downloading from WISEdash...")

  # Build the URL for enrollment by grade level
  # Format: enrollment_by_gradelevel_certified_YYYY-YY.zip
  school_year <- format_school_year(end_year)
  filename <- paste0("enrollment_by_gradelevel_certified_", school_year, ".zip")
  url <- paste0("https://dpi.wi.gov/sites/default/files/wise/downloads/", filename)

  # Create temp file for download
  temp_zip <- tempfile(fileext = ".zip")
  temp_dir <- tempdir()

  # Download the ZIP file
  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_zip, overwrite = TRUE),
      httr::timeout(300),
      httr::config(connecttimeout = 60)
    )

    if (httr::http_error(response)) {
      # Try alternate URL pattern (some years use different naming)
      filename_alt <- paste0("enrollment_certified_", school_year, ".zip")
      url_alt <- paste0("https://dpi.wi.gov/sites/default/files/wise/downloads/", filename_alt)

      response <- httr::GET(
        url_alt,
        httr::write_disk(temp_zip, overwrite = TRUE),
        httr::timeout(300),
        httr::config(connecttimeout = 60)
      )

      if (httr::http_error(response)) {
        stop(paste("HTTP error:", httr::status_code(response)))
      }
    }

    # Check file size
    if (file.info(temp_zip)$size < 1000) {
      stop("Downloaded file is too small - may be an error page")
    }

  }, error = function(e) {
    stop(paste("Failed to download WISEdash data for year", end_year,
               "\nURL:", url,
               "\nError:", e$message))
  })

  # Unzip and read
  unzip(temp_zip, exdir = temp_dir)

  # Find the CSV file(s) in the extracted contents
  csv_files <- list.files(temp_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)

  # Filter to enrollment files (exclude any metadata files)
  enr_files <- csv_files[grep("enrollment", csv_files, ignore.case = TRUE)]

  if (length(enr_files) == 0) {
    # Fall back to any CSV file
    enr_files <- csv_files
  }

  if (length(enr_files) == 0) {
    stop("No CSV files found in ZIP archive")
  }

  # Read the enrollment data
  df <- readr::read_csv(
    enr_files[1],
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  # Clean up temp files
  unlink(temp_zip)
  unlink(enr_files)

  df
}


#' Download published enrollment data (1997-2015)
#'
#' Downloads enrollment data from DPI's published Excel files.
#' These are Excel workbooks with enrollment by school/district.
#'
#' File types used:
#' - PEM (Public Enrollment Master): School-level with grade, gender, ethnicity
#' - PESE (Public Enrollment School Ethnicity): School-level ethnicity detail
#' - PEDGr (Public Enrollment District Grade): District-level by grade
#'
#' @param end_year School year end (1997-2015)
#' @return Data frame with enrollment data
#' @keywords internal
download_published_enrollment <- function(end_year) {

  message("  Downloading from published enrollment files...")

  # Determine the file suffix based on year
  # Files use 2-digit year suffix (e.g., pem16.xlsx for 2015-16)
  year_suffix <- sprintf("%02d", end_year %% 100)

  # Base URL for published enrollment files
  base_url <- "https://dpi.wi.gov/sites/default/files/imce/cst/xls/"

  # Try PEM file first (Public Enrollment Master - most complete)
  # File extension varies by year: .xlsx for recent, .xls for older
  extensions <- c(".xlsx", ".xls")
  pem_url <- NULL

  for (ext in extensions) {
    test_url <- paste0(base_url, "pem", year_suffix, ext)
    response <- httr::HEAD(test_url, httr::timeout(30))
    if (!httr::http_error(response)) {
      pem_url <- test_url
      break
    }
  }

  if (is.null(pem_url)) {
    # Try alternate naming patterns
    for (ext in extensions) {
      # Try uppercase
      test_url <- paste0(base_url, "PEM", year_suffix, ext)
      response <- httr::HEAD(test_url, httr::timeout(30))
      if (!httr::http_error(response)) {
        pem_url <- test_url
        break
      }
    }
  }

  if (is.null(pem_url)) {
    stop(paste("Could not find PEM file for year", end_year))
  }

  # Create temp file for download
  file_ext <- tools::file_ext(pem_url)
  temp_file <- tempfile(fileext = paste0(".", file_ext))

  # Download the file
  tryCatch({
    response <- httr::GET(
      pem_url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::timeout(300)
    )

    if (httr::http_error(response)) {
      stop(paste("HTTP error:", httr::status_code(response)))
    }

    # Check file size
    if (file.info(temp_file)$size < 1000) {
      stop("Downloaded file is too small - may be an error page")
    }

  }, error = function(e) {
    stop(paste("Failed to download published enrollment data for year", end_year,
               "\nURL:", pem_url,
               "\nError:", e$message))
  })

  # Read the Excel file
  # Try to determine if there are multiple sheets
  sheets <- readxl::excel_sheets(temp_file)

  # Read the first sheet (usually contains the main data)
  df <- readxl::read_excel(
    temp_file,
    sheet = 1,
    col_types = "text"
  )

  # Clean up temp file
  unlink(temp_file)

  df
}


#' Get column mappings for Wisconsin enrollment data
#'
#' Returns a list mapping Wisconsin DPI column names to standardized names.
#' Column names vary by era and file type.
#'
#' @param era Data era ("winss", "wisedash_early", "wisedash_modern")
#' @return Named list of column mappings
#' @keywords internal
get_wi_column_map <- function(era = "wisedash_modern") {

  if (era == "wisedash_modern") {
    # WISEdash CSV columns (2016+)
    list(
      # Identifiers
      school_year = c("SCHOOL_YEAR", "School Year"),
      district_code = c("DISTRICT_CODE", "District Code", "LEA_CODE"),
      district_name = c("DISTRICT_NAME", "District Name", "LEA_NAME"),
      school_code = c("SCHOOL_CODE", "School Code"),
      school_name = c("SCHOOL_NAME", "School Name"),
      cesa = c("CESA", "Cesa"),
      county = c("COUNTY", "County"),
      charter_ind = c("CHARTER_IND", "Charter Indicator"),
      agency_type = c("AGENCY_TYPE", "Agency Type"),

      # Grade level
      grade_level = c("GRADE_LEVEL", "Grade Level", "GRADE"),

      # Demographics/Groups
      group_by = c("GROUP_BY", "Group By"),
      group_by_value = c("GROUP_BY_VALUE", "Group By Value"),

      # Counts
      student_count = c("STUDENT_COUNT", "Student Count", "COUNT"),
      percent_of_group = c("PERCENT_OF_GROUP", "Percent of Group")
    )
  } else {
    # Published Excel columns (1997-2015)
    # PEM file structure varies but generally has:
    list(
      district_code = c("DIST", "District", "DISTRICT", "Dist Code"),
      district_name = c("District Name", "DISTRICT NAME", "DistName"),
      school_code = c("SCHOOL", "School", "SCHL", "School Code"),
      school_name = c("School Name", "SCHOOL NAME", "SchName"),
      county = c("County", "COUNTY", "County Name"),
      cesa = c("CESA", "Cesa"),

      # Grade columns
      grade_pk = c("PK", "Pre-K", "PRE-K", "4K"),
      grade_k = c("K", "KG", "KINDER"),
      grade_01 = c("G1", "1", "GR01", "Grade 1"),
      grade_02 = c("G2", "2", "GR02", "Grade 2"),
      grade_03 = c("G3", "3", "GR03", "Grade 3"),
      grade_04 = c("G4", "4", "GR04", "Grade 4"),
      grade_05 = c("G5", "5", "GR05", "Grade 5"),
      grade_06 = c("G6", "6", "GR06", "Grade 6"),
      grade_07 = c("G7", "7", "GR07", "Grade 7"),
      grade_08 = c("G8", "8", "GR08", "Grade 8"),
      grade_09 = c("G9", "9", "GR09", "Grade 9"),
      grade_10 = c("G10", "10", "GR10", "Grade 10"),
      grade_11 = c("G11", "11", "GR11", "Grade 11"),
      grade_12 = c("G12", "12", "GR12", "Grade 12"),
      total = c("TOTAL", "Total", "TOT", "All Grades"),

      # Demographics
      male = c("M", "Male", "MALE"),
      female = c("F", "Female", "FEMALE"),
      white = c("White", "WHITE", "W"),
      black = c("Black", "BLACK", "B", "Afr Am", "African American"),
      hispanic = c("Hispanic", "HISPANIC", "H", "Hisp"),
      asian = c("Asian", "ASIAN", "A"),
      native_american = c("Am Ind", "American Indian", "AM IND", "Native American"),
      pacific_islander = c("Pac Isl", "Pacific Islander", "PACIFIC"),
      multiracial = c("Two or More", "TWO OR MORE", "Multi")
    )
  }
}
