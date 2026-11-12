# Samples run inside the browser, so a round trip from R cannot miss a frame.
install_hold_sampler <- function(app) {
  app$run_js("
    window.wrapFor = function (id) {
      return document.getElementById(id).closest('.bones-wrap');
    };
    window.stateFor = function (id) {
      var w = wrapFor(id), s = getComputedStyle(w.querySelector('.bones-skeleton'));
      return {
        held: w.classList.contains('bones-held'),
        loading: w.classList.contains('bones-loading'),
        errored: w.classList.contains('bones-errored'),
        skeleton: s.display !== 'none' && s.visibility === 'visible',
        content: getComputedStyle(w.querySelector('.bones-content')).visibility,
        height: w.getBoundingClientRect().height
      };
    };
    window.sampleHold = function (id, button) {
      var w = wrapFor(id);
      window.holdSamples = [];
      window.firstHoldFrame = null;
      window.beforeHold = stateFor(id);
      if (window.holdObserver) window.holdObserver.disconnect();
      window.holdObserver = new MutationObserver(function () {
        holdSamples.push(stateFor(id));
      });
      holdObserver.observe(w, {attributes: true, attributeFilter: ['class']});
      var control = button ? document.getElementById(button) : w.querySelector('.bones-retry');
      control.click();
      requestAnimationFrame(function () { window.firstHoldFrame = stateFor(id); });
    };
  ")
}

test_that("retry shows a skeleton and recovers, including in a module", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "external-state"),
                          name = "retry", seed = 42L, timeout = 15000L)
  install_hold_sampler(app)
  for (id in c("retry_value", "module-value")) {
    app$wait_for_js(sprintf("stateFor('%s').errored", id))
    expect_equal(app$get_js(sprintf(
      "wrapFor('%s').querySelector('.bones-retry').tabIndex", id
    )), 0)
    app$run_js(sprintf("sampleHold('%s');", id))
    app$wait_for_js("window.firstHoldFrame !== null")
    frame <- app$get_js("window.firstHoldFrame")
    expect_equal(frame$skeleton, TRUE)
    expect_equal(frame$loading, TRUE)
    expect_equal(frame$errored, FALSE)
    app$wait_for_idle()
    app$wait_for_js(sprintf("!stateFor('%s').held", id))
    expect_equal(app$get_js(sprintf("stateFor('%s').content", id)), "visible")
    expect_equal(app$get_js(sprintf("stateFor('%s').errored", id)), FALSE)
    expect_match(app$get_value(output = id), "[Rr]ecovered")
    expect_equal(app$get_js(sprintf(
      "document.getElementById('%s').classList.contains('shiny-output-error')", id
    )), FALSE)
  }
  # The module's hold id uses the same namespace as its retry id.
  app$run_js("sampleHold('module-value', 'module-refresh');")
  app$wait_for_js("window.firstHoldFrame !== null")
  expect_equal(app$get_js("window.firstHoldFrame.skeleton"), TRUE)
  app$wait_for_idle()
  app$wait_for_js("!stateFor('module-value').held")
})

test_that("retry with no output dependency restores the error at idle", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "external-state"),
                          name = "retry-idle", seed = 42L, timeout = 15000L)
  install_hold_sampler(app)
  app$wait_for_js("stateFor('stuck').errored")
  app$run_js("sampleHold('stuck');")
  app$wait_for_js("window.firstHoldFrame !== null")
  expect_equal(app$get_js("window.firstHoldFrame.skeleton"), TRUE)
  expect_equal(app$get_js("window.firstHoldFrame.loading"), TRUE)
  expect_equal(app$get_js("window.firstHoldFrame.errored"), FALSE)
  app$wait_for_idle()
  app$wait_for_js("stateFor('stuck').errored && !stateFor('stuck').held")
  expect_equal(app$get_js("stateFor('stuck').skeleton"), FALSE)
  expect_equal(app$get_js("stateFor('stuck').loading"), FALSE)
})

test_that("input holds show within one frame before lazy invalidation", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "external-state"),
                          name = "hold-lazy", seed = 42L, timeout = 15000L)
  install_hold_sampler(app)
  app$wait_for_js("stateFor('value').content === 'visible'")
  for (motion in c("no-preference", "reduce")) {
    app$get_chromote_session()$Emulation$setEmulatedMedia(
      features = list(list(name = "prefers-reduced-motion", value = motion))
    )
    for (id in c("value", "replacement")) {
      app$run_js(sprintf("sampleHold('%s', 'refresh');", id))
      app$wait_for_js("window.firstHoldFrame !== null")
      frame <- app$get_js("window.firstHoldFrame")
      expect_equal(frame$skeleton, TRUE)
      expect_equal(frame$content, "hidden")
      expect_equal(frame$height, app$get_js("window.beforeHold.height"))
      app$wait_for_idle()
      app$wait_for_js(sprintf("!stateFor('%s').held", id))
      expect_equal(app$get_js(sprintf("stateFor('%s').content", id)), "visible")
      expect_equal(app$get_js(sprintf("stateFor('%s').skeleton", id)), FALSE)
      expect_equal(app$get_js("holdSamples.some(function (s) { return s.held; })"), TRUE)
    }
  }
  expect_equal(app$get_value(output = "value"), "Value 4")
})

test_that("an unused hold input releases at idle", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "external-state"),
                          name = "hold-idle", seed = 42L, timeout = 15000L)
  install_hold_sampler(app)
  app$wait_for_js("stateFor('value').content === 'visible'")
  app$run_js("sampleHold('value', 'unused');")
  app$wait_for_js("window.firstHoldFrame !== null")
  expect_equal(app$get_js("window.firstHoldFrame.skeleton"), TRUE)
  app$wait_for_idle()
  app$wait_for_js("!stateFor('value').held")
  expect_equal(app$get_js("stateFor('value').content"), "visible")
  expect_equal(app$get_value(output = "value"), "Value 0")
})

test_that("explicit holds accept ids and elements and survive idle", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "external-state"),
                          name = "hold-api", seed = 42L, timeout = 15000L)
  install_hold_sampler(app)
  app$wait_for_js("stateFor('value').content === 'visible'")
  for (el in c("'value'", "document.getElementById('value')", "wrapFor('value')")) {
    app$run_js(sprintf("Bones.hold(%s, true);", el))
    expect_equal(app$get_js("stateFor('value').skeleton"), TRUE)
    app$run_js("document.getElementById('unused').click();")
    app$wait_for_idle()
    expect_equal(app$get_js("stateFor('value').held"), TRUE)
    app$run_js(sprintf("Bones.hold(%s, false);", el))
    expect_equal(app$get_js("stateFor('value').content"), "visible")
    expect_equal(app$get_js("stateFor('value').held"), FALSE)
  }
  app$run_js("Bones.hold('value', true); document.getElementById('refresh').click();")
  app$wait_for_idle()
  app$wait_for_js("!stateFor('value').held")
  expect_equal(app$get_value(output = "value"), "Value 1")
  app$run_js("Bones.hold('value', true); document.getElementById('fail').click();")
  app$wait_for_idle()
  app$wait_for_js("stateFor('value').errored && !stateFor('value').held")
  expect_equal(app$get_js("stateFor('value').skeleton"), FALSE)
  expect_equal(app$get_js("getComputedStyle(wrapFor('value').querySelector('.bones-error')).display"), "flex")
})

test_that("holds keep learned records and count min_time from the hold", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "external-state"),
                          name = "hold-timing", seed = 42L, timeout = 15000L)
  install_hold_sampler(app)
  app$wait_for_js("stateFor('value').content === 'visible'")
  # Send a value event directly to control the gap between completion and
  # the delayed layout save. The other tests exercise actual server loads.
  app$run_js("
    window.layoutKey = 'bones:layout:' + location.pathname + ':value';
    var w = wrapFor('value'), rect = w.getBoundingClientRect();
    window.savedLayout = JSON.stringify({v: 1, w: rect.width, h: rect.height,
      b: [[0, 0, 30, 10, 0]]});
    localStorage.setItem(layoutKey, savedLayout);
    jQuery(document.getElementById('value')).trigger({type: 'shiny:value', value: 'Value 0'});
    Bones.hold('value', true);
    window.layoutSaveDone = false;
    setTimeout(function () { window.layoutSaveDone = true; }, 350);
  ")
  app$wait_for_js("window.layoutSaveDone")
  expect_equal(app$get_js("localStorage.getItem(layoutKey)"), app$get_js("savedLayout"))
  app$run_js("
    Bones.hold('value', false);
    var w = wrapFor('value');
    w.setAttribute('data-bones-min-time', '400');
    window.holdElapsed = null;
    var start = performance.now();
    var observer = new MutationObserver(function () {
      if (!w.classList.contains('bones-held')) {
        window.holdElapsed = performance.now() - start;
        observer.disconnect();
      }
    });
    observer.observe(w, {attributes: true, attributeFilter: ['class']});
    Bones.hold('value', true);
    jQuery(document.getElementById('value')).trigger({type: 'shiny:value', value: 'Value 0'});
    window.heldAfterValue = stateFor('value').held;
  ")
  expect_equal(app$get_js("window.heldAfterValue"), TRUE)
  app$wait_for_js("window.holdElapsed !== null")
  expect_gte(app$get_js("window.holdElapsed"), 380)
  expect_equal(app$get_js("stateFor('value').content"), "visible")
})
