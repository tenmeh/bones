# A small application for test-app-smoke.R. It is not an example.
#
# Each output depends on one slow reactive. The "mode" input then sends
# each output down a different path: a value, a silent req(), or an error.
# The test uses it to show that no wrapper stays stale or on a skeleton,
# whatever the path. The last output is inside a wrapped uiOutput(), to show
# that its events do not change the wrapper of the uiOutput().

library(shiny)
library(bones)

ui <- fluidPage(
  radioButtons("mode", "Mode", c("value", "silent", "error")),
  withBones(textOutput("first")),
  withBones(textOutput("second")),
  withBones(textOutput("third"), stale = FALSE),
  # The uiOutput() does not change. Only the output inside it does. Its
  # wrapper must thus stay as it is.
  withBones(uiOutput("outer"), type = "text")
)

server <- function(input, output, session) {
  source_value <- reactive({
    Sys.sleep(0.8)
    input$mode
  })

  render_for <- function(label) {
    renderText({
      mode <- source_value()
      req(mode != "silent")
      if (mode == "error") stop("An error on purpose, for the test.")
      paste(label, mode)
    })
  }

  output$first <- render_for("first")
  output$second <- render_for("second")
  output$third <- render_for("third")

  output$outer <- renderUI(textOutput("inner"))
  output$inner <- render_for("inner")
}

shinyApp(ui, server)
