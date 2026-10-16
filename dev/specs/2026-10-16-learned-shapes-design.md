# Learned shapes: design

Date: 2026-10-16. Status: approved in discussion, waiting for review of
this written spec.

## Goal

On a repeat visit, the skeleton of an output has the shape that the real
output had, with no arguments from the developer. A table with a title and
12 rows gets a skeleton with a title and 12 rows of bars. A block of text
gets one bar for each line. Three cards get three frames.

The first visit does not change: bones still guesses the shape from the
type of the output, as in 0.1.1.

## Decisions

These were decided in the discussion of 2026-10-16:

1. Every output can learn, not only tables. Charts are the exception (see
   "Which outputs learn").
2. Learning is on by default. It follows `remember`. `learn = FALSE` in
   `withBones()` or `bones_defaults()` turns it off.
3. Anything that the developer set wins. When `rows`, `cols`, `type` or
   `skeleton` is given, that output does not learn.
4. One stored layout per output. It is used only when the width of the
   wrapper is within 10% of the width at which it was recorded.
5. The layout is recorded as boxes (approach A). bones measures the boxes
   of the visible parts of the content, and draws a bar or a frame at each
   box. It has no reader for each package.
6. When the data changes, the most recent layout is kept.

Rejected:

- Functions for each package, such as `bones_gt()` and `bones_dt()`, with
  arguments that copy those packages. Too many exports to maintain.
- A structure for each family of output, such as "a title, 2 header rows,
  12 rows" (approach B). It covers only the outputs that bones knows.
- Both A and B (approach C). Two systems to maintain.

## Which outputs learn

`withBones()` writes `data-bones-learn="true"` on the wrapper when all of
these are true:

- `remember` is `TRUE`.
- `learn` is not `FALSE`.
- `rows`, `cols`, `type` and `skeleton` are all `NULL`.
- The output is not a chart: not `plotOutput()`, not a plotly, echarts4r
  or highcharter output, and not a chart type from the output class.

The decision is made in R. `bones.js` learns only for a wrapper with the
mark.

## Recording

When: at the same time as the height is stored now. That is 250ms after a
load ends with a value, so that a widget has drawn. Each load with a value
records again. A load that ends in an error records nothing, and the old
record stays.

What: bones walks the content of the wrapper (`.bones-content`) and
collects boxes. Each box is relative to the top left of the content.

- Text: one box for each line, from the rectangles of the text itself
  (`Range.getClientRects()` on each text node). A short line gives a short
  box. The text in table cells counts, which gives the rows of a table.
- Elements with no text: `img`, `input`, `select`, `textarea` and `button`
  give one box each.
- Frames: an element with a visible border, or a background that is not
  transparent, gives one frame box. Cards and value boxes are frames.

Skipped:

- Elements that are not displayed, that have `visibility: hidden`, or that
  have no width or no height.
- Boxes, or the parts of boxes, outside the wrapper.
- The skeleton itself.

Tidying:

- Two bar boxes on one line merge when they are less than 8px apart. One
  line is "on one line" with another when their tops and their heights
  differ by 2px or less.
- All numbers are rounded to whole pixels.
- The boxes are sorted from top to bottom, then from left to right.
- At most 150 boxes are kept: the first 150 in that order.

Nothing is stored, and any old record of the output is removed, when:

- there are fewer than 2 boxes, or
- one box covers more than 60% of the area of the content. This catches
  widgets that bones does not know, such as a map or a canvas.

## Storage

Key: `bones:layout:` + the path of the page + `:` + the id of the output.
This is the form of the keys for the height and the chart kind.

Value: JSON.

```json
{"v": 1, "w": 812, "h": 430, "b": [[0, 0, 240, 18, 0], [0, 30, 780, 14, 0], [0, 60, 380, 200, 1]]}
```

- `v`: the version of the format. A record with another version is
  ignored.
- `w`: the width of the wrapper when the layout was recorded, in px.
- `h`: the height of the content when the layout was recorded, in px.
- `b`: the boxes. Each is `[x, y, width, height, kind]`. `kind` is 0 for a
  bar and 1 for a frame.

A record holds numbers only. No text, value, class or id from the app goes
into it.

Size: 150 boxes take about 3 KB. Browsers allow about 5 MB for a site.

Every read and write is in a `try` block. Blocked storage, a full storage,
a record that does not parse, a record with a wrong shape and a record with
another version all mean "no layout".

A record of an output that is no longer on the page stays in the browser,
as a height record does now.

## Drawing

When: as the wrapper comes into the page, in the same code that restores
the height and the chart kind now. That is before the first paint, so the
built-in shape does not show first. A wrapper that a `renderUI()` inserts
is handled in the same way. A wrapper in a hidden tab has no width yet. It
tries again when its output starts to load, as the height does now.

Rule: the layout is drawn only when the record is valid and the width of
the wrapper is within 10% of `w`. Otherwise the built-in shape stays.

How: `bones.js` puts a new skeleton in place of `.bones-skeleton`:

- `div.bones-skeleton.bones-skeleton-learned`, with `position: relative`,
  a height of `h` px and `overflow: hidden`. It copies the attributes of
  the skeleton that it replaces, such as `aria-hidden`.
- The frames come first, then the bars, so that a bar is drawn over a
  frame.
- Each bar is a `div.bones-bar` with `position: absolute` at its box.
- Each frame is a `div.bones-learned-frame` with `position: absolute` at
  its box: a border of the colour of the skeleton, and no fill.

The reserved height of the wrapper (`--bones-reserve`) is set to `h`.

`.bones-bar` gives the colours, the corner radius and the animations,
including the values from `bones_defaults()`. The bars are in order from top
to bottom, so the cascade animation goes down the page.

In one session, the learned skeleton stays for later loads with
`stale = FALSE`. A layout recorded in the session is drawn on the next
visit, not at the next load. The shape thus does not change while the user
looks at it.

When the window becomes narrower while a learned skeleton shows, the boxes
keep their positions and `overflow: hidden` cuts them at the right. The
next load at the new width records a layout that fits.

## Changes to the code

R:

- `withBones(learn = NULL)`. `NULL` takes `getOption("bones.learn", TRUE)`.
  It is checked with `check_flag()`, as `remember` is.
- `bones_defaults(learn = NULL)`, which sets `bones.learn`.
- The mark `data-bones-learn` on the wrapper (see "Which outputs learn").

JavaScript (`inst/www/bones.js`), next to the height and kind code, in the
same style:

- `layoutKey(wrap)`, `readLayout(key)`, `recordLayout(wrap)`,
  `saveLayout(wrap)` and `restoreLayout(wrap)`.
- `saveLayout` runs where `saveHeight` runs. `restoreLayout` runs where
  `restoreHeight` runs.

CSS (`inst/www/bones.css`): about 10 lines for `.bones-skeleton-learned`,
`.bones-skeleton-learned > .bones-bar` and `.bones-learned-frame`.

## Testing

R unit tests, in `tests/testthat/test-learn.R`:

- The mark is there by default.
- The mark is not there with `learn = FALSE`, or with
  `bones_defaults(learn = FALSE)`.
- The mark is not there when `rows`, `cols`, `type` or `skeleton` is
  given.
- The mark is not there for `plotOutput()`, a plotly, an echarts4r or a
  highcharter output, or a chart type.
- The mark is not there when `remember = FALSE`.
- `learn` gets the same errors for a bad value as `remember`.

Browser tests with shinytest2, in a new app `tests/testthat/apps/learn/`.
The app has a table with a title and 12 rows, a block of text, three
cards, an output with one short word, an output with one large canvas, a
chart, and a table with `rows = 8`. A button changes the table to 4 rows,
and another makes an output fail.

1. After the first load, each output that learns has a valid record, with
   at least 2 boxes. The output with one word and the canvas have none.
2. No record holds any text from the app.
3. After a reload, while the outputs load, each output that learns shows
   `.bones-skeleton-learned`. The number of bars is the number in the
   record, and the first bar is at its recorded place, to 1px. The chart
   and the table with `rows = 8` show their built-in shapes.
4. With a window that is more than 10% narrower, a reload shows the
   built-in shape.
5. With storage that throws on each call, with a record that does not
   parse, and with a record of version 2, the page loads with no console
   error and shows the built-in shape.
6. After the table changes to 4 rows, a reload shows fewer bars.
7. A load that ends in an error does not change the record.

Each gate is broken once on purpose, to see that it fails: for example,
remove the width check, put text in a record, or let an output with
`rows` learn.

All existing tests, lint, spelling, the ASCII and LF checks, and
`R CMD check --as-cran` must pass, with 0 notes.

## Documentation

- `NEWS.md`: an entry in the development section.
- `README.md` and the Get Started article: a section "Learned shapes" that
  explains `learn`, the width rule, and that only numbers are stored.
- The `learn` argument in the help of `withBones()` and `bones_defaults()`.
  The help of `remember` says that it also turns on learning.

## Not in this version

- A layout for each screen size.
- Stretching a layout to a new width.
- Learning for charts.
- Removing old records of outputs that are gone.
