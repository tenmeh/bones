# Learned shapes in a real browser, with apps/learn. See that app for what
# each output holds.

learn_ids <- c("tbl", "txt", "cards", "word", "canvas", "chart", "fixed", "fail")

# Wait until each wrapper shows its content. After a reload the idle
# tracking of shinytest2 is gone, so wait for the state itself. A layout is
# stored 250ms after the load, so wait a little more.
wait_all_loaded <- function(app) {
  app$wait_for_js(sprintf(
    "document.querySelectorAll('.bones-wrap').length === %1$d &&
     document.querySelectorAll('.bones-wrap.bones-loaded').length === %1$d",
    length(learn_ids)
  ), timeout = 30000)
  Sys.sleep(0.8)
}

# A first visit with an empty storage.
first_visit <- function(app) {
  app$run_js("try { localStorage.clear(); } catch (e) {}")
  app$run_js("location.reload();")
  Sys.sleep(0.5)
  wait_all_loaded(app)
}

# The stored layouts, as JSON strings named by output id.
stored_layouts <- function(app) {
  app$get_js("
    var out = {};
    Object.keys(localStorage).forEach(function (k) {
      if (k.indexOf('bones:layout:') === 0) out[k.split(':').pop()] = localStorage.getItem(k);
    });
    out;
  ")
}

test_that("a layout is stored for each output that learns", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "learn"), name = "bones-learn-store",
                          wait = FALSE, load_timeout = 45000L, timeout = 15000L)
  first_visit(app)

  stored <- stored_layouts(app)
  expect_equal(sort(names(stored)), c("cards", "fail", "tbl", "txt"))

  for (id in names(stored)) {
    record <- jsonlite::fromJSON(stored[[id]], simplifyVector = FALSE)
    expect_equal(record$v, 1, info = id)
    expect_gt(record$w, 0)
    expect_gt(record$h, 0)
    expect_gte(length(record$b), 2)
    expect_lte(length(record$b), 150)
    for (box in record$b) {
      expect_length(box, 5)
      expect_true(box[[5]] %in% c(0, 1), info = id)
    }
  }

  tbl <- jsonlite::fromJSON(stored$tbl, simplifyVector = FALSE)
  expect_gte(length(tbl$b), 13)   # 12 rows and the header
  cards <- jsonlite::fromJSON(stored$cards, simplifyVector = FALSE)
  expect_equal(sum(vapply(cards$b, function(box) box[[5]] == 1, logical(1))), 3)
})

test_that("a stored layout holds no text from the app", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "learn"), name = "bones-learn-privacy",
                          wait = FALSE, load_timeout = 45000L, timeout = 15000L)
  first_visit(app)

  stored <- unlist(stored_layouts(app))
  expect_gt(length(stored), 0)
  for (x in stored) {
    expect_match(x, "^[0-9,\\[\\]{}\":vwhb -]*$", perl = TRUE)
    for (word in c("Card", "Mazda", "Hi", "mpg", "text")) {
      expect_false(grepl(word, x, fixed = TRUE), info = word)
    }
  }
})

test_that("an error does not change a stored layout", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "learn"), name = "bones-learn-error",
                          wait = FALSE, load_timeout = 45000L, timeout = 15000L)
  first_visit(app)

  before <- stored_layouts(app)$fail
  expect_false(is.null(before))
  app$run_js("document.getElementById('break_it').click();")
  app$wait_for_js("document.querySelector('#box-fail .shiny-output-error') !== null", timeout = 15000)
  Sys.sleep(1)
  expect_identical(stored_layouts(app)$fail, before)
})

# --- Drawing on the next visit ----------------------------------------------

# Reload, and wait until the wrappers are on the page. Their content takes
# 1.5 seconds, so the skeletons can be read before it arrives.
reload_page <- function(app) {
  app$run_js("location.reload();")
  Sys.sleep(0.4)
  app$wait_for_js(sprintf("document.querySelectorAll('.bones-wrap').length === %d",
                          length(learn_ids)), timeout = 30000)
}

# For each wrapper: is its skeleton learned, how many boxes it has, the
# place of the first box, and the height of the wrapper.
skeleton_info <- function(app) {
  app$get_js("
    var out = {};
    document.querySelectorAll('.bones-wrap').forEach(function (w) {
      var s = w.querySelector(':scope > .bones-skeleton');
      var learned = !!s && s.classList.contains('bones-skeleton-learned');
      var first = learned ? s.firstElementChild : null;
      out[w.getAttribute('data-bones-id')] = {
        learned: learned,
        loaded: w.classList.contains('bones-has-loaded'),
        n: learned ? s.children.length : 0,
        left: first ? first.style.left : '',
        top: first ? first.style.top : '',
        height: Math.round(w.getBoundingClientRect().height)
      };
    });
    out;
  ")
}

parse_layouts <- function(app) {
  lapply(stored_layouts(app), jsonlite::fromJSON, simplifyVector = FALSE)
}

test_that("the next visit draws the learned shape", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "learn"), name = "bones-learn-draw",
                          wait = FALSE, load_timeout = 45000L, timeout = 15000L)
  first_visit(app)
  records <- parse_layouts(app)

  reload_page(app)
  info <- skeleton_info(app)

  for (id in c("tbl", "txt", "cards")) {
    record <- records[[id]]
    got <- info[[id]]
    expect_false(got$loaded, info = id)
    expect_true(got$learned, info = id)
    expect_equal(got$n, length(record$b), info = id)
    expect_equal(got$left, paste0(record$b[[1]][[1]], "px"), info = id)
    expect_equal(got$top, paste0(record$b[[1]][[2]], "px"), info = id)
    expect_lte(abs(got$height - record$h), 1)
  }
  for (id in c("chart", "fixed", "word", "canvas")) {
    expect_false(info[[id]]$learned, info = id)
  }
  wait_all_loaded(app)
  expect_no_shiny_errors(app)
})

test_that("a much narrower window draws the built-in shape", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "learn"), name = "bones-learn-narrow",
                          wait = FALSE, load_timeout = 45000L, timeout = 15000L)
  w0 <- app$get_js("window.innerWidth")
  first_visit(app)

  app$set_window_size(width = round(0.8 * w0), height = 900, wait = FALSE)
  reload_page(app)
  info <- skeleton_info(app)
  expect_false(info$tbl$loaded)
  expect_false(info$tbl$learned)
})

test_that("the newest layout wins", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "learn"), name = "bones-learn-newest",
                          wait = FALSE, load_timeout = 45000L, timeout = 15000L)
  first_visit(app)
  before <- length(parse_layouts(app)$tbl$b)

  app$run_js("document.getElementById('fewer').click();")
  app$wait_for_js("document.querySelectorAll('#tbl tbody tr').length === 4", timeout = 15000)
  Sys.sleep(0.8)

  reload_page(app)
  info <- skeleton_info(app)
  expect_true(info$tbl$learned)
  expect_lt(info$tbl$n, before)
})

test_that("a learned skeleton does not scroll the page sideways", {
  testthat::skip_on_cran()
  app <- local_app_driver(test_path("apps", "learn"), name = "bones-learn-scroll",
                          wait = FALSE, load_timeout = 45000L, timeout = 15000L)
  w0 <- app$get_js("window.innerWidth")
  first_visit(app)

  # Within 10%, so the layout is drawn at its old, wider width.
  app$set_window_size(width = round(0.95 * w0), height = 900, wait = FALSE)
  reload_page(app)
  info <- skeleton_info(app)
  expect_true(info$tbl$learned)
  expect_true(app$get_js("document.documentElement.scrollWidth <= window.innerWidth"))
})
