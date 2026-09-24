test_that("the wrapper has the shape that it found", {
  w <- withBones(fake_output("shiny-plot-output", id = "chart"))
  html <- as.character(w)

  expect_s3_class(w, "shiny.tag")
  expect_match(html, "bones-wrap")
  expect_match(html, 'data-bones-type="plot"')
  expect_match(html, 'data-bones-id="chart"')
  expect_match(html, "bones-content")
})

test_that("the output in the wrapper does not change", {
  w <- withBones(fake_output("shiny-table-output", id = "results"))
  expect_match(as.character(w), 'id="results"')
})

test_that("a type argument is stronger than the found shape", {
  w <- withBones(fake_output("shiny-html-output"), type = "cards", n = 2)
  html <- as.character(w)

  expect_match(html, 'data-bones-type="cards"')
  expect_equal(count_matches(html, "bones-card\""), 2L)
})

test_that("the height of the output is kept", {
  w <- withBones(fake_output("shiny-plot-output", style = "height:320px"))
  expect_match(as.character(w), "--bones-reserve: 320px")
})

test_that("a height argument is stronger than the height of the output", {
  w <- withBones(fake_output("shiny-plot-output", style = "height:320px"),
                 height = "100px")
  expect_match(as.character(w), "--bones-reserve: 100px")
})

test_that("a height is calculated when the output has none", {
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
    # bones-has-loaded, not bones-loaded: a stale = FALSE recalculation
    # removes bones-loaded, and the reserve must not come back then.
    "\\.bones-wrap:not\\(\\.bones-has-loaded\\)\\s*\\{[^}]*min-height:\\s*var\\(--bones-reserve"
  )
})

test_that("stale content is on by default, and can be turned off", {
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
  # With `display: none`, Shiny reads a width of zero, and a plot gets the
  # wrong size. The stylesheet must use visibility.
  css <- readLines(
    system.file("www", "bones.css", package = "bones"),
    warn = FALSE
  )
  css <- paste(css, collapse = "\n")

  expect_match(css, "\\.bones-content\\s*\\{[^}]*visibility:\\s*hidden")
  expect_false(grepl("\\.bones-content\\s*\\{[^}]*display:\\s*none", css))
})

test_that("the dimming of Shiny is turned off only inside a stale wrapper", {
  # An output inside a wrapped uiOutput() does not make that wrapper stale.
  # Its own dimming is then the only sign that it updates.
  css <- paste(
    readLines(system.file("www", "bones.css", package = "bones"), warn = FALSE),
    collapse = "\n"
  )
  expect_match(css, "\\.bones-wrap\\.bones-stale \\.shiny-bound-output\\.recalculating")
  expect_false(grepl("\\.bones-wrap \\.shiny-bound-output\\.recalculating", css))
})

test_that("an output with no id gives no data-bones-id attribute", {
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

test_that("the wrapper brings the dependency", {
  deps <- htmltools::findDependencies(withBones(fake_output("shiny-plot-output")))
  expect_true(any(vapply(deps, function(d) d$name == "bones", logical(1))))
})

test_that("real Shiny outputs get the correct shapes", {
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

test_that("the skeleton inside a wrapper has no height of its own", {
  # It fills the wrapper. A fixed height would not follow the wrapper.
  html <- as.character(withBones(fake_output("shiny-plot-output")))
  expect_false(grepl('class="bones-skeleton[^"]*"[^>]*style="height', html))
})

test_that("delay and min_time have defaults of 300 and 500 milliseconds", {
  html <- as.character(withBones(fake_output("shiny-plot-output")))
  expect_match(html, "--bones-delay: 300ms;", fixed = TRUE)
  expect_match(html, 'data-bones-min-time="500"', fixed = TRUE)
})

test_that("delay and min_time can be set per output and for the session", {
  html <- as.character(withBones(fake_output("shiny-plot-output"), delay = 0, min_time = 1000))
  expect_match(html, "--bones-delay: 0ms;", fixed = TRUE)
  expect_match(html, 'data-bones-min-time="1000"', fixed = TRUE)

  old <- bones_defaults(delay = 150, min_time = 250)
  on.exit(options(old), add = TRUE)
  html <- as.character(withBones(fake_output("shiny-plot-output")))
  expect_match(html, "--bones-delay: 150ms;", fixed = TRUE)
  expect_match(html, 'data-bones-min-time="250"', fixed = TRUE)

  # An argument is stronger than the session default.
  html <- as.character(withBones(fake_output("shiny-plot-output"), delay = 50))
  expect_match(html, "--bones-delay: 50ms;", fixed = TRUE)
})

test_that("delay and min_time must be single numbers of 0 or more", {
  out <- fake_output("shiny-plot-output")
  expect_error(withBones(out, delay = -1), "`delay` must be a single number of milliseconds")
  expect_error(withBones(out, delay = "300"), "`delay` must be a single number of milliseconds")
  expect_error(withBones(out, min_time = NA_real_), "`min_time` must be a single number of milliseconds")
  expect_error(withBones(out, min_time = c(1, 2)), "`min_time` must be a single number of milliseconds")
  expect_error(bones_defaults(delay = Inf), "`delay` must be a single number of milliseconds")
})

test_that("only an estimated height is marked to be remembered", {
  # An estimate: the output sets no height.
  html <- as.character(withBones(fake_output("shiny-html-output", id = "a"), type = "text"))
  expect_match(html, 'data-bones-remember="true"', fixed = TRUE)

  # Exact already: the output sets its height, or the caller gives one.
  html <- as.character(withBones(fake_output("shiny-plot-output", style = "height:320px")))
  expect_false(grepl("data-bones-remember", html, fixed = TRUE))
  html <- as.character(withBones(fake_output("shiny-html-output"), height = 200))
  expect_false(grepl("data-bones-remember", html, fixed = TRUE))
})

test_that("remember can be turned off per output and for the session", {
  out <- fake_output("shiny-html-output", id = "a")
  expect_false(grepl("data-bones-remember", as.character(withBones(out, remember = FALSE)), fixed = TRUE))

  old <- bones_defaults(remember = FALSE)
  on.exit(options(old), add = TRUE)
  expect_false(grepl("data-bones-remember", as.character(withBones(out)), fixed = TRUE))
  expect_match(as.character(withBones(out, remember = TRUE)), 'data-bones-remember="true"', fixed = TRUE)

  expect_error(withBones(out, remember = "yes"), "`remember` must be TRUE or FALSE")
  expect_error(bones_defaults(remember = NA), "`remember` must be TRUE or FALSE")
})

test_that("the skeleton and the dimming wait for the delay", {
  css <- paste(
    readLines(system.file("www", "bones.css", package = "bones"), warn = FALSE),
    collapse = "\n"
  )
  expect_match(css, "bones-appear 1ms linear var(--bones-delay) both", fixed = TRUE)
  expect_match(css, "transition: opacity 120ms ease var(--bones-delay);", fixed = TRUE)
  # Reduced motion drops the fade, but keeps the delay.
  expect_match(css, "transition: opacity 0s linear var(--bones-delay);", fixed = TRUE)
})
