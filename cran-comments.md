## Resubmission

This is a resubmission. In this version I have:

* Written the package name in single quotes, and in lower case, in the
  Title and the Description: 'shiny'.

* Reset the graphical parameters in the demo application in
  inst/examples/demo/server.R. Each plot saves the result of par() and
  restores it with on.exit(par(old), add = TRUE). Nothing else in the
  examples, the demo or the vignettes changes options(), par() or the
  working directory without restoring it.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.
