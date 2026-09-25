server <- function(input, output, session) {

  # --- One slow reactive for all the outputs -----------------------------------
  # "Load new data" makes new data after the chosen load time. The load time
  # is read with isolate(), so moving the slider does not start a load.
  data <- reactive({
    input$refresh
    Sys.sleep(isolate(input$seconds))
    make_data()
  })

  # A plot with a transparent background, so it suits the dark mode too.
  # `draw` is a function of the data. It is not an expression: R evaluates
  # an argument only once, so the plot would not read data() again.
  chart <- function(draw) {
    renderPlot(bg = "transparent", {
      d <- data()
      grey <- "#888888"   # reads on a light and on a dark page
      par(mar = c(3, 3, 1, 1), mgp = c(2, 0.6, 0), las = 1,
          fg = grey, col.axis = grey, col.lab = grey)
      draw(d)
    })
  }
  blue <- "#4c72b0"

  # --- Charts -------------------------------------------------------------------
  output$bar <- chart(function(d) barplot(d$sales, col = blue, border = NA))
  output$line <- chart(function(d) plot(d$trend, type = "l", lwd = 2, col = blue, xlab = "Month", ylab = ""))
  output$scatter <- chart(function(d) plot(d$points, pch = 19, col = "#4c72b099", xlab = "Height", ylab = "Weight"))
  output$histogram <- chart(function(d) {
    hist(d$ages, breaks = 20, col = blue, border = "white", main = "", xlab = "Age")
  })
  output$pie <- chart(function(d) pie(d$share, col = c(blue, "#dd8452", "#55a868", "#c44e52"), border = "white"))
  output$heatmap <- chart(function(d) image(d$grid, col = hcl.colors(20, "Blues", rev = TRUE), axes = FALSE))

  # --- Tables -------------------------------------------------------------------
  orders <- reactive(head(data()$orders, 8))

  output$plain <- renderTable(orders())

  if (HAS[["DT"]]) {
    output$dt <- DT::renderDT(DT::datatable(data()$orders, rownames = FALSE,
                                            options = list(pageLength = 8)))
  }
  if (HAS[["reactable"]]) {
    output$reactable <- reactable::renderReactable(
      reactable::reactable(data()$orders, defaultPageSize = 8)
    )
  }
  if (HAS[["gt"]]) {
    output$gt <- gt::render_gt(
      gt::gt(orders()) |>
        gt::tab_header("Orders", "The first eight") |>
        gt::tab_spanner("Amount", c(units, price)) |>
        gt::tab_source_note("Random data, made again on each load")
    )
  }

  # --- Text and cards -----------------------------------------------------------
  output$values <- renderUI({
    d <- data()
    layout_column_wrap(
      width = 1 / 3,
      value_box("Total sales", format(sum(d$sales), big.mark = ",")),
      value_box("Best region", names(which.max(d$sales))),
      value_box("Orders", nrow(d$orders))
    )
  })

  output$cards <- renderUI({
    d <- data()
    layout_column_wrap(
      width = 1 / 3,
      !!!lapply(names(sort(d$sales, decreasing = TRUE))[1:3], function(region) {
        card(card_header(region), card_body(sprintf("%s units sold", d$sales[[region]])))
      })
    )
  })

  output$regions <- renderUI({
    d <- data()
    top <- sort(d$sales, decreasing = TRUE)[1:3]
    div(
      style = "display: grid; gap: 0.5rem;",
      lapply(names(top), function(region) {
        region_row(
          div(class = "rounded-circle bg-primary text-white d-flex align-items-center ",
              class = "justify-content-center fw-bold",
              style = "width: 48px; height: 48px;", substr(region, 1, 1)),
          strong(region),
          span(class = "text-muted small", sprintf("%s units sold", top[[region]]))
        )
      })
    )
  })

  output$summary <- renderText({
    d <- data()
    sprintf(
      paste("Across %d regions, sales were %s units. The best region was %s.",
            "The average price of an order was %.2f."),
      length(d$sales), format(sum(d$sales), big.mark = ","),
      names(which.max(d$sales)), mean(d$orders$price)
    )
  })

  # --- Maps and networks --------------------------------------------------------
  if (HAS[["leaflet"]]) {
    output$map <- leaflet::renderLeaflet({
      s <- data()$stores
      leaflet::leaflet(s) |>
        leaflet::addTiles() |>
        leaflet::addMarkers(~lng, ~lat)
    })
  }
  if (HAS[["visNetwork"]]) {
    output$network <- visNetwork::renderVisNetwork({
      data()
      nodes <- data.frame(id = 1:10, label = LETTERS[1:10])
      edges <- data.frame(from = sample(1:10, 14, replace = TRUE), to = sample(1:10, 14, replace = TRUE))
      # Grey labels read on a light and on a dark page, as on the plots.
      visNetwork::visNetwork(nodes, edges) |>
        visNetwork::visNodes(font = list(color = "#888888"))
    })
  }
}
