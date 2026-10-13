library(shiny)
library(bones)

ui <- fluidPage(
  tags$head(tags$script(HTML("$(document).on('shiny:error', function(e) {
    window.bonesErrors = window.bonesErrors || {};
    window.bonesErrors[e.name] = e.error;
  });"))),
  actionButton("fail", "Fail"),
  actionButton("recover", "Recover"),
  actionButton("idle", "Make idle"),
  textOutput("idle_value"),
  withBones(textOutput("silent"), delay = 0, min_time = 0),
  withBones(textOutput("validation"), delay = 0, min_time = 0),
  withBones(textOutput("first_error"), delay = 0, min_time = 0),
  withBones(
    htmltools::tagAppendAttributes(textOutput("later_error"), style = "min-height: 160px;"),
    delay = 10000, min_time = 10000
  ),
  withBones(
    htmltools::tagAppendAttributes(textOutput("no_stale"), style = "min-height: 160px;"),
    stale = FALSE, delay = 0, min_time = 0
  ),
  withBones(textOutput("detail"), fallback = bones_fallback(detail = TRUE)),
  withBones(textOutput("safe_error"), delay = 0, min_time = 0),
  withBones(textOutput("disabled"), fallback = FALSE, delay = 0, min_time = 0)
)

server <- function(input, output, session) {
  output$idle_value <- renderText({
    input$idle
  })
  output$silent <- renderText({
    req(FALSE)
  })
  output$validation <- renderText({
    validate(need(FALSE, "pick one"))
  })
  output$first_error <- renderText({
    stop("boom")
  })
  output$later_error <- renderText({
    if (input$fail > input$recover) stop("boom")
    "Old content"
  })
  output$no_stale <- renderText({
    if (input$fail > input$recover) stop("boom")
    "Old content without stale"
  })
  output$detail <- renderText({
    stop("<boom>")
  })
  output$safe_error <- renderText({
    stop(safeError("safe boom"))
  })
  output$disabled <- renderText({
    stop("boom")
  })
}

shinyApp(ui, server)
