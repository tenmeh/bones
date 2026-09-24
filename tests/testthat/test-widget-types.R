# Visualisation widgets: the shape of each one, found from its output.
#
# Each htmlwidget output writes the name of its widget as a class on the
# container, next to "html-widget-output": for example
# class="leaflet html-widget html-widget-output". bones reads that name.
#
# The tests build that markup here, in the same form as
# htmlwidgets::shinyWidgetOutput(), so the package does not need each
# widget package in Suggests. The real output functions were checked by hand
# against the same map.

widget_output <- function(name, id = "w", style = "width:100%;height:400px;") {
  htmltools::tags$div(
    id = id,
    class = paste(name, "html-widget html-widget-output shiny-report-size"),
    style = style
  )
}

test_that("a map widget gets the map shape", {
  for (name in c("leaflet", "mapdeck", "globe", "google_map", "maplibregl",
                 "mapboxgl", "deckgl", "mapboxer")) {
    expect_equal(bones:::infer_type(widget_output(name)), "map", info = name)
  }
})

test_that("a network or diagram widget gets the network shape", {
  for (name in c("visNetwork", "grViz", "DiagrammeR", "forceNetwork", "sankeyNetwork",
                 "diagonalNetwork", "radialNetwork", "dendroNetwork", "collapsibleTree")) {
    expect_equal(bones:::infer_type(widget_output(name)), "network", info = name)
  }
})

test_that("timevis gets the timeline shape, and wordcloud2 the word cloud", {
  expect_equal(bones:::infer_type(widget_output("timevis")), "timeline")
  expect_equal(bones:::infer_type(widget_output("wordcloud2")), "wordcloud")
})

test_that("a widget of one kind of chart gets that shape", {
  expect_equal(bones:::infer_type(widget_output("dygraphs")), "line")
  expect_equal(bones:::infer_type(widget_output("sparkline")), "line")
  expect_equal(bones:::infer_type(widget_output("scatterplotThree")), "scatter")
})

test_that("a widget that can draw any chart keeps the bar shape", {
  # plotly, echarts4r and the others can draw any kind of chart. The output
  # does not say which, so `type` is still the way to choose.
  for (name in c("plotly", "echarts4r", "highchart", "girafe", "apexcharter",
                 "billboarder", "something-new")) {
    expect_equal(bones:::infer_type(widget_output(name)), "plot", info = name)
  }
  html <- as.character(withBones(widget_output("plotly"), type = "line"))
  expect_match(html, 'data-bones-type="line"', fixed = TRUE)
})

test_that("the height of the widget is kept", {
  html <- as.character(withBones(widget_output("leaflet", style = "width:100%;height:520px;")))
  expect_match(html, "--bones-reserve: 520px", fixed = TRUE)
})

test_that("each new shape makes a skeleton with its own marks", {
  map <- as.character(bones_skeleton("map"))
  expect_match(map, "bones-skeleton-map", fixed = TRUE)
  expect_equal(count_matches(map, "bones-pin\""), 3L)
  expect_equal(count_matches(map, "bones-map-zoom-button"), 2L)
  expect_match(map, "<polyline", fixed = TRUE)          # the roads

  network <- as.character(bones_skeleton("network"))
  expect_match(network, "bones-skeleton-network", fixed = TRUE)
  expect_gte(count_matches(network, "bones-svg-node"), 8L)
  expect_gte(count_matches(network, "bones-svg-edge"), 8L)
  # The nodes must stay round, so this SVG keeps its aspect ratio.
  expect_match(network, 'preserveAspectRatio="xMidYMid meet"', fixed = TRUE)

  timeline <- as.character(bones_skeleton("timeline"))
  expect_match(timeline, "bones-skeleton-timeline", fixed = TRUE)
  expect_gte(count_matches(timeline, "bones-timeline-item"), 6L)
  expect_match(timeline, "bones-axis", fixed = TRUE)

  cloud <- as.character(bones_skeleton("wordcloud"))
  expect_match(cloud, "bones-skeleton-wordcloud", fixed = TRUE)
  expect_gte(count_matches(cloud, "bones-word"), 15L)
})

test_that("the new shapes have a default height", {
  expect_equal(bones:::default_height("map"), "400px")
  expect_equal(bones:::default_height("network"), "400px")
  expect_equal(bones:::default_height("timeline"), "300px")
  expect_equal(bones:::default_height("wordcloud"), "400px")
})
