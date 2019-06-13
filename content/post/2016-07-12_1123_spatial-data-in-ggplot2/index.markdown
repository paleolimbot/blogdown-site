---
title: 'Spatial data in ggplot2'
author: Dewey Dunnington
date: '2016-07-12'
slug: []
categories: []
tags: ["ggspatial", "gis", "R", "Releases"]
subtitle: ''
summary: ''
authors: []
lastmod: '2016-07-12T14:22:41+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---


I recently figured out how to use the ggplot2 framework to plot raster data, which led me to write a package extending ggplot2 for more convenient spatial data geometries. Ever wanted a `geom_spatial()` for those `SpatialPolygonsDataFrame`s and `RasterBrick`s you've got kicking around? Well...maybe you did or didn't, but the [ggspatial](https://github.com/paleolimbot/ggspatial) package is now here for your spatial data/ggplot-ing pleasure. It needs some work (and feedback) before it becomes a CRAN release, but in the meantime it should do the trick for most things spatial. Unfortunately, there is a bug when using `coord_fixed()` and `scales="free"` with facetting in ggplot, so facetting with different spatial extents is out. Luckily, that's not particularly common (probably more common is to vary the aesthetic with the same spatial extent which still isn't quite there yet in this package), so give it a shot!

``` r
install.packages("devtools") # if devtools isn't installed
devtools::install_github("paleolimbot/ggspatial")
library(ggspatial)
data(longlake_waterdf, longlake_depthdf)
ggplot() + geom_spatial(longlake_waterdf[2,], fill="lightblue") +
  geom_spatial(longlake_depthdf, aes(col=DEPTH.M), size=2) + 
  scale_color_gradient(high="black", low="#56B1F7") + coord_fixed()
```

[caption id="attachment_1124" align="alignleft" width="672"]<img src="unnamed-chunk-4-1.png" alt="All the ggplot goodness with your spatial data" width="672" height="480" class="size-full wp-image-1124" /> All the ggplot goodness with your spatial data[/caption]