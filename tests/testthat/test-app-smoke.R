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
  wait_for_settled(app)

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
  wait_for_settled(app)
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
  wait_for_settled(app)
  expect_equal(
    wrapper_states(app),
    c(first = "loaded", second = "loaded", third = "loaded", outer = "loaded")
  )

  wrapper_height <- function(id) {
    app$get_js(sprintf(
      "document.querySelector('[data-bones-id=%s]').getBoundingClientRect().height",
      id
    ))
  }

  for (mode in c("silent", "error", "value")) {
    third_before <- wrapper_height("third")

    app$set_inputs(mode = mode, wait_ = FALSE)
    Sys.sleep(0.3)
    expect_equal(
      wrapper_states(app),
      c(first = "stale", second = "stale", third = "loading", outer = "loaded"),
      info = paste("while the mode changes to", mode)
    )

    # The skeleton comes back for stale = FALSE, but the reserve does not.
    # The old content keeps its box, so the page must not move.
    expect_equal(
      wrapper_height("third"), third_before,
      info = paste("height of the stale = FALSE wrapper while the mode changes to", mode)
    )

    # The output inside the wrapped uiOutput() does not change the state of
    # that wrapper. Shiny must thus still dim it, or the user sees no sign
    # that it updates. Shiny starts its fade after 500ms, so look at 0.8s.
    # The slow reactive of the application takes 1.2s.
    Sys.sleep(0.5)
    expect_lt(
      as.numeric(app$get_js("getComputedStyle(document.getElementById('inner')).opacity")),
      1
    )

    wait_for_settled(app)
    expect_equal(
      wrapper_states(app),
      c(first = "loaded", second = "loaded", third = "loaded", outer = "loaded"),
      info = paste("after the mode changes to", mode)
    )
  }

  # --- a standalone skeleton takes space in its own container -----------
  # It must not cover its container, or the page, as the skeleton inside a
  # wrapper does.
  box <- app$get_js("
    (function () {
      var box = document.getElementById('standalone-box');
      var sk = box.querySelector('.bones-skeleton');
      return {
        box: box.getBoundingClientRect().height,
        skeleton: sk.getBoundingClientRect().height,
        position: getComputedStyle(sk).position,
        bar: getComputedStyle(sk.querySelector('.bones-bar')).backgroundColor
      };
    })()
  ")
  expect_equal(box$position, "static")
  expect_equal(box$skeleton, 72)
  expect_gte(box$box, box$skeleton)
  # The colours are custom properties. With no wrapper around it, the
  # skeleton must still get them, or its bars are transparent.
  expect_false(box$bar %in% c("rgba(0, 0, 0, 0)", "transparent"))

  # The error above is on purpose, so the stderr holds it. The browser
  # console must still be clean: that shows bones.js did not fail.
  logs <- as.data.frame(app$get_logs())
  console_errors <- logs$message[logs$location == "chromote" &
                                   !is.na(logs$level) & logs$level == "error"]
  expect_length(console_errors, 0L)
})

test_that("each table package gets its own shape, and its table fits the reserve", {
  testthat::skip_on_cran()
  for (pkg in c("DT", "reactable", "gt", "rhandsontable")) skip_if_not_installed(pkg)

  app <- local_app_driver(
    test_path("apps", "tables"),
    name         = "bones-tables-smoke",
    wait         = FALSE,
    load_timeout = 45000L,
    timeout      = 15000L
  )

  # --- while the tables load: the right shape, with visible marks ----------
  app$wait_for_js("document.querySelectorAll('.bones-wrap .bones-skeleton').length === 4",
                  timeout = 30000)
  first <- app$get_js("
    ['dt', 'reactable', 'gt', 'rhandsontable'].map(function (k) {
      var w = document.querySelector('#box-' + k + ' .bones-wrap');
      var sk = w.querySelector(':scope > .bones-skeleton');
      var box = sk.getBoundingClientRect();
      var bars = Array.from(sk.querySelectorAll('.bones-bar'));
      var hidden = bars.filter(function (b) {
        var r = b.getBoundingClientRect();
        return r.width === 0 || r.height === 0 || r.bottom > box.bottom + 1;
      });
      return {kind: k, type: w.getAttribute('data-bones-type'),
              loaded: w.classList.contains('bones-loaded'),
              reserve: w.getBoundingClientRect().height,
              bars: bars.length, hidden: hidden.length};
    })
  ")
  for (f in first) {
    expect_equal(f$type, f$kind)
    expect_false(isTRUE(f$loaded), label = paste(f$kind, "loaded too early"))
    expect_gt(f$bars, 10L, label = paste(f$kind, "bars"))
    expect_equal(f$hidden, 0L, label = paste(f$kind, "bars that cannot be seen"))
  }

  # --- when the tables arrive: each fits in the space that was kept --------
  wait_for_settled(app, timeout = 30000L)
  Sys.sleep(0.5)
  final <- app$get_js("
    ['dt', 'reactable', 'gt', 'rhandsontable'].map(function (k) {
      return document.querySelector('#box-' + k + ' .bones-wrap').getBoundingClientRect().height;
    })
  ")
  for (i in seq_along(first)) {
    # A table taller than its reserve pushes the page down when it arrives.
    # One that is shorter only closes the space, so a small margin is fine.
    expect_lte(final[[i]], first[[i]]$reserve + 1, label = paste(first[[i]]$kind, "height"))
    expect_gte(final[[i]], first[[i]]$reserve - 40, label = paste(first[[i]]$kind, "height"))
  }

  expect_no_shiny_errors(app)
})

test_that("each chart shape draws visible marks inside its skeleton", {
  testthat::skip_on_cran()

  # The HTML tests count the marks. Only a browser shows that the marks have
  # a size, sit inside the skeleton, and have a colour: a mark with no
  # height, or outside the box, or transparent, cannot be seen.
  app <- local_app_driver(
    test_path("apps", "charts"),
    name         = "bones-charts-smoke",
    load_timeout = 45000L,
    timeout      = 15000L
  )
  app$wait_for_idle(timeout = 10000L)

  marks <- app$get_js("
    Array.from(document.querySelectorAll('.bones-skeleton-chart')).map(function (sk) {
      var box = sk.getBoundingClientRect();
      var els = sk.querySelectorAll('.bones-bar, .bones-svg-line, .bones-svg-fill');
      var bad = [];
      els.forEach(function (el) {
        var r = el.getBoundingClientRect();
        var cs = getComputedStyle(el);
        var paint = el.tagName.toLowerCase() === 'polyline' ? cs.stroke :
                    el.tagName.toLowerCase() === 'polygon' ? cs.fill : cs.backgroundColor;
        var inside = r.left >= box.left - 1 && r.right <= box.right + 1 &&
                     r.top >= box.top - 1 && r.bottom <= box.bottom + 1;
        var sized = r.width > 0 && r.height > 0;
        var painted = paint && paint !== 'none' && paint !== 'transparent' &&
                      paint !== 'rgba(0, 0, 0, 0)';
        if (!inside || !sized || !painted) bad.push(el.className.baseVal || el.className);
      });
      var type = Array.from(sk.classList).find(function (c) {
        return /^bones-skeleton-/.test(c) && c !== 'bones-skeleton-chart';
      });
      return {type: type, height: box.height, marks: els.length, bad: bad};
    })
  ")

  # Eight shapes, each on its own and inside a wrapper.
  expect_length(marks, 16L)
  for (m in marks) {
    expect_gt(m$height, 100, label = paste(m$type, "height"))
    expect_gt(m$marks, 0L, label = paste(m$type, "marks"))
    expect_true(
      length(unlist(m$bad)) == 0L,
      info = paste0(m$type, ": marks that cannot be seen: ", paste(unlist(m$bad), collapse = ", "))
    )
  }

  expect_no_shiny_errors(app)
})
