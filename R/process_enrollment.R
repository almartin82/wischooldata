# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw Wisconsin DPI enrollment data
# into a clean, standardized format.
#
# Wisconsin has two main data eras:
# - Published Excel files (1997-2015): Wide format with grades as columns
# - WISEdash CSV files (2016+): Long format with grade as a row variable
#
# ==============================================================================

#' Process raw Wisconsin DPI enrollment data
#'
#' Transforms raw DPI data into a standardized schema.
#' Handles both WISEdash (long format) and published Excel (wide format) data.
#'
#' @param raw_data Data frame from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  era <- get_data_era(end_year)

  if (era == "wisedash_modern") {
    result <- process_wisedash_enr(raw_data, end_year)
  } else {
    result <- process_published_enr(raw_data, end_year)
  }

  # Create state aggregate
  state_agg <- create_state_aggregate(result, end_year)

  # Combine
  dplyr::bind_rows(state_agg, result)
}


#' Process WISEdash enrollment data (2016+)
#'
#' WISEdash data is in long format with one row per school/grade/group combination.
#' This function pivots to wide format matching the standard schema.
#'
#' The data structure has:
#' - GROUP_BY: Disability, Race/Ethnicity, Gender, Economic Status, EL Status, etc.
#' - GROUP_BY_VALUE: Specific values (e.g., "White", "Male", "Economically Disadvantaged")
#' - GROUP_COUNT: Total enrollment for the grade/school (used as denominator)
#' - STUDENT_COUNT: Count for the specific subgroup
#'
#' @param df Raw WISEdash data frame
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_wisedash_enr <- function(df, end_year) {

  cols <- names(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  col_map <- get_wi_column_map("wisedash_modern")

  # Find key columns
  district_code_col <- find_col(c("DISTRICT_CODE", "District Code"))
  district_name_col <- find_col(c("DISTRICT_NAME", "District Name"))
  school_code_col <- find_col(c("SCHOOL_CODE", "School Code"))
  school_name_col <- find_col(c("SCHOOL_NAME", "School Name"))
  grade_col <- find_col(c("GRADE_LEVEL", "Grade Level", "GRADE"))
  group_col <- find_col(c("GROUP_BY", "Group By"))
  group_val_col <- find_col(c("GROUP_BY_VALUE", "Group By Value"))
  count_col <- find_col(c("STUDENT_COUNT", "Student Count"))
  group_count_col <- find_col(c("GROUP_COUNT", "Group Count"))
  charter_col <- find_col(c("CHARTER_IND", "Charter Indicator"))
  county_col <- find_col(c("COUNTY", "County"))
  cesa_col <- find_col(c("CESA", "Cesa"))

  # Standardize column names
  if (!is.null(district_code_col)) names(df)[names(df) == district_code_col] <- "district_id"
  if (!is.null(district_name_col)) names(df)[names(df) == district_name_col] <- "district_name"
  if (!is.null(school_code_col)) names(df)[names(df) == school_code_col] <- "campus_id"
  if (!is.null(school_name_col)) names(df)[names(df) == school_name_col] <- "campus_name"
  if (!is.null(grade_col)) names(df)[names(df) == grade_col] <- "grade"
  if (!is.null(group_col)) names(df)[names(df) == group_col] <- "group_by"
  if (!is.null(group_val_col)) names(df)[names(df) == group_val_col] <- "group_value"
  if (!is.null(count_col)) names(df)[names(df) == count_col] <- "student_count"
  if (!is.null(group_count_col)) names(df)[names(df) == group_count_col] <- "group_count"
  if (!is.null(charter_col)) names(df)[names(df) == charter_col] <- "charter_flag"
  if (!is.null(county_col)) names(df)[names(df) == county_col] <- "county"
  if (!is.null(cesa_col)) names(df)[names(df) == cesa_col] <- "cesa"

  # Convert counts to numeric
  if ("student_count" %in% names(df)) {
    df$student_count <- safe_numeric(df$student_count)
  }
  if ("group_count" %in% names(df)) {
    df$group_count <- safe_numeric(df$group_count)
  }

  # Create grade_clean column for pivoting
  # Wisconsin has: K3 (3-year kindergarten), K4 (4K), KG (kindergarten), PK, and grades 1-12
  df <- df |>
    dplyr::mutate(
      grade_clean = dplyr::case_when(
        grade %in% c("PK", "K3") ~ "grade_pk",  # Pre-K and 3-year-old kindergarten
        grade == "K4" ~ "grade_pk4",             # 4-year-old kindergarten (Wisconsin's 4K)
        grade == "KG" ~ "grade_k",               # Regular kindergarten
        grade == "1" ~ "grade_01",
        grade == "2" ~ "grade_02",
        grade == "3" ~ "grade_03",
        grade == "4" ~ "grade_04",
        grade == "5" ~ "grade_05",
        grade == "6" ~ "grade_06",
        grade == "7" ~ "grade_07",
        grade == "8" ~ "grade_08",
        grade == "9" ~ "grade_09",
        grade == "10" ~ "grade_10",
        grade == "11" ~ "grade_11",
        grade == "12" ~ "grade_12",
        TRUE ~ NA_character_
      )
    )

  # Filter out non-grade rows (keep only valid grades)
  df <- df |>
    dplyr::filter(!is.na(grade_clean))

  # =============================================
  # STEP 1: Get total enrollment by grade/school
  # Use GROUP_COUNT (total for that grade) from any row
  # WISEdash data has both:
  # - District-level rows: SCHOOL_CODE = "" (empty)
  # - School-level rows: SCHOOL_CODE = actual school code
  # - Statewide rows: DISTRICT_CODE = "0000"
  # =============================================

  # Get one row per district/school/grade to extract totals
  totals <- df |>
    dplyr::select(district_id, district_name, campus_id, campus_name,
                  dplyr::any_of(c("county", "cesa", "charter_flag")),
                  grade_clean, group_count) |>
    dplyr::distinct() |>
    dplyr::filter(!is.na(group_count))

  # School-level totals (where campus_id is not empty)
  school_totals <- totals |>
    dplyr::filter(!is.na(campus_id) & campus_id != "" & campus_id != "0" &
                  !is.na(district_id) & district_id != "0000") |>
    tidyr::pivot_wider(
      id_cols = c(district_id, district_name, campus_id, campus_name,
                  dplyr::any_of(c("county", "cesa", "charter_flag"))),
      names_from = grade_clean,
      values_from = group_count,
      values_fn = max,
      values_fill = 0
    )

  # Calculate row_total
  grade_cols <- grep("^grade_", names(school_totals), value = TRUE)
  if (length(grade_cols) > 0) {
    school_totals$row_total <- rowSums(school_totals[, grade_cols, drop = FALSE], na.rm = TRUE)
  }
  school_totals$type <- "Campus"
  school_totals$end_year <- end_year

  # District-level: use the district-level rows directly (campus_id is empty)
  # These rows already have the correct district totals - no need to aggregate
  district_totals <- totals |>
    dplyr::filter(!is.na(district_id) & district_id != "0000" &
                  (is.na(campus_id) | campus_id == "" | campus_id == "0")) |>
    tidyr::pivot_wider(
      id_cols = c(district_id, district_name, dplyr::any_of(c("county", "cesa"))),
      names_from = grade_clean,
      values_from = group_count,
      values_fn = max,
      values_fill = 0
    )

  grade_cols_d <- grep("^grade_", names(district_totals), value = TRUE)
  if (length(grade_cols_d) > 0) {
    district_totals$row_total <- rowSums(district_totals[, grade_cols_d, drop = FALSE], na.rm = TRUE)
  }
  district_totals$type <- "District"
  district_totals$end_year <- end_year
  district_totals$campus_id <- NA_character_
  district_totals$campus_name <- NA_character_

  # =============================================
  # STEP 2: Get demographics from GROUP_BY = "Race/Ethnicity", "Gender", etc.
  # =============================================

  # Race/Ethnicity
  race_data <- df |>
    dplyr::filter(group_by == "Race/Ethnicity") |>
    dplyr::mutate(
      demo_col = dplyr::case_when(
        grepl("White", group_value, ignore.case = TRUE) ~ "white",
        grepl("Black", group_value, ignore.case = TRUE) ~ "black",
        grepl("Hispanic", group_value, ignore.case = TRUE) ~ "hispanic",
        grepl("Asian", group_value, ignore.case = TRUE) ~ "asian",
        grepl("Amer Indian|American Indian", group_value, ignore.case = TRUE) ~ "native_american",
        grepl("Pacific", group_value, ignore.case = TRUE) ~ "pacific_islander",
        grepl("Two or More", group_value, ignore.case = TRUE) ~ "multiracial",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::filter(!is.na(demo_col))

  # Gender
  gender_data <- df |>
    dplyr::filter(group_by == "Gender") |>
    dplyr::mutate(
      demo_col = dplyr::case_when(
        grepl("^Male$", group_value, ignore.case = TRUE) ~ "male",
        grepl("^Female$", group_value, ignore.case = TRUE) ~ "female",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::filter(!is.na(demo_col))

  # Economic Status
  econ_data <- df |>
    dplyr::filter(group_by == "Economic Status") |>
    dplyr::mutate(
      demo_col = dplyr::case_when(
        grepl("Economically Disadvantaged", group_value, ignore.case = TRUE) ~ "econ_disadv",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::filter(!is.na(demo_col))

  # EL Status
  el_data <- df |>
    dplyr::filter(group_by == "EL Status") |>
    dplyr::mutate(
      demo_col = dplyr::case_when(
        grepl("^EL$|English Learner", group_value, ignore.case = TRUE) ~ "lep",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::filter(!is.na(demo_col))

  # Disability Status
  sped_data <- df |>
    dplyr::filter(group_by == "Disability Status") |>
    dplyr::mutate(
      demo_col = dplyr::case_when(
        grepl("^SWD$|Students with Disabilities", group_value, ignore.case = TRUE) ~ "special_ed",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::filter(!is.na(demo_col))

  # Combine all demographics
  all_demos <- dplyr::bind_rows(race_data, gender_data, econ_data, el_data, sped_data)

  if (nrow(all_demos) > 0) {
    # Aggregate demographics by school (sum across all grades)
    school_demos <- all_demos |>
      dplyr::filter(!is.na(campus_id) & campus_id != "" & campus_id != "0" &
                    !is.na(district_id) & district_id != "0000") |>
      dplyr::group_by(district_id, campus_id, demo_col) |>
      dplyr::summarize(
        count = sum(student_count, na.rm = TRUE),
        .groups = "drop"
      ) |>
      tidyr::pivot_wider(
        names_from = demo_col,
        values_from = count,
        values_fill = 0
      )

    # District demographics: use district-level rows (campus_id is empty)
    district_demos <- all_demos |>
      dplyr::filter(!is.na(district_id) & district_id != "0000" &
                    (is.na(campus_id) | campus_id == "" | campus_id == "0")) |>
      dplyr::group_by(district_id, demo_col) |>
      dplyr::summarize(
        count = sum(student_count, na.rm = TRUE),
        .groups = "drop"
      ) |>
      tidyr::pivot_wider(
        names_from = demo_col,
        values_from = count,
        values_fill = 0
      )

    # Join demographics to totals
    if (nrow(school_demos) > 0 && "campus_id" %in% names(school_totals)) {
      school_totals <- dplyr::left_join(
        school_totals, school_demos,
        by = c("district_id", "campus_id")
      )
    }

    if (nrow(district_demos) > 0) {
      district_totals <- dplyr::left_join(
        district_totals, district_demos,
        by = "district_id"
      )
    }
  }

  # Combine school and district data
  result <- dplyr::bind_rows(district_totals, school_totals)

  # Select and order columns
  # Note: Wisconsin has grade_pk4 (4-year-old kindergarten) which is unique to WI
  standard_cols <- c(
    "end_year", "type", "district_id", "campus_id", "district_name", "campus_name",
    "county", "cesa", "charter_flag", "row_total",
    "white", "black", "hispanic", "asian", "native_american", "pacific_islander", "multiracial",
    "male", "female", "econ_disadv", "lep", "special_ed",
    "grade_pk", "grade_pk4", "grade_k", "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08", "grade_09", "grade_10",
    "grade_11", "grade_12"
  )

  # Keep only columns that exist
  existing_cols <- standard_cols[standard_cols %in% names(result)]

  result <- result |>
    dplyr::select(dplyr::all_of(existing_cols))

  result
}


#' Process published enrollment data (1997-2015)
#'
#' Published Excel files are in wide format with grades as columns.
#'
#' @param df Raw Excel data frame
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_published_enr <- function(df, end_year) {

  cols <- names(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    # Try partial match
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  col_map <- get_wi_column_map("winss")

  # Build result dataframe
  n_rows <- nrow(df)

  result <- data.frame(
    end_year = rep(end_year, n_rows),
    stringsAsFactors = FALSE
  )

  # District ID
  dist_col <- find_col(col_map$district_code)
  if (!is.null(dist_col)) {
    result$district_id <- as.character(trimws(df[[dist_col]]))
  }

  # District name
  dist_name_col <- find_col(col_map$district_name)
  if (!is.null(dist_name_col)) {
    result$district_name <- trimws(df[[dist_name_col]])
  }

  # School/Campus ID
  school_col <- find_col(col_map$school_code)
  if (!is.null(school_col)) {
    result$campus_id <- as.character(trimws(df[[school_col]]))
  }

  # School/Campus name
  school_name_col <- find_col(col_map$school_name)
  if (!is.null(school_name_col)) {
    result$campus_name <- trimws(df[[school_name_col]])
  }

  # County
  county_col <- find_col(col_map$county)
  if (!is.null(county_col)) {
    result$county <- trimws(df[[county_col]])
  }

  # CESA (region)
  cesa_col <- find_col(col_map$cesa)
  if (!is.null(cesa_col)) {
    result$cesa <- trimws(df[[cesa_col]])
  }

  # Determine type based on presence of school ID
  if ("campus_id" %in% names(result)) {
    result$type <- ifelse(
      is.na(result$campus_id) | result$campus_id == "",
      "District",
      "Campus"
    )
  } else {
    result$type <- "District"
    result$campus_id <- NA_character_
    result$campus_name <- NA_character_
  }

  # Grade columns
  grade_map <- list(
    grade_pk = col_map$grade_pk,
    grade_k = col_map$grade_k,
    grade_01 = col_map$grade_01,
    grade_02 = col_map$grade_02,
    grade_03 = col_map$grade_03,
    grade_04 = col_map$grade_04,
    grade_05 = col_map$grade_05,
    grade_06 = col_map$grade_06,
    grade_07 = col_map$grade_07,
    grade_08 = col_map$grade_08,
    grade_09 = col_map$grade_09,
    grade_10 = col_map$grade_10,
    grade_11 = col_map$grade_11,
    grade_12 = col_map$grade_12
  )

  for (grade_name in names(grade_map)) {
    col <- find_col(grade_map[[grade_name]])
    if (!is.null(col)) {
      result[[grade_name]] <- safe_numeric(df[[col]])
    }
  }

  # Total column
  total_col <- find_col(col_map$total)
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  } else {
    # Calculate total from grade columns
    grade_cols <- grep("^grade_", names(result), value = TRUE)
    if (length(grade_cols) > 0) {
      result$row_total <- rowSums(result[, grade_cols, drop = FALSE], na.rm = TRUE)
    }
  }

  # Demographics
  demo_map <- list(
    male = col_map$male,
    female = col_map$female,
    white = col_map$white,
    black = col_map$black,
    hispanic = col_map$hispanic,
    asian = col_map$asian,
    native_american = col_map$native_american,
    pacific_islander = col_map$pacific_islander,
    multiracial = col_map$multiracial
  )

  for (demo_name in names(demo_map)) {
    col <- find_col(demo_map[[demo_name]])
    if (!is.null(col)) {
      result[[demo_name]] <- safe_numeric(df[[col]])
    }
  }

  # Remove rows with no data
  result <- result |>
    dplyr::filter(!is.na(row_total) | !is.na(district_id))

  result
}


#' Create state-level aggregate from district data
#'
#' @param df Processed data frame with district-level data
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(df, end_year) {

  # Get district-level data only
  district_df <- df |>
    dplyr::filter(type == "District")

  if (nrow(district_df) == 0) {
    return(data.frame())
  }

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "econ_disadv", "lep", "special_ed",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(district_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    stringsAsFactors = FALSE
  )

  # Add optional columns if they exist in source
  if ("county" %in% names(district_df)) state_row$county <- NA_character_
  if ("cesa" %in% names(district_df)) state_row$cesa <- NA_character_
  if ("charter_flag" %in% names(district_df)) state_row$charter_flag <- NA_character_

  # Sum each column
  for (col in sum_cols) {
    state_row[[col]] <- sum(district_df[[col]], na.rm = TRUE)
  }

  state_row
}
