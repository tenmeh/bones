# bones writes no style attribute, so a strict Content-Security-Policy has
# nothing to block. The sizes go in data-bones-style, which bones.js applies.

has_style_attr <- function(html) grepl("(^|[[:space:]])style=", html)

test_that("no shape writes a style attribute", {
  for (type in skeleton_types()) {
    html <- as.character(bones_skeleton(type))
    expect_false(has_style_attr(html), label = type)
    expect_match(html, "data-bones-style=", fixed = TRUE, label = type)
  }
})

test_that("no wrapper writes a style attribute, with colours from the defaults", {
  old <- bones_defaults(color = "rgb(255, 0, 0)", radius = "4px", speed = 2)
  withr::defer(options(old))
  for (type in skeleton_types()) {
    html <- as.character(withBones(fake_output("shiny-html-output"), type = type))
    expect_false(has_style_attr(html), label = type)
  }
  html <- as.character(withBones(fake_output("shiny-html-output")))
  expect_match(html, "--bones-color: rgb(255, 0, 0);", fixed = TRUE)
})

test_that("bones_auto() and the error panel write no style attribute", {
  ui <- htmltools::tagList(
    fake_output("shiny-text-output", id = "a"),
    fake_output("shiny-html-output", id = "b")
  )
  expect_false(has_style_attr(as.character(bones_auto(ui))))
  html <- as.character(withBones(fake_output("shiny-html-output"),
                                 error = bones_error("Failed", detail = TRUE)))
  expect_false(has_style_attr(html))
})

test_that("a style attribute of the output itself is left as it is", {
  html <- as.character(withBones(fake_output("shiny-plot-output", style = "height:320px")))
  expect_match(html, 'style="height:320px"', fixed = TRUE)
})

test_that("bones.js applies data-bones-style with the CSSOM", {
  js <- paste(readLines(system.file("www", "bones.js", package = "bones")), collapse = "\n")
  expect_match(js, 'getAttribute("data-bones-style")', fixed = TRUE)
  expect_match(js, "style.setProperty(", fixed = TRUE)
  expect_false(grepl('setAttribute("style"', js, fixed = TRUE))
})
