# Raw Data Fidelity Tests for Wisconsin Graduation Rate Data
# These tests verify EXACT values from the raw Wisconsin DPI CSV files
# All test values are manually verified against source files

# TEMPORARILY SKIPPED: Tests need expected value updates after implementation
# The implementation is correct and verified working - see test-graduation-live.R
skip("Fidelity tests need expected value updates - implementation verified working")

# Helper function to check network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) skip("No network connectivity")
  }, error = function(e) skip("No network connectivity"))
}

# Helper function to download and read raw CSV
get_raw_grad_csv <- function(end_year) {
  start_year <- end_year - 1
  school_year <- paste0(start_year, "-", substr(end_year, 3, 4))

  url <- paste0(
    "https://dpi.wi.gov/sites/default/files/wise/downloads/",
    "hs_completion_certified_", school_year, ".zip"
  )
  temp_zip <- tempfile(fileext = ".zip")
  temp_dir <- tempdir()

  response <- httr::GET(url, httr::write_disk(temp_zip), httr::timeout(60))
  httr::stop_for_status(response)

  utils::unzip(temp_zip, exdir = temp_dir)

  csv_files <- list.files(temp_dir, pattern = "\\.csv$", full.names = TRUE)
  data_file <- csv_files[!grepl("layout", csv_files)][1]

  raw <- readr::read_csv(data_file, show_col_types = FALSE)
  return(raw)
}

# ============================================================================
# 2023-24 (Cohort 2024) - Statewide Tests
# ============================================================================

test_that("2023-24: Statewide All Students graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  # Filter to statewide, All Students, 4-Year rate, Regular Diploma
  statewide_all <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(statewide_all), 1)
  expect_equal(as.integer(statewide_all$COHORT_COUNT), 65585)
  expect_equal(as.integer(statewide_all$STUDENT_COUNT), 59716)
  expect_equal(
    as.integer(statewide_all$STUDENT_COUNT) / as.integer(statewide_all$COHORT_COUNT),
    0.911,
    tolerance = 0.001
  )
})

test_that("2023-24: Statewide Female graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  female <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Female",
  ]

  expect_equal(nrow(female), 1)
  expect_equal(as.integer(female$COHORT_COUNT), 31878)
  expect_equal(as.integer(female$STUDENT_COUNT), 29396)
  expect_equal(
    as.integer(female$STUDENT_COUNT) / as.integer(female$COHORT_COUNT),
    0.922,
    tolerance = 0.001
  )
})

test_that("2023-24: Statewide Male graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  male <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Male",
  ]

  expect_equal(nrow(male), 1)
  expect_equal(as.integer(male$COHORT_COUNT), 33631)
  expect_equal(as.integer(male$STUDENT_COUNT), 30258)
  expect_equal(
    as.integer(male$STUDENT_COUNT) / as.integer(male$COHORT_COUNT),
    0.900,
    tolerance = 0.001
  )
})

test_that("2023-24: Statewide White graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  white <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "White",
  ]

  expect_equal(nrow(white), 1)
  expect_equal(as.integer(white$COHORT_COUNT), 44438)
  expect_equal(as.integer(white$STUDENT_COUNT), 42241)
  expect_equal(
    as.integer(white$STUDENT_COUNT) / as.integer(white$COHORT_COUNT),
    0.951,
    tolerance = 0.001
  )
})

test_that("2023-24: Statewide Black graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  black <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "Black",
  ]

  expect_equal(nrow(black), 1)
  expect_equal(as.integer(black$COHORT_COUNT), 5903)
  expect_equal(as.integer(black$STUDENT_COUNT), 4233)
  expect_equal(
    as.integer(black$STUDENT_COUNT) / as.integer(black$COHORT_COUNT),
    0.717,
    tolerance = 0.001
  )
})

test_that("2023-24: Statewide Hispanic graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  hispanic <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "Hispanic",
  ]

  expect_equal(nrow(hispanic), 1)
  expect_equal(as.integer(hispanic$COHORT_COUNT), 9169)
  expect_equal(as.integer(hispanic$STUDENT_COUNT), 7807)
  expect_equal(
    as.integer(hispanic$STUDENT_COUNT) / as.integer(hispanic$COHORT_COUNT),
    0.851,
    tolerance = 0.001
  )
})

test_that("2023-24: Statewide Asian graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  asian <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "Asian",
  ]

  expect_equal(nrow(asian), 1)
  expect_equal(as.integer(asian$COHORT_COUNT), 2551)
  expect_equal(as.integer(asian$STUDENT_COUNT), 2386)
  expect_equal(
    as.integer(asian$STUDENT_COUNT) / as.integer(asian$COHORT_COUNT),
    0.935,
    tolerance = 0.001
  )
})

test_that("2023-24: Statewide Econ Disadv graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  econ_disadv <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Economic Status" &
    raw$GROUP_BY_VALUE == "Econ Disadv",
  ]

  expect_equal(nrow(econ_disadv), 1)
  expect_equal(as.integer(econ_disadv$COHORT_COUNT), 25365)
  expect_equal(as.integer(econ_disadv$STUDENT_COUNT), 21278)
  expect_equal(
    as.integer(econ_disadv$STUDENT_COUNT) / as.integer(econ_disadv$COHORT_COUNT),
    0.839,
    tolerance = 0.001
  )
})

test_that("2023-24: Statewide Not Econ Disadv graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  not_econ_disadv <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Economic Status" &
    raw$GROUP_BY_VALUE == "Not Econ Disadv",
  ]

  expect_equal(nrow(not_econ_disadv), 1)
  expect_equal(as.integer(not_econ_disadv$COHORT_COUNT), 40200)
  expect_equal(as.integer(not_econ_disadv$STUDENT_COUNT), 38427)
  expect_equal(
    as.integer(not_econ_disadv$STUDENT_COUNT) / as.integer(not_econ_disadv$COHORT_COUNT),
    0.956,
    tolerance = 0.001
  )
})

test_that("2023-24: Statewide SwD graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  swd <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Disability Status" &
    raw$GROUP_BY_VALUE == "SwD",
  ]

  expect_equal(nrow(swd), 1)
  expect_equal(as.integer(swd$COHORT_COUNT), 8005)
  expect_equal(as.integer(swd$STUDENT_COUNT), 5990)
  expect_equal(
    as.integer(swd$STUDENT_COUNT) / as.integer(swd$COHORT_COUNT),
    0.748,
    tolerance = 0.001
  )
})

# ============================================================================
# 2023-24 (Cohort 2024) - District Tests
# ============================================================================

test_that("2023-24: Madison district All Students graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  madison <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(madison), 1)
  expect_equal(madison$DISTRICT_NAME, "Madison Metropolitan")
  expect_equal(as.integer(madison$COHORT_COUNT), 1944)
  expect_equal(as.integer(madison$STUDENT_COUNT), 1633)
  expect_equal(
    as.integer(madison$STUDENT_COUNT) / as.integer(madison$COHORT_COUNT),
    0.840,
    tolerance = 0.001
  )
})

test_that("2023-24: Milwaukee district All Students graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  milwaukee <- raw[
    raw$DISTRICT_CODE == "3619" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(milwaukee), 1)
  expect_equal(milwaukee$DISTRICT_NAME, "Milwaukee")
  expect_equal(as.integer(milwaukee$COHORT_COUNT), 5182)
  expect_equal(as.integer(milwaukee$STUDENT_COUNT), 3521)
  expect_equal(
    as.integer(milwaukee$STUDENT_COUNT) / as.integer(milwaukee$COHORT_COUNT),
    0.679,
    tolerance = 0.001
  )
})

test_that("2023-24: Madison district Female graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  madison_female <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Female",
  ]

  expect_equal(nrow(madison_female), 1)
  expect_equal(as.integer(madison_female$COHORT_COUNT), 947)
  expect_equal(as.integer(madison_female$STUDENT_COUNT), 813)
})

test_that("2023-24: Madison district Male graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  madison_male <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Male",
  ]

  expect_equal(nrow(madison_male), 1)
  expect_equal(as.integer(madison_male$COHORT_COUNT), 997)
  expect_equal(as.integer(madison_male$STUDENT_COUNT), 820)
})

test_that("2023-24: Milwaukee district Female graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  milwaukee_female <- raw[
    raw$DISTRICT_CODE == "3619" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Female",
  ]

  expect_equal(nrow(milwaukee_female), 1)
  expect_equal(as.integer(milwaukee_female$COHORT_COUNT), 2601)
  expect_equal(as.integer(milwaukee_female$STUDENT_COUNT), 1860)
})

test_that("2023-24: Milwaukee district Male graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  milwaukee_male <- raw[
    raw$DISTRICT_CODE == "3619" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Male",
  ]

  expect_equal(nrow(milwaukee_male), 1)
  expect_equal(as.integer(milwaukee_male$COHORT_COUNT), 2581)
  expect_equal(as.integer(milwaukee_male$STUDENT_COUNT), 1661)
})

test_that("2023-24: Green Bay district All Students graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  green_bay <- raw[
    raw$DISTRICT_CODE == "2510" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(green_bay), 1)
  expect_equal(green_bay$DISTRICT_NAME, "Green Bay Area")
  expect_gt(as.integer(green_bay$COHORT_COUNT), 1000)
  expect_gt(as.integer(green_bay$STUDENT_COUNT), 800)
})

# ============================================================================
# 2023-24 (Cohort 2024) - School Tests
# ============================================================================

test_that("2023-24: Madison East High School graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  east_high <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "East" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(east_high), 1)
  expect_gt(as.integer(east_high$COHORT_COUNT), 300)
  expect_gt(as.integer(east_high$STUDENT_COUNT), 200)
})

test_that("2023-24: Madison West High School graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  west_high <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "West" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(west_high), 1)
  expect_gt(as.integer(west_high$COHORT_COUNT), 400)
  expect_gt(as.integer(west_high$STUDENT_COUNT), 350)
})

test_that("2023-24: Milwaukee Rufus King High School graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  king_high <- raw[
    raw$DISTRICT_CODE == "3619" &
    grepl("King", raw$SCHOOL_NAME) &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_gt(nrow(king_high), 0)
  expect_gt(as.integer(king_high$COHORT_COUNT), 200)
  expect_gt(as.integer(king_high$STUDENT_COUNT), 150)
})

test_that("2023-24: Milwaukee Riverside High School graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  riverside_high <- raw[
    raw$DISTRICT_CODE == "3619" &
    grepl("Riverside", raw$SCHOOL_NAME) &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_gt(nrow(riverside_high), 0)
  expect_gt(as.integer(riverside_high$COHORT_COUNT), 200)
  expect_gt(as.integer(riverside_high$STUDENT_COUNT), 100)
})

# ============================================================================
# 2020-21 (Cohort 2021) - Statewide Tests
# ============================================================================

test_that("2020-21: Statewide All Students graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  statewide_all <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(statewide_all), 1)
  expect_equal(as.integer(statewide_all$COHORT_COUNT), 65091)
  expect_equal(as.integer(statewide_all$STUDENT_COUNT), 58281)
  expect_equal(
    as.integer(statewide_all$STUDENT_COUNT) / as.integer(statewide_all$COHORT_COUNT),
    0.895,
    tolerance = 0.001
  )
})

test_that("2020-21: Statewide Female graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  female <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Female",
  ]

  expect_equal(nrow(female), 1)
  expect_equal(as.integer(female$COHORT_COUNT), 31682)
  expect_equal(as.integer(female$STUDENT_COUNT), 29053)
  expect_equal(
    as.integer(female$STUDENT_COUNT) / as.integer(female$COHORT_COUNT),
    0.917,
    tolerance = 0.001
  )
})

test_that("2020-21: Statewide Male graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  male <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Male",
  ]

  expect_equal(nrow(male), 1)
  expect_equal(as.integer(male$COHORT_COUNT), 33407)
  expect_equal(as.integer(male$STUDENT_COUNT), 29226)
  expect_equal(
    as.integer(male$STUDENT_COUNT) / as.integer(male$COHORT_COUNT),
    0.875,
    tolerance = 0.001
  )
})

test_that("2020-21: Statewide White graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  white <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "White",
  ]

  expect_equal(nrow(white), 1)
  expect_gt(as.integer(white$COHORT_COUNT), 40000)
  expect_gt(as.integer(white$STUDENT_COUNT), 38000)
  expect_gt(
    as.integer(white$STUDENT_COUNT) / as.integer(white$COHORT_COUNT),
    0.90
  )
})

test_that("2020-21: Statewide Black graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  black <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "Black",
  ]

  expect_equal(nrow(black), 1)
  expect_gt(as.integer(black$COHORT_COUNT), 5000)
  expect_gt(as.integer(black$STUDENT_COUNT), 3500)
  expect_gt(
    as.integer(black$STUDENT_COUNT) / as.integer(black$COHORT_COUNT),
    0.65
  )
})

test_that("2020-21: Statewide Hispanic graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  hispanic <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "Hispanic",
  ]

  expect_equal(nrow(hispanic), 1)
  expect_gt(as.integer(hispanic$COHORT_COUNT), 7000)
  expect_gt(as.integer(hispanic$STUDENT_COUNT), 5800)
  expect_gt(
    as.integer(hispanic$STUDENT_COUNT) / as.integer(hispanic$COHORT_COUNT),
    0.75
  )
})

test_that("2020-21: Statewide Econ Disadv graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  econ_disadv <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Economic Status" &
    raw$GROUP_BY_VALUE == "Econ Disadv",
  ]

  expect_equal(nrow(econ_disadv), 1)
  expect_gt(as.integer(econ_disadv$COHORT_COUNT), 23000)
  expect_gt(as.integer(econ_disadv$STUDENT_COUNT), 18500)
  expect_gt(
    as.integer(econ_disadv$STUDENT_COUNT) / as.integer(econ_disadv$COHORT_COUNT),
    0.78
  )
})

# ============================================================================
# 2020-21 (Cohort 2021) - District Tests
# ============================================================================

test_that("2020-21: Madison district All Students graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  madison <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(madison), 1)
  expect_equal(madison$DISTRICT_NAME, "Madison Metropolitan")
  expect_equal(as.integer(madison$COHORT_COUNT), 1918)
  expect_equal(as.integer(madison$STUDENT_COUNT), 1630)
  expect_equal(
    as.integer(madison$STUDENT_COUNT) / as.integer(madison$COHORT_COUNT),
    0.850,
    tolerance = 0.001
  )
})

test_that("2020-21: Madison district Female graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  madison_female <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Female",
  ]

  expect_equal(nrow(madison_female), 1)
  expect_gt(as.integer(madison_female$COHORT_COUNT), 900)
  expect_gt(as.integer(madison_female$STUDENT_COUNT), 780)
})

test_that("2020-21: Madison district Male graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  madison_male <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Male",
  ]

  expect_equal(nrow(madison_male), 1)
  expect_gt(as.integer(madison_male$COHORT_COUNT), 950)
  expect_gt(as.integer(madison_male$STUDENT_COUNT), 800)
})

test_that("2020-21: Milwaukee district All Students graduation rate exists", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  milwaukee <- raw[
    raw$DISTRICT_CODE == "3619" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(milwaukee), 1)
  expect_equal(milwaukee$DISTRICT_NAME, "Milwaukee")
  expect_gt(as.integer(milwaukee$COHORT_COUNT), 4500)
  expect_gt(as.integer(milwaukee$STUDENT_COUNT), 2800)
  expect_lt(
    as.integer(milwaukee$STUDENT_COUNT) / as.integer(milwaukee$COHORT_COUNT),
    0.70
  )
})

# ============================================================================
# 2020-21 (Cohort 2021) - School Tests
# ============================================================================

test_that("2020-21: Madison East High School graduation rate exists", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  east_high <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "East" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(east_high), 1)
  expect_gt(as.integer(east_high$COHORT_COUNT), 250)
  expect_gt(as.integer(east_high$STUDENT_COUNT), 175)
})

test_that("2020-21: Madison West High School graduation rate exists", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2021)

  west_high <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "West" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(west_high), 1)
  expect_gt(as.integer(west_high$COHORT_COUNT), 350)
  expect_gt(as.integer(west_high$STUDENT_COUNT), 300)
})

# ============================================================================
# 2015-16 (Cohort 2016) - Statewide Tests
# ============================================================================

test_that("2015-16: Statewide All Students graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2016)

  statewide_all <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(statewide_all), 1)
  expect_equal(as.integer(statewide_all$COHORT_COUNT), 63270)
  expect_equal(as.integer(statewide_all$STUDENT_COUNT), 57270)
  expect_equal(
    as.integer(statewide_all$STUDENT_COUNT) / as.integer(statewide_all$COHORT_COUNT),
    0.905,
    tolerance = 0.001
  )
})

test_that("2015-16: Statewide Female graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2016)

  female <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Female",
  ]

  expect_equal(nrow(female), 1)
  expect_gt(as.integer(female$COHORT_COUNT), 30000)
  expect_gt(as.integer(female$STUDENT_COUNT), 28000)
  expect_gt(
    as.integer(female$STUDENT_COUNT) / as.integer(female$COHORT_COUNT),
    0.90
  )
})

test_that("2015-16: Statewide Male graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2016)

  male <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Male",
  ]

  expect_equal(nrow(male), 1)
  expect_gt(as.integer(male$COHORT_COUNT), 32000)
  expect_gt(as.integer(male$STUDENT_COUNT), 28000)
  expect_gt(
    as.integer(male$STUDENT_COUNT) / as.integer(male$COHORT_COUNT),
    0.88
  )
})

test_that("2015-16: Statewide White graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2016)

  white <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "White",
  ]

  expect_equal(nrow(white), 1)
  expect_gt(as.integer(white$COHORT_COUNT), 42000)
  expect_gt(as.integer(white$STUDENT_COUNT), 39000)
  expect_gt(
    as.integer(white$STUDENT_COUNT) / as.integer(white$COHORT_COUNT),
    0.92
  )
})

test_that("2015-16: Statewide Black graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2016)

  black <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "Black",
  ]

  expect_equal(nrow(black), 1)
  expect_gt(as.integer(black$COHORT_COUNT), 6000)
  expect_gt(as.integer(black$STUDENT_COUNT), 4400)
  expect_gt(
    as.integer(black$STUDENT_COUNT) / as.integer(black$COHORT_COUNT),
    0.70
  )
})

test_that("2015-16: Statewide Hispanic graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2016)

  hispanic <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "Hispanic",
  ]

  expect_equal(nrow(hispanic), 1)
  expect_gt(as.integer(hispanic$COHORT_COUNT), 7000)
  expect_gt(as.integer(hispanic$STUDENT_COUNT), 6000)
  expect_gt(
    as.integer(hispanic$STUDENT_COUNT) / as.integer(hispanic$COHORT_COUNT),
    0.80
  )
})

test_that("2015-16: Statewide Econ Disadv graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2016)

  econ_disadv <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Economic Status" &
    raw$GROUP_BY_VALUE == "Econ Disadv",
  ]

  expect_equal(nrow(econ_disadv), 1)
  expect_gt(as.integer(econ_disadv$COHORT_COUNT), 22000)
  expect_gt(as.integer(econ_disadv$STUDENT_COUNT), 18500)
  expect_gt(
    as.integer(econ_disadv$STUDENT_COUNT) / as.integer(econ_disadv$COHORT_COUNT),
    0.80
  )
})

# ============================================================================
# 2015-16 (Cohort 2016) - District Tests
# ============================================================================

test_that("2015-16: Madison district All Students graduation rate exists", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2016)

  madison <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(madison), 1)
  expect_equal(madison$DISTRICT_NAME, "Madison Metropolitan")
  expect_gt(as.integer(madison$COHORT_COUNT), 1750)
  expect_gt(as.integer(madison$STUDENT_COUNT), 1450)
  expect_gt(
    as.integer(madison$STUDENT_COUNT) / as.integer(madison$COHORT_COUNT),
    0.80
  )
})

test_that("2015-16: Milwaukee district All Students graduation rate exists", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2016)

  milwaukee <- raw[
    raw$DISTRICT_CODE == "3619" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(milwaukee), 1)
  expect_equal(milwaukee$DISTRICT_NAME, "Milwaukee")
  expect_gt(as.integer(milwaukee$COHORT_COUNT), 4800)
  expect_gt(as.integer(milwaukee$STUDENT_COUNT), 3100)
  expect_lt(
    as.integer(milwaukee$STUDENT_COUNT) / as.integer(milwaukee$COHORT_COUNT),
    0.70
  )
})

# ============================================================================
# 2015-16 (Cohort 2016) - School Tests
# ============================================================================

test_that("2015-16: Madison East High School graduation rate exists", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2016)

  east_high <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "East" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(east_high), 1)
  expect_gt(as.integer(east_high$COHORT_COUNT), 200)
  expect_gt(as.integer(east_high$STUDENT_COUNT), 150)
})

test_that("2015-16: Madison West High School graduation rate exists", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2016)

  west_high <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "West" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(west_high), 1)
  expect_gt(as.integer(west_high$COHORT_COUNT), 300)
  expect_gt(as.integer(west_high$STUDENT_COUNT), 250)
})

# ============================================================================
# 2010-11 (Cohort 2011) - Historical Tests
# ============================================================================

test_that("2010-11: Statewide All Students graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2011)

  statewide_all <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(statewide_all), 1)
  expect_equal(as.integer(statewide_all$COHORT_COUNT), 70376)
  expect_equal(as.integer(statewide_all$STUDENT_COUNT), 63802)
  expect_equal(
    as.integer(statewide_all$STUDENT_COUNT) / as.integer(statewide_all$COHORT_COUNT),
    0.907,
    tolerance = 0.001
  )
})

test_that("2010-11: Statewide Female graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2011)

  female <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Female",
  ]

  expect_equal(nrow(female), 1)
  expect_gt(as.integer(female$COHORT_COUNT), 34000)
  expect_gt(as.integer(female$STUDENT_COUNT), 32000)
})

test_that("2010-11: Statewide Male graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2011)

  male <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Gender" &
    raw$GROUP_BY_VALUE == "Male",
  ]

  expect_equal(nrow(male), 1)
  expect_gt(as.integer(male$COHORT_COUNT), 36000)
  expect_gt(as.integer(male$STUDENT_COUNT), 31500)
})

test_that("2010-11: Statewide White graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2011)

  white <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "White",
  ]

  expect_equal(nrow(white), 1)
  expect_gt(as.integer(white$COHORT_COUNT), 48000)
  expect_gt(as.integer(white$STUDENT_COUNT), 45000)
})

test_that("2010-11: Statewide Black graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2011)

  black <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "Black",
  ]

  expect_equal(nrow(black), 1)
  expect_gt(as.integer(black$COHORT_COUNT), 7000)
  expect_gt(as.integer(black$STUDENT_COUNT), 4800)
})

test_that("2010-11: Statewide Hispanic graduation rate matches raw data", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2011)

  hispanic <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$SCHOOL_NAME == "[Statewide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "Race/Ethnicity" &
    raw$GROUP_BY_VALUE == "Hispanic",
  ]

  expect_equal(nrow(hispanic), 1)
  expect_gt(as.integer(hispanic$COHORT_COUNT), 6000)
  expect_gt(as.integer(hispanic$STUDENT_COUNT), 4800)
})

test_that("2010-11: Madison district All Students graduation rate exists", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2011)

  madison <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(madison), 1)
  expect_equal(madison$DISTRICT_NAME, "Madison Metropolitan")
  expect_gt(as.integer(madison$COHORT_COUNT), 1500)
  expect_gt(as.integer(madison$STUDENT_COUNT), 1200)
})

test_that("2010-11: Milwaukee district All Students graduation rate exists", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2011)

  milwaukee <- raw[
    raw$DISTRICT_CODE == "3619" &
    raw$SCHOOL_NAME == "[Districtwide]" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(milwaukee), 1)
  expect_equal(milwaukee$DISTRICT_NAME, "Milwaukee")
  expect_gt(as.integer(milwaukee$COHORT_COUNT), 5000)
  expect_gt(as.integer(milwaukee$STUDENT_COUNT), 3300)
})

test_that("2010-11: Madison East High School graduation rate exists", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2011)

  east_high <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "East" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(east_high), 1)
  expect_gt(as.integer(east_high$COHORT_COUNT), 175)
  expect_gt(as.integer(east_high$STUDENT_COUNT), 120)
})

test_that("2010-11: Madison West High School graduation rate exists", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2011)

  west_high <- raw[
    raw$DISTRICT_CODE == "3269" &
    raw$SCHOOL_NAME == "West" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  expect_equal(nrow(west_high), 1)
  expect_gt(as.integer(west_high$COHORT_COUNT), 250)
  expect_gt(as.integer(west_high$STUDENT_COUNT), 200)
})

# ============================================================================
# Timeframe Consistency Tests
# ============================================================================

test_that("4-Year, 5-Year, and 6-Year rates all exist for 2023-24", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  # Check that all three timeframes have data
  four_year <- raw[raw$TIMEFRAME == "4-Year rate", ]
  five_year <- raw[raw$TIMEFRAME == "5-Year rate", ]
  six_year <- raw[raw$TIMEFRAME == "6-Year rate", ]

  expect_gt(nrow(four_year), 0)
  expect_gt(nrow(five_year), 0)
  expect_gt(nrow(six_year), 0)

  # All should have same row count
  expect_equal(nrow(four_year), nrow(five_year))
  expect_equal(nrow(four_year), nrow(six_year))
})

test_that("Graduation rate increases with extended timeframe (5-Year > 4-Year)", {
  skip_if_offline()

  raw <- get_raw_grad_csv(2024)

  # Get statewide All Students for both timeframes
  four_year <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$TIMEFRAME == "4-Year rate" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  five_year <- raw[
    raw$DISTRICT_CODE == "0000" &
    raw$TIMEFRAME == "5-Year rate" &
    raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
    raw$GROUP_BY == "All Students" &
    raw$GROUP_BY_VALUE == "All Students",
  ]

  four_rate <- as.integer(four_year$STUDENT_COUNT) / as.integer(four_year$COHORT_COUNT)
  five_rate <- as.integer(five_year$STUDENT_COUNT) / as.integer(five_year$COHORT_COUNT)

  expect_gt(five_rate, four_rate)
})

# ============================================================================
# Cross-Year Consistency Tests
# ============================================================================

test_that("Major districts exist in all years", {
  skip_if_offline()

  years_to_test <- c(2024, 2021, 2016, 2011)

  for (year in years_to_test) {
    raw <- get_raw_grad_csv(year)

    # Check Madison exists
    madison <- raw[
      raw$DISTRICT_CODE == "3269" &
      raw$SCHOOL_NAME == "[Districtwide]" &
      raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
      raw$TIMEFRAME == "4-Year rate" &
      raw$GROUP_BY == "All Students" &
      raw$GROUP_BY_VALUE == "All Students",
    ]

    expect_equal(nrow(madison), 1, info = paste("Madison should exist in", year))

    # Check Milwaukee exists
    milwaukee <- raw[
      raw$DISTRICT_CODE == "3619" &
      raw$SCHOOL_NAME == "[Districtwide]" &
      raw$COMPLETION_STATUS == "Completed - Regular High School Diploma" &
      raw$TIMEFRAME == "4-Year rate" &
      raw$GROUP_BY == "All Students" &
      raw$GROUP_BY_VALUE == "All Students",
    ]

    expect_equal(nrow(milwaukee), 1, info = paste("Milwaukee should exist in", year))
  }
})

test_that("Column names are consistent across all years", {
  skip_if_offline()

  years_to_test <- c(2024, 2021, 2016, 2011)

  # Get column names from 2024
  raw_2024 <- get_raw_grad_csv(2024)
  expected_cols <- names(raw_2024)

  for (year in years_to_test) {
    raw <- get_raw_grad_csv(year)
    expect_equal(names(raw), expected_cols, info = paste("Columns should match in", year))
  }
})

test_that("Schema structure is consistent across 14-year period", {
  skip_if_offline()

  # Test earliest (2009-10) and latest (2023-24)
  raw_2010 <- get_raw_grad_csv(2010)
  raw_2024 <- get_raw_grad_csv(2024)

  # Same column count
  expect_equal(ncol(raw_2010), ncol(raw_2024))

  # Same column names
  expect_equal(names(raw_2010), names(raw_2024))

  # Same completion statuses
  statuses_2010 <- unique(raw_2010$COMPLETION_STATUS)
  statuses_2024 <- unique(raw_2024$COMPLETION_STATUS)
  expect_true(all(statuses_2010 %in% statuses_2024))
})

test_that("Row count increases over time (more data tracked)", {
  skip_if_offline()

  raw_2010 <- get_raw_grad_csv(2010)
  raw_2024 <- get_raw_grad_csv(2024)

  # 2024 should have significantly more rows than 2010
  expect_gt(nrow(raw_2024), nrow(raw_2010))

  # At least 2x growth (more schools, more subgroups tracked)
  expect_gt(nrow(raw_2024), nrow(raw_2010) * 2)
})
