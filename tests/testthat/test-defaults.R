test_that("defaults are set and restored cleanly", {
  old <- bones_defaults(animation = "pulse", radius = "1rem")
  on.exit(options(old), add = TRUE)

  expect_equal(getOption("bones.animation"), "pulse")
  expect_equal(getOption("bones.radius"), "1rem")

  options(old)
  expect_null(getOption("bones.animation"))
  expect_null(getOption("bones.radius"))
})

test_that("NULL arguments leave existing values alone", {
  old <- bones_defaults(animation = "pulse", speed = 2)
  on.exit(options(old), add = TRUE)

  bones_defaults(speed = 3)
  expect_equal(getOption("bones.animation"), "pulse")   # untouched
  expect_equal(getOption("bones.speed"), 3)
})

test_that("withBones picks up the defaults", {
  old <- bones_defaults(animation = "none", stale = FALSE)
  on.exit(options(old), add = TRUE)

  html <- as.character(withBones(fake_output("shiny-plot-output")))
  expect_match(html, "bones-anim-none")
  expect_match(html, 'data-bones-stale="false"')
})

test_that("an explicit argument still beats the default", {
  old <- bones_defaults(animation = "none")
  on.exit(options(old), add = TRUE)

  html <- as.character(
    withBones(fake_output("shiny-plot-output"), animation = "wave")
  )
  expect_match(html, "bones-anim-wave")
})

test_that("bad values are rejected", {
  expect_error(bones_defaults(animation = "disco"), "arg")
  expect_error(bones_defaults(speed = -1), "positive")
  expect_error(bones_defaults(speed = 0), "positive")
  expect_error(bones_defaults(speed = c(1, 2)), "positive")
  expect_error(bones_defaults(stale = "yes"), "TRUE or FALSE")
})

test_that("colour and shape options become inline CSS variables", {
  old <- bones_defaults(color = "#eee", highlight = "#ddd",
                        radius = "2px", speed = 1.5)
  on.exit(options(old), add = TRUE)

  vars <- bones:::css_vars()
  expect_true(any(grepl("--bones-color: #eee;", vars, fixed = TRUE)))
  expect_true(any(grepl("--bones-highlight: #ddd;", vars, fixed = TRUE)))
  expect_true(any(grepl("--bones-radius: 2px;", vars, fixed = TRUE)))
  expect_true(any(grepl("--bones-speed: 1.5s;", vars, fixed = TRUE)))

  expect_match(as.character(withBones(fake_output("shiny-plot-output"))),
               "--bones-color: #eee", fixed = TRUE)
})

test_that("no options means no inline variables", {
  old <- options(
    bones.color = NULL, bones.highlight = NULL,
    bones.radius = NULL, bones.speed = NULL
  )
  on.exit(options(old), add = TRUE)

  expect_equal(length(bones:::css_vars()), 0L)
})

test_that("the dependency points at installed assets", {
  dep <- bones_dependency()

  expect_s3_class(dep, "html_dependency")
  expect_equal(dep$name, "bones")
  expect_true(file.exists(file.path(dep$src$file, "bones.js")))
  expect_true(file.exists(file.path(dep$src$file, "bones.css")))
})

test_that("stale in the defaults must be one TRUE or FALSE", {
  expect_error(bones_defaults(stale = NA), "TRUE or FALSE")
  expect_error(bones_defaults(stale = c(TRUE, FALSE)), "TRUE or FALSE")
})

test_that("CSS values cannot break out of the style attribute", {
  expect_error(bones_defaults(color = "red; display: none"), "`color` must be a single CSS value")
  expect_error(bones_defaults(highlight = c("#fff", "#000")), "`highlight` must be a single CSS value")
  expect_error(bones_defaults(radius = 4), "`radius` must be a single CSS value")
})

test_that("speed = NA is rejected with the usual message", {
  # NA <= 0 is NA, so the check once failed with "missing value where
  # TRUE/FALSE needed".
  expect_error(bones_defaults(speed = NA_real_), "positive")
})
