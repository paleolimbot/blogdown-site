
library(tidyverse)

papers <- jsonlite::read_json("content/publication/papers.json", simplifyDataFrame = FALSE, simplifyVector = TRUE)

for(original_item in papers) {
  item <- original_item
  item$author <- lapply(transpose(item$author), vapply, identity, character(1))
  item$abstract <- item$abstract %||% ""
  item$issue <- item$issue %||% ""
  item$volume <- item$volume %||% ""
  item$page <- item$page %||% ""
  
  item_dir <- file.path("content/publication", item$id)
  if (dir.exists(item_dir)) {
    message("Skipping ", item$id, ": directory '", item_dir, "' already exists")
    next
  }
  
  index_content <- glue::glue_data(item, read_file("content/publication/paper.md.template"))
  bib_content <- glue::glue_data(
    item, 
    read_file("content/publication/paper.bib.template"),
    .open = "[[", .close = "]]"
  )
  
  dir.create(item_dir)
  if (!dir.exists(item_dir)) stop("Could not create directory '", item_dir, "'")
  write_file(index_content, file.path(item_dir, "index.md"))
  write_file(bib_content, file.path(item_dir, "cite.bib"))
  jsonlite::write_json(original_item, file.path(item_dir, "cite.json"))
}

conferences <- jsonlite::read_json("content/publication/conferences.json", simplifyDataFrame = FALSE, simplifyVector = TRUE)

for(original_item in conferences) {
  item <- original_item
  item$author <- lapply(transpose(item$author), vapply, identity, character(1))
  item$abstract <- item$abstract %||% ""
  item$issue <- item$issue %||% ""
  item$volume <- item$volume %||% ""
  item$page <- item$page %||% ""
  item$URL <- item$url %||% ""
  item$DOI <- item$DOI %||% ""
  item$id <- paste0("conf_", item$id)
  
  item_dir <- file.path("content/publication", item$id)
  if (dir.exists(item_dir)) {
    message("Skipping ", item$id, ": directory '", item_dir, "' already exists")
    next
  }
  
  index_content <- glue::glue_data(item, read_file("content/publication/conference.md.template"))
  bib_content <- glue::glue_data(
    item, 
    read_file("content/publication/conference.bib.template"),
    .open = "[[", .close = "]]"
  )
  
  dir.create(item_dir)
  if (!dir.exists(item_dir)) stop("Could not create directory '", item_dir, "'")
  write_file(index_content, file.path(item_dir, "index.md"))
  write_file(bib_content, file.path(item_dir, "cite.bib"))
  jsonlite::write_json(original_item, file.path(item_dir, "cite.json"))
}
