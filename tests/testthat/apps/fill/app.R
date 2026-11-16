# A small application for test-app-smoke.R. It is not an example.
#
# DT::DTOutput() is a fill item, and DT gives a fill item in a fill
# container a 400px flex basis. Outside a fill layout, a wrapped table must
# keep the height of a plain table, and not spill over the next element. In
# a fillable card, a wrapped table must fill the card as a plain table does.

library(shiny)
library(bones)

long_data <- function() {
  data.frame(id = 1:60, name = paste("Subject", 1:60))
}

ui <- bslib::page_fluid(
  div(id = "box-plain", DT::DTOutput("plain")),
  div(id = "box-wrapped", withBones(DT::DTOutput("wrapped"))),
  bslib::card(id = "card-plain", height = 300, DT::DTOutput("card_plain")),
  bslib::card(id = "card-wrapped", height = 300, withBones(DT::DTOutput("card_wrapped")))
)

server <- function(input, output, session) {
  long_table <- function() {
    DT::renderDT(DT::datatable(long_data(), options = list(pageLength = 50)))
  }
  output$plain <- long_table()
  output$wrapped <- long_table()
  output$card_plain <- long_table()
  output$card_wrapped <- long_table()
}

shinyApp(ui, server)
