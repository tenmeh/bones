# A small application for test-app-smoke.R. It is not an example.
#
# Four outputs, each with its own button and its own load time, for the
# delay (300ms) and min_time (500ms) of withBones():
#
#   fast        50ms, stale = FALSE: must never show a skeleton.
#   faststale   50ms, stale = TRUE:  must never dim the content.
#   slow        1.2s, stale = FALSE: the skeleton appears after the delay.
#   medium      450ms, stale = FALSE: the skeleton appears at 300ms. With no
#               min_time it would go 150ms later. It must stay 500ms.

library(shiny)
library(bones)

timed_text <- function(id, seconds, stale) {
  tagList(
    actionButton(paste0("go_", id), id),
    div(id = paste0("box-", id), withBones(textOutput(id), stale = stale))
  )
}

ui <- fluidPage(
  timed_text("fast", 0.05, stale = FALSE),
  timed_text("faststale", 0.05, stale = TRUE),
  timed_text("slow", 1.2, stale = FALSE),
  timed_text("medium", 0.45, stale = FALSE)
)

server <- function(input, output, session) {
  make <- function(id, seconds) {
    renderText({
      input[[paste0("go_", id)]]
      Sys.sleep(seconds)
      paste(id, "done at", format(Sys.time(), "%H:%M:%OS3"))
    })
  }
  output$fast      <- make("fast", 0.05)
  output$faststale <- make("faststale", 0.05)
  output$slow      <- make("slow", 1.2)
  output$medium    <- make("medium", 0.45)
}

shinyApp(ui, server)
