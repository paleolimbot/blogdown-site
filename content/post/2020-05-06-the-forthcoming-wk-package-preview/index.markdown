---
title: The forthcoming {wk} package preview!
author: Dewey Dunnington
date: '2020-05-06'
slug: wk-package-preview
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2020-05-06T10:59:17-03:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---



This is a preview of the [wk package for R](https://paleolimbot.github.io/wk), which is currently undergoing the CRAN submission process. I'm just so excited about it that I can't wait to start talking about what it can do! For now, you'll have to install from GitHub to follow along:


```r
# remotes::install_github("paleolimbot/wk")
library(wk)
```

I'll be using the North Carolina dataset from the [sf](https://r-spatial.github.io/sf) package as example data:


```r
nc_sf <- sf::read_sf(system.file("shape/nc.shp", package="sf"))
nc_sfc <- sf::st_geometry(nc_sf)
nc_WKB <- sf::st_as_binary(nc_sfc)
```

## Motivation

The motivation for the wk package came from trying to write a [(currently unfinished) standalone GEOS API wrapper for R](https://paleolimbot.github.io/geom), which turned out to be completely un-useful without a way to get data into and out of the package. Of course, packages like [sf](https://r-spatial.github.io/sf) and [rgdal](https://cran.r-project.org/package=rgdal) can read files, but all of these require system GEOS and GDAL installations and only read files into a specific in-memory format (sf and sp, respectively). Under the hood, these packages use GEOS and GDAL to do most of the exciting things (intersects, buffers, etc.), and these packages all can read [well-known binary (WKB)](https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry#Well-known_binary). The wk package asks: why not just use WKB?

There are good reasons not to, which I imagine is why this hasn't become widespread. The WKB format under the hood looks like this:


```r
sf::st_as_binary(nc_sfc[1])
```

```
## [[1]]
##   [1] 01 06 00 00 00 01 00 00 00 01 03 00 00 00 01 00 00 00 1b 00 00 00 00
##  [24] 00 00 a0 41 5e 54 c0 00 00 00 60 ff 1d 42 40 00 00 00 20 9d 62 54 c0
##  [47] 00 00 00 80 e1 22 42 40 00 00 00 80 f7 63 54 c0 00 00 00 20 05 23 42
##  [70] 40 00 00 00 20 84 68 54 c0 00 00 00 a0 9b 2b 42 40 00 00 00 c0 6d 6f
##  [93] 54 c0 00 00 00 00 26 32 42 40 00 00 00 a0 b0 6c 54 c0 00 00 00 40 63
## [116] 3c 42 40 00 00 00 a0 fa 6c 54 c0 00 00 00 c0 79 42 42 40 00 00 00 40
## [139] e1 6a 54 c0 00 00 00 a0 79 4b 42 40 00 00 00 60 19 56 54 c0 00 00 00
## [162] a0 53 49 42 40 00 00 00 20 3e 56 54 c0 00 00 00 60 da 44 42 40 00 00
## [185] 00 20 c9 54 54 c0 00 00 00 40 c0 41 42 40 00 00 00 80 0d 54 54 c0 00
## [208] 00 00 80 87 3d 42 40 00 00 00 00 0a 51 54 c0 00 00 00 60 f6 37 42 40
## [231] 00 00 00 60 d2 50 54 c0 00 00 00 60 d8 33 42 40 00 00 00 80 67 4f 54
## [254] c0 00 00 00 c0 90 30 42 40 00 00 00 60 5a 4f 54 c0 00 00 00 40 c4 2e
## [277] 42 40 00 00 00 60 e9 50 54 c0 00 00 00 e0 1b 2d 42 40 00 00 00 40 0e
## [300] 55 54 c0 00 00 00 40 87 2e 42 40 00 00 00 c0 20 57 54 c0 00 00 00 60
## [323] 34 2d 42 40 00 00 00 80 67 57 54 c0 00 00 00 00 66 2b 42 40 00 00 00
## [346] 20 aa 56 54 c0 00 00 00 20 5d 26 42 40 00 00 00 60 84 57 54 c0 00 00
## [369] 00 60 ac 23 42 40 00 00 00 40 02 5a 54 c0 00 00 00 a0 7c 24 42 40 00
## [392] 00 00 a0 63 5a 54 c0 00 00 00 a0 36 22 42 40 00 00 00 20 96 5b 54 c0
## [415] 00 00 00 40 5f 21 42 40 00 00 00 20 fc 5c 54 c0 00 00 00 c0 aa 1e 42
## [438] 40 00 00 00 a0 41 5e 54 c0 00 00 00 60 ff 1d 42 40
## 
## attr(,"class")
## [1] "WKB"
```

...whereas the sfc format looks like this:


```r
nc_sfc[1]
```

```
## Geometry set for 1 feature 
## geometry type:  MULTIPOLYGON
## dimension:      XY
## bbox:           xmin: -81.74107 ymin: 36.23436 xmax: -81.23989 ymax: 36.58965
## epsg (SRID):    4267
## proj4string:    +proj=longlat +datum=NAD27 +no_defs
```

```
## MULTIPOLYGON (((-81.47276 36.23436, -81.54084 3...
```

Furthermore, if you wanted to do some manipulation of WKB geometry without resorting to the GEOS or GDAL C APIs, there's really no way to do it. Which would you rather work with!?

The wk package tries to provide tools to make working with WKB easier, because it's a well-supported format and doing pretty much anything useful in sf or sp requires a handful of conversions to and from WKB anyway. Some  examples of the tools in the wk package include extracting coordinates:


```r
head(wkb_coords(nc_WKB))
```

```
##   feature_id nest_id part_id ring_id coord_id         x        y  z  m
## 1          1       0       1       1        1 -81.47276 36.23436 NA NA
## 2          1       0       1       1        2 -81.54084 36.27251 NA NA
## 3          1       0       1       1        3 -81.56198 36.27359 NA NA
## 4          1       0       1       1        4 -81.63306 36.34069 NA NA
## 5          1       0       1       1        5 -81.74107 36.39178 NA NA
## 6          1       0       1       1        6 -81.69828 36.47178 NA NA
```

Computing a bounding box:


```r
wkb_ranges(nc_WKB)
```

```
##        xmin     ymin zmin mmin      xmax     ymax zmax mmax
## 1 -84.32385 33.88199  Inf  Inf -75.45698 36.58965 -Inf -Inf
```

And getting a printable summary of each feature:


```r
head(wkb_format(nc_WKB))
```

```
## [1] "MULTIPOLYGON (((-81.4728 36.2344, -81.5408 36.2725, -81.562 36.2736..." 
## [2] "MULTIPOLYGON (((-81.2399 36.3654, -81.2407 36.3794, -81.2628 36.405..." 
## [3] "MULTIPOLYGON (((-80.4563 36.2426, -80.4764 36.2547, -80.5369 36.2567..."
## [4] "MULTIPOLYGON (((-76.009 36.3196, -76.0173 36.3377, -76.0329 36.336..."  
## [5] "MULTIPOLYGON (((-77.2177 36.241, -77.2346 36.2146, -77.2986 36.2115..." 
## [6] "MULTIPOLYGON (((-76.7451 36.2339, -76.9807 36.2302, -76.9948 36.2356..."
```

Finally, the wk package provides a minimal class definition so that packages that return WKB can do so in a way that any package can recognize. This comes with a built-in `print()` method and some vector helpers so that you can put these in a data frame/tibble like you would other spatial types (like `sf::st_sfc()`).


```r
head(wkb(nc_WKB))
```

```
## <wk_wkb[6]>
## [1] <MULTIPOLYGON (((-81.4728 36.2344, -81.5408 36.2725, -81.562 36.2736...> 
## [2] <MULTIPOLYGON (((-81.2399 36.3654, -81.2407 36.3794, -81.2628 36.405...> 
## [3] <MULTIPOLYGON (((-80.4563 36.2426, -80.4764 36.2547, -80.5369 36.2567...>
## [4] <MULTIPOLYGON (((-76.009 36.3196, -76.0173 36.3377, -76.0329 36.336...>  
## [5] <MULTIPOLYGON (((-77.2177 36.241, -77.2346 36.2146, -77.2986 36.2115...> 
## [6] <MULTIPOLYGON (((-76.7451 36.2339, -76.9807 36.2302, -76.9948 36.2356...>
```

Having a WKB class that lives in a package with no system dependencies and one R package dependency ([Rcpp](https://cran.r-project.org/package=Rcpp) until I'm good enough at C++ to avoid it) makes it easier for other packages to return and recognize `wkb()` vectors. The dream is that this class could be used by any spatial package that reads and writes WKB anyway to do so in a way that a totally unrelated package could take advantage of. Coming full-circle, this means that my GEOS API wrapper could exist in complete isolation of sf and sp, yet users of both could take advantage of its processing functions.

## High performance processing functions

Another motivation of the wk package is to make it easier to re-use code that works with multiple formats. The ultimate example of this is GDAL, and to a certain extent GEOS, which contain in-memory structures to represent geometries and have various ways to load and export them. Rather than invent an in-memory format, the wk package uses an event-based approach, meaning that the reader sends signals when it sees certain information. This is really efficient for operations (e.g., calculating a bounding box) that only care about certain information (e.g., the coordinate values). You can see the signals that would get generated by a given geometry using the `wk*_debug()` functions (mostly used by me to work out bugs in the readers...):


```r
wkt_debug("POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))")
```

```
## nextFeatureStart(0)
##     nextGeometryStart(POLYGON [1], WKReader::PART_ID_NONE)
##         nextLinearRingStart(POLYGON [1], 5, 0)
##             nextCoordinate(POLYGON [1], WKCoord(x = 0, y = 0), 0)
##             nextCoordinate(POLYGON [1], WKCoord(x = 10, y = 0), 1)
##             nextCoordinate(POLYGON [1], WKCoord(x = 10, y = 10), 2)
##             nextCoordinate(POLYGON [1], WKCoord(x = 0, y = 10), 3)
##             nextCoordinate(POLYGON [1], WKCoord(x = 0, y = 0), 4)
##         nextLinearRingEnd(POLYGON [1], 5, 0)
##     nextGeometryEnd(POLYGON [1], WKReader::PART_ID_NONE)
## nextFeatureEnd(0)
```

For the bounding box example, the C++ code to calculate the bounding box would look like this:


```cpp
// [[Rcpp::depends(wk)]]
#include <Rcpp.h>
#include "wk/rcpp-io.h"
#include "wk/wkt-streamer.h"
using namespace Rcpp;

class BboxHandler: public WKGeometryHandler {
public:
  double xmin;
  double ymin;
  double xmax;
  double ymax;
  
  BboxHandler(): 
    xmin(R_PosInf), ymin(R_PosInf), 
    xmax(R_NegInf), ymax(R_NegInf) {}
  
  void nextCoordinate(const WKGeometryMeta& meta, const WKCoord& coord, uint32_t coordId) {
    xmin = std::min(xmin, coord.x);
    ymin = std::min(ymin, coord.y);
    xmax = std::max(xmax, coord.x);
    ymax = std::max(ymax, coord.y);
  }
};

// [[Rcpp::export]]
NumericVector wkt_bbox(CharacterVector wkt) {
  WKCharacterVectorProvider provider(wkt);
  WKTStreamer reader(provider);
  BboxHandler handler;
  
  reader.setHandler(&handler);
  while (reader.hasNextFeature()) {
    reader.iterateFeature();
  }
  
  return NumericVector::create(
    handler.xmin, handler.ymin,
    handler.xmax, handler.ymax
  );
}
```

Giving this a shot on our previous example, we get the following:


```r
wkt_bbox("POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))")
```

```
## [1]  0  0 10 10
```

I used well-known text here because it's easier to see what's going on, but you can wire the same handler up to a `WKBReader` and a `WKRawVectorListProvider` to process WKB using the same `BboxHandler`. This API is a little more verbose than I'd like, but I was trying to separate any code that was R-specific (e.g., `List`s of `RawVector`s) from the WKB logic.

An example where this could lead to huge speed improvements is coordinate transformations. `WKWriter`s are "just" geometry handlers, so operations that don't need to know context (e.g., a linear coordinate transformation) can transform each coordinate one at a time as they're being read and written. This means that, like the bounding box handler, only one coordinate ever exists in memory at a time.


```cpp
// [[Rcpp::depends(wk)]]
#include <Rcpp.h>
#include "wk/rcpp-io.h"
#include "wk/wkb-reader.h"
#include "wk/wkb-writer.h"
using namespace Rcpp;

class WKBTransformer: public WKBWriter {
public:
  double slopeX;
  double interceptX;
  double slopeY;
  double interceptY;
  
  WKBTransformer(WKBytesExporter& exporter, NumericVector transform): 
    WKBWriter(exporter),
    slopeX(transform[0]),
    interceptX(transform[1]),
    slopeY(transform[2]),
    interceptY(transform[3]) {}
  
  void nextCoordinate(const WKGeometryMeta& meta, const WKCoord& coord, uint32_t coordId) {
    WKCoord newCoord(coord);
    newCoord.x = coord.x * slopeX + interceptX;
    newCoord.y = coord.y * slopeY + interceptY;
    WKBWriter::nextCoordinate(meta, newCoord, coordId);
  }
};

// [[Rcpp::export]]
List wkb_transform(List wkb, NumericVector transform) {
  WKRawVectorListProvider provider(wkb);
  WKBReader reader(provider);
  
  WKRawVectorListExporter exporter(reader.nFeatures());
  WKBTransformer writer(exporter, transform);
  
  reader.setHandler(&writer);
  while (reader.hasNextFeature()) {
    reader.iterateFeature();
  }
  
  return exporter.output;
}
```

On the NC dataset, this would look like so:


```r
trans_identity <- c(1, 0, 1, 0)
head(wkb(wkb_transform(nc_WKB, trans_identity)))
```

```
## <wk_wkb[6]>
## [1] <MULTIPOLYGON (((-81.4728 36.2344, -81.5408 36.2725, -81.562 36.2736...> 
## [2] <MULTIPOLYGON (((-81.2399 36.3654, -81.2407 36.3794, -81.2628 36.405...> 
## [3] <MULTIPOLYGON (((-80.4563 36.2426, -80.4764 36.2547, -80.5369 36.2567...>
## [4] <MULTIPOLYGON (((-76.009 36.3196, -76.0173 36.3377, -76.0329 36.336...>  
## [5] <MULTIPOLYGON (((-77.2177 36.241, -77.2346 36.2146, -77.2986 36.2115...> 
## [6] <MULTIPOLYGON (((-76.7451 36.2339, -76.9807 36.2302, -76.9948 36.2356...>
```

This is *really* fast: it can do this about three times faster than an equivalent read + write operation from the sf package:


```r
bench::mark(
  sf:::CPL_read_wkb(sf:::CPL_write_wkb(nc_sfc)),
  wkb_transform(nc_WKB, trans_identity),
  check = FALSE
)
```

```
## # A tibble: 2 x 6
##   expression                                      min median `itr/sec`
##   <bch:expr>                                    <bch> <bch:>     <dbl>
## 1 sf:::CPL_read_wkb(sf:::CPL_write_wkb(nc_sfc)) 386µs  433µs     2251.
## 2 wkb_transform(nc_WKB, trans_identity)         118µs  140µs     6968.
## # … with 2 more variables: mem_alloc <bch:byt>, `gc/sec` <dbl>
```

## More features

This package may change as it gets battle tested (which currently it has not been!), but I think it's an approach that has legs. Feel free to [open an issue on the wk GitHub repo](https://github.com/paleolimbot/wk/issues/new) if you have ideas!
