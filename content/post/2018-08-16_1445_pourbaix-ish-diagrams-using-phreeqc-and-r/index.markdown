---
title: 'Pourbaix-ish diagrams using PHREEQC and R'
author: Dewey Dunnington
date: '2018-08-16'
slug: []
categories: []
tags: ["geochemistry", "PHREEQC", "pourbaix", "R", "tidyphreeqc", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2018-08-16T16:03:00+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

A side project of mine recently has been to play with <a href="https://wwwbrr.cr.usgs.gov/projects/GWC_coupled/phreeqc/phreeqc3-html/phreeqc3.htm">PHREEQC</a>, which is a powerful geochemical modelling platform put out by the USGS. In order to make the <a href="https://cran.r-project.org/package=phreeqc">R package for phreeqc</a> more accessible, I've started to wrap a few common uses of PHREEQC in a new R package, <a href="https://github.com/paleolimbot/tidyphreeqc">tidyphreeqc</a>. In particular, I'm interested in using PHREEQC to take a look at the classic <a href="https://en.wikipedia.org/wiki/Pourbaix_diagram">Pourbaix diagram</a>, which is almost always represented in pure solution at a particular concentration of the target element, at 25°C.



![Pourbaix diagram for Mn from Wikimedia Commons](https://upload.wikimedia.org/wikipedia/commons/6/66/Pourbaix_diagram_for_Manganese.svg)

([Pourbaix diagram for Mn from Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Pourbaix_diagram_for_Manganese.svg))

There's obviously more to it than that. The lines on the diagram change with temperature, concentration, and other properties of the solution in question. Also, some phases on the diagram are solid phases, and others are aqueous. Diagrams are represented like this probably because they are relatively time-consuming to create. But what if we could generate a few thousand hypothetical solutions and see what happens? This is a problem that is well-suited for PHREEQC.

The packages I'm using in this post are the [tidyverse](https://tidyverse.org) and [tidyphreeqc](https://github.com/paleolimbot/tidyphreeqc), the later of which you'll have to install using `devtools::install_github()`.

``` r
library(tidyverse)
# devtools::install_github("paleolimbot/tidyphreeqc")
library(tidyphreeqc)
# the minteq database is slightly more comprehensive than the default
phr_use_db_minteq()
```

The basic usage of **tidyphreeqc** is to call `phr_run()` with some input arguments. For our purposes, we're going to create a solution, then look at the output (the default units for components of the solution are mmol/kg water).

``` r
phr_run(
  phr_solution(Mn = 0.1)
) %>%
  phr_print_output()
```

    ## ------------------------------------
    ## Reading input data for simulation 1.
    ## ------------------------------------
    ## 
    ##  SOLUTION 1
    ##      Mn    0.1
    ## -------------------------------------------
    ## Beginning of initial solution calculations.
    ## -------------------------------------------
    ## 
    ## Initial solution 1.  
    ## 
    ## -----------------------------Solution composition------------------------------
    ## 
    ##  Elements           Molality       Moles
    ## 
    ##  Mn                1.000e-04   1.000e-04
    ## 
    ## ----------------------------Description of solution----------------------------
    ## 
    ##                                        pH  =   7.000    
    ##                                        pe  =   4.000    
    ##                         Activity of water  =   1.000
    ##                  Ionic strength (mol/kgw)  =   2.001e-04
    ##                        Mass of water (kg)  =   1.000e+00
    ##                  Total alkalinity (eq/kg)  =   2.499e-08
    ##                     Total carbon (mol/kg)  =   0.000e+00
    ##                        Total CO2 (mol/kg)  =   0.000e+00
    ##                          Temperature (oC)  =  25.00
    ##                   Electrical balance (eq)  =   2.000e-04
    ##  Percent error, 100*(Cat-|An|)/(Cat+|An|)  =  99.90
    ##                                Iterations  =   4
    ##                                   Total H  = 1.110124e+02
    ##                                   Total O  = 5.550622e+01
    ## 
    ## ----------------------------Distribution of species----------------------------
    ## 
    ##                                                Log       Log       Log    mole V
    ##    Species          Molality    Activity  Molality  Activity     Gamma   cm3/mol
    ## 
    ##    OH-             1.021e-07   1.005e-07    -6.991    -6.998    -0.007     (0)  
    ##    H+              1.016e-07   1.000e-07    -6.993    -7.000    -0.007      0.00
    ##    H2O             5.551e+01   1.000e+00     1.744    -0.000     0.000     18.07
    ## H(0)          1.416e-25
    ##    H2              7.079e-26   7.079e-26   -25.150   -25.150     0.000     (0)  
    ## Mn(2)         1.000e-04
    ##    Mn+2            9.998e-05   9.372e-05    -4.000    -4.028    -0.028     (0)  
    ##    MnOH+           2.448e-08   2.409e-08    -7.611    -7.618    -0.007     (0)  
    ##    Mn(OH)3-        1.510e-18   1.485e-18   -17.821   -17.828    -0.007     (0)  
    ## Mn(3)         3.366e-26
    ##    Mn+3            3.366e-26   2.916e-26   -25.473   -25.535    -0.062     (0)  
    ## Mn(6)         0.000e+00
    ##    MnO4-2          0.000e+00   0.000e+00   -50.440   -50.468    -0.028     (0)  
    ## Mn(7)         0.000e+00
    ##    MnO4-           0.000e+00   0.000e+00   -55.845   -55.852    -0.007     (0)  
    ## O(0)          0.000e+00
    ##    O2              0.000e+00   0.000e+00   -42.080   -42.080     0.000     (0)  
    ## 
    ## ------------------------------Saturation indices-------------------------------
    ## 
    ##   Phase               SI** log IAP   log K(298 K,   1 atm)
    ## 
    ##   Birnessite      -11.63      6.46   18.09  MnO2
    ##   Bixbyite         -8.46     -9.07   -0.61  Mn2O3
    ##   Hausmannite      -9.62     51.92   61.54  Mn3O4
    ##   Manganite        -4.30     -4.54   -0.24  MnOOH
    ##   Nsutite         -11.04      6.46   17.50  MnO2
    ##   O2(g)           -39.12     44.00   83.12  O2
    ##   Pyrocroite       -5.12      9.97   15.09  Mn(OH)2
    ##   Pyrolusite       -9.40      6.46   15.86  MnO2
    ## 
    ## **For a gas, SI = log10(fugacity). Fugacity = pressure * phi / 1 atm.
    ##   For ideal gases, phi = 1.
    ## 
    ## ------------------
    ## End of simulation.
    ## ------------------
    ## 
    ## ------------------------------------
    ## Reading input data for simulation 2.
    ## ------------------------------------
    ## 
    ## ---------------------------------
    ## End of Run after 1.79396 Seconds.
    ## ---------------------------------

Alright! This suggests that the species we should consider in the water are Mn<sup>+2</sup>, MnOH<sup>+</sup>, Mn(OH)<sub>3</sub><sup>-</sup>, Mn<sup>+3</sup>, MnO<sub>4</sub><sup>-2</sup>, and MnO<sub>4</sub><sup>-</sup>. Additionally, there are a number of solid phases that should be considered. Usually when running a PHREEQC run, its best to look at the output of one or two equilibrium calculations to see what species are being considered (if you change databases, this list will change! You can also add your own phases/reactions if you know what you're up to with PHREEQC).

To get machine-readable output, we need to add things to the `phr_selected_output()` block. There are [extensive instructions](https://wwwbrr.cr.usgs.gov/projects/GWC_coupled/phreeqc/phreeqc3-html/phreeqc3-38.htm) on this block in the documentation, but the gist of it is that for equilibrium calculations, soluble species show up in the `activities` argument, and solid phases show up in the `saturation_indicies` argument (and you have to use the mineral name, not the chemical formula).

``` r
phr_run(
  phr_solution(Mn = 0.1),
  phr_selected_output(
    activities = c("Mn+2", "MnOH+", "Mn(OH)3-", "Mn+3", "MnO4-2", "MnO4-"),
    saturation_indices = c(
      "Birnessite", "Bixbyite", "Hausmannite", "Manganite",
      "Nsutite", "Pyrocroite", "Pyrolusite"
    ),
    temp = TRUE
  )
) %>%
  as_tibble() %>%
  select(pH, pe, `temp(C)`, starts_with("la_"), starts_with("si_"))
```

    ## # A tibble: 1 x 16
    ##      pH    pe `temp(C)` `la_Mn+2` `la_MnOH+` `la_Mn(OH)3-` `la_Mn+3`
    ##   <dbl> <dbl>     <dbl>     <dbl>      <dbl>         <dbl>     <dbl>
    ## 1  7.00  4.00      25.0     -4.03      -7.62         -17.8     -25.5
    ## # ... with 9 more variables: `la_MnO4-2` <dbl>, `la_MnO4-` <dbl>,
    ## #   si_Birnessite <dbl>, si_Bixbyite <dbl>, si_Hausmannite <dbl>,
    ## #   si_Manganite <dbl>, si_Nsutite <dbl>, si_Pyrocroite <dbl>,
    ## #   si_Pyrolusite <dbl>

You'll notice that all the things you put in the `activities` list are prefixed with `la_` (log activity), and all the things from the `solution_indicies` get prefixed with `si_`. If you misspell something (or a perfectly reasonable species isn't in the database), you will get all `NA` values in the column.

The real power of PHREEQC is that it can run lots of simulations very quickly, and `phr_solution_list()` can generate lots of solutions along a gradient. For example, we could take a look at species of Mn in solution along a pH gradient:

``` r
phr_run(
  phr_solution_list(Mn = 0.1, pe = 4, pH = seq(1, 13, by = 0.1)),
  phr_selected_output(
    activities = c("Mn+2", "MnOH+", "Mn(OH)3-", "Mn+3", "MnO4-2", "MnO4-")
  )
)  %>%
  as_tibble() %>%
  select(pH, starts_with("la_")) %>%
  gather(key = "species", value = "log_activity", -pH) %>%
  mutate(activity = 10^log_activity) %>%
  ggplot(aes(pH, activity, col = species)) +
  geom_line()
```

    ## Warning: package 'bindrcpp' was built under R version 3.4.4

![](pH-1.png)

Or, by passing a vector of temperature values, we could look at the temperature-pH relationship:

``` r
phr_run(
  phr_solution_list(Mn = 0.1, temp = c(25, 50, 75), pH = seq(1, 13, by = 0.1)),
  phr_selected_output(
    activities = c("Mn+2", "MnOH+", "Mn(OH)3-", "Mn+3", "MnO4-2", "MnO4-"),
    temp = TRUE
  )
)  %>%
  as_tibble() %>%
  select(pH, temp = `temp(C)`, starts_with("la_")) %>%
  gather(key = "species", value = "log_activity", -pH, -temp) %>%
  mutate(activity = 10^log_activity) %>%
  ggplot(aes(pH, activity, col = species, lty = factor(temp))) +
  geom_line()
```

![](temp-ph-1.png)

Finally, by looking at pH, pe, and temperature, we can build a 3D pourbaix diagram! The code for this is quite complex because it involves converting regions into polygons using **raster** and **sf**, but you can find it at [this gist](https://gist.github.com/paleolimbot/e854c098c6d95330c361014276b5a8db). It's an interesting perspective on the Pourbaix diagram, because it is asking a slightly different question. Rather than "what is dominant", a pH-pe diagram based on PHREEQC can ask both "what species is most likely to occur in the water", and "what species is most likely to precipitate". I've done this animation along the temperature axis, but it's possible to do this under many different scenarios using PHREEQC.

![](pourbaix-anim-1.gif)
