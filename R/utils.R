`%||%` <- function(x, y) if (is.null(x)) y else x

#' Drop NA so htmltools omits the attribute entirely
#' @keywords internal
#' @noRd
na_to_null <- function(x) {
  if (length(x) == 0L || is.na(x[1])) NULL else x[1]
}

#' Join CSS declarations into one style attribute
#'
#' @param declarations A character vector, such as `"height: 10px;"`.
#' @return A string, or `NULL` when there are no declarations, so that
#'   htmltools does not write an empty `style` attribute.
#' @keywords internal
#' @noRd
style_attr <- function(declarations) {
  if (length(declarations) == 0L) return(NULL)
  paste(declarations, collapse = " ")
}

#' Stop unless `x` is a single number that is not NA
#'
#' Counts below one are not an error. The shape functions make them one, so
#' a count that comes from data with no rows still gives a placeholder.
#'
#' @param x The value to check.
#' @param name The name of the argument, for the message.
#' @return `x`, invisibly.
#' @keywords internal
#' @noRd
check_count <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be a single number.", name), call. = FALSE)
  }
  invisible(x)
}

#' Make `x` a CSS length, or stop
#'
#' Uses htmltools::validateCssUnit(), so a height works as it does in
#' Shiny: `300` becomes `"300px"`, and a string such as `"banana"` is an
#' error. That function lets NA through, so this one stops it first.
#'
#' @param x `NULL`, a number of pixels, or a CSS length as a string.
#' @param name The name of the argument, for the message.
#' @return `NULL`, or a CSS length as a string.
#' @keywords internal
#' @noRd
as_css_length <- function(x, name) {
  if (is.null(x)) return(NULL)
  if (length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be a single CSS length, such as \"300px\".", name),
         call. = FALSE)
  }
  htmltools::validateCssUnit(x)
}

#' Stop unless `x` is TRUE or FALSE
#'
#' @param x The value to check.
#' @param name The name of the argument, for the message.
#' @return `x`, invisibly.
#' @keywords internal
#' @noRd
check_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be TRUE or FALSE.", name), call. = FALSE)
  }
  invisible(x)
}
