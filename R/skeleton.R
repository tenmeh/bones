#' Make a skeleton placeholder
#'
#' Makes the grey placeholder on its own, with no output in it. You do not
#' need this for a Shiny output, because [withBones()] makes the
#' placeholder for you. Use this function where there is no Shiny output:
#' for example, inside a `renderUI()` while you get data, or to look at a
#' shape while you design a page.
#'
#' The skeleton uses the animation and the colours from [bones_defaults()].
#'
#' # Chart shapes
#'
#' A chart has a shape for each common kind: `"bar"`, `"line"`,
#' `"scatter"`, `"area"`, `"histogram"`, `"pie"`, `"heatmap"`, `"map"`,
#' `"network"`, `"timeline"` and `"wordcloud"`. `"plot"` is the same as
#' `"bar"`. [withBones()] finds the shape of a map, network, timeline or
#' word cloud widget from its output. `plotOutput()` cannot say which kind it will
#' hold, because `renderPlot()` decides that later, on the server. So you
#' name the kind yourself.
#'
#' # Table shapes
#'
#' A table from a table package has a shape that copies that package:
#' `"dt"`, `"reactable"`, `"gt"` and `"rhandsontable"`. [withBones()] finds
#' it from the output by itself.
#'
#' @param type The shape: `"text"`, `"table"`, `"plot"`, `"cards"`,
#'   `"value"`, or one of the chart or table shapes above.
#' @param rows The number of body rows, for `type = "table"` and the table
#'   package shapes.
#' @param cols The number of columns, for `type = "table"` and the table
#'   package shapes.
#' @param lines The number of lines, for `type = "text"`.
#' @param n The number of cards or values, for `type = "cards"` and
#'   `"value"`.
#' @param height A CSS height for the placeholder, or a number of pixels.
#'   `NULL` gives a default for the type, the same one that [withBones()]
#'   uses.
#'
#' @return An [htmltools::tag], with the stylesheet attached.
#'
#' @examples
#' bones_skeleton("text", lines = 4)
#' bones_skeleton("table", rows = 8, cols = 5)
#' bones_skeleton("plot", height = "300px")
#' bones_skeleton("scatter", height = "300px")
#' bones_skeleton("dt", rows = 10, cols = 5)
#' @export
bones_skeleton <- function(type = "text",
                           rows = 6L,
                           cols = 4L,
                           lines = 3L,
                           n = 3L,
                           height = NULL) {
  # --- Validate inputs ---
  type <- match.arg(type, skeleton_types())
  check_count(rows, "rows")
  check_count(cols, "cols")
  check_count(lines, "lines")
  check_count(n, "n")
  height <- as_css_length(height, "height")

  # On its own, a skeleton takes space like any other element, so it needs
  # a height. The plot shape sets the height of its columns as a percentage
  # of this height.
  height <- height %||% default_height(type, rows = rows, lines = lines, n = n)

  # With no wrapper, the skeleton itself must carry what a wrapper carries:
  # the animation class and the colours from bones_defaults().
  animation <- match.arg(getOption("bones.animation", "wave"),
                         c("wave", "pulse", "none"))

  htmltools::attachDependencies(
    skeleton_tag(type, rows = rows, cols = cols, lines = lines, n = n,
                 height = height,
                 class = paste0("bones-anim-", animation),
                 style = css_vars()),
    bones_dependency()
  )
}


#' The skeleton markup, with no validation and no dependency
#'
#' withBones() uses this directly. Inside a wrapper, the skeleton fills the
#' wrapper, so it gets no height of its own.
#'
#' @inheritParams bones_skeleton
#' @param class More classes for the skeleton element.
#' @param style More CSS declarations for the skeleton element.
#' @return An htmltools tag.
#' @keywords internal
#' @noRd
skeleton_tag <- function(type, rows, cols, lines, n, height = NULL,
                         class = NULL, style = character(0)) {
  body <- switch(
    type,
    text      = skel_text(lines),
    table     = skel_table(rows, cols),
    dt            = skel_dt(rows, cols),
    reactable     = skel_reactable(rows, cols),
    gt            = skel_gt(rows, cols),
    rhandsontable = skel_rhandsontable(rows, cols),
    plot      = skel_bar(),
    bar       = skel_bar(),
    histogram = skel_histogram(),
    line      = skel_line(),
    area      = skel_area(),
    scatter   = skel_scatter(),
    pie       = skel_pie(),
    heatmap   = skel_heatmap(),
    map       = skel_map(),
    network   = skel_network(),
    timeline  = skel_timeline(),
    wordcloud = skel_wordcloud(),
    cards     = skel_cards(n),
    value     = skel_value(n)
  )

  # All the chart shapes share the layout of a chart: the marks fill the
  # height, and an axis is at the bottom.
  chart_class <- if (type %in% c("plot", chart_types())) "bones-skeleton-chart"

  htmltools::tags$div(
    class = paste(c("bones-skeleton", paste0("bones-skeleton-", type), chart_class, class),
                  collapse = " "),
    # Only for the eye. Shiny sets aria-busy on the output while it
    # calculates, so a screen reader already tells the user. A second
    # message from the placeholder would only repeat it.
    `aria-hidden` = "true",
    style = style_attr(c(
      if (!is.null(height)) sprintf("height: %s;", height),
      style
    )),
    body
  )
}


# --- shapes ---------------------------------------------------------------

#' A single grey bar
#' @keywords internal
#' @noRd
bar <- function(width = "100%", height = NULL, class = NULL) {
  styles <- c(
    sprintf("width: %s;", width),
    if (!is.null(height)) sprintf("height: %s;", height)
  )
  htmltools::tags$div(
    class = paste(c("bones-bar", class), collapse = " "),
    style = paste(styles, collapse = " ")
  )
}


#' Lines of text. The last line is short, so the lines look like a paragraph.
#' @keywords internal
#' @noRd
skel_text <- function(lines) {
  lines <- max(as.integer(lines), 1L)
  widths <- c("100%", "94%", "98%", "91%")
  htmltools::tagList(
    lapply(seq_len(lines), function(i) {
      w <- if (i == lines && lines > 1L) "62%" else widths[((i - 1L) %% 4L) + 1L]
      bar(width = w)
    })
  )
}


#' A header row and body rows, each divided into columns
#' @keywords internal
#' @noRd
skel_table <- function(rows, cols) {
  table_rows(rows, cols)
}

#' A header row and body rows of bars
#'
#' The plain table, DT and reactable use this. `row_class` adds classes to
#' each row, so each package can style its rows.
#' @keywords internal
#' @noRd
table_rows <- function(rows, cols, row_class = NULL, head_class = NULL) {
  rows <- max(as.integer(rows), 1L)
  cols <- max(as.integer(cols), 1L)

  row_of_bars <- function(bar_class = NULL, extra = NULL) {
    htmltools::tags$div(
      class = paste(c("bones-row", row_class, extra), collapse = " "),
      lapply(seq_len(cols), function(j) {
        # Columns of slightly different widths look like data, not a grid.
        w <- c("100%", "80%", "92%", "70%")[((j - 1L) %% 4L) + 1L]
        bar(width = w, class = bar_class)
      })
    )
  }

  htmltools::tagList(
    row_of_bars(bar_class = "bones-bar-strong", extra = head_class),
    lapply(seq_len(rows), function(i) row_of_bars())
  )
}


# --- table package shapes -------------------------------------------------
#
# Each shape copies the parts of its package that a user sees first: the
# controls of DT, the thin lines of reactable, the title of gt, and the grid
# of rhandsontable. The table itself follows `rows` and `cols`.

#' DT: "Show entries" and a search box above, the info and the pages below
#' @keywords internal
#' @noRd
skel_dt <- function(rows, cols) {
  htmltools::tags$div(
    class = "bones-dt",
    htmltools::tags$div(
      class = "bones-dt-top",
      htmltools::tags$div(
        class = "bones-dt-length",
        bar(width = "2.5rem"),
        htmltools::tags$div(class = "bones-bar bones-dt-select"),
        bar(width = "3rem")
      ),
      htmltools::tags$div(
        class = "bones-dt-search",
        bar(width = "3rem"),
        htmltools::tags$div(class = "bones-dt-input")
      )
    ),
    htmltools::tags$div(
      class = "bones-dt-table",
      table_rows(rows, cols, row_class = "bones-dt-row", head_class = "bones-dt-head")
    ),
    htmltools::tags$div(
      class = "bones-dt-bottom",
      bar(width = "30%"),
      htmltools::tags$div(
        class = "bones-dt-pages",
        lapply(1:4, function(i) htmltools::tags$div(class = "bones-bar bones-dt-page"))
      )
    )
  )
}

#' reactable: rows with thin lines, and pages when there are more than ten
#' @keywords internal
#' @noRd
skel_reactable <- function(rows, cols) {
  rows <- max(as.integer(rows), 1L)
  htmltools::tags$div(
    class = "bones-rt",
    table_rows(rows, cols, row_class = "bones-rt-row", head_class = "bones-rt-head"),
    # reactable shows 10 rows on a page by default, and pages only for more.
    if (rows > 10L) {
      htmltools::tags$div(
        class = "bones-rt-pages",
        bar(width = "6rem"),
        htmltools::tags$div(class = "bones-bar bones-rt-button"),
        htmltools::tags$div(class = "bones-bar bones-rt-button")
      )
    }
  )
}

#' gt: a title, a spanner, a stub column, and a source note
#' @keywords internal
#' @noRd
skel_gt <- function(rows, cols) {
  rows <- max(as.integer(rows), 1L)
  cols <- max(as.integer(cols), 1L)

  gt_row <- function(stub_width, cell_class = NULL, row_class = NULL) {
    htmltools::tags$div(
      class = paste(c("bones-gt-row", row_class), collapse = " "),
      htmltools::tags$div(class = "bones-gt-stub", bar(width = stub_width, class = cell_class)),
      lapply(seq_len(cols), function(j) {
        # The numbers of a gt table are on the right of each cell.
        htmltools::tags$div(class = "bones-gt-cell", bar(width = "55%", class = cell_class))
      })
    )
  }
  stub_widths <- c("70%", "55%", "80%", "62%", "48%", "75%")

  htmltools::tags$div(
    class = "bones-gt",
    htmltools::tags$div(
      class = "bones-gt-title",
      bar(width = "45%", class = "bones-bar-strong"),
      bar(width = "28%")
    ),
    htmltools::tags$div(
      class = "bones-gt-spanner-row",
      htmltools::tags$div(class = "bones-gt-corner"),
      htmltools::tags$div(
        class = "bones-gt-spanner",
        # The spanner covers all the data columns, which a static rule cannot
        # know, so the width is set here.
        style = sprintf("flex: %d 1 0;", cols),
        bar(width = "40%", class = "bones-bar-strong")
      )
    ),
    gt_row("50%", cell_class = "bones-bar-strong", row_class = "bones-gt-labels"),
    lapply(seq_len(rows), function(i) gt_row(stub_widths[((i - 1L) %% 6L) + 1L])),
    htmltools::tags$div(class = "bones-gt-note", bar(width = "35%"))
  )
}

#' rhandsontable: a spreadsheet grid, with lettered columns and numbered rows
#' @keywords internal
#' @noRd
skel_rhandsontable <- function(rows, cols) {
  rows <- max(as.integer(rows), 1L)
  cols <- max(as.integer(cols), 1L)
  widths <- c("75%", "50%", "85%", "60%")

  htmltools::tags$div(
    class = "bones-hot",
    style = sprintf("grid-template-columns: 2.5rem repeat(%d, 1fr);", cols),
    htmltools::tags$div(class = "bones-hot-corner"),
    lapply(seq_len(cols), function(j) {
      htmltools::tags$div(class = "bones-hot-colhead", bar(width = "1rem"))
    }),
    lapply(seq_len(rows), function(i) {
      htmltools::tagList(
        htmltools::tags$div(class = "bones-hot-rowhead", bar(width = "0.8rem")),
        lapply(seq_len(cols), function(j) {
          htmltools::tags$div(
            class = "bones-hot-cell",
            bar(width = widths[((i + j) %% 4L) + 1L])
          )
        })
      )
    })
  )
}


# --- chart shapes ---------------------------------------------------------
#
# Each chart shape is a plot area and an axis under it. The marks use
# percentages of the plot area, so a shape fits any height. The positions are
# fixed numbers, not random ones, so a skeleton looks the same each time.

#' The names of the chart shapes, other than "plot"
#' @keywords internal
#' @noRd
chart_types <- function() {
  c("bar", "line", "scatter", "area", "histogram", "pie", "heatmap",
    "map", "network", "timeline", "wordcloud")
}

#' The names of the table shapes for table packages, other than "table"
#' @keywords internal
#' @noRd
table_types <- function() {
  c("dt", "reactable", "gt", "rhandsontable")
}

#' The names of all the skeleton shapes, in the order of the documentation
#' @keywords internal
#' @noRd
skeleton_types <- function() {
  c("text", "table", "plot", "cards", "value", chart_types(), table_types())
}

#' A plot area with the given marks in it, and an axis under it
#' @keywords internal
#' @noRd
chart_frame <- function(..., class = NULL) {
  htmltools::tagList(
    htmltools::tags$div(
      class = paste(c("bones-plot-area", class), collapse = " "),
      ...
    ),
    htmltools::tags$div(class = "bones-axis")
  )
}

#' Columns of the given heights, in percent
#' @keywords internal
#' @noRd
columns <- function(heights) {
  lapply(heights, function(h) {
    htmltools::tags$div(
      class = "bones-bar bones-bar-column",
      style = sprintf("height: %d%%;", h)
    )
  })
}

#' Columns of different heights on an axis, so the shape looks like a chart
#' @keywords internal
#' @noRd
skel_bar <- function() {
  chart_frame(columns(c(45, 72, 58, 88, 64, 40, 76, 52)))
}

#' More columns, with no space between them, in the shape of a distribution
#' @keywords internal
#' @noRd
skel_histogram <- function() {
  chart_frame(
    columns(c(10, 22, 38, 56, 74, 88, 82, 64, 46, 30, 18, 8)),
    class = "bones-plot-area-tight"
  )
}

#' An SVG that fills the plot area
#'
#' The view box is 100 by 100 and does not keep its aspect ratio, so the
#' coordinates are percentages of the plot area. `y` counts up from the
#' axis, as in a chart.
#' @keywords internal
#' @noRd
chart_svg <- function(...) {
  htmltools::tags$svg(
    class = "bones-svg",
    xmlns = "http://www.w3.org/2000/svg",
    viewBox = "0 0 100 100",
    preserveAspectRatio = "none",
    focusable = "false",
    ...
  )
}

#' SVG points text from values that count up from the axis
#' @keywords internal
#' @noRd
svg_points <- function(y) {
  x <- seq(0, 100, length.out = length(y))
  paste(sprintf("%g,%g", round(x, 2), 100 - y), collapse = " ")
}

# The values of the line and the area: a trend upwards, with some noise.
line_values <- function() c(30, 42, 36, 52, 47, 60, 55, 70, 64, 78)

#' A line across the plot area
#' @keywords internal
#' @noRd
skel_line <- function() {
  chart_frame(chart_svg(
    htmltools::tags$polyline(class = "bones-svg-line", points = svg_points(line_values()))
  ))
}

#' A filled area under a line
#' @keywords internal
#' @noRd
skel_area <- function() {
  y <- line_values()
  chart_frame(chart_svg(
    htmltools::tags$polygon(
      class = "bones-svg-fill",
      points = paste(svg_points(y), "100,100 0,100")
    ),
    htmltools::tags$polyline(class = "bones-svg-line", points = svg_points(y))
  ))
}

#' Dots in a cloud that rises from left to right
#' @keywords internal
#' @noRd
skel_scatter <- function() {
  x <- c(5, 9, 14, 18, 22, 27, 31, 35, 40, 44, 49, 53, 58, 62, 67, 71, 76, 80, 85, 90, 94)
  noise <- c(4, -6, 9, -3, 7, -9, 2, 10, -5, 6, -8, 3, 11, -4, 5, -10, 8, -2, 6, -7, 3)
  y <- pmin(pmax(18 + 0.62 * x + noise, 4), 94)
  chart_frame(
    lapply(seq_along(x), function(i) {
      htmltools::tags$div(
        class = "bones-bar bones-dot",
        style = sprintf("left: %g%%; bottom: %g%%;", x[i], round(y[i], 1))
      )
    }),
    class = "bones-plot-area-free"
  )
}

#' A disc and a legend of four keys
#' @keywords internal
#' @noRd
skel_pie <- function() {
  htmltools::tags$div(
    class = "bones-pie",
    htmltools::tags$div(class = "bones-bar bones-pie-disc"),
    htmltools::tags$div(
      class = "bones-pie-legend",
      lapply(c("70%", "55%", "80%", "45%"), function(w) {
        htmltools::tags$div(
          class = "bones-pie-key",
          htmltools::tags$div(class = "bones-bar bones-pie-swatch"),
          bar(width = w)
        )
      })
    )
  )
}

#' A grid of cells, each of a different strength
#'
#' The strength changes smoothly across the grid, as in a real heatmap, and
#' not at random.
#' @keywords internal
#' @noRd
skel_heatmap <- function(n_rows = 6L, n_cols = 10L) {
  cells <- expand.grid(col = seq_len(n_cols), row = seq_len(n_rows))
  strength <- (sin(cells$col * 0.8) + cos(cells$row * 1.1) + 2) / 4
  htmltools::tags$div(
    class = "bones-heatmap",
    style = sprintf("grid-template-columns: repeat(%d, 1fr);", n_cols),
    lapply(strength, function(s) {
      htmltools::tags$div(
        class = "bones-bar bones-heat-cell",
        style = sprintf("opacity: %.2f;", 0.25 + 0.75 * s)
      )
    })
  )
}


#' A map: tiles, a coast, roads, three pins and the zoom buttons
#'
#' The tiles are a grid in the stylesheet. The coast and the roads are an
#' SVG that fills the map, so they stretch with it. The pins and the zoom
#' buttons are bars, so they have the wave animation.
#' @keywords internal
#' @noRd
skel_map <- function() {
  roads <- c(
    "0,30 22,34 45,28 70,40 100,36",
    "52,0 55,22 58,48 66,72 70,100",
    "20,100 34,76 58,48 88,64 100,70"
  )
  pins <- list(c(28, 36), c(61, 54), c(78, 24))   # left and top, in percent
  htmltools::tags$div(
    class = "bones-map",
    chart_svg(
      htmltools::tags$polygon(
        class = "bones-svg-fill",
        points = "0,62 14,58 26,66 38,72 44,84 40,100 0,100"
      ),
      lapply(roads, function(p) htmltools::tags$polyline(class = "bones-svg-road", points = p))
    ),
    htmltools::tags$div(
      class = "bones-map-zoom",
      htmltools::tags$div(class = "bones-bar bones-map-zoom-button"),
      htmltools::tags$div(class = "bones-bar bones-map-zoom-button")
    ),
    lapply(pins, function(p) {
      htmltools::tags$div(
        class = "bones-bar bones-pin",
        style = sprintf("left: %g%%; top: %g%%;", p[1], p[2])
      )
    })
  )
}

#' A network: nodes of different sizes, joined by edges
#'
#' This SVG keeps its aspect ratio, unlike the line and the area, so the
#' nodes stay round. The network is centred in the space.
#' @keywords internal
#' @noRd
skel_network <- function() {
  nodes <- data.frame(
    x = c(14, 32, 34, 52, 70, 72, 88, 52, 20, 90),
    y = c(30, 14, 44, 28, 12, 46, 26, 54, 52, 50),
    r = c(4, 3, 3.5, 5, 3, 3.5, 4, 2.8, 2.8, 2.6)
  )
  edges <- list(c(1, 2), c(1, 3), c(1, 4), c(2, 4), c(3, 4), c(4, 5), c(4, 6),
                c(5, 7), c(6, 7), c(6, 8), c(3, 9), c(7, 10), c(6, 10))
  htmltools::tags$div(
    class = "bones-network",
    htmltools::tags$svg(
      class = "bones-svg",
      xmlns = "http://www.w3.org/2000/svg",
      viewBox = "0 0 100 60",
      preserveAspectRatio = "xMidYMid meet",
      focusable = "false",
      # The edges first, so the nodes are drawn on top of them.
      lapply(edges, function(e) {
        htmltools::tags$line(
          class = "bones-svg-edge",
          x1 = nodes$x[e[1]], y1 = nodes$y[e[1]], x2 = nodes$x[e[2]], y2 = nodes$y[e[2]]
        )
      }),
      lapply(seq_len(nrow(nodes)), function(i) {
        htmltools::tags$circle(class = "bones-svg-node", cx = nodes$x[i], cy = nodes$y[i], r = nodes$r[i])
      })
    )
  )
}

#' A timeline: items on four rows, over an axis with tick labels
#' @keywords internal
#' @noRd
skel_timeline <- function() {
  # row, left and width, in percent
  items <- list(c(1, 4, 22), c(1, 38, 30), c(2, 14, 26), c(2, 52, 18),
                c(3, 6, 16), c(3, 30, 34), c(4, 10, 20), c(4, 46, 40))
  htmltools::tagList(
    htmltools::tags$div(
      class = "bones-timeline",
      lapply(items, function(it) {
        htmltools::tags$div(
          class = "bones-bar bones-timeline-item",
          style = sprintf("left: %g%%; top: %g%%; width: %g%%;", it[2], 6 + (it[1] - 1) * 24, it[3])
        )
      })
    ),
    htmltools::tags$div(class = "bones-axis"),
    htmltools::tags$div(
      class = "bones-timeline-ticks",
      lapply(1:6, function(i) bar(width = "2.5rem"))
    )
  )
}

#' A word cloud: words of different sizes, around the centre
#' @keywords internal
#' @noRd
skel_wordcloud <- function() {
  # width and height of each word, in rem. The big words are strong.
  words <- list(
    c(4, 0.9), c(6, 1.3), c(3, 0.7), c(5, 1.1), c(9, 2.2), c(3.5, 0.8),
    c(4.5, 1.0), c(7, 1.6), c(2.8, 0.7), c(5.5, 1.2), c(3.2, 0.8), c(8, 1.9),
    c(4, 0.9), c(2.5, 0.6), c(6, 1.4), c(3.6, 0.8), c(5, 1.1), c(3, 0.7)
  )
  htmltools::tags$div(
    class = "bones-wordcloud",
    lapply(words, function(w) {
      htmltools::tags$div(
        class = paste(c("bones-bar", "bones-word", if (w[2] >= 1.6) "bones-bar-strong"), collapse = " "),
        style = sprintf("width: %grem; height: %grem;", w[1], w[2])
      )
    })
  )
}

#' Card shapes, side by side
#' @keywords internal
#' @noRd
skel_cards <- function(n) {
  n <- max(as.integer(n), 1L)
  htmltools::tags$div(
    class = "bones-cards",
    lapply(seq_len(n), function(i) {
      htmltools::tags$div(
        class = "bones-card",
        bar(width = "55%", class = "bones-bar-strong"),
        bar(width = "100%"),
        bar(width = "78%")
      )
    })
  )
}


#' A label above a large number, as in a value box
#' @keywords internal
#' @noRd
skel_value <- function(n) {
  n <- max(as.integer(n), 1L)
  htmltools::tags$div(
    class = "bones-values",
    lapply(seq_len(n), function(i) {
      htmltools::tags$div(
        class = "bones-value",
        bar(width = "48%", height = "0.6rem"),
        bar(width = "72%", height = "1.6rem", class = "bones-bar-strong")
      )
    })
  )
}


#' The default height for a type, when the output does not set one
#'
#' Counts below one become one, as in the shape functions. The height thus
#' fits the shape that is drawn, and is never negative.
#' @keywords internal
#' @noRd
default_height <- function(type, rows = 6L, lines = 3L, n = 3L) {
  switch(
    type,
    plot  = "400px",
    # The same height as plotOutput(), for each chart shape.
    bar = , line = , scatter = , area = , histogram = , pie = , heatmap = "400px",
    # A map, a network and a word cloud are as tall as leafletOutput() and
    # most other widget outputs. A timeline has a few rows, so it is lower.
    map = , network = , wordcloud = "400px",
    timeline = "300px",
    # The table packages, measured in a browser with Bootstrap 5, which is
    # the larger of Bootstrap 3 and 5. A reserve that is too tall closes
    # when the content arrives; one that is too short pushes the page down.
    #   DT: 53px of controls above, 40px rows with the header, 63px below.
    dt = sprintf("%.0fpx", 53 + (max(as.integer(rows), 1L) + 1) * 40 + 63),
    #   reactable: 38px rows with the header, and a small margin.
    reactable = sprintf("%.0fpx", (max(as.integer(rows), 1L) + 1) * 38 + 8),
    #   gt, with a title, a spanner and a source note: 180px, and 38.5px
    #   for each row. With no spanner it is 33px shorter, and the reserve
    #   closes by that much.
    gt = sprintf("%.0fpx", 180 + max(as.integer(rows), 1L) * 38.5),
    #   rhandsontable: a 26px header, 24px rows, and a small margin.
    rhandsontable = sprintf("%.0fpx", 32 + max(as.integer(rows), 1L) * 24),
    # A header row plus the body rows. A row of tableOutput() is 34px tall
    # with Bootstrap 5 (bslib) and 31px with Bootstrap 3 (fluidPage). Use
    # the larger value: the reserve goes when the content arrives, so a
    # reserve that is too tall closes, but one that is too short pushes the
    # page down.
    table = sprintf("%.0fpx", (max(as.integer(rows), 1L) + 1) * 34),
    text  = sprintf("%.0fpx", max(as.integer(lines), 1L) * 24),
    cards = sprintf("%.0fpx", 110),
    value = "88px",
    "120px"
  )
}
