## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

---

## Data Sources

Wisconsin DPI provides enrollment data through two systems:

### WISEdash (2006-present) - PRIMARY SOURCE
- **URL pattern**: `https://dpi.wi.gov/sites/default/files/wise/downloads/enrollment_by_gradelevel_certified_{year}.zip`
- **Format**: ZIP containing CSV file
- **Years available**: 2005-06 through 2023-24 (school year end 2006-2024)
- **Data structure**: Long format with one row per school/grade/subgroup combination
- **Key columns**: DISTRICT_CODE, SCHOOL_CODE, GRADE_LEVEL, GROUP_BY, GROUP_BY_VALUE, STUDENT_COUNT

### Published PEM Files (1997-2005) - LEGACY SOURCE
- **URL pattern**: `https://dpi.wi.gov/sites/default/files/imce/cst/xls/pem{YY}.xls`
- **Format**: Excel workbook with multiple sheets
- **Years available**: 2001-2011 (files for 2012-2016 return 404)
- **Data sheet**: Named "PEM{YY}" (e.g., "PEM10" for 2010)
- **Note**: Since WISEdash is available for 2006+, we only use PEM files for 1997-2005

### Data Availability Summary
| Years | Source | Status |
|-------|--------|--------|
| 2006-2024 | WISEdash ZIP | Active |
| 1997-2005 | Published PEM Excel | Active |

### Known Issues (as of 2026-01)
- PEM files for years 2012-2016 return HTTP 404 (no longer available)
- WISEdash files back to 2006 are fully functional
- All current tests pass (166 tests)

---

# Claude Code Instructions

## Git Commits and PRs
- NEVER reference Claude, Claude Code, or AI assistance in commit messages
- NEVER reference Claude, Claude Code, or AI assistance in PR descriptions
- NEVER add Co-Authored-By lines mentioning Claude or Anthropic
- Keep commit messages focused on what changed, not how it was written

---

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally BEFORE opening a PR:

### CI Checks That Must Pass

| Check | Local Command | What It Tests |
|-------|---------------|---------------|
| R-CMD-check | `devtools::check()` | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pywischooldata.py -v` | Python wrapper works correctly |
| pkgdown | `pkgdown::build_site()` | Documentation and vignettes render |

### Quick Commands

```r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pywischooldata && pytest tests/test_pywischooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify:
- [ ] `devtools::check()` — 0 errors, 0 warnings
- [ ] `pytest tests/test_pywischooldata.py` — all tests pass
- [ ] `pkgdown::build_site()` — builds without errors
- [ ] Vignettes render (no `eval=FALSE` hacks)

---

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE network tests.

### Test Categories:
1. URL Availability - HTTP 200 checks
2. File Download - Verify actual file (not HTML error)
3. File Parsing - readxl/readr succeeds
4. Column Structure - Expected columns exist
5. get_raw_enr() - Raw data function works
6. Data Quality - No Inf/NaN, non-negative counts
7. Aggregation - State total > 0
8. Output Fidelity - tidy=TRUE matches raw

### Running Tests:
```r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework documentation.


---

## Git Workflow (REQUIRED)

### Feature Branch + PR + Auto-Merge Policy

**NEVER push directly to main.** All changes must go through PRs with auto-merge:

```bash
# 1. Create feature branch
git checkout -b fix/description-of-change

# 2. Make changes, commit
git add -A
git commit -m "Fix: description of change"

# 3. Push and create PR with auto-merge
git push -u origin fix/description-of-change
gh pr create --title "Fix: description" --body "Description of changes"
gh pr merge --auto --squash

# 4. Clean up stale branches after PR merges
git checkout main && git pull && git fetch --prune origin
```

### Branch Cleanup (REQUIRED)

**Clean up stale branches every time you touch this package:**

```bash
# Delete local branches merged to main
git branch --merged main | grep -v main | xargs -r git branch -d

# Prune remote tracking branches
git fetch --prune origin
```

### Auto-Merge Requirements

PRs auto-merge when ALL CI checks pass:
- R-CMD-check (0 errors, 0 warnings)
- Python tests (if py{st}schooldata exists)
- pkgdown build (vignettes must render)

If CI fails, fix the issue and push - auto-merge triggers when checks pass.

