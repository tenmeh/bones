test_that("with stale = FALSE, old content stays until the skeleton appears (#42)", {
  testthat::skip_on_cran()
  # One app for both motion settings: the media feature changes the CSS at
  # once, so the app does not need to start again.
  app <- local_app_driver(
    test_path("apps", "content-delay"),
    name = "content-delay", seed = 42L,
    load_timeout = 45000L, timeout = 15000L
  )
  wait_for_settled(app)

  # Sample in the browser so R round trips cannot miss a short blank.
  app$run_js("
    window.sampleContent = function (button) {
      var w = document.querySelector('.bones-wrap');
      var content = w.querySelector('.bones-content');
      var skeleton = w.querySelector('.bones-skeleton');
      var start = null;
      window.contentSamples = [];
      window.contentDone = false;
      function sample() {
        var loading = w.classList.contains('bones-loading');
        if (loading && start === null) start = performance.now();
        if (start !== null) {
          var s = getComputedStyle(skeleton);
          window.contentSamples.push({
            time: performance.now() - start,
            content: getComputedStyle(content).visibility,
            skeleton: s.display !== 'none' && s.visibility === 'visible',
            loading: loading
          });
          if (!loading) {
            window.contentDone = true;
            observer.disconnect();
            clearInterval(timer);
          }
        }
      }
      var observer = new MutationObserver(sample);
      observer.observe(w, {attributes: true, attributeFilter: ['class']});
      var timer = setInterval(sample, 10);
      document.getElementById(button).click();
    };
  ")

  samples <- function(button) {
    app$run_js(sprintf("window.sampleContent('%s');", button))
    app$wait_for_js("window.contentDone")
    app$wait_for_idle()
    rows <- app$get_js("window.contentSamples")
    do.call(rbind, lapply(rows, as.data.frame))
  }

  for (motion in c("no-preference", "reduce")) {
    app$get_chromote_session()$Emulation$setEmulatedMedia(
      features = list(list(name = "prefers-reduced-motion", value = motion))
    )
    fast <- samples("fast")
    expect_gt(sum(fast$loading), 2)
    expect_lt(max(fast$time), 1000)
    expect_equal(unique(fast$content), "visible")
    expect_equal(unique(fast$skeleton), FALSE)

    slow <- samples("slow")
    early <- slow[slow$loading & slow$time < 900, ]
    late <- slow[slow$loading & slow$time > 1100, ]
    expect_gt(nrow(early), 2)
    expect_gt(nrow(late), 2)
    expect_equal(unique(early$content), "visible")
    expect_equal(unique(early$skeleton), FALSE)
    expect_equal(unique(late$content), "hidden")
    expect_equal(unique(late$skeleton), TRUE)
    expect_equal(tail(slow$content, 1), "visible")
  }
  expect_no_shiny_errors(app)

  # Existing error behavior keeps dimmed old content below the banner.
  samples("fail")
  app$wait_for_js("document.querySelector('.bones-wrap').classList.contains('bones-errored')")
  error_state <- app$get_js("(function () {
    var w = document.querySelector('.bones-wrap');
    var c = getComputedStyle(w.querySelector('.bones-content'));
    return {
      errored: w.classList.contains('bones-errored'),
      content: c.visibility,
      opacity: c.opacity,
      animation: c.animationName,
      panel: getComputedStyle(w.querySelector('.bones-error')).display,
      skeleton: getComputedStyle(w.querySelector('.bones-skeleton')).display
    };
  })()")
  expect_equal(error_state, list(
    errored = TRUE, content = "visible", opacity = "0.45",
    animation = "none", panel = "flex", skeleton = "none"
  ))
})
