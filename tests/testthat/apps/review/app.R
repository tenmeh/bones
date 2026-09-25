# A small application for test-app-smoke.R. It is not an example.
#
# Four faults that a review found, each in a form that a test can see:
#
# 1. The template of the chart kinds is a singleton inside the first
#    wrapper that needs it. "panel" is a renderUI() that renders again on
#    each click, so the only template goes away with the old content. Both
#    plotly outputs are in it, so that no other template is on the page.
# 2. A chart can change its kind. "changes" is a line chart first, and a
#    box plot after a click. A box plot has no shape, so the wrapper must go
#    back to the first shape, and forget the line.
# 3. In a fillable card, a wrapped plot must fill the card as a plain plot
#    does.
# 4. A bones_skeleton() in the content of a wrapper with the sweep must not
#    get the band of the sweep.

library(shiny)
library(bslib)
library(bones)
library(plotly)

ui <- page_fluid(
  actionButton("go", "Go"),
  uiOutput("panel"),
  layout_columns(
    card(id = "card-plain", height = 300, plotOutput("plain")),
    card(id = "card-wrapped", height = 300, withBones(plotOutput("wrapped")))
  ),
  div(id = "box-nested", withBones(uiOutput("nested"), animation = "sweep"))
)

server <- function(input, output, session) {
  output$panel <- renderUI({
    input$go
    tagList(
      withBones(plotlyOutput("inner", height = "200px"), stale = FALSE),
      withBones(plotlyOutput("changes", height = "200px"), stale = FALSE)
    )
  })
  output$inner <- renderPlotly({
    input$go
    plot_ly(x = 1:5, y = c(1, 3, 2, 4, 3), type = "scatter", mode = "lines")
  })
  output$changes <- renderPlotly({
    if (input$go == 0) {
      plot_ly(x = 1:5, y = 1:5, type = "scatter", mode = "lines")
    } else {
      plot_ly(y = c(1, 2, 3, 4, 10), type = "box")
    }
  })
  output$plain <- renderPlot(plot(1:10))
  output$wrapped <- renderPlot(plot(1:10))
  # The documented use of bones_skeleton(): a placeholder in a renderUI().
  output$nested <- renderUI(tagList(p("Loading the list:"), bones_skeleton("text", lines = 2)))
}

shinyApp(ui, server)
