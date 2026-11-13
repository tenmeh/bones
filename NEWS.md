# bones (development version)

* `withBones()` gains `speed` and `color`, for one output. `bones_defaults()`
  still sets them for the whole session.
* `bones_animations()` lists the valid animations.
* The colours can be set in CSS, with or without Bootstrap. `--bones-color`,
  `--bones-radius` and the other properties now work on `:root` and on a
  container. Two new properties, `--bones-text` and `--bones-surface`, set
  the colours that the others are made from. With no Bootstrap 5 theme, the
  skeleton takes the text colour of the page, not a fixed grey.
* `withBones(retry = "id")` adds a Try again button to the error panel (#20).
* `withBones(hold = "refresh")` shows the skeleton when an input changes.
  JavaScript can also use `Bones.hold(el)` and `Bones.release(el)` (#44).

* Learned shapes are more robust. A render while the output is hidden, or
  a silent `req()` while a value waits for `min_time`, no longer deletes
  the stored shape. Striped rows of a reactable table, buttons, and boxes
  with a clear `color()` background are no longer drawn as cards.

* `withBones()` reserves the natural height of a custom skeleton when no
  `height` is given. An explicit `learn = TRUE` replaces it with the learned
  content shape on later visits. Custom skeletons keep their look by default
  (#43).

* `withBones()` and `bones_skeleton()` warn about unused shape arguments.
  A new warning may appear in code that passed an unused argument.
  `bones_auto()` does not give these warnings (#25).
* `withBones()` shows session options in its defaults. `bones_defaults()`
  with no arguments returns current values. Call it before you build the
  UI, when the options are read (#28).

* `bones_auto()` gives a short error and a hint for a misspelt argument
  name (#29).
* `bones_shapes()` lists all valid shapes, or the shapes in the basic,
  chart or table group (#26).

* With `stale = FALSE`, old content stays visible until the skeleton appears.
  Fast recalculations no longer flash a blank box (#42).

* bones works under a strict Content-Security-Policy, such as
  `style-src 'self'` with no `'unsafe-inline'`. It writes no `style`
  attribute any more, which such a policy blocks. The sizes, positions and
  colours of a skeleton go in a `data-bones-style` attribute, and a script in
  bones sets them in the browser. The look does not change. A `style` attribute
  that Shiny or a widget writes on the output itself, such as the height of
  `plotOutput()`, is not from bones and is left as it is.
* A bad `type`, `animation` or `shape` now gives a clear error with a hint
  for a near miss. Only exact names are accepted: a short form such as
  `type = "pi"` is now an error that says `Did you mean "pie"?` (#24).
* An output learns the shape of its content. After a load, the browser
  stores the place of each line of text, image and card. On the next visit,
  the skeleton has that shape in place of a guess from the type of the
  output. It is on by default. It applies only when you do not give `type`,
  `rows`, `cols`, `lines`, `n` or `skeleton`, and not to charts. A stored
  shape is used only at almost the same width, and it holds only numbers,
  never text. Turn it off with `withBones(learn = FALSE)` or
  `bones_defaults(learn = FALSE)`.
* `withBones()` now shows a calm panel when an output fails. After a good
  load, it keeps the old content dimmed with a banner. This is on by default
  and changes the error display on upgrade. Use
  `bones_defaults(error = FALSE)` to keep the error text of Shiny.
  Silent `req()` errors and `validate()` messages keep their usual behaviour
  (#19).
* `bones_error()` builds an error panel with a custom message. Error detail
  is off by default; use it only for development. Messages from `safeError()`
  still show when detail is off (#19).

# bones 0.1.1

First release.

* `withBones()` puts a placeholder around a Shiny output. The placeholder
  has the shape of the content, and the shape comes from the class of the
  output.
* The placeholder keeps the height of the output until the content
  arrives, so the page does not move. The content then sets the height, so
  no gap stays under content that is shorter than the estimate.
* The skeleton shows on the first load only. When the output calculates
  again, the old content stays on the screen, dimmed. Set `stale = FALSE`
  to show the skeleton again instead.
* All outputs show a recalculation at the same time, also when several
  outputs use one slow reactive and Shiny calculates them one after the
  other.
* `bones_skeleton()` makes a placeholder on its own, for use where there
  is no Shiny output. It takes space in its container, and brings its
  stylesheet, its animation and its colours.
* A chart can have the shape of its kind: `type = "bar"`, `"line"`,
  `"area"`, `"scatter"`, `"histogram"`, `"pie"` or `"heatmap"`. A
  `plotOutput()` with no `type` gets the bar shape, as before.
* A visualisation widget gets the shape of its kind, with no `type`. New
  shapes: `"map"` (leaflet, tmap, mapview, mapdeck, mapgl, googleway,
  threejs globe), `"network"` (visNetwork, DiagrammeR, networkD3,
  collapsibleTree), `"timeline"` (timevis) and `"wordcloud"` (wordcloud2).
  dygraphs gets `"line"`. ggiraph and other widgets that draw any chart
  keep the bar shape.
* A table from DT, reactable, gt or rhandsontable gets a shape that copies
  that package, with no `type`: for example the search box and the pages
  of DT, or the title and the spanner of gt. The space kept for each one
  was measured in a browser. gt is found from gt 1.0.0; with an older gt,
  give `type = "gt"`.
* The real height of the content is remembered. When the content arrives,
  the browser stores its height, and on the next visit the placeholder
  keeps that height in place of the estimate, so the page does not move.
  Only an estimated height is stored, per page and per output id, and it is
  used only at almost the same width. Turn it off with `remember = FALSE`.
* A fast load does not flicker. The skeleton, and the dimming of old
  content, appear only after `delay` (300 ms), so a load that ends sooner
  shows nothing. Once visible, they stay for at least `min_time` (500 ms).
  Both are arguments of `withBones()` and `bones_defaults()`.
* The colours come from the theme of the page: the text colour of the
  bslib theme, made faint. A skeleton thus takes the tint of a branded
  theme, and turns light in a dark theme or a dark part of a page, with no
  configuration. The corners follow the rounding of the theme. With no
  Bootstrap 5 theme, the colours are neutral greys.
* `bones_defaults()` sets the colours, the corner radius, the animation and
  the speed for the session. A colour set there is stronger than the theme.
* The arguments are checked, and a bad value gives a message that names
  the argument. `height` works as in Shiny, so a number is pixels.
* There is no animation for users who ask their system to reduce motion.
* The demo is a tour, with a tab for charts, tables, text and cards, and
  maps and networks. The sidebar sets the load time, `stale`, the animation
  and the dark mode, so you can see each option at work.
* A plotly, echarts4r or highcharter output finds the kind of its chart by
  itself. When the first value arrives, bones reads the kind of the series,
  and the next loads show that shape. A box plot or another kind with no
  shape keeps the bar shape. With `remember`, the kind is stored in the browser, so
  the first skeleton of the next visit has the right shape too. A `type`
  that you give always wins.
* `bones_auto()` puts each Shiny output in a UI in `withBones()`, so an
  app gets skeletons with one call. It keeps an output that is already
  wrapped, and leaves alone an inline output and the ids in `exclude`.
  Other arguments go to each wrapper. A bslib page keeps its class and
  its theme.
* Two more animations: `"cascade"`, where each bar, cell or line lights up
  a little after the one before, and `"sweep"`, where one band of light
  crosses the whole placeholder. Both stop for users who ask to reduce
  motion.
* `withBones(skeleton = )` takes a placeholder of your own, for a layout that
  no built-in shape fits. Build it from `bones_block()`, a grey block with the
  colours and the animation of bones, and any tags around it. It waits for
  `delay`, keeps the space of the content, and keeps stale content, as a
  built-in shape does.
* A wrapped output that fills its container in a fillable bslib layout, such
  as a plot in a card, still fills it: the wrapper passes the fill on. This
  needs htmltools 0.5.4 or newer.
