---
title: 'Mapping package updates'
author: Dewey Dunnington
date: '2017-04-02'
slug: []
categories: []
tags: ["ggspatial", "gis", "prettymapr", "R", "Releases", "rosm", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2017-04-01T21:13:19+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
aliases: [/archives/1263]
---


I've been in a bit of a programming haze for the last few days after discovering that the code I wrote a year ago was not working very well in the [rosm](https://github.com/paleolimbot/rosm) and [prettymapr](https://github.com/paleolimbot/prettymapr) packages. In addition, a project I had worked on a few months ago needed some work, and for some reason I decided that the last few days were the days to get things done. The READMEs for [rosm](https://github.com/paleolimbot/rosm) and [prettymapr](https://github.com/paleolimbot/prettymapr), and [ggspatial](https://github.com/paleolimbot/ggspatial) give all the details, but most of it can be summed up in the following few-liner:

```r
library(prettymapr)
library(ggspatial)

places <- geocode(c("halifax, ns", "moncton, nb", "yarmouth, ns", "wolfville, ns"))
ggplot(places, aes(lon, lat, shape = query)) + 
  geom_osm() + geom_point() + 
  coord_quickmap()
```


<img src="Rplot001.png" alt="" width="480" height="480" class="alignnone size-full wp-image-1264" />

It turns out extending geometries and stats in ggplot is actually quite complex, but it seems this particular iteration of ggspatial does the trick. Now back to the real world...