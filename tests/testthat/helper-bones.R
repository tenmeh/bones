# Count how many placeholder bars a tag renders.
#
# Bars carry `class="bones-bar"` or `class="bones-bar bones-bar-strong"`, so
# matching the bare string "bones-bar" would double-count the modified ones.
# Anchoring on the opening quote gives exactly one match per bar.
count_bars <- function(tag) {
  count_matches(as.character(tag), "class=\"bones-bar")
}

count_matches <- function(x, pattern) {
  m <- gregexpr(pattern, x, fixed = TRUE)[[1]]
  if (length(m) == 1L && m[1] == -1L) 0L else length(m)
}

# A minimal stand-in for a Shiny output container, so the test suite does not
# need shiny installed to exercise type inference.
fake_output <- function(class, id = "out", style = NULL) {
  htmltools::tags$div(id = id, class = class, style = style)
}
