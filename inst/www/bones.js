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

    // The skeleton is hidden now, so a change of its shape is not seen.
    if (wrap._bonesKind) {
      setKind(wrap, wrap._bonesKind);
      wrap._bonesKind = null;
    }

    // The content is on the screen now. Measure it a moment later, when a
    // widget has finished drawing.
    if (wrap._bonesSaveHeight) {
      wrap._bonesSaveHeight = false;
      window.setTimeout(function () {
        saveHeight(wrap);
        saveLayout(wrap);
      }, 250);
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

  /* --- Learn the shape of the content ------------------------------------
   *
   * The built-in skeleton is a guess from the type of the output. When the
   * content has arrived, the boxes of its visible parts are stored in
   * localStorage: one box for each line of text, one for each image or
   * control, and one frame for each card. On the next visit, the skeleton is
   * drawn from those boxes (see restoreLayout).
   *
   * Only a wrapper with data-bones-learn="true" does this. withBones() sets
   * it only when the developer did not set the shape, and not for a chart.
   * The key has the form of the height key. Only numbers are stored, never
   * text: {v: 1, w: width, h: height, b: [[x, y, width, height, kind]]},
   * with kind 0 for a bar and 1 for a frame.
   *
   * Nothing is stored when the content gives fewer than 2 boxes, or when one
   * box covers most of it, such as a map or a canvas: the built-in shape is
   * better than one large box. */
  var LAYOUT_PREFIX = "bones:layout:";
  var LAYOUT_VERSION = 1;
  var MAX_BOXES = 150;
  var MERGE_GAP = 8;        // px between two bars on one line that merge
  var LINE_TOLERANCE = 2;   // px of difference that is still one line
  var MIN_FRAME = 24;       // px: a smaller box is never a frame
  var MAX_SHARE = 0.6;      // of the area: a larger bar stops the record
  var MAX_NODES = 2000;     // text nodes, and elements, that one record visits
  var BAR = 0;
  var FRAME = 1;
  var TABLE_PARTS = /^(TABLE|THEAD|TBODY|TFOOT|TR|TH|TD)$/;

  function learns(wrap) {
    return wrap.getAttribute("data-bones-learn") === "true";
  }

  function layoutKey(wrap) {
    var id = wrap.getAttribute("data-bones-id");
    return id ? LAYOUT_PREFIX + window.location.pathname + ":" + id : null;
  }

  function isShown(el) {
    return el.getClientRects().length > 0 &&
      window.getComputedStyle(el).visibility !== "hidden";
  }

  /* The part of the screen where the content of `el` can show: the content
   * box of the wrapper, made smaller by each element between them whose
   * overflow is not visible, such as a box that scrolls. A row under the
   * edge of a scroll box is thus not recorded. The result is kept on the
   * element for one record (`stamp`), so each element is examined once. */
  function clipOf(el, content, origin, stamp) {
    if (!el || el === content) return origin;
    if (el._bonesClipStamp === stamp) return el._bonesClip;
    var clip = clipOf(el.parentElement, content, origin, stamp);
    var style = window.getComputedStyle(el);
    if (style.overflowX !== "visible" || style.overflowY !== "visible") {
      var r = el.getBoundingClientRect();
      clip = {
        left: Math.max(clip.left, r.left),
        top: Math.max(clip.top, r.top),
        right: Math.min(clip.right, r.right),
        bottom: Math.min(clip.bottom, r.bottom)
      };
    }
    el._bonesClipStamp = stamp;
    el._bonesClip = clip;
    return clip;
  }

  /* An element of another skeleton, such as that of an inner withBones()
   * that still loads. It is not content. */
  function inSkeleton(el) {
    return !!el.closest(".bones-skeleton");
  }

  function hasAlpha(color) {
    return color && color !== "transparent" && !/^rgba\(.*,\s*0\)$/.test(color);
  }

  /* A card or a value box: a border on all four sides, or a background of
   * its own. Never a part of a table: a striped row is not a card. */
  function isFrame(el) {
    if (TABLE_PARTS.test(el.tagName)) return false;
    var style = window.getComputedStyle(el);
    var sides = ["Top", "Right", "Bottom", "Left"];
    var bordered = true;
    for (var i = 0; i < sides.length; i++) {
      if (!(parseFloat(style["border" + sides[i] + "Width"]) > 0) ||
          style["border" + sides[i] + "Style"] === "none") {
        bordered = false;
        break;
      }
    }
    if (bordered) return true;
    var bg = style.backgroundColor;
    var parent = el.parentElement;
    return hasAlpha(bg) && !!parent &&
      bg !== window.getComputedStyle(parent).backgroundColor;
  }

  function insideButton(node, root) {
    for (var el = node.parentElement; el && el !== root; el = el.parentElement) {
      if (el.tagName === "BUTTON") return true;
    }
    return false;
  }

  var recordStamp = 0;

  /* The boxes of the content of `wrap`, relative to the content, or null
   * when nothing should be stored. */
  function recordLayout(wrap) {
    var content = wrap.querySelector(":scope > .bones-content");
    if (!content) return null;
    var origin = content.getBoundingClientRect();
    if (!(origin.width > 0 && origin.height > 0)) return null;
    var stamp = ++recordStamp;
    var raw = [];

    function add(rect, kind, el) {
      // Cut the box to the part of the content where it can show.
      var clip = clipOf(el, content, origin, stamp);
      var left = Math.max(rect.left, clip.left) - origin.left;
      var top = Math.max(rect.top, clip.top) - origin.top;
      var right = Math.min(rect.right, clip.right) - origin.left;
      var bottom = Math.min(rect.bottom, clip.bottom) - origin.top;
      var x = Math.round(left);
      var y = Math.round(top);
      var w = Math.round(right) - x;
      var h = Math.round(bottom) - y;
      if (w > 0 && h > 0) raw.push([x, y, w, h, kind]);
    }

    // Bars from text: one for each line that the text takes. The walk stops
    // after MAX_NODES text nodes. Only the first boxes from the top are
    // kept, so the end of a long table adds nothing, and the walk stays
    // short after each load.
    var walker = document.createTreeWalker(content, NodeFilter.SHOW_TEXT, null);
    var range = document.createRange();
    var visited = 0;
    for (var node = walker.nextNode(); node && visited < MAX_NODES; node = walker.nextNode()) {
      if (!/\S/.test(node.nodeValue)) continue;
      visited++;
      var parent = node.parentElement;
      if (!parent || !isShown(parent) || insideButton(node, content)) continue;
      range.selectNodeContents(node);
      var rects = range.getClientRects();
      for (var r = 0; r < rects.length; r++) add(rects[r], BAR, parent);
    }

    // Bars from elements with no text of their own.
    var things = content.querySelectorAll("img, input, select, textarea, button, canvas, svg");
    for (var t = 0; t < things.length && t < MAX_NODES; t++) {
      var thing = things[t];
      if (inSkeleton(thing)) continue;
      if (thing.tagName.toLowerCase() === "svg" && insideButton(thing, content)) continue;
      if (isShown(thing)) add(thing.getBoundingClientRect(), BAR, thing.parentElement);
    }

    // Frames: cards and value boxes that show.
    var all = content.querySelectorAll("*");
    for (var e = 0; e < all.length && e < MAX_NODES; e++) {
      var el = all[e];
      var rect = el.getBoundingClientRect();
      if (rect.width >= MIN_FRAME && rect.height >= MIN_FRAME && !inSkeleton(el) &&
          isShown(el) && isFrame(el)) {
        add(rect, FRAME, el.parentElement);
      }
    }

    raw.sort(function (a, b) { return a[1] - b[1] || a[0] - b[0]; });

    // Merge the bars of one line that almost touch, such as the words of a
    // cell that the browser gives as several rects.
    var boxes = [];
    var last = null;
    for (var i = 0; i < raw.length; i++) {
      var box = raw[i];
      if (box[4] === BAR && last &&
          Math.abs(box[1] - last[1]) <= LINE_TOLERANCE &&
          Math.abs(box[3] - last[3]) <= LINE_TOLERANCE &&
          box[0] - (last[0] + last[2]) < MERGE_GAP && box[0] >= last[0]) {
        last[2] = Math.max(last[0] + last[2], box[0] + box[2]) - last[0];
        continue;
      }
      boxes.push(box);
      if (box[4] === BAR) last = box;
    }

    if (boxes.length < 2) return null;
    // One large bar, such as a canvas or a map, gives no useful shape. A
    // large frame does: it is a card around the rest.
    var area = origin.width * origin.height;
    for (var k = 0; k < boxes.length; k++) {
      if (boxes[k][4] === BAR && boxes[k][2] * boxes[k][3] > MAX_SHARE * area) return null;
    }

    // The first boxes from the top. Then the frames before the bars, so
    // that a bar is drawn over its card.
    boxes = boxes.slice(0, MAX_BOXES);
    var frames = boxes.filter(function (b) { return b[4] === FRAME; });
    var bars = boxes.filter(function (b) { return b[4] === BAR; });
    return {
      v: LAYOUT_VERSION,
      w: Math.round(wrap.getBoundingClientRect().width),
      h: Math.round(origin.height),
      b: frames.concat(bars)
    };
  }

  function saveLayout(wrap) {
    if (!learns(wrap) || !wrap.classList.contains("bones-loaded")) return;
    var key = layoutKey(wrap);
    if (!key) return;
    var record = recordLayout(wrap);
    try {
      if (record) {
        window.localStorage.setItem(key, JSON.stringify(record));
      } else {
        window.localStorage.removeItem(key);
      }
    } catch (e) {
      // No storage: the next visit draws the built-in shape.
    }
  }

  /* A stored record, or null when there is none, or when it does not have
   * the form that this version writes. */
  function readLayout(key) {
    var record;
    try {
      record = JSON.parse(window.localStorage.getItem(key));
    } catch (e) {
      return null;
    }
    if (!record || record.v !== LAYOUT_VERSION ||
        !(isFinite(record.w) && record.w > 0) || !(isFinite(record.h) && record.h > 0) ||
        !Array.isArray(record.b) || record.b.length > MAX_BOXES) return null;
    for (var i = 0; i < record.b.length; i++) {
      var box = record.b[i];
      if (!Array.isArray(box) || box.length !== 5) return null;
      for (var j = 0; j < 5; j++) {
        if (typeof box[j] !== "number" || !isFinite(box[j])) return null;
      }
      if (box[4] !== BAR && box[4] !== FRAME) return null;
    }
    return record;
  }

  /* Draw the stored layout in place of the built-in skeleton, once, before
   * the first load. A layout recorded later in this visit is drawn on the
   * next visit, so the shape does not change while the user looks at it.
   * As for the height, a layout is used only at almost the same width. */
  function restoreLayout(wrap) {
    if (wrap._bonesLayoutRestored || !learns(wrap) ||
        wrap.classList.contains("bones-has-loaded")) return;
    var key = layoutKey(wrap);
    if (!key) return;
    var width = wrap.getBoundingClientRect().width;
    // A wrapper in a hidden tab has no width yet. Try again when its output
    // starts to load (see onInvalidated).
    if (!(width > 0)) return;
    wrap._bonesLayoutRestored = true;
    var record = readLayout(key);
    var old = wrap.querySelector(":scope > .bones-skeleton");
    if (!record || !old || Math.abs(width - record.w) > 0.1 * record.w) return;

    var skeleton = document.createElement("div");
    for (var a = 0; a < old.attributes.length; a++) {
      var attr = old.attributes[a];
      if (attr.name !== "class") skeleton.setAttribute(attr.name, attr.value);
    }
    skeleton.className = "bones-skeleton bones-skeleton-learned";
    for (var i = 0; i < record.b.length; i++) {
      var box = record.b[i];
      var el = document.createElement("div");
      el.className = box[4] === FRAME ? "bones-learned-frame" : "bones-bar";
      el.style.left = box[0] + "px";
      el.style.top = box[1] + "px";
      el.style.width = box[2] + "px";
      el.style.height = box[3] + "px";
      skeleton.appendChild(el);
    }
    wrap.replaceChild(skeleton, old);
    // As for the remembered height: only a height that was an estimate is
    // replaced. A height from `height`, or from the output, is exact.
    if (remembers(wrap)) wrap.style.setProperty("--bones-reserve", record.h + "px");
  }

  /* --- The kind of a chart, from its value -----------------------------------
   *
   * A plotly, echarts4r or highcharter output can hold any kind of chart, so
   * withBones() gives it the bar shape. The value of the output holds the
   * spec of the chart, and each series in it names its kind. When the value
   * arrives, this script reads the kind and puts the skeleton of that kind in
   * place of the bar shape. The next load with stale = FALSE then shows the
   * right shape.
   *
   * With remember, the kind is also stored in localStorage, with a key in
   * the form of the height key. On the next visit the first skeleton has the
   * right shape too. The skeletons come from a template that withBones()
   * writes once on the page, so their markup is made only in R.
   *
   * The kind of one series is a shape name, or NO_SHAPE for a kind that has
   * no shape, such as a box plot, or null for a series that says nothing,
   * such as the outliers of a box plot. */
  var KIND_PREFIX = "bones:kind:";
  var NO_SHAPE = false;

  function kindKey(wrap) {
    var id = wrap.getAttribute("data-bones-id");
    return id ? KIND_PREFIX + window.location.pathname + ":" + id : null;
  }

  /* The kind of the first series that names one. The first series is
   * usually the main one: in a ggplotly chart of points with a smooth line,
   * the points come first. A first series of a kind with no shape stops the
   * search, so a box plot does not get the shape of its outliers. */
  function firstKind(series, kindOf) {
    if (!Array.isArray(series)) return null;
    for (var i = 0; i < series.length; i++) {
      var kind = series[i] ? kindOf(series[i]) : null;
      if (kind === NO_SHAPE) return null;
      if (kind) return kind;
    }
    return null;
  }

  /* plotly: value.x.data holds the traces. */
  function plotlyTraceKind(trace) {
    var type = trace.type || "scatter";
    switch (type) {
      case "bar": case "waterfall": case "funnel":
        return "bar";
      case "histogram":
        return "histogram";
      case "pie": case "sunburst":
        return "pie";
      case "heatmap": case "heatmapgl": case "contour":
      case "histogram2d": case "histogram2dcontour":
        return "heatmap";
      case "scattergeo": case "choropleth": case "scattermapbox":
      case "choroplethmapbox": case "densitymapbox": case "scattermap":
      case "choroplethmap": case "densitymap":
        return "map";
      case "sankey":
        return "network";
      case "box": case "violin": case "candlestick": case "ohlc":
        return NO_SHAPE;
      case "scatter": case "scattergl":
        // Any fill is an area. ggplotly() draws geom_area() and geom_ribbon()
        // as a closed shape with fill "toself". A ggplot2 map drawn with
        // ggplotly() is also "toself", so it gets the area shape: give
        // type = "map" for it.
        if (trace.fill && trace.fill !== "none") return "area";
        var mode = trace.mode || "lines";
        return mode.indexOf("lines") >= 0 ? "line" : "scatter";
      default:
        return null;
    }
  }

  function plotlyKind(value) {
    return firstKind(value && value.x && value.x.data, plotlyTraceKind);
  }

  /* echarts4r: value.x.opts.series holds the series. e_area() is a line
   * with an areaStyle, and e_histogram() is a bar. */
  function echartsSeriesKind(series) {
    // A scatter or a line on a map is a map.
    var system = series.coordinateSystem;
    if (system === "geo" || system === "leaflet" || system === "bmap") return "map";
    switch (series.type) {
      case "bar": case "pictorialBar":
        return "bar";
      case "line":
        return series.areaStyle ? "area" : "line";
      case "scatter": case "effectScatter":
        return "scatter";
      case "pie": case "sunburst":
        return "pie";
      case "heatmap":
        return "heatmap";
      case "map": case "lines":
        return "map";
      case "graph": case "tree": case "sankey":
        return "network";
      case "wordCloud":
        return "wordcloud";
      case "boxplot": case "candlestick": case "gauge": case "radar":
      case "funnel": case "parallel": case "themeRiver": case "liquidFill":
        return NO_SHAPE;
      default:
        return null;
    }
  }

  function echartsKind(value) {
    var opts = value && value.x && value.x.opts;
    return firstKind(opts && opts.series, echartsSeriesKind);
  }

  /* highcharter: value.x.hc_opts holds the options. A series has its own
   * type, or takes chart.type, or is a line. hchart() of numbers draws a
   * histogram as columns, so it gets the bar shape. */
  function highchartSeriesKind(type) {
    switch (type) {
      case "line": case "spline":
        return "line";
      case "area": case "areaspline": case "arearange": case "areasplinerange":
      case "streamgraph":
        return "area";
      case "column": case "bar": case "columnrange": case "waterfall":
        return "bar";
      case "histogram":
        return "histogram";
      case "scatter": case "bubble":
        return "scatter";
      case "pie": case "variablepie": case "sunburst":
        return "pie";
      case "heatmap": case "tilemap":
        return "heatmap";
      case "map": case "mapbubble": case "mappoint": case "mapline":
        return "map";
      case "networkgraph": case "sankey": case "dependencywheel":
      case "organization":
        return "network";
      case "wordcloud":
        return "wordcloud";
      case "boxplot": case "candlestick": case "ohlc": case "errorbar":
      case "gauge": case "solidgauge": case "funnel": case "pyramid":
        return NO_SHAPE;
      default:
        return null;
    }
  }

  function highchartKind(value) {
    var x = value && value.x;
    if (!x) return null;
    // hcmap() makes a map chart, whose series have no type of their own.
    if (x.type === "map") return "map";
    var opts = x.hc_opts || {};
    var chartType = (opts.chart && opts.chart.type) || "line";
    return firstKind(opts.series, function (series) {
      return highchartSeriesKind(series.type || chartType);
    });
  }

  var KIND_READERS = {
    plotly: plotlyKind,
    echarts4r: echartsKind,
    highchart: highchartKind
  };

  /* withBones() writes the template once on the page, as a singleton, in
   * the first wrapper that needs it. Shiny inserts a singleton only once,
   * so when a renderUI() that holds it renders again, the template goes
   * away with the old content and does not come back. The script thus
   * keeps its own copy as soon as the template is on the page (see
   * restoreAll). */
  var shapes = null;

  /* Keep a copy of the template in `node`, once. Not while the page loads:
   * the parser can give the template to this script before it has read all
   * of its content, and a copy then would miss the later shapes for good.
   * A template that a renderUI() inserts comes whole, after the page has
   * loaded. */
  function keepTemplate(node) {
    if (shapes || node.nodeType !== 1 || document.readyState === "loading") return;
    var template = node.matches("template.bones-kinds") ? node :
      node.querySelector("template.bones-kinds");
    if (template && template.content) shapes = template.content.cloneNode(true);
  }

  function templateOf(kind) {
    var selector = '[data-bones-kind="' + kind + '"]';
    if (!shapes) keepTemplate(document.documentElement);
    if (shapes) return shapes.querySelector(selector);
    // While the page loads: the template as the parser has read it so far.
    // A shape that is not there yet gives null, and the caller tries again.
    var template = document.querySelector("template.bones-kinds");
    return template && template.content ? template.content.querySelector(selector) : null;
  }

  /* Put the skeleton of `kind` in place of the skeleton of `wrap`. */
  function setKind(wrap, kind) {
    if (wrap.getAttribute("data-bones-type") === kind) return;
    var shape = templateOf(kind);
    var old = wrap.querySelector(":scope > .bones-skeleton");
    if (!shape || !old) return;
    var skeleton = shape.cloneNode(true);
    skeleton.removeAttribute("data-bones-kind");
    wrap.replaceChild(skeleton, old);
    wrap.setAttribute("data-bones-type", kind);
  }

  /* Store the kind for the next visit, or remove it when `kind` is null. */
  function saveKind(wrap, kind) {
    if (wrap.getAttribute("data-bones-remember-kind") !== "true") return;
    var key = kindKey(wrap);
    if (!key) return;
    try {
      if (kind) {
        window.localStorage.setItem(key, kind);
      } else {
        window.localStorage.removeItem(key);
      }
    } catch (e) {
      // No storage: the next visit starts with the bar shape.
    }
  }

  function restoreKind(wrap) {
    if (wrap._bonesKindRestored || wrap.classList.contains("bones-has-loaded") ||
        wrap.getAttribute("data-bones-remember-kind") !== "true") return;
    var key = kindKey(wrap);
    if (!key) return;
    var kind = null;
    try {
      kind = window.localStorage.getItem(key);
    } catch (e) {
      return;
    }
    // The template can come later in the page than this wrapper, while the
    // page loads. Try again then.
    if (kind && !templateOf(kind)) return;
    wrap._bonesKindRestored = true;
    if (kind) setKind(wrap, kind);
  }

  /* Read the kind from the value of a detecting wrapper. The new shape is
   * put in place when the load ends (see markLoaded), because the skeleton
   * can still show until min_time has passed. */
  function readKind(wrap, value) {
    var reader = KIND_READERS[wrap.getAttribute("data-bones-detect")];
    if (!reader) return;
    var kind = reader(value);
    // A chart with no shape, such as a box plot, goes back to the first
    // shape, "plot", and the kind of an earlier chart is not kept for the
    // next visit. A chart can change its kind: its type can follow an input.
    wrap._bonesKind = kind || "plot";
    saveKind(wrap, kind);
  }

  // Restore as each wrapper enters the page: while the page loads, and when
  // a renderUI() inserts one. The records come before the browser paints,
  // so the wrapper has the stored height from its first frame. Only the
  // added nodes are examined, so a busy app does little extra work.
  function restoreAll(node) {
    restoreIn(node);
    if (node.nodeType !== 1) return;
    keepTemplate(node);
    // After the height: a drawn layout sets the height of its own record.
    if (node.matches(".bones-wrap[data-bones-learn]")) restoreLayout(node);
    var learning = node.querySelectorAll(".bones-wrap[data-bones-learn]");
    for (var l = 0; l < learning.length; l++) restoreLayout(learning[l]);
    if (node.matches(".bones-wrap[data-bones-detect]")) restoreKind(node);
    var inner = node.querySelectorAll(".bones-wrap[data-bones-detect]");
    for (var i = 0; i < inner.length; i++) restoreKind(inner[i]);
  }

  restoreAll(document.documentElement);
  new MutationObserver(function (records) {
    for (var r = 0; r < records.length; r++) {
      var added = records[r].addedNodes;
      for (var a = 0; a < added.length; a++) restoreAll(added[a]);
    }
  }).observe(document.documentElement, {childList: true, subtree: true});
  // When the page has loaded, each wrapper and the template are complete.
  document.addEventListener("DOMContentLoaded", function () {
    restoreAll(document.documentElement);
  });

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
    restoreLayout(wrap);

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
    if (e.type === "shiny:value") {
      wrap._bonesSaveHeight = true;
      readKind(wrap, e.value);
    }
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
