# A small application for test-app-smoke.R. It is not an example.
#
# echarts4r and highcharter charts of several kinds, each with no type.
# Each one first gets the bar shape. When its value arrives, bones.js reads
# the kind from its series and uses that shape. The box plots have no shape,
# so they keep the bar shape, and not the shape of their outliers. The
# charts take 1.5 seconds, so the test can look at the skeletons first.

library(shiny)
library(bones)
library(echarts4r)
library(highcharter)

box <- function(output) {
  div(class = "box", withBones(output, stale = FALSE))
}

ui <- fluidPage(
  actionButton("refresh", "Refresh"),
  box(echarts4rOutput("e_line", height = "200px")),
  box(echarts4rOutput("e_area", height = "200px")),
  box(echarts4rOutput("e_pie", height = "200px")),
  box(echarts4rOutput("e_cloud", height = "200px")),
  box(echarts4rOutput("e_box", height = "200px")),
  box(highchartOutput("h_column", height = "200px")),
  box(highchartOutput("h_area", height = "200px")),
  box(highchartOutput("h_scatter", height = "200px")),
  box(highchartOutput("h_default", height = "200px")),
  box(highchartOutput("h_box", height = "200px"))
)

server <- function(input, output, session) {
  wait <- reactive({
    input$refresh
    Sys.sleep(1.5)
  })
  d <- data.frame(x = 1:10, y = (1:10)^1.5, g = rep(c("a", "b"), 5))
  words <- data.frame(w = c("alpha", "beta", "gamma"), f = c(3, 2, 1))

  # Each chart waits for the slow reactive, then draws.
  echart <- function(expr) {
    expr <- substitute(expr)
    env <- parent.frame()
    renderEcharts4r({
      wait()
      eval(expr, env)
    })
  }
  hchart_slow <- function(expr) {
    expr <- substitute(expr)
    env <- parent.frame()
    renderHighchart({
      wait()
      eval(expr, env)
    })
  }

  output$e_line <- echart(d |> e_charts(x) |> e_line(y))
  output$e_area <- echart(d |> e_charts(x) |> e_area(y))
  output$e_pie <- echart(d |> e_charts(g) |> e_pie(y))
  output$e_cloud <- echart(words |> e_color_range(f, color) |> e_charts() |> e_cloud(w, f, color))
  output$e_box <- echart(d |> e_charts() |> e_boxplot(y))

  output$h_column <- hchart_slow(hchart(d, "column", hcaes(x, y)))
  output$h_area <- hchart_slow(hchart(d, "area", hcaes(x, y)))
  output$h_scatter <- hchart_slow(hchart(d, "scatter", hcaes(x, y)))
  output$h_default <- hchart_slow(highchart() |> hc_add_series(data = 1:5))
  output$h_box <- hchart_slow(
    highchart() |> hc_add_series(type = "boxplot", data = list(c(1, 2, 3, 4, 5)))
  )
}

shinyApp(ui, server)
