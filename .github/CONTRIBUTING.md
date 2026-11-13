# Contributing to bones

Thank you for your help. A clear bug report is a real contribution.

## Report a bug

Open an issue with a small example that shows the problem, and the output of `sessionInfo()`. Remove any real or patient data from the example.

## Change the code

1. Open an issue first for a large change, so that we can agree on the design.
2. Make a branch from `main`.
3. Add a test that fails without your change. A change in `bones.js` or `bones.css` needs a browser test (see `tests/testthat/test-app-*.R`).
4. Run `devtools::test()`, `devtools::check()` and `lintr::lint_package()`. The browser tests need a headless Chrome and `NOT_CRAN=true`.
5. Add a line to `NEWS.md` for a change that users can see.
6. Open a pull request. Commit subjects follow Conventional Commits, such as `fix: keep the reserve on a hidden tab`.

## Design rules

These rules keep the API small as bones grows.

### A new option for one shape goes into a shape object (#27)

`withBones()` already has arguments that apply to some shapes only: `rows`, `cols`, `lines` and `n`. Do not add more of them. A new option that only one shape uses goes into a shape object, not into `withBones()`.

Build the object when the first such option arrives. `type` then takes a string, as today, or the object:

```r
withBones(tableOutput("t"), type = "table", rows = 8)               # still works
withBones(tableOutput("t"), type = bones_shape("table", rows = 8))  # new
withBones(uiOutput("kpis"), type = bones_shape("value", n = 3))
```

- `bones_shape()` checks its own arguments against the shape, so an argument that does nothing for the shape is an error at once.
- `type` and `skeleton` then stop being exclusive: a custom placeholder is one more shape.
- The change adds and does not remove. `rows`, `cols`, `lines`, `n` and `skeleton` keep working.

The tidyverse design guide describes this pattern: <https://design.tidyverse.org/argument-clutter.html>

### bones has no server side

bones is a package of tags and one script. `shiny` is in Suggests only. A feature that changes a wrapper from outside, such as retry, takes an input id and lets bones.js act in the browser. It does not add a function that needs a live `session`.

### No style attributes

bones works under a strict Content-Security-Policy (`style-src 'self'`). Do not write a `style` attribute, in R or in JavaScript. Use classes, and set computed values with the CSSOM (`el.style.setProperty()`).

## Style

Follow the tidyverse style guide, with the base pipe `|>`. Write comments and documents in short, plain English.
