#' Wrap a Shiny output in a skeleton placeholder
#'
#' Shows a grey placeholder in the shape of the content while the output
#' loads for the first time. When the output calculates again, the old
#' content stays on the screen and is dimmed. The user is possibly reading
#' that content, and grey boxes in its place would remove information and
#' add none.
#'
#' # Shape
#'
#' The shape comes from the output that you give: `plotOutput()` gets the
#' shape of a chart, `tableOutput()` gets rows and columns, and
#' `textOutput()` gets lines of text. Use `type` to set a different shape.
#' You must do this for `uiOutput()`, because its content is not known
#' before it arrives.
#'
#' A `plotOutput()` gets the shape of a bar chart. If the chart is of
#' another kind, give that kind: `"line"`, `"scatter"`, `"area"`,
#' `"histogram"`, `"pie"` or `"heatmap"`. The output cannot tell, because
#' `renderPlot()` decides the kind later, on the server.
#'
#' # Layout
#'
#' The wrapper keeps the space of the output until the content arrives, so
#' the page does not move. If the output sets its own height, as
#' `plotOutput()` does, the wrapper uses that height. If not, the height
#' comes from `rows`, `lines` or `n`, or you can set it with `height`. When
#' the content arrives, the content sets the height.
#'
#' @param ui A Shiny output, such as `plotOutput("chart")`.
#' @param type The shape of the skeleton: `"text"`, `"table"`, `"plot"`,
#'   `"cards"`, `"value"`, or a chart shape (`"bar"`, `"line"`,
#'   `"scatter"`, `"area"`, `"histogram"`, `"pie"`, `"heatmap"`). `NULL`
#'   (the default) gets the shape from `ui`.
#' @param rows,cols The number of body rows and columns, when `type` is
#'   `"table"`.
#' @param lines The number of lines, when `type` is `"text"`.
#' @param n The number of cards or values, when `type` is `"cards"` or
#'   `"value"`.
#' @param height A CSS height for the placeholder, or a number of pixels, as
#'   in Shiny. `NULL` uses the height of the output. If the output has no
#'   height, `NULL` uses a default for the type.
#' @param animation `"wave"`, `"pulse"` or `"none"`. `NULL` uses the value
#'   from [bones_defaults()].
#' @param stale `TRUE` keeps the old content on the screen, dimmed, while
#'   the output calculates again. `FALSE` shows the skeleton again. `NULL`
#'   uses the value from [bones_defaults()], which is `TRUE` if you did not
#'   set it.
#'
#' @return `ui`, in a placeholder container.
#'
#' @examples
#' if (requireNamespace("shiny", quietly = TRUE)) {
#'   library(shiny)
#'
#'   withBones(plotOutput("chart"))
#'   withBones(tableOutput("results"), rows = 8, cols = 5)
#'   withBones(uiOutput("cards"), type = "cards", n = 4)
#'   withBones(plotOutput("trend"), type = "line")
#' }
#' @export
# The name is camelCase, not snake_case, on purpose. It follows the wrappers
# of Shiny, such as withProgress() and withMathJax().
withBones <- function(ui, # nolint: object_name_linter.
                      type = NULL,
                      rows = 6L,
                      cols = 4L,
                      lines = 3L,
                      n = 3L,
                      height = NULL,
                      animation = NULL,
                      stale = NULL) {

  # --- Validate inputs ---
  if (is.null(ui)) stop("`ui` must be a Shiny output, not NULL.", call. = FALSE)
  check_count(rows, "rows")
  check_count(cols, "cols")
  check_count(lines, "lines")
  check_count(n, "n")
  height <- as_css_length(height, "height")

  if (is.null(type)) {
    type <- infer_type(ui)
  } else {
    type <- match.arg(type, skeleton_types())
  }

  animation <- animation %||% getOption("bones.animation", "wave")
  animation <- match.arg(animation, c("wave", "pulse", "none"))
  stale <- stale %||% getOption("bones.stale", TRUE)
  check_flag(stale, "stale")

  # --- Height to keep until the content arrives ---
  if (is.null(height)) {
    height <- find_inline_height(ui)
    if (is.na(height)) {
      height <- default_height(type, rows = rows, lines = lines, n = n)
    }
  }

  # No height here. Inside the wrapper, the skeleton fills the wrapper.
  skeleton <- skeleton_tag(
    type = type, rows = rows, cols = cols, lines = lines, n = n
  )

  htmltools::attachDependencies(
    htmltools::tags$div(
      class = paste0("bones-wrap bones-anim-", animation),
      `data-bones-type` = type,
      `data-bones-stale` = if (isTRUE(stale)) "true" else "false",
      # htmltools writes an NA attribute as an attribute with no value. Give
      # NULL instead, so that no `data-bones-id` attribute is written.
      `data-bones-id` = na_to_null(find_output_id(ui)),
      # A custom property, not a min-height. bones.css applies it only
      # until the content arrives. A min-height that stayed would leave a
      # gap under content that is shorter than the estimate.
      style = paste(c(
        sprintf("--bones-reserve: %s;", height),
        css_vars()
      ), collapse = " "),
      skeleton,
      # The content has its box from the start, but it is hidden. With
      # `display: none`, Shiny would read a width of zero, and
      # plotOutput() would make its image at the wrong size. That image
      # then stays until something causes a new render.
      htmltools::tags$div(class = "bones-content", ui)
    ),
    bones_dependency()
  )
}


#' Set the placeholder defaults for the session
#'
#' Sets the defaults that [withBones()] uses for the rest of the session.
#' An argument that is `NULL` does not change its default. An argument that
#' you give to [withBones()] is stronger than a default from here.
#'
#' @param animation `"wave"` (a band of light moves across the
#'   placeholder), `"pulse"` (the placeholder fades out and in), or
#'   `"none"`. Users who ask their system to reduce motion always get
#'   `"none"`.
#' @param color The colour of the placeholder, as a CSS colour.
#' @param highlight The colour of the band of light in the `"wave"`
#'   animation, and of the header row of a table.
#' @param radius The CSS corner radius of the placeholder bars.
#' @param speed The time of one animation cycle, in seconds.
#' @param stale The default for the `stale` argument of [withBones()].
#'
#' @return The old values, invisibly, in the form that [options()] uses.
#'   Give them to `options()` to restore them. Do not give them to
#'   `bones_defaults()`: `NULL` there means "do not change", so an option
#'   that had no value before would keep the new value.
#'
#' @examples
#' old <- bones_defaults(animation = "pulse", radius = "0.5rem")
#' bones_skeleton("text")
#'
#' options(old)
#' @export
bones_defaults <- function(animation = NULL,
                           color = NULL,
                           highlight = NULL,
                           radius = NULL,
                           speed = NULL,
                           stale = NULL) {

  # --- Validate inputs ---
  if (!is.null(animation)) {
    animation <- match.arg(animation, c("wave", "pulse", "none"))
  }
  if (!is.null(speed) &&
        (!is.numeric(speed) || length(speed) != 1L || is.na(speed) || speed <= 0)) {
    stop("`speed` must be a single positive number of seconds.", call. = FALSE)
  }
  if (!is.null(stale)) check_flag(stale, "stale")

  # These values go into an inline style attribute. A value with a ";"
  # would end the declaration and start another one.
  css_values <- list(color = color, highlight = highlight, radius = radius)
  for (name in names(css_values)) {
    value <- css_values[[name]]
    if (is.null(value)) next
    if (!is.character(value) || length(value) != 1L || is.na(value) ||
          !nzchar(value) || grepl("[;{}]", value)) {
      stop(sprintf("`%s` must be a single CSS value, with no \";\", \"{\" or \"}\".", name),
           call. = FALSE)
    }
  }

  # --- Set only the options that were given ---
  new <- list(
    bones.animation = animation,
    bones.color     = color,
    bones.highlight = highlight,
    bones.radius    = radius,
    bones.speed     = speed,
    bones.stale     = stale
  )
  new <- new[!vapply(new, is.null, logical(1))]

  invisible(options(new))
}


#' Make the colour and shape options into inline CSS custom properties
#' @keywords internal
#' @noRd
css_vars <- function() {
  pairs <- list(
    `--bones-color`     = getOption("bones.color"),
    `--bones-highlight` = getOption("bones.highlight"),
    `--bones-radius`    = getOption("bones.radius"),
    `--bones-speed`     = {
      s <- getOption("bones.speed")
      if (is.null(s)) NULL else sprintf("%ss", s)
    }
  )
  pairs <- pairs[!vapply(pairs, is.null, logical(1))]
  if (length(pairs) == 0L) return(character(0))
  sprintf("%s: %s;", names(pairs), unlist(pairs, use.names = FALSE))
}
