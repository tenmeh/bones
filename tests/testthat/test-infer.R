test_that("classes are collected from each level of the tree", {
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

test_that("a class or a style given in two parts is read in full", {
  # gt_output() writes class "shiny-html-output", then a second class
  # "gt_shiny". tag$attribs$class gave only the first one.
  tag <- htmltools::tagAppendAttributes(
    htmltools::tags$div(id = "x", class = "shiny-html-output"),
    class = "gt_shiny"
  )
  expect_setequal(bones:::collect_classes(tag), c("shiny-html-output", "gt_shiny"))

  # The same for style: the height is in the second part.
  tag <- htmltools::tagAppendAttributes(
    htmltools::tags$div(class = "shiny-plot-output", style = "width: 100%"),
    style = "height: 250px"
  )
  expect_equal(bones:::find_inline_height(tag), "250px")

  # When the height is given two times, the last one wins, as in CSS.
  tag <- fake_output("shiny-plot-output", style = "height: 100px; height: 300px")
  expect_equal(bones:::find_inline_height(tag), "300px")
})

test_that("a class attribute with several names is divided before the match", {
  # DT and htmlwidgets write their containers in this way.
  expect_equal(
    bones:::infer_type(fake_output("datatables html-widget html-widget-output")),
    "dt"
  )
})

test_that("an unknown output gets the text shape", {
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

test_that("an inline height is read from the output", {
  tag <- fake_output("shiny-plot-output", style = "width:100%;height:400px")
  expect_equal(bones:::find_inline_height(tag), "400px")

  tag2 <- fake_output("shiny-plot-output", style = "height: 25rem;")
  expect_equal(bones:::find_inline_height(tag2), "25rem")
})

test_that("a percentage height is ignored", {
  # It depends on the height of the parent, which the package does not know.
  # It thus does not help to find the height of the skeleton.
  tag <- fake_output("shiny-plot-output", style = "height:100%")
  expect_true(is.na(bones:::find_inline_height(tag)))
})

test_that("a keyword height such as auto is ignored", {
  # DT::DTOutput() writes height:auto. As a reserve, auto keeps no space,
  # so the skeleton was 0px tall and could not be seen.
  for (value in c("auto", "fit-content", "inherit", "var(--h)")) {
    tag <- fake_output("html-widget-output", style = paste0("width:100%;height:", value, ";"))
    expect_true(is.na(bones:::find_inline_height(tag)), info = value)
  }

  # A calculation with a length in it is still a height.
  tag <- fake_output("shiny-plot-output", style = "height: calc(100vh - 80px)")
  expect_equal(bones:::find_inline_height(tag), "calc(100vh - 80px)")
})

test_that("min-height, max-height and line-height are not read as the height", {
  for (prop in c("min-height", "max-height", "line-height")) {
    tag <- fake_output("shiny-html-output", style = paste0(prop, ": 300px;"))
    expect_true(is.na(bones:::find_inline_height(tag)), info = prop)
  }

  # The real height after one of them is still found.
  tag <- fake_output("shiny-plot-output", style = "line-height: 1.5; height: 250px")
  expect_equal(bones:::find_inline_height(tag), "250px")
})

test_that("a DT output does not reserve height:auto", {
  skip_if_not_installed("DT")

  # DTOutput() writes height:auto. As a reserve that keeps no space, so the
  # default height of the DT shape is used instead.
  html <- as.character(withBones(DT::DTOutput("dt")))
  expect_false(grepl("--bones-reserve: auto", html, fixed = TRUE))
  expect_match(html, "--bones-reserve: \\d+px")
})

test_that("a missing height is reported as NA", {
  expect_true(is.na(bones:::find_inline_height(fake_output("shiny-table-output"))))
  expect_true(is.na(bones:::find_inline_height(htmltools::tags$div())))
})

test_that("the shape is correct for real Shiny outputs", {
  skip_if_not_installed("shiny")

  expect_equal(bones:::infer_type(shiny::plotOutput("p")), "plot")
  expect_equal(bones:::infer_type(shiny::tableOutput("t")), "table")
  expect_equal(bones:::infer_type(shiny::textOutput("x")), "text")
  expect_equal(bones:::infer_type(shiny::uiOutput("u")), "text")
})

test_that("the two classes of tableOutput() give a table, not text", {
  skip_if_not_installed("shiny")

  # tableOutput() writes class="shiny-html-output shiny-table-output". Both
  # are in the map. The result is correct only because the more specific
  # class comes first in the map.
  classes <- bones:::collect_classes(shiny::tableOutput("t"))
  expect_match(paste(classes, collapse = " "), "shiny-html-output")
  expect_match(paste(classes, collapse = " "), "shiny-table-output")
  expect_equal(bones:::infer_type(shiny::tableOutput("t")), "table")
})
