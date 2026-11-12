test_that("defaults are set, and options() restores them", {
  old <- bones_defaults(animation = "pulse", radius = "1rem")
  on.exit(options(old), add = TRUE)

  expect_equal(getOption("bones.animation"), "pulse")
  expect_equal(getOption("bones.radius"), "1rem")

  options(old)
  expect_null(getOption("bones.animation"))
  expect_null(getOption("bones.radius"))
})

test_that("a NULL argument does not change the value", {
  old <- bones_defaults(animation = "pulse", speed = 2)
  on.exit(options(old), add = TRUE)

  bones_defaults(speed = 3)
  expect_equal(getOption("bones.animation"), "pulse")   # untouched
  expect_equal(getOption("bones.speed"), 3)
})

test_that("withBones() uses the defaults", {
  old <- bones_defaults(animation = "none", stale = FALSE)
  on.exit(options(old), add = TRUE)

  html <- as.character(withBones(fake_output("shiny-plot-output")))
  expect_match(html, "bones-anim-none")
  expect_match(html, 'data-bones-stale="false"')
})

test_that("an argument to withBones() is stronger than the default", {
  old <- bones_defaults(animation = "none")
  on.exit(options(old), add = TRUE)

  html <- as.character(
    withBones(fake_output("shiny-plot-output"), animation = "wave")
  )
  expect_match(html, "bones-anim-wave")
})

test_that("bad values are rejected", {
  expect_error(bones_defaults(animation = "disco"), "`animation` must be one of", fixed = TRUE)
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

test_that("with no options, there are no inline variables", {
  old <- options(
    bones.color = NULL, bones.highlight = NULL,
    bones.radius = NULL, bones.speed = NULL
  )
  on.exit(options(old), add = TRUE)

  expect_equal(length(bones:::css_vars()), 0L)
})

test_that("the dependency points to the installed files", {
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
test_that("session options are visible in the signature", {
  expected <- alist(
    animation = getOption("bones.animation", "wave"),
    stale = getOption("bones.stale", TRUE),
    delay = getOption("bones.delay", 300),
    min_time = getOption("bones.min_time", 500),
    remember = getOption("bones.remember", TRUE),
    error = getOption("bones.error", bones_error()),
    learn = getOption("bones.learn", TRUE)
  )
  expect_identical(as.list(formals(withBones))[names(expected)], expected)
})

test_that("reading defaults uses fallbacks and changes no options", {
  withr::local_options(list(
    bones.animation = NULL, bones.color = NULL, bones.highlight = NULL,
    bones.radius = NULL, bones.speed = NULL, bones.stale = NULL,
    bones.delay = NULL, bones.min_time = NULL, bones.remember = NULL,
    bones.error = NULL, bones.learn = NULL
  ))
  before <- options()
  expect_equal(bones_defaults(), list(
    animation = "wave", color = NULL, highlight = NULL, radius = NULL,
    speed = 1.4, stale = TRUE, delay = 300, min_time = 500,
    remember = TRUE, error = bones_error(), learn = TRUE
  ))
  expect_identical(options(), before)

  bones_defaults(delay = 42, animation = "pulse", error = FALSE)
  before <- options()
  current <- bones_defaults()
  expect_equal(current$delay, 42)
  expect_equal(current$animation, "pulse")
  expect_identical(current$error, FALSE)
  expect_identical(options(), before)
  expect_length(bones_defaults(delay = NULL), 0L)
})

test_that("NULL forwarded by bones_auto still uses session defaults", {
  withr::local_options(list(
    bones.animation = "pulse", bones.stale = FALSE, bones.delay = 42,
    bones.min_time = 75, bones.remember = FALSE, bones.error = FALSE,
    bones.learn = FALSE
  ))
  ui <- fake_output("shiny-table-output")
  expect_equal(
    bones_auto(ui, animation = NULL, stale = NULL, delay = NULL,
               min_time = NULL, remember = NULL, error = NULL, learn = NULL),
    bones_auto(ui)
  )
})

test_that("the defaults in the signature match the built-in defaults", {
  # The signature repeats the values so the help page shows them.
  withr::local_options(bones.animation = NULL, bones.stale = NULL,
                       bones.delay = NULL, bones.min_time = NULL,
                       bones.remember = NULL, bones.error = NULL,
                       bones.learn = NULL)
  f <- formals(withBones)
  builtin <- builtin_defaults()
  for (name in c("animation", "stale", "delay", "min_time", "remember", "error", "learn")) {
    expect_equal(eval(f[[name]], asNamespace("bones")), builtin[[name]], info = name)
  }
})
