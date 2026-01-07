# wischooldata: Wisconsin School Data

A simple, consistent interface for accessing Wisconsin school data in
Python and R.

An R package for fetching and analyzing Wisconsin public school
enrollment data from the Wisconsin Department of Public Instruction
(DPI).

## Data Sources

Wisconsin enrollment data is available through two systems:

- **WISEdash** (2016-present): Modern data portal with CSV downloads

- **Published Excel files** (1997-2015): Historical Excel workbooks

The package handles both formats transparently, providing a consistent
interface across all available years.

## Main Functions

- [`fetch_enr()`](https://almartin82.github.io/wischooldata/reference/fetch_enr.md):
  Download enrollment data for a single year

- [`fetch_enr_multi()`](https://almartin82.github.io/wischooldata/reference/fetch_enr_multi.md):
  Download enrollment data for multiple years

- [`tidy_enr()`](https://almartin82.github.io/wischooldata/reference/tidy_enr.md):
  Transform wide data to tidy (long) format

- [`get_available_years()`](https://almartin82.github.io/wischooldata/reference/get_available_years.md):
  List available data years

## Wisconsin ID System

Wisconsin uses a hierarchical ID system:

- **District Code**: 4 digits (e.g., "3269" for Madison Metropolitan)

- **School Code**: 8-9 characters (district-school, e.g., "3269-0280")

- **CESA**: Cooperative Educational Service Agency (12 regions)

## Data Availability

|                 |              |                 |             |
|-----------------|--------------|-----------------|-------------|
| Era             | Years        | Source          | Format      |
| WINSS/Published | 1997-2005    | Published Excel | Wide format |
| WISEdash Early  | 2006-2015    | Published Excel | Wide format |
| WISEdash Modern | 2016-present | WISEdash CSV    | Long format |

## Known Limitations

- Pre-2011 data combines Asian and Pacific Islander categories

- Two or More Races category available starting 2010-11

- Economic disadvantage definitions vary by year

- Small cell sizes may be suppressed (\<5 students)

## See also

Useful links:

- <https://almartin82.github.io/wischooldata/>

- <https://github.com/almartin82/wischooldata>

- Report bugs at <https://github.com/almartin82/wischooldata/issues>

Useful links:

- <https://almartin82.github.io/wischooldata/>

- <https://github.com/almartin82/wischooldata>

- Report bugs at <https://github.com/almartin82/wischooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@gmail.com>
