/* bones - content-shaped loading placeholders for Shiny outputs
 *
 * This script sets one of four states on each wrapper element, with classes:
 *
 *   (no class)     First load. The skeleton shows. The content is hidden,
 *                  but it has its box.
 *   bones-loaded   The content has arrived. The skeleton is hidden.
 *   bones-stale    With bones-loaded. The content shows, dimmed, while the
 *                  output calculates again.
 *   bones-loading  The output calculates again and the stale option is off.
 *                  The skeleton shows again.
 *
 * One more class records the history, not the state:
 *
 *   bones-has-loaded  The content arrived at least once. It is never removed.
 *                     bones.css keeps the reserved height only until then.
 *
 * The events of Shiny for an output are jQuery events, so this script listens
 * with jQuery and not with addEventListener. jQuery.trigger() does not call
 * native listeners for custom event types.
 */
(function () {
  "use strict";

  if (!window.jQuery) return;
  var $ = window.jQuery;

  function outputOf(wrap) {
    var content = wrap.querySelector(".bones-content");
    if (!content) return null;
    return content.querySelector(".shiny-bound-output") || content.firstElementChild;
  }

  /* The wrapper that `el` is the output of, or null. The Shiny events bubble,
   * so an output inside a wrapped uiOutput() also reaches the wrapper of the
   * uiOutput(). Only the output of the wrapper itself may change its state. */
  function wrapOf(el) {
    var $wrap = $(el).closest(".bones-wrap");
    if (!$wrap.length) return null;
    return outputOf($wrap[0]) === el ? $wrap[0] : null;
  }

  function keepsStale(wrap) {
    return wrap.getAttribute("data-bones-stale") === "true";
  }

  function markLoaded(wrap) {
    wrap.classList.add("bones-loaded", "bones-has-loaded");
    wrap.classList.remove("bones-loading", "bones-stale");
  }

  function onInvalidated(e) {
    var wrap = wrapOf(e.target);
    if (!wrap) return;

    if (wrap.classList.contains("bones-loaded") && keepsStale(wrap)) {
      // The user is possibly reading this content, so it stays and dims.
      // Grey blocks in its place would remove information and add none.
      wrap.classList.add("bones-stale");
      return;
    }

    wrap.classList.remove("bones-loaded");
    wrap.classList.add("bones-loading");
  }

  function onSettled(e) {
    var wrap = wrapOf(e.target);
    if (wrap) markLoaded(wrap);
  }

  /* Listen for "shiny:outputinvalidated", not "shiny:recalculating".
   *
   * Shiny sends "outputinvalidated" for each output at the same time, as soon
   * as the output is out of date. It sends "recalculating" only when the
   * render function of that output starts, and it starts them one at a time.
   * When several outputs use one slow reactive, the first render does all the
   * slow work. The other outputs then get "recalculating" only at the end, a
   * few milliseconds before their value. A wrapper that waited for it thus
   * showed nothing for the whole wait.
   *
   * The end of the recalculation is "shiny:value" or "shiny:error". A silent
   * req() also sends "shiny:error". "shiny:recalculated" is not used: it
   * comes before the value, and would show the old content for a moment when
   * the stale option is off. */
  $(document).on("shiny:outputinvalidated", onInvalidated);
  $(document).on("shiny:value shiny:error", onSettled);

  /* A safety net for two cases. The events above do not cover them.
   *
   * 1. An output can render before this script attaches its listeners. This
   *    occurs on a fast first load, or when a renderUI() inserts an output.
   *    Its wrapper would then show a skeleton for ever. Show the wrapper if
   *    its output has content.
   * 2. A recalculation can end with no "shiny:value" or "shiny:error". The
   *    wrapper would then stay stale or on a skeleton. When Shiny is idle and
   *    the output is no longer recalculating, the recalculation has ended.
   *
   * A wrapper in its first load with an empty output stays on its skeleton.
   * Its output can be in a hidden tab, where Shiny does not render it yet. */
  function sweep() {
    var wraps = document.querySelectorAll(".bones-wrap");
    for (var i = 0; i < wraps.length; i++) {
      var wrap = wraps[i];
      var output = outputOf(wrap);
      if (!output || output.classList.contains("recalculating")) continue;

      var wasRecalculating =
        wrap.classList.contains("bones-stale") ||
        wrap.classList.contains("bones-loading");
      var filled =
        output.children.length > 0 ||
        (output.textContent || "").trim().length > 0;

      if (wasRecalculating || (filled && !wrap.classList.contains("bones-loaded"))) {
        markLoaded(wrap);
      }
    }
  }

  $(document).on("shiny:idle", function () {
    // One tick later, so any render that triggered this has finished writing.
    window.setTimeout(sweep, 0);
  });
})();
