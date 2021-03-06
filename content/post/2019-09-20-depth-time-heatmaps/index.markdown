---
title: Depth-Time visualization using R, the tidyverse, and ggplot2
author: Dewey Dunnington
date: '2019-09-20'
slug: depth-time-heatmaps
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2019-09-20T20:41:51-03:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---



It's come up a few times in my career working with lakes that I've been asked to visualize the results of a sonde-based sampling program. These programs (and the data collected by them) are common, and it's easy to see why: taking a boat to one of the deeper places in a lake and recording the temperature, oxygen saturation, and pH from a multi-parameter sonde is a relatively easy and engaging way to collect data. Automated multi-parameter sonde stations mounted on rafts are becoming more and more common as well, collecting vast amounts of high-resolution water quality data with a depth component.

An excellent example of such data is that of the [Lake Champlain Long-Term monitoring program](https://anrweb.vt.gov/DEC/_DEC/MultiProbeSonde.aspx) - a joint effort between the states of Vermont and New York. The data I'll use for this post was collected between 1992 and 2018 from Mallett's Bay (where I grew up learning to sail!). To make it easier to see what's going on, I'll only use data from 1993 for the first exercise. As usual, I'll use the [tidyverse](https://tidyverse.org/), and to help with date processing I'll use the [lubridate package](https://lubridate.tidyverse.org/).


```r
library(tidyverse)
library(lubridate)
sonde_tbl_1993
```

```
## # A tibble: 252 x 3
##    date       depth  temp
##    <date>     <dbl> <dbl>
##  1 1993-05-13     1  9.68
##  2 1993-05-13     2  9.63
##  3 1993-05-13     3  9.49
##  4 1993-05-13     4  9.22
##  5 1993-05-13     5  9.14
##  6 1993-05-13     6  8.91
##  7 1993-05-13     7  8.9 
##  8 1993-05-13     8  8.85
##  9 1993-05-13     9  8.78
## 10 1993-05-13    10  8.73
## # … with 242 more rows
```

The best way to start visualizing this type of data is to use points, using some other aesthetic (colour is probably best) to visualize the variability in temperature. I used `scale_colour_gradient2()` instead of the default colour scale because it allowed for a more intuitive reading of the graphic (red is hot, blue is cold), and using a middle value helps show the depth of the thermocline deepening as the year progresses.


```r
ggplot(sonde_tbl_1993, aes(x = date, y = depth, colour = temp)) +
  geom_point() +
  scale_y_reverse() +
  scale_colour_gradient2(
    midpoint = 15, 
    high = scales::muted("red"), 
    low = scales::muted("blue")
  )
```

<img src="fig-points-1993-1.png" width="672" />

This type of visualization is excellent for many reasons. First, it makes no assumptions...the points represent was was measured and no more. It's also a good way to visualize what was done: without reading any description of the sampling program, we can see that measurements were taken for all depths every two weeks from May to October. Usually a value was collected at 1 m depth intervals, but later in the year values were collected at 1 m intervals above the thermocline, below which values were only collected every 5 m.

However, visualizing these measurements as points is not ideal. It's difficult to see the deepening of the thermocline over time, and difficult to estimate what the temperature or thermal structure might be at a specific date (that might not have been measured directly). A common way of visualizing this is to "fill in" the missing pieces mathematically, creating a heatmap:

![](fig-linear-interp-1.png)

At its heart, this graphic is just a `ggplot()` with a `geom_raster()` layer. The complication is, `geom_raster()` requires equally spaced points in both the x- and y-direction. The rest of this post is about how to make that happen.

### Linear interpolation

If you had the foresight to design a sampling program with exactly equal numbers of days between samplings (and the good luck/determination to carry it out perfectly), you can skip the interpolation section and head straight for the plotting. However, even if you did collect perfect data (in-situ sensor data is likely to be nearly perfect), you might want it at higher resolution, or you might want to fill in values that are missing due to sensor errors. To make that happen, we need to interpolate.

I interpolate in the depth direction first, because I think this is the better assumption: as you go down in depth, a reasonable way to estimate the temperature at a depth which you did not measure is to draw a straight line between the temperatures at the depths that you did measure.

<img src="fig-interp-1.png" width="672" />

In the above figure I've done this for one sampling event (the one on August 8, 1993), but to make the figure we need to do this for every sampling date. A good way to go about this is to make a function that will estimate the temperature at a given depth for a given sampling date. The approach I've taken is to filter our original data to only contain values for that date, then use `approx(known_x, known_y, xout = new_x)$y` to do the interpolation. Here `target_date` has to be a single value, but `target_depth` can be a vector of depths, which we'll see is useful in a moment.


```r
estimate_temp_by_date <- function(target_date, target_depth) {
  data_for_date <- sonde_tbl_1993 %>% 
    filter(date == target_date) %>%
    arrange(depth)
  
  # approx() is one way to do a linear interpolation
  approx(data_for_date$depth, data_for_date$temp, xout = target_depth)$y
}

estimate_temp_by_date(ymd("1993-05-13"), c(0, 1, 1.5, 2))
```

```
## [1]    NA 9.680 9.655 9.630
```

Notice here that the function returns `NA` for values outside the range measured (there was never any measurement above 1 m depth), returns the value that was measured for depths that are in `sonde_tbl_1993`, and interpolates if the requested depth is between two other measured depths.

Scaling this up to the entire dataset can be done a few ways, but I like the grouped mutate method the best. First, we need to create a tibble containing all the dates and depths for which we want to compute a value. Because of how we've written our estimator function, the dates have to be dates that are in `sonde_tbl_1993`, but depths can be anything we want. Here I've chosen to create a sequence of depths from 1 to 20 with 100 equally-spaced values in between. This is helpful for creating a figure, because you can increase `length.out` if the figure looks pixelly. I've used `crossing()` to do this...for those familiar with base R, `expand.grid(..., stringsAsFactors = FALSE)` does something similar (I prefer `crossing()` because forgetting `stringsAsFactors = FALSE` can lead to some hard-to-track-down errors).

Second, we need to compute the temperature values. Most people familiar with [dplyr](https://dplyr.tidyverse.org/) know the pattern of `group_by()` (assign groups to unique combinations of one or more variables) and `summarise()` (compute summary values for each group), but the `group_by() %>% mutate()` pattern is useful when a column computation depends on a grouped summary value. In this case, we need to pass a different `target_date` (of length 1) to `estimate_temp_by_date()` for each sampling date.


```r
temp_interp_depth <- crossing(
  # the same dates as sonde_tbl_1993
  tibble(date = unique(sonde_tbl_1993$date)),
  # depths can now be any value
  tibble(depth = seq(1, 20, length.out = 100))
) %>%
  group_by(date) %>%
  mutate(temp = estimate_temp_by_date(date[1], depth))
```

Now we have a tibble that contains equally-spaced `depth` values, but unequally-spaced `date` values:

<img src="fig-points-depth-interp-1.png" width="672" />

To interpolate in the date dimension, we can use a similar process. First, we write a function that estimates the temperature at any date given a depth that is in `temp_interp_depth` (the tibble we just calculated). This assumption becomes more and more spurious as the time between sampling events increases, but I think it's still the best way to process this type of data.


```r
# create a function that will, given a depth, estimate the temp on any given day
estimate_temp_by_depth <- function(target_depth, target_date) {
  data_for_depth <- temp_interp_depth %>% 
    filter(depth == target_depth) %>%
    arrange(date)
  approx(data_for_depth$date, data_for_depth$temp, xout = target_date)$y
}

estimate_temp_by_depth(
  target_depth = 1, 
  target_date = seq(ymd("1993-05-12"), ymd("1993-05-15"), by = 1)
)
```

```
## [1]        NA  9.680000  9.905385 10.130769
```

Next, we create a tibble of the values we want using `crossing()`, then use a grouped mutate (grouping by `depth` this time) to estimate the temperature at all depth/date combinations.


```r
temp_raster <- crossing(
  # dates can now be any value
  tibble(date = seq(ymd("1993-05-13"), ymd("1993-10-06"), by = 1)),
  # depths must be the same as in temp_interp_depth
  tibble(depth = unique(temp_interp_depth$depth))
) %>%
  group_by(depth) %>%
  mutate(temp = estimate_temp_by_depth(depth[1], date))
```

Finally, we have equally-spaced values in both the date and depth dimensions. This can be visualized using `geom_raster()`, with `temp` mapped to the `fill` aesthetic. I've again used `scale_fill_gradient2()` to ensure that red values represent "hot", blue values represent "cool", and that there is some way to visualize the depth of the thermocline. Finally, I've used `coord_cartesian(expand = FALSE)` to eliminate the white border around the outside of the raster layer...I think it looks nicer that way.


```r
ggplot(temp_raster, aes(date, depth, fill = temp)) +
  geom_raster() +
  scale_y_reverse() +
  scale_fill_gradient2(
    midpoint = 15, 
    high = scales::muted("red"), 
    low = scales::muted("blue")
  ) +
  coord_cartesian(expand = FALSE)
```

<img src="fig-linear-interp-1.png" width="672" />

And bingo! We've got a heatmap (quite literally representing heat in this case). It's worth noting that there are still some parts of the figure that look "boxy", which is a result of interpolating in the date dimension (a lot of variability in temperature is probably occurring in the two weeks between sampling events that isn't well-characterized by the linear interpolation).

### Fitting a 2D smoother

There are many instances in which the linear interpolation method won't work. The most common reason I can think of is when you have more than one season of data that you want to summarise into a single figure. For example, the dataset in this post includes 304 sampling events from 1992 to 2018:


```r
sonde_tbl %>% 
  summarise(min(date), max(date), n_distinct(date))
```

```
## # A tibble: 1 x 3
##   `min(date)` `max(date)` `n_distinct(date)`
##   <date>      <date>                   <int>
## 1 1992-06-23  2018-10-08                 304
```

Plotting this one one figure requires some manipulation beforehand. In particular, we need a way to get dates from any year on to the same axis. I'll do this by calculating the `day_in_year`. `lubridate::floor_date()` is very handy for this. Next, I'll pretend that all the dates are in a single year (purely for plotting purposes).


```r
sonde_tbl_yearless <- sonde_tbl %>%
  mutate(
    day_in_year = as.numeric(date - floor_date(date, unit = "years"), unit = "days"),
    date_label = ymd("2019-01-01") + day_in_year
  )
```

<img src="fig-points-all-1.png" width="672" />

In this case, interpolating by date makes no sense: what happened on June 1 in 1993 has nothing to do with what happened on June 2 in 2018, yet on the figure these two values plot next to each other. Yet to make a proper heatmap we still need to estimate the temperature at equally-spaced values in the depth and date dimensions.

We can calculate these using a 2D smoother. I'm going to use the `loess()` smoother here, but a GAM fit using `mgcv::gam()` is probably more appropriate in many cases. Both have inherent assumptions, notably that the data is in some sense, "smooth". From the above plot I think it's a reasonable assumption: there is a similar relationship between years (some years being slightly different than others in the timing and magnitude of warming). An assumption that is unlikely to be true is that of independence: values at these points are *very* dependent on the values at other data points (e.g., the ones above, below, before, and after them). This shouldn't keep you from using a smoother to create an informative graphic, however you should never do any kind of statistical test on the smooth.

The first step (for any type of smoother) is to compute and evaluate the fit. For a GAM, you should use the `mgcv::gam.check()` function to make sure you GAM isn't terribly misguided...for all smoothers, you will have to graphically compare the points plot that you created with the smooth to see if the smooth is a good representation of an "average" year. You will have to fiddle with the options...for `loess()` this will mean adjusting the `span` parameter; for a GAM you'll have to adjust (at least) the value of `k`. From some trial and error, a `loess()` smooth with a `span` of 0.2 seems reasonable to me.


```r
smooth_fit <- loess(
  temp ~ day_in_year + depth, 
  data = sonde_tbl_yearless, 
  span = 0.2
)
```

Then we need to (1) create a tibble with equally-spaced date and depth values and (2) estimate the temperature at each date/depth combination. I use the same approach here as above for step 1 (`crossing()`); for step 2 I use the `predict()` function with the model fit as the first argument and a `tibble()` of "new data" as the second. This will work for most smooth fit objects as long as the columns in `newdata` are named identically to the ones you used to fit the model.


```r
temp_raster_smooth <- crossing(
  tibble(date = seq(ymd("2019-04-02"), ymd("2019-10-27"), by = 1)),
  tibble(depth = seq(1, 20, length.out = 100))
) %>%
  mutate(
    day_in_year = as.numeric(date - floor_date(date, unit = "years"), unit = "days"),
    temp = predict(
      smooth_fit, 
      newdata = tibble(day_in_year = day_in_year, depth = depth)
    )
  )
```

Now we have a tibble with equally-spaced date and depth values, so we can use similar ggplot2 code to plot it!

<img src="fig-loess-smooth-1.png" width="672" />

I think this is a good representation of the dataset as a whole: on an average year, Mallett's Bay begins warming at all depths in early May, developing a warm mixed layer in early June. This warm mixed layer becomes progressively thicker over the course of the year, until the surface temperature begins decreasing in September. By October, the entire water column has mixed and cooled considerably. 

As somebody who has been swimming in Mallett's Bay for over 25 years, I can unequivocally vouch for this story.
