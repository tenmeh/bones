#' The classes that Shiny puts on its output containers, and the skeleton
#' shape for each one.
#'
#' The order is important. The first match wins, so the more specific
#' classes come first.
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
#' `withBones()` gets a UI element, not the type of an output, so it must
#' find the shape in the HTML. Each output function of Shiny puts a
#' `shiny-*-output` class on its container. This function collects the
#' classes, and `infer_type()` looks for that one.
#'
#' @param x A tag or a tag list. Any other value gives no classes.
#' @return A character vector of class strings, in document order.
#' @keywords internal
#' @noRd
collect_classes <- function(x) {
  if (inherits(x, "shiny.tag")) {
    return(c(
      attr_values(x, "class"),
      collect_classes(x$children)
    ))
  }
  if (inherits(x, "shiny.tag.list") || is.list(x)) {
    return(unlist(lapply(x, collect_classes), use.names = FALSE))
  }
  character(0)
}


#' Every value of one attribute of a tag
#'
#' A tag can hold the same attribute more than one time. gt_output() does
#' this: it has class "shiny-html-output" and a second class "gt_shiny".
#' `tag$attribs$class` gives only the first one.
#'
#' @param tag A tag.
#' @param name The name of the attribute.
#' @return A character vector. It is empty when the tag has no such
#'   attribute.
#' @keywords internal
#' @noRd
attr_values <- function(tag, name) {
  values <- tag$attribs[names(tag$attribs) == name]
  as.character(unlist(values, use.names = FALSE))
}


#' Get the skeleton shape from a Shiny output element
#'
#' @param tag A UI element, typically the result of `plotOutput()` and friends.
#' @return One of "plot", "table", "text", "cards", "value".
#' @keywords internal
#' @noRd
infer_type <- function(tag) {
  classes <- collect_classes(tag)
  if (length(classes) == 0L) return("text")

  # One class attribute can hold several names, with spaces between them.
  classes <- unlist(strsplit(classes, "\\s+"), use.names = FALSE)
  classes <- classes[nzchar(classes)]

  for (entry in class_map()) {
    if (entry[["class"]] %in% classes) return(entry[["type"]])
  }
  "text"
}


#' Find the id of the output in a tag tree, for the data-bones-id attribute
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


#' Find an inline CSS height in a tag tree
#'
#' `plotOutput()` sets `style="height:400px"`. The wrapper can then use that
#' height, and the skeleton has the same height as the content. If there is
#' no height, the caller can give one. If not, `withBones()` uses a default
#' for the type.
#'
#' @param tag A UI element.
#' @return A CSS length as a string, or `NA_character_`.
#' @keywords internal
#' @noRd
find_inline_height <- function(tag) {
  if (inherits(tag, "shiny.tag")) {
    style <- paste(attr_values(tag, "style"), collapse = ";")
    if (nzchar(style)) {
      # Only the "height" property. The start of a declaration comes first,
      # so "min-height", "max-height" and "line-height" do not match. When
      # there are several, the last one wins, as in CSS.
      m <- regmatches(style, gregexpr("(^|;)\\s*height\\s*:\\s*[^;]+", style))[[1]]
      if (length(m) >= 1L) {
        value <- trimws(sub("^;?\\s*height\\s*:\\s*", "", m[length(m)]))
        # A percentage height depends on the height of the parent, which
        # this package does not know. It thus does not help to find the
        # height of the skeleton.
        #
        # A value with no digit is a keyword, such as "auto" from
        # DT::DTOutput(). As a reserve, "auto" keeps no space, and the
        # skeleton is then 0px tall. A value such as "calc(100vh - 80px)"
        # has digits, so it is still used.
        if (nzchar(value) && !grepl("%$", value) && grepl("[0-9]", value)) {
          return(value)
        }
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
