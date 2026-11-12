#' List the valid skeleton shapes
#'
#' Returns all shapes, or the shapes in one group:
#'
#' * Basic: `r shapes_md("basic")`.
#' * Chart: `r shapes_md("chart")`.
#' * Table: `r shapes_md("table")`.
#'
#' The chart group includes `"plot"`, which uses the bar shape.
#' The table group includes `"table"` and the table package shapes.
#'
#' @param group A group: `"basic"`, `"chart"` or `"table"`.
#'   `NULL` (the default) returns all shapes.
#' @return A character vector in the same order as the full list of shapes.
#' @seealso [bones_skeleton()], [withBones()]
#' @examples
#' bones_shapes()
#' bones_shapes("chart")
#' @export
bones_shapes <- function(group = NULL) {
  types <- skeleton_types()
  if (is.null(group)) return(types)
  check_choice(group, c("basic", "chart", "table"), "group")

  # Filter the full list to keep its order within each group.
  selected <- switch(group,
    basic = c("text", "cards", "value"),
    chart = c("plot", chart_types()),
    table = c("table", table_types())
  )
  types[types %in% selected]
}

# The shapes as Markdown code, for the help pages: `"text"`, `"table"`, ...
# roxygen runs it inline, so the lists in the docs cannot drift from the code.
shapes_md <- function(group = NULL) {
  paste0("`\"", bones_shapes(group), "\"`", collapse = ", ")
}
