server <- function(input, output, session) {
  # The button keeps the skeleton visible until the test has measured it.
  # Register outputs only on the click. A req() would settle the skeleton.
  observe({
    output$learned <- renderUI({
      tagList(p("First line of content."), p("Second line of content."))
    })
    output$custom <- renderUI({
      tagList(p("First line of content."), p("Second line of content."))
    })
    output$unremembered <- renderText("Loaded content.")
  }) |> bindEvent(input$load, ignoreInit = TRUE)
}
