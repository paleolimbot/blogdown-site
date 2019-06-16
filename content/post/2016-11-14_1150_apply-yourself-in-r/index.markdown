---
title: 'apply() yourself in R'
author: Dewey Dunnington
date: '2016-11-14'
slug: []
categories: []
tags: ["R", "sapply", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2016-11-14T16:46:38+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
aliases: [/archives/1150]
---

A few months ago I wrote what I thought was a quite useful post on list comprehensions in R, which, after working with numerous datasets since, I have realized is almost useless. In <a href="http://apps.fishandwhistle.net/archives/1010">the post</a>, I suggested a few ways to go about generating vectors of data using non-vectorized functions. Packages such as <a href="https://cran.r-project.org/package=foreach">foreach</a>, <a href="https://cran.r-project.org/package=plyr">plyr</a>, and <a href="https://cran.r-project.org/package=dplyr">dplyr</a> offer advanced solutions to tackle advanced manipulation and grouping. Most of the time, however, all I really want is to generate a vector of data based on some existing data structure. For sample data, we'll use a sample list of latitudes and longitudes of a few locations in Nova Scotia, Canada, and try to generate a list of distances of adjacent cities.


``` r
locations <- prettymapr::geocode(c("digby, NS", "middleton, NS", 
                                   "wolfville, NS", "windsor, NS", 
                                   "halifax, NS"))
locations <- locations[c("query", "lon", "lat")]
```

| query         |        lon|       lat|
|:--------------|----------:|---------:|
| digby, NS     |  -65.75857|  44.61940|
| middleton, NS |  -65.06807|  44.94243|
| wolfville, NS |  -64.36449|  45.09123|
| windsor, NS   |  -64.13637|  44.99051|
| halifax, NS   |  -63.57497|  44.64842|

For those of you who don't know, the cities listed here are along what could be a bus route from Digby to Halifax, and one could plausibly be interested in the distances between each. Finding the distance between two lat/lon points is quite easy using the [geosphere](https://cran.r-project.org/package=geosphere) package:

``` r
library(geosphere)
distGeo(c(-65.75857, 44.61940), c(-65.06807, 44.94243)) # about 65 km
```

    ## [1] 65385.73

However, in this situation, we need to compute the distance between the previous point and the current point, for which there is no vectorized function. It is possible to do this using a standard `for` loop, however it is usually best to avoid `for` loops in R as they are [horrendous for performance](http://leftcensored.skepsi.net/2011/08/21/the-performance-cost-of-a-for-loop-and-some-alternatives/). To avoid this, we need `sapply()`.

At heart, `sapply()` takes a vector (or list) input, applys a function to each item, and produces as simple an output as it can. In most cases this is a vector, but if the output has a `length` &gt; 1, results vary.

``` r
sapply(c("first item", "second item", "third item"), nchar)
```

    ##  first item second item  third item 
    ##          10          11          10

In this example, we apply `nchar` to each item individually, returning the result as a vector (the names above each item means that the vector is a **named** vector, which we can suppress by passing `USE.NAMES=FALSE`). In the case of `nchar` this is unnecessary, because `nchar` is already vectorized (i.e. passing in a vector of values results in the a vector the same length as output), but to do something more complicated, we need to specify a custom function.

``` r
sapply(c("first item", "second item", "third item"), function(item) {
  if(item == "first item") {
    return(1)
  } else if(item == "second item") {
    return(2)
  } else if(item == "third item") {
    return(3)
  }
}, USE.NAMES = FALSE)
```

    ## [1] 1 2 3

A third common use of `sapply()` is to use the indicies as well as the values within the funcion.

``` r
values <- c("first item", "second item", "third item")
sapply(1:length(values), function(index) {
  paste(rep(values[index], index), collapse="/")
})
```

    ## [1] "first item"                       "second item/second item"         
    ## [3] "third item/third item/third item"

In most cases, what you're trying to accomplish can be done using a vectorized function (the above example could use a few nested `ifelse` calls), but there's a few cases where this will not work:

-   A calculation involves values before/after the current value, or depends on the index of the value in addition to the value itself
-   A calculation involves multiple columns in a data frame, and the target function is not vectorized
-   It is necessary to construct a data structure more complicated than a vector (usually a `list`) from a vector.

Back to our list of Nova Scotian towns along a fictional bus line, the calculation we want to do falls into the first two categories. The first step is to generate a list of distances between adjascent points.

``` r
locations$distance <- c(0, sapply(2:nrow(locations), function(rownumber) {
  distGeo(c(locations$lon[rownumber-1], locations$lat[rownumber-1]), 
          c(locations$lon[rownumber], locations$lat[rownumber]))
}))
```

| query         |        lon|       lat|  distance|
|:--------------|----------:|---------:|---------:|
| digby, NS     |  -65.75857|  44.61940|      0.00|
| middleton, NS |  -65.06807|  44.94243|  65385.65|
| wolfville, NS |  -64.36449|  45.09123|  57871.46|
| windsor, NS   |  -64.13637|  44.99051|  21173.59|
| halifax, NS   |  -63.57497|  44.64842|  58453.64|

Often there is a calculation that depends heavily on on the index of the value and the value itself, for which use `sapply(1:nrow(some.data.frame), function(rownumber) ...)`. I find that I use this construct a few times a week during an average week of programming. While there is still no list comprehension in R (a Python construct), `sapply()` is as close as it gets.

