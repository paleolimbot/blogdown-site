---
title: "Bathymetry & Lake Volume Estimation using R"
author: Dewey Dunnington
date: '2019-11-14'
slug: bathymetry-lake-volume-estimation-using-r
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2019-11-14T12:39:56-05:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---



I've been curious about bathymetry ever since I was a kid, when I could often be found pouring over charts of Lake Champlain during family sailing vacations. Little did I know that two decades later I would be making some of those maps myself! I often work on small lakes, and the ability to compute simple bathymetry without leaving R is something I've been toying with but never written up. After meeting some folks at the North American Lake Management Society conference that were curious about how to do all the steps without resorting to Arc or QGIS, I decided it was time. While my favourite interpolation method isn't available in R ([regularized spline tension](https://doi.org/10.1007/BF00893171) from the GRASS toolbox in QGIS), a number of others are, including TIN, Inverse Distance Weighting (IDW), and GAM methods.

I'll start with the loading of packages: I use the [tidyverse](https://tidyverse.org/) for dplyr and ggplot2, I use [sf](https://r-spatial.github.io/sf) for spatial reading, writing, and manipulation, and I use [ggspatial](https://github.com/paleolimbot/ggspatial) for the example data and some plotting help.


```r
library(tidyverse)
library(sf)
library(ggspatial)
```

The example data I'm using is from my honours thesis, and consists of a small depth survey I did on my study lake. I'm using `transmute()` to add a "source" note and rename the depth column. For doing interpolation, it's important that the data are in a coordinate system that is in meters (easting and northing). UTM usually works well for single lakes, in this case UTM zone 20N.


```r
measured_depths <- read_sf(
  system.file(
    "longlake/LongLakeDepthSurvey.shp", 
    package = "ggspatial"
  )
) %>%
  transmute(source = "measured", depth = DEPTH_M) %>%
  st_transform(26920)

measured_depths
```

```
## Simple feature collection with 64 features and 2 fields
## geometry type:  POINT
## dimension:      XY
## bbox:           xmin: 409967.1 ymin: 5083354 xmax: 411658.7 ymax: 5084777
## epsg (SRID):    NA
## proj4string:    +proj=utm +zone=20 +ellps=GRS80 +units=m +no_defs
## # A tibble: 64 x 3
##    source   depth           geometry
##  * <chr>    <dbl>        <POINT [m]>
##  1 measured   0.8 (411658.7 5084501)
##  2 measured   0.9 (411630.3 5084560)
##  3 measured   0.8 (411553.4 5084601)
##  4 measured   0.8 (411476.4 5084600)
##  5 measured   1.4 (411466.8 5084488)
##  6 measured   0.6 (411466.4 5084410)
##  7 measured   1.4 (411379.1 5084490)
##  8 measured   0.8 (411321.2 5084721)
##  9 measured   1.4 (411292.9 5084670)
## 10 measured   1.5 (411290.8 5084593)
## # … with 54 more rows
```

The other thing we need is the boundary of the lake as a polygon layer. We can use this to establish zero-points on the edge of the lake as well as clip our final raster to the extent of the lake. I'm using `st_zm()` here to drop the Z information from the coordinates...this is something that comes with the Nova Scotia water layer shapefile that causes errors later. It's important that the CRS of the boundary is the same as the CRS of the data.


```r
boundary <- read_sf(
  system.file(
    "longlake/LongLakeMarshWaterPoly.shp", 
    package = "ggspatial"
  )
) %>%
  filter(label == "Long Lake") %>%
  transmute(source = "boundary", depth = 0) %>%
  st_transform(26920) %>%
  st_zm()

boundary
```

```
## Simple feature collection with 1 feature and 2 fields
## geometry type:  POLYGON
## dimension:      XY
## bbox:           xmin: 409949.5 ymin: 5083316 xmax: 411757.1 ymax: 5084852
## epsg (SRID):    26920
## proj4string:    +proj=utm +zone=20 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs
## # A tibble: 1 x 3
##   source   depth                                                   geometry
## * <chr>    <dbl>                                              <POLYGON [m]>
## 1 boundary     0 ((411505.3 5084641, 411512.3 5084641, 411519.3 5084643, 4…
```

Finally, we can have a look at the measurements. Long Lake is on the edge of a floating bog, so on some edges of the lake the depth is not zero! I will still approximate the shoreline as zero later, but it's good to be aware that the assumption may not hold.


```r
ggplot() +
  geom_sf(data = boundary) +
  geom_sf_text(aes(label = depth), data = measured_depths, size = 2.5) +
  annotation_scale(location = "br")
```

<img src="input-data-1.png" width="672" />

All the different analysis methods require either (1) a spatial object of some kind or (2) a data frame with X, Y, and depth values. You can convert the boundary polygon to points using `st_cast()`, combine it with the measured values using `rbind()`, and add `X` and `Y` coordinates using the `%>% cbind(., st_coordinates(.))` trick. I wish there were a more elegant way to add the coordinates as columns, but this is the cleanest way I've been able to find. At the end, we have `depths`, a data frame with a point geometry column and X, Y, and depth values.


```r
boundary_points <- st_cast(boundary, "POINT")
depths <- rbind(boundary_points, measured_depths) %>%
  cbind(., st_coordinates(.))

depths
```

```
## Simple feature collection with 552 features and 4 fields
## geometry type:  POINT
## dimension:      XY
## bbox:           xmin: 409949.5 ymin: 5083316 xmax: 411757.1 ymax: 5084852
## epsg (SRID):    26920
## proj4string:    +proj=utm +zone=20 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs
## First 10 features:
##      source depth        X       Y                 geometry
## 1  boundary     0 411505.3 5084641 POINT (411505.3 5084641)
## 2  boundary     0 411512.3 5084641 POINT (411512.3 5084641)
## 3  boundary     0 411519.3 5084643 POINT (411519.3 5084643)
## 4  boundary     0 411524.4 5084646 POINT (411524.4 5084646)
## 5  boundary     0 411532.5 5084651 POINT (411532.5 5084651)
## 6  boundary     0 411537.5 5084652 POINT (411537.5 5084652)
## 7  boundary     0 411559.4 5084647 POINT (411559.4 5084647)
## 8  boundary     0 411564.4 5084646 POINT (411564.4 5084646)
## 9  boundary     0 411566.4 5084646 POINT (411566.4 5084646)
## 10 boundary     0 411569.4 5084649 POINT (411569.4 5084649)
```

We need a similar object for the regularly-spaced output that we will use to create a raster at the end. This can be created using `st_make_grid()`, where here I've made the cell size 10 m by 10 m. I use the coordinates trick again because some methods need the coordinates (`X` and `Y`) while other methods need a spatial object.


```r
grid <- st_make_grid(depths, cellsize = c(10, 10), what = "centers") %>%
  st_as_sf() %>% 
  filter(st_contains(boundary, ., sparse = FALSE)) %>%
  cbind(., st_coordinates(.))
```

### TIN

The triangular irregular network surface (TIN) connects points using a Delaunay triangulation (a network of triangles as round as possible) and approximates each triangle as a plane. It results in contours that are pointier than you may be hoping for, but doesn't predict any values higher or lower than you measured and is a good reality check on any other method as its main assumption is that you bothered to take a depth measurement anywhere that it mattered. This can be done using the `interpp()` (two p's!) function in the [interp](https://cran.r-project.org/package=interp) (one p!) package:


```r
fit_TIN <- interp::interpp(
  x = depths$X,
  y = depths$Y,
  z = depths$depth,
  xo = grid$X,
  yo = grid$Y,
  duplicate = "strip"
)

grid$TIN <- fit_TIN$z
```

Here, `x` and `y` are the coordinates, `z` is the depth, and `xo`/`yo` are the desired output coordinates (in our case, the grid of equally-spaced points we created). The `interp::interpp()` function returns a list with `x`, `y`, and `z` components, of which we only need the `z`. I'm adding the resulting predicted depth values as a column in `grid` so that I can compare the methods in the end.

### Inverse Distance Weighting (IDW)

IDW works on the premise that the depth at any given point is related to that of surrounding points, and that points that are farther away are less related than closer points. While this sounds reasonable, in practice, IDW makes terrible bathymetry maps because the points tend to be visible as artifacts on the final raster (at the end when I plot this you'll see what I  mean). You can mitigate this to a certain extent by constraining the number of points IDW is allowed to consider and fiddling with the inverse distance power. I used the [gstat](https://cran.r-project.org/package=gstat) package for this, which can also do kriging.


```r
fit_gstat <- gstat::gstat(
  formula = depth ~ 1,
  data = as(depths, "Spatial"),
  nmax = 10, nmin = 3,
  set = list(idp = 0.5)
)

grid$IDW <- predict(fit_gstat, newdata = as(grid, "Spatial")) %>%
  st_as_sf() %>%
  pull(1)
```

```
## [inverse distance weighted interpolation]
```

The `gstat::gstat()` function returns a "fit" object, which we can then pass to `predict()` to get values at new locations. This is a common idiom in R. The gstat package uses spatial objects, but uses the version of spatial objects from the older sp package. You can convert between these using `as(sf_object, "Spatial")` and `st_as_sf()`. 

### Thin Plate Regression Spline (TPRS)

Ever since I read [Gavin Simpson's excellent blog post on bathymetry using GAMs](https://www.fromthebottomoftheheap.net/2016/03/27/soap-film-smoothers/) I've wanted to give it a shot! A GAM is a general additive model, and tends to produce nice smooth surfaces. For bathymetry maps, this means nice smooth contour lines, possibly at the expense of reality. You will need to fiddle with the `k` value to make sure the level of smoothness matches your idea of how smooth the lake bottom is. According to the blog post, this is called a "thin plate regression spline".


```r
library(mgcv)
fit_gam_reml <- mgcv::gam(depth ~ s(X, Y, k = 60), data = depths, method = "REML")
grid$TPRS <- predict(fit_gam_reml, newdata = grid, type = "response")
```

The TPRS method also uses the "fit then predict" idiom, and uses the x, y, and depth values rather than the spatial part of the object.

### Soap Film Smooth

Another method that uses a GAM is a soap film smoother, which actively takes into account the border boundary condition. Specifying the boundary is a bit interesting as it uses a custom format, but following the instructions in the blog post I was able to make it work. I had to disregard the first point in `boundary_coords` because the first and last points were identical, which resulted in errors fitting the model. The soap film smoother also needs explicit knot locations (the place where the splines join together) that are (well) within the boundary. I made this work by making another grid and excluding points that were outside the boundary or were inside the boundary by 10 meters or less (that's why there's an `st_buffer(10)` in there).


```r
boundary_coords <- st_coordinates(boundary)

gam_bound <- list(
  list(
    X = boundary_coords[-1, "X"], 
    Y = boundary_coords[-1, "Y"], 
    f = rep(0, nrow(boundary_coords))
  )
)

knot_points <- st_make_grid(
  boundary,
  n = c(10, 10),
  what = "centers"
) %>%
  st_as_sf() %>%
  filter(st_contains(boundary, x, sparse = FALSE)) %>%
  filter(
    !st_intersects(
      boundary %>% st_cast("LINESTRING") %>% st_buffer(10), 
      x, 
      sparse = FALSE
    )
  ) %>%
  cbind(., st_coordinates(.))

fit_gam_soap <- gam(
  depth ~ s(X, Y, bs = "so", xt = list(bnd = gam_bound)),
  data = depths %>% 
    filter(source == "measured") %>% 
    filter(st_contains(boundary, geometry, sparse = FALSE)), 
  method = "REML", 
  knots = knot_points
)

grid$GAM_Soap <- predict(fit_gam_soap, newdata = grid, type = "response")
```

I found this method complicated, but the fact that the model has assumptions that line up with reality (zero depth around the edge of the lake) means that it may work quite well in some circumstances. As you'll see shortly, it didn't work particularly well for this data set.

### Computing volume

One of the purposes of interpolating bathymetry to a fine grid is to estimate volume. I think the best way to do this is to take the mean depth and multiply by the area of the lake, which works regardless of the cell size used. Note that `grid` was clipped to the boundary when it was created, so there aren't any estimates from outside the lake that are being used for the volume calculation. For the TIN interpolation, the calculation would look like this:


```r
boundary_area <- st_area(boundary) %>% 
  as.numeric()

grid %>% 
  st_set_geometry(NULL) %>% 
  summarise(
    mean_depth = mean(TIN),
    volume = mean(TIN) * boundary_area
  )
```

```
##   mean_depth   volume
## 1  0.9387065 911488.1
```

### Contouring

Another purpose of interpolating bathymetry is to generate a raster or contours to bring in to mapping software. These can both be done using the [raster](https://cran.r-project.org/package=raster) package, which can create a raster from an evenly-spaced grid with z values. This function needs a data frame with exactly three columns and no geometry column. For contours, you can specify the levels or leave them blank to have them picked for you, and you have to convert them back to sf format (they are produced in sp format). Again for the TIN interpolation, it would look like this:


```r
depth_raster <- grid %>% 
  st_set_geometry(NULL) %>% 
  select(X, Y, TIN) %>% 
  raster::rasterFromXYZ(crs = raster::crs("+init=epsg:26920"))

depth_contours <- depth_raster %>% 
  raster::rasterToContour(levels = c(0.5, 1, 1.5)) %>% 
  st_as_sf()
```

### Plotting

A really good map needs GIS software, but you can get pretty close with [ggplot2](https://ggplot2.tidyverse.org/) and ggspatial (for the scale bar).


```r
ggplot(grid) +
  geom_sf(data = boundary) +
  geom_raster(aes(X, Y, fill = TIN)) +
  geom_sf(data = depth_contours) +
  scale_fill_viridis_c() +
  annotation_scale(location = "br") +
  labs(x = NULL, y = NULL, fill = "Depth (m)")
```

<img src="result-one-1.png" width="672" />

### Comparing models

So how do the models stack up!? I don't have a comprehensive evaluation in this post, but if you take a look at them all it's clear that IDW and the soap film smooth have some problems: the sampling points are somewhat visible in the IDW raster (which is very much influenced by the high density of border points) and the soap film smooth shorelines are all 1 m deep. The contour lines for the thin plate regression spline looked the best (but overestimated depth next to the steep northern slope of the lake), and the TIN interpolation made the fewest assumptions, although it probably underestimated the depth in the neck of the lake.



<img src="unnamed-chunk-12-1.png" width="672" />

As anybody who has created bathymetry models would know, every lake is different! And every lake will probably need its own bathymetry methods (especially the  complex ones). I'd like have it be easier to use GRASS and QGIS from inside R, which would open up some better algorithms that might apply more generally (I'm looking at you, RST).
