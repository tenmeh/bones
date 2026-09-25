#' A grey block to build your own placeholder
#'
#' The building block of a placeholder that you make yourself. Give the
#' blocks to [withBones()] as `skeleton`, laid out with any tags. Each block
#' takes the colours, the corner radius and the animation of bones, so your
#' placeholder moves and looks like the built-in shapes.
#'
#' The tags at the top level of `skeleton` stack with a small gap. Inside a
#' tag of your own, you set the layout: for example `display: flex` for a
#' row, or `display: grid; gap: 0.5rem` for a column.
#'
#' @param width A CSS width, or a number of pixels. `"100%"` fills the width.
#' @param height A CSS height, or a number of pixels. The default is the
#'   height of one line of text in the built-in shapes.
#' @param shape `"rect"` for a block with the corner radius of bones, or
#'   `"circle"` for a round block, such as an avatar. Give a circle the same
#'   width and height.
#'
#' @return An [htmltools::tag].
#'
#' @seealso [withBones()] and its section "Your own placeholder".
#'
#' @examples
#' # A line of text, 60% wide.
#' bones_block("60%")
#'
#' # An avatar.
#' bones_block(48, 48, shape = "circle")
#'
#' if (requireNamespace("shiny", quietly = TRUE)) {
#'   library(shiny)
#'
#'   # A list of three people: an avatar, a name and a line of text each.
#'   person <- div(
#'     style = "display: flex; gap: 0.75rem; align-items: center;",
#'     bones_block(40, 40, shape = "circle"),
#'     div(
#'       style = "flex: 1; display: grid; gap: 0.4rem;",
#'       bones_block("40%"), bones_block("80%", "0.6rem")
#'     )
#'   )
#'   withBones(uiOutput("people"), skeleton = tagList(person, person, person))
#' }
#' @export
bones_block <- function(width = "100%", height = "0.75rem", shape = c("rect", "circle")) {
  # --- Validate inputs ---
  width <- as_css_length(width, "width")
  height <- as_css_length(height, "height")
  if (is.null(width)) stop("`width` must be a CSS width, not NULL.", call. = FALSE)
  if (is.null(height)) stop("`height` must be a CSS height, not NULL.", call. = FALSE)
  shape <- match.arg(shape)

  # The same element as the bars of the built-in shapes, so it takes their
  # colours and their animation.
  bar(width, height, class = c("bones-block", if (shape == "circle") "bones-block-circle"))
}


#' The skeleton element for your own placeholder
#'
#' The same element as a built-in shape, so the stylesheet and bones.js
#' treat it in the same way: it is hidden for the reader of a screen reader,
#' it waits for the delay, and it takes the animation of the wrapper.
#'
#' @param skeleton A tag or a tag list.
#' @return An htmltools tag.
#' @keywords internal
#' @noRd
custom_skeleton_tag <- function(skeleton) {
  htmltools::tags$div(
    class = "bones-skeleton bones-skeleton-custom",
    `aria-hidden` = "true",
    skeleton
  )
}
