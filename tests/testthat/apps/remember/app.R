# A small application for test-app-smoke.R. It is not an example.
#
# Two outputs with the same 400px content, and a text estimate of 72px. The
# content takes 1.5 seconds, so the test can measure the kept space before
# it arrives. On the first visit both keep 72px. After a reload, the one
# that remembers keeps 400px, and the other still keeps 72px.

library(shiny)
library(bones)

tall_content <- function(label) {
  renderUI({
    Sys.sleep(1.5)
    div(style = "height: 400px; background: #eef;", label)
  })
}

ui <- fluidPage(
  div(id = "box-remember", withBones(uiOutput("tall"), type = "text")),
  div(id = "box-forget", withBones(uiOutput("other"), type = "text", remember = FALSE))
)

server <- function(input, output, session) {
  output$tall <- tall_content("remembered")
  output$other <- tall_content("not remembered")
}

shinyApp(ui, server)
