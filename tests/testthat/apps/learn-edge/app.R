# A small application for test-app-learn.R. It is not an example.
#
# Harder cases for the learned shapes. Each output waits 1.5 seconds.
#
#   single  one card that fills the output, with text in it: learns. The
#           card is a frame, and a frame never stops the record.
#   scroll  a box of 100px that scrolls, with 30 lines in it, and one line
#           60px under it: only the lines that show are recorded.
#   exact   an output with an exact height of 50vh: a learned layout must
#           not change the space that it keeps.
#   outer   two lines, and an inner withBones() of the cards shape that
#           loads for 6 seconds: the inner skeleton is not recorded.
#   big     a table of 3000 rows: recorded quickly.
#   roles   a table made of divs with ARIA roles and striped rows, as
#           reactable makes: no row is a frame.
#   button  a button with a background, and a line: the button is one bar,
#           not a bar and a frame.
#   clear   a box whose background is transparent in the color() form:
#           not a frame.
#   hidden  two lines. The test hides the box, and "Again" renders it
#           again while hidden: the record must stay.
#   flaky   two lines, with min_time = 2000. "Flaky" gives a quick value,
#           then a silent req() while that value waits for min_time: the
#           record must stay.

library(shiny)
library(bones)

slow <- function(expr, seconds = 1.5) {
  Sys.sleep(seconds)
  expr
}

box <- function(id, ui) div(id = paste0("box-", id), ui)

ui <- fluidPage(
  box("single", withBones(uiOutput("single"))),
  box("scroll", withBones(uiOutput("scroll"))),
  box("exact", withBones(htmltools::tagAppendAttributes(uiOutput("exact"), style = "height: 50vh;"))),
  box("outer", withBones(uiOutput("outer"))),
  box("big", withBones(tableOutput("big"))),
  box("roles", withBones(uiOutput("roles"))),
  box("button", withBones(uiOutput("button"))),
  box("clear", withBones(uiOutput("clear"))),
  actionButton("again", "Again"),
  box("hidden", withBones(uiOutput("hidden"))),
  actionButton("flaky", "Flaky"),
  box("flaky", withBones(uiOutput("flaky"), min_time = 2000))
)

server <- function(input, output, session) {
  output$single <- renderUI(slow(div(
    style = "border: 1px solid #ccc; border-radius: 8px; padding: 16px; height: 160px;",
    h4("Total"),
    p("1,234 patients")
  )))
  output$scroll <- renderUI(slow(tagList(
    div(style = "height: 100px; overflow: auto;",
        lapply(seq_len(30), function(i) p(style = "margin: 0;", paste("Line", i)))),
    p(style = "margin-top: 60px;", "Under the box")
  )))
  output$exact <- renderUI(slow(tagList(p("One"), p("Two"))))
  output$outer <- renderUI(slow(tagList(
    p("The outer content"),
    p("A second line"),
    withBones(uiOutput("inner"), type = "cards", n = 3)
  )))
  output$inner <- renderUI(slow(p("Inner"), seconds = 6))
  output$big <- renderTable(slow(data.frame(
    a = seq_len(3000), b = "some text", c = 1.5, d = "more text", e = 2L, f = "end"
  )))

  output$roles <- renderUI(slow(div(
    role = "table",
    lapply(seq_len(6), function(i) {
      div(
        role = "row",
        style = sprintf("height: 32px; background: %s;", if (i %% 2) "#f0f0f0" else "transparent"),
        span(role = "cell", paste("Row", i))
      )
    })
  )))
  output$button <- renderUI(slow(tagList(
    tags$button(style = "height: 40px; background: #dddddd; border: 0;", "Press"),
    p("A line under the button")
  )))
  output$clear <- renderUI(slow(div(
    style = "height: 60px; background-color: color(srgb 1 0 0 / 0);",
    p("One line"),
    p("Another line")
  )))

  output$hidden <- renderUI({
    input$again
    slow(tagList(p("First line"), p("Second line")))
  })
  outputOptions(output, "hidden", suspendWhenHidden = FALSE)

  mode <- reactiveVal("full")
  observeEvent(input$flaky, {
    mode("quick")
    later::later(function() mode("blank"), 1)
  })
  output$flaky <- renderUI({
    m <- mode()
    req(m != "blank")
    Sys.sleep(if (m == "quick") 0.6 else 1.5)
    tagList(p("First line"), p("Second line"))
  })
}

shinyApp(ui, server)
