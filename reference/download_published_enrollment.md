# Download published enrollment data (1997-2015)

Downloads enrollment data from DPI's published Excel files. These are
Excel workbooks with enrollment by school/district.

## Usage

``` r
download_published_enrollment(end_year)
```

## Arguments

- end_year:

  School year end (1997-2015)

## Value

Data frame with enrollment data

## Details

File types used:

- PEM (Public Enrollment Master): School-level with grade, gender,
  ethnicity

- PESE (Public Enrollment School Ethnicity): School-level ethnicity
  detail

- PEDGr (Public Enrollment District Grade): District-level by grade
