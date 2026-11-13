test_that("custom skeletons reserve their height and learn only on request", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "custom-learn"),
                          name = "bones-custom-learn", seed = 43,
                          wait = FALSE, load_timeout = 45000L, timeout = 15000L)
  reload <- function() {
    app$run_js("window.bonesOldPage = true; location.reload();")
    app$wait_for_js("!window.bonesOldPage && window.Shiny && Shiny.shinyapp &&
      Shiny.shinyapp.isConnected() &&
      document.querySelectorAll('.bones-wrap').length === 3")
  }
  info <- function() {
    app$get_js("
    var out = {};
    document.querySelectorAll('.bones-wrap').forEach(function (w) {
      var s = w.querySelector(':scope > .bones-skeleton');
      out[w.getAttribute('data-bones-id')] = {
        custom: s.classList.contains('bones-skeleton-custom'),
        learned: s.classList.contains('bones-skeleton-learned'),
        loaded: w.classList.contains('bones-has-loaded'),
        height: w.getBoundingClientRect().height,
        blockHeight: s.firstElementChild.getBoundingClientRect().height
      };
    });
    out;
  ")
  }
  app$wait_for_js("window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected()")
  app$run_js("localStorage.clear();")
  reload()
  first <- info()
  for (id in c("learned", "custom", "unremembered")) {
    expect_false(first[[id]]$loaded)
    expect_true(first[[id]]$custom)
    expect_false(first[[id]]$learned)
    expect_gte(first[[id]]$blockHeight, if (id == "unremembered") 180 else 240)
    expect_gte(first[[id]]$height, first[[id]]$blockHeight)
  }

  app$run_js("document.getElementById('load').click();")
  app$wait_for_js("document.querySelectorAll('.bones-loaded').length === 3")
  app$wait_for_js("Object.keys(localStorage).some(function (k) {
    return k.indexOf('bones:layout:') === 0 && k.endsWith(':learned');
  })")
  app$wait_for_js("Object.keys(localStorage).some(function (k) {
    return k.indexOf('bones:height:') === 0 && k.endsWith(':custom');
  })")
  expect_no_shiny_errors(app)
  reload()
  second <- info()
  expect_false(second$learned$loaded)
  expect_true(second$learned$learned)
  expect_false(second$learned$custom)
  expect_false(second$custom$loaded)
  expect_true(second$custom$custom)
  expect_false(second$custom$learned)
  # The real content is shorter than the custom block. Stored height wins.
  expect_lt(second$custom$height, first$custom$height)
  expect_equal(second$unremembered$height, first$unremembered$height)
})
