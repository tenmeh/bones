# test-app-theme-plain.R ---------------------------------------------------
#
# Theming with no Bootstrap: the colour inputs (--bones-color, --bones-text,
# --bones-surface, --bones-radius) work from :root and from a container, and
# with no input the skeleton follows the text colour of the page.

test_that("the colour inputs work from :root and from a container, with no Bootstrap", {
  testthat::skip_on_cran()

  app <- local_app_driver(
    test_path("apps", "theme-plain"),
    name         = "bones-theme-plain",
    load_timeout = 45000L,
    timeout      = 15000L
  )
  app$wait_for_idle(timeout = 10000L)

  # No Bootstrap on the page, so nothing comes from --bs-* variables.
  expect_false(app$get_js("!!document.querySelector('link[href*=\"bootstrap\"]')"))

  # The colour of the first bar in each box, as red, green, blue (0 to 255)
  # and alpha. getComputedStyle() gives color-mix() as "color(srgb ...)".
  colours <- app$get_js("
    ['root', 'dark', 'text', 'own', 'alone'].map(function (k) {
      var bar = document.querySelector('#box-' + k + ' .bones-bar');
      var c = getComputedStyle(bar).backgroundColor;
      var n = (c.match(/[0-9.]+/g) || []).map(Number);
      var srgb = c.indexOf('color(srgb') === 0;
      return {
        box: k, raw: c, radius: getComputedStyle(bar).borderTopLeftRadius,
        r: srgb ? n[0] * 255 : n[0], g: srgb ? n[1] * 255 : n[1], b: srgb ? n[2] * 255 : n[2],
        a: n.length > 3 ? n[3] : 1
      };
    })
  ")
  names(colours) <- vapply(colours, `[[`, "", "box")
  rgb <- function(x) c(x$r, x$g, x$b)

  # :root sets the colour and the rounding of every skeleton.
  expect_equal(rgb(colours$root), c(0, 128, 0), info = colours$root$raw)
  expect_equal(colours$root$a, 1, info = colours$root$raw)
  expect_identical(colours$root$radius, "7px")
  expect_equal(rgb(colours$alone), c(0, 128, 0), info = colours$alone$raw)

  # With no input, the bars are the text colour of their part of the page,
  # made faint: light bars on the dark part.
  expect_equal(rgb(colours$dark), c(240, 240, 240), tolerance = 0.02, info = colours$dark$raw)
  expect_equal(colours$dark$a, 0.1, tolerance = 0.01, info = colours$dark$raw)

  # --bones-text sets the colour that the others are made from.
  expect_equal(rgb(colours$text), c(200, 0, 0), tolerance = 0.02, info = colours$text$raw)
  expect_equal(colours$text$a, 0.1, tolerance = 0.01, info = colours$text$raw)

  # A colour given to withBones() is stronger than :root.
  expect_equal(rgb(colours$own), c(0, 0, 255), info = colours$own$raw)

  # --bones-surface sets the band of the sweep.
  band <- app$get_js("
    getComputedStyle(document.querySelector('#box-surface .bones-skeleton'), '::after').backgroundImage
  ")
  nums <- as.numeric(regmatches(band, gregexpr("[0-9.]+", band))[[1]])
  expect_true(
    any(vapply(seq_len(max(0, length(nums) - 2)), function(i) {
      isTRUE(all.equal(nums[i:(i + 2)], c(10, 20, 30), tolerance = 0.02)) ||
        isTRUE(all.equal(nums[i:(i + 2)] * 255, c(10, 20, 30), tolerance = 0.02))
    }, logical(1))),
    label = band
  )

  expect_no_shiny_errors(app)
})
