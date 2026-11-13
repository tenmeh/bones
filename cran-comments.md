# CRAN comments

## Update

This is an update of bones 0.1.1, which is on CRAN. It is version 0.2.0.
There were no releases in between.

Main changes (all in NEWS.md):

* New features: outputs learn the shape of their content, an error panel
  with an optional retry button, a way to show the placeholder on demand,
  per-output speed and colour, colours set from CSS, and two functions
  that list the valid shapes and animations.
* Three small breaking changes, each in NEWS.md: the error panel is on by
  default, names of types and animations must match exactly, and unused
  shape arguments now give a warning.

## Test environments

* local Windows 11, R 4.6.1 (release): R CMD check --as-cran on the built
  tarball, with _R_CHECK_CRAN_INCOMING_REMOTE_=TRUE and the PDF manual
* win-builder, Windows Server 2022, R-devel (2026-11-12 r90881): the same
  tarball, Status OK
* GitHub Actions, R CMD check --as-cran: macOS (release), Windows
  (release), Ubuntu (devel, release, oldrel-1)

## R CMD check results

0 errors | 0 warnings | 0 notes

## Reverse dependencies

There are no reverse dependencies on CRAN.

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
  and the layout of an output in localStorage, so that the page does not
  move on the next visit. This stores only sizes and positions, never text.
  The option remember = FALSE turns it off.
