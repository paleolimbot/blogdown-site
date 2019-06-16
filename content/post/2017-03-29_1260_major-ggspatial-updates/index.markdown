---
title: 'Major ggspatial updates'
author: Dewey Dunnington
date: '2017-03-29'
slug: []
categories: []
tags: ["ggplot", "ggspatial", "R", "Releases", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2017-03-28T21:41:37+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
aliases: [/archives/1260]
---


I took the day to update [ggspatial](https://github.com/paleolimbot/ggspatial) an old R project that was never published to CRAN. The idea is to create [ggplot](https://github.com/tidyverse/ggplot2) `layer()` calls from [sp](https://github.com/edzer/sp) Spatial* objects using a consistent interface. Last year I wrote a blog post about how that might work, and while the usage hasn't changed much, the implementation is now much, much, much, (much!) cleaner, and a few things have been removed that were never really going to work out. One of those is the `geom_osm()` function, which needs some serious soul searching given better options (like [ggmap](https://github.com/dkahle/ggmap) and [rosm](https://github.com/paleolimbot/ggspatial)).

In the meantime, you can do some pretty seriously cool work with vector layers, including aesthetic mapping, facets, multiple projections, and more! Check it out!

``` r
ggspatial(longlake_waterdf, fill="lightblue") +
   geom_spatial(longlake_marshdf, fill="grey", alpha=0.5) +
   geom_spatial(longlake_streamsdf, col="lightblue") +
  coord_map()
```

![](unnamed-chunk-7-1.png)

