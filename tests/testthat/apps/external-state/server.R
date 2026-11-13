server <- function(input, output, session) {
  retry_server("module")
  output$retry_value <- renderText({
    if (is.null(input$retry)) stop("Expected first failure")
    Sys.sleep(0.4)
    "Recovered"
  })
  output$stuck <- renderText(stop("Expected persistent failure"))
  # Make idle observable even when the target output has no dependency.
  observeEvent(input$unused_retry, Sys.sleep(0.2))
  observeEvent(input$unused, Sys.sleep(0.2))
  value <- reactiveVal(0L)
  observeEvent(input$refresh, {
    Sys.sleep(0.7)
    value(input$refresh)
  })
  output$value <- renderText({
    if (input$fail > 0) stop("Expected held failure")
    paste("Value", value())
  })
  output$replacement <- renderText(paste("Replacement", value()))
}
