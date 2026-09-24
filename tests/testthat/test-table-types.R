# Table skeletons: one shape for each common table package.
#
# Unlike a chart, a table package can be found from its output: DT,
# reactable, gt and rhandsontable each put their own class on the container.
# withBones() thus picks the shape by itself.

table_types <- c("dt", "reactable", "gt", "rhandsontable")

test_that("each table type makes a skeleton with its own class", {
  for (type in table_types) {
    html <- as.character(bones_skeleton(type))
    expect_match(html, paste0("bones-skeleton-", type), fixed = TRUE, info = type)
    expect_match(html, 'aria-hidden="true"', fixed = TRUE, info = type)
  }
})

test_that("each table package is found from the class of its container", {
  expect_equal(bones:::infer_type(fake_output("datatables html-widget html-widget-output")), "dt")
  expect_equal(bones:::infer_type(fake_output("reactable html-widget html-widget-output")), "reactable")
  expect_equal(bones:::infer_type(fake_output("shiny-html-output gt_shiny")), "gt")
  # rhandsontable is an htmlwidget, and an htmlwidget with no known class
  # gets the chart shape. The table class must win.
  expect_equal(
    bones:::infer_type(fake_output("rhandsontable html-widget html-widget-output")),
    "rhandsontable"
  )
  # A plain tableOutput() keeps the plain table shape.
  expect_equal(bones:::infer_type(fake_output("shiny-html-output shiny-table-output")), "table")
})

test_that("the real output functions give the right shape", {
  skip_if_not_installed("DT")
  skip_if_not_installed("reactable")
  skip_if_not_installed("gt")
  skip_if_not_installed("rhandsontable")

  expect_equal(bones:::infer_type(DT::DTOutput("a")), "dt")
  expect_equal(bones:::infer_type(reactable::reactableOutput("b")), "reactable")
  expect_equal(bones:::infer_type(gt::gt_output("c")), "gt")
  expect_equal(bones:::infer_type(rhandsontable::rHandsontableOutput("d")), "rhandsontable")
})

test_that("the rows and columns arguments apply to each table type", {
  for (type in table_types) {
    small <- as.character(bones_skeleton(type, rows = 3, cols = 2))
    big   <- as.character(bones_skeleton(type, rows = 9, cols = 5))
    expect_gt(count_bars(big), count_bars(small), label = type)
  }
})

test_that("a DT skeleton has the controls of DT around the table", {
  html <- as.character(bones_skeleton("dt", rows = 4, cols = 3))
  expect_match(html, "bones-dt-top", fixed = TRUE)
  expect_match(html, "bones-dt-search", fixed = TRUE)
  expect_match(html, "bones-dt-bottom", fixed = TRUE)
  expect_equal(count_matches(html, "bones-dt-page\""), 4L)
  expect_equal(count_matches(html, "bones-row"), 5L)          # 4 + header
})

test_that("a reactable skeleton has pages only when the rows need them", {
  # reactable shows 10 rows on a page by default.
  expect_false(grepl("bones-rt-pages", as.character(bones_skeleton("reactable", rows = 10))))
  expect_match(as.character(bones_skeleton("reactable", rows = 11)), "bones-rt-pages", fixed = TRUE)
  expect_equal(count_matches(as.character(bones_skeleton("reactable", rows = 5)), "bones-rt-row"), 6L)
})

test_that("a gt skeleton has a title, a spanner, a stub and a source note", {
  html <- as.character(bones_skeleton("gt", rows = 4, cols = 3))
  expect_match(html, "bones-gt-title", fixed = TRUE)
  expect_match(html, "bones-gt-spanner", fixed = TRUE)
  expect_equal(count_matches(html, "bones-gt-stub"), 5L)      # 4 + label
  expect_match(html, "bones-gt-note", fixed = TRUE)
})

test_that("an rhandsontable skeleton is a grid with row and column headers", {
  html <- as.character(bones_skeleton("rhandsontable", rows = 4, cols = 3))
  # One corner, three column headers, four row headers, twelve cells.
  expect_equal(count_matches(html, "bones-hot-corner"), 1L)
  expect_equal(count_matches(html, "bones-hot-colhead"), 3L)
  expect_equal(count_matches(html, "bones-hot-rowhead"), 4L)
  expect_equal(count_matches(html, "bones-hot-cell\""), 12L)
  expect_match(html, "grid-template-columns: 2.5rem repeat(3, 1fr);", fixed = TRUE)
})

test_that("default heights follow the measured size of each package", {
  # Measured in a browser with Bootstrap 5, the larger of Bootstrap 3 and 5.
  # DT: 53px of controls above, 40px rows with the header, 63px below.
  expect_equal(bones:::default_height("dt", rows = 6), "396px")
  # reactable: 38px rows with the header, and a small margin.
  expect_equal(bones:::default_height("reactable", rows = 6), "274px")
  # gt with a title, a spanner and a source note: 180px, and 38.5px for
  # each row. The measured table with 6 rows was 411px.
  expect_equal(bones:::default_height("gt", rows = 6), "411px")
  # rhandsontable: a 26px header and 24px rows, and a small margin.
  expect_equal(bones:::default_height("rhandsontable", rows = 6), "176px")
})

test_that("a DT output reserves the DT height, not the plain table height", {
  skip_if_not_installed("DT")
  html <- as.character(withBones(DT::DTOutput("dt")))
  expect_match(html, 'data-bones-type="dt"', fixed = TRUE)
  expect_match(html, "--bones-reserve: 396px", fixed = TRUE)
})
