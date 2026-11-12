ui <- fluidPage(
  actionButton("load", "Load content"),
  withBones(uiOutput("learned"), skeleton = bones_block(height = 240),
            learn = TRUE, delay = 0, min_time = 0),
  withBones(uiOutput("custom"), skeleton = bones_block(height = 240),
            delay = 0, min_time = 0),
  withBones(textOutput("unremembered"), skeleton = bones_block(height = 180),
            remember = FALSE, delay = 0, min_time = 0)
)
