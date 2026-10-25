test_that("check_choice() returns an exact choice invisibly", {
  result <- withVisible(check_choice("bar", skeleton_types(), "type"))
  expect_identical(result, list(value = "bar", visible = FALSE))
})

test_that("bad choices name the argument, value and nearest choice", {
  cases <- list(
    list(function() withBones(fake_output("shiny-plot-output"), type = "bars"),
         "type", "bars", "bar"),
    list(function() bones_skeleton("bars"), "type", "bars", "bar"),
    list(function() withBones(fake_output("shiny-plot-output"), animation = "pules"),
         "animation", "pules", "pulse"),
    list(function() bones_defaults(animation = "pules"),
         "animation", "pules", "pulse"),
    list(function() bones_block(shape = "circel"), "shape", "circel", "circle")
  )
  for (case in cases) {
    error <- expect_error(case[[1]]())
    msg <- conditionMessage(error)
    expect_match(msg, sprintf("`%s` must be one of", case[[2]]), fixed = TRUE)
    expect_match(msg, sprintf('You gave "%s".', case[[3]]), fixed = TRUE)
    expect_match(msg, sprintf('Did you mean "%s"?', case[[4]]), fixed = TRUE)
  }
})

test_that("partial and differently cased names are errors with hints", {
  expect_error(
    withBones(fake_output("shiny-plot-output"), type = "pi"),
    'Did you mean "pie"?', fixed = TRUE
  )
  expect_error(check_choice("BAR", skeleton_types(), "type"),
               'Did you mean "bar"?', fixed = TRUE)
})

test_that("a distant choice has no hint", {
  error <- expect_error(
    withBones(fake_output("shiny-plot-output"), type = "zzzzzz"),
    'You gave "zzzzzz".', fixed = TRUE
  )
  expect_no_match(conditionMessage(error), "Did you mean", fixed = TRUE)
})

test_that("choices must be single non-missing strings", {
  for (value in list(1, NA, NA_character_, c("bar", "pie"), NULL, character())) {
    expect_error(check_choice(value, skeleton_types(), "type"),
                 "`type` must be a single string", fixed = TRUE)
  }
})

test_that("choice errors use the full list and straight quotes", {
  expect_error(
    check_choice(NA, c("rect", "circle"), "shape"),
    '`shape` must be a single string, one of "rect", "circle".',
    fixed = TRUE
  )
  error <- expect_error(check_choice("zzzzzz", c("rect", "circle"), "shape"))
  expect_identical(
    conditionMessage(error),
    '`shape` must be one of "rect", "circle". You gave "zzzzzz".'
  )
  expect_null(conditionCall(error))
})

test_that("a unique prefix takes priority over edit distance", {
  expect_error(check_choice("p", c("pie", "a"), "type"),
               'Did you mean "pie"?', fixed = TRUE)
  expect_error(check_choice("p", c("pie", "plot"), "type"),
               'Did you mean "pie"?', fixed = TRUE)
})

test_that("blocks keep their default rectangle and explicit circle", {
  expect_identical(bones_block(), bones_block(shape = "rect"))
  expect_match(as.character(bones_block()), 'class="bones-bar bones-block"',
               fixed = TRUE)
  expect_match(as.character(bones_block(shape = "circle")), "bones-block-circle",
               fixed = TRUE)
  expect_error(bones_block(shape = c("rect", "circle")),
               "`shape` must be a single string", fixed = TRUE)
})

test_that("skeletons check the animation option", {
  withr::local_options(bones.animation = "pules")
  error <- expect_error(bones_skeleton(), "`animation` must be one of", fixed = TRUE)
  expect_match(conditionMessage(error), 'You gave "pules".', fixed = TRUE)
  expect_match(conditionMessage(error), 'Did you mean "pulse"?', fixed = TRUE)
})
