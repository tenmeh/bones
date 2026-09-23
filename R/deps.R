#' The bones HTML dependency
#'
#' [withBones()] attaches this automatically. It is exported for the case where
#' you build placeholder markup yourself with [bones_skeleton()] and need the
#' stylesheet to come along with it.
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
