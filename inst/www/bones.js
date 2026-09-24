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
    if (wrap._bonesTimer) {
      window.clearTimeout(wrap._bonesTimer);
      wrap._bonesTimer = null;
    }
    wrap._bonesShownAt = undefined;
    wrap.classList.add("bones-loaded", "bones-has-loaded");
    wrap.classList.remove("bones-loading", "bones-stale");

    // The content is on the screen now. Measure it a moment later, when a
    // widget has finished drawing.
    if (wrap._bonesSaveHeight) {
      wrap._bonesSaveHeight = false;
      window.setTimeout(function () { saveHeight(wrap); }, 250);
    }
  }

  /* --- Remember the real height ------------------------------------------
   *
   * The space that a wrapper keeps before its content arrives is an
   * estimate, unless the output sets its own height. The estimate can be
   * wrong, and the page then moves when the content arrives. So when the
   * content has arrived, its real height is stored in localStorage. On the
   * next visit, the wrapper keeps that height in place of the estimate.
   *
   * Only a wrapper with data-bones-remember="true" does this: withBones()
   * sets it only when the height came from an estimate. The key is the path
   * of the page and the id of the output, so two apps on one server do not
   * mix their heights. A stored height is used only when the wrapper has
   * almost the same width as when it was measured: a narrower wrapper, as on
   * a phone, makes taller content, and the estimate is then better.
   *
   * localStorage can be absent or full, or blocked in a private window. Each
   * access is thus in a try block, and a failure only means no stored
   * height. */
  var HEIGHT_PREFIX = "bones:height:";

  function heightKey(wrap) {
    var id = wrap.getAttribute("data-bones-id");
    return id ? HEIGHT_PREFIX + window.location.pathname + ":" + id : null;
  }

  function remembers(wrap) {
    return wrap.getAttribute("data-bones-remember") === "true";
  }

  function readHeight(key) {
    try {
      var value = JSON.parse(window.localStorage.getItem(key));
      return value && isFinite(value.h) && isFinite(value.w) && value.h > 0 ? value : null;
    } catch (e) {
      return null;
    }
  }

  function saveHeight(wrap) {
    if (!remembers(wrap) || !wrap.classList.contains("bones-loaded")) return;
    var key = heightKey(wrap);
    var content = wrap.querySelector(".bones-content");
    if (!key || !content) return;
    var h = Math.round(content.getBoundingClientRect().height);
    var w = Math.round(wrap.getBoundingClientRect().width);
    if (!(h > 0 && w > 0)) return;
    try {
      window.localStorage.setItem(key, JSON.stringify({h: h, w: w}));
    } catch (e) {
      // No storage: the next visit uses the estimate.
    }
  }

  function restoreHeight(wrap) {
    if (wrap._bonesRestored || !remembers(wrap) ||
        wrap.classList.contains("bones-has-loaded")) return;
    var key = heightKey(wrap);
    if (!key) return;
    var width = wrap.getBoundingClientRect().width;
    // A wrapper in a hidden tab has no width yet. Try again when its output
    // starts to load (see onInvalidated).
    if (!(width > 0)) return;
    wrap._bonesRestored = true;
    var saved = readHeight(key);
    if (saved && Math.abs(width - saved.w) <= 0.1 * saved.w) {
      wrap.style.setProperty("--bones-reserve", saved.h + "px");
    }
  }

  function restoreIn(node) {
    if (node.nodeType !== 1) return;
    if (node.matches(".bones-wrap[data-bones-remember]")) restoreHeight(node);
    var inner = node.querySelectorAll(".bones-wrap[data-bones-remember]");
    for (var i = 0; i < inner.length; i++) restoreHeight(inner[i]);
  }

  // Restore as each wrapper enters the page: while the page loads, and when
  // a renderUI() inserts one. The records come before the browser paints,
  // so the wrapper has the stored height from its first frame. Only the
  // added nodes are examined, so a busy app does little extra work.
  restoreIn(document.documentElement);
  new MutationObserver(function (records) {
    for (var r = 0; r < records.length; r++) {
      var added = records[r].addedNodes;
      for (var a = 0; a < added.length; a++) restoreIn(added[a]);
    }
  }).observe(document.documentElement, {childList: true, subtree: true});

  /* --- No flicker ------------------------------------------------------------
   *
   * Two rules stop a skeleton, or the dimming, from flashing on the screen:
   *
   * 1. It appears only after a delay (--bones-delay). The stylesheet does
   *    this with an animation delay and a transition delay, so a load that
   *    ends before then shows nothing.
   * 2. When it has appeared, it stays for at least min_time milliseconds
   *    (data-bones-min-time). A load that ends a moment after the delay thus
   *    does not show a skeleton for one frame. This script does this.
   *
   * The script does not guess when the skeleton appeared. It listens for
   * the start of the "bones-appear" animation of the skeleton, and for the
   * start of the opacity transition of dimmed content. Those events come
   * exactly when the delay ends. */
  var DEFAULT_MIN_TIME = 500;

  function minTimeOf(wrap) {
    var value = parseFloat(wrap.getAttribute("data-bones-min-time"));
    return isFinite(value) && value >= 0 ? value : DEFAULT_MIN_TIME;
  }

  function now() {
    return window.performance && performance.now ? performance.now() : Date.now();
  }

  /* End the load of `wrap`, now or when min_time has passed. */
  function settle(wrap) {
    if (wrap._bonesTimer) return;
    var shown = wrap._bonesShownAt;
    var wait = shown === undefined ? 0 : minTimeOf(wrap) - (now() - shown);
    if (wait <= 0) {
      markLoaded(wrap);
      return;
    }
    wrap._bonesTimer = window.setTimeout(function () {
      wrap._bonesTimer = null;
      markLoaded(wrap);
    }, wait);
  }

  document.addEventListener("animationstart", function (e) {
    if (e.animationName !== "bones-appear") return;
    var wrap = e.target.parentElement;
    if (wrap && wrap.classList.contains("bones-wrap")) wrap._bonesShownAt = now();
  }, true);

  document.addEventListener("transitionstart", function (e) {
    if (e.propertyName !== "opacity" || !e.target.classList.contains("bones-content")) return;
    var wrap = e.target.parentElement;
    if (wrap && wrap.classList.contains("bones-stale")) wrap._bonesShownAt = now();
  }, true);

  function onInvalidated(e) {
    var wrap = wrapOf(e.target);
    if (!wrap) return;

    // A new load starts. An end that waited for min_time is not the end of
    // this load. The skeleton or the dimming stays on, so the time that it
    // appeared stays the same.
    if (wrap._bonesTimer) {
      window.clearTimeout(wrap._bonesTimer);
      wrap._bonesTimer = null;
    }

    // A wrapper that was in a hidden tab can have a width now.
    restoreHeight(wrap);

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
    if (!wrap) return;
    // Only a real value has a height worth storing. An error, or a silent
    // req(), leaves the output empty or shows a message.
    if (e.type === "shiny:value") wrap._bonesSaveHeight = true;
    settle(wrap);
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
        settle(wrap);
      }
    }
  }

  $(document).on("shiny:idle", function () {
    // One tick later, so any render that triggered this has finished writing.
    window.setTimeout(sweep, 0);
  });
})();
