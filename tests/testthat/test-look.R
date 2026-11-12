test_that("bones_animations() lists the valid animations", {
  expect_equal(bones_animations(), c("wave", "pulse", "cascade", "sweep", "none"))
  for (a in bones_animations()) {
    expect_no_error(withBones(fake_output("shiny-text-output"), animation = a))
  }
})

test_that("speed and color apply to one output", {
  withr::local_options(bones.speed = NULL, bones.color = NULL)
  w <- withBones(fake_output("shiny-text-output"), speed = 0.8, color = "#dbeafe")
  style <- w$attribs[["data-bones-style"]]
  expect_match(style, "--bones-speed: 0.8s;", fixed = TRUE)
  expect_match(style, "--bones-color: #dbeafe;", fixed = TRUE)

  plain <- withBones(fake_output("shiny-text-output"))
  expect_false(grepl("--bones-speed", plain$attribs[["data-bones-style"]], fixed = TRUE))
  expect_false(grepl("--bones-color", plain$attribs[["data-bones-style"]], fixed = TRUE))
})

test_that("an argument is stronger than the session default", {
  withr::local_options(bones.speed = 2, bones.color = "red")
  w <- withBones(fake_output("shiny-text-output"), speed = 0.5, color = "blue")
  style <- w$attribs[["data-bones-style"]]
  expect_match(style, "--bones-speed: 0.5s;", fixed = TRUE)
  expect_match(style, "--bones-color: blue;", fixed = TRUE)
  expect_false(grepl("red", style, fixed = TRUE))

  # With no argument, the session default is used.
  style <- withBones(fake_output("shiny-text-output"))$attribs[["data-bones-style"]]
  expect_match(style, "--bones-speed: 2s;", fixed = TRUE)
  expect_match(style, "--bones-color: red;", fixed = TRUE)
})

test_that("bad speed and color give clear errors", {
  ui <- fake_output("shiny-text-output")
  for (bad in list(0, -1, NA_real_, "fast", c(1, 2))) {
    expect_error(withBones(ui, speed = bad), "`speed` must be a single positive number of seconds.",
                 fixed = TRUE)
  }
  for (bad in list("", NA_character_, 1, "red; display: none", c("a", "b"))) {
    expect_error(withBones(ui, color = bad), "`color` must be a single CSS value", fixed = TRUE)
  }
})

test_that("bones_auto() passes speed and color to each output", {
  w <- bones_auto(fake_output("shiny-text-output", id = "value"), speed = 3, color = "green")
  html <- as.character(w)
  expect_match(html, "--bones-speed: 3s;", fixed = TRUE)
  expect_match(html, "--bones-color: green;", fixed = TRUE)
})
