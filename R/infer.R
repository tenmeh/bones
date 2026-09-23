#' Classes Shiny puts on its output containers, mapped to a skeleton shape.
#'
#' Order matters: the first match wins, so more specific classes come first.
#' @keywords internal
#' @noRd
class_map <- function() {
  list(
    c(class = "shiny-plot-output",    type = "plot"),
    c(class = "shiny-image-output",   type = "plot"),
    c(class = "shiny-table-output",   type = "table"),
    c(class = "datatables",           type = "table"),
    c(class = "reactable",            type = "table"),
    c(class = "shiny-text-output",    type = "text"),
    c(class = "html-widget-output",   type = "plot"),
    c(class = "shiny-html-output",    type = "text")
  )
}


#' Collect every class attribute in a tag tree
#'
#' `withBones()` is handed a UI element, not an output type, so the shape has to
#' be read back off the HTML. Shiny's output functions all stamp a
#' `shiny-*-output` class onto their container, which is what we look for.
#'
#' @param x A tag, tag list, or anything else (ignored).
#' @return A character vector of class strings, in document order.
#' @keywords internal
#' @noRd
collect_classes <- function(x) {
  if (inherits(x, "shiny.tag")) {
    return(c(
      as.character(x$attribs$class %||% character(0)),
      collect_classes(x$children)
    ))
  }
  if (inherits(x, "shiny.tag.list") || is.list(x)) {
    return(unlist(lapply(x, collect_classes), use.names = FALSE))
  }
  character(0)
}


#' Infer a skeleton shape from a Shiny output element
#'
#' @param tag A UI element, typically the result of `plotOutput()` and friends.
#' @return One of "plot", "table", "text", "cards", "value".
#' @keywords internal
#' @noRd
infer_type <- function(tag) {
  classes <- collect_classes(tag)
  if (length(classes) == 0L) return("text")

  # Class attributes can hold several space-separated names.
  classes <- unlist(strsplit(classes, "\\s+"), use.names = FALSE)
  classes <- classes[nzchar(classes)]

  for (entry in class_map()) {
    if (entry[["class"]] %in% classes) return(entry[["type"]])
  }
  "text"
}


#' Pull the output id out of a tag tree, for diagnostics and data attributes
#'
#' @param tag A UI element.
#' @return A single string, or `NA_character_` when no id is present.
#' @keywords internal
#' @noRd
find_output_id <- function(tag) {
  if (inherits(tag, "shiny.tag")) {
    id <- tag$attribs$id
    if (!is.null(id) && nzchar(as.character(id)[1])) return(as.character(id)[1])
    return(find_output_id(tag$children))
  }
  if (inherits(tag, "shiny.tag.list") || is.list(tag)) {
    for (child in tag) {
      id <- find_output_id(child)
      if (!is.na(id)) return(id)
    }
  }
  NA_character_
}


#' Read an inline CSS height off a tag tree
#'
#' `plotOutput()` sets `style="height:400px"`. When it does, the wrapper can
#' inherit that height and the skeleton will match the eventual content exactly.
#' When it doesn't, the caller has to tell us or we fall back to a per-type
#' default.
#'
#' @param tag A UI element.
#' @return A CSS length as a string, or `NA_character_`.
#' @keywords internal
#' @noRd
find_inline_height <- function(tag) {
  if (inherits(tag, "shiny.tag")) {
    style <- tag$attribs$style
    if (!is.null(style)) {
      m <- regmatches(
        as.character(style)[1],
        regexpr("height\\s*:\\s*[^;]+", as.character(style)[1])
      )
      if (length(m) == 1L) {
        value <- trimws(sub("^height\\s*:\\s*", "", m))
        # A percentage height is relative to a parent we do not control, so it
        # tells us nothing useful about how tall the skeleton should be.
        if (nzchar(value) && !grepl("%$", value)) return(value)
      }
    }
    return(find_inline_height(tag$children))
  }
  if (inherits(tag, "shiny.tag.list") || is.list(tag)) {
    for (child in tag) {
      h <- find_inline_height(child)
      if (!is.na(h)) return(h)
    }
  }
  NA_character_
}
