---
title: "Using a Hexagonal Grid for Canada's Election Map"
author: Dewey Dunnington
date: '2019-10-21'
slug: canada-ridings-hex
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2019-10-21T09:46:25-03:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---



Us Canadians are going to be looking at a lot of election maps in the next few hours, so I thought I'd try to make a few! First, we need to download the [Riding geography](https://open.canada.ca/data/en/dataset/737be5ea-27cf-48a3-91d6-e835f11834b0) from open Canada (there is more extensive information on [Elections](https://lop.parl.ca/sites/ParlInfo/default/en_CA/ElectionsRidings/Elections) and [Ridings](https://lop.parl.ca/sites/ParlInfo/default/en_CA/ElectionsRidings/Ridings) at the Library of Parliament website). Next, we need the [tidyverse](https://tidyverse.org) and the [sf](https://r-spatial.github.io/sf/) packages.


```r
library(tidyverse)
library(sf)
```

```
## Linking to GEOS 3.6.1, GDAL 2.1.3, PROJ 4.9.3
```

The riding boundaries come in shapefile format, which is handled by a one-liner to `read_sf()`. I'm going to simplify the boundaries a bit to speed up the plotting time. The `dTolderance` argument is in map units, and it took some experimenting to settle on the number 100.


```r
ridings <- read_sf("boundaries_2015_shp_en/FED_CA_2_2_ENG.shp") %>%
  st_simplify(dTolerance = 100)
ridings
```

```
## Simple feature collection with 347 features and 13 fields
## geometry type:  GEOMETRY
## dimension:      XY
## bbox:           xmin: 3658201 ymin: 658873 xmax: 9019157 ymax: 6083005
## epsg (SRID):    NA
## proj4string:    +proj=lcc +lat_1=49 +lat_2=77 +lat_0=63.390675 +lon_0=-91.86666666666666 +x_0=6200000 +y_0=3000000 +datum=NAD83 +units=m +no_defs
## # A tibble: 347 x 14
##    FED_NUM NID   FEDNUM ENNAME FRNAME PROVCODE CREADT REVDT REPORDER
##      <dbl> <chr>  <dbl> <chr>  <chr>  <chr>    <chr>  <chr> <chr>   
##  1   35029 {30F…  35029 Etobi… Etobi… ON       20131… <NA>  2013    
##  2   35032 {39A…  35032 Guelph Guelph ON       20131… <NA>  2013    
##  3   48017 {C3B…  48017 Edmon… Edmon… AB       20131… <NA>  2013    
##  4   48018 {C5B…  48018 Edmon… Edmon… AB       20131… <NA>  2013    
##  5   48021 {BBF…  48021 Edmon… Edmon… AB       20131… <NA>  2013    
##  6   48022 {F45…  48022 Footh… Footh… AB       20131… <NA>  2013    
##  7   48023 {B4C…  48023 Fort … Fort … AB       20131… <NA>  2013    
##  8   48024 {4CA…  48024 Grand… Grand… AB       20131… 2014… 2013    
##  9   48025 {722…  48025 Lakel… Lakel… AB       20131… <NA>  2013    
## 10   24065 {858…  24065 Marc-… Marc-… QC       20131… 2014… 2013    
## # … with 337 more rows, and 5 more variables: DECPOPCNT <dbl>,
## #   QUIPOPCNT <dbl>, ENLEGALDSC <chr>, FRLEGALDSC <chr>, geometry <POLYGON
## #   [m]>
```

Next, we can plot! I opted to use [ggplot2](https://ggplot2.tidyverse.org/)'s `geom_sf()`, using `theme_void()` to strip away the axes/labels.


```r
ggplot(ridings) + 
  geom_sf(aes(fill = PROVCODE)) + 
  theme_void()
```

<img src="fig-ridings-geo-1.png" width="672" />

This is the type of map that all the major outlets are using to communicate election results (I'm looking at you, [CBC](https://newsinteractives.cbc.ca/elections/federal/2019/results/) and [Global](https://globalnews.ca/news/6023150/live-canada-election-results-2019-real-time-results-in-the-federal-election/)), but it's misleading because each riding has an equal say in forming government. 

A better way would be to give each riding an equal area. Luckily many others have thought of this, and in R we can use the [geogrid](https://github.com/jbaileyh/geogrid) package to calculate a hexagonal (or rectangular) grid, to which we can then assign ridings. This takes about 20 minutes...it may sound slow, but it's way faster than trying to do this by hand!


```r
library(geogrid)
ridings_grid <- ridings %>%
  calculate_grid(grid_type = "hexagonal", seed = 1938)

ridings_hex <- assign_polygons(ridings, ridings_grid)
```





Now we can use similar code to make a "map" of ridings, this time with each riding having equal area:


```r
ggplot(ridings_hex) +
  geom_sf(aes(fill = PROVCODE)) +
  theme_void()
```

<img src="unnamed-chunk-6-1.png" width="672" />

The default grid/riding assignment definitely has some problems: PEI's ridings are mashed up with New Brunswick, Newfoundland, and Labrador. Setting the `seed` argument in `calculate_grid()` may help calculate alternate grids, although it's probably a better bet to calculate by province and arrange things manually. Either way, it's far superior to the geographical map!

A cool way to see where the seats are coming from is animation! Luckily, the [gganimate](https://gganimate.com/) package supports spatial objects out of the box. In order to combine the objects, we need to make sure they have the same CRS (I set it to `NA` here because we're no longer in geographic coordinates with the hex grid) and the same columns. Then, we can use `transition_states()` to animate!


```r
library(gganimate)
ridings_combined <- rbind(
  ridings %>% 
    mutate(type = "geographic") %>% 
    st_set_crs(NA) %>% 
    select(PROVCODE, type, geometry),
  ridings_hex %>%
    mutate(type = "hex") %>% 
    st_set_crs(NA) %>% 
    select(PROVCODE, type, geometry)
)

plot_obj <- ggplot(ridings_combined) +
  geom_sf(aes(fill = PROVCODE)) +
  theme_void() +
  transition_states(type, transition_length = 1, state_length = 5)

animate(plot_obj, width = 700, height = 700, res = 96)
```

![](ridings_anim.gif)
