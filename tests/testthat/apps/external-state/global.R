library(shiny)
library(bones)

retry_ui <- function(id) {
  ns <- NS(id)
  tagList(
    actionButton(ns("refresh"), "Refresh module"),
    withBones(textOutput(ns("value")), retry = ns("retry"),
              hold = ns("refresh"), error = bones_error("Module failed"),
              delay = 1000, min_time = 150)
  )
}

retry_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$value <- renderText({
      input$refresh
      if (is.null(input$retry)) stop("Expected first failure")
      Sys.sleep(0.4)
      "Module recovered"
    })
  })
}
