---
title: 'Using the tidyverse to wrangle core data'
author: Dewey Dunnington
date: '2017-08-24'
slug: []
categories: []
tags: ["paleolimnology", "R", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2017-08-24T15:31:51+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
aliases: [/archives/1287]
---

The paleolimnological data I work with most days is voluminous and difficult to wrangle. There are a lot of cores, a lot of variables, and a lot of parameters thanks to the multi-element analysis of the X-Ray Fluorescence spectrometer we've used recently on our sediment samples. However, since the advent of the tidyverse, this job has gotten a lot easier! I've been preparing some material to help students at the <a href="http://centreforwaterresourcesstudies.dal.ca/">Centre for Water Resources Studies</a> at Dalhousie and the <a href="http://paleoenvironment.acadiau.ca/home.html">Paleoenvironmental Research Group</a> at Acadia handle what are quickly becoming big data projects.


## Prerequisites

This tutorial uses the tidyverse, which can be installed using:

```r
install.packages("tidyverse")
library(tidyverse)
```

The tutorial also uses some sample data, which is a small subset of data from two cores taken several years ago. You can load the sample data by running the below code:

```r
pocmaj_raw <- tribble(
  ~sample_id, ~Ca, ~Ti, ~V,  
  "poc15-2 0",  1036, 1337, 29,
  "poc15-2 0", 1951, 2427, 31,
  "poc15-2 0", 1879, 2350, 39,
  "poc15-2 1", 1488, 2016, 36,
  "poc15-2 2", 2416, 3270, 79,
  "poc15-2 3", 2253, 3197, 79,
  "poc15-2 4", 2372, 3536, 87,
  "poc15-2 5", 2621, 3850, 86,
  "poc15-2 5", 2785, 3939, 95,
  "poc15-2 5", 2500, 3881, 80,
  "maj15-1 0", 1623, 2104, 73,
  "maj15-1 0", 1624, 2174, 73,
  "maj15-1 0", 2407, 2831, 89,
  "maj15-1 1", 1418, 2409, 70,
  "maj15-1 2", 1550, 2376, 70,
  "maj15-1 3", 1448, 2485, 64,
  "maj15-1 4", 1247, 2414, 57,
  "maj15-1 5", 1463, 1869, 78,
  "maj15-1 5", 1269, 1834, 71,
  "maj15-1 5", 1505, 1989, 94
)
```

### Wrangling the sample ID column

Often the first challenge in dealing with data straight from a lab is converting the `sample_id` column into a `core` and `depth` column, which are the two columns needed to properly plot the data. For this, we will use the `separate()` function within the tidyverse (for more advanced manipulation, see the `extract()` function).

``` r
pocmaj_clean <- pocmaj_raw %>%
  separate(sample_id, into = c("core", "depth"), sep = " ")

head(pocmaj_clean)
#> # A tibble: 6 x 5
#>      core depth    Ca    Ti     V
#>     <chr> <chr> <int> <int> <int>
#> 1 poc15-2     0  1036  1337    29
#> 2 poc15-2     0  1951  2427    31
#> 3 poc15-2     0  1879  2350    39
#> 4 poc15-2     1  1488  2016    36
#> 5 poc15-2     2  2416  3270    79
#> 6 poc15-2     3  2253  3197    79
```

The `separate()` function takes a data.frame and three arguments: the column containing the values to separate, the names of the output columns, and the separator to use. This is technically a [regular expression](https://en.wikipedia.org/wiki/Regular_expression), which will only matter if you need to split on a string that contains special characters such as `+\[]()?*.{}`. Usually this isn't a problem, but if it is you can escape the string with a double backslash like this: `sep = "\\+"`. You can also keep your original `sample_id` column by passing `remove = FALSE`.

There is a good chance that some of your `sample_id` values will be misspelled for some reason or another. A simple way to fix these values is using `if_else()`, which can be used to replace specific values in a column.

``` r
pocmaj_raw %>%
  mutate(sample_id = if_else(sample_id == "poc15-2 1", 
                             "the correct value", sample_id)) %>%
  head()
#> # A tibble: 6 x 4
#>           sample_id    Ca    Ti     V
#>               <chr> <int> <int> <int>
#> 1         poc15-2 0  1036  1337    29
#> 2         poc15-2 0  1951  2427    31
#> 3         poc15-2 0  1879  2350    39
#> 4 the correct value  1488  2016    36
#> 5         poc15-2 2  2416  3270    79
#> 6         poc15-2 3  2253  3197    79
```

For more advanced manipulation, use the `stringr` package, which provides the function `str_replace()` (among others) that can perform search and replace queries along the column.

The next step is to convert depth values into numbers (they are currently text!). For this we will use `mutate()` and `as.numeric()`:

``` r
pocmaj_clean <- pocmaj_raw %>%
  separate(sample_id, into = c("core", "depth"), sep = " ") %>%
  mutate(depth = as.numeric(depth))

head(pocmaj_clean)
#> # A tibble: 6 x 5
#>      core depth    Ca    Ti     V
#>     <chr> <dbl> <int> <int> <int>
#> 1 poc15-2     0  1036  1337    29
#> 2 poc15-2     0  1951  2427    31
#> 3 poc15-2     0  1879  2350    39
#> 4 poc15-2     1  1488  2016    36
#> 5 poc15-2     2  2416  3270    79
#> 6 poc15-2     3  2253  3197    79
```

### Parameter-long data

Occasionally, data in parameter-wide form (like the above) is useful, but to summarise replicates for a whole bunch of parameters and plot all the parameters at once, we need the data in parameter-long form. This form is more difficult to understand, but easier to work with! To convert the data to parameter-long form, we can use the `gather()` function.

``` r
pocmaj_long <- pocmaj_clean %>%
  gather(Ca:V, key = "param", value = "value")

head(pocmaj_long)
#> # A tibble: 6 x 4
#>      core depth param value
#>     <chr> <dbl> <chr> <int>
#> 1 poc15-2     0    Ca  1036
#> 2 poc15-2     0    Ca  1951
#> 3 poc15-2     0    Ca  1879
#> 4 poc15-2     1    Ca  1488
#> 5 poc15-2     2    Ca  2416
#> 6 poc15-2     3    Ca  2253
```

The `gather()` function takes a data frame plus three arguments: the columns to gather, the `key` column (in which the column names are placed), and the `value` column (in which the values corresponding to each row/key combination are drawn). The columns not mentioned act as identifying variables that identify unique rows, which means that columns that contain measured values will cause problems! These can be removed using something like `select(-ends_with("_error"))`, or something similar. If you don't quite understand this step, bear with me, because it makes plotting and summarising a whole lot easier!

### Summarising replicates

The final step before plotting is to summarise replicate values. For this, we will use `group_by()` and `summarise()`.

``` r
pocmaj_long_summarised <- pocmaj_long %>%
  group_by(core, depth, param) %>%
  summarise(mean_value = mean(value), sd_value = sd(value), n = n())

head(pocmaj_long_summarised)
#> # A tibble: 6 x 6
#> # Groups:   core, depth [2]
#>      core depth param mean_value   sd_value     n
#>     <chr> <dbl> <chr>      <dbl>      <dbl> <int>
#> 1 maj15-1     0    Ca 1884.66667 452.354212     3
#> 2 maj15-1     0    Ti 2369.66667 401.056521     3
#> 3 maj15-1     0     V   78.33333   9.237604     3
#> 4 maj15-1     1    Ca 1418.00000         NA     1
#> 5 maj15-1     1    Ti 2409.00000         NA     1
#> 6 maj15-1     1     V   70.00000         NA     1
```

Using `group_by()` then `summarise()` is common: `group_by()` specifies the columns whose unique combinations we are interested in. The values in these columns will identify unique rows in the output, which in our case are represented by `core`, `depth`, and `param`. The `summarise()` function takes arguments in the form of `output_column_name = expression`, where `expression` is an R expression (like `mean(value)`)) where column names can be used like variables. Using `mean()` and `sd()` is a good start, but `min()` and `max()` are also useful, as well as passing `na.rm = TRUE` if `NA` values exist in the `value` column.

### Converting parameter-long data to parameter-wide format

Some plotting functions and almost all ordination functions require data in parameter-wide. For this, we can use the opposite of `gather()`: the `spread()` function.

``` r
pocmaj_wide_summarised <- pocmaj_long_summarised %>%
  select(core, depth, param, mean_value) %>%
  spread(key = param, value = mean_value)

head(pocmaj_wide_summarised)
#> # A tibble: 6 x 5
#> # Groups:   core, depth [6]
#>      core depth       Ca       Ti        V
#>     <chr> <dbl>    <dbl>    <dbl>    <dbl>
#> 1 maj15-1     0 1884.667 2369.667 78.33333
#> 2 maj15-1     1 1418.000 2409.000 70.00000
#> 3 maj15-1     2 1550.000 2376.000 70.00000
#> 4 maj15-1     3 1448.000 2485.000 64.00000
#> 5 maj15-1     4 1247.000 2414.000 57.00000
#> 6 maj15-1     5 1412.333 1897.333 81.00000
```

Plotting Paleo Data
-------------------

There are several plotting libraries for paleo data, particularly for species composition data. These include [analogue](https://github.com/gavinsimpson/analogue) (the `Stratiplot()` function) and [rioja](https://cran.r-project.org/web/packages/rioja/index.html) (the `strat.plot()` function). For non-species data, the `ggplot2` library works quite well, provided data are in parameter-long form.

``` r
ggplot(pocmaj_long_summarised, aes(y = depth, x = mean_value, colour = core)) +
  geom_errorbarh(aes(xmax = mean_value + sd_value, xmin = mean_value - sd_value),
                 height = 0.1) +
  geom_point() +
  geom_path() +
  facet_wrap(~param, scales = "free_x") +
  scale_y_reverse()
#> Warning: Removed 24 rows containing missing values (geom_errorbarh).
```

![](README-unnamed-chunk-12-1.png)

The `ggplot` library is quite intimidating at first, but it provides much flexibility and is worth the effort to [learn](http://r4ds.had.co.nz/data-visualisation.html). The above plot is constructed using a few lines, which I will describe one at a time.

``` r
ggplot(pocmaj_long_summarised, aes(y = depth, x = mean_value, col = core)) +
```

The `ggplot()` function creates a plot using its first argument as the primary `data` source. In our case, this is the `pocmaj_long_summarised`. Within `ggplot()`, we specify the default **aesthetics**, which is a mapping between the columns in `data` and the information that `ggplot` needs to construct a plot. Generally, paleo diagrams have the depth on the y-axis, and the parameter value on the x-axis. If more than one value exists in `core` (or this column may not exist of the data is only for one core), we can use `colour = core` to plot each core using a different color.

``` r
  geom_point() +
  geom_path() +
```

These `geom_*` functions don't need any arguments because they inherit the default aesthetics specified in `ggplot()`. We use `geom_path()` instead of `geom_line()` because `geom_line()` sorts its values by x value, which in our case doesn't make any sense!

``` r
geom_errorbarh(aes(xmax = mean_value + sd_value, xmin = mean_value - sd_value),
                 height = 0.1) +
```

Including error information is important when constructing paleolimnological diagrams (when uncertainty information is available), which is why we include the fairly long call to `geom_errorbarh()`. Unlike `geom_point()` and `geom_path()`, error bars require more information than `x`, `y`, and `colour`. Instead, we need to specify additional aesthetics (`xmin` and `xmax`), and how these should be calculated given `data` (in our case, `xmax = mean_value + sd_value, xmin = mean_value - sd_value`). Finally, the `height` of the error bars needs to be adjusted or they look quite huge.

``` r
facet_wrap(~param, scales = "free_x") +
```

The `facet_wrap()` specification is how `ggplot` creates many graphs using a single data input. The values in the specified column are used to create panels, with one panel per value. In our case, the `param` column is how we would like to separate our plots (this is usually the case). By default, `facet_wrap()` will keep all axes aligned, but because each parameter has a different range of values, we need that axis to automatically adjust based on its content. This is why we specify `scales = "free_x"`.

``` r
  scale_y_reverse()
```

Finally, we need to reverse the y-axis for the traditional strat diagram look with zero depth at the top of the diagram. If ages are used, this can be omitted.

### Tips and tricks

There are as many variations on strat diagrams as there are cores in the world, and `ggplot` can't produce all of them. A few things are still possible with slight modification!

#### Dual Y axis (ages and depths)

Having a dual y axis is possible, but requires a function transforming depth to age. In this example I'll use a simple function assuming a constant sedimentation rate, but in reality this function will probably use the `approx()` function given known age/depth values from <sup>210</sup>Pb or other dating method.

``` r
depth_to_age <- function(depth, sed_rate = 0.1, core_year = 2017) {
  # sed_rate here is in cm/year
  core_year - 1 / sed_rate * depth
}
depth_to_age(0:10)
#>  [1] 2017 2007 1997 1987 1977 1967 1957 1947 1937 1927 1917
```

Given this function, it can be passed to the `trans` argument of `sec_axis` to create a secondary Y axis.

``` r
ggplot(pocmaj_long_summarised, aes(y = depth, x = mean_value, col = core)) +
  geom_path() +
  facet_wrap(~param, scales = "free_x") +
  scale_y_reverse(sec.axis = sec_axis(trans = ~depth_to_age(.), name = "age"))
```

![](README-unnamed-chunk-19-1.png)

The details of creating a secondary axis can be found in `?sec_axis`. Obviously this doesn't make sense for multiple cores, but works well for multiple parameters on a single core.

#### Zonation Lines

Zone lines can be added using `geom_hline()`, which creates a horizontal line superimposed over the plot.

``` r
ggplot(pocmaj_long_summarised, aes(y = depth, x = mean_value, col = core)) +
  geom_path() +
  geom_hline(yintercept = c(1.8, 4.2), linetype = 2, alpha = 0.5) +
  facet_wrap(~param, scales = "free_x") +
  scale_y_reverse()
```

![](README-unnamed-chunk-20-1.png)

#### "Everything vs. everything"

Making a series of biplots is often useful, especially when dealing with XRF data. This is easy with data in its original, wide, format, but ggplot needs data in parameter-long form to make use of facets. This paired, long-form data can be created using a self `full_join()` using the non-parameter ID columns:

``` r
long_pairs <- full_join(pocmaj_long_summarised,
                        pocmaj_long_summarised,
                        by = c("core", "depth"))

head(long_pairs)
#> # A tibble: 6 x 10
#> # Groups:   core, depth [1]
#>      core depth param.x mean_value.x sd_value.x   n.x param.y mean_value.y
#>     <chr> <dbl>   <chr>        <dbl>      <dbl> <int>   <chr>        <dbl>
#> 1 maj15-1     0      Ca     1884.667   452.3542     3      Ca   1884.66667
#> 2 maj15-1     0      Ca     1884.667   452.3542     3      Ti   2369.66667
#> 3 maj15-1     0      Ca     1884.667   452.3542     3       V     78.33333
#> 4 maj15-1     0      Ti     2369.667   401.0565     3      Ca   1884.66667
#> 5 maj15-1     0      Ti     2369.667   401.0565     3      Ti   2369.66667
#> 6 maj15-1     0      Ti     2369.667   401.0565     3       V     78.33333
#> # ... with 2 more variables: sd_value.y <dbl>, n.y <int>
```

Creating a plot using this is quite straightforward (note that in this form, error bars can also be included using `geom_errorbar()` and `geom_errorbarh()`):

``` r
ggplot(long_pairs, aes(x = mean_value.x, y = mean_value.y, col = core)) +
  geom_point() +
  facet_grid(param.y ~ param.x, scales = "free")
```

![](README-unnamed-chunk-22-1.png)

This data format has the added advantage of being able to test all the correlations for significance:

``` r
long_pairs %>%
  group_by(param.x, param.y) %>%
  summarise(test = list(cor.test(mean_value.x, mean_value.y))) %>%
  mutate(test = map(test, broom::glance)) %>%
  unnest()
#> # A tibble: 9 x 10
#> # Groups:   param.x [3]
#>   param.x param.y  estimate    statistic      p.value parameter   conf.low
#>     <chr>   <chr>     <dbl>        <dbl>        <dbl>     <int>      <dbl>
#> 1      Ca      Ca 1.0000000          Inf 0.000000e+00        10 1.00000000
#> 2      Ca      Ti 0.9025993 6.630408e+00 5.850911e-05        10 0.68194992
#> 3      Ca       V 0.5913529 2.318939e+00 4.285015e-02        10 0.02641645
#> 4      Ti      Ca 0.9025993 6.630408e+00 5.850911e-05        10 0.68194992
#> 5      Ti      Ti 1.0000000 2.122169e+08 1.328317e-79        10 1.00000000
#> 6      Ti       V 0.6502911 2.706912e+00 2.205017e-02        10 0.12187280
#> 7       V      Ca 0.5913529 2.318939e+00 4.285015e-02        10 0.02641645
#> 8       V      Ti 0.6502911 2.706912e+00 2.205017e-02        10 0.12187280
#> 9       V       V 1.0000000          Inf 0.000000e+00        10 1.00000000
#> # ... with 3 more variables: conf.high <dbl>, method <fctr>,
#> #   alternative <fctr>
```

Summary
-------

The tidyverse offers a great number of possibilities with respect to core data, only a few of which I describe here. In general, the functions in the tidyverse allow for parameter-long data to be manipulated more easily, which allows for a greater amount of metadata and uncertainty information to be kept alongside the data until it is not needed. For more, see the extensive [tidyverse documentation](http://www.tidyverse.org/articles/) and companion book, [R for Data Science](http://r4ds.had.co.nz/).

