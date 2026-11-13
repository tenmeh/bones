ui <- fluidPage(
  withBones(textOutput("retry_value"), retry = "retry", delay = 1000, min_time = 150),
  retry_ui("module"),
  withBones(textOutput("stuck"), retry = "unused_retry", delay = 1000),
  actionButton("refresh", "Refresh"),
  actionButton("unused", "No output change"),
  actionButton("fail", "Fail"),
  withBones(textOutput("value"), hold = c("refresh", "unused", "fail"),
            delay = 1000, min_time = 150, animation = "pulse"),
  withBones(textOutput("replacement"), hold = "refresh", stale = FALSE,
            delay = 1000, min_time = 150)
)
