# A small application for test-app-csp.R. It is not an example.
#
# The page is served with a strict Content-Security-Policy: no inline styles
# and no inline scripts. bones must still draw each skeleton at its sizes.
# The outputs are ones that Shiny itself writes with no style attribute, so
# any violation comes from bones. Only "done" renders; the others keep their
# skeletons, so the test can measure them.

library(shiny)
library(bones)

csp <- "default-src 'self'; script-src 'self'; style-src 'self'"

# The colour from bones_defaults() goes through the same path as the sizes.
old <- bones_defaults(color = "rgb(255, 0, 0)")
red_wrap <- withBones(tableOutput("red"))
options(old)

ui <- fluidPage(
  tags$head(tags$script(src = "csp-log.js")),
  div(id = "box-text", withBones(textOutput("text"), type = "text", lines = 4)),
  div(id = "box-table", withBones(tableOutput("table"))),
  div(id = "box-scatter", withBones(uiOutput("scatter"), type = "scatter")),
  div(id = "box-heatmap", withBones(uiOutput("heatmap"), type = "heatmap")),
  div(id = "box-red", red_wrap),
  div(id = "box-alone", bones_skeleton("bar", height = 150)),
  div(id = "box-done", withBones(textOutput("done")))
)

server <- function(input, output, session) {
  output$done <- renderText("loaded")
}

app <- shinyApp(ui, server)

# Add the policy as a real response header when the address has ?csp=1.
# shinytest2 evaluates strings in the page, which the policy blocks, so the
# AppDriver starts the app without it and the test then opens ?csp=1.
serve <- app$httpHandler
app$httpHandler <- function(req) {
  res <- serve(req)
  wants_csp <- grepl("(^|[?&])csp=1", req$QUERY_STRING %||% "")
  if (wants_csp && is.list(res) && !is.null(res$status)) {
    res$headers[["Content-Security-Policy"]] <- csp
  }
  res
}

app
