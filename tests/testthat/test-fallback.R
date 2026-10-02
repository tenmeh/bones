test_that("the default fallback is last and has an alert role", {
  w <- withBones(fake_output("shiny-text-output"))
  html <- as.character(w)
  expect_match(html, 'data-bones-error="true"')
  panel <- tail(w$children, 1L)[[1]]
  expect_equal(panel$attribs$class, "bones-error")
  expect_equal(panel$attribs$role, "alert")
  expect_false(grepl("aria-hidden", as.character(panel), fixed = TRUE))
  expect_false(grepl("bones-error-detail", html, fixed = TRUE))
})

test_that("fallback can be disabled or set for the session", {
  output <- fake_output("shiny-text-output")
  html <- as.character(withBones(output, fallback = FALSE))
  expect_false(grepl("bones-error", html, fixed = TRUE))
  old <- bones_defaults(fallback = FALSE)
  on.exit(options(old))
  expect_false(grepl("bones-error", as.character(withBones(output)), fixed = TRUE))
  panel <- bones_fallback("Custom message")
  bones_defaults(fallback = panel)
  expect_identical(tail(withBones(output)$children, 1L)[[1]], panel)
  expect_false(grepl("bones-error", as.character(withBones(output, fallback = FALSE)), fixed = TRUE))
})

test_that("custom fallback tags are kept inside the panel", {
  custom <- htmltools::tagList(htmltools::tags$p("Custom"), htmltools::tags$button("Help"))
  w <- withBones(fake_output("shiny-text-output"), fallback = custom)
  panel <- tail(w$children, 1L)[[1]]
  expect_equal(panel$attribs$class, "bones-error")
  expect_equal(panel$attribs$role, "alert")
  expect_identical(panel$children[[1]], custom)
})

test_that("existing error panels are kept with any class whitespace", {
  for (class in c("bones-error", "foo  bones-error", "foo\tbones-error", "foo\nbones-error")) {
    custom <- htmltools::tags$div(class = class, "Custom")
    w <- withBones(fake_output("shiny-text-output"), fallback = custom)
    expect_identical(tail(w$children, 1L)[[1]], custom)
  }
})

test_that("a plain fallback tag gets an error panel around it", {
  custom <- htmltools::tags$div("Custom")
  w <- withBones(fake_output("shiny-text-output"), fallback = custom)
  panel <- tail(w$children, 1L)[[1]]
  expect_equal(panel$attribs$class, "bones-error")
  expect_equal(panel$attribs$role, "alert")
  expect_identical(panel$children[[1]], custom)
})

test_that("bones_fallback has optional detail and escapes text", {
  panel <- bones_fallback("<message>", detail = TRUE)
  expect_equal(panel$attribs$class, "bones-error")
  expect_equal(panel$attribs$role, "alert")
  expect_match(as.character(panel), "&lt;message&gt;", fixed = TRUE)
  expect_match(as.character(panel), "bones-error-message", fixed = TRUE)
  expect_match(as.character(panel), "bones-error-detail", fixed = TRUE)
  expect_match(as.character(bones_fallback()), "This content could not be loaded.", fixed = TRUE)
  expect_match(as.character(bones_fallback("")), "bones-error-message", fixed = TRUE)
})

test_that("bones_fallback always has an empty safe error slot", {
  for (detail in c(FALSE, TRUE)) {
    panel <- bones_fallback(detail = detail)
    safe <- panel$children[[2]]
    expect_equal(safe$attribs$class, "bones-error-safe")
    expect_length(safe$children, 0L)
  }
})

test_that("fallback arguments reject invalid values", {
  for (bad in list(TRUE, NA, "text", 1, list(), c(FALSE, FALSE))) {
    expect_error(withBones(fake_output("shiny-text-output"), fallback = bad), "`fallback`")
    expect_error(bones_defaults(fallback = bad), "`fallback`")
  }
  for (bad in list(NA_character_, c("a", "b"), 1, character())) {
    expect_error(bones_fallback(message = bad), "`message`")
  }
  for (bad in list(NA, 1, c(TRUE, FALSE))) {
    expect_error(bones_fallback(detail = bad), "`detail`")
  }
})

test_that("the stylesheet has panel and banner rules", {
  css <- paste(readLines(system.file("www", "bones.css", package = "bones")), collapse = "\n")
  expect_match(css, "\\.bones-error\\s*\\{[^}]*display: none")
  expect_match(css, "\\.bones-wrap\\.bones-errored > \\.bones-error\\s*\\{[^}]*display: flex")
  expect_match(css, "\\.bones-errored\\.bones-has-loaded > \\.bones-content\\s*\\{[^}]*opacity: 0.45")
  expect_match(css, "\\.bones-errored\\.bones-has-loaded > \\.bones-error\\s*\\{[^}]*position: static")
})
