# helper-shiny-smoke.R --------------------------------------------------
#
# A check that you can use again: "did the application report an error?"
# testthat reads each helper-*.R file before the tests. This file runs in
# the TEST process. It examines the application through the AppDriver
# object. It does not run inside the application.
#
# WHY THIS FILE EXISTS
# Two obvious checks do not find a render error:
#
#   * "the browser console has no errors". Shiny catches a render error and
#     puts it in the output element. Shiny does NOT send it to the browser
#     console.
#   * "the output element is not empty". A render that fails leaves a
#     `shiny-output-error` <div>. That div holds text. The element is thus
#     not empty, and the check passes when it must fail.
#
# A render error always goes to the stderr of the application. Shiny writes
# a line there that holds the word "Error". shinytest2 keeps that line in
# `app$get_logs()`, with `location == "shiny"`.
#
# This file examines three places: the stderr, the browser console, and the
# DOM. It collects each problem into one character vector. One assertion
# then reports all of them together. A test failure thus shows every
# problem at the same time, and not only the first one.

#' Collect each error that the running application reports.
#'
#' @param app A live `shinytest2::AppDriver`.
#' @param allow_dom_errors A regular expression. An output whose id matches
#'   it may be in an error state. Use this for an output that a test puts in
#'   an error state on purpose.
#' @return A character vector. It holds one line for each problem. The
#'   vector is empty when the application reported no error.
collect_shiny_problems <- function(app, allow_dom_errors = NULL) {
  problems <- character(0)

  logs <- as.data.frame(app$get_logs())
  has_logs <- nrow(logs) > 0 && all(c("location", "message") %in% names(logs))

  if (has_logs) {
    # The stderr of the application. A render error reaches this place even
    # when it never reaches the browser console.
    from_r <- logs$message[logs$location == "shiny" &
                             grepl("Error", logs$message, fixed = TRUE)]
    if (length(from_r) > 0) {
      problems <- c(problems, paste("R stderr:", from_r))
    }

    # The browser console. These are failures in the JS code.
    if ("level" %in% names(logs)) {
      is_error <- !is.na(logs$level) & logs$level == "error"
      from_browser <- logs$message[is_error & logs$location == "chromote"]
      if (length(from_browser) > 0) {
        problems <- c(problems, paste("Browser console:", from_browser))
      }
    }
  }

  # The DOM. No output must have the `shiny-output-error` class.
  in_dom <- unlist(app$get_js(
    "Array.from(document.querySelectorAll('.shiny-output-error')).map(e => e.id)"
  ))
  if (!is.null(allow_dom_errors)) {
    in_dom <- in_dom[!grepl(allow_dom_errors, in_dom)]
  }
  if (length(in_dom) > 0) {
    problems <- c(problems, paste("Output element in an error state:", in_dom))
  }

  problems
}

#' Make sure that the running application reported no error.
#'
#' Call this AFTER the test uses the controls. A render error occurs only
#' when its reactive runs.
#'
#' @param app A live `shinytest2::AppDriver`.
#' @param allow_dom_errors Passed to `collect_shiny_problems()`.
#' @return The application, invisibly.
expect_no_shiny_errors <- function(app, allow_dom_errors = NULL) {
  problems <- collect_shiny_problems(app, allow_dom_errors)
  testthat::expect_equal(
    length(problems), 0L,
    info = paste0("The application reported these problems:\n",
                  paste(problems, collapse = "\n"))
  )
  invisible(app)
}

#' Start an AppDriver for `app_dir`. Skip the test, and do not fail it, when
#' this computer has no headless Chrome.
#'
#' Chrome writes its own work files while it runs, in `TMPDIR`, `TMP` or
#' `TEMP`. R CMD check sets those values to a directory inside the tree that
#' it examines later for "detritus in the temp directory". Each file that
#' Chrome leaves there thus causes a NOTE. This function sends Chrome to a
#' directory outside that tree while the browser runs, and removes the
#' directory at the end.
#'
#' @param app_dir The path to the Shiny application, or an application
#'   object.
#' @param ... More arguments for `shinytest2::AppDriver$new()`.
#' @return A live `AppDriver`.
local_app_driver <- function(app_dir, ...) {
  testthat::skip_if_not_installed("shinytest2")
  testthat::skip_if_not_installed("withr")

  runner_tmp <- Sys.getenv("RUNNER_TEMP", unset = "")
  chrome_root <- if (nzchar(runner_tmp)) runner_tmp else tools::R_user_dir("bones", "cache")
  chrome_tmp <- file.path(chrome_root, paste0("chromote-", Sys.getpid()))
  dir.create(chrome_tmp, showWarnings = FALSE, recursive = TRUE)
  withr::local_envvar(
    list(TMPDIR = chrome_tmp, TMP = chrome_tmp, TEMP = chrome_tmp),
    .local_envir = parent.frame()
  )

  app <- tryCatch(
    shinytest2::AppDriver$new(app_dir, ...),
    error = function(e) {
      unlink(chrome_tmp, recursive = TRUE)
      testthat::skip(paste("Could not start a headless browser:", conditionMessage(e)))
    }
  )
  withr::defer(
    {
      app$stop()
      unlink(chrome_tmp, recursive = TRUE)
    },
    envir = parent.frame()
  )
  app
}

#' Wait until each bones wrapper shows its content.
#'
#' app$wait_for_idle() is not sufficient. On a slow machine it can return
#' before the first render ends: this occurred on the macOS runner of GitHub
#' Actions, and the test then found each wrapper still on its skeleton. This
#' function waits for the state itself. If a wrapper never loads, the wait
#' times out, so a real fault still fails the test.
#'
#' @param app A live `shinytest2::AppDriver`.
#' @param timeout The longest wait, in milliseconds.
#' @param ids The output ids to wait for. `NULL` waits for all of them. An
#'   output on a tab that does not show never loads, so give the ids of the
#'   tab that shows.
#' @return The application, invisibly.
wait_for_settled <- function(app, timeout = 20000L, ids = NULL) {
  app$wait_for_js(
    sprintf("(function () {
       var w = %s;
       return w.length > 0 && w.every(function (x) {
         return x.classList.contains('bones-loaded') &&
           !x.classList.contains('bones-stale') &&
           !x.classList.contains('bones-loading');
       });
     })()", wrap_query(ids)),
    timeout = timeout
  )
  app$wait_for_idle(timeout = timeout)
  invisible(app)
}

#' The state classes of each bones wrapper, by output id.
#'
#' @param app A live `shinytest2::AppDriver`.
#' @param ids The output ids to look at. `NULL` looks at all of them.
#' @return A named character vector. Each value is one of "skeleton",
#'   "loaded", "stale" or "loading".
wrapper_states <- function(app, ids = NULL) {
  states <- app$get_js(sprintf("
    %s.map(function (w) {
      var c = w.classList;
      var s = c.contains('bones-stale') ? 'stale' :
              c.contains('bones-loading') ? 'loading' :
              c.contains('bones-loaded') ? 'loaded' : 'skeleton';
      return [w.getAttribute('data-bones-id'), s];
    })
  ", wrap_query(ids)))
  stats::setNames(
    vapply(states, `[[`, character(1), 2L),
    vapply(states, `[[`, character(1), 1L)
  )
}

#' JS for an array of the bones wrappers of the given outputs.
#'
#' @param ids Output ids, or `NULL` for all the wrappers.
#' @return A string of JS.
wrap_query <- function(ids = NULL) {
  selector <- if (is.null(ids)) {
    ".bones-wrap"
  } else {
    paste0(".bones-wrap[data-bones-id=\"", ids, "\"]", collapse = ", ")
  }
  sprintf("Array.from(document.querySelectorAll('%s'))", selector)
}
