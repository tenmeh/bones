# bones demo -----------------------------------------------------------------
#
# A tour of bones. Run it with:
#
#   shiny::runApp(system.file("examples/demo", package = "bones"))
#
# What to look at:
#   * Open each tab. Its outputs load only when the tab first shows, so each
#     one shows a skeleton in the shape of its content: a chart, a table, a
#     map, and so on.
#   * The page does not move when the content arrives.
#   * Press "Load new data". With "stale" on, the content that you read stays
#     on the screen and dims. Turn "stale" off and press again: the skeletons
#     come back.
#   * Set the load time below 0.3 seconds. A load that fast shows nothing,
#     so the page does not flicker.
#   * Change the animation, and turn on the dark mode. The skeletons take
#     their colours from the theme.
#
# The demo needs shiny and bslib. The tables tab also uses DT, reactable and
# gt, and the maps tab uses leaflet and visNetwork. A package that is not
# installed is left out, with a note, so the demo always runs.

library(shiny)
library(bslib)
library(bones)

# --- Optional packages --------------------------------------------------------

# system.file(), not requireNamespace(): in the live demo, webR answers a
# requireNamespace() for a missing package by downloading it, and the live
# demo leaves some packages out on purpose, to start faster.
has <- function(pkg) nzchar(system.file(package = pkg))
HAS <- vapply(c("DT", "reactable", "gt", "leaflet", "visNetwork"), has, logical(1))

# TRUE in the live demo on the pkgdown site, which runs in the browser. It
# leaves out the maps and networks tab: leaflet and the map packages that
# it needs are about a third of the download, and the download is the
# time that the live demo takes to start.
LIVE <- isTRUE(getOption("bones.demo.live"))

# --- Data ---------------------------------------------------------------------

REGIONS <- c("North", "South", "East", "West", "Central", "Coast")

# Random data for all the outputs. One call makes all of it, so all the
# outputs load together.
make_data <- function() {
  n <- 40
  list(
    sales = setNames(round(runif(length(REGIONS), 20, 100)), REGIONS),
    trend = cumsum(rnorm(24, 1, 3)),
    points = data.frame(x = rnorm(n, 170, 10), y = rnorm(n, 70, 12)),
    ages = rnorm(300, 45, 12),
    share = setNames(runif(4), c("A", "B", "C", "D")),
    grid = matrix(runif(80), 8, 10),
    orders = data.frame(
      id     = 1:12,
      region = sample(REGIONS, 12, replace = TRUE),
      units  = sample(10:500, 12),
      price  = round(runif(12, 5, 60), 2),
      status = sample(c("Open", "Shipped", "Closed"), 12, replace = TRUE)
    ),
    stores = data.frame(
      lng = -0.12 + rnorm(6, 0, 0.06),
      lat = 51.51 + rnorm(6, 0, 0.03)
    )
  )
}

# --- UI helpers ---------------------------------------------------------------

# A card with a title and one wrapped output.
demo_card <- function(title, ui) {
  card(card_header(title), ui)
}

# One row of the list of top regions: a round badge, a name and a number.
region_row <- function(badge, name, detail) {
  div(
    style = "display: flex; gap: 0.75rem; align-items: center;",
    badge,
    div(style = "flex: 1; display: grid; gap: 0.35rem; line-height: 1.2;", name, detail)
  )
}

# The placeholder of the list: the same rows, made of bones_block() blocks.
# No built-in shape has a round badge, so the list brings its own.
region_skeleton <- tagList(lapply(1:3, function(i) {
  region_row(
    bones_block(48, 48, shape = "circle"),
    bones_block("30%"),
    bones_block("55%", "0.6rem")
  )
}))

# A card for an output from an optional package. R evaluates `ui` only when
# the package is installed, so the output function of a missing package is
# never called.
optional_card <- function(pkg, title, ui) {
  if (HAS[[pkg]]) demo_card(title, ui) else missing_card(title, pkg)
}

# A card for a package that is not installed. The live demo on the pkgdown
# site leaves some packages out, to download less, and says so.
missing_card <- function(title, pkg) {
  text <- if (isTRUE(getOption("bones.demo.live"))) {
    sprintf("The live demo leaves %s out, so that it starts faster. Run the demo in R to see this output.", pkg)
  } else {
    sprintf("Install %s to see this output: install.packages(\"%s\")", pkg, pkg)
  }
  card(card_header(title), card_body(class = "text-muted", text))
}
