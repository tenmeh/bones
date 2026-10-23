# A small application for test-app-learn.R. It is not an example.
#
# A page with bslib cards, as in a real app. While the browser reads a page
# of this size, a wrapper can come into the page before its skeleton. Each
# of the three outputs must still draw its learned shape on the next visit.

library(shiny)
library(bslib)
library(bones)

slow <- function(expr) {
  Sys.sleep(2)
  expr
}

kpi <- function(label, value) {
  div(style = "flex: 1; border: 1px solid #ddd; border-radius: 10px; padding: 14px;",
      div(style = "color: #666; font-size: 0.85rem;", label),
      div(style = "font-size: 1.6rem; font-weight: 600;", value))
}

ui <- page_fluid(
  theme = bs_theme(version = 5),
  h4("Study overview", class = "mt-3"),
  withBones(uiOutput("kpis")),
  layout_columns(
    col_widths = c(7, 5),
    card(card_header("Adverse events by site"), withBones(tableOutput("ae"))),
    card(card_header("Notes"), withBones(uiOutput("notes")))
  )
)

server <- function(input, output, session) {
  output$kpis <- renderUI(slow(div(
    style = "display: flex; gap: 12px; margin-bottom: 12px;",
    kpi("Patients", "1,234"), kpi("Sites", "18"), kpi("Events", "312")
  )))
  output$ae <- renderTable(slow(data.frame(
    Site = sprintf("Site %02d", 1:9),
    Patients = c(88, 74, 69, 61, 58, 52, 47, 41, 36),
    Events = c(31, 22, 25, 17, 19, 12, 14, 9, 8)
  )))
  output$notes <- renderUI(slow(tagList(
    p("Enrolment is ahead of plan at most sites. Two sites are behind and have a new recruitment plan."),
    p("The data cut for this report is 30 September. Events are counted once for each patient.")
  )))
}

shinyApp(ui, server)
