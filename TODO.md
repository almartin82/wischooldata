# TODO: pkgdown Build Issues

## Network Connectivity Issue (2026-01-01)

The pkgdown build failed due to network connectivity issues:

1. **git pull failed**: Could not connect to github.com port 443 (timeout after 75 seconds)
2. **pkgdown::build_site() failed**: Could not connect to cloud.r-project.org (timeout after 10 seconds)

### Error Details

```
Error in `httr2::req_perform(req)`:
! Failed to perform HTTP request.
Caused by error in `curl::curl_fetch_memory()`:
! Timeout was reached [cloud.r-project.org]:
Connection timed out after 10001 milliseconds
```

The build was attempting to check CRAN links when the network timeout occurred.

### Resolution

This is a temporary network issue, not a code problem. Retry the build when network connectivity is restored:

```r
pkgdown::build_site()
```
