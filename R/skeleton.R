#' Build a skeleton placeholder
#'
#' Produces the grey placeholder markup on its own, without wrapping an output.
#' [withBones()] calls this for you; it is exported for the cases where you want
#' a placeholder somewhere Shiny outputs don't reach — inside a `renderUI()`
#' while you fetch something, say, or to preview a shape while designing.
#'
#' @param type One of `"text"`, `"table"`, `"plot"`, `"cards"`, `"value"`.
#' @param rows Number of body rows, for `type = "table"`.
#' @param cols Number of columns, for `type = "table"`.
#' @param lines Number of lines, for `type = "text"`.
#' @param n Number of cards or values, for `type = "cards"` and `"value"`.
#' @param height A CSS height for the placeholder. Defaults to something
#'   sensible per type.
#'
#' @return An [htmltools::tag].
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
  type <- match.arg(type)

  body <- switch(
    type,
    text  = skel_text(lines),
    table = skel_table(rows, cols),
    plot  = skel_plot(),
    cards = skel_cards(n),
    value = skel_value(n)
  )

  htmltools::tags$div(
    class = paste0("bones-skeleton bones-skeleton-", type),
    # Decorative. Shiny already sets aria-busy on the output while it
    # recalculates, so screen readers are told what is happening without us
    # duplicating it here.
    `aria-hidden` = "true",
    style = if (!is.null(height)) sprintf("height: %s;", height),
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


#' Lines of text, with a short last line so it reads as a paragraph
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


#' A header row plus body rows, each split into columns
#' @keywords internal
#' @noRd
skel_table <- function(rows, cols) {
  rows <- max(as.integer(rows), 1L)
  cols <- max(as.integer(cols), 1L)

  row_of_bars <- function(class = NULL) {
    htmltools::tags$div(
      class = "bones-row",
      lapply(seq_len(cols), function(j) {
        # Vary column widths a little so it reads as data rather than a grid.
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


#' Bars of varying height sitting on an axis, so it reads as a chart
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


#' Repeated card shapes
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


#' Default height for a type when we can't read one off the output
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
    table = sprintf("%.0fpx", (as.integer(rows) + 1) * 34),
    text  = sprintf("%.0fpx", as.integer(lines) * 24),
    cards = sprintf("%.0fpx", 110),
    value = "88px",
    "120px"
  )
}
