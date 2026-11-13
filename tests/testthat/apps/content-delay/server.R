server <- function(input, output, session) {
  # The button that was clicked last sets how this render behaves. The counts
  # of the last render tell which button changed, so one click gives exactly
  # one recalculation.
  seen <- c(fast = 0, slow = 0, fail = 0)

  output$value <- renderText({
    now <- c(fast = input$fast, slow = input$slow, fail = input$fail)
    changed <- names(now)[now > seen]
    seen <<- now
    mode <- if (length(changed)) changed[1] else "fast"
    Sys.sleep(if (mode == "slow") 2 else 0.1)
    if (mode == "fail") stop("Expected failure")
    paste("Content", now[["fast"]], now[["slow"]])
  })
}
