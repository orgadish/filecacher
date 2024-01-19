# filecacher 0.2.9

* Removed dependencies on `fs`, `dplyr`, `readr` in tests to pass CRAN package 
  checks.
  
* Made explicit the dependency R (>= 4.1.0) due to use of new pipe `|>` in 
  tests and examples.

# filecacher 0.2.8

* Updates to pass CRAN package checks.


# filecacher 0.2.7

* Another fix to `test-cached_read` to pass CRAN Package Check. 
  Copied test data to a temporary directory to perform tests there.


# filecacher 0.2.5

* Fix to `test-cached_read` to pass CRAN Package Check. 


# filecacher 0.2.4

* `file_cache(cache=NULL)` (default) now uses a sub-folder
  "cache" rather than the top directory.


# filecacher 0.2.3

* Initial CRAN submission.
