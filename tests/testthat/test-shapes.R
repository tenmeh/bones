test_that("all shapes are returned in their original order", {
  expect_identical(bones_shapes(), skeleton_types())
  expect_identical(bones_shapes(NULL), skeleton_types())
})

test_that("groups partition the shapes and preserve their order", {
  groups <- lapply(c("basic", "chart", "table"), bones_shapes)
  all <- bones_shapes()
  for (group in groups) {
    expect_identical(group, all[all %in% group])
    expect_gt(length(group), 0L)
  }
  combined <- unlist(groups, use.names = FALSE)
  expect_setequal(combined, all)
  expect_identical(anyDuplicated(combined), 0L)
  expect_identical(bones_shapes("basic"), c("text", "cards", "value"))
  expect_identical(bones_shapes("chart"), c("plot", chart_types()))
  expect_identical(bones_shapes("table"), c("table", table_types()))
})

test_that("bad groups give a clear error with a hint", {
  error <- expect_error(bones_shapes("chrat"))
  expect_identical(
    conditionMessage(error),
    paste('`group` must be one of "basic", "chart", "table".',
          'You gave "chrat". Did you mean "chart"?')
  )
  expect_null(conditionCall(error))
  for (group in list(character(), NA_character_, 1, c("basic", "table"))) {
    expect_error(bones_shapes(group), "`group` must be a single string",
                 fixed = TRUE)
  }
  expect_error(bones_shapes(""), "`group` must be one of", fixed = TRUE)
})
