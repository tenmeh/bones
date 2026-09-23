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
#' @param type The shape: `"text"`, `"table"`, `"plot"`, `"cards"` or
#'   `"value"`.
#' @param rows The number of body rows, for `type = "table"`.
#' @param cols The number of columns, for `type = "table"`.
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
#' @export
bones_skeleton <- function(type = c("text", "table", "plot", "cards", "value"),
                           rows = 6L,
                           cols = 4L,
                           lines = 3L,
                           n = 3L,
                           height = NULL) {
  # --- Validate inputs ---
  type <- match.arg(type)
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
    text  = skel_text(lines),
    table = skel_table(rows, cols),
    plot  = skel_plot(),
    cards = skel_cards(n),
    value = skel_value(n)
  )

  htmltools::tags$div(
    class = paste(c("bones-skeleton", paste0("bones-skeleton-", type), class),
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
  rows <- max(as.integer(rows), 1L)
  cols <- max(as.integer(cols), 1L)

  row_of_bars <- function(class = NULL) {
    htmltools::tags$div(
      class = "bones-row",
      lapply(seq_len(cols), function(j) {
        # Columns of slightly different widths look like data, not a grid.
        w <- c("100%", "80%", "92%", "70%")[((j - 1L) %% 4L) + 1L]
        bar(width = w, class = class)
      })
    )
  }

  htmltools::tagList(
    row_of_bars(class = "bones-bar-strong"),
    lapply(seq_len(rows), function(i) row_of_bars())
  )
}


#' Columns of different heights on an axis, so the shape looks like a chart
#' @keywords internal
#' @noRd
skel_plot <- function() {
  heights <- c(45, 72, 58, 88, 64, 40, 76, 52)
  htmltools::tagList(
    htmltools::tags$div(
      class = "bones-plot-area",
      lapply(heights, function(h) {
        htmltools::tags$div(
          class = "bones-bar bones-bar-column",
          style = sprintf("height: %d%%;", h)
        )
      })
    ),
    htmltools::tags$div(class = "bones-axis")
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
