test_that("retry and hold write ids without changing them", {
  w <- withBones(fake_output("shiny-text-output"),
                 retry = "module-retry", hold = c("module-refresh", "a b%20"))
  expect_equal(w$attribs[["data-bones-retry"]], "module-retry")
  expect_equal(w$attribs[["data-bones-hold"]], "module-refresh a%20b%2520")
  html <- as.character(w)
  expect_match(html, '<button type="button" class="bones-retry">Try again</button>', fixed = TRUE)
  expect_false(grepl(" style=", html, fixed = TRUE))
})

test_that("NULL writes no trigger attributes or retry button", {
  w <- withBones(fake_output("shiny-text-output"), retry = NULL, hold = NULL)
  expect_null(w$attribs[["data-bones-retry"]])
  expect_null(w$attribs[["data-bones-hold"]])
  expect_false(grepl("bones-retry", as.character(w), fixed = TRUE))
})

test_that("retry is appended to custom error panels", {
  for (panel in list(bones_error("Custom message"), htmltools::tags$p("Custom message"))) {
    w <- withBones(fake_output("shiny-text-output"), error = panel, retry = "retry")
    html <- as.character(w)
    expect_match(html, "Custom message")
    expect_equal(count_matches(html, 'class="bones-error"'), 1L)
    expect_equal(count_matches(html, 'class="bones-retry"'), 1L)
    expect_lt(regexpr("Custom message", html)[1], regexpr("class=\"bones-retry\"", html, fixed = TRUE)[1])
  }
})

test_that("invalid trigger ids give clear errors", {
  ui <- fake_output("shiny-text-output")
  for (bad in list(character(), "", " ", NA_character_, TRUE, 1, c("a", "b"), list("a"))) {
    expect_error(withBones(ui, retry = bad), "`retry` must be a single non-empty input id", fixed = TRUE)
  }
  for (bad in list(character(), "", " ", NA_character_, TRUE, 1, c("a", NA), list("a"))) {
    expect_error(withBones(ui, hold = bad), "`hold` must be a non-empty character vector", fixed = TRUE)
  }
  expect_error(withBones(ui, retry = "retry", error = FALSE),
               "`retry` cannot be used with `error = FALSE`.", fixed = TRUE)
})

test_that("bones_auto accepts both trigger arguments", {
  w <- bones_auto(fake_output("shiny-text-output", id = "value"),
                  retry = "retry", hold = "refresh")
  expect_match(as.character(w), 'data-bones-retry="retry"', fixed = TRUE)
  expect_match(as.character(w), 'data-bones-hold="refresh"', fixed = TRUE)
})
