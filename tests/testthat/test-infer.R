test_that("classes are collected from anywhere in the tree", {
  tag <- htmltools::tags$div(
    class = "outer",
    htmltools::tags$div(
      class = "middle",
      htmltools::tags$span(class = "inner deep")
    )
  )

  expect_setequal(bones:::collect_classes(tag), c("outer", "middle", "inner deep"))
  expect_equal(bones:::collect_classes("not a tag"), character(0))
  expect_equal(bones:::collect_classes(NULL), character(0))
})

test_that("each Shiny output class maps to the right shape", {
  expect_equal(bones:::infer_type(fake_output("shiny-plot-output")), "plot")
  expect_equal(bones:::infer_type(fake_output("shiny-image-output")), "plot")
  expect_equal(bones:::infer_type(fake_output("shiny-table-output")), "table")
  expect_equal(bones:::infer_type(fake_output("shiny-text-output")), "text")
  expect_equal(bones:::infer_type(fake_output("shiny-html-output")), "text")
  expect_equal(bones:::infer_type(fake_output("html-widget-output")), "plot")
})

test_that("multi-class attributes are split before matching", {
  # This is how DT and htmlwidgets actually stamp their containers.
  expect_equal(
    bones:::infer_type(fake_output("datatables html-widget html-widget-output")),
    "table"
  )
})

test_that("unknown output shapes fall back to text", {
  expect_equal(bones:::infer_type(fake_output("something-else")), "text")
  expect_equal(bones:::infer_type(htmltools::tags$div()), "text")
})

test_that("the output id is found for the data attribute", {
  expect_equal(bones:::find_output_id(fake_output("x", id = "chart")), "chart")

  nested <- htmltools::tags$div(
    htmltools::tags$div(id = "inner", class = "shiny-plot-output")
  )
  expect_equal(bones:::find_output_id(nested), "inner")

  expect_true(is.na(bones:::find_output_id(htmltools::tags$div())))
})

test_that("an inline pixel height is read off the output", {
  tag <- fake_output("shiny-plot-output", style = "width:100%;height:400px")
  expect_equal(bones:::find_inline_height(tag), "400px")

  tag2 <- fake_output("shiny-plot-output", style = "height: 25rem;")
  expect_equal(bones:::find_inline_height(tag2), "25rem")
})

test_that("a percentage height is ignored", {
  # Relative to a parent we do not control, so it says nothing about how tall
  # the skeleton should be.
  tag <- fake_output("shiny-plot-output", style = "height:100%")
  expect_true(is.na(bones:::find_inline_height(tag)))
})

test_that("a missing height is reported as NA", {
  expect_true(is.na(bones:::find_inline_height(fake_output("shiny-table-output"))))
  expect_true(is.na(bones:::find_inline_height(htmltools::tags$div())))
})

test_that("inference works on real Shiny outputs", {
  skip_if_not_installed("shiny")

  expect_equal(bones:::infer_type(shiny::plotOutput("p")), "plot")
  expect_equal(bones:::infer_type(shiny::tableOutput("t")), "table")
  expect_equal(bones:::infer_type(shiny::textOutput("x")), "text")
  expect_equal(bones:::infer_type(shiny::uiOutput("u")), "text")
})

test_that("tableOutput's two classes resolve to table, not text", {
  skip_if_not_installed("shiny")

  # tableOutput() emits class="shiny-html-output shiny-table-output". Both are
  # in the map, so this only works because the map is ordered specific-first.
  classes <- bones:::collect_classes(shiny::tableOutput("t"))
  expect_match(paste(classes, collapse = " "), "shiny-html-output")
  expect_match(paste(classes, collapse = " "), "shiny-table-output")
  expect_equal(bones:::infer_type(shiny::tableOutput("t")), "table")
})
