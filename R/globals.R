# ==============================================================================
# Global Variables Declaration
# ==============================================================================
# This file declares global variables used in non-standard evaluation (NSE)
# to avoid R CMD CHECK notes about "no visible binding for global variable"

#' @importFrom utils unzip
NULL

utils::globalVariables(c(
  # Common columns used in dplyr pipelines
  "type",
  "subgroup",
  "grade_level",
  "n_students",
  "charter_flag",
  "row_total",
  "district_id",
  "grade_clean",
  "school_id",
  "school_name",
  "district_name",
  "end_year",
  "entity_type",
  "entity_name",
  "entity_id"
))
