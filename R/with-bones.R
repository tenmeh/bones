#' Wrap a Shiny output in a skeleton placeholder
#'
#' Shows a grey placeholder shaped like the content while the output loads for
#' the first time. On subsequent recalculations the previous content stays on
#' screen and is dimmed instead, because replacing something the user is already
#' reading with grey boxes takes information away rather than adding it.
#'
#' # Shape
#'
#' The shape is inferred from the output you pass in — `plotOutput()` gets a
#' chart shape, `tableOutput()` gets rows and columns, `textOutput()` gets
#' lines. Pass `type` explicitly to override, which you will need to do for
#' `uiOutput()` since there is no way to know in advance what will appear there.
#'
#' # Layout
#'
#' The wrapper reserves the output's height so that nothing on the page moves
#' when real content arrives. Where the output declares its own height, as
#' `plotOutput()` does, that height is used. Otherwise the height is derived
#' from `rows` / `lines` / `n`, or you can set it directly with `height`.
#'
#' @param ui A Shiny output, such as `plotOutput("chart")`.
#' @param type Skeleton shape: one of `"text"`, `"table"`, `"plot"`, `"cards"`,
#'   `"value"`. `NULL` (the default) infers it from `ui`.
#' @param rows,cols Table dimensions, when `type` is `"table"`.
#' @param lines Number of lines, when `type` is `"text"`.
#' @param n Number of cards or values, when `type` is `"cards"` or `"value"`.
#' @param height A CSS height for the placeholder, or a number of pixels, as
#'   in Shiny. `NULL` reads the output's own height, falling back to a
#'   per-type default.
#' @param animation `"wave"`, `"pulse"` or `"none"`. Defaults to the value set
#'   by [bones_defaults()].
#' @param stale Whether to keep and dim previous content on recalculation
#'   (`TRUE`, the default) or show the skeleton again (`FALSE`).
#'
#' @return `ui`, wrapped in a placeholder container.
#'
#' @examples
#' if (requireNamespace("shiny", quietly = TRUE)) {
#'   library(shiny)
#'
#'   withBones(plotOutput("chart"))
#'   withBones(tableOutput("results"), rows = 8, cols = 5)
#'   withBones(uiOutput("cards"), type = "cards", n = 4)
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
    type <- match.arg(type, c("text", "table", "plot", "cards", "value"))
  }

  animation <- animation %||% getOption("bones.animation", "wave")
  animation <- match.arg(animation, c("wave", "pulse", "none"))
  stale <- stale %||% getOption("bones.stale", TRUE)
  check_flag(stale, "stale")

  if (is.null(height)) {
    height <- find_inline_height(ui)
    if (is.na(height)) {
      height <- default_height(type, rows = rows, lines = lines, n = n)
    }
  }

  # No height: inside the wrapper the skeleton fills the wrapper.
  skeleton <- skeleton_tag(
    type = type, rows = rows, cols = cols, lines = lines, n = n
  )

  htmltools::attachDependencies(
    htmltools::tags$div(
      class = paste0("bones-wrap bones-anim-", animation),
      `data-bones-type` = type,
      `data-bones-stale` = if (isTRUE(stale)) "true" else "false",
      # htmltools renders an NA attribute as a bare boolean one, so drop it
      # rather than emitting a meaningless `data-bones-id`.
      `data-bones-id` = na_to_null(find_output_id(ui)),
      # A custom property, not a min-height. bones.css applies it only
      # until the content arrives. A min-height that stayed would leave a
      # gap under content that is shorter than the estimate.
      style = paste(c(
        sprintf("--bones-reserve: %s;", height),
        css_vars()
      ), collapse = " "),
      skeleton,
      # The content keeps its box from the start, only hidden. Using
      # `display: none` here would report a width of zero to Shiny, and
      # plotOutput() would render at the wrong size — a bug that only appears
      # once and then bakes itself into a cached image.
      htmltools::tags$div(class = "bones-content", ui)
    ),
    bones_dependency()
  )
}


#' Set package-wide placeholder defaults
#'
#' Sets the defaults used by [withBones()] for the rest of the session. Each
#' argument left as `NULL` is unchanged. Individual calls to [withBones()] still
#' win over anything set here.
#'
#' @param animation `"wave"` (a sweep of light across the placeholder),
#'   `"pulse"` (a gentle fade), or `"none"`. `"none"` is also applied
#'   automatically for users who have asked their system to reduce motion.
#' @param color Base placeholder colour, any CSS colour.
#' @param highlight Colour of the sweep, used by the `"wave"` animation.
#' @param radius CSS corner radius for placeholder bars.
#' @param speed Duration of one animation cycle, in seconds.
#' @param stale Default for whether recalculation keeps and dims the previous
#'   content (`TRUE`) or returns to the skeleton (`FALSE`).
#'
#' @return The previous values, invisibly, in the form [options()] expects.
#'   Restore them with `options(old)` — note that this genuinely unsets
#'   anything that had no value before, which passing them back through
#'   `bones_defaults()` would not, since `NULL` there means "leave alone".
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

  if (!is.null(animation)) {
    animation <- match.arg(animation, c("wave", "pulse", "none"))
  }
  if (!is.null(speed) &&
        (!is.numeric(speed) || length(speed) != 1L || is.na(speed) || speed <= 0)) {
    stop("`speed` must be a single positive number of seconds.", call. = FALSE)
  }
  if (!is.null(stale)) check_flag(stale, "stale")

  # These go into an inline style attribute. A value with a semicolon
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


#' Turn the colour/shape options into inline CSS custom properties
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
