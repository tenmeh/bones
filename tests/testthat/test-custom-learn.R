test_that("custom learning needs an explicit TRUE, not a default", {
  withr::local_options(bones.learn = TRUE, bones.remember = TRUE)
  out <- fake_output("shiny-text-output")
  learned <- function(...) {
    htmltools::tagGetAttribute(
      withBones(out, skeleton = bones_block(), ...), "data-bones-learn"
    )
  }
  expect_null(learned())
  expect_null(learned(learn = NULL))
  expect_null(learned(learn = FALSE))
  expect_identical(learned(learn = TRUE), "true")
  withr::local_options(bones.learn = FALSE)
  expect_identical(learned(learn = TRUE), "true")
})

test_that("custom learning respects remember and the inferred type", {
  expect_warning(
    tag <- withBones(fake_output("shiny-text-output"),
                     skeleton = bones_block(), learn = TRUE, remember = FALSE),
    "needs `remember = TRUE`. The skeleton does not learn.", fixed = TRUE
  )
  expect_null(htmltools::tagGetAttribute(tag, "data-bones-learn"))
  expect_warning(
    tag <- withBones(fake_output("shiny-plot-output"),
                     skeleton = bones_block(), learn = TRUE),
    'a "plot" output cannot learn its shape', fixed = TRUE
  )
  expect_null(htmltools::tagGetAttribute(tag, "data-bones-learn"))
})

test_that("custom height is measured and estimated unless height is explicit", {
  out <- fake_output("shiny-text-output")
  tag <- withBones(out, skeleton = bones_block(height = 240))
  expect_identical(tag$attribs[["data-bones-measure-custom"]], "true")
  expect_identical(tag$attribs[["data-bones-remember"]], "true")
  tag <- withBones(out, skeleton = bones_block(), remember = FALSE)
  expect_identical(tag$attribs[["data-bones-measure-custom"]], "true")
  expect_null(tag$attribs[["data-bones-remember"]])
  tag <- withBones(out, skeleton = bones_block(), height = 100, learn = TRUE)
  expect_null(tag$attribs[["data-bones-measure-custom"]])
  expect_null(tag$attribs[["data-bones-remember"]])
  expect_identical(tag$attribs[["data-bones-learn"]], "true")
  expect_null(withBones(out)$attribs[["data-bones-measure-custom"]])
})
