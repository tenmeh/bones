/* bones — content-shaped loading placeholders for Shiny outputs
 *
 * The whole behaviour is four states on the wrapper element:
 *
 *   (none)         first load, skeleton visible, content hidden but boxed
 *   bones-loaded   content has arrived, skeleton gone
 *   bones-stale    content is on screen but being recalculated (dimmed)
 *   bones-loading  recalculating with stale disabled, skeleton back
 *
 * Shiny's output lifecycle events are jQuery events, so they are listened to
 * with jQuery rather than addEventListener — jQuery.trigger() does not invoke
 * native listeners for custom event types.
 */
(function () {
  "use strict";

  if (!window.jQuery) return;
  var $ = window.jQuery;

  function wrapOf(el) {
    var $wrap = $(el).closest(".bones-wrap");
    return $wrap.length ? $wrap[0] : null;
  }

  function keepsStale(wrap) {
    return wrap.getAttribute("data-bones-stale") === "true";
  }

  function markLoaded(wrap) {
    wrap.classList.add("bones-loaded");
    wrap.classList.remove("bones-loading", "bones-stale");
  }

  function onRecalculating(e) {
    var wrap = wrapOf(e.target);
    if (!wrap) return;

    if (wrap.classList.contains("bones-loaded") && keepsStale(wrap)) {
      // Content the user is already reading stays put and dims. Swapping it
      // for grey blocks would remove information rather than add any.
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

  $(document).on("shiny:recalculating", onRecalculating);
  $(document).on("shiny:value shiny:recalculated shiny:error", onSettled);

  /* An output may render before this script has attached its listeners — on a
   * fast initial load, or when a `renderUI()` inserts one. Those wrappers would
   * sit on a skeleton for ever. Once Shiny goes idle, reveal any wrapper whose
   * output already has content. */
  function sweep() {
    var wraps = document.querySelectorAll(".bones-wrap:not(.bones-loaded)");
    for (var i = 0; i < wraps.length; i++) {
      var content = wraps[i].querySelector(".bones-content");
      if (!content) continue;

      var output = content.querySelector(".shiny-bound-output") || content.firstElementChild;
      if (!output) continue;

      var filled =
        output.children.length > 0 ||
        (output.textContent || "").trim().length > 0;

      if (filled) markLoaded(wraps[i]);
    }
  }

  $(document).on("shiny:idle", function () {
    // One tick later, so any render that triggered this has finished writing.
    window.setTimeout(sweep, 0);
  });
})();
