# A small application for test-app-theme-plain.R. It is not an example.
#
# A page with no Bootstrap. The app sets the colour inputs of bones on
# :root and on containers, as an app with its own CSS would. No output
# renders, so each wrapper keeps its skeleton.

library(shiny)
library(bones)

page_css <- "
:root { --bones-color: rgb(0, 128, 0); --bones-radius: 7px; }
body { color: rgb(20, 20, 20); background: #ffffff; }
/* initial empties an input, so these parts get the colours of the theme. */
.dark { --bones-color: initial; color: rgb(240, 240, 240); background: #111111; }
.text { --bones-color: initial; --bones-text: rgb(200, 0, 0); }
.surface { --bones-surface: rgb(10, 20, 30); }
"

ui <- tagList(
  tags$head(tags$style(page_css)),
  div(id = "box-root", withBones(plotOutput("root", height = "120px"))),
  div(id = "box-dark", class = "dark", withBones(plotOutput("dark", height = "120px"))),
  div(id = "box-text", class = "text", withBones(plotOutput("text", height = "120px"))),
  div(id = "box-surface", class = "surface",
      withBones(plotOutput("surface", height = "120px"), animation = "sweep")),
  div(id = "box-own", withBones(plotOutput("own", height = "120px"), color = "rgb(0, 0, 255)")),
  div(id = "box-alone", bones_skeleton("text"))
)

server <- function(input, output, session) {}

shinyApp(ui, server)
