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
* A table from DT, reactable, gt or rhandsontable gets a shape that copies
  that package, with no `type`: for example the search box and the pages
  of DT, or the title and the spanner of gt. The space kept for each one
  was measured in a browser.
* `bones_defaults()` sets the colours, the corner radius, the animation and
  the speed for the session.
* The arguments are checked, and a bad value gives a message that names
  the argument. `height` works as in Shiny, so a number is pixels.
* There is no animation for users who ask their system to reduce motion.
