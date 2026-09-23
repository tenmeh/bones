# Chart skeletons: one shape for each common kind of chart.
#
# plotOutput() cannot say what kind of chart it will hold, because
# renderPlot() decides that later, on the server. The caller thus names the
# shape with `type`. "plot" stays the shape of a bar chart.

chart_types <- c("bar", "line", "scatter", "area", "histogram", "pie", "heatmap")

test_that("each chart type makes a skeleton with its own class", {
  for (type in chart_types) {
    html <- as.character(bones_skeleton(type))
    expect_match(html, paste0("bones-skeleton-", type), fixed = TRUE, info = type)
    expect_match(html, 'aria-hidden="true"', fixed = TRUE, info = type)
  }
})

test_that("withBones() accepts each chart type and keeps it", {
  for (type in chart_types) {
    html <- as.character(withBones(fake_output("shiny-plot-output"), type = type))
    expect_match(html, sprintf('data-bones-type="%s"', type), fixed = TRUE, info = type)
  }
})

test_that("plotOutput() still gets the bar shape when no type is given", {
  html <- as.character(withBones(fake_output("shiny-plot-output")))
  expect_match(html, 'data-bones-type="plot"', fixed = TRUE)
  expect_match(html, "bones-plot-area", fixed = TRUE)
  expect_equal(count_matches(html, "bones-bar-column"), 8L)
})

test_that("a chart skeleton gets the height of a plot", {
  for (type in chart_types) {
    expect_equal(bones:::default_height(type), "400px", info = type)
  }
})

test_that("bar and histogram draw columns on an axis", {
  bar <- as.character(bones_skeleton("bar"))
  expect_equal(count_matches(bar, "bones-bar-column"), 8L)
  expect_match(bar, "bones-axis", fixed = TRUE)

  # A histogram has more columns, with no space between them.
  hist <- as.character(bones_skeleton("histogram"))
  expect_equal(count_matches(hist, "bones-bar-column"), 12L)
  expect_match(hist, "bones-plot-area-tight", fixed = TRUE)
  expect_match(hist, "bones-axis", fixed = TRUE)
})

test_that("scatter draws dots inside the plot area", {
  html <- as.character(bones_skeleton("scatter"))
  n <- count_matches(html, "bones-dot")
  expect_gte(n, 15L)

  # Each dot has a position in percent, from 0 to 100.
  pos <- regmatches(html, gregexpr("(left|bottom): [0-9.]+%", html))[[1]]
  values <- as.numeric(sub("^(left|bottom): ([0-9.]+)%$", "\\2", pos))
  expect_length(values, 2L * n)
  expect_true(all(values >= 0 & values <= 100))
  expect_match(html, "bones-axis", fixed = TRUE)
})

test_that("line and area draw an SVG that scales to the plot area", {
  line <- as.character(bones_skeleton("line"))
  expect_match(line, "<svg", fixed = TRUE)
  expect_match(line, "<polyline", fixed = TRUE)
  expect_match(line, 'preserveAspectRatio="none"', fixed = TRUE)
  expect_match(line, "bones-axis", fixed = TRUE)

  area <- as.character(bones_skeleton("area"))
  expect_match(area, "<polygon", fixed = TRUE)
  expect_match(area, "<polyline", fixed = TRUE)

  # The SVG is only for the eye, like the rest of the skeleton.
  expect_match(line, 'focusable="false"', fixed = TRUE)
})

test_that("pie draws a disc and a legend", {
  html <- as.character(bones_skeleton("pie"))
  expect_match(html, "bones-pie-disc", fixed = TRUE)
  expect_equal(count_matches(html, "bones-pie-key\""), 4L)
})

test_that("heatmap draws a grid of cells of different strengths", {
  html <- as.character(bones_skeleton("heatmap"))
  expect_equal(count_matches(html, "bones-heat-cell"), 60L)

  opacity <- as.numeric(sub(
    "opacity: ", "",
    regmatches(html, gregexpr("opacity: [0-9.]+", html))[[1]]
  ))
  expect_length(opacity, 60L)
  expect_gt(length(unique(opacity)), 5L)
  expect_true(all(opacity > 0 & opacity <= 1))
})

test_that("the SVG shapes animate and respect reduced motion", {
  css <- paste(
    readLines(system.file("www", "bones.css", package = "bones"), warn = FALSE),
    collapse = "\n"
  )
  # A gradient background does not move along an SVG stroke, so the SVG
  # shapes pulse in the wave animation.
  expect_match(css, "\\.bones-anim-wave \\.bones-svg\\s*[,{]")
  reduced <- regmatches(css, regexpr("@media \\(prefers-reduced-motion: reduce\\)[\\s\\S]*$", css, perl = TRUE))
  expect_match(reduced, ".bones-anim-wave .bones-svg", fixed = TRUE)
})

test_that("an unknown type still lists the choices", {
  expect_error(bones_skeleton("donut"), "should be one of")
  expect_error(withBones(fake_output("shiny-plot-output"), type = "donut"), "should be one of")
})
