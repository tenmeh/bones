test_that("shape arguments follow the calls that build the shapes", {
  uses <- bones:::shape_arguments()
  expect_setequal(names(uses), bones:::skeleton_types())
  expect_identical(uses$text, "lines")
  for (type in c("table", bones:::table_types())) {
    expect_identical(uses[[type]], c("rows", "cols"))
  }
  for (type in c("cards", "value")) expect_identical(uses[[type]], "n")
  for (type in c("plot", bones:::chart_types())) {
    expect_length(uses[[type]], 0L)
  }
})

test_that("only explicit unused shape arguments warn", {
  expect_warning(withBones(shiny::plotOutput("x"), rows = 8),
                 '`rows` has no effect on the "plot" shape.', fixed = TRUE)
  expect_no_warning(withBones(shiny::tableOutput("x"), rows = 8))
  expect_warning(bones_skeleton("plot", rows = 8),
                 '`rows` has no effect on the "plot" shape.', fixed = TRUE)
  expect_warning(bones_skeleton("text", n = 3),
                 '`n` has no effect on the "text" shape. It applies to "cards" and "value".',
                 fixed = TRUE)
  for (type in bones:::skeleton_types()) {
    expect_no_warning(bones_skeleton(type))
    expect_no_warning(withBones(shiny::uiOutput("x"), type = type))
    for (arg in c("rows", "cols", "lines", "n")) {
      args <- c(list(type = type), setNames(list(8), arg))
      if (arg %in% bones:::shape_arguments()[[type]]) {
        expect_no_warning(do.call(bones_skeleton, args))
      } else {
        expect_warning(do.call(bones_skeleton, args), "has no effect")
      }
    }
  }
})

test_that("custom placeholders ignore all count arguments", {
  ui <- shiny::uiOutput("x")
  for (arg in c("rows", "cols", "lines", "n")) {
    args <- c(list(ui = ui, skeleton = bones_block()), setNames(list(8), arg))
    expect_warning(result <- do.call(withBones, args),
                   paste0("`", arg, "` has no effect with a custom `skeleton`."),
                   fixed = TRUE)
    expect_equal(result, withBones(ui, skeleton = bones_block()))
  }
})

test_that("automatic wrapping skips only unused argument warnings", {
  ui <- htmltools::tagList(shiny::plotOutput("p"), shiny::tableOutput("t"))
  expect_no_warning(bones_auto(ui, rows = 8))
  expect_error(bones_auto(ui, rows = NA), "`rows` must be a single number")
  # The quiet switch is internal, and it does not outlive bones_auto().
  expect_false("bones.quiet_shape_args" %in% names(formals(withBones)))
  expect_null(getOption("bones.quiet_shape_args"))
  expect_warning(withBones(shiny::plotOutput("p"), rows = 8), "has no effect")
})

test_that("warnings have no call and use the shape known in R", {
  ui <- fake_output("plotly html-widget-output")
  caught <- NULL
  withCallingHandlers(withBones(ui, cols = 4), warning = function(w) {
    caught <<- w
    invokeRestart("muffleWarning")
  })
  expect_match(conditionMessage(caught), '"plot" shape', fixed = TRUE)
  expect_null(conditionCall(caught))
})
