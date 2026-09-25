# Build the live demo of the pkgdown site with shinylive.
#
# Run from the root of the package, after the site is built:
#
#   Rscript pkgdown/live-demo.R [site directory]
#
# The site directory is "docs" if you do not give one. The demo goes in
# <site>/demo, and the "Live demo" article shows it in an iframe.
#
# Shinylive runs the app in webR, R in the browser. webR installs packages
# only from a repository of WebAssembly builds, and bones is not in the
# default one. But bones is pure R: it has no compiled code. So an
# installed copy of bones goes into the app itself, in lib/, and the app
# adds lib/ to its library paths. The demo thus always uses the bones of
# this commit. The other packages come from the webR repository.

args <- commandArgs(trailingOnly = TRUE)
site <- if (length(args) >= 1L) args[[1]] else "docs"
if (!dir.exists(site)) {
  stop("The site directory `", site, "` does not exist. Build the site first.", call. = FALSE)
}

# --- A copy of the demo, with bones in lib/ -----------------------------------

app <- file.path(tempfile("bones-demo-"), "app")
dir.create(file.path(app, "lib"), recursive = TRUE)
invisible(file.copy(list.files("inst/examples/demo", full.names = TRUE), app))

# --no-test-load: the check that the package loads runs in a new R, which
# does not know this library path yet. The build of the site has loaded
# bones already.
status <- system2(
  file.path(R.home("bin"), "R"),
  c("CMD", "INSTALL", "--no-docs", "--no-multiarch", "--no-test-load",
    paste0("--library=", shQuote(file.path(app, "lib"))), ".")
)
if (status != 0L || !file.exists(file.path(app, "lib", "bones", "DESCRIPTION"))) {
  stop("R CMD INSTALL of bones into the demo failed.", call. = FALSE)
}

# The first lines of global.R, before library(bones). In webR, bones comes
# from lib/. `if (FALSE) library(...)` names the other packages for
# shinylive, so it bundles them: the demo loads them with requireNamespace(),
# which shinylive does not see.
global <- file.path(app, "global.R")
writeLines(c(
  "# Live demo: bones is in lib/, next to this file.",
  ".libPaths(c(normalizePath(\"lib\"), .libPaths()))",
  "if (FALSE) {",
  "  library(DT); library(reactable); library(gt); library(leaflet); library(visNetwork)",
  "}",
  "",
  readLines(global)
), global)

# --- Export -------------------------------------------------------------------

out <- file.path(site, "demo")
unlink(out, recursive = TRUE)
shinylive::export(app, out, quiet = TRUE)
message("Live demo written to: ", out)
