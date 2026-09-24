# A small application for test-app-smoke.R. It is not an example.
#
# The skeletons must take their colours from the theme of the page. The page
# has a bslib theme with navy text, a part with the dark theme of Bootstrap,
# a wrapper with a colour from bones_defaults(), and a skeleton with no
# wrapper. No output renders, so each wrapper keeps its skeleton.

library(shiny)
library(bones)

navy_wrap <- withBones(plotOutput("navy", height = "120px"))

dark_wrap <- div(
  `data-bs-theme` = "dark",
  style = "background: #212529; padding: 1rem;",
  withBones(plotOutput("dark", height = "120px"))
)

# bones_defaults() is stronger than the theme.
old <- bones_defaults(color = "rgb(255, 0, 0)")
red_wrap <- withBones(plotOutput("red", height = "120px"))
options(old)

ui <- bslib::page_fluid(
  theme = bslib::bs_theme(version = 5, fg = "#1d3557", bg = "#ffffff"),
  div(id = "box-navy", navy_wrap),
  div(id = "box-dark", dark_wrap),
  div(id = "box-red", red_wrap),
  div(id = "box-alone", bones_skeleton("text"))
)

server <- function(input, output, session) {}

shinyApp(ui, server)
