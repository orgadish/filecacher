# filecacher 0.2.9

* Removed test dependencies on suggested packages `dplyr` and `readr` and
  confirmed that R CMD CHECK passes with no suggested packages installed.

* Fixed bugs in `file_cache()` when suggested packages were not available.

# filecacher 0.2.8

* Updated tests and examples to skip if arrow is not installed. R CMD check and
  passes locally with or without arrow installed.

* Updated `test-file_cache.R` to skip failing test on CRAN package check since
  it relies on being able to alter the local file system.

# filecacher 0.2.7

* Addressed issue with `test-cached_read.R` in `filecacher` 0.2.6 which had 
  passed in local testing but failed on Windows system. The fix has now been
  tested locally (on Mac) as well as on a Windows system.

# filecacher 0.2.6

* Updated `test-cached_read.R` again to copy test data into a temporary directory
  using `tempfile()` to correct the new error caught by the CRAN Package Check.
  
## ── R CMD check results ────────────────────── filecacher 0.2.6 ────
Duration: 21.2s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

# filecacher 0.2.5

* Updated `test-cached_read.R` to use a temporary directory as created by
  `tempfile()` to correct the error caught by the CRAN Package Check.

# filecacher 0.2.4

* Updated default behavior of `file_cache()`.

## ── R CMD check results ──────────────────────── filecacher 0.2.4 ────
Duration: 22.2s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔


# filecacher 0.2.3

CRAN Resubmission:
* Updated LICENSE to use updated package name (filecacher)
  instead of old package name (cachedread).
* Updated DESCRIPTION to use quotes for package 'cachem'.
* Added new examples and updated existing examples so that they can be run.
* Updated documentation.

There are no references for this package.


## ── R CMD check results ──────────────────────── filecacher 0.2.3 ────
Duration: 41.3s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔
