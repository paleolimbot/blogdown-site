---
title: Stream networks using R and sf
author: Dewey Dunnington
date: '2020-04-14'
slug: stream-networks-using-r-and-sf
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2020-04-14T22:04:01-03:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---



I have a paper in the works that involves data for a few hundred lakes in Nova Scotia, for which I need catchment parameters. That's a tall order! Automated catchment extraction is possible, but it helps to have a ballpark area to work with. Actually, it's mission critical to have a ballpark area to work with...650 is just too many lakes to catch all the errors by hand. One of the ways to generate these catchments is using the stream network. I'll do so using the [tidyverse](https://tidyverse.org/) family of packages and [sf](https://r-spatial.github.io/sf):


```r
library(tidyverse)
library(sf)
```

The data I'm using is from Nova Scotia Environment/Nova Scotia Department of Natural Resources' excellent collection of geographic information (the [geospatial data directory](https://nsgi.novascotia.ca/gdd/)). Included is a small subset of the water features (`lakes`) and hydrographic network (`rivers`) near [Lake Major](https://www.openstreetmap.org/#map=13/44.7838/-63.5046).


```r
lakes <- read_sf("lakes.shp")
rivers <- read_sf("rivers.shp") %>% 
  st_cast("LINESTRING") %>% 
  transmute(river_id = 1:n())

lakes
```

```
## Simple feature collection with 6 features and 1 field
## geometry type:  POLYGON
## dimension:      XY
## bbox:           xmin: 456770.4 ymin: 4951163 xmax: 465842.1 ymax: 4964343
## epsg (SRID):    26920
## proj4string:    +proj=utm +zone=20 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs
## # A tibble: 6 x 2
##   feat_id                                                          geometry
##   <chr>                                                       <POLYGON [m]>
## 1 card_set     ((463125.7 4961860, 463140.7 4961858, 463149.7 4961856, 463…
## 2 care_catch   ((459477.3 4964343, 459489.2 4964343, 459495.2 4964340, 459…
## 3 carry_news   ((457335.6 4956697, 457340.5 4956695, 457343.5 4956691, 457…
## 4 carry_result ((460692.9 4957888, 460693.9 4957886, 460696.8 4957880, 460…
## 5 case_contra… ((464473.3 4956212, 464476.1 4956205, 464480.9 4956193, 464…
## 6 case_on      ((458446.9 4958244, 458453.8 4958237, 458456.7 4958233, 458…
```

```r
rivers
```

```
## Simple feature collection with 811 features and 1 field
## geometry type:  LINESTRING
## dimension:      XY
## bbox:           xmin: 455676.1 ymin: 4954527 xmax: 469315.8 ymax: 4966713
## epsg (SRID):    26920
## proj4string:    +proj=utm +zone=20 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs
## # A tibble: 811 x 2
##    river_id                                                        geometry
##  *    <int>                                                <LINESTRING [m]>
##  1        1 (461837.9 4955133, 461835.1 4955126, 461833.9 4955121, 461833.…
##  2        2 (461171.9 4954904, 461167.3 4954905, 461138.1 4954939, 461110.…
##  3        3 (460825 4955149, 460866.6 4955016, 460867.6 4955013, 460868.8 …
##  4        4 (460911.9 4955137, 460909.5 4955137, 460907.7 4955138, 460904 …
##  5        5 (460512.5 4955185, 460493.8 4954909, 460495.1 4954865, 460495.…
##  6        6 (462494.3 4955272, 462489.3 4955271, 462476.3 4955268, 462431 …
##  7        7                            (459961.3 4955396, 459984.1 4955397)
##  8        8 (461711.8 4955615, 461714.6 4955605, 461722.1 4955579, 461728.…
##  9        9 (458104.5 4955291, 458102.6 4955296, 458100.7 4955302, 458100.…
## 10       10 (457870.3 4955693, 457884.6 4955704, 457888.4 4955707, 457888.…
## # … with 801 more rows
```

An important bit here is that I've made sure that `rivers` is a LINESTRING...(previously it was a MULTILINESTRING). This is important later when we extract the nodes. I've given each river an ID as well, which also comes in handy later. Plotted, these look like this:

<img src="unnamed-chunk-3-1.png" width="672" />

I've highlighted East Lake, which is the lake I'll use as an example to generate an approximate catchment. The basic approach is: follow the rivers that come into the lake upstream until there are no more rivers!

We'll start with "the rivers that come into the lake". Actually, even simpler: "the rivers that touch the edge of the lake". We can find these with the binary predicate `st_touches()`.


```r
lake <- lakes %>% filter(feat_id == "carry_result")
lake_border_segments <- rivers %>% 
  filter(st_touches(geometry, st_boundary(lake), sparse = FALSE))

plot(lake$geometry)
plot(lake_border_segments$geometry, col = "red", add = T)
```

<img src="unnamed-chunk-4-1.png" width="672" />

An important feature of a hydrographic network is that the features must be ordered in the right direction. That is, the network is only useful if the segments are all defined in the direction of flow. This means that the "first" node in the linestring is always upstream of the "last" node in a segment. We can extract nodes by using `st_cast(x, "POINT")`, but it's a little tricky to generalize this to a per-feature basis. For exactly one feature, a function like this works:


```r
extract_node_single <- function(x, n) {
  # extract the nodes
  nodes <- suppressWarnings(st_cast(x, "POINT"))
  
  # lets you specify n = -1 for the last node
  if (n < 0) {
    n <- nrow(nodes) + 1 + n
  }
  
  # ensures that the output is always length(n)
  if (n > nrow(nodes)) {
    sfc <-  st_sfc(st_point(), crs = st_crs(x))
    st_as_sf(tibble(geometry = rep(sfc, length(n))))
  } else {
    nodes[n, ]
  }
}

lake_border_segments_start <- map(
  seq_len(nrow(lake_border_segments)), 
  ~extract_node_single(lake_border_segments[.x, ], 1)
) %>% 
  do.call(rbind, .)

plot(c(lake$geometry, lake_border_segments$geometry))
plot(lake_border_segments$geometry, col = "red", add = T)
plot(lake_border_segments_start$geometry, col = "red", add = T)
```

<img src="unnamed-chunk-5-1.png" width="672" />

I took a few liberties with this function. Notably, I made sure that it always has an output of predictable length. This is important, because when we use it we need to be able to trust that the features will line up. Second, I let negative indices denote "from the end". This is a bit like `stringr::str_sub()` and Python indexing, and it's useful as we also need to know the last node of each feature.

As written, it only works for a one-row sf object. We can generalize it using `purrr::map2()` so that we can pass any size of sf object in. Because `purrr::map2()` recycles `x` and `n` to a common length, `extract_node()` is properly vectorized on both.


```r
extract_node <- function(x, n) {
  nodes_single <- map2(
    seq_len(nrow(x)), n, 
    ~extract_node_single(x[.x, ], n = .y)
  )
  do.call(rbind, nodes_single)
}
```

With this, we can extract the end nodes more readily:


```r
lake_border_segments_end <- extract_node(lake_border_segments, -1)

plot(c(lake$geometry, lake_border_segments$geometry))
plot(lake_border_segments$geometry, col = "red", add = T)
plot(lake_border_segments_end$geometry, col = "red", add = T)
```

<img src="unnamed-chunk-7-1.png" width="672" />

From here, we can at the very least find the outlet of the lake. I happen to know it's at the south, but from a "segments in hydrographic network" standpoint, it's a segment outside the lake boundary that is touching the lake boundary whose first point intersects the lake boundary (note that this works because the water layer and the hydrographic network were generated together, so segments are already broken along the lake boundary). I use `st_difference()` to remove the segments inside the lake.


```r
outlet <- lake_border_segments %>% 
  st_difference(lake) %>% 
  extract_node(1) %>% 
  st_intersection(st_boundary(lake))

plot(lake$geometry)
plot(outlet$geometry, col = "red", add = T)
```

<img src="unnamed-chunk-8-1.png" width="672" />

We're getting there! The outlet is important because all the *other* segments must therefore be inlets, which is what we want to follow. The act of "following" requires a heavy amount of lookup: for each segment, we'll need to find all the other segments in the network that also touch that segment. The lookup doesn't take long with this tiny dataset, but for the whole province this is incredibly time-consuming. To make this as efficient as possible, we can cache which segments touch which other segments using a unary `st_touches(obj)`. It generates a list of indices, so that for any index `i` we can use `obj[result[[i]], ]` to find all the neighbouring segments  of `obj[i, ]`.


```r
neighbouring_segment_lookup <- st_touches(rivers, sparse = TRUE)
neighbouring_segment_lookup[[1]]
```

```
## [1] 6 8
```

Finally, we have all the pieces to make an upstream segments function. I'm using a recursive approach...I'm sure there's a more efficient way, but this seems to perform reasonably well for the whole province (650 lakes in about an hour), so I didn't bother to optimise.


```r
upstream_segments <- function(x, recursion_limit = 100) {
  if (recursion_limit == 0) {
    message("Recursion limit reached!")
    return(x)
  }
  
  touching_segs <- rivers[neighbouring_segment_lookup[[x$river_id]], ]
  is_upstream <- st_intersects(
    extract_node(x, 1), 
    extract_node(touching_segs, -1), 
    sparse = FALSE
  )
  upstream_segs <- touching_segs[is_upstream, ]
  
  if (nrow(upstream_segs) == 0) {
    x
  } else {
    upstream_of_upstream <- map(
      seq_len(nrow(upstream_segs)), 
      ~upstream_segments(upstream_segs[.x, ], recursion_limit - 1)
    )

    do.call(rbind, c(list(x), upstream_of_upstream))
  }
}
```

The general approach is (1) locate all the touching segments, (2) only use touching segments whose last node intersects the first node of the input, and (3) for all of *those*, locate the upstream segments and bind the result together. I keep track of the `recursion_limit` in case I did something wrong (likely when constructing the function), and because it helped me make an animation of the process below.

Let's see it in action! Picking one of the segments, does it work!?


```r
lake_upstream <- upstream_segments(lake_border_segments[6, ])
plot(lake_upstream$geometry)
plot(lake$geometry, add = T)
plot(lake_border_segments[6, ], col = "red", add = T)
```

<img src="unnamed-chunk-11-1.png" width="672" />

Cool! To generate the whole network, we need to do this for both inlets, which we can find by `st_difference()`ing out the lake and removing the outlet.


```r
lake_inlets <- lake_border_segments %>% 
  st_difference(lake) %>% 
  select(-feat_id) %>% 
  filter(st_disjoint(geometry, outlet, sparse = FALSE)) 

lake_upstream_all <- map(
  seq_len(nrow(lake_inlets)), 
  ~upstream_segments(lake_inlets[.x, ])
) %>% 
  do.call(rbind, .)

plot(lake_upstream_all$geometry)
plot(lake$geometry, add = T)
```

<img src="unnamed-chunk-12-1.png" width="672" />

It takes about a second, but it works! This is a few kilometers wide and finished in 100 levels of recursion...for reference, the largest network in the province took about 10 seconds and took about 2,000 levels of recursion.

We can use the recursion limit to visualize the process. Using `animation.hook='gifski'` in my knitr chunk options, this is reasonably straightforward:


```r
for (i in 0:50) {
  plot(lake_upstream_all$geometry, main = paste("recursion limit:", i))
  plot(lake$geometry, add = T)
  
  map(
    seq_len(nrow(lake_inlets)), 
    ~upstream_segments(lake_inlets[.x, ], recursion_limit = i)
  ) %>% 
    do.call(rbind, .) %>% 
    pull(geometry) %>% 
    plot(col = "red", add = T)
}
```

<img src="unnamed-chunk-13-.gif" width="672" />

There is definitely room for optimization, but it's a whole lot easier than doing it by hand!
