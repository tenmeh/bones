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
#' If you give `rows`, `cols`, `lines` or `n` to a shape that does not use
#' it, a warning names the unused argument. The shape known in R decides
#' this, before any chart kind is found in the browser. None of these
#' arguments apply to a custom `skeleton`.
#'
#' A `plotOutput()` gets the shape of a bar chart. If the chart is of
#' another kind, give that kind: `"line"`, `"scatter"`, `"area"`,
#' `"histogram"`, `"pie"` or `"heatmap"`. The output cannot tell, because
#' `renderPlot()` decides the kind later, on the server.
#'
#' A table from a table package gets the shape of that package, found from
#' its output: `DT::DTOutput()` gets `"dt"`, `reactable::reactableOutput()`
#' gets `"reactable"`, `gt::gt_output()` gets `"gt"`, and
#' `rhandsontable::rHandsontableOutput()` gets `"rhandsontable"`. Each shape
#' copies the parts of its package, such as the search box of DT. Set `rows`
#' to the number of rows on a page: DT and reactable show 10 by default.
#' Before gt 1.0.0, `gt_output()` did not mark its output as a gt table, so
#' with an older gt, give `type = "gt"`.
#'
#' A visualisation widget gets the shape of its kind, found from its output
#' in the same way. A map (leaflet, tmap, mapview, mapdeck and others) gets
#' `"map"`. A network or a diagram (visNetwork, DiagrammeR, networkD3,
#' collapsibleTree) gets `"network"`. timevis gets `"timeline"`, wordcloud2
#' gets `"wordcloud"`, and dygraphs gets `"line"`. ggmap and a ggplot2 map
#' draw into a `plotOutput()`, so give them `type = "map"`.
#'
#' A plotly, echarts4r or highcharter output can draw any kind of chart. With
#' no `type`, it finds its kind by itself, but only when its first value
#' arrives in the browser: the spec of the chart names the kind of each
#' series. The first skeleton thus has the bar shape. The next loads, with
#' `stale = FALSE`, show the shape of the kind: `"bar"`, `"line"`, `"area"`,
#' `"scatter"`, `"histogram"`, `"pie"`, `"heatmap"`, `"map"`, `"network"` or
#' `"wordcloud"`. With `remember`, the kind is also stored in the browser, so
#' on the next visit the first skeleton has that shape too. The first series
#' that names a kind decides. A chart of a kind with no shape, such as a box
#' plot, keeps the bar shape. A `type` that you give always wins. Other
#' widgets that can draw any chart, such as ggiraph, keep the bar shape: give
#' their kind with `type`.
#'
#' # Your own placeholder
#'
#' When no built-in shape fits, give your own with `skeleton`. Build it from
#' [bones_block()], a grey block that takes the colours and the animation of
#' bones, and lay the blocks out with any tags. The tags at the top level
#' stack with a small gap. The placeholder behaves as a built-in shape does: it
#' waits for `delay`, it stays for `min_time`, it keeps the space of the
#' content, and the old content stays when `stale` is `TRUE`.
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
#' @param type The shape of the skeleton:
#'   `r shapes_md()`.
#'   `NULL` (the default) gets the shape from `ui`.
#'   Use [bones_shapes()] to list shapes by group.
#' @param rows,cols The number of body rows and columns, when `type` is
#'   `"table"` or a table package shape.
#' @param lines The number of lines, when `type` is `"text"`.
#' @param n The number of cards or values, when `type` is `"cards"` or
#'   `"value"`.
#' @param height A CSS height for the placeholder, or a number of pixels, as
#'   in Shiny. `NULL` uses the height of the output. If the output has no
#'   height, `NULL` uses a default for the type. With `skeleton` and an
#'   output that has no height, `NULL` uses the natural height of your
#'   skeleton in the browser. A height that you give always wins.
#' @param animation `"wave"`, `"pulse"`, `"cascade"`, `"sweep"` or
#'   `"none"`. See [bones_defaults()] for what each one does. `NULL` uses the
#'   value from [bones_defaults()].
#' @param stale `TRUE` keeps the old content on the screen, dimmed, while
#'   the output calculates again. `FALSE` shows the skeleton again. `NULL`
#'   uses the value from [bones_defaults()], which is `TRUE` if you did not
#'   set it.
#' @param delay The time in milliseconds before the skeleton, or the
#'   dimming, appears. A load that ends sooner shows nothing, so a fast
#'   output does not flicker. The space of the content is kept from the
#'   start. `NULL` uses the value from [bones_defaults()], which is 300 if
#'   you did not set it.
#' @param min_time The shortest time in milliseconds that the skeleton, or
#'   the dimming, stays on the screen once it has appeared. A load that ends
#'   a moment after `delay` thus does not flash a skeleton for one frame.
#'   `NULL` uses the value from [bones_defaults()], which is 500 if you did
#'   not set it.
#' @param remember `TRUE` stores the real height of the content in the
#'   browser, and keeps that height on the next visit in place of the
#'   estimate, so the page does not move when the content arrives. Only a
#'   height from an estimate is stored: a height from `height`, or from the
#'   output itself, is exact already. The height is kept per page and per
#'   output id, and it is used only when the output has almost the same
#'   width as when it was measured. For a plotly, echarts4r or highcharter
#'   output, `remember` also stores the kind of the chart (see "Shape").
#'   It also allows `learn`. With `skeleton`, its measured height is an
#'   estimate too. `remember = FALSE` disables learning, even if `learn = TRUE`.
#'   `NULL` uses the value from [bones_defaults()], which is `TRUE` if you
#'   did not set it.
#' @param skeleton Your own placeholder, in place of a built-in shape: a tag
#'   or a tag list, made of [bones_block()] blocks and any layout around
#'   them. See "Your own placeholder". Give `type` or `skeleton`, not both.
#'   It keeps its own look by default. Give `learn = TRUE` explicitly to
#'   use it only until the browser has learned the content for a later visit.
#' @param error A panel for a failed output: a tag or a tag list.
#'   `NULL` uses [bones_defaults()], or [bones_error()] if unset.
#'   `FALSE` keeps the error text of Shiny. Silent `req()` errors and
#'   `validate()` messages keep their usual behaviour. After a good load,
#'   the old content stays dimmed with the panel as a banner.
#' @param learn `TRUE` stores the shape of the content in the browser of the
#'   user, and the first skeleton of the next visit has that shape. Only
#'   numbers are stored: the place and the size of each line of text, image
#'   and frame. It applies only when you do not give `type`, `rows`, `cols`,
#'   `lines` or `n`, and not to charts. With `skeleton`, only an explicit
#'   `learn = TRUE` enables learning; a session default does not. Unused
#'   shape arguments do not prevent a custom skeleton from learning.
#'   It needs `remember = TRUE`. A custom skeleton gives a warning if
#'   learning is requested with `remember = FALSE` or for a chart.
#'   `NULL` uses the value from [bones_defaults()], which is `TRUE` if you
#'   did not set it.
#' @param retry A single non-empty input id, or `NULL` for no retry button.
#'   Adds "Try again" after the error panel content. The output must read
#'   this input to run again. Cannot be used with `error = FALSE`.
#' @param hold Input ids that show the skeleton at once when they change,
#'   or `NULL`. Use `ns()` for ids inside modules, for both arguments.
#'   A hold hides content but keeps its space, overrides `stale` and `delay`,
#'   and respects `min_time` when the load finishes. If this output does not
#'   start calculating, the hold releases when Shiny is idle.
#'   In JavaScript, `Bones.hold(el)` holds until the next finished load or
#'   until `Bones.release(el)`, even across idle events. `el` can be the
#'   wrapper, the output element, or its id string.
#' @param speed The time of one animation cycle for this output, in
#'   seconds. `NULL` uses [bones_defaults()], or 1.4 seconds if unset.
#' @param color The colour of this placeholder, as a CSS colour. `NULL`
#'   uses [bones_defaults()], or the theme of the page if unset.
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
#'
#'   # Your own placeholder: an avatar and two lines of text.
#'   withBones(
#'     uiOutput("profile"),
#'     skeleton = div(
#'       style = "display: flex; gap: 1rem; align-items: center;",
#'       bones_block("3rem", "3rem", shape = "circle"),
#'       div(
#'         style = "flex: 1; display: grid; gap: 0.5rem;",
#'         bones_block("60%"), bones_block("40%")
#'       )
#'     )
#'   )
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
                      animation = getOption("bones.animation", "wave"),
                      stale = getOption("bones.stale", TRUE),
                      delay = getOption("bones.delay", 300),
                      min_time = getOption("bones.min_time", 500),
                      remember = getOption("bones.remember", TRUE),
                      skeleton = NULL,
                      error = getOption("bones.error", bones_error()),
                      learn = getOption("bones.learn", TRUE),
                      retry = NULL,
                      hold = NULL,
                      speed = getOption("bones.speed"),
                      color = getOption("bones.color")) {

  # Which arguments set the shape. rows and cols have defaults, so missing()
  # is the only way to tell that the developer gave them. An output whose
  # shape the developer set does not learn its shape.
  shaped <- !missing(rows) || !missing(cols) || !missing(lines) || !missing(n) ||
    !is.null(type) || !is.null(skeleton)
  custom_learn <- !is.null(skeleton) && !missing(learn) && isTRUE(learn)

  # --- Validate inputs ---
  if (is.null(ui)) stop("`ui` must be a Shiny output, not NULL.", call. = FALSE)
  check_count(rows, "rows")
  check_count(cols, "cols")
  check_count(lines, "lines")
  check_count(n, "n")
  height <- as_css_length(height, "height")
  if (!is.null(skeleton)) {
    if (!is.null(type)) {
      stop("Give `type` or `skeleton`, not both.", call. = FALSE)
    }
    if (!inherits(skeleton, c("shiny.tag", "shiny.tag.list", "html")) && !is.list(skeleton)) {
      stop("`skeleton` must be a tag or a tag list, such as `bones_block()`.", call. = FALSE)
    }
  }

  # A type that you give always wins. Only an inferred shape of a plotly,
  # echarts4r or highcharter output is replaced by the kind that bones.js
  # reads from the value.
  detect <- NA_character_
  if (is.null(type)) {
    type <- infer_type(ui)
    # Your own placeholder wins too: its shape must not change.
    if (is.null(skeleton)) detect <- detect_widget(ui)
  } else {
    check_choice(type, skeleton_types(), "type")
  }

  animation <- animation %||% bones_option("animation")
  check_choice(animation, animation_types(), "animation")
  stale <- stale %||% bones_option("stale")
  check_flag(stale, "stale")
  delay <- delay %||% bones_option("delay")
  check_ms(delay, "delay")
  min_time <- min_time %||% bones_option("min_time")
  check_ms(min_time, "min_time")
  remember <- remember %||% bones_option("remember")
  check_flag(remember, "remember")
  error <- error %||% bones_option("error")
  check_error(error)
  if (!is.null(speed)) check_speed(speed)
  if (!is.null(color)) check_css_value(color, "color")
  if (!is.null(retry)) check_ids(retry, "retry", single = TRUE)
  if (!is.null(hold)) check_ids(hold, "hold")
  if (!is.null(retry) && identical(error, FALSE)) {
    stop("`retry` cannot be used with `error = FALSE`.", call. = FALSE)
  }
  if (!identical(error, FALSE) && !is_error_panel(error)) {
    error <- htmltools::tags$div(class = "bones-error", role = "alert", error)
  }
  if (!is.null(retry)) {
    error <- htmltools::tagAppendChild(error, htmltools::tags$button(
      type = "button", class = "bones-retry", "Try again"
    ))
  }
  learn <- learn %||% bones_option("learn")
  check_flag(learn, "learn")
  if (custom_learn && !isTRUE(remember)) {
    warning("`learn = TRUE` with `skeleton` needs `remember = TRUE`. The skeleton does not learn.",
            call. = FALSE)
  }
  if (custom_learn && !type %in% learnable_types()) {
    warning(sprintf(paste(
      "`learn = TRUE` has no effect: a \"%s\" output cannot learn its shape.",
      "The custom skeleton keeps its shape."
    ), type), call. = FALSE)
  }
  learnable <- isTRUE(remember) && isTRUE(learn) && (!shaped || custom_learn) &&
    type %in% learnable_types()

  if (!isTRUE(getOption("bones.quiet_shape_args"))) {
    warn_unused_shape_args(type, c(
      rows = !missing(rows), cols = !missing(cols),
      lines = !missing(lines), n = !missing(n)
    ), custom = !is.null(skeleton))
  }

  # --- Height to keep until the content arrives ---
  # Only an estimated height can be improved by the real one, so only an
  # estimate is marked for bones.js to remember.
  estimated <- FALSE
  # A custom skeleton with no height to go on is measured in the browser.
  # The height of the output itself, when it has one, still wins.
  measure_custom <- FALSE
  if (is.null(height)) {
    height <- find_inline_height(ui)
    measure_custom <- !is.null(skeleton) && is.na(height)
    if (is.na(height)) {
      height <- if (!is.null(skeleton)) {
        default_height(type)
      } else {
        default_height(type, rows = rows, lines = lines, n = n)
      }
      estimated <- TRUE
    }
  }

  # No height here. Inside the wrapper, the skeleton fills the wrapper. The
  # browser measures a custom skeleton before restoring a remembered height.
  custom <- !is.null(skeleton)
  skeleton <- if (custom) {
    custom_skeleton_tag(skeleton)
  } else {
    skeleton_tag(type = type, rows = rows, cols = cols, lines = lines, n = n)
  }

  # In a fillable layout of bslib, such as a card, an output that is a fill
  # item grows to fill its container, and each tag between them must pass
  # the fill on. The wrapper and the content div are between them, so they
  # become fill containers and fill items too. Other outputs keep their own
  # height, and their wrapper stays a plain block.
  fill <- is_fill_item(ui)
  fill_role <- function(tag) {
    if (fill) htmltools::bindFillRole(tag, container = TRUE, item = TRUE) else tag
  }

  # The content has its box from the start, but it is hidden. With
  # `display: none`, Shiny would read a width of zero, and plotOutput()
  # would make its image at the wrong size. That image then stays until
  # something causes a new render.
  content <- fill_role(htmltools::tags$div(class = "bones-content", ui))

  wrap <- fill_role(htmltools::tags$div(
    class = paste0("bones-wrap bones-anim-", animation),
    `data-bones-type` = if (custom) "custom" else type,
    `data-bones-stale` = if (isTRUE(stale)) "true" else "false",
    `data-bones-error` = if (!identical(error, FALSE)) "true",
    `data-bones-retry` = retry,
    # Encode each id separately so spaces and punctuation survive unchanged.
    `data-bones-hold` = if (!is.null(hold)) paste(
      vapply(enc2utf8(hold), utils::URLencode, character(1),
             reserved = TRUE, repeated = TRUE),
      collapse = " "
    ),
    `data-bones-min-time` = format(min_time, scientific = FALSE),
    # Read by bones.js: store the real height, and use it next time.
    `data-bones-remember` = if (estimated && isTRUE(remember)) "true",
    `data-bones-measure-custom` = if (measure_custom) "true",
    # Read by bones.js: find the chart kind from the value, and with
    # remember, store it for the next visit.
    `data-bones-detect` = na_to_null(detect),
    `data-bones-remember-kind` = if (!is.na(detect) && isTRUE(remember)) "true",
    # Read by bones.js: store the boxes of the content, and draw them as
    # the skeleton of the next visit.
    `data-bones-learn` = if (learnable) "true",
    # htmltools writes an NA attribute as an attribute with no value. Give
    # NULL instead, so that no `data-bones-id` attribute is written.
    `data-bones-id` = na_to_null(find_output_id(ui)),
    # A custom property, not a min-height. bones.css applies it only
    # until the content arrives. A min-height that stayed would leave a
    # gap under content that is shorter than the estimate.
    `data-bones-style` = paste(c(
      sprintf("--bones-reserve: %s;", height),
      sprintf("--bones-delay: %sms;", format(delay, scientific = FALSE)),
      css_vars(color = color, speed = speed)
    ), collapse = " "),
    skeleton,
    if (!is.na(detect)) kind_templates(),
    content,
    if (!identical(error, FALSE)) error
  ))

  htmltools::attachDependencies(wrap, bones_dependency(), append = TRUE)
}


#' Is the output a fill item, which grows in a fillable layout?
#'
#' @param ui A UI element.
#' @return `TRUE` or `FALSE`.
#' @keywords internal
#' @noRd
is_fill_item <- function(ui) {
  classes <- unlist(strsplit(collect_classes(ui), "\\s+"), use.names = FALSE)
  "html-fill-item" %in% classes
}


#' Set the placeholder defaults for the session
#'
#' Sets the defaults that [withBones()] uses for the rest of the session.
#' An argument that is `NULL` does not change its default. An argument that
#' you give to [withBones()] is stronger than a default from here.
#' Call it before you build the UI, for example in `global.R`.
#' The options are read when the UI is built.
#'
#' @param animation How the placeholder moves:
#'   * `"wave"`: a band of light moves along each bar.
#'   * `"pulse"`: the whole placeholder fades out and in.
#'   * `"cascade"`: each bar, cell or line lights up a little after the one
#'     before, so a ripple runs through the shape.
#'   * `"sweep"`: one band of light crosses the whole placeholder, over
#'     every mark at once, the lines and dots of a chart too.
#'   * `"none"`: no movement.
#'
#'   Users who ask their system to reduce motion always get `"none"`.
#' @param color The colour of the placeholder, as a CSS colour. By default
#'   it comes from the theme of the page: the text colour of the bslib
#'   theme, made faint. A colour given here is stronger than the theme.
#' @param highlight The colour of the band of light in the `"wave"`
#'   animation, and of the header row of a table. By default it comes from
#'   the theme, as `color` does.
#' @param radius The CSS corner radius of the placeholder bars. By default
#'   it follows the rounding of the theme.
#' @param speed The time of one animation cycle, in seconds.
#' @param stale The default for the `stale` argument of [withBones()].
#' @param delay,min_time The defaults for the `delay` and `min_time`
#'   arguments of [withBones()], in milliseconds.
#' @param remember The default for the `remember` argument of
#'   [withBones()].
#' @param error The default for the `error` argument of [withBones()].
#'   `NULL` leaves the option unchanged. Use `FALSE` for the error text of Shiny.
#' @param learn The default for the `learn` argument of [withBones()].
#'
#' @return With no arguments, a named list of current values. Unset options
#'   use the built-in defaults. `NULL` for `color`, `highlight` and `radius`
#'   means that the stylesheet uses the page theme.
#'   With arguments, the old values, invisibly, in the form that [options()] uses.
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
                           stale = NULL,
                           delay = NULL,
                           min_time = NULL,
                           remember = NULL,
                           error = NULL,
                           learn = NULL) {
  if (nargs() == 0L) {
    current <- lapply(names(builtin_defaults()), bones_option)
    names(current) <- names(builtin_defaults())
    return(current)
  }

  # --- Validate inputs ---
  if (!is.null(animation)) {
    check_choice(animation, animation_types(), "animation")
  }
  if (!is.null(speed)) check_speed(speed)
  if (!is.null(stale)) check_flag(stale, "stale")
  if (!is.null(delay)) check_ms(delay, "delay")
  if (!is.null(min_time)) check_ms(min_time, "min_time")
  if (!is.null(remember)) check_flag(remember, "remember")
  if (!is.null(error)) check_error(error)
  if (!is.null(learn)) check_flag(learn, "learn")

  if (!is.null(color)) check_css_value(color, "color")
  if (!is.null(highlight)) check_css_value(highlight, "highlight")
  if (!is.null(radius)) check_css_value(radius, "radius")

  # --- Set only the options that were given ---
  new <- list(
    bones.animation = animation,
    bones.color     = color,
    bones.highlight = highlight,
    bones.radius    = radius,
    bones.speed     = speed,
    bones.stale     = stale,
    bones.delay     = delay,
    bones.min_time  = min_time,
    bones.remember  = remember,
    bones.error     = error,
    bones.learn     = learn
  )
  new <- new[!vapply(new, is.null, logical(1))]

  invisible(options(new))
}


#' Make the colour and shape options into inline CSS custom properties
#' @keywords internal
#' @noRd
css_vars <- function(color = getOption("bones.color"),
                     speed = getOption("bones.speed")) {
  pairs <- list(
    `--bones-color`     = color,
    `--bones-highlight` = getOption("bones.highlight"),
    `--bones-radius`    = getOption("bones.radius"),
    `--bones-speed`     = if (!is.null(speed)) sprintf("%ss", format(speed, scientific = FALSE))
  )
  pairs <- pairs[!vapply(pairs, is.null, logical(1))]
  if (length(pairs) == 0L) return(character(0))
  sprintf("%s: %s;", names(pairs), unlist(pairs, use.names = FALSE))
}
