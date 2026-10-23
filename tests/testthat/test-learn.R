# Which outputs may learn their shape. bones.js learns only for a wrapper
# with data-bones-learn="true", so these tests check that mark.

learns <- function(tag) {
  identical(htmltools::tagGetAttribute(tag, "data-bones-learn"), "true")
}

table_out <- function(id = "t") fake_output("shiny-table-output", id = id)

test_that("an output with no shape arguments learns", {
  expect_true(learns(withBones(fake_output("shiny-html-output"))))
  expect_true(learns(withBones(table_out())))
  expect_true(learns(withBones(fake_output("shiny-text-output"))))
  expect_true(learns(withBones(fake_output("gt_shiny shiny-html-output"))))
})

test_that("an output does not learn when the developer sets its shape", {
  expect_false(learns(withBones(table_out(), rows = 8)))
  expect_false(learns(withBones(table_out(), cols = 3)))
  expect_false(learns(withBones(fake_output("shiny-text-output"), lines = 2)))
  expect_false(learns(withBones(fake_output("shiny-html-output"), n = 4)))
  expect_false(learns(withBones(table_out(), type = "table")))
  expect_false(learns(withBones(table_out(), skeleton = bones_block())))
})

test_that("a chart does not learn", {
  expect_false(learns(withBones(fake_output("shiny-plot-output"))))
  expect_false(learns(withBones(fake_output("plotly html-widget html-widget-output"))))
  expect_false(learns(withBones(fake_output("leaflet html-widget html-widget-output"))))
})

test_that("learn = FALSE and remember = FALSE turn learning off", {
  expect_false(learns(withBones(table_out(), learn = FALSE)))
  expect_false(learns(withBones(table_out(), remember = FALSE)))

  withr::local_options(bones.learn = NULL)
  old <- bones_defaults(learn = FALSE)
  withr::defer(options(old))
  expect_false(learns(withBones(table_out())))
  expect_true(learns(withBones(table_out(), learn = TRUE)))
})

test_that("learn = TRUE does not override a shape that the developer set", {
  expect_false(learns(withBones(table_out(), rows = 8, learn = TRUE)))
})

test_that("bones_auto() passes the shape arguments on", {
  wrap_of <- function(ui) htmltools::tagQuery(ui)$find(".bones-wrap")$selectedTags()[[1]]
  page <- function() htmltools::div(table_out("a"))

  expect_true(learns(wrap_of(bones_auto(page()))))
  expect_false(learns(wrap_of(bones_auto(page(), rows = 8))))
})

test_that("learn must be TRUE or FALSE", {
  expect_error(withBones(table_out(), learn = NA), "`learn` must be TRUE or FALSE.", fixed = TRUE)
  expect_error(withBones(table_out(), learn = "yes"), "`learn` must be TRUE or FALSE.", fixed = TRUE)
  expect_error(bones_defaults(learn = 1), "`learn` must be TRUE or FALSE.", fixed = TRUE)
})
