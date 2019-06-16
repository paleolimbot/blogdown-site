---
title: 'Holes in ggplot polygons'
author: Dewey Dunnington
date: '2016-07-13'
slug: []
categories: []
tags: ["ggplot", "ggspatial", "R", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2016-07-13T20:35:46+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
aliases: [/archives/1126]
---


As part of my efforts to construct an [R package connecting ggplot and Spatial objects](http://github.com/paleolimbot/ggspatial), I came across an issue with ggplot involving holes in polygons. According to the collective knowledge of StackOverflow, it's possible to make this happen by putting the coordinates in the [correct clockwise/counterclockwise order](http://stackoverflow.com/questions/12033560/use-ggplot-to-plot-polygon-with-holes-in-a-city-map), [extending geom_polygon()](http://stackoverflow.com/questions/28036162/plotting-islands-in-ggplot2) somehow, or [other really complicated things](http://rstudio-pubs-static.s3.amazonaws.com/58401_1e87f6fe73e14bafbe1f3ce3df85c99e.html). But for my simple example, things didn't work, and [appears not to work for many examples](http://gis.stackexchange.com/questions/130482/plotting-islands-in-ggplot2) where spatial data is involved.

```r 
devtools::install_github("paleolimbot/ggspatial")
library(ggspatial)
data("longlake_waterdf")

spdf <- longlake_waterdf[is.na(longlake_waterdf$label),]
ggplot(spdf) + geom_polygon()
```

[caption id="attachment_1127" align="alignleft" width="598"]<img src="Rplot.png" alt="it&#039;s all wrong!" width="598" height="424" class="size-full wp-image-1127" /> it's all wrong![/caption]

Of course, `ggplot` has to turn the `SpatialPolygonsDataFrame` into a `data.frame` somehow, and it turns out that this happens using the `fortify()` function.

```r
df <- fortify(spdf)
head(df)
```

```
      long     lat order  hole piece id group
1 412583.6 5086360     1 FALSE     1  2   2.1
2 412585.6 5086360     2 FALSE     1  2   2.1
3 412588.5 5086356     3 FALSE     1  2   2.1
4 412588.4 5086350     4 FALSE     1  2   2.1
5 412585.2 5086343     5 FALSE     1  2   2.1
6 412583.1 5086335     6 FALSE     1  2   2.1
```

So more specifically, our call to `ggplot` is really more like this:

```r
ggplot(df, aes(x=long, y=lat)) + 
    geom_polygon(aes(group=id), fill="lightblue") + 
    geom_path(aes(group=group))
```

<img src="Rplot01.png" alt="Rplot01" width="598" height="424" class="alignleft size-full wp-image-1128" />

Here we can see that the 'fill' is working improperly, but if we use `group=group` as an aesthetic, the `geom_path` of the outline is correct.

It turns out that the secret is actually a bit of a workaround, suggested by [this answer]() on StackOverFlow. He didn't get credit for an answer, but got plenty of upvotes. Basically, if you come back to the same point after every hole, you fix the fill problem. So the solution is, insert a the first point before each piece of the polygon. Finding the first line of every hole is easy if it's just one feature (which our example is), so we'll start there.

```r
ringstarts <- which(!duplicated(df$group))
df[ringstarts, ]
```

```
        long     lat order  hole piece id group
1   412583.6 5086360     1 FALSE     1  2   2.1
320 412375.3 5086133   320  TRUE     2  2   2.2
431 412076.0 5085796   431  TRUE     3  2   2.3
502 412477.7 5086260   502  TRUE     4  2   2.4
581 412317.0 5085906   581  TRUE     5  2   2.5
676 412310.1 5086123   676  TRUE     6  2   2.6
714 412234.5 5085986   714  TRUE     7  2   2.7
```

Now if we manually insert the first row in front of each of the rings, we can see that our fill plots properly.

```r
df2 <- df[c(1:319, 
          1, 320:430, 1, 431:501, 1, 502:580, 
          1, 581:675, 1, 676:713, 1, 714:nrow(df)),]
ggplot(df, aes(x=long, y=lat)) + 
    geom_polygon(aes(group=id), fill="lightblue") + 
    geom_path(aes(group=group))
```

<img src="Rplot02.png" alt="Rplot02" width="598" height="424" class="alignleft size-full wp-image-1129" />

Programmatically coming up with this vector of row numbers took quite a bit of experimentation, but with a combination of `c()`, `lapply()`, and `do.call()` it looks like this does the trick:

```r
fixfeature <- function(df) {
  ringstarts <- which(!duplicated(df$group))
  if(length(ringstarts) < 2) {
    return(df)
  } else {
    ringstarts <- c(ringstarts, nrow(df))
    indicies <- c(1:(ringstarts[2]-1), do.call(c, lapply(2:(length(ringstarts)-1), function(x) {
        c(1, ringstarts[x]:(ringstarts[x+1]-1))
    })), nrow(df))
    return(df[indicies,])
  }
}
```

Because this only works with a single feature, we need to invoke `dplyr` to split our original `data.frame` up and apply the `fix_feature` function.

```r
library(dplyr)
custom_fortify <- function(x, ...) {
  df <- fortify(x, ...)
  df %>% group_by(id) %>% do(fixfeature(.))
}
```
This appears to work on any multi-part geometry, whether it involves a hole or not. The classic `wrld_simpl` dataset (from the `maptools` package) looks particularly bad when plotted without any type of conversion.

```r
library(maptools)
data(wrld_simpl)
wrld_df <- fortify(wrld_simpl)
ggplot(wrld_df, aes(x=long, y=lat)) + geom_polygon()
```

<img src="Rplot03.png" alt="Rplot03" width="598" height="424" class="alignleft size-full wp-image-1130" />

But if we use our `custom_fortify()` function, things look much prettier.

```r
wrld_df <- custom_fortify(wrld_simpl)
ggplot(wrld_df, aes(x=long, y=lat, group=id)) + geom_polygon()
```

<img src="Rplot04.png" alt="Rplot04" width="598" height="424" class="alignleft size-full wp-image-1131" />


Or if we want to add outlines, we have to use a slightly different aesthetic but it still works:

```r
ggplot(wrld_df, aes(x=long, y=lat, group=id)) + 
    geom_polygon() + geom_path(aes(group=group))
```

<img src="Rplot05.png" alt="Rplot05" width="598" height="424" class="alignleft size-full wp-image-1132" />

And of course, the whole point of this was to roll it into the [ggspatial](http://github.com/paleolimbot/ggspatial) package, so the easy way to go about this would be using `geom_spatial()` (but that would be cheating...).

```r
library(ggspatial) # devtools::install_github("paleolimbot/ggspatial") if you don't have it
data(longlake_waterdf)
ggplot() + geom_spatial(longlake_waterdf, aes(fill=label, col=area)) + 
    coord_fixed()
```
<img src="unnamed-chunk-3-2.png" alt="unnamed-chunk-3-2" width="672" height="480" class="alignleft size-full wp-image-1133" />


There you go! A generic solution (hopefully!) to all your holes-in-polygons needs.