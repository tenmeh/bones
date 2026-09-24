# A small application for test-app-smoke.R. It is not an example.
#
# It shows each chart shape two times: on its own, from bones_skeleton(), and
# inside a withBones() wrapper whose plot never arrives. The test measures
# the marks of each shape in a real browser.

library(shiny)
library(bones)

types <- c("plot", "bar", "histogram", "line", "area", "scatter", "pie", "heatmap")

ui <- fluidPage(
  tags$style(".gallery { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; }"),
  h4("On their own"),
  div(
    class = "gallery",
    lapply(types, function(type) {
      div(id = paste0("alone-", type), tags$small(type), bones_skeleton(type, height = 200))
    })
  ),
  h4("Inside a wrapper"),
  div(
    class = "gallery",
    lapply(types, function(type) {
      div(tags$small(type), withBones(plotOutput(paste0("p_", type), height = "200px"), type = type))
    })
  )
)

# The server defines no plots. Each output thus stays empty, and each
# wrapper keeps its skeleton for the whole test.
server <- function(input, output, session) {}

shinyApp(ui, server)
