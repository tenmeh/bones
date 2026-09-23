#' The bones HTML dependency
#'
#' [withBones()] and [bones_skeleton()] attach this for you. It is exported
#' for HTML that you make yourself with the `bones-*` classes, which needs
#' the stylesheet and the script.
#'
#' @return An [htmltools::htmlDependency()].
#' @examples
#' bones_dependency()
#' @export
bones_dependency <- function() {
  htmltools::htmlDependency(
    name       = "bones",
    version    = as.character(utils::packageVersion("bones")),
    src        = c(file = system.file("www", package = "bones")),
    script     = "bones.js",
    stylesheet = "bones.css"
  )
}
