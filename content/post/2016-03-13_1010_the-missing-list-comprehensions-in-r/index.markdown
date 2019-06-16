---
title: 'The missing list comprehensions in R'
author: Dewey Dunnington
date: '2016-03-13'
slug: []
categories: []
tags: ["R", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2016-03-13T20:48:08+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
aliases: [/archives/1010]
---


The first problem I had with making the move to R from Python was the lack of the **list comprehension**, which in python lets you easily create new vectors (well, lists, because it's Python) by evaluating a function. In R this is mostly taken care of because all the base functions (and most package functions) are vectorized, meaning they automatically operate on every item you pass into it and return a vector of the same (usually) length. Usually some combination of the `ifelse` function and vectorized operations gives the desired result, but sometimes it's not enough. Consider the following dataset:

``` r
cormatrix
```

    ##           As        Pb        Zn          V       Cr
    ## S         NA        NA        NA         NA       NA
    ## Cl 0.5978618        NA 0.5814264         NA       NA
    ## Ti        NA 0.7568323        NA         NA 0.815492
    ## Mn        NA        NA        NA         NA       NA
    ## Fe        NA        NA 0.5629760 -0.5589387       NA
    ## Co        NA        NA        NA         NA       NA
    ## As 1.0000000        NA 0.5897606         NA       NA
    ## Mo        NA        NA        NA         NA       NA
    ## Ag        NA        NA        NA  0.7963853       NA
    ## Sn        NA        NA        NA         NA       NA

Here we have a number of correlation coeficients between various metals, with the non-significant ones as `NA`. There's a few rows here that have all `NA` values that are unnecessary, and it would be a more useful table if we could remove them. In R language, we want to remove the rows where `all(is.na(cormatrix[i,]))` returns `TRUE` for all values of `i` in `1:nrow(cormatrix)`. In Python, the syntax for this would be something like this:

``` python
[all(isnan(row)) for row in cormatrix]
```

I run into this problem in R often, where I want to produce a vector but the input needs to be specified using indicies for some reason (usually because I'm trying to figure out something about multiple columns at a time). The base package contains the `apply()` function, as well as slightly more flexible approaches in the `foreach` and `plyr` packages. The syntax for all of these is a little clunky and I can never seem to remember it.

``` r
# from the foreach package
foreach(i=1:nrow(cormatrix), .combine=c) %do% all(is.na(cormatrix[i,]))
```

    ##  [1]  TRUE FALSE FALSE  TRUE FALSE  TRUE FALSE  TRUE FALSE  TRUE

``` r
# from the plyr package
aaply(cormatrix, .margins=1, .expand = FALSE, .fun=function(row) all(is.na(row)))
```

    ##     1     2     3     4     5     6     7     8     9    10 
    ##  TRUE FALSE FALSE  TRUE FALSE  TRUE FALSE  TRUE FALSE  TRUE

``` r
# from the base package
apply(cormatrix, MARGIN=1, FUN=function(row) all(is.na(row)))
```

    ##     S    Cl    Ti    Mn    Fe    Co    As    Mo    Ag    Sn 
    ##  TRUE FALSE FALSE  TRUE FALSE  TRUE FALSE  TRUE FALSE  TRUE

I haven't played with the `Vectorize` function in R much, but there's a solution here as well.

``` r
f <- Vectorize(function(i) all(is.na(cormatrix[i,])))
f(1:nrow(cormatrix))
```

    ##  [1]  TRUE FALSE FALSE  TRUE FALSE  TRUE FALSE  TRUE FALSE  TRUE

The general case here is a function such that typing something like `lc(all(is.na(cormatrix[i,])), i=1:nrow(cormatrix))` will produce the output vector we're looking for. It turns out that writing this function for the general case is a little tricky since we have to not evaluate the first argument until we've assigned the `i` value properly. Luckily, some R magic and the `foreach` package make this quite flexible.

``` r
lc <- function(expr, ...) {
  expr <- deparse(substitute(expr))
  foreach(..., .combine=c) %do% eval(parse(text=expr))
}

lc(all(is.na(cormatrix[i,])), i=1:nrow(cormatrix))
```

    ##  [1]  TRUE FALSE FALSE  TRUE FALSE  TRUE FALSE  TRUE FALSE  TRUE

Performance wise, there's a good chance this is super slow. But the syntax is so neat that it's hard to resist using it in cases where one line of code would solve a complex subsetting operation like this one.

``` r
cormatrix[lc(!all(is.na(cormatrix[i,])), i=1:nrow(cormatrix)),]
```

    ##           As        Pb        Zn          V       Cr
    ## Cl 0.5978618        NA 0.5814264         NA       NA
    ## Ti        NA 0.7568323        NA         NA 0.815492
    ## Fe        NA        NA 0.5629760 -0.5589387       NA
    ## As 1.0000000        NA 0.5897606         NA       NA
    ## Ag        NA        NA        NA  0.7963853       NA

There are also solutions in the `plyr` and `base` package versions, but the `foreach` method is by far the most flexible since it doesn't depend on iterating over rows in a `data.frame` or `matrix`, and the `...` means we can pass in just about any iterable argument. For ease of copy-and-pasting, here's the general-use case (that doesn't require `library`ing `foreach`)

``` r
lc <- function(expr, ...) {
  `%do%` <- foreach::`%do%`
  expr <- deparse(substitute(expr))
  foreach::foreach(..., .combine=c) %do% eval(parse(text=expr))
}

lc(all(is.na(cormatrix[i,])), i=1:nrow(cormatrix))
```

    ##  [1]  TRUE FALSE FALSE  TRUE FALSE  TRUE FALSE  TRUE FALSE  TRUE

