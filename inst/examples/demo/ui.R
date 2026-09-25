ui <- page_sidebar(
  title = "bones: content-shaped loading placeholders",
  theme = bs_theme(version = 5),
  # The page scrolls. A page that fills the window makes each card, and its
  # plot, shorter than the plot height in a small window.
  fillable = FALSE,

  # --- Controls -----------------------------------------------------------------
  sidebar = sidebar(
    width = 300,
    actionButton("refresh", "Load new data", class = "btn-primary"),
    sliderInput("seconds", "Load time (seconds)", min = 0.1, max = 4, value = 1.5, step = 0.1),
    input_switch("stale", "stale: keep the old content, dimmed, while it loads", value = TRUE),
    radioButtons("animation", "Animation", c("wave", "pulse", "cascade", "sweep", "none"),
                 inline = TRUE),
    input_dark_mode(id = "mode"),
    tags$p(
      class = "small text-muted mt-2",
      "Open each tab: its outputs load when the tab first shows. ",
      "Try a load time under 0.3 seconds: a load that fast shows no skeleton."
    ),
    # The switch and the animation change the attributes that withBones()
    # writes. bones.js and bones.css read them at each load, so the change
    # applies to the next load. In an app, set these with withBones(stale = ,
    # animation = ) or bones_defaults().
    tags$script(HTML("
      $(document).on('change', '#stale', function () {
        var value = this.checked ? 'true' : 'false';
        // The summary keeps its own stale = FALSE.
        document.querySelectorAll('.bones-wrap:not([data-bones-id=summary])').forEach(function (w) {
          w.setAttribute('data-bones-stale', value);
        });
      });
      $(document).on('change', 'input[name=animation]', function () {
        var value = this.value;
        document.querySelectorAll('.bones-wrap').forEach(function (w) {
          Array.from(w.classList).forEach(function (c) {
            if (c.indexOf('bones-anim-') === 0) w.classList.remove(c);
          });
          w.classList.add('bones-anim-' + value);
        });
      });
    "))
  ),

  # --- The tour -----------------------------------------------------------------
  navset_card_tab(
    id = "tab",

    nav_panel(
      "Charts",
      tags$p(
        class = "text-muted",
        "plotOutput() cannot say what kind of chart it holds, so each one names ",
        "its kind with type."
      ),
      layout_column_wrap(
        width = "280px",
        demo_card('Bar  (type = "bar")', withBones(plotOutput("bar", height = 240), type = "bar")),
        demo_card('Line  (type = "line")', withBones(plotOutput("line", height = 240), type = "line")),
        demo_card('Scatter  (type = "scatter")',
                  withBones(plotOutput("scatter", height = 240), type = "scatter")),
        demo_card('Histogram  (type = "histogram")',
                  withBones(plotOutput("histogram", height = 240), type = "histogram")),
        demo_card('Pie  (type = "pie")', withBones(plotOutput("pie", height = 240), type = "pie")),
        demo_card('Heatmap  (type = "heatmap")',
                  withBones(plotOutput("heatmap", height = 240), type = "heatmap"))
      )
    ),

    nav_panel(
      "Tables",
      tags$p(
        class = "text-muted",
        "A table package says which package it is, so each table gets the shape ",
        "of its package with no type."
      ),
      layout_column_wrap(
        width = "400px",
        demo_card("tableOutput()", withBones(tableOutput("plain"), rows = 8)),
        optional_card("DT", "DT::DTOutput()", withBones(DT::DTOutput("dt"), rows = 8)),
        optional_card("reactable", "reactable::reactableOutput()",
                      withBones(reactable::reactableOutput("reactable"), rows = 8)),
        # Before gt 1.0.0, gt_output() did not mark its output as a gt table,
        # so an older gt needs the type. webR, for the live demo, has an
        # older gt.
        optional_card("gt", "gt::gt_output()", withBones(
          gt::gt_output("gt"), rows = 8, cols = 5,
          type = if (utils::packageVersion("gt") < "1.0.0") "gt"
        ))
      )
    ),

    nav_panel(
      "Text and cards",
      tags$p(
        class = "text-muted",
        "A uiOutput() can hold anything, so it names its shape with type, or ",
        "brings a placeholder of its own. The summary has stale = FALSE, so it ",
        "always shows its skeleton."
      ),
      demo_card('Value boxes  (type = "value")', withBones(uiOutput("values"), type = "value", n = 3)),
      demo_card('Cards  (type = "cards")', withBones(uiOutput("cards"), type = "cards", n = 3)),
      demo_card("Your own placeholder  (skeleton = )",
                withBones(uiOutput("regions"), skeleton = region_skeleton, height = 160)),
      demo_card("textOutput(), stale = FALSE",
                withBones(textOutput("summary"), lines = 3, stale = FALSE))
    ),

    # Not in the live demo. A NULL tab is left out.
    if (!LIVE) nav_panel(
      "Maps and networks",
      tags$p(
        class = "text-muted",
        "A visualisation widget says what it is too: a leaflet map gets the map ",
        "shape, and a visNetwork graph gets the network shape."
      ),
      layout_column_wrap(
        width = "400px",
        optional_card("leaflet", "leaflet::leafletOutput()",
                      withBones(leaflet::leafletOutput("map", height = 320))),
        optional_card("visNetwork", "visNetwork::visNetworkOutput()",
                      withBones(visNetwork::visNetworkOutput("network", height = "320px")))
      )
    )
  )
)
