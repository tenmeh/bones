# bones 0.1.0

First release.

* `withBones()` wraps a Shiny output in a placeholder shaped like the content,
  inferred from the output's own class.
* Placeholders reserve the output's height, so nothing shifts when content
  arrives.
* Skeletons appear on first load only; recalculation keeps the previous content
  on screen and dims it. Set `stale = FALSE` for the older behaviour.
* `bones_skeleton()` builds placeholder markup on its own, for use outside a
  Shiny output.
* `bones_defaults()` sets colours, corner radius, animation and speed for the
  session.
* Animation respects `prefers-reduced-motion`.
