# Learned Shapes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **In this repo the worker is Codex, through the codex-delegate skill.** Codex cannot run R in its sandbox: it cannot read the R library. Write the code and the tests; the reviewer runs every "Run" step and sends back the results.

**Goal:** On a repeat visit, the skeleton of an output has the shape of the content that the output showed last time.

**Architecture:** R marks each wrapper that may learn (`data-bones-learn="true"`). After a load with a value, `bones.js` measures the boxes of the visible content and stores them as numbers in `localStorage`. On the next visit, before the first paint, it draws a bar or a frame at each stored box, in place of the built-in skeleton, when the width is within 10%.

**Tech Stack:** R (htmltools, testthat 3, shinytest2), plain ES5 JavaScript in `inst/www/bones.js` (no build step, jQuery from Shiny), CSS in `inst/www/bones.css`.

**Spec:** `dev/specs/2026-10-16-learned-shapes-design.md`. Read it before you start. This plan says how; the spec says what and why.

## Global Constraints

- R: `"/c/Program Files/R/R-4.6.1/bin/x64/Rscript.exe"`. Browser tests need `NOT_CRAN=true`.
- No new dependency in `DESCRIPTION`. No change to any exported function other than `withBones()` and `bones_defaults()`.
- JavaScript stays ES5, like the rest of `bones.js`: `var`, `function`, no arrow functions, no `let`/`const`, no classes.
- Every `localStorage` access is inside `try`/`catch`. A failure means "no layout".
- A stored record holds numbers only. Exact format: `{"v": 1, "w": <int>, "h": <int>, "b": [[x, y, width, height, kind], ...]}`, `kind` 0 = bar, 1 = frame.
- Values from the spec: key prefix `bones:layout:`; at most 150 boxes; merge bars less than 8px apart on one line; "one line" = tops and heights differ by 2px or less; frames at least 24px in width and in height; no record when fewer than 2 boxes or one box covers more than 60% of the content area; width tolerance 10%.
- Text in comments, documentation and test names: short sentences, ASCII only, LF line endings, en-GB spelling (the package has `Language: en-GB`).
- The base pipe `|>` if a pipe is needed.
- Do not commit, push, or change git state. The reviewer commits after each task.

## Review Focus

1. **An existing test app reloads, and its outputs now learn.** Apps in `tests/testthat/apps/` with outputs that give no `type` will start to store and draw layouts. Expected: the existing tests still pass. Task 5 runs the whole suite. The `remember` app gives `type = "text"`, so it does not learn.
2. **The window narrows while a learned skeleton shows.** Expected: no horizontal scroll bar, because the skeleton cuts its bars at the right (`overflow: hidden`). Test in Task 3.
3. **`bones_auto()` with `rows = 8` in its `...`.** Expected: no output learns, because the developer set the shape. Test in Task 1.
4. **An output inside a tab that is hidden on the first visit.** Expected: no layout is drawn at width 0, and the layout is drawn when the output starts to load in a tab that shows. Covered by calling `restoreLayout()` from `onInvalidated()` (Task 3).
5. **An output with a scroll area, such as a long `verbatimTextOutput()`.** Expected: only the boxes inside the visible area of the content count, and nothing outside the wrapper is stored. Covered by the clip step in Task 2.

---

### Task 1: The `learn` option and the wrapper mark (R)

**Files:**
- Modify: `R/with-bones.R` (`withBones()`, `bones_defaults()`, their roxygen)
- Modify: `R/skeleton.R` (add `learnable_types()` next to `table_types()`)
- Create: `tests/testthat/test-learn.R`
- Regenerate: `man/withBones.Rd`, `man/bones_defaults.Rd` (roxygen)

**Interfaces:**
- Produces: the attribute `data-bones-learn="true"` on the `.bones-wrap` div, or no attribute at all. Tasks 2 and 3 read only this attribute.
- Produces: `learnable_types()` returns `c("text", "table", "cards", "value", table_types())`.
- Produces: `withBones(..., learn = NULL)` as the last argument, after `skeleton`. `bones_defaults(..., learn = NULL)` as its last argument, setting `options(bones.learn = )`.

- [ ] **Step 1: Write the failing tests in `tests/testthat/test-learn.R`**

Use `fake_output()` from `helper-bones.R` for outputs, as the other unit tests do. One helper:

```r
learns <- function(tag) identical(htmltools::tagGetAttribute(tag, "data-bones-learn"), "true")
```

Tests (one `test_that()` each; restore options with `withr::local_options()`):

- "an output with no shape arguments learns": `withBones(fake_output("shiny-html-output"))`, `withBones(shiny::tableOutput("t"))`, `withBones(shiny::textOutput("x"))` all learn.
- "an output does not learn when the developer sets its shape": each of `rows = 8`, `cols = 3`, `lines = 2`, `n = 4`, `type = "table"`, `skeleton = bones_block()` gives `learns() == FALSE`.
- "a chart does not learn": `withBones(shiny::plotOutput("p"))`, `withBones(fake_output("plotly html-widget-output"))` do not learn.
- "learn = FALSE and remember = FALSE turn learning off": `withBones(shiny::tableOutput("t"), learn = FALSE)`, `withBones(shiny::tableOutput("t"), remember = FALSE)`, and with `bones_defaults(learn = FALSE)` in force, `withBones(shiny::tableOutput("t"))` do not learn.
- "learn = TRUE does not override a shape that the developer set": `withBones(shiny::tableOutput("t"), rows = 8, learn = TRUE)` does not learn.
- "bones_auto() passes the shape arguments on": in `bones_auto(shiny::fluidPage(shiny::tableOutput("a")), rows = 8)` the wrapper does not learn; in `bones_auto(shiny::fluidPage(shiny::tableOutput("a")))` it learns. Find the wrapper with `htmltools::tagQuery(x)$find(".bones-wrap")$selectedTags()[[1]]`.
- "learn must be TRUE or FALSE": `expect_error(withBones(shiny::tableOutput("t"), learn = NA), "`learn` must be TRUE or FALSE.", fixed = TRUE)`, the same for `"yes"`, and for `bones_defaults(learn = 1)`.

- [ ] **Step 2: Run the tests and see them fail**

Run: `"/c/Program Files/R/R-4.6.1/bin/x64/Rscript.exe" -e 'devtools::test(filter = "learn")'`
Expected: FAIL. `learn` is an unused argument.

- [ ] **Step 3: Implement it**

In `withBones()`:
- Before the input checks, record which shape arguments were given: `shaped <- !missing(rows) || !missing(cols) || !missing(lines) || !missing(n) || !is.null(type) || !is.null(skeleton)`. `rows` and `cols` have defaults (6 and 4), so `missing()` is the only way to tell. `lines` and `n` count too: they set the shape (spec decision 3, "anything that the developer set wins").
- `learn <- learn %||% getOption("bones.learn", TRUE)`, then `check_flag(learn, "learn")`, next to `remember`.
- `learnable <- isTRUE(remember) && isTRUE(learn) && !shaped && type %in% learnable_types()`. Compute it after `type` is inferred.
- Add `` `data-bones-learn` = if (learnable) "true" `` to the wrapper, after `data-bones-remember-kind`, with a one-line comment in the style of its neighbours.

In `bones_defaults()`: add `learn = NULL`, check it with `check_flag()` when not NULL, and set `bones.learn` in the same `options()` call as `bones.remember`.

Roxygen: `@param learn` for both functions. For `withBones()`: "`TRUE` stores the shape of the content in the browser of the user, and the first skeleton of the next visit has that shape. Only numbers are stored: the place and the size of each line of text, image and frame. It applies only when you do not give `type`, `rows`, `cols`, `lines`, `n` or `skeleton`, and not to charts. It needs `remember`. The default is `TRUE`; see [bones_defaults()]." Add one sentence to `@param remember`: "It also turns on `learn`." For `bones_defaults()`: "The default for the `learn` argument of [withBones()]."

Run `roxygen2::roxygenise()`.

- [ ] **Step 4: Run the tests and see them pass**

Run: `"/c/Program Files/R/R-4.6.1/bin/x64/Rscript.exe" -e 'devtools::test(filter = "learn|with-bones|defaults|auto")'`
Expected: PASS, 0 failures.

- [ ] **Step 5: Commit** (reviewer)

`feat(learn): mark the outputs that may learn their shape`

---

### Task 2: Record and store the layout (JS)

**Files:**
- Modify: `inst/www/bones.js` (a new section after "Remember the real height", and one change in `markLoaded()`)
- Create: `tests/testthat/apps/learn/app.R`
- Modify: `tests/testthat/test-app-smoke.R` (new tests at the end)

**Interfaces:**
- Consumes: `data-bones-learn="true"` (Task 1). `data-bones-id`, as `heightKey()` uses it.
- Produces, in `bones.js` (Task 3 uses them):
  - `var LAYOUT_PREFIX = "bones:layout:";`
  - `function learns(wrap)` returns `true` when `data-bones-learn` is `"true"`.
  - `function layoutKey(wrap)` returns `LAYOUT_PREFIX + location.pathname + ":" + id`, or `null` with no id. The same form as `heightKey()`.
  - `function recordLayout(wrap)` returns a record `{v: 1, w, h, b}`, or `null` when the spec says to store nothing.
  - `function saveLayout(wrap)` stores the record, or removes the key when `recordLayout()` gives `null`.
- Produces: the test app `apps/learn` (Task 3 and Task 4 use it). Its outputs and their ids are listed in Step 1.

- [ ] **Step 1: Write the test app `tests/testthat/apps/learn/app.R`**

A header comment in the style of `apps/remember/app.R`. Each output waits 1.5 s with `Sys.sleep(1.5)`, so a test can look at the skeleton before the content arrives. Each output is in `div(id = "box-<id>", withBones(...))`:

| id | UI | Content |
|---|---|---|
| `tbl` | `tableOutput("tbl")` | `head(mtcars[, 1:5], n())` where `n <- reactiveVal(12L)` |
| `txt` | `uiOutput("txt")` | three `p()` of about 30 words each |
| `cards` | `uiOutput("cards")` | three `div(style = "border: 1px solid #ccc; border-radius: 8px; padding: 12px; height: 90px;", h4("Card"), p("Some text"))` side by side in a `div(style = "display: flex; gap: 12px;")` |
| `word` | `textOutput("word")` | `"Hi"` |
| `canvas` | `uiOutput("canvas")` | `tagList(tags$canvas(width = 600, height = 300, style = "display: block;"), p("A caption"))`: two boxes, and the canvas covers more than 60% |
| `chart` | `plotOutput("chart", height = "200px")` | `plot(1:10)` |
| `fixed` | `tableOutput("fixed")` with `rows = 8` | `head(mtcars[, 1:3], 8)` |
| `fail` | `uiOutput("fail")` | `tagList(p("first value"), p("second line"))`, but `stop("planned failure")` when `input$break_it > 0` |

Two buttons: `actionButton("fewer", "Fewer rows")` sets `n(4L)`; `actionButton("break_it", "Break")`.

- [ ] **Step 2: Write the failing browser tests at the end of `test-app-smoke.R`**

Follow the pattern of "the real height is remembered for the next visit": `local_app_driver(test_path("apps", "learn"), name = "bones-learn-smoke", wait = FALSE, load_timeout = 45000L, timeout = 15000L)`, then `localStorage.clear()` and `location.reload()`, then wait with `app$wait_for_js()` for `.bones-wrap.bones-loaded` to count 8, then `Sys.sleep(0.6)` (the record is written 250 ms after the load).

A helper in the test file:

```r
stored_layouts <- function(app) {
  app$get_js("
    var out = {};
    Object.keys(localStorage).forEach(function (k) {
      if (k.indexOf('bones:layout:') === 0) out[k.split(':').pop()] = localStorage.getItem(k);
    });
    out;
  ")
}
```

Tests:
- "a layout is stored for each output that learns": the names of `stored_layouts(app)` are exactly `c("cards", "fail", "tbl", "txt")` (sorted). `word` has one box and `canvas` has one box over 60%, so neither is stored. Parse each with `jsonlite::fromJSON(x, simplifyVector = FALSE)` (jsonlite comes with shinytest2): `v == 1`; `w > 0`; `h > 0`; `length(b) >= 2` and `<= 150`; each box has 5 numbers, the last one 0 or 1. `tbl` has at least 13 boxes (12 rows and a header). `cards` has exactly 3 boxes of kind 1.
- "a stored layout holds no text from the app": each stored string matches `^[0-9,\\[\\]{}\":vwhb -]*$`, and none contains `"Card"`, `"Mazda"`, `"Hi"` or `"mpg"`.
- "an error does not change a stored layout": read the `fail` record, click `break_it`, wait 2 s, and expect the `fail` record to be unchanged.

- [ ] **Step 3: Run the tests and see them fail**

Run: `NOT_CRAN=true "/c/Program Files/R/R-4.6.1/bin/x64/Rscript.exe" -e 'devtools::test(filter = "app-smoke")'`
Expected: FAIL. No `bones:layout:` keys.

- [ ] **Step 4: Implement recording in `bones.js`**

`recordLayout(wrap)`, step by step, with `content = wrap.querySelector(".bones-content")` and `origin = content.getBoundingClientRect()`:

1. **Bars from text.** A `document.createTreeWalker(content, NodeFilter.SHOW_TEXT)` over the text nodes. Skip a node whose text is only white space, and a node whose parent element has no client rects (`display: none`) or a computed `visibility` of `hidden`. For each node, a `Range` with `selectNodeContents(node)`, then `range.getClientRects()`: one box per rect.
2. **Bars from elements with no text.** `content.querySelectorAll("img, input, select, textarea, button, canvas, svg")`. The spec names `img`, `input`, `select`, `textarea` and `button`; `canvas` and `svg` are added so that a widget with no text counts for the 60% rule: one box each from `getBoundingClientRect()`. Skip an `svg` inside a `button` (an icon). A button gives one box; its own text is then skipped: skip a text node that has a `button` ancestor.
3. **Frames.** For each element in `content.querySelectorAll("*")` that is not a table part (`TABLE`, `THEAD`, `TBODY`, `TFOOT`, `TR`, `TH`, `TD`), and whose box is at least 24px wide and 24px high: it is a frame when its computed style has a border width greater than 0 and a border style not `none` on all four sides, or a `background-color` whose alpha is not 0 and that differs from the computed `background-color` of its parent element. Kind 1.
4. **Make each box relative and clip it.** `x = left - origin.left`, `y = top - origin.top`. Clip to `0 <= x <= origin.width` and `0 <= y <= origin.height`. Drop a box with no width or no height after the clip. Round all four numbers with `Math.round()`.
5. **Sort** by `y`, then by `x`.
6. **Merge bars.** Walk the sorted bars. Merge a bar into the one before it when `Math.abs(dy) <= 2`, `Math.abs(dh) <= 2`, and the gap from the right end of the one before to the left of this one is less than 8. The merged box spans both. Frames are not merged.
7. **Decide.** Return `null` when there are fewer than 2 boxes, or when one box has an area greater than 0.6 times `origin.width * origin.height`. Otherwise keep the first 150 boxes in the sorted order. Then put the frames before the bars, each group still in the sorted order, so that a bar is drawn over a frame. Return `{v: 1, w: Math.round(wrap.getBoundingClientRect().width), h: Math.round(origin.height), b: boxes}`.

`saveLayout(wrap)`: return unless `learns(wrap)` and the wrapper is `bones-loaded`. Then `setItem(key, JSON.stringify(record))`, or `removeItem(key)` for `null`, in a `try`.

In `markLoaded()`, the timer that calls `saveHeight(wrap)` calls `saveLayout(wrap)` too. Do not add a second timer.

A section comment at the top, in the style of "Remember the real height": what is stored, when, and that only numbers are stored.

- [ ] **Step 5: Run the tests and see them pass**

Run: `NOT_CRAN=true "/c/Program Files/R/R-4.6.1/bin/x64/Rscript.exe" -e 'devtools::test(filter = "app-smoke")'`
Expected: PASS, all tests in the file.

- [ ] **Step 6: Commit** (reviewer)

`feat(learn): record the boxes of the content after a load`

---

### Task 3: Draw the learned skeleton (JS and CSS)

**Files:**
- Modify: `inst/www/bones.js` (the layout section, `restoreAll()`, `onInvalidated()`)
- Modify: `inst/www/bones.css` (a new section "learned shape", after "your own placeholder")
- Modify: `tests/testthat/test-app-smoke.R`

**Interfaces:**
- Consumes: `learns()`, `layoutKey()` (Task 2). The record format (Global Constraints).
- Produces: `function readLayout(key)` returns a valid record or `null`. `function restoreLayout(wrap)`. The class `bones-skeleton-learned` on the drawn skeleton, and `bones-learned-frame` on a frame. Task 4 tests these names.

- [ ] **Step 1: Write the failing browser tests**

Same app and pattern as Task 2. After the first visit has stored its layouts, `location.reload()`, `Sys.sleep(0.5)`, and read the skeletons while the content still loads (1.5 s):

- "the next visit draws the learned shape": for `tbl`, `txt` and `cards`, the wrapper's `:scope > .bones-skeleton` has the class `bones-skeleton-learned`. The number of its `.bones-bar` children plus `.bones-learned-frame` children equals the length of `b` in the record. The first child's `style.left` and `style.top` equal `b[[1]][[1]]` and `b[[1]][[2]]` with `"px"` (an exact match: the values are whole pixels). The wrapper keeps `h` px: its `getBoundingClientRect().height`, rounded, is within 1 of `h`.
- "a chart, an output with rows, and outputs with no layout keep their built-in shape": `chart`, `fixed`, `word` and `canvas` have no `.bones-skeleton-learned`.
- "a much narrower window draws the built-in shape": `app$set_window_size(width = round(0.8 * w0), height = 900)`, with `w0` as in the next test, reload, and `tbl` has no `.bones-skeleton-learned`. Then restore the size.
- "the newest layout wins": click `fewer`, wait until `#tbl tbody tr` counts 4, `Sys.sleep(0.6)`, reload, and `tbl` draws fewer boxes than on the first reload.
- "a narrower window does not scroll the page sideways": read the window width `w0` with `app$get_js("window.innerWidth")`, `app$set_window_size(width = round(0.95 * w0), height = 900)` (within 10%, so the layout is drawn at its old width), reload, and while the learned skeleton shows, `document.documentElement.scrollWidth <= window.innerWidth`.

- [ ] **Step 2: Run the tests and see them fail**

Run: `NOT_CRAN=true "/c/Program Files/R/R-4.6.1/bin/x64/Rscript.exe" -e 'devtools::test(filter = "app-smoke")'`
Expected: FAIL. No `.bones-skeleton-learned`.

- [ ] **Step 3: Implement drawing**

`readLayout(key)`: parse in a `try`. Return the record only when `v === 1`, `w` and `h` are finite and greater than 0, `b` is an array of at most 150 entries, and each entry is an array of 5 finite numbers whose last one is 0 or 1. Otherwise `null`.

`restoreLayout(wrap)`: in the form of `restoreHeight()`. Return when `wrap._bonesLayoutRestored`, when `!learns(wrap)`, or when the wrapper has `bones-has-loaded`. Read the width; when it is not greater than 0, return without setting the flag (a hidden tab tries again). Set `wrap._bonesLayoutRestored = true`. Read the record; draw it only when `Math.abs(width - record.w) <= 0.1 * record.w`. To draw it:
- A new `div` with the classes `bones-skeleton bones-skeleton-learned`. Copy each attribute of the old `:scope > .bones-skeleton` except `class` (so `aria-hidden` is kept).
- For each box, a `div` with the class `bones-bar` (kind 0) or `bones-learned-frame` (kind 1), and an inline `left`, `top`, `width` and `height` in px.
- `wrap.replaceChild(newSkeleton, oldSkeleton)`, and `wrap.style.setProperty("--bones-reserve", record.h + "px")`.

Call `restoreLayout()` in `restoreAll()` for the node and for each `.bones-wrap[data-bones-learn]` in it, after the height. Call it in `onInvalidated()` after `restoreHeight(wrap)`.

CSS, in `bones.css`:

```css
/* --- learned shape --------------------------------------------------------- */

/* A skeleton drawn from the boxes of the content of the last visit. It keeps
   the place of every skeleton (on top of the content), but not its flex
   layout and its padding: each box has its own place, in px. */
.bones-skeleton-learned {
  display: block;
  padding: 0;
}

.bones-skeleton-learned > .bones-bar,
.bones-learned-frame {
  position: absolute;
}

.bones-learned-frame {
  box-sizing: border-box;
  border: 1px solid var(--bones-color);
  border-radius: var(--bones-radius);
}
```

The `overflow: hidden` of `.bones-wrap > .bones-skeleton` already cuts boxes at the right.

- [ ] **Step 4: Run the tests and see them pass**

Run: `NOT_CRAN=true "/c/Program Files/R/R-4.6.1/bin/x64/Rscript.exe" -e 'devtools::test(filter = "app-smoke")'`
Expected: PASS.

- [ ] **Step 5: Commit** (reviewer)

`feat(learn): draw the learned shape on the next visit`

---

### Task 4: Storage that fails

**Files:**
- Modify: `tests/testthat/test-app-smoke.R`
- Modify: `inst/www/bones.js` only if a test fails

**Interfaces:**
- Consumes: the test app and the class names of Tasks 2 and 3.

- [ ] **Step 1: Write the tests**

The script must be in place before `bones.js` runs, so use the Chromote session of the app: `app$get_chromote_session()$Page$addScriptToEvaluateOnNewDocument(source = js)`, then reload.

- "storage that throws gives the built-in shape and no error": `js` replaces `Storage.prototype.getItem`, `setItem` and `removeItem` with functions that throw `new Error("blocked")`. After a reload, while the content loads: no `.bones-skeleton-learned` anywhere. After the load: `expect_no_shiny_errors(app)`, and the browser log (`app$get_logs()`) has no line with `level == "error"` from the page.
- "a record that does not parse, or of another version, is ignored": with no stub, after a first visit, `localStorage.setItem` the `tbl` key to `"{"`, the `txt` key to the `txt` record with `"v":2`, and the `cards` key to a record with a box of 4 numbers. Reload. None of the three draws `.bones-skeleton-learned`. No console error.

Use a new `local_app_driver()` for each test, so the stub of one test does not stay in the next.

- [ ] **Step 2: Run the tests**

Run: `NOT_CRAN=true "/c/Program Files/R/R-4.6.1/bin/x64/Rscript.exe" -e 'devtools::test(filter = "app-smoke")'`
Expected: PASS when Tasks 2 and 3 followed the spec. A failure here is a bug in `readLayout()` or a missing `try`: fix it in `bones.js`.

- [ ] **Step 3: Commit** (reviewer)

`test(learn): storage that fails gives the built-in shape`

---

### Task 5: Documentation, and the whole check

**Files:**
- Modify: `NEWS.md` (the "development version" section)
- Modify: `README.md` (a section "Learned shapes" after "Your own placeholder")
- Modify: `vignettes/articles/get-started.Rmd` (a short section in the same place)
- Modify: `inst/WORDLIST` only for a real new word, with `spelling::update_wordlist()`

- [ ] **Step 1: Write the docs**

NEWS entry, one bullet: what learning does, that it is on by default, `learn = FALSE`, and when it does not apply.

README and article, the same content, about 15 lines:
- The first visit uses the shape from the output type. After it, each output that learns stores the boxes of its content, and the next visit draws them.
- When it applies: no `type`, `rows`, `cols`, `lines`, `n` or `skeleton`, not a chart, and `remember` on.
- The width rule: within 10% of the width at which it was stored.
- Only numbers are stored. No text from the app.
- `withBones(x, learn = FALSE)` and `bones_defaults(learn = FALSE)`.

- [ ] **Step 2: Run the whole check** (reviewer)

Run, in this order:
1. `NOT_CRAN=true` full suite: `devtools::test()`. Expected: 0 failed, 0 skipped. Review Focus item 1: the other test apps must still pass.
2. `lintr::lint_package()`. Expected: 0 lints.
3. `spelling::spell_check_package()`. Expected: no errors.
4. ASCII and LF check of every changed file.
5. `R CMD check --as-cran` on a tarball from `git archive`. Expected: 0 errors, 0 warnings, 0 notes.
6. Break each gate once, and see it fail: remove the width check in `restoreLayout()`; put the text of the node into a box in `recordLayout()`; let an output with `rows` learn. Then restore.

- [ ] **Step 3: Commit** (reviewer)

`docs(learn): explain learned shapes`
