# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from
# Wisconsin Department of Public Instruction (DPI).
#
# Data sources:
# - Published Excel files (1997-2005): Direct download from DPI (PEM files)
# - WISEdash ZIP/CSV files (2006-present): Download from WISEdash data files
#
# NOTE: PEM files for 2012-2016 no longer exist on DPI website (404).
# WISEdash files are available back to 2006, so we use those for 2006+.
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

  if (era == "wisedash") {
    # 2006+ uses WISEdash ZIP/CSV files
    df <- download_wisedash_enrollment(end_year)
  } else {
    # 1997-2005 uses published Excel files (PEM files)
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

  # Filter to enrollment files (exclude any metadata/layout files)
  enr_files <- csv_files[grep("enrollment", csv_files, ignore.case = TRUE)]
  enr_files <- enr_files[!grepl("_layout\\.csv$", enr_files, ignore.case = TRUE)]

  if (length(enr_files) == 0) {
    # Fall back to any CSV file that's not a layout file
    enr_files <- csv_files[!grepl("_layout\\.csv$", csv_files, ignore.case = TRUE)]
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
  # PEM files have multiple sheets; data is in the sheet named "PEM{year}"
  sheets <- readxl::excel_sheets(temp_file)

  # Find the data sheet (named "PEM{year}" e.g., "PEM10" for 2010)
  data_sheet <- grep(paste0("^PEM", year_suffix, "$"), sheets, value = TRUE,
                     ignore.case = TRUE)

  if (length(data_sheet) == 0) {
    # Try alternate pattern (just look for PEM followed by digits)
    data_sheet <- grep("^PEM[0-9]+$", sheets, value = TRUE, ignore.case = TRUE)
  }

  if (length(data_sheet) == 0) {
    # Fall back to first non-metadata sheet
    meta_sheets <- c("Disclaimer", "Data Changes", "Data Abbreviations",
                     "Locale Code Definitions")
    data_sheets <- setdiff(sheets, meta_sheets)
    if (length(data_sheets) > 0) {
      data_sheet <- data_sheets[1]
    } else {
      stop(paste("Could not find data sheet in PEM file. Available sheets:",
                 paste(sheets, collapse = ", ")))
    }
  }

  message(paste("  Reading sheet:", data_sheet[1]))

  df <- readxl::read_excel(
    temp_file,
    sheet = data_sheet[1],
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
#' @param era Data era ("published", "wisedash")
#' @return Named list of column mappings
#' @keywords internal
get_wi_column_map <- function(era = "wisedash") {

  if (era == "wisedash") {
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
    # Published Excel columns (1997-2005)
    # PEM files have columns like:
    # District, Dist Code, Dist No., Sch Code, School, County Name, CESA, Grade, etc.
    # The data is in long format (one row per grade) with ethnicity columns
    list(
      # District columns
      district_code = c("Dist Code", "Dist No.", "DIST", "District Code"),
      district_name = c("District", "District Name", "DISTRICT NAME"),

      # School columns
      school_code = c("Sch Code", "School Code", "SCHOOL", "SCHL"),
      school_name = c("School", "School Name", "SCHOOL NAME"),

      # Location columns
      county = c("County Name", "County", "COUNTY"),
      cesa = c("CESA", "Cesa"),

      # Grade columns (in PEM files, grade is a single column, not wide format)
      grade = c("Grade", "Gr. Cat.", "GRADE"),

      # Total column
      total = c("TOTAL", "Total", "TOT"),

      # Ethnicity columns (these are wide in the PEM files)
      white = c("White (not Hispanic)", "White", "WHITE"),
      black = c("Black (not Hispanic)", "Black", "BLACK", "Afr Am"),
      hispanic = c("Hispanic", "HISPANIC", "Hisp"),
      asian = c("Asian/Pacific Islander", "Asian", "ASIAN"),
      native_american = c("American Indian/ Alaskan Native", "Am Ind", "American Indian"),
      pacific_islander = c("Pacific Islander", "Pac Isl", "PACIFIC"),
      multiracial = c("Two or More", "TWO OR MORE", "Multi")
    )
  }
}
