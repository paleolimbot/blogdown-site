---
title: Calculating lake outlets using R
author: Dewey Dunnington
date: '2020-04-22'
slug: calculating-lake-outlets-using-r
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2020-04-22T20:06:14-03:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---



If you can't tell from my [last](/post/2020/stream-networks-using-r-and-sf/) two [posts](/post/2020/calling-qgis-from-r/), I'm trying to delineate watersheds for about 650 lakes. We've gotten to the point where we can calculate an approximate catchment using the upstream network, and call the QGIS processing algorithms we need to delineate the catchment from the outlet. The problem is, we don't know which outlet point will give us the catchment we're looking for. We'll use [sf](https://r-spatial.github.io/sf) for vector handling and [raster](https://rspatial.org/raster/) for raster handling.


```r
library(sf)
library(raster)
```

Next, we'll need some test data. I'm using the same area as in the [last post](/post/2020/calling-qgis-from-r/), which is a tiny lake in southwest Nova Scotia. In addition to the lake (as a polygon), we also need the flow accumulation raster. This represents the number of cells that flow through any given cell, or the relative watershed area of any given cell. This is one of the outputs of GRASS' [r.watershed](https://grass.osgeo.org/grass78/manuals/r.watershed.html), and is also an output of the corresponding ArcHydro function.


```r
lake <- read_sf("lakes.shp")
accumulation <- raster("accumulation.tif")

plot(accumulation)
plot(lake$geometry, add = T)
```

<img src="unnamed-chunk-2-1.png" width="672" />

One curious feature of the default r.watershed output is that negative values indicate likely underestimates of flow accumulation. This means that what we really want is the `abs()` of the accumulation, which we will apply when we crop later.

From a delineation perspective, clicking on the points with a high flow accumulation value will give us a bigger total watershed, and for a lake, we want the maximum watershed along the lake boundary. In GIS-speak, we need the location of the maximum flow accumulation along the boundary of the lake polygon. Because the raster cell size is 20 m, I think it makes sense to include a buffer of 40 m on either side of the lake boundary, which we can calculate using `st_buffer()` and `st_boundary()`.


```r
boundary <- st_boundary(lake) %>% st_buffer(40)

plot(accumulation)
plot(lake$geometry, add = T)
plot(boundary$geometry, add = T, border = "red")
```

<img src="unnamed-chunk-3-1.png" width="672" />

We *could* find the location of the maximum value with in the `boundary` using the whole `accumulation` raster, but in my case, the `accumulation` raster is 2 GB and covers the whole province of Nova Scotia. Luckily, `raster()` is lazy and doesn't load values unless absolutely necessary, which includes a `crop()` operation.


```r
accumulation_crop <- crop(accumulation, extent(lake))
```

To extract the accumulation values only within `boundary`, I'm going to first create a "mask", which will be `1` within the polygon and `NA` outside it. Then, I'm going to multiply that by `abs(accumulation_crop)` to get the actual accumulation cell values. This works because `NA` values propogate through the calculation.


```r
mask_boundary <- rasterize(as_Spatial(boundary), accumulation_crop)
accumulation_boundary <- mask_boundary * abs(accumulation_crop)

plot(accumulation_boundary)
```

<img src="unnamed-chunk-5-1.png" width="672" />

Now we need the location of the maximum value! The function for this is `which.max()`, but we also need `xyFromCell()` to convert that value into a matrix of x and y values. This is more useful as a `st_sfc()`, which plays nicely with the sf package.


```r
outlet_xy <- xyFromCell(accumulation_boundary, which.max(accumulation_boundary))
outlet <- st_sfc(st_point(outlet_xy), crs = st_crs(lake))

plot(accumulation_boundary)
plot(outlet, add = T)
```

<img src="unnamed-chunk-6-1.png" width="672" />

It worked! At scale, you might run into a situation where there this returns more than one outlet per lake (most likely in tiny lakes). You also will run into situations where this returns only one outlet, but in order to capture the whole watershed of the lake you might need more than one "outlet" (because the flow accumulation raster has a mind of its own). I don't have a good automatic solution for this, but you could convert the raster values to points using `ggspatial::df_spatial(accumulation_boundary)` and do some [dplyr](https://dplyr.tidyverse.org/) magic to find more than one probable outlet.


```r
ggspatial::df_spatial(accumulation_boundary) %>% 
  dplyr::filter(!is.na(band1)) %>% 
  dplyr::arrange(desc(band1))
```

```
## # A tibble: 530 x 3
##         x       y band1
##     <dbl>   <dbl> <dbl>
##  1 252858 4889828 2447.
##  2 252838 4889828 2289.
##  3 252738 4889808 1940.
##  4 252718 4889808 1895.
##  5 252818 4889828 1773.
##  6 252758 4889808 1713.
##  7 252698 4889808 1685.
##  8 252678 4889808 1618.
##  9 252798 4889828 1574.
## 10 252778 4889828 1380.
## # … with 520 more rows
```

