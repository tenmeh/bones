# A small application for test-app-smoke.R. It is not an example.
#
# Outputs for the learned shapes. Each output waits 1.5 seconds, so a test
# can look at the skeleton before the content arrives.
#
#   tbl     a table of 12 rows: learns. "Fewer rows" makes it 4 rows.
#   txt     three paragraphs: learns.
#   cards   three cards with a border: learns, with three frames.
#   word    one word: one box, so nothing is stored.
#   canvas  a canvas and a caption: the canvas covers more than 60%, so
#           nothing is stored.
#   chart   a plot: a chart does not learn.
#   fixed   a table with rows = 8: the developer set the shape.
#   fail    two lines: learns. "Break" makes it fail, and the stored
#           layout must not change.

library(shiny)
library(bones)

slow <- function(expr) {
  Sys.sleep(1.5)
  expr
}

words <- paste(rep("Some text that fills a line of the paragraph.", 4), collapse = " ")

card <- function() {
  div(
    style = "flex: 1; border: 1px solid #ccc; border-radius: 8px; padding: 12px; height: 90px;",
    h4("Card"),
    p("Some text")
  )
}

box <- function(id, ui) div(id = paste0("box-", id), ui)

ui <- fluidPage(
  actionButton("fewer", "Fewer rows"),
  actionButton("break_it", "Break"),
  box("tbl", withBones(tableOutput("tbl"))),
  box("txt", withBones(uiOutput("txt"))),
  box("cards", withBones(uiOutput("cards"))),
  box("word", withBones(textOutput("word"))),
  box("canvas", withBones(uiOutput("canvas"))),
  box("chart", withBones(plotOutput("chart", height = "200px"))),
  box("fixed", withBones(tableOutput("fixed"), rows = 8)),
  box("fail", withBones(uiOutput("fail")))
)

server <- function(input, output, session) {
  n <- reactiveVal(12L)
  observeEvent(input$fewer, n(4L))

  output$tbl <- renderTable(slow(head(mtcars[, 1:5], n())), rownames = TRUE)
  output$txt <- renderUI(slow(tagList(p(words), p(words), p(words))))
  output$cards <- renderUI(slow(div(style = "display: flex; gap: 12px;", card(), card(), card())))
  output$word <- renderText(slow("Hi"))
  output$canvas <- renderUI(slow(tagList(
    tags$canvas(height = 300, style = "display: block; width: 100%; height: 300px;"),
    p("A caption")
  )))
  output$chart <- renderPlot(slow(plot(1:10)))
  output$fixed <- renderTable(slow(head(mtcars[, 1:3], 8)))
  output$fail <- renderUI({
    if (input$break_it > 0) stop("planned failure")
    slow(tagList(p("first value"), p("second line")))
  })
}

shinyApp(ui, server)
