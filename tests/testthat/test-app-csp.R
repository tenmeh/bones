# test-app-csp.R -----------------------------------------------------------
#
# bones under a strict Content-Security-Policy: no inline styles and no
# inline scripts. Such a policy blocks every style attribute, so bones writes
# none. bones.js sets the same sizes with the CSSOM, which the policy allows.
#
# shinytest2 evaluates strings in the page, which this policy also blocks.
# The AppDriver thus starts the app without the policy, and the test then
# opens the same page with ?csp=1, which adds the policy header. From there,
# it reads the page with Runtime.evaluate of the DevTools protocol.

test_that("a strict Content-Security-Policy blocks nothing, and the sizes still apply", {
  testthat::skip_on_cran()

  app <- local_app_driver(
    test_path("apps", "csp"),
    name         = "bones-csp",
    wait         = FALSE,
    load_timeout = 45000L,
    timeout      = 15000L
  )
  session <- app$get_chromote_session()
  page_js <- function(code) {
    session$Runtime$evaluate(code, returnByValue = TRUE)$result$value
  }

  session$Page$navigate(paste0(app$get_url(), "?csp=1"))
  loaded <- FALSE
  for (i in seq_len(150)) {
    loaded <- isTRUE(page_js("!!document.querySelector('#box-done .bones-wrap.bones-loaded')"))
    if (loaded) break
    Sys.sleep(0.2)
  }
  expect_true(loaded, label = "the page loaded under the policy")

  violations <- page_js("window.cspViolations")
  expect_length(violations, 0L)
  expect_gt(page_js("document.querySelectorAll('[data-bones-style]').length"), 50L)

  # Each declaration in data-bones-style is set on its element.
  unset <- page_js("(function () {
    var bad = [];
    document.querySelectorAll('[data-bones-style]').forEach(function (el) {
      el.getAttribute('data-bones-style').split(';').forEach(function (d) {
        var at = d.indexOf(':');
        if (at < 1) return;
        var name = d.slice(0, at).trim(), want = d.slice(at + 1).trim();
        var got = el.style.getPropertyValue(name).trim();
        var same = got === want ||
          (!isNaN(parseFloat(want)) && parseFloat(got) === parseFloat(want));
        if (!same) bad.push(name + ': ' + want + ' -> ' + got);
      });
    });
    return bad;
  })()")
  expect_length(unset, 0L)

  # The look: bar widths, the reserved height, positions and colours.
  look <- page_js("(function () {
    var text = document.querySelector('#box-text .bones-skeleton');
    var bars = Array.from(text.querySelectorAll('.bones-bar'));
    var tw = text.getBoundingClientRect().width;
    var tableWrap = document.querySelector('#box-table .bones-wrap');
    var points = Array.from(document.querySelectorAll('#box-scatter .bones-skeleton *'))
      .filter(function (el) { return el.style.left; });
    var cells = Array.from(document.querySelectorAll('#box-heatmap .bones-skeleton *'))
      .filter(function (el) { return el.style.opacity; });
    var red = document.querySelector('#box-red .bones-wrap');
    return {
      widths: bars.map(function (b) {
        return Math.round(100 * b.getBoundingClientRect().width / tw);
      }),
      declared: bars.map(function (b) { return parseFloat(b.style.width); }),
      reserve: parseFloat(getComputedStyle(tableWrap).getPropertyValue('--bones-reserve')),
      tableHeight: tableWrap.getBoundingClientRect().height,
      lefts: points.map(function (p) { return Math.round(p.getBoundingClientRect().left); }),
      opacities: cells.map(function (c) { return getComputedStyle(c).opacity; }),
      red: getComputedStyle(red).getPropertyValue('--bones-color').trim(),
      alone: document.querySelector('#box-alone .bones-skeleton').getBoundingClientRect().height
    };
  })()")

  expect_gt(length(look$widths), 3L)
  expect_equal(unlist(look$widths), unlist(look$declared), tolerance = 0.02)
  expect_gt(length(unique(unlist(look$widths))), 1L)
  expect_gt(look$reserve, 0)
  expect_equal(look$tableHeight, look$reserve, tolerance = 0.02)
  expect_gt(length(unique(unlist(look$lefts))), 5L)
  expect_gt(length(unique(unlist(look$opacities))), 3L)
  expect_identical(look$red, "rgb(255, 0, 0)")
  expect_equal(look$alone, 150, tolerance = 0.01)

  # Last, show that the policy is active and that the log works: a style
  # attribute set from a script is blocked, and the log records it.
  probe <- page_js("(function () {
    var el = document.createElement('div');
    el.setAttribute('style', 'width: 7px');
    document.body.appendChild(el);
    return el.style.width;
  })()")
  expect_identical(probe, "")
  for (i in seq_len(25)) {
    if (page_js("window.cspViolations.length") > 0) break
    Sys.sleep(0.2)
  }
  expect_identical(page_js("window.cspViolations.length"), 1L)
})
