test_that("a skeleton is a tag with the type in its class", {
  for (type in c("text", "table", "plot", "cards", "value")) {
    sk <- bones_skeleton(type)
    expect_s3_class(sk, "shiny.tag")
    expect_match(as.character(sk), paste0("bones-skeleton-", type))
  }
})

test_that("skeletons are hidden from screen readers", {
  # Shiny sets aria-busy on the output while it calculates. A message from
  # the placeholder as well would only repeat it.
  expect_match(as.character(bones_skeleton("text")), 'aria-hidden="true"')
})

test_that("text draws one bar per line", {
  expect_equal(count_bars(bones_skeleton("text", lines = 1)), 1L)
  expect_equal(count_bars(bones_skeleton("text", lines = 3)), 3L)
  expect_equal(count_bars(bones_skeleton("text", lines = 7)), 7L)
})

test_that("the last text line is short, so the lines look like a paragraph", {
  html <- as.character(bones_skeleton("text", lines = 3))
  expect_match(html, "62%")

  # One line is not a paragraph, so it is not short.
  expect_false(grepl("62%", as.character(bones_skeleton("text", lines = 1))))
})

test_that("table draws a header row and body rows", {
  sk <- bones_skeleton("table", rows = 3, cols = 2)

  expect_equal(count_matches(as.character(sk), "bones-row"), 4L)   # 3 + header
  expect_equal(count_bars(sk), 8L)                                 # 4 rows x 2
  expect_match(as.character(sk), "bones-bar-strong")               # header
})

test_that("plot draws columns on an axis", {
  sk <- bones_skeleton("plot")
  html <- as.character(sk)

  expect_match(html, "bones-plot-area")
  expect_match(html, "bones-axis")
  expect_equal(count_matches(html, "bones-bar-column"), 8L)
})

test_that("cards and values repeat n times", {
  expect_equal(count_matches(as.character(bones_skeleton("cards", n = 4)), "bones-card\""), 4L)
  expect_equal(count_matches(as.character(bones_skeleton("value", n = 2)), "bones-value\""), 2L)
})

test_that("a count below one becomes one, so the markup is not empty", {
  expect_equal(count_bars(bones_skeleton("text", lines = 0)), 1L)
  expect_equal(count_bars(bones_skeleton("text", lines = -3)), 1L)
  expect_gt(count_bars(bones_skeleton("table", rows = 0, cols = 0)), 0L)
})

test_that("an explicit height is applied", {
  expect_match(as.character(bones_skeleton("plot", height = "250px")), "height: 250px")
})

test_that("an unknown type is rejected", {
  expect_error(bones_skeleton("banana"), "arg")
})

test_that("the default height increases with the content", {
  expect_equal(bones:::default_height("plot"), "400px")
  expect_equal(bones:::default_height("value"), "88px")

  small <- bones:::default_height("table", rows = 2)
  big   <- bones:::default_height("table", rows = 20)
  expect_lt(as.numeric(sub("px", "", small)), as.numeric(sub("px", "", big)))
})

test_that("bad counts and heights are rejected", {
  expect_error(bones_skeleton("table", rows = NA), "`rows` must be a single number")
  expect_error(bones_skeleton("text", lines = "3"), "`lines` must be a single number")
  expect_error(bones_skeleton("cards", n = numeric(0)), "`n` must be a single number")
  expect_error(bones_skeleton("plot", height = "banana"), "not a valid CSS unit")
  expect_match(as.character(bones_skeleton("plot", height = 250)), "height: 250px")
})

test_that("a standalone skeleton gets the default height for its type", {
  # On its own it takes space like any other element, so it needs a height.
  expect_match(as.character(bones_skeleton("text", lines = 3)), "height: 72px")
  expect_match(as.character(bones_skeleton("plot")), "height: 400px")
})

test_that("a standalone skeleton brings its stylesheet", {
  deps <- htmltools::findDependencies(bones_skeleton("text"))
  expect_true(any(vapply(deps, function(d) d$name == "bones", logical(1))))
})

test_that("only the skeleton inside a wrapper is absolutely positioned", {
  css <- paste(
    readLines(system.file("www", "bones.css", package = "bones"), warn = FALSE),
    collapse = "\n"
  )
  expect_match(css, "\\.bones-wrap > \\.bones-skeleton\\s*\\{[^}]*position:\\s*absolute")
  expect_false(grepl("(^|\\n)\\.bones-skeleton\\s*\\{[^}]*position:\\s*absolute", css))
})

test_that("default heights are never negative, and fit the shape drawn", {
  # The shapes make a count below one into one. The height must do the same.
  expect_equal(bones:::default_height("text", lines = -3), "24px")
  expect_equal(bones:::default_height("table", rows = 0), "68px")
  expect_match(as.character(bones_skeleton("text", lines = -3)), "height: 24px")
})

test_that("a standalone skeleton carries the animation and the colours", {
  # With no wrapper, nothing else would give them to it.
  old <- bones_defaults(animation = "pulse", color = "#eee")
  on.exit(options(old), add = TRUE)

  html <- as.character(bones_skeleton("text"))
  expect_match(html, "bones-anim-pulse", fixed = TRUE)
  expect_match(html, "--bones-color: #eee;", fixed = TRUE)
})

test_that("the skeleton inside a wrapper gets no style of its own", {
  # It gets the colours from its wrapper. Its own would be stronger.
  old <- bones_defaults(color = "#eee")
  on.exit(options(old), add = TRUE)

  html <- as.character(withBones(fake_output("shiny-plot-output")))
  expect_false(grepl('class="bones-skeleton[^"]*"[^>]*style=', html))
})

test_that("the default colours are on :root, not on the wrapper", {
  css <- paste(
    readLines(system.file("www", "bones.css", package = "bones"), warn = FALSE),
    collapse = "\n"
  )
  expect_match(css, ":root\\s*\\{[^}]*--bones-color:")
  expect_false(grepl("\\.bones-wrap\\s*\\{[^}]*--bones-color:", css))
})

test_that("an infinite count gives the argument message", {
  # Inf once passed the check, and then failed inside seq_len() with
  # "argument must be coercible to non-negative integer".
  expect_error(bones_skeleton("table", rows = Inf), "`rows` must be a single number")
  expect_error(bones_skeleton("text", lines = -Inf), "`lines` must be a single number")
  expect_error(withBones(fake_output("shiny-table-output"), cols = Inf),
               "`cols` must be a single number")
})
