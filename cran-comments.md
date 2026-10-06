# CRAN comments

## Resubmission

This is a resubmission of a new package. The first submission was 0.1.0.
In this version I have:

* Written the package name 'shiny' in single quotes, in lower case, in
  the Title and the Description.
* Reset par() in the demo app in inst/examples/demo/server.R. The plot
  code saves the old values and gives them back with on.exit(). This was
  the only place in the examples, demos and inst folder that changed
  par(), options() or the working directory. The example of
  bones_defaults() already restores options().

## Test environments

* local Windows 11, R 4.6.1 (release): R CMD check --as-cran on the built
  tarball, with _R_CHECK_CRAN_INCOMING_REMOTE_=TRUE and the PDF manual
* GitHub Actions, R CMD check --as-cran: macOS (release), Windows
  (release), Ubuntu (devel, release, oldrel-1)

The tarball was checked locally with the current release of R, not
R-devel, because this machine has only the release version. R-devel is
covered by the Ubuntu (devel) job above, which also runs
R CMD check --as-cran.

## R CMD check results

0 errors | 0 warnings | 1 note

* Maintainer: 'Tanmay Chanda <tanmaychanda96@gmail.com>'
  New submission

The only note is the standard note for a first submission.

## Notes for the reviewer

* The package gives 'shiny' outputs a loading placeholder in the shape of
  the content. Its R functions only build HTML, and its JavaScript runs in
  the browser of the user of a 'shiny' app.
* The examples run without a 'shiny' session. They build the HTML and
  return it. The examples that use 'shiny' run only when it is installed.
* The tests that start an app in a headless browser use shinytest2. They
  call skip_on_cran(), and they skip when Chrome or a suggested package
  is not available.
* The package writes nothing outside tempdir(), opens no connections, and
  starts no processes. In the browser, the JavaScript can store the height
  of an output in localStorage, so that the page does not move on the next
  visit. The option remember = FALSE turns this off.
