# bones demo ------------------------------------------------------------
#
# Run with:
#   shiny::runApp(system.file("examples/demo", package = "bones"))
#
# What to look at:
#   * When the page loads, each panel shows a placeholder in the shape of
#     its content: a chart for the plot, and rows and columns for the table.
#   * The page does not move when the content arrives.
#   * Press "Refresh". The content that you are reading stays on the screen
#     and dims. It does not go back to grey blocks.
#   * The last panel has stale = FALSE, so it goes back to a skeleton.
#     Compare the two, and decide which one you prefer.

library(shiny)
library(bones)

slow <- function(seconds = 1.2) Sys.sleep(seconds)

ui <- fluidPage(
  tags$style(HTML("
    body { padding: 1.5rem; max-width: 60rem; }
    .panel-title { font-weight: 600; margin: 1.25rem 0 0.5rem; }
    .hint { opacity: 0.6; font-size: 0.85rem; margin-bottom: 1rem; }
  ")),

  titlePanel("bones"),
  p(class = "hint", "Spinners tell you to wait. Bones tell you what's coming."),

  actionButton("refresh", "Refresh", class = "btn-primary"),

  div(class = "panel-title", "Plot - the shape comes from plotOutput()"),
  withBones(plotOutput("chart", height = "280px")),

  div(class = "panel-title", "Table - eight rows, four columns"),
  withBones(tableOutput("table"), rows = 8, cols = 4),

  div(class = "panel-title", "Value boxes - uiOutput() needs a type"),
  withBones(uiOutput("boxes"), type = "value", n = 3, height = "90px"),

  div(class = "panel-title", "Text with stale = FALSE - goes back to a skeleton"),
  withBones(textOutput("summary"), lines = 3, stale = FALSE)
)

server <- function(input, output, session) {

  data <- reactive({
    input$refresh
    slow()
    data.frame(
      region  = c("North", "South", "East", "West"),
      revenue = round(runif(4, 1e5, 9e5)),
      orders  = sample(200:900, 4),
      margin  = round(runif(4, 0.1, 0.4), 2)
    )
  })

  output$chart <- renderPlot({
    d <- data()
    barplot(d$revenue, names.arg = d$region, col = "#4c72b0",
            border = NA, las = 1, main = "Revenue by region")
  })

  output$table <- renderTable({
    d <- data()
    d[rep(seq_len(nrow(d)), 2), ]
  }, digits = 2)

  output$boxes <- renderUI({
    d <- data()
    div(
      style = "display:flex; gap:1rem;",
      lapply(seq_len(3), function(i) {
        div(
          style = "flex:1; padding:0.75rem; border:1px solid #ddd; border-radius:0.5rem;",
          div(style = "opacity:0.6; font-size:0.8rem;", d$region[i]),
          div(style = "font-size:1.5rem; font-weight:600;",
              format(d$revenue[i], big.mark = ","))
        )
      })
    )
  })

  output$summary <- renderText({
    d <- data()
    sprintf(
      paste("Across %d regions, total revenue was %s from %s orders,",
            "with an average margin of %.0f%%. Press Refresh to regenerate."),
      nrow(d),
      format(sum(d$revenue), big.mark = ","),
      format(sum(d$orders), big.mark = ","),
      100 * mean(d$margin)
    )
  })
}

shinyApp(ui, server)
