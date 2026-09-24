# bones_auto(): each output in a UI gets a wrapper, and nothing else does.

skip_if_not_installed("shiny")

# The ids of the outputs that are in a wrapper, in page order.
wrapped_ids <- function(ui) {
  html <- as.character(htmltools::renderTags(ui)$html)
  m <- regmatches(html, gregexpr('data-bones-id="[^"]+"', html))[[1]]
  sub('data-bones-id="([^"]+)"', "\\1", m)
}

test_that("each output gets a wrapper with the shape of its kind", {
  ui <- bones_auto(shiny::fluidPage(
    shiny::plotOutput("chart"),
    shiny::tableOutput("rows"),
    shiny::verbatimTextOutput("log"),
    shiny::uiOutput("any"),
    shiny::imageOutput("picture")
  ))
  expect_equal(wrapped_ids(ui), c("chart", "rows", "log", "any", "picture"))

  html <- as.character(ui)
  expect_match(html, 'data-bones-type="plot"', fixed = TRUE)
  expect_match(html, 'data-bones-type="table"', fixed = TRUE)
  expect_match(html, 'data-bones-type="text"', fixed = TRUE)
})

test_that("outputs deep in the layout are found", {
  ui <- bones_auto(shiny::fluidPage(
    shiny::sidebarLayout(
      shiny::sidebarPanel(shiny::textOutput("side")),
      shiny::mainPanel(
        shiny::tabsetPanel(
          shiny::tabPanel("A", shiny::fluidRow(shiny::column(6, shiny::plotOutput("a")))),
          shiny::tabPanel("B", shiny::tags$div(shiny::tags$div(shiny::tableOutput("b"))))
        )
      )
    )
  ))
  expect_setequal(wrapped_ids(ui), c("side", "a", "b"))
})

test_that("a wrapped output, an excluded one and an inline one are left alone", {
  ui <- bones_auto(
    shiny::tagList(
      withBones(shiny::uiOutput("cards"), type = "cards"),
      shiny::plotOutput("skip"),
      shiny::textOutput("count", inline = TRUE),
      shiny::uiOutput("label", inline = TRUE),
      shiny::plotOutput("keep")
    ),
    exclude = "skip"
  )
  expect_equal(wrapped_ids(ui), c("cards", "keep"))

  html <- as.character(ui)
  # The wrapper that was there keeps its own shape, and gets no second one.
  expect_match(html, 'data-bones-type="cards"', fixed = TRUE)
  expect_equal(count_matches(html, 'class="bones-wrap'), 2L)
})

test_that("the arguments go to each wrapper", {
  ui <- bones_auto(
    shiny::tagList(shiny::plotOutput("a"), shiny::plotOutput("b")),
    stale = FALSE, animation = "pulse"
  )
  html <- as.character(ui)
  expect_equal(count_matches(html, 'data-bones-stale="false"'), 2L)
  expect_equal(count_matches(html, "bones-anim-pulse"), 2L)
})

test_that("a bslib page keeps its class and its theme", {
  skip_if_not_installed("bslib")
  page <- bslib::page_sidebar(
    title = "t",
    theme = bslib::bs_theme(primary = "#123456"),
    sidebar = bslib::sidebar("s"),
    bslib::card(shiny::plotOutput("a"))
  )
  ui <- bones_auto(page)
  expect_s3_class(ui, "bslib_page")
  expect_identical(attr(ui, "bs_theme"), attr(page, "bs_theme"))
  expect_equal(wrapped_ids(ui), "a")
})

test_that("an htmlwidget output keeps its dependencies", {
  skip_if_not_installed("DT")
  ui <- bones_auto(shiny::tagList(DT::DTOutput("table")))
  expect_equal(wrapped_ids(ui), "table")
  expect_match(as.character(ui), 'data-bones-type="dt"', fixed = TRUE)
  deps <- vapply(htmltools::findDependencies(ui), `[[`, character(1), "name")
  expect_true("htmlwidgets" %in% deps)
  expect_true("bones" %in% deps)
})

test_that("a UI with no output is returned as it was", {
  ui <- shiny::tags$div(shiny::tags$p("text"), shiny::actionButton("go", "Go"))
  expect_identical(bones_auto(ui), ui)
})

test_that("bad arguments give a clear message", {
  out <- shiny::plotOutput("a")
  expect_error(bones_auto(NULL), "`ui` must be a UI", fixed = TRUE)
  expect_error(bones_auto(out, type = "line"), "`type` cannot go to bones_auto()", fixed = TRUE)
  expect_error(bones_auto(out, FALSE), "must have a name", fixed = TRUE)
  expect_error(bones_auto(out, exclude = 1), "`exclude` must be", fixed = TRUE)
  # A bad argument for withBones() fails once, with the message of withBones().
  expect_error(bones_auto(out, stale = "yes"), "stale", fixed = TRUE)
})
