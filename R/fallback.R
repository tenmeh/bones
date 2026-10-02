#' A calm panel for a failed output
#'
#' Shows a short message when a wrapped output fails. On the first load,
#' the panel fills the space of the output. After a good load, it becomes
#' a banner above the old content. Messages from `validate()` pass through.
#' Messages from `shiny::safeError()` show in the panel even when `detail`
#' is `FALSE`, including when `shiny.sanitize.errors = TRUE`.
#'
#' @param message A single string. `NULL` uses "This content could not be
#'   loaded.".
#' @param detail Show the error message below the main message. The default
#'   is `FALSE`. Use `TRUE` only for development: when
#'   `shiny.sanitize.errors = FALSE`, raw errors can contain file paths,
#'   SQL, or private data.
#'
#' @return An [htmltools::tag] with `role="alert"`.
#'
#' @examples
#' bones_fallback()
#' bones_fallback("The chart could not be loaded.")
#' @export
bones_fallback <- function(message = NULL, detail = FALSE) {
  check_flag(detail, "detail")
  message <- message %||% "This content could not be loaded."
  if (!is.character(message) || length(message) != 1L || is.na(message)) {
    stop("`message` must be a single string.", call. = FALSE)
  }

  htmltools::tags$div(
    class = "bones-error",
    role = "alert",
    htmltools::tags$div(class = "bones-error-message", message),
    htmltools::tags$div(class = "bones-error-safe"),
    if (detail) htmltools::tags$div(class = "bones-error-detail")
  )
}


#' Check whether a tag is already an error panel
#'
#' @param x A tag or a tag list.
#' @return TRUE if `x` is a tag with the class `bones-error`, otherwise FALSE.
#' @keywords internal
#' @noRd
is_error_panel <- function(x) {
  if (!inherits(x, "shiny.tag")) return(FALSE)
  classes <- strsplit(x$attribs$class %||% "", "\\s+")[[1]]
  "bones-error" %in% classes
}
