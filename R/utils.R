`%||%` <- function(x, y) if (is.null(x)) y else x

#' Drop NA so htmltools omits the attribute entirely
#' @keywords internal
#' @noRd
na_to_null <- function(x) {
  if (length(x) == 0L || is.na(x[1])) NULL else x[1]
}
