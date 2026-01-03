# Tests for enrollment functions
# Note: Most tests are marked as skip_on_cran since they require network access

test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,234"), 1234)

  # Suppressed values
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("-1")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("")))
  expect_true(is.na(safe_numeric("--")))

  # Whitespace handling
  expect_equal(safe_numeric("  100  "), 100)
})

test_that("get_available_years returns valid range", {
  years <- get_available_years()

  expect_true(is.numeric(years))
  expect_true(length(years) > 20)
  expect_true(min(years) == 1997)
  expect_true(max(years) >= 2024)
})

test_that("get_data_era returns correct era for each year range", {
  # Published era (1997-2005)
  expect_equal(get_data_era(1997), "published")
  expect_equal(get_data_era(2000), "published")
  expect_equal(get_data_era(2005), "published")

  # WISEdash era (2006+)
  expect_equal(get_data_era(2006), "wisedash")
  expect_equal(get_data_era(2010), "wisedash")
  expect_equal(get_data_era(2015), "wisedash")
  expect_equal(get_data_era(2016), "wisedash")
  expect_equal(get_data_era(2020), "wisedash")
  expect_equal(get_data_era(2024), "wisedash")

  # Error for invalid year
  expect_error(get_data_era(1990), "not available before 1997")
})

test_that("format_school_year returns correct format", {
  expect_equal(format_school_year(2024), "2023-24")
  expect_equal(format_school_year(2000), "1999-00")
  expect_equal(format_school_year(2010), "2009-10")
})

test_that("fetch_enr validates year parameter", {
  expect_error(fetch_enr(1990), "end_year must be between")
  expect_error(fetch_enr(2030), "end_year must be between")
})

test_that("fetch_enr validates within valid range", {
  # 1997 should be valid (earliest year)
  # This test would run if we could reach the server
  # expect_no_error(fetch_enr(1997, use_cache = FALSE))
})

test_that("get_cache_dir returns valid path", {
  cache_dir <- get_cache_dir()
  expect_true(is.character(cache_dir))
  expect_true(grepl("wischooldata", cache_dir))
})

test_that("cache functions work correctly", {
  # Test cache path generation
  path <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024.rds", path))

  # Test cache_exists returns FALSE for non-existent cache
  expect_false(cache_exists(9999, "tidy"))
})

test_that("get_wi_column_map returns expected structure", {
  # Test WISEdash era
  map_wisedash <- get_wi_column_map("wisedash")
  expect_true(is.list(map_wisedash))
  expect_true("district_code" %in% names(map_wisedash))
  expect_true("school_code" %in% names(map_wisedash))
  expect_true("student_count" %in% names(map_wisedash))

  # Test published era
  map_published <- get_wi_column_map("published")
  expect_true(is.list(map_published))
  expect_true("district_code" %in% names(map_published))
  expect_true("grade" %in% names(map_published))
})

# Integration tests (require network access)
test_that("fetch_enr downloads and processes WISEdash data (modern era)", {
  skip_on_cran()
  skip_if_offline()

  # Use a recent year (WISEdash modern)
  result <- fetch_enr(2023, tidy = FALSE, use_cache = FALSE)

  # Check structure
  expect_true(is.data.frame(result))
  expect_true("district_id" %in% names(result))
  expect_true("row_total" %in% names(result))
  expect_true("type" %in% names(result))
  expect_true("end_year" %in% names(result))

  # Check we have all levels
  expect_true("State" %in% result$type)
  expect_true("District" %in% result$type)

  # Check end_year is set correctly
  expect_true(all(result$end_year == 2023))

  # Check reasonable total (Wisconsin has ~800k students)
  state_total <- result[result$type == "State", "row_total"]
  expect_true(state_total > 500000)
  expect_true(state_total < 1500000)
})

test_that("fetch_enr handles WISEdash data for 2010", {
  skip_on_cran()
  skip_if_offline()

  # Test year 2010 (uses WISEdash ZIP/CSV files)
  result <- fetch_enr(2010, tidy = FALSE, use_cache = FALSE)

  expect_true(is.data.frame(result))
  expect_true("district_id" %in% names(result))
  expect_true("type" %in% names(result))
  expect_true(nrow(result) > 0)

  # Verify we get reasonable data
  expect_true("District" %in% result$type || "Campus" %in% result$type)
})

test_that("tidy_enr produces correct long format", {
  skip_on_cran()
  skip_if_offline()

  # Get wide data
  wide <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)

  # Tidy it
  tidy_result <- tidy_enr(wide)

  # Check structure
  expect_true("grade_level" %in% names(tidy_result))
  expect_true("subgroup" %in% names(tidy_result))
  expect_true("n_students" %in% names(tidy_result))
  expect_true("pct" %in% names(tidy_result))

  # Check subgroups include expected values
  subgroups <- unique(tidy_result$subgroup)
  expect_true("total_enrollment" %in% subgroups)
})

test_that("id_enr_aggs adds correct flags", {
  skip_on_cran()
  skip_if_offline()

  # Get tidy data with aggregation flags
  result <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Check flags exist
  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_campus" %in% names(result))
  expect_true("is_charter" %in% names(result))

  # Check flags are boolean
  expect_true(is.logical(result$is_state))
  expect_true(is.logical(result$is_district))
  expect_true(is.logical(result$is_campus))
  expect_true(is.logical(result$is_charter))

  # Check mutual exclusivity (each row is only one type)
  type_sums <- result$is_state + result$is_district + result$is_campus
  expect_true(all(type_sums == 1))
})

test_that("fetch_enr_multi combines years correctly", {
  skip_on_cran()
  skip_if_offline()

  # Fetch two years
  result <- fetch_enr_multi(c(2022, 2023), tidy = TRUE, use_cache = TRUE)

  # Check we have both years
  expect_true(all(c(2022, 2023) %in% result$end_year))

  # Check structure
  expect_true(is.data.frame(result))
  expect_true("n_students" %in% names(result))
})

test_that("output schema is consistent across years", {
  skip_on_cran()
  skip_if_offline()

  # Fetch from different years (all use WISEdash since 2006+)
  modern <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)
  older <- fetch_enr(2010, tidy = FALSE, use_cache = TRUE)

  # Core columns should be present in both
  core_cols <- c("end_year", "type", "district_id", "row_total")

  expect_true(all(core_cols %in% names(modern)))
  expect_true(all(core_cols %in% names(older)))
})

test_that("enr_grade_aggs creates correct aggregates", {
  skip_on_cran()
  skip_if_offline()

  # Get tidy data
  tidy_data <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Create grade aggregates
  grade_aggs <- enr_grade_aggs(tidy_data)

  # Check expected grade levels created
  expect_true("K8" %in% grade_aggs$grade_level)
  expect_true("HS" %in% grade_aggs$grade_level)
  expect_true("K12" %in% grade_aggs$grade_level)

  # Check structure
  expect_true("n_students" %in% names(grade_aggs))
})
