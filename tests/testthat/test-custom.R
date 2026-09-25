# Your own placeholder, bones_block(), and the animations.

test_that("bones_block() makes a grey block of the given size", {
  html <- as.character(bones_block("60%"))
  expect_match(html, 'class="bones-bar bones-block"', fixed = TRUE)
  expect_match(html, "width: 60%; height: 0.75rem;", fixed = TRUE)

  # A number is pixels, as in Shiny.
  circle <- as.character(bones_block(48, 48, shape = "circle"))
  expect_match(circle, "bones-block-circle", fixed = TRUE)
  expect_match(circle, "width: 48px; height: 48px;", fixed = TRUE)
})

test_that("bones_block() refuses a bad size or shape", {
  expect_error(bones_block(NULL), "`width` must be a CSS width", fixed = TRUE)
  expect_error(bones_block(height = NULL), "`height` must be a CSS height", fixed = TRUE)
  expect_error(bones_block(c("1px", "2px")), "`width` must be a single CSS length", fixed = TRUE)
  expect_error(bones_block(shape = "star"), "should be one of")
})

test_that("withBones() puts your own placeholder in place of the built-in shape", {
  html <- as.character(withBones(
    fake_output("shiny-html-output", id = "profile"),
    skeleton = htmltools::tagList(bones_block("40%"), bones_block("80%"))
  ))
  expect_match(html, 'data-bones-type="custom"', fixed = TRUE)
  expect_match(html, "bones-skeleton bones-skeleton-custom", fixed = TRUE)
  expect_match(html, 'aria-hidden="true"', fixed = TRUE)
  expect_equal(count_matches(html, "bones-block"), 2L)
  # No built-in shape is there too.
  expect_no_match(html, "bones-skeleton-text", fixed = TRUE)
  # The id and the other attributes stay, so bones.js treats it as usual.
  expect_match(html, 'data-bones-id="profile"', fixed = TRUE)
})

test_that("your own placeholder keeps the space of the output", {
  # A height from the output wins, as for a built-in shape.
  plot <- as.character(withBones(
    fake_output("shiny-plot-output", style = "width:100%;height:320px;"),
    skeleton = bones_block("100%", "320px")
  ))
  expect_match(plot, "--bones-reserve: 320px", fixed = TRUE)
  expect_no_match(plot, "data-bones-remember", fixed = TRUE)

  # With no height, the default of the shape of the output, and it is
  # remembered, because it is an estimate.
  text <- as.character(withBones(fake_output("shiny-html-output"), skeleton = bones_block()))
  expect_match(text, sprintf("--bones-reserve: %s", bones:::default_height("text")), fixed = TRUE)
  expect_match(text, 'data-bones-remember="true"', fixed = TRUE)
})

test_that("your own placeholder turns off the chart kind of a widget", {
  widget <- htmltools::tags$div(id = "w", class = "plotly html-widget html-widget-output")
  html <- as.character(withBones(widget, skeleton = bones_block()))
  expect_no_match(html, "data-bones-detect", fixed = TRUE)
  expect_no_match(html, "bones-kinds", fixed = TRUE)
})

test_that("withBones() refuses a bad skeleton", {
  out <- fake_output("shiny-html-output")
  expect_error(withBones(out, type = "text", skeleton = bones_block()),
               "Give `type` or `skeleton`, not both.", fixed = TRUE)
  expect_error(withBones(out, skeleton = 42), "`skeleton` must be a tag", fixed = TRUE)
})

test_that("bones_auto() refuses a skeleton for every output", {
  expect_error(bones_auto(fake_output("shiny-html-output"), skeleton = bones_block()),
               "`skeleton` cannot go to bones_auto()", fixed = TRUE)
})

test_that("each animation is accepted, and gives its class", {
  for (anim in c("wave", "pulse", "cascade", "sweep", "none")) {
    html <- as.character(withBones(fake_output("shiny-plot-output"), animation = anim))
    expect_match(html, paste0("bones-anim-", anim), fixed = TRUE, info = anim)
  }
  expect_error(withBones(fake_output("shiny-plot-output"), animation = "spin"), "should be one of")

  old <- bones_defaults(animation = "cascade")
  on.exit(options(old))
  expect_match(as.character(bones_skeleton("text")), "bones-anim-cascade", fixed = TRUE)
})

test_that("the stylesheet has the new animations, and stops them for reduced motion", {
  css <- paste(readLines(system.file("www", "bones.css", package = "bones")), collapse = "\n")
  expect_match(css, "@keyframes bones-cascade", fixed = TRUE)
  expect_match(css, "@keyframes bones-sweep", fixed = TRUE)
  reduced <- sub(".*@media \\(prefers-reduced-motion: reduce\\)", "", css)
  expect_match(reduced, ".bones-anim-cascade .bones-bar", fixed = TRUE)
  expect_match(reduced, ".bones-wrap.bones-anim-sweep > .bones-skeleton::after", fixed = TRUE)

  # The band belongs to the skeleton of the wrapper itself (">"), not to a
  # bones_skeleton() in the content, which is not positioned.
  expect_no_match(css, ".bones-anim-sweep .bones-skeleton::after", fixed = TRUE)
})

test_that("a fill output gets a wrapper that passes the fill on", {
  skip_if_not_installed("shiny")
  classes <- function(html, cls) {
    regmatches(html, regexpr(sprintf('class="%s[^"]*"', cls), html))
  }
  plot <- as.character(withBones(shiny::plotOutput("p")))
  expect_match(classes(plot, "bones-wrap"), "html-fill-container", fixed = TRUE)
  expect_match(classes(plot, "bones-wrap"), "html-fill-item", fixed = TRUE)
  expect_match(classes(plot, "bones-content"), "html-fill-container", fixed = TRUE)

  # An output that is not a fill item keeps a plain wrapper.
  table <- as.character(withBones(shiny::tableOutput("t")))
  expect_no_match(table, "html-fill", fixed = TRUE)
})

test_that("the template of the chart kinds has the first shape, plot, too", {
  widget <- htmltools::tags$div(id = "w", class = "plotly html-widget html-widget-output")
  html <- as.character(withBones(widget))
  expect_match(html, 'data-bones-kind="plot"', fixed = TRUE)
})
