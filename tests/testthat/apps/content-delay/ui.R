ui <- fluidPage(
  actionButton("fast", "Fast"),
  actionButton("slow", "Slow"),
  actionButton("fail", "Fail"),
  withBones(textOutput("value"), stale = FALSE, delay = 1000, min_time = 0)
)
