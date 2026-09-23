# bones

**Content-shaped loading placeholders for Shiny outputs.**

Spinners tell users to wait. Bones tell them what's coming.

```r
library(shiny)
library(bones)

ui <- fluidPage(
  withBones(plotOutput("chart")),
  withBones(tableOutput("results"), rows = 8)
)
```

That's it. The shape is inferred from the output you wrap.

## Installation

```r
# install.packages("remotes")
remotes::install_github("tanmaychanda/bones")
```

Then run the demo, which is built to show the difference:

```r
shiny::runApp(system.file("examples/demo", package = "bones"))
```

## The idea

A spinner communicates one bit: *something is happening*. A skeleton
communicates the shape of what's about to appear, so the page stops feeling
empty and the user's eye can settle where the content will be.

`bones` infers that shape from the output you hand it:

| Output | Placeholder |
|---|---|
| `plotOutput()`, `imageOutput()` | columns on an axis |
| `tableOutput()`, `DT::DTOutput()` | a header row and body rows |
| `textOutput()`, `verbatimTextOutput()` | lines of text, last one short |
| `uiOutput()` | lines — pass `type` for anything else |

Override any of it:

```r
withBones(uiOutput("cards"),  type = "cards", n = 4)
withBones(uiOutput("kpis"),   type = "value", n = 3, height = "90px")
withBones(plotOutput("map"),  height = "600px", animation = "pulse")
```

## Two things it does that a spinner can't

### It keeps content you're already reading

On **first** load you get a skeleton. On **re**calculation you don't — the
previous content stays on screen and dims instead.

This is deliberate. Replacing a chart someone is mid-way through reading with
grey rectangles takes information away; the old numbers were at least *a*
answer, and a moment later they'll be replaced by a better one. Reverting to a
skeleton is strictly worse than leaving the stale content up.

Opt out per output if you disagree:

```r
withBones(plotOutput("chart"), stale = FALSE)
```

### It reserves the layout

The placeholder occupies the output's real height, so nothing on the page jumps
when content lands. Where the output declares a height — `plotOutput()` defaults
to `400px` — that height is used. Otherwise it's derived from `rows`, `lines` or
`n`, or you can set `height` yourself.

## Implementation note

The content is hidden with `visibility: hidden`, not `display: none`, and the
skeleton is absolutely positioned on top of it.

This matters more than it looks. A `display: none` element reports a width of
zero, and `renderPlot()` sizes the image it generates from the element's
measured width — so hiding the output that way produces a plot rendered at the
wrong size, which then gets cached and looks broken until something forces a
redraw. Keeping the box and hiding only the paint avoids the whole class of bug.

## Theming

```r
bones_defaults(
  animation = "wave",      # or "pulse", or "none"
  color     = "#e9ecef",
  highlight = "#f8f9fa",
  radius    = "0.5rem",
  speed     = 1.4          # seconds per cycle
)
```

Defaults are greys built from `rgba(128, 128, 128, …)`, so they work on light
and dark themes without configuration. Animation is disabled automatically for
users who have asked their system to reduce motion — a placeholder that throbs
is exactly what that setting is about.

## Standalone placeholders

For the times you need a placeholder somewhere a Shiny output isn't:

```r
bones_skeleton("table", rows = 5, cols = 3)
bones_skeleton("text", lines = 4)
```

Pair it with `bones_dependency()` so the stylesheet comes along.

## Accessibility

The placeholder is `aria-hidden="true"`. Shiny already sets `aria-busy` on an
output while it recalculates and treats outputs as live regions, so announcing
the placeholder too would just be duplicate noise for screen reader users.

## Building from source

`man/` is generated, not checked in:

```r
devtools::document()
devtools::test()
devtools::check()
```

## License

MIT
