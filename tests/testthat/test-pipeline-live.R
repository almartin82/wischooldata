# ==============================================================================
# LIVE Pipeline Tests for wischooldata
# ==============================================================================
#
# These tests verify EACH STEP of the data pipeline using LIVE network calls.
# No mocks - we verify actual connectivity and data correctness.
#
# Test Categories:
# 1. URL Availability - HTTP status codes
# 2. File Download - Successful download and file type verification
# 3. File Parsing - Read file into R
# 4. Column Structure - Expected columns exist
# 5. get_raw_enr() - Raw data function works
# 6. Aggregation Logic - District sums match state totals
# 7. Data Quality - No Inf/NaN, valid ranges
# 8. Output Fidelity - tidy=TRUE matches raw data
#
# Data Sources:
# - WISEdash ZIP files (2006+): https://dpi.wi.gov/sites/default/files/wise/downloads/
# - Published PEM files (1997-2005): https://dpi.wi.gov/sites/default/files/imce/cst/xls/
#
# ==============================================================================

library(testthat)
library(httr)

# Skip if no network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

# ==============================================================================
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("Wisconsin DPI main website is accessible", {
  skip_if_offline()

  response <- httr::HEAD("https://dpi.wi.gov/", httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("WISEdash download page is accessible", {
  skip_if_offline()

  response <- httr::HEAD("https://dpi.wi.gov/wisedash/download-files", httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("WISEdash enrollment ZIP file URL returns HTTP 200 (current year)", {
  skip_if_offline()

  url <- "https://dpi.wi.gov/sites/default/files/wise/downloads/enrollment_by_gradelevel_certified_2023-24.zip"
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("WISEdash enrollment ZIP files return HTTP 200 (multiple years)", {
  skip_if_offline()

  years <- c("2023-24", "2022-23", "2020-21", "2015-16", "2010-11", "2006-07")

  for (year in years) {
    url <- paste0("https://dpi.wi.gov/sites/default/files/wise/downloads/",
                  "enrollment_by_gradelevel_certified_", year, ".zip")
    response <- httr::HEAD(url, httr::timeout(30))
    expect_equal(httr::status_code(response), 200,
                 label = paste("WISEdash file for", year))
  }
})

test_that("Published PEM files return HTTP 200 (historical years)", {
  skip_if_offline()

  # Test PEM files for years 2005 and earlier
  years <- c("05", "04", "03", "02", "01")

  for (year in years) {
    url <- paste0("https://dpi.wi.gov/sites/default/files/imce/cst/xls/pem", year, ".xls")
    response <- httr::HEAD(url, httr::timeout(30))
    expect_equal(httr::status_code(response), 200,
                 label = paste("PEM file for 20", year, sep = ""))
  }
})

# ==============================================================================
# STEP 2: File Download Tests
# ==============================================================================

test_that("Can download WISEdash enrollment ZIP file", {
  skip_if_offline()

  url <- "https://dpi.wi.gov/sites/default/files/wise/downloads/enrollment_by_gradelevel_certified_2023-24.zip"
  temp_file <- tempfile(fileext = ".zip")

  response <- httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE),
                        httr::timeout(120))

  expect_equal(httr::status_code(response), 200)
  expect_true(file.info(temp_file)$size > 10000)  # Should be > 10KB

  # Verify it's actually a ZIP file by checking magic bytes
  conn <- file(temp_file, "rb")
  magic_bytes <- readBin(conn, "raw", n = 4)
  close(conn)

  # ZIP files start with PK (0x50 0x4B)
  expect_equal(magic_bytes[1:2], as.raw(c(0x50, 0x4B)))

  unlink(temp_file)
})

test_that("Downloaded file is a valid ZIP archive", {
  skip_if_offline()

  url <- "https://dpi.wi.gov/sites/default/files/wise/downloads/enrollment_by_gradelevel_certified_2023-24.zip"
  temp_file <- tempfile(fileext = ".zip")

  httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(120))

  # Try to list contents - will fail if not a valid ZIP
  contents <- tryCatch(
    unzip(temp_file, list = TRUE),
    error = function(e) NULL
  )

  expect_true(!is.null(contents), label = "File should be a valid ZIP")
  expect_true(nrow(contents) > 0, label = "ZIP should have contents")

  unlink(temp_file)
})

# ==============================================================================
# STEP 3: File Parsing Tests
# ==============================================================================

test_that("Can extract and parse WISEdash CSV from ZIP", {
  skip_if_offline()

  url <- "https://dpi.wi.gov/sites/default/files/wise/downloads/enrollment_by_gradelevel_certified_2023-24.zip"
  temp_zip <- tempfile(fileext = ".zip")
  temp_dir <- tempdir()

  httr::GET(url, httr::write_disk(temp_zip, overwrite = TRUE), httr::timeout(120))

  # Extract ZIP
  unzip(temp_zip, exdir = temp_dir, overwrite = TRUE)

  # Find CSV file
  csv_files <- list.files(temp_dir, pattern = "enrollment.*\\.csv$",
                          full.names = TRUE, ignore.case = TRUE)
  csv_files <- csv_files[!grepl("layout", csv_files, ignore.case = TRUE)]

  expect_true(length(csv_files) > 0, label = "ZIP should contain enrollment CSV file")

  # Parse CSV
  df <- readr::read_csv(csv_files[1], col_types = readr::cols(.default = "c"),
                        show_col_types = FALSE)

  expect_true(is.data.frame(df))
  expect_true(nrow(df) > 1000, label = "CSV should have substantial data")
  expect_true(ncol(df) > 5)

  unlink(temp_zip)
  unlink(csv_files)
})

# ==============================================================================
# STEP 4: Column Structure Tests
# ==============================================================================

test_that("WISEdash CSV has expected columns", {
  skip_if_offline()

  url <- "https://dpi.wi.gov/sites/default/files/wise/downloads/enrollment_by_gradelevel_certified_2023-24.zip"
  temp_zip <- tempfile(fileext = ".zip")
  temp_dir <- tempdir()

  httr::GET(url, httr::write_disk(temp_zip, overwrite = TRUE), httr::timeout(120))
  unzip(temp_zip, exdir = temp_dir, overwrite = TRUE)

  csv_files <- list.files(temp_dir, pattern = "enrollment.*\\.csv$",
                          full.names = TRUE, ignore.case = TRUE)
  csv_files <- csv_files[!grepl("layout", csv_files, ignore.case = TRUE)]

  df <- readr::read_csv(csv_files[1], col_types = readr::cols(.default = "c"),
                        n_max = 100, show_col_types = FALSE)

  expected_cols <- c("DISTRICT_CODE", "SCHOOL_CODE", "GRADE_LEVEL",
                     "GROUP_BY", "STUDENT_COUNT")

  for (col in expected_cols) {
    expect_true(col %in% names(df), label = paste("Column", col))
  }

  unlink(temp_zip)
  unlink(csv_files)
})

test_that("WISEdash data has expected GROUP_BY values", {
  skip_if_offline()

  url <- "https://dpi.wi.gov/sites/default/files/wise/downloads/enrollment_by_gradelevel_certified_2023-24.zip"
  temp_zip <- tempfile(fileext = ".zip")
  temp_dir <- tempdir()

  httr::GET(url, httr::write_disk(temp_zip, overwrite = TRUE), httr::timeout(120))
  unzip(temp_zip, exdir = temp_dir, overwrite = TRUE)

  csv_files <- list.files(temp_dir, pattern = "enrollment.*\\.csv$",
                          full.names = TRUE, ignore.case = TRUE)
  csv_files <- csv_files[!grepl("layout", csv_files, ignore.case = TRUE)]

  df <- readr::read_csv(csv_files[1], col_types = readr::cols(.default = "c"),
                        show_col_types = FALSE)

  group_values <- unique(df$GROUP_BY)

  # Should have Race/Ethnicity and Gender at minimum
  expect_true("Race/Ethnicity" %in% group_values, label = "GROUP_BY Race/Ethnicity")
  expect_true("Gender" %in% group_values, label = "GROUP_BY Gender")

  unlink(temp_zip)
  unlink(csv_files)
})

# ==============================================================================
# STEP 5: get_raw_enr() Function Tests
# ==============================================================================

test_that("get_raw_enr returns data for current year", {
  skip_if_offline()

  raw <- wischooldata:::get_raw_enr(2024)

  expect_true(is.data.frame(raw))
  expect_true(nrow(raw) > 1000)
  expect_true("end_year" %in% names(raw))
  expect_equal(unique(raw$end_year), 2024)
})

test_that("get_raw_enr returns data for historical year (2010)", {
  skip_if_offline()

  raw <- wischooldata:::get_raw_enr(2010)

  expect_true(is.data.frame(raw))
  expect_true(nrow(raw) > 1000)
  expect_true("end_year" %in% names(raw))
  expect_equal(unique(raw$end_year), 2010)
})

test_that("get_raw_enr errors for invalid year", {
  expect_error(wischooldata:::get_raw_enr(1990), "must be between")
  expect_error(wischooldata:::get_raw_enr(2030), "must be between")
})

test_that("get_available_years returns valid year range", {
  result <- wischooldata::get_available_years()

  expect_true(is.numeric(result))
  expect_true(1997 %in% result)
  expect_true(2024 %in% result)
  expect_true(length(result) > 20)
})

# ==============================================================================
# STEP 6: Data Quality Tests
# ==============================================================================

test_that("fetch_enr returns data with no Inf or NaN", {
  skip_if_offline()

  data <- wischooldata::fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  for (col in names(data)[sapply(data, is.numeric)]) {
    expect_false(any(is.infinite(data[[col]]), na.rm = TRUE),
                 label = paste("No Inf in", col))
    expect_false(any(is.nan(data[[col]]), na.rm = TRUE),
                 label = paste("No NaN in", col))
  }
})

test_that("Enrollment counts are non-negative", {
  skip_if_offline()

  data <- wischooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  if ("row_total" %in% names(data)) {
    expect_true(all(data$row_total >= 0, na.rm = TRUE))
  }

  # Check grade columns too
  grade_cols <- grep("^grade_", names(data), value = TRUE)
  for (col in grade_cols) {
    expect_true(all(data[[col]] >= 0, na.rm = TRUE),
                label = paste(col, "non-negative"))
  }
})

test_that("Percentages are in valid range (0-1)", {
  skip_if_offline()

  data <- wischooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  if ("pct" %in% names(data)) {
    valid_pcts <- data$pct[!is.na(data$pct)]
    expect_true(all(valid_pcts >= 0 & valid_pcts <= 1))
  }
})

# ==============================================================================
# STEP 7: Aggregation Tests
# ==============================================================================

test_that("State total is reasonable (not zero)", {
  skip_if_offline()

  data <- wischooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  state_rows <- data[data$type == "State", ]
  expect_true(nrow(state_rows) > 0)

  if ("row_total" %in% names(state_rows)) {
    state_total <- sum(state_rows$row_total, na.rm = TRUE)
    # Wisconsin has ~800k students
    expect_true(state_total > 500000, label = "State total > 500k")
    expect_true(state_total < 1500000, label = "State total < 1.5M")
  }
})

test_that("District totals sum to approximately state total", {
  skip_if_offline()

  data <- wischooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  state_total <- sum(data$row_total[data$type == "State"], na.rm = TRUE)
  district_total <- sum(data$row_total[data$type == "District"], na.rm = TRUE)

  # Allow 5% tolerance
  ratio <- district_total / state_total
  expect_true(ratio > 0.95 && ratio < 1.05,
              label = paste("District/State ratio:", round(ratio, 3)))
})

test_that("State has both male and female enrollment > 0", {
  skip_if_offline()

  data <- wischooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  state_data <- data[data$type == "State", ]

  if ("male" %in% names(state_data) && "female" %in% names(state_data)) {
    expect_true(sum(state_data$male, na.rm = TRUE) > 0, label = "male > 0")
    expect_true(sum(state_data$female, na.rm = TRUE) > 0, label = "female > 0")
  }
})

test_that("State has all major race/ethnicity groups", {
  skip_if_offline()

  data <- wischooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  state_data <- data[data$type == "State", ]

  race_cols <- c("white", "black", "hispanic", "asian")

  for (col in race_cols) {
    if (col %in% names(state_data)) {
      expect_true(sum(state_data[[col]], na.rm = TRUE) > 0, label = paste(col, "> 0"))
    }
  }
})

# ==============================================================================
# STEP 8: Output Fidelity Tests
# ==============================================================================

test_that("tidy=TRUE and tidy=FALSE return consistent totals", {
  skip_if_offline()

  wide <- wischooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- wischooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_true(nrow(wide) > 0)
  expect_true(nrow(tidy) > 0)

  # State totals should match
  wide_state <- sum(wide$row_total[wide$type == "State"], na.rm = TRUE)
  tidy_state <- sum(tidy$n_students[tidy$is_state &
                                    tidy$subgroup == "total_enrollment" &
                                    tidy$grade_level == "TOTAL"], na.rm = TRUE)

  expect_equal(wide_state, tidy_state, tolerance = 1)
})

test_that("Year-over-year state totals are within 10%", {
  skip_if_offline()

  data_2024 <- wischooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  data_2023 <- wischooldata::fetch_enr(2023, tidy = FALSE, use_cache = TRUE)

  state_2024 <- sum(data_2024$row_total[data_2024$type == "State"], na.rm = TRUE)
  state_2023 <- sum(data_2023$row_total[data_2023$type == "State"], na.rm = TRUE)

  yoy_change <- abs(state_2024 / state_2023 - 1)
  expect_true(yoy_change < 0.10,
              label = paste("YoY change:", round(yoy_change * 100, 2), "%"))
})

test_that("Multiple years can be fetched consistently", {
  skip_if_offline()

  data_multi <- wischooldata::fetch_enr_multi(c(2022, 2023, 2024), tidy = TRUE, use_cache = TRUE)

  expect_true(all(c(2022, 2023, 2024) %in% data_multi$end_year))

  # Each year should have state-level data
  for (year in c(2022, 2023, 2024)) {
    year_data <- data_multi[data_multi$end_year == year & data_multi$is_state, ]
    expect_true(nrow(year_data) > 0, label = paste("Year", year, "has state data"))
  }
})

# ==============================================================================
# Raw Data Fidelity Tests
# ==============================================================================

test_that("get_raw_enr data matches independent read", {
  skip_if_offline()

  # Get raw data via package function
  raw <- wischooldata:::get_raw_enr(2024)

  # Verify we can independently read the same data
  url <- "https://dpi.wi.gov/sites/default/files/wise/downloads/enrollment_by_gradelevel_certified_2023-24.zip"
  temp_zip <- tempfile(fileext = ".zip")
  temp_dir <- tempdir()

  httr::GET(url, httr::write_disk(temp_zip, overwrite = TRUE), httr::timeout(120))
  unzip(temp_zip, exdir = temp_dir, overwrite = TRUE)

  csv_files <- list.files(temp_dir, pattern = "enrollment.*\\.csv$",
                          full.names = TRUE, ignore.case = TRUE)
  csv_files <- csv_files[!grepl("layout", csv_files, ignore.case = TRUE)]

  independent <- readr::read_csv(csv_files[1], col_types = readr::cols(.default = "c"),
                                 show_col_types = FALSE)

  # Row counts should match (minus end_year column added by package)
  expect_equal(nrow(raw), nrow(independent))

  unlink(temp_zip)
  unlink(csv_files)
})

# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("Cache functions exist and work", {
  path <- wischooldata:::get_cache_path(2024, "tidy")
  expect_true(is.character(path))
  expect_true(grepl("2024", path))
})

test_that("Cached and fresh data match", {
  skip_if_offline()

  # Get fresh data
  fresh <- wischooldata::fetch_enr(2024, tidy = FALSE, use_cache = FALSE)

  # Get cached data
  cached <- wischooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  expect_equal(nrow(fresh), nrow(cached))
  expect_equal(sum(fresh$row_total, na.rm = TRUE),
               sum(cached$row_total, na.rm = TRUE))
})
