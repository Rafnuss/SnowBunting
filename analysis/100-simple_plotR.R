library(leaflet)
library(dplyr)
library(htmlwidgets)
library(webshot) # install_github("wch/webshot")
# webshot::install_phantomjs()

list_id <- tail(
  names(yaml::yaml.load_file("config.yml", eval.expr = FALSE)),
  -1
)
library(tidyverse)
paths <- map_dfr(seq_along(list_id), function(i) {
  id <- list_id[[i]]
  cli::cli_h1("Run tag_download_wind for {id}")
  load(glue::glue("./data/interim/{id}.RData"))
  path_most_likely$tag_id <- id # make j unique per tag
  path_most_likely
})

# Generate a color palette for unique tag IDs
tag_ids <- unique(paths$tag_id)
color_palette <- colorFactor(palette = "Set1", domain = tag_ids)

leaflet_map <- leaflet(height = 600) %>% addTiles()

# Add polylines and markers for each tag_id
for (tag in tag_ids) {
  bird_subset <- paths %>% filter(tag_id == tag)
  leaflet_map <- leaflet_map %>%
    addPolylines(
      lng = ~lon,
      lat = ~lat,
      data = bird_subset,
      color = color_palette(tag),
      weight = 2,
      popup = ~ paste0("Tag ID: ", tag_id, "<br>Step: ", stap_id)
    ) %>%
    addCircleMarkers(
      lng = ~lon,
      lat = ~lat,
      data = bird_subset,
      color = color_palette(tag),
      radius = 4,
      fillOpacity = 0.8,
      popup = ~ paste0("Tag ID: ", tag_id, "<br>Step: ", stap_id)
    )
}

# Add a legend
leaflet_map <- leaflet_map %>%
  addLegend(
    position = "topright",
    pal = color_palette,
    values = tag_ids,
    title = "Bird Trajectories",
    opacity = 1
  )

# Display the map
leaflet_map


# Export
saveWidget(leaflet_map, "temp.html", selfcontained = FALSE)
webshot("temp.html", file = "Rplot.png", cliprect = "viewport")
