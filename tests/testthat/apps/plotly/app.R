# A small application for test-app-smoke.R. It is not an example.
#
# Plotly charts of five kinds. Each one first gets the bar shape, because a
# plotly output does not say its kind. When its value arrives, bones.js
# reads the kind from the traces and uses that shape. Two outputs must keep
# their shape in the next visit: "fixed" has a type that you give, and
# "forget" has remember = FALSE. The charts take 1.5 seconds, so the test
# can look at the skeletons before they arrive. stale = FALSE, so a new load
# shows the skeleton again.

library(shiny)
library(bones)
library(plotly)

chart <- function(id, ...) {
  div(id = paste0("box-", id), withBones(plotlyOutput(id, height = "250px"), stale = FALSE, ...))
}

ui <- fluidPage(
  actionButton("refresh", "Refresh"),
  chart("line"),
  chart("scatter"),
  chart("pie"),
  chart("area"),
  chart("heatmap"),
  chart("fixed", type = "scatter"),
  chart("forget", remember = FALSE)
)

server <- function(input, output, session) {
  # One slow reactive for all the charts, so a load takes 1.5 seconds.
  wait <- reactive({
    input$refresh
    Sys.sleep(1.5)
  })
  slow <- function(expr) {
    expr <- substitute(expr)
    env <- parent.frame()
    renderPlotly({
      wait()
      eval(expr, env)
    })
  }
  x <- 1:20
  output$line <- slow(plot_ly(x = x, y = cumsum(x), type = "scatter", mode = "lines"))
  output$scatter <- slow(plot_ly(x = x, y = rev(x), type = "scatter", mode = "markers"))
  output$pie <- slow(plot_ly(labels = c("A", "B", "C"), values = c(3, 2, 1), type = "pie"))
  output$area <- slow(plot_ly(x = x, y = x, type = "scatter", mode = "lines", fill = "tozeroy"))
  output$heatmap <- slow(plot_ly(z = matrix(1:20, 4), type = "heatmap"))
  output$fixed <- slow(plot_ly(x = c("a", "b"), y = c(1, 2), type = "bar"))
  output$forget <- slow(plot_ly(x = x, y = x, type = "scatter", mode = "lines"))
}

shinyApp(ui, server)
