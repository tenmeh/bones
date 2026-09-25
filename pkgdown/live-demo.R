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
# installed copy of bones goes into the app itself, and the app adds it to
# its library paths. The demo thus always uses the bones of this commit.
# The other packages come from the webR repository.
#
# The browser downloads every package that the app bundles before the app
# starts, also packages for a tab that nobody opens. So the download is the
# start time, and the live demo bundles only the packages in
# `live_packages`. leaflet is left out: with sf, terra, raster and sp, it is
# about a third of the download. Its card then says that the live demo
# leaves it out. Set BONES_LIVE_PACKAGES (comma-separated) to try another
# list.
#
# shinylive finds the packages to bundle with renv::dependencies(), which
# reads the code of the app for library() and pkg:: calls. It does this
# twice: here, to bundle them, and in the browser, where it downloads each
# one that is missing. renv never reads a folder named "vendor". So the demo
# and bones go in vendor/, the three files at the top only source them, and
# live-packages.R names the packages to bundle.
#
#   app/
#     global.R, ui.R, server.R   source the files in vendor/demo
#     live-packages.R            library() calls, for renv to read
#     vendor/demo/               a copy of inst/examples/demo
#     vendor/lib/bones/          bones, installed from this commit

live_packages <- strsplit(Sys.getenv("BONES_LIVE_PACKAGES", "DT,reactable,gt,visNetwork"), ",")[[1]]

args <- commandArgs(trailingOnly = TRUE)
site <- if (length(args) >= 1L) args[[1]] else "docs"
if (!dir.exists(site)) {
  stop("The site directory `", site, "` does not exist. Build the site first.", call. = FALSE)
}

# --- The demo and bones, in vendor/ -------------------------------------------

app <- file.path(tempfile("bones-demo-"), "app")
demo <- file.path(app, "vendor", "demo")
lib <- file.path(app, "vendor", "lib")
dir.create(demo, recursive = TRUE)
dir.create(lib, recursive = TRUE)
invisible(file.copy(list.files("inst/examples/demo", full.names = TRUE), demo))

# --no-test-load: the check that the package loads runs in a new R, which
# does not know this library path yet. The build of the site has loaded
# bones already.
status <- system2(
  file.path(R.home("bin"), "R"),
  c("CMD", "INSTALL", "--no-docs", "--no-multiarch", "--no-test-load",
    paste0("--library=", shQuote(lib)), ".")
)
if (status != 0L || !file.exists(file.path(lib, "bones", "DESCRIPTION"))) {
  stop("R CMD INSTALL of bones into the demo failed.", call. = FALSE)
}

# --- The files at the top of the app ------------------------------------------

writeLines(c(
  "# Live demo. The demo is in vendor/demo, and bones is in vendor/lib.",
  "# See pkgdown/live-demo.R in the source of bones.",
  ".libPaths(c(normalizePath(\"vendor/lib\"), .libPaths()))",
  "# Tells the demo that it runs live, for the cards of the packages that",
  "# the live demo leaves out.",
  "options(bones.demo.live = TRUE)",
  "source(\"vendor/demo/global.R\")"
), file.path(app, "global.R"))

# Shiny takes the value of ui.R and server.R: here, the value of the file
# that each one sources.
writeLines("source(\"vendor/demo/ui.R\", local = TRUE)$value", file.path(app, "ui.R"))
writeLines("source(\"vendor/demo/server.R\", local = TRUE)$value", file.path(app, "server.R"))

writeLines(c(
  "# The packages that shinylive bundles for the live demo. This file is not",
  "# run: renv::dependencies() only reads it.",
  sprintf("library(%s)", live_packages)
), file.path(app, "live-packages.R"))

# --- Export -------------------------------------------------------------------

out <- file.path(site, "demo")
unlink(out, recursive = TRUE)
shinylive::export(app, out, quiet = TRUE)
message("Live demo written to: ", out)
