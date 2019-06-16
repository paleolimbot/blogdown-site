---
title: 'An Alternative R Wrapper for PHREEQC Geochemical Modelling'
author: Dewey Dunnington
date: '2017-05-01'
slug: []
categories: []
tags: ["PHREEQC", "R", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2017-05-01T18:57:45+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
aliases: [/archives/1268]
---


Recently I was introduced to [PHREEQC](https://wwwbrr.cr.usgs.gov/projects/GWC_coupled/phreeqc/), which is a program that models chemical interactions between rocks and water (among many, many other things). It is an open-source project by the USGS, and has a number of powerful features, including modeling equilibrium concentrations of elements according to various input parameters (e.g. temperature, pH). My task for the day (a few weeks ago) was to see if changing partial pressure of CO<sub>2</sub> could theoretically have any effect on Alkalinity in surface water. PHREEQC was the solution.

Installing and running PHREEQC is not trivial. There are binary distributions for Mac and Windows, but the method of running the program is somewhat archane: the user is required to provide an input file that looks something like this (this is a modified version of [Example 2](https://wwwbrr.cr.usgs.gov/projects/GWC_coupled/phreeqc/phreeqc3-html/phreeqc3-57.htm#50524175_28577) in the [Version 3 User's Guide](https://wwwbrr.cr.usgs.gov/projects/GWC_coupled/phreeqc/phreeqc3-html/phreeqc3.htm):

    TITLE Example 2.--Temperature dependence of solubility
                      of gypsum and anhydrite
    SOLUTION 1 Pure water
            pH      7.0
            temp    25.0                
    EQUILIBRIUM_PHASES 1
            Gypsum          0.0     1.0
            Anhydrite       0.0     1.0
    REACTION_TEMPERATURE 1
            25.0 75.0 in 51 steps
    SELECTED_OUTPUT
            -file   ex2.sel
            -temperature
            -si     anhydrite  gypsum
    END

The above code will calculate the saturation indicies of Gypsum and Anhydrite as they change with temperature (between 25 and 75 degrees), and save the results to a delimited file called `ex2.sel`. It takes some sleuthing in the documentation (which is quite good and very complete) to figure that out. Somebody has also made a [package for R](https://cran.r-project.org/package=phreeqc) that will install, run, and parse the results of PHREEQC to an R object.

``` r
library(phreeqc)
phrLoadDatabaseString(phreeqc.dat)
phrRunString(ex2)
so <- phrGetSelectedOutput()
head(so$n1)
```

|  sim| state   |  soln|  dist\_x|  time|  step|        pH|        pe|  temp.C.|  si\_anhydrite|  si\_gypsum|
|----:|:--------|-----:|--------:|-----:|-----:|---------:|---------:|--------:|--------------:|-----------:|
|    1| i\_soln |     1|       NA|    NA|    NA|  7.000000|   4.00000|       25|             NA|          NA|
|    1| react   |     1|       NA|     0|     1|  7.066148|  10.74441|       25|     -0.3030109|           0|
|    1| react   |     1|       NA|     0|     2|  7.052481|  10.67606|       26|     -0.2922587|           0|
|    1| react   |     1|       NA|     0|     3|  7.038914|  10.60756|       27|     -0.2815457|           0|
|    1| react   |     1|       NA|     0|     4|  7.025453|  10.53874|       28|     -0.2708716|           0|
|    1| react   |     1|       NA|     0|     5|  7.012103|  10.47159|       29|     -0.2602361|           0|

Here, `ex2` is a character vector (one element per line) of the input file, which is included in the package as data. Similarly, `phreeqc.dat` is a database that contains speciation and geochemical reaction information. There are a number of these databases included, which, being new to PHREEQC, I don't fully grasp other than that they contain different species, elements, and reactions.

What I would like to type is quite a bit simpler than creating a character vector with a preformed input file. What if creating a solution could be as easy as `solution(pH=7)`? I spent an afternoon with this, and ended up with a wrapper package that is called (preliminarily) [easyphreeqc](https://github.com/paleolimbot/easyphreeqc).

``` r
library(easyphreeqc)

# generate input
input <- solution(pH = 7, temp = 25) +
  equilibrium_phases(Gypsum = c(0, 1), Anhydrite = c(0, 1)) +
  reaction_temperature(low = 25, high = 75, steps = 51) +
  selected_output(temperature = TRUE, si = c('anhydrite', 'gypsum'))

# run phreeqc() with a character vector as input
output <- phreeqc(input)

# output is the first selected output as a data frame
head(output)
```

|  sim| state   |  soln|  dist\_x|  time|  step|        pH|        pe|  temp.C.|  si\_anhydrite|  si\_gypsum|
|----:|:--------|-----:|--------:|-----:|-----:|---------:|---------:|--------:|--------------:|-----------:|
|    1| i\_soln |     1|       NA|    NA|    NA|  7.000000|   4.00000|       25|             NA|          NA|
|    1| react   |     1|       NA|     0|     1|  7.066148|  10.74441|       25|     -0.3030109|           0|
|    1| react   |     1|       NA|     0|     2|  7.052481|  10.67606|       26|     -0.2922587|           0|
|    1| react   |     1|       NA|     0|     3|  7.038914|  10.60756|       27|     -0.2815457|           0|
|    1| react   |     1|       NA|     0|     4|  7.025453|  10.53874|       28|     -0.2708716|           0|
|    1| react   |     1|       NA|     0|     5|  7.012103|  10.47159|       29|     -0.2602361|           0|

The idea is to turn each section of the input file into a function, so that specifying it is more "R-like". If you have used [ggplot2](https://cran.r-project.org/package=ggplot2), you'll notice the syntax is very similar. Of course, you can use regular old `c()` to combine the output of `solution()` and related functions (they just return, for now, the equivalent character vector that you would read from a file specifying the same solution).

With simplification comes the loss of flexibility, but many of the components of PHREEQC that require that flexibility are features that are more convenient to implement in R (e.g. vectorization of input values such as temperature, or plotting output). Realistically, functions like `solution()` should have formal R arguments, rather than just pasting the input together line-by-line. In any case, it's unlikely I'll get back to this side-project until after field season, but if you are interested in contributing, the [GitHub repo](https://github.com/paleolimbot/easyphreeqc) has the source code available. You can install the package using `devtools::install_github('paleolimbot/easyphreeqc')`.
