# bones 0.1.0

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
