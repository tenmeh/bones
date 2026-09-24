# A small application for test-app-smoke.R. It is not an example.
#
# Each table package in a withBones() wrapper, with the shape that withBones()
# finds by itself. The tables take 2 seconds to arrive, so the test can look
# at the skeletons first, and then compare the reserved space with the real
# tables.

library(shiny)
library(bones)

table_data <- function() {
  data.frame(
    id   = 1:6,
    name = paste("Subject", 1:6),
    age  = 21:26,
    arm  = rep(c("A", "B"), 3)
  )
}

ui <- bslib::page_fluid(
  div(id = "box-dt", withBones(DT::DTOutput("dt"))),
  div(id = "box-reactable", withBones(reactable::reactableOutput("rt"))),
  div(id = "box-gt", withBones(gt::gt_output("gt"))),
  div(id = "box-rhandsontable", withBones(rhandsontable::rHandsontableOutput("hot")))
)

server <- function(input, output, session) {
  slow_data <- reactive({
    Sys.sleep(2)
    table_data()
  })

  output$dt <- DT::renderDT(DT::datatable(slow_data()))
  output$rt <- reactable::renderReactable(reactable::reactable(slow_data()))
  output$gt <- gt::render_gt(
    gt::gt(slow_data()) |>
      gt::tab_header("Title", "Subtitle") |>
      gt::tab_spanner("Details", c(age, arm)) |>
      gt::tab_source_note("Source note")
  )
  output$hot <- rhandsontable::renderRHandsontable(rhandsontable::rhandsontable(slow_data()))
}

shinyApp(ui, server)
