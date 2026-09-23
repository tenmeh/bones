# test-app-smoke.R -------------------------------------------------------
#
# The other tests examine the HTML that R makes. They do not run bones.js.
# The state of each wrapper (skeleton, loaded, stale, loading) is set by
# bones.js in the browser, so only a real browser can show that it works.
#
# The first test starts the demo application in a headless browser. All its
# outputs depend on one reactive that takes 1.2 seconds. Shiny starts the
# render functions one at a time, so only the first output does the slow
# work. A wrapper that waited for its own render to start thus did not go
# stale at all. The test looks at the page 0.4 seconds after a refresh,
# while the slow work runs, and each wrapper must already show it.
#
# The second test uses a small application in apps/settle. It sends the
# outputs down each path that ends a recalculation: a value, a silent
# req(), and an error. No wrapper may stay stale or on a skeleton after
# any of them.
#
# helper-shiny-smoke.R tells you why this test skips, and does not fail,
# when there is no headless Chrome.
#
# A note for local runs. The apps/settle application is inside the package
# source, and shinytest2 then loads that source with pkgload::load_all().
# That application thus gets bones.js from inst/www in the source tree. The
# demo comes from system.file(), so it uses the installed package. To try a
# change to bones.js, install the package again as well as edit the source.

click_without_wait <- function(app, id) {
  # app$click() waits until Shiny is idle. The test must look at the page
  # before that, so it clicks from JS.
  app$run_js(sprintf("document.getElementById('%s').click();", id))
}

test_that("the demo app: skeletons on load, stale content on refresh", {
  testthat::skip_on_cran()

  app <- local_app_driver(
    system.file("examples/demo", package = "bones"),
    name         = "bones-demo-smoke",
    seed         = 42L,
    load_timeout = 45000L,
    timeout      = 15000L
  )
  app$wait_for_idle(timeout = 10000L)

  # --- first load: each wrapper shows its content -------------------------
  expect_equal(
    wrapper_states(app),
    c(chart = "loaded", table = "loaded", boxes = "loaded", summary = "loaded")
  )

  # --- refresh: each wrapper shows the recalculation at once --------------
  click_without_wait(app, "refresh")
  Sys.sleep(0.4)
  expect_equal(
    wrapper_states(app),
    c(chart = "stale", table = "stale", boxes = "stale", summary = "loading")
  )

  # --- after the refresh: each wrapper shows its content again ------------
  app$wait_for_idle(timeout = 10000L)
  Sys.sleep(0.2)
  expect_equal(
    wrapper_states(app),
    c(chart = "loaded", table = "loaded", boxes = "loaded", summary = "loaded")
  )

  # --- the reserved height goes after the content arrives -----------------
  # A text output of two lines must not keep the space of three.
  summary_gap <- app$get_js("
    (function () {
      var w = document.querySelector('[data-bones-id=summary]');
      var c = w.querySelector('.bones-content');
      return w.getBoundingClientRect().height - c.getBoundingClientRect().height;
    })()
  ")
  expect_lt(summary_gap, 1)

  expect_no_shiny_errors(app)
})

test_that("no wrapper stays stale after a value, a silent req(), or an error", {
  testthat::skip_on_cran()

  app <- local_app_driver(
    test_path("apps", "settle"),
    name         = "bones-settle-smoke",
    load_timeout = 45000L,
    timeout      = 15000L
  )
  app$wait_for_idle(timeout = 10000L)
  expect_equal(
    wrapper_states(app),
    c(first = "loaded", second = "loaded", third = "loaded", outer = "loaded")
  )

  for (mode in c("silent", "error", "value")) {
    app$set_inputs(mode = mode, wait_ = FALSE)
    Sys.sleep(0.3)
    expect_equal(
      wrapper_states(app),
      c(first = "stale", second = "stale", third = "loading", outer = "loaded"),
      info = paste("while the mode changes to", mode)
    )

    app$wait_for_idle(timeout = 10000L)
    Sys.sleep(0.2)
    expect_equal(
      wrapper_states(app),
      c(first = "loaded", second = "loaded", third = "loaded", outer = "loaded"),
      info = paste("after the mode changes to", mode)
    )
  }

  # The error above is on purpose, so the stderr holds it. The browser
  # console must still be clean: that shows bones.js did not fail.
  logs <- as.data.frame(app$get_logs())
  console_errors <- logs$message[logs$location == "chromote" &
                                   !is.na(logs$level) & logs$level == "error"]
  expect_length(console_errors, 0L)
})
