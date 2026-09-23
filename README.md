# bones

<!-- badges: start -->
[![R-CMD-check](https://github.com/tenmeh/bones/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/tenmeh/bones/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**Content-shaped loading placeholders for Shiny outputs.**

A spinner tells the user to wait. A skeleton tells the user what is coming.

```r
library(shiny)
library(bones)

ui <- fluidPage(
  withBones(plotOutput("chart")),
  withBones(tableOutput("results"), rows = 8)
)
```

That is all. The shape comes from the output that you wrap.

## Installation

```r
# install.packages("remotes")
remotes::install_github("tenmeh/bones")
```

Then run the demo. It shows the difference:

```r
shiny::runApp(system.file("examples/demo", package = "bones"))
```

## The idea

A spinner gives one piece of information: *something happens*. A skeleton
also shows the shape of the content that comes next. The page does not look
empty, and the eye of the user can go to the place where the content will
be.

`bones` gets that shape from the output that you give it:

| Output | Placeholder |
|---|---|
| `plotOutput()`, `imageOutput()` | columns on an axis. Use `type` for another kind of chart. |
| `tableOutput()` | a header row and body rows |
| `DT::DTOutput()` | the controls of DT: "Show entries", search, info and pages |
| `reactable::reactableOutput()` | rows with thin lines, and pages for more than 10 rows |
| `gt::gt_output()` | a title, a spanner, a label column and a source note |
| `rhandsontable::rHandsontableOutput()` | a spreadsheet grid with row and column headers |
| `textOutput()`, `verbatimTextOutput()` | lines of text, with a short last line |
| `uiOutput()` | lines of text. Use `type` for a different shape. |

You can change each of these:

```r
withBones(uiOutput("cards"),  type = "cards", n = 4)
withBones(uiOutput("kpis"),   type = "value", n = 3, height = "90px")
withBones(plotOutput("map"),  height = "600px", animation = "pulse")
```

### Chart shapes

A chart can have the shape of its kind:

```r
withBones(plotOutput("sales"),  type = "bar")
withBones(plotOutput("trend"),  type = "line")
withBones(plotOutput("growth"), type = "area")
withBones(plotOutput("fit"),    type = "scatter")
withBones(plotOutput("ages"),   type = "histogram")
withBones(plotOutput("share"),  type = "pie")
withBones(plotOutput("corr"),   type = "heatmap")
```

`bones` cannot find the kind for you. `plotOutput()` only says that a plot
will be there. `renderPlot()` decides the kind later, on the server. With no
`type`, a plot gets the bar shape.

### Table shapes

A table package is different: its output says which package it is. So
`bones` gives DT, reactable, gt and rhandsontable their own shape with no
`type`:

```r
withBones(DT::DTOutput("patients"), rows = 10)
withBones(gt::gt_output("summary"), rows = 8, cols = 5)
```

Set `rows` to the number of rows on a page. DT and reactable show 10 by
default. The space kept for each package was measured in a browser, so the
page does not move when the table arrives.

## Two things that a spinner cannot do

### It keeps the content that the user reads

On the **first** load, the user sees a skeleton. When the output calculates
**again**, the user does not. The old content stays on the screen, dimmed.

This is on purpose. The user is possibly in the middle of a chart. Grey
rectangles in its place would remove information. The old numbers are an
answer, and a better answer replaces them a moment later. A skeleton would
be worse than the old content.

All outputs show the recalculation at the same time. This is true when
several outputs use one slow reactive, and Shiny calculates them one after
the other.

Turn it off for one output if you prefer a skeleton:

```r
withBones(plotOutput("chart"), stale = FALSE)
```

### It keeps the space of the content

Until the content arrives, the placeholder keeps the height of the output.
The page thus does not move when the content arrives. If the output sets a
height, the placeholder uses it: `plotOutput()` sets `400px` by default. If
not, the height comes from `rows`, `lines` or `n`, or you can set `height`
yourself.

When the content arrives, the content sets the height. If the estimate was
too tall, the space closes. No gap stays under the content.

## A note about the implementation

The content is hidden with `visibility: hidden`, not with `display: none`.
The skeleton is on top of the content, with absolute position.

This is more important than it looks. An element with `display: none` has
a width of zero. `renderPlot()` makes its image at the width of the
element. An output hidden in that way thus gets a plot at the wrong size.
Shiny keeps that image, and it looks broken until something causes a new
render. When the output keeps its box and only the paint is hidden, this
problem cannot occur.

## Theming

```r
bones_defaults(
  animation = "wave",      # or "pulse", or "none"
  color     = "#e9ecef",
  highlight = "#f8f9fa",
  radius    = "0.5rem",
  speed     = 1.4          # seconds for each cycle
)
```

The default colours are greys made from `rgba(128, 128, 128, ...)`. They
thus work on light themes and on dark themes with no change. Users who ask
their system to reduce motion get no animation. A placeholder that moves is
exactly what that setting is for.

## Placeholders on their own

When you need a placeholder where there is no Shiny output:

```r
bones_skeleton("table", rows = 5, cols = 3)
bones_skeleton("text", lines = 4)
```

The placeholder brings its stylesheet, and it uses the animation and the
colours from `bones_defaults()`.

## Accessibility

The placeholder has `aria-hidden="true"`. Shiny already sets `aria-busy` on
an output while it calculates, and treats outputs as live regions. A message
from the placeholder as well would only repeat that for users of a screen
reader.

## Development

`man/` is made by roxygen2 and is in the repository, so an install from
GitHub has the help pages. After a change to the roxygen comments:

```r
devtools::document()
devtools::test()
devtools::check()
```

The browser tests in `tests/testthat/test-app-smoke.R` need a headless
Chrome. They skip on CRAN, and when no browser can start. Set
`NOT_CRAN=true` to run them.

## License

MIT
