# Count the placeholder bars in a tag.
#
# A bar has `class="bones-bar"` or `class="bones-bar bones-bar-strong"`. The
# string "bones-bar" alone would thus count a strong bar two times. With the
# opening quote in the pattern, each bar gives exactly one match.
count_bars <- function(tag) {
  count_matches(as.character(tag), "class=\"bones-bar")
}

count_matches <- function(x, pattern) {
  m <- gregexpr(pattern, x, fixed = TRUE)[[1]]
  if (length(m) == 1L && m[1] == -1L) 0L else length(m)
}

# A small replacement for the container of a Shiny output. The tests of the
# shape can thus run when shiny is not installed.
fake_output <- function(class, id = "out", style = NULL) {
  htmltools::tags$div(id = id, class = class, style = style)
}
