# A small application for test-app-smoke.R. It is not an example.
#
# One chart for each animation, and one output with a placeholder of its
# own: an avatar and two lines. The outputs take 2 seconds, so the test can
# look at the skeletons while they move.

library(shiny)
library(bones)

chart <- function(animation) {
  div(
    id = paste0("box-", animation),
    withBones(plotOutput(animation, height = 160), type = "bar", animation = animation)
  )
}

profile <- div(
  style = "display: flex; gap: 1rem; align-items: center;",
  bones_block(48, 48, shape = "circle"),
  div(
    style = "flex: 1; display: grid; gap: 0.5rem;",
    bones_block("40%"), bones_block("70%")
  )
)

ui <- fluidPage(
  chart("wave"),
  chart("pulse"),
  chart("cascade"),
  chart("sweep"),
  chart("none"),
  div(id = "box-custom", withBones(uiOutput("profile"), skeleton = profile, height = 80))
)

server <- function(input, output, session) {
  wait <- reactive(Sys.sleep(2))
  for (animation in c("wave", "pulse", "cascade", "sweep", "none")) {
    local({
      id <- animation
      output[[id]] <- renderPlot({
        wait()
        barplot(c(3, 5, 2, 4))
      })
    })
  }
  output$profile <- renderUI({
    wait()
    div(style = "height: 80px;", strong("Ada"), p("Loaded."))
  })
}

shinyApp(ui, server)
