#' Wrap every Shiny output in a UI in a skeleton placeholder
#'
#' Gives skeletons to an app with no change to each output. `bones_auto()`
#' looks through a UI and puts each Shiny output in [withBones()]. Each one
#' gets the shape of its output, as with `withBones(output)`: a
#' `plotOutput()` gets a chart, a `tableOutput()` gets rows, a DT table
#' gets the shape of DT, and so on.
#'
#' Give it the whole page, or only a part of it:
#'
#' ```r
#' ui <- bones_auto(page_sidebar(...))
#' ui <- page_sidebar(sidebar = ..., bones_auto(navset_card_tab(...)))
#' ```
#'
#' # What it leaves alone
#'
#' * An output that is already in [withBones()]. To give one output its own
#'   shape or options, wrap it yourself: `bones_auto()` keeps that wrapper.
#' * An output whose id is in `exclude`.
#' * An inline output, such as `textOutput("n", inline = TRUE)`. The
#'   wrapper is a block, so it would break the line of text.
#'
#' A `uiOutput()` can hold anything, so it gets the text shape. Wrap it
#' yourself to give it another shape, such as `type = "cards"`.
#'
#' `bones_auto()` sees only the UI that you give it. Outputs that a
#' `renderUI()` makes later are not in it. Call `bones_auto()` on the UI
#' inside that `renderUI()` to give them skeletons too.
#'
#' @param ui A UI: a page, a tag, or a tag list.
#' @param ... Arguments for [withBones()], used for every output that is
#'   wrapped: for example `stale = FALSE` or `animation = "pulse"`. Not
#'   `type`, because each output gets the shape of its own kind.
#' @param exclude The ids of outputs to leave alone.
#'
#' @return `ui`, with each output in a placeholder container. A page keeps
#'   its class and its theme.
#'
#' @examples
#' if (requireNamespace("shiny", quietly = TRUE)) {
#'   library(shiny)
#'
#'   ui <- bones_auto(fluidPage(
#'     plotOutput("chart"),
#'     tableOutput("results"),
#'     textOutput("count", inline = TRUE),         # inline: left alone
#'     withBones(uiOutput("cards"), type = "cards") # wrapped already: kept
#'   ))
#' }
#' @export
bones_auto <- function(ui, ..., exclude = NULL) {
  # --- Validate inputs ---
  if (is.null(ui)) stop("`ui` must be a UI, not NULL.", call. = FALSE)
  args <- list(...)
  if (length(args) > 0L && (is.null(names(args)) || any(!nzchar(names(args))))) {
    stop("Each argument in `...` must have a name, such as `stale = FALSE`.", call. = FALSE)
  }
  if ("type" %in% names(args)) {
    stop("`type` cannot go to bones_auto(): each output gets the shape of its own kind. ",
         "Wrap one output in withBones(type = ) to give it a shape.", call. = FALSE)
  }
  if ("ui" %in% names(args)) {
    stop("`ui` must be the first argument of bones_auto(), not in `...`.", call. = FALSE)
  }
  if (!is.null(exclude) && !is.character(exclude)) {
    stop("`exclude` must be a character vector of output ids.", call. = FALSE)
  }

  # Check the arguments for withBones() once, here, so a bad one gives one
  # message and not one message for each output.
  do.call(withBones, c(list(htmltools::tags$div()), args))

  wrap_outputs(ui, args, exclude)
}


#' The classes of the containers of Shiny outputs
#'
#' Each output function of Shiny, and each htmlwidget, puts one of these on
#' its container. The table packages add their own class as well, but they
#' also have one of these.
#' @keywords internal
#' @noRd
output_classes <- function() {
  c("shiny-plot-output", "shiny-image-output", "shiny-table-output",
    "shiny-text-output", "shiny-html-output", "html-widget-output")
}


#' Is this tag the container of a Shiny output?
#' @keywords internal
#' @noRd
is_output_tag <- function(tag) {
  classes <- unlist(strsplit(attr_values(tag, "class"), "\\s+"), use.names = FALSE)
  any(output_classes() %in% classes) && length(attr_values(tag, "id")) > 0L
}


#' Wrap each output in a tag tree
#'
#' The walk changes only the children of each tag and the items of each
#' list, in place. It never makes a new object, so a page keeps its class
#' and its attributes, such as the theme of a bslib page and the HTML
#' dependencies of a tag.
#'
#' @param x A tag, a tag list, or any other child of a tag.
#' @param args Arguments for withBones().
#' @param exclude Output ids to leave alone.
#' @return `x`, with each output wrapped.
#' @keywords internal
#' @noRd
wrap_outputs <- function(x, args, exclude) {
  if (inherits(x, "shiny.tag")) {
    classes <- attr_values(x, "class")
    # A wrapper that is there already: keep it and all that is in it.
    if (any(grepl("(^|\\s)bones-wrap(\\s|$)", classes))) return(x)

    if (is_output_tag(x)) {
      id <- attr_values(x, "id")[1]
      # An inline output is a span. A block wrapper would break its line.
      if (id %in% exclude || identical(x$name, "span")) return(x)
      return(do.call(withBones, c(list(x), args)))
    }

    if (length(x$children) > 0L) x$children <- wrap_outputs(x$children, args, exclude)
    return(x)
  }

  # A tag list, or the list of children of a tag. `[<-` keeps the class and
  # the other attributes of the list.
  if (is.list(x) && !inherits(x, "html_dependency")) {
    x[] <- lapply(x, wrap_outputs, args = args, exclude = exclude)
    return(x)
  }

  x
}
