#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

#' wischooldata: Wisconsin School Enrollment Data
#'
#' An R package for fetching and analyzing Wisconsin public school enrollment
#' data from the Wisconsin Department of Public Instruction (DPI).
#'
#' @section Data Sources:
#'
#' Wisconsin enrollment data is available through two systems:
#'
#' - **WISEdash** (2016-present): Modern data portal with CSV downloads
#' - **Published Excel files** (1997-2015): Historical Excel workbooks
#'
#' The package handles both formats transparently, providing a consistent
#' interface across all available years.
#'
#' @section Main Functions:
#'
#' - [fetch_enr()]: Download enrollment data for a single year
#' - [fetch_enr_multi()]: Download enrollment data for multiple years
#' - [tidy_enr()]: Transform wide data to tidy (long) format
#' - [get_available_years()]: List available data years
#'
#' @section Wisconsin ID System:
#'
#' Wisconsin uses a hierarchical ID system:
#'
#' - **District Code**: 4 digits (e.g., "3269" for Madison Metropolitan)
#' - **School Code**: 8-9 characters (district-school, e.g., "3269-0280")
#' - **CESA**: Cooperative Educational Service Agency (12 regions)
#'
#' @section Data Availability:
#'
#' | Era | Years | Source | Format |
#' |-----|-------|--------|--------|
#' | WINSS/Published | 1997-2005 | Published Excel | Wide format |
#' | WISEdash Early | 2006-2015 | Published Excel | Wide format |
#' | WISEdash Modern | 2016-present | WISEdash CSV | Long format |
#'
#' @section Known Limitations:
#'
#' - Pre-2011 data combines Asian and Pacific Islander categories
#' - Two or More Races category available starting 2010-11
#' - Economic disadvantage definitions vary by year
#' - Small cell sizes may be suppressed (<5 students)
#'
#' @docType package
#' @name wischooldata-package
NULL
