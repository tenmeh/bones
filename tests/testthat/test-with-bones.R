test_that("the wrapper carries the shape it inferred", {
  w <- withBones(fake_output("shiny-plot-output", id = "chart"))
  html <- as.character(w)

  expect_s3_class(w, "shiny.tag")
  expect_match(html, "bones-wrap")
  expect_match(html, 'data-bones-type="plot"')
  expect_match(html, 'data-bones-id="chart"')
  expect_match(html, "bones-content")
})

test_that("the wrapped output survives intact", {
  w <- withBones(fake_output("shiny-table-output", id = "results"))
  expect_match(as.character(w), 'id="results"')
})

test_that("an explicit type overrides inference", {
  w <- withBones(fake_output("shiny-html-output"), type = "cards", n = 2)
  html <- as.character(w)

  expect_match(html, 'data-bones-type="cards"')
  expect_equal(count_matches(html, "bones-card\""), 2L)
})

test_that("the output's own height is reserved", {
  w <- withBones(fake_output("shiny-plot-output", style = "height:320px"))
  expect_match(as.character(w), "--bones-reserve: 320px")
})

test_that("an explicit height wins over the output's", {
  w <- withBones(fake_output("shiny-plot-output", style = "height:320px"),
                 height = "100px")
  expect_match(as.character(w), "--bones-reserve: 100px")
})

test_that("a height is derived when the output declares none", {
  w <- withBones(fake_output("shiny-table-output"), rows = 4)
  # A header row plus four body rows, at 34px each.
  expect_match(as.character(w), "--bones-reserve: 170px", fixed = TRUE)
})

test_that("the reserve is a custom property, not a min-height", {
  # A min-height in the style attribute would stay after the content
  # arrives, and leave a gap under content shorter than the estimate.
  html <- as.character(withBones(fake_output("shiny-plot-output")))
  expect_false(grepl("min-height", html, fixed = TRUE))

  css <- paste(
    readLines(system.file("www", "bones.css", package = "bones"), warn = FALSE),
    collapse = "\n"
  )
  expect_match(
    css,
    "\\.bones-wrap:not\\(\\.bones-loaded\\)\\s*\\{[^}]*min-height:\\s*var\\(--bones-reserve"
  )
})

test_that("stale-while-revalidate is on by default and can be turned off", {
  expect_match(as.character(withBones(fake_output("shiny-plot-output"))),
               'data-bones-stale="true"')
  expect_match(as.character(withBones(fake_output("shiny-plot-output"), stale = FALSE)),
               'data-bones-stale="false"')
})

test_that("the animation class is applied", {
  expect_match(as.character(withBones(fake_output("shiny-plot-output"))),
               "bones-anim-wave")
  expect_match(
    as.character(withBones(fake_output("shiny-plot-output"), animation = "pulse")),
    "bones-anim-pulse"
  )
})

test_that("content is hidden with visibility, never display", {
  # `display: none` reports a width of zero to Shiny and plots then render at
  # the wrong size. The stylesheet must use visibility instead.
  css <- readLines(
    system.file("www", "bones.css", package = "bones"),
    warn = FALSE
  )
  css <- paste(css, collapse = "\n")

  expect_match(css, "\\.bones-content\\s*\\{[^}]*visibility:\\s*hidden")
  expect_false(grepl("\\.bones-content\\s*\\{[^}]*display:\\s*none", css))
})

test_that("an id-less output does not emit a stray attribute", {
  w <- withBones(htmltools::tags$div(class = "shiny-plot-output"))
  expect_false(grepl("data-bones-id", as.character(w)))
})

test_that("NULL input is rejected", {
  expect_error(withBones(NULL), "must be a Shiny output")
})

test_that("a bad type or animation is rejected", {
  expect_error(withBones(fake_output("shiny-plot-output"), type = "banana"), "arg")
  expect_error(withBones(fake_output("shiny-plot-output"), animation = "disco"), "arg")
})

test_that("the dependency travels with the wrapper", {
  deps <- htmltools::findDependencies(withBones(fake_output("shiny-plot-output")))
  expect_true(any(vapply(deps, function(d) d$name == "bones", logical(1))))
})

test_that("real Shiny outputs get sensible shapes", {
  skip_if_not_installed("shiny")

  expect_match(as.character(withBones(shiny::plotOutput("p"))),
               'data-bones-type="plot"')
  expect_match(as.character(withBones(shiny::tableOutput("t"))),
               'data-bones-type="table"')
  expect_match(as.character(withBones(shiny::textOutput("x"))),
               'data-bones-type="text"')
})

test_that("stale must be TRUE or FALSE", {
  # "yes" once became FALSE with no message.
  out <- fake_output("shiny-plot-output")
  expect_error(withBones(out, stale = "yes"), "`stale` must be TRUE or FALSE")
  expect_error(withBones(out, stale = NA), "`stale` must be TRUE or FALSE")
  expect_error(withBones(out, stale = c(TRUE, FALSE)), "`stale` must be TRUE or FALSE")
})

test_that("counts must be single numbers", {
  out <- fake_output("shiny-table-output")
  expect_error(withBones(out, rows = NA), "`rows` must be a single number")
  expect_error(withBones(out, cols = "4"), "`cols` must be a single number")
  expect_error(withBones(out, lines = c(1, 2)), "`lines` must be a single number")
  expect_error(withBones(out, n = NULL), "`n` must be a single number")
})

test_that("a height works as it does in Shiny", {
  out <- fake_output("shiny-plot-output")
  expect_match(as.character(withBones(out, height = 300)), "--bones-reserve: 300px")
  expect_error(withBones(out, height = "banana"), "not a valid CSS unit")
  expect_error(withBones(out, height = NA), "single CSS length")
})
