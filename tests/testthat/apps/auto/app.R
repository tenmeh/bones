# A small application for test-app-smoke.R. It is not an example.
#
# bones_auto() wraps the whole bslib page. Four outputs get a wrapper: a
# plot, a table, a text and a uiOutput. The inline text is left alone, and
# so is the excluded plot. The outputs take 1.2 seconds, so the test can
# see the skeletons first.

library(shiny)
library(bslib)
library(bones)

ui <- bones_auto(
  page_sidebar(
    title = "auto",
    theme = bs_theme(primary = "#7a1f5c"),
    sidebar = sidebar(
      actionButton("refresh", "Refresh"),
      p("Count: ", textOutput("count", inline = TRUE))
    ),
    card(plotOutput("chart", height = 200)),
    card(tableOutput("rows")),
    card(textOutput("summary")),
    card(uiOutput("extra")),
    card(plotOutput("skipped", height = 100))
  ),
  exclude = "skipped",
  stale = FALSE
)

server <- function(input, output, session) {
  wait <- reactive({
    input$refresh
    Sys.sleep(1.2)
  })
  output$chart <- renderPlot({
    wait()
    barplot(c(3, 5, 2))
  })
  output$rows <- renderTable({
    wait()
    head(mtcars[, 1:4])
  })
  output$summary <- renderText({
    wait()
    "Six cars."
  })
  output$extra <- renderUI({
    wait()
    tags$p("More.")
  })
  output$count <- renderText(input$refresh)
  output$skipped <- renderPlot(plot(1))
}

shinyApp(ui, server)
