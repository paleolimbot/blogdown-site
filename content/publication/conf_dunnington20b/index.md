---
abstract: "The ggplot2 package is widely acknowledged as a powerful, dynamic, and easy-to-learn graphics framework when used in an interactive environment. Using ggplot2 in a package or Shiny app environment adds several constraints which are sometimes circumvented using ggplot2 behaviour that may change in the future. Some best practices include (1) using the `.data` pronoun to refer to the layer data within `aes()` and `vars()` instead of the original variable name, (2) ensuring that `plot()` methods that use ggplot2 explicitly `print()` one or more ggplot objects, (3) defining extension themes that modify a complete theme within ggplot2 (like `theme_gray()`), and (4) testing graphical output using the vdiffr package. Collectively, these practices result in better error messages with unexpected user input and ensure compatibility with most versions of ggplot2, including those to come in the future."
authors: ["D.W. Dunnington"]
date: "2020-01-01"
doi: ""
featured: false
image:
  caption: ""
  focal_point: ""
  preview_only: false
projects: []
publication: "RStudio Conference"
publication_short: ""
publication_types: ["1"]
summary: ""
tags: []
title: "Best practices for programming with ggplot2"
url_code: ""
url_dataset: ""
url_pdf: ""
url_poster: ""
url_project: "https://ggplot2.tidyverse.org/articles/ggplot2-in-packages.html"
url_slides: "https://fishandwhistle.net/slides/rstudioconf2020"
url_source: ""
url_video: "https://resources.rstudio.com/rstudio-conf-2020/best-practices-for-programming-with-ggplot2-dewey-dunnington"
---