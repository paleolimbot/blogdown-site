---
title: 'R data structures for Chemical Modeling'
author: Dewey Dunnington
date: '2017-08-25'
slug: []
categories: []
tags: ["chemistry", "R", "Releases", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2017-08-25T13:17:51+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

In the past few months I've done some work on <a href="http://apps.fishandwhistle.net/archives/1268">PHREEQC modeling in R</a>, as well as a whole lot of XRF data work that required converting what seemed like an ungodly number of molecular concentrations (e.g. Al2O3) into elemental concentrations (Al). Both of these highlighted a need for chemical data structures in R such that user input to <a href="https://github.com/paleolimbot/easyphreeqc">easyphreeqc</a> can be properly validated and chemical calculations can be made reproducible easily. The result is <a href="https://github.com/paleolimbot/chemr">chemr</a>, which will hopefully integrate soon with other packages of the chemical persuasion.


Installation
------------

You can install chemr from github with:

``` r
# install.packages("devtools")
devtools::install_github("paleolimbot/chemr")
```

If you can load the package, everything worked!

``` r
library(chemr)
```

The periodic tibble
-------------------

The periodic tibble is [Wikipedia's version of the periodic table](https://en.wikipedia.org/wiki/List_of_chemical_elements) in data.frame (tibble) form. You can access these data in a few ways:

``` r
is_element("Hg")
#> [1] TRUE
```

``` r
elmass("Hg")
#>       Hg 
#> 200.5923
```

``` r
elz("Hg")
#> Hg 
#> 80
```

``` r
elsymbol(80)
#> [1] "Hg"
```

You can also access the entire periodic tibble by typing `data(pt)`.

``` r
data(pt)
pt
#> # A tibble: 118 x 7
#>        z symbol      name group period      mass   valence
#>    <int>  <chr>     <chr> <int>  <int>     <dbl>    <list>
#>  1     1      H  Hydrogen     1      1  1.008000 <int [3]>
#>  2     2     He    Helium    18      1  4.002602 <int [1]>
#>  3     3     Li   Lithium     1      2  6.940000 <int [2]>
#>  4     4     Be Beryllium     2      2  9.012183 <int [3]>
#>  5     5      B     Boron    13      2 10.810000 <int [6]>
#>  6     6      C    Carbon    14      2 12.011000 <int [9]>
#>  7     7      N  Nitrogen    15      2 14.007000 <int [9]>
#>  8     8      O    Oxygen    16      2 15.999000 <int [5]>
#>  9     9      F  Fluorine    17      2 18.998403 <int [2]>
#> 10    10     Ne      Neon    18      2 20.179760 <int [1]>
#> # ... with 108 more rows
```

Molecules
---------

Molecules are a collection of counted elements (or sub-molecules) with a charge. While it's possible to create a molecule by "hand", it's much easier to use the character representation of a molecule, which is usually what you get when copy/pasting from a source.

``` r
mol("H2O")
#> <mol>
#> [1] H2O
```

And like everything else in R, `mol` objects are vectorized, so you can serialize an entire column of molecule formulas.

``` r
as_mol(c("H2O", "H+", "Fe(OH)3", "Ca+2"))
#> <mol>
#> [1] H2O     H+      Fe(OH)3 Ca+2
```

You can access the mass, charge, and elemental composition of a molecule using `mass()`, `charge()`, and `as.data.frame()` or `as.matrix()`

``` r
m <- as_mol(c("H2O", "H+", "Fe(OH)3", "Ca+2"))
mass(m)
#> [1]  18.0150   1.0080 106.8662  40.0784
```

``` r
charge(m)
#> [1] 0 1 0 2
```

``` r
as.data.frame(m)
#>       mol mol_text     mass charge H O Fe Ca
#> 1    2, 1      H2O  18.0150      0 2 1  0  0
#> 2       1       H+   1.0080      1 1 0  0  0
#> 3 1, 1, 1  Fe(OH)3 106.8662      0 3 3  1  0
#> 4       1     Ca+2  40.0784      2 0 0  0  1
```

Reactions
---------

Reactions are essentially a molecule vector with coefficients (positive for the left side, negative for the right side). Similar to molecules, it's easiest to use the serialized form (conveniently, what is generally copied/pasted):

``` r
as_reaction("2H2 + O2 = 2H2O")
#> <reaction> 2H2 + O2 = 2H2O
```

The `is_balanced()` and `balance()` functions will happily balance these for you, provided you have the correct number of species defined.

``` r
balance("H2 + O2 = H2O")
#> <reaction> 2H2 + O2 = 2H2O
```

You can access various components of a reaction in the same way as for molecules:

``` r
r <- as_reaction("2H2 + O2 = 2H2O")
lhs(r)
#> <reaction> 2H2 + O2 =
```

``` r
rhs(r)
#> <reaction> 2H2O =
```

``` r
mass(r) # mass balance of the reaction
#> [1] 0
```

``` r
charge(r) # charge balance of the reaction
#> [1] 0
```

``` r
as.data.frame(r)
#>    mol mol_text charge   mass coefficient H O
#> 1    2       H2      0  2.016           2 2 0
#> 2    2       O2      0 31.998           1 0 2
#> 3 2, 1      H2O      0 18.015          -2 2 1
```

``` r
as.matrix(r)
#>      H  O
#> H2   4  0
#> O2   0  2
#> H2O -4 -2
```

Molecule and Reaction arithmetic
--------------------------------

Various arithmetic operators are available for molecule and reaction objects, such as `+`, `*` and `==`.

``` r
m <- mol(~Fe2O3, ~H2O, ~NH3, ~`H+`)
m + as_mol("OH-")
#> <mol>
#> [1] Fe2O3OH- H2OOH-   NH3OH-   HOH
```

``` r
m * 2
#> <mol>
#> [1] Fe4O6 H4O2  N2H6  H2+2
```

``` r
m == as_mol(~H2O)
#> [1] FALSE  TRUE FALSE FALSE
```

Reactions have similar arithmetic, with coefficients to various molecules being added together.

``` r
r1 <- as_reaction("2H2 + O2 = 2H2O")
r1 + as_reaction("H2O = H2O")
#> <reaction> 2H2 + O2 + H2O = 2H2O + H2O
```

By default the reaction isn't simplified, but can be using `simplify()` and `remove_zero_counts()`.

``` r
simplify(r1 + as_reaction("H2O = H2O"))
#> <reaction> 2H2 + O2 = 2H2O
```

``` r
simplify(r1 - as_reaction("2H+ + 2OH- = 2H2O"))
#> <reaction> 2H2 + O2 + 0H2O = 2H+ + 2OH-
```

``` r
remove_zero_counts(simplify(r1 - as_reaction("2H+ + 2OH- = 2H2O")))
#> <reaction> 2H2 + O2 = 2H+ + 2OH-
```

The Wish List
-------------

There are lots of things missing from this package that should exist, including the include various parameters to molecules and equations such as *Δ**H* or aliases (e.g., `CaSO4` as "gypsum"). Additionally, there is currently no way to indicate hydration in the same way as PHREEQC (e.g., `CaSO4:2H2O`). Currently this is possible only as `CaSO4(H2O)2`. Feel free to [contribute to development](https://github.com/paleolimbot/chemr) or [submit feature requests](https://github.com/paleolimbot/chemr/issues) on GitHub.
