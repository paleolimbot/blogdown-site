---
title: 'Programmer-friendly names come to rclimateca!'
author: Dewey Dunnington
date: '2017-02-27'
slug: []
categories: []
tags: ["R", "rclimateca", "Releases"]
subtitle: ''
summary: ''
authors: []
lastmod: '2017-02-27T19:57:02+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
aliases: [/archives/1229]
---

The most frustrating thing about working with the previous version of the <a href="https://cran.r-project.org/package=rclimateca">rclimteca package</a> is the column headers given by Environment Canada. In R it is possible to refer to these columns using the backticks or the double bracket, but to save on typing I introduced a predictable column renaming function that removes the hard-to-type and upper-case characters so that column names that were previously something like "Max Temp (°C)" or "Latitude (Decimal Degrees)" become "maxtemp" and "latitude". The implementation of the <a href="https://cran.r-project.org/package=testthat">testthat package</a> for automated testing highlighted a number of bugs that were discovered and fixed, in addition to integration with the new <a href="https://cran.r-project.org/package=mudata">mudata package</a> (more to come on that in a few weeks!). Give it a shot!


```r
# get nice names for climate data (wide or long)
df <- getClimateData(5585, timeframe="daily", year=2015, nicenames=TRUE)
# get nice names for climate sites
sites <- getClimateSites("gatineau QC", year=2014:2016, nicenames=TRUE)
```
