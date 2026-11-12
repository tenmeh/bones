`%||%` <- function(x, y) if (is.null(x)) y else x

#' The names of the animations, in the order of the documentation
#' @keywords internal
#' @noRd
animation_types <- function() {
  c("wave", "pulse", "cascade", "sweep", "none")
}

#' Give NULL for NA, so that htmltools does not write the attribute
#' @keywords internal
#' @noRd
na_to_null <- function(x) {
  if (length(x) == 0L || is.na(x[1])) NULL else x[1]
}

#' Join CSS declarations for one `data-bones-style` attribute
#'
#' bones writes no `style` attribute. A strict Content-Security-Policy
#' (`style-src` with no `'unsafe-inline'`) blocks those, and the skeleton
#' would then lose its sizes. bones.js reads `data-bones-style` and sets each
#' declaration with the CSSOM, which such a policy allows.
#'
#' @param declarations A character vector, such as `"height: 10px;"`.
#' @return A string, or `NULL` when there are no declarations, so that
#'   htmltools does not write an empty attribute.
#' @keywords internal
#' @noRd
style_attr <- function(declarations) {
  if (length(declarations) == 0L) return(NULL)
  paste(declarations, collapse = " ")
}

#' Stop unless `x` is a single finite number
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
  # is.finite() is FALSE for NA and for Inf. Inf would become NA in
  # as.integer(), and then fail inside seq_len() with an unclear message.
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) {
    stop(sprintf("`%s` must be a single number.", name), call. = FALSE)
  }
  invisible(x)
}

#' Stop unless `x` is exactly one of the choices
#'
#' @param x The value to check.
#' @param choices The valid strings.
#' @param name The name of the argument, for the message.
#' @return `x`, invisibly.
#' @keywords internal
#' @noRd
check_choice <- function(x, choices, name) {
  valid <- paste(sprintf('"%s"', choices), collapse = ", ")
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be a single string, one of %s.", name, valid),
         call. = FALSE)
  }

  # Exact matching means a new shape cannot change what an old short name means.
  if (!x %in% choices) {
    msg <- sprintf('`%s` must be one of %s. You gave "%s".', name, valid, x)
    hint <- choice_hint(x, choices)
    if (!is.null(hint)) {
      msg <- paste(msg, sprintf('Did you mean "%s"?', hint))
    }
    stop(msg, call. = FALSE)
  }
  invisible(x)
}

# Share the same near-match rule for values and argument names.
choice_hint <- function(x, choices) {
  prefixes <- choices[startsWith(choices, x)]
  if (length(prefixes) == 1L) return(prefixes)

  distances <- utils::adist(x, choices, ignore.case = TRUE)
  nearest <- which.min(distances)
  if (length(nearest) == 1L && distances[nearest] <= 2L) {
    return(choices[nearest])
  }
  NULL
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

#' Stop unless `x` is a single time in milliseconds
#'
#' @param x The value to check.
#' @param name The name of the argument, for the message.
#' @return `x`, invisibly.
#' @keywords internal
#' @noRd
check_ms <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0) {
    stop(sprintf("`%s` must be a single number of milliseconds, 0 or more.", name),
         call. = FALSE)
  }
  invisible(x)
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

#' Stop unless `x` is a character vector of input ids
#'
#' @param x The value to check.
#' @param name The name of the argument, for the message.
#' @param single `TRUE` if only one id is allowed.
#' @return `x`, invisibly.
#' @keywords internal
#' @noRd
check_ids <- function(x, name, single = FALSE) {
  ok <- is.character(x) && length(x) > 0L && !anyNA(x) && all(nzchar(trimws(x)))
  if (single && !(ok && length(x) == 1L)) {
    stop(sprintf("`%s` must be a single non-empty input id or NULL.", name), call. = FALSE)
  }
  if (!ok) {
    stop(sprintf("`%s` must be a non-empty character vector of input ids or NULL.", name),
         call. = FALSE)
  }
  invisible(x)
}

#' The built-in defaults of the options that bones_defaults() sets
#'
#' The one list of these values. The signature of withBones() repeats some
#' of them so that its help page shows them; a test keeps the two the same.
#' @keywords internal
#' @noRd
builtin_defaults <- function() {
  list(animation = "wave", color = NULL, highlight = NULL, radius = NULL,
       speed = 1.4, stale = TRUE, delay = 300, min_time = 500,
       remember = TRUE, error = bones_error(), learn = TRUE)
}

#' The value of one bones option, or its built-in default
#' @keywords internal
#' @noRd
bones_option <- function(name) {
  getOption(paste0("bones.", name), builtin_defaults()[[name]])
}

#' Stop unless `x` is FALSE, a tag, or a tag list
#'
#' @param x The value to check.
#' @return `x`, invisibly.
#' @keywords internal
#' @noRd
check_error <- function(x) {
  if (!identical(x, FALSE) &&
        !inherits(x, c("shiny.tag", "shiny.tag.list"))) {
    stop("`error` must be FALSE, a tag, or a tag list.", call. = FALSE)
  }
  invisible(x)
}
