---
title: Using GEOS in Rcpp
author: Dewey Dunnington
date: '2020-02-11'
slug: using-geos-in-rcpp
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2020-02-11T19:45:03-04:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---



Before we start, I have to warn you that this is probably the nerdiest thing you're going to do all week. In fact, the only thing that is nerdier than you reading this is me writing it. I got started on GEOS in Rcpp because I wanted to do some complex vector processing, and the overhead of converting to and from sf was inefficient (in my case, I'd be literally paying for the inefficiency because of cloud processing time).

I'll use something like that example here: starting with a well-known text representation of geometries, I'll perform an intersection between the two geometries, returning the output as well-known text. Basically, I want to do this:


```r
intersect_text(
  "POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))",
  "POLYGON ((5 5, 15 5, 15 15, 5 15, 5 5))"
)
```


```
## [1] "POLYGON ((5 5, 10 5, 10 10, 5 10, 5 5))"
```

Of course, we could do this in [sf](http://r-spatial.github.io/sf/) using `st_intersection()` and `st_as_sfc()`:


```r
library(sf)
polygon_one_text <- "POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))"
polygon_two_text <- "POLYGON ((5 5, 15 5, 15 15, 5 15, 5 5))"

st_as_text(
  st_intersection(
    st_as_sfc(polygon_one_text),
    st_as_sfc(polygon_two_text)
  )
)
```

```
## [1] "POLYGON ((5 10, 10 10, 10 5, 5 5, 5 10))"
```

Now the hard way! Let's start with Rcpp, since writing C++ code is already has some cognitive overhead. I started with [Hadley Wickham's Advanced R's Rcpp chapter](http://adv-r.had.co.nz/Rcpp.html), which gives an excellent overview of introductory C++ and how to write it in R. I'm writing this post in RMarkdown, which lets you include Rcpp chunks like so:


```cpp
#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
NumericVector timesTwo(NumericVector x) {
  return x * 2;
}
```

...and then call the function in R like this:


```r
timesTwo(5)
```

```
## [1] 10
```

It gets a little harder when external libraries are involved, in my case GEOS. Everything I know about GEOS (which isn't much) comes from the [geos.cpp source file in the sf package](https://github.com/r-spatial/sf/blob/master/src/geos.cpp) and the [GEOS C API header file](https://geos.osgeo.org/doxygen/geos__c_8h_source.html) (I can't seem to find the HTML version of the C API anywhere). I mostly use the C API because that's what sf does, and it exposes most of the things you might want to do with GEOS with [some degree of version independence](https://geos.osgeo.org/doxygen/c_iface.html).

One of those things is getting GEOS to tell us what version it is. The function is `GEOSversion()`, which you can see getting called in real life [here](https://github.com/r-spatial/sf/blob/master/src/geos.cpp#L864). The C++ code would look like this:

``` c++
#include <Rcpp.h>
#include <geos_c.h>
using namespace Rcpp;

// [[Rcpp::export]]
std::string geos_version() {
  return GEOSversion();
}
```

The basic strategy is to `#include <geos_c.h>`, which exposes `GEOS*()` functions for you to use in a given source file. If you tried running that, you'd notice that you get a compile error because it won't be able to find the library `<geos_c.h>`. This is because we need some compiler flags to let Rcpp know where we've installed GEOS. In packages (like sf) there's a configure script that automatically figures out whether or not you have the libraries necessary to use GEOS in compiled code, which basically calls the `geos-config` at the terminal to find the flags and libraries that are needed.


```bash
geos-config --cflags
geos-config --clibs
```

```
## -I/usr/local/Cellar/geos/3.7.2/include
## -L/usr/local/Cellar/geos/3.7.2/lib -lgeos_c
```

(If you don't have the command `geos-config`, you probably need to install it. On MacOS I used `brew install geos`, on Ubuntu I think you need `apt-get install libgeos-dev`)

Then we need to set environment variables to let Rcpp where to look when we invoke `#include <geos_c.h>`:


```r
Sys.setenv(
  PKG_CFLAGS = "-I/usr/local/Cellar/geos/3.7.2/include",
  PKG_LIBS = "-L/usr/local/Cellar/geos/3.7.2/lib -lgeos_c"
)
```

Then, we can compile the above code (in an RMarkdown `Rcpp` chunk or using `Rcpp::sourceCpp()`) and call the `geos_version()` function, which has been magically exported to R.




```r
geos_version()
```

```
## [1] "3.7.2-CAPI-1.11.2 b55d2125"
```

Doing anything useful with GEOS requires some more code. In general, every time you invoke GEOS, you need to (1) create a `context` (sometimes referred to as a handle), (2) create a reader to create a `GEOSGeometry` from your input(s), (3) create the output vector, (4) loop over the input doing some `GEOS*()` thing with the input and assigning it to the output, and (5) cleaning up the reader and the handle. It's a lot to take in, but the sf package has some examples of [creating a handle](https://github.com/r-spatial/sf/blob/master/src/geos.cpp#L91), [reading well-known binary (WKB)](https://github.com/r-spatial/sf/blob/master/src/geos.cpp#L153), [doing binary operations that return true or false](https://github.com/r-spatial/sf/blob/master/src/geos.cpp#L1027), and [doing binary operations that return a geometry](https://github.com/r-spatial/sf/blob/master/src/geos.cpp#L801).

In my example, this is what the C++ code would look like. In my case I need a reader *and* a writer because I want well-known text output as well. Note that I need a `precision` argument, because without it GEOS doesn't know how many decimal places to use (it defaults to something like 10, which leads to ugly and unnecessarily long output).


```cpp
#include <Rcpp.h>
#include <geos_c.h>
using namespace Rcpp;

// [[Rcpp::export]]
CharacterVector intersect_text(CharacterVector input1, CharacterVector input2, 
                               int precision) {
  // allocate the output
  CharacterVector output(input1.size());
  
  // create the handle, reader, and writer
  GEOSContextHandle_t context = GEOS_init_r();
  GEOSWKTReader *wkt_reader = GEOSWKTReader_create_r(context);
  GEOSWKTWriter *wkt_writer = GEOSWKTWriter_create_r(context);
  GEOSWKTWriter_setRoundingPrecision_r(context, wkt_writer, precision);
  
  // allocate the variables that will all
  // be used once in each step of the loop
  GEOSGeometry* geometry1;
  GEOSGeometry* geometry2;
  GEOSGeometry* geometry_output;
  std::string output_wkt;
  
  for (int i=0; i < input1.size(); i++) {
    geometry1 = GEOSWKTReader_read_r(context, wkt_reader, input1[i]);
    geometry2 = GEOSWKTReader_read_r(context, wkt_reader, input2[i]);
    geometry_output = GEOSIntersection_r(context, geometry1, geometry2);
    output_wkt = GEOSWKTWriter_write_r(context, wkt_writer, geometry_output);
    output[i] = output_wkt;
  }
  
  // cleanup the reader, writer, and handle
  GEOSWKTWriter_destroy_r(context, wkt_writer);
  GEOSWKTReader_destroy_r(context, wkt_reader);
  GEOS_finish_r(context);
  
  // return the output
  return output;
}
```

The big moment! Does it work!?


```r
intersect_text(
  "POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))",
  "POLYGON ((5 5, 15 5, 15 15, 5 15, 5 5))",
  0
)
```

```
## [1] "POLYGON ((5 10, 10 10, 10 5, 5 5, 5 10))"
```

Something that's important to check is whether or not it's actually faster than the easy thing (in this case, just using sf's functions for reading text and intersecting geometries):


```r
intersect_text_sf <- function(input1, input2) {
  st_as_text(
    st_intersection(
      st_as_sfc(input1),
      st_as_sfc(input2)
    )
  )
}

bench::mark(
  Rcpp = intersect_text(
    "POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))",
    "POLYGON ((5 5, 15 5, 15 15, 5 15, 5 5))",
    0
  ),
  sf = intersect_text_sf(
    "POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))",
    "POLYGON ((5 5, 15 5, 15 15, 5 15, 5 5))"
  )
)
```

```
## # A tibble: 2 x 6
##   expression      min   median `itr/sec` mem_alloc `gc/sec`
##   <bch:expr> <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
## 1 Rcpp        116.3µs 123.25µs     7916.    9.12KB     0   
## 2 sf            1.2ms   1.29ms      746.   14.95KB     6.17
```

It turns out that it's a *lot* faster to run, although it took me a long time to write and compile that C++ code, and I haven't even written any tests yet (which you should always consider!). Some things that are useful in the library include Delaunay triangulations, Voronoi polygons, binary predicates, and more! To be useful in C++ however, you probably need a specific input and output format, since conversion to and from sf's in-memory format can take a lot of time (if you're doing it millions of times).

It's worth mentioning that what I did is scripting-quality C++...if you're putting it in a package for other users to use, you have to be a lot more sure that you're properly cleaning up the memory you allocate. This is outside the scope of what I know about C++, but when I figure out how to do it properly there will probably be a blog post about it...right here (and it will be even more nerdy).
