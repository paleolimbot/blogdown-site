---
title: "wk version 0.5.0!"
subtitle: ""
summary: ""
authors: []
tags: []
categories: []
date: 2021-07-12T20:37:02-04:00
lastmod: 2021-07-12T20:37:02-04:00
featured: false
draft: false
image:
  caption: ""
  focal_point: ""
  preview_only: false
projects: []
output: hugodown::md_document
rmd_hash: 393f9477184e9930

---

A new version of wk is fresh on CRAN! Version 0.5 introduces some new features to the framework, incorporates most of the functionality that was previously in the [wkutils](https://github.com/paleolimbot/wkutils) package, and fixes a number of bugs that popped up in the development of [s2](https://github.com/r-spatial/s2) and [geos](https://github.com/paleolimbot/geos). To showcase some of the new features I'll use the [Vermont counties data set from the VT Open Geodata Portal](https://geodata.vermont.gov/datasets/2f289dbae90347c58cd1765db84bd09e_29/explore).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://paleolimbot.github.io/wk/'>wk</a></span><span class='o'>)</span>
<span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://r-spatial.github.io/sf/'>sf</a></span><span class='o'>)</span>
<span class='nv'>vt</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://r-spatial.github.io/sf/reference/st_read.html'>read_sf</a></span><span class='o'>(</span><span class='s'>"VT_Data_-_County_Boundaries.geojson"</span><span class='o'>)</span><span class='o'>[</span><span class='s'>"CNTYNAME"</span><span class='o'>]</span>
<span class='nv'>vt</span>
<span class='c'>#&gt; Simple feature collection with 14 features and 1 field</span>
<span class='c'>#&gt; Geometry type: MULTIPOLYGON</span>
<span class='c'>#&gt; Dimension:     XY</span>
<span class='c'>#&gt; Bounding box:  xmin: -73.4379 ymin: 42.72697 xmax: -71.46539 ymax: 45.01667</span>
<span class='c'>#&gt; Geodetic CRS:  WGS 84</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 14 x 2</span></span>
<span class='c'>#&gt;    CNTYNAME                                                             geometry</span>
<span class='c'>#&gt;    <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>                                                      <span style='color: #555555; font-style: italic;'>&lt;MULTIPOLYGON [°]&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span> ORLEANS    (((-71.92088 45.00785, -71.92933 45.00812, -71.94575 45.00838, -7…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span> GRAND ISLE (((-73.23344 44.66446, -73.23341 44.66632, -73.23355 44.66813, -7…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span> CHITTENDEN (((-73.10283 44.67616, -73.16068 44.69752, -73.16189 44.69799, -7…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span> WINDSOR    (((-72.77108 43.93907, -72.78996 43.94532, -72.78522 43.9522, -72…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span> WINDHAM    (((-72.70141 43.22634, -72.73021 43.2333, -72.75071 43.23825, -72…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span> BENNINGTON (((-73.0961 43.30715, -73.1146 43.30827, -73.12266 43.30869, -73.…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span> FRANKLIN   (((-72.99655 45.0148, -73.00945 45.01503, -73.01624 45.01516, -73…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span> ESSEX      (((-71.46539 45.01323, -71.4654 45.01338, -71.46541 45.01358, -71…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span> LAMOILLE   (((-72.60514 44.79044, -72.60572 44.79073, -72.60685 44.79128, -7…</span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span> CALEDONIA  (((-71.85297 44.70108, -71.84619 44.70755, -71.84129 44.7123, -71…</span>
<span class='c'>#&gt; <span style='color: #555555;'>11</span> ORANGE     (((-72.31223 44.18541, -72.3206 44.18818, -72.32826 44.1907, -72.…</span>
<span class='c'>#&gt; <span style='color: #555555;'>12</span> WASHINGTON (((-72.22314 44.42381, -72.22334 44.42408, -72.2235 44.42432, -72…</span>
<span class='c'>#&gt; <span style='color: #555555;'>13</span> RUTLAND    (((-72.85266 43.8336, -72.86138 43.83624, -72.86845 43.83816, -72…</span>
<span class='c'>#&gt; <span style='color: #555555;'>14</span> ADDISON    (((-72.97588 44.29505, -72.997 44.29923, -73.00585 44.30098, -73.…</span></code></pre>

</div>

### Breaking down features and building them back up again

The biggest feature in the new release is the ability to break down features to simpler components (at the simplest, a bunch of coordinates) and build them back up again into geometry that you can pass elsewhere. Some of this functionality previously lived in [wkutils](https://github.com/paleolimbot/wkutils) but it turns out this is really important: pretty much all geometry in base R is done with big long `x` and `y` vectors (e.g., [`xy.coords()`](https://rdrr.io/r/grDevices/xy.coords.html)). To make geometry that was previously locked away in WKB, WKT, or sf objects accessible, there needed to be a way out.

The first level of a geometry you might want to break down are collections: MULTIPOLYGON, MULTILINESTRING, MULTIPOINT, and GEOMETRYCOLLECTION. These types are useful when you have multiple things that represent one element in a vector, like multiple bits of land representing a county. In our case the features were saved as MULTIPOLYGON but there aren't actually any features with more than one. To simplify it, we can use [`wk_flatten()`](https://paleolimbot.github.io/wk/reference/wk_flatten.html):

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='o'>(</span><span class='nv'>vt_poly</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_flatten.html'>wk_flatten</a></span><span class='o'>(</span><span class='nv'>vt</span><span class='o'>)</span><span class='o'>)</span>
<span class='c'>#&gt; Simple feature collection with 15 features and 1 field</span>
<span class='c'>#&gt; Geometry type: POLYGON</span>
<span class='c'>#&gt; Dimension:     XY</span>
<span class='c'>#&gt; Bounding box:  xmin: -73.4379 ymin: 42.72697 xmax: -71.46539 ymax: 45.01667</span>
<span class='c'>#&gt; Geodetic CRS:  WGS 84</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 15 x 2</span></span>
<span class='c'>#&gt;    CNTYNAME                                                             geometry</span>
<span class='c'>#&gt;  <span style='color: #555555;'>*</span> <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>                                                           <span style='color: #555555; font-style: italic;'>&lt;POLYGON [°]&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span> ORLEANS    ((-71.92088 45.00785, -71.92933 45.00812, -71.94575 45.00838, -71…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span> GRAND ISLE ((-73.23344 44.66446, -73.23341 44.66632, -73.23355 44.66813, -73…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span> CHITTENDEN ((-73.10283 44.67616, -73.16068 44.69752, -73.16189 44.69799, -73…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span> WINDSOR    ((-72.77108 43.93907, -72.78996 43.94532, -72.78522 43.9522, -72.…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span> WINDHAM    ((-72.70141 43.22634, -72.73021 43.2333, -72.75071 43.23825, -72.…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span> BENNINGTON ((-73.0961 43.30715, -73.1146 43.30827, -73.12266 43.30869, -73.1…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span> FRANKLIN   ((-72.99655 45.0148, -73.00945 45.01503, -73.01624 45.01516, -73.…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span> ESSEX      ((-71.46539 45.01323, -71.4654 45.01338, -71.46541 45.01358, -71.…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span> LAMOILLE   ((-72.60514 44.79044, -72.60572 44.79073, -72.60685 44.79128, -72…</span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span> CALEDONIA  ((-71.85297 44.70108, -71.84619 44.70755, -71.84129 44.7123, -71.…</span>
<span class='c'>#&gt; <span style='color: #555555;'>11</span> CALEDONIA  ((-72.03989 44.15707, -72.03991 44.15719, -72.04024 44.15707, -72…</span>
<span class='c'>#&gt; <span style='color: #555555;'>12</span> ORANGE     ((-72.31223 44.18541, -72.3206 44.18818, -72.32826 44.1907, -72.3…</span>
<span class='c'>#&gt; <span style='color: #555555;'>13</span> WASHINGTON ((-72.22314 44.42381, -72.22334 44.42408, -72.2235 44.42432, -72.…</span>
<span class='c'>#&gt; <span style='color: #555555;'>14</span> RUTLAND    ((-72.85266 43.8336, -72.86138 43.83624, -72.86845 43.83816, -72.…</span>
<span class='c'>#&gt; <span style='color: #555555;'>15</span> ADDISON    ((-72.97588 44.29505, -72.997 44.29923, -73.00585 44.30098, -73.0…</span></code></pre>

</div>

By default [`wk_flatten()`](https://paleolimbot.github.io/wk/reference/wk_flatten.html) peels off one layer of collections, repeating rows where a feature has more than one element. This is a little like [`sf::st_cast()`](https://r-spatial.github.io/sf/reference/st_cast.html) but is defined in terms of what you have rather than what you want. For advanced users, the flattening functionality is also implemented as a [wk "filter"](https://paleolimbot.github.io/wk/dev/articles/articles/programming.html#filters), which means it can do most of what it does without allocating any extra memory and can stream input and output very efficiently.

I'm demonstrating all of this with sf because it's the most common use-case, but it works with any data frame/tibble with exactly one column implementing the [`wk_handle()`](https://paleolimbot.github.io/wk/reference/wk_handle.html) generic (including an [`st_sfc()`](https://r-spatial.github.io/sf/reference/sfc.html)!). In fact, pretty much anything you do with wk also "just works" with data frames.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>vt_tbl</span> <span class='o'>&lt;-</span> <span class='nf'>tibble</span><span class='nf'>::</span><span class='nf'><a href='https://tibble.tidyverse.org/reference/tibble.html'>tibble</a></span><span class='o'>(</span><span class='nv'>vt</span><span class='o'>$</span><span class='nv'>CNTYNAME</span>, geom <span class='o'>=</span> <span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wkb.html'>as_wkb</a></span><span class='o'>(</span><span class='nv'>vt</span><span class='o'>)</span><span class='o'>)</span>
<span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_flatten.html'>wk_flatten</a></span><span class='o'>(</span><span class='nv'>vt_tbl</span><span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 15 x 2</span></span>
<span class='c'>#&gt;    `vt$CNTYNAME` geom                                                           </span>
<span class='c'>#&gt;    <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>         <span style='color: #555555; font-style: italic;'>&lt;wk_wkb&gt;</span>                                                       </span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span> ORLEANS       &lt;POLYGON ((-71.9209 45.0079, -71.9293 45.0081, -71.9458 45.008…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span> GRAND ISLE    &lt;POLYGON ((-73.2334 44.6645, -73.2334 44.6663, -73.2336 44.668…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span> CHITTENDEN    &lt;POLYGON ((-73.1028 44.6762, -73.1607 44.6975, -73.1619 44.698…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span> WINDSOR       &lt;POLYGON ((-72.7711 43.9391, -72.79 43.9453, -72.7852 43.9522.…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span> WINDHAM       &lt;POLYGON ((-72.7014 43.2263, -72.7302 43.2333, -72.7507 43.238…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span> BENNINGTON    &lt;POLYGON ((-73.0961 43.3072, -73.1146 43.3083, -73.1227 43.308…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span> FRANKLIN      &lt;POLYGON ((-72.9966 45.0148, -73.0094 45.015, -73.0162 45.0152…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span> ESSEX         &lt;POLYGON ((-71.4654 45.0132, -71.4654 45.0134, -71.4654 45.013…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span> LAMOILLE      &lt;POLYGON ((-72.6051 44.7904, -72.6057 44.7907, -72.6069 44.791…</span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span> CALEDONIA     &lt;POLYGON ((-71.853 44.7011, -71.8462 44.7076, -71.8413 44.7123…</span>
<span class='c'>#&gt; <span style='color: #555555;'>11</span> CALEDONIA     &lt;POLYGON ((-72.0399 44.1571, -72.0399 44.1572, -72.0402 44.157…</span>
<span class='c'>#&gt; <span style='color: #555555;'>12</span> ORANGE        &lt;POLYGON ((-72.3122 44.1854, -72.3206 44.1882, -72.3283 44.190…</span>
<span class='c'>#&gt; <span style='color: #555555;'>13</span> WASHINGTON    &lt;POLYGON ((-72.2231 44.4238, -72.2233 44.4241, -72.2235 44.424…</span>
<span class='c'>#&gt; <span style='color: #555555;'>14</span> RUTLAND       &lt;POLYGON ((-72.8527 43.8336, -72.8614 43.8362, -72.8685 43.838…</span>
<span class='c'>#&gt; <span style='color: #555555;'>15</span> ADDISON       &lt;POLYGON ((-72.9759 44.295, -72.997 44.2992, -73.0058 44.301..…</span></code></pre>

</div>

The next level is vertices: one point feature for each vertex in the input.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='o'>(</span><span class='nv'>vt_vertices</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_vertices.html'>wk_vertices</a></span><span class='o'>(</span><span class='nv'>vt</span><span class='o'>)</span><span class='o'>)</span>
<span class='c'>#&gt; Simple feature collection with 18342 features and 1 field</span>
<span class='c'>#&gt; Geometry type: POINT</span>
<span class='c'>#&gt; Dimension:     XY</span>
<span class='c'>#&gt; Bounding box:  xmin: -73.4379 ymin: 42.72697 xmax: -71.46539 ymax: 45.01667</span>
<span class='c'>#&gt; Geodetic CRS:  WGS 84</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 18,342 x 2</span></span>
<span class='c'>#&gt;    CNTYNAME             geometry</span>
<span class='c'>#&gt;  <span style='color: #555555;'>*</span> <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>             <span style='color: #555555; font-style: italic;'>&lt;POINT [°]&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span> ORLEANS  (-71.92088 45.00785)</span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span> ORLEANS  (-71.92933 45.00812)</span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span> ORLEANS  (-71.94575 45.00838)</span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span> ORLEANS   (-71.95514 45.0082)</span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span> ORLEANS  (-71.96699 45.00797)</span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span> ORLEANS  (-72.00706 45.00717)</span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span> ORLEANS  (-72.00985 45.00712)</span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span> ORLEANS  (-72.01698 45.00697)</span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span> ORLEANS  (-72.02311 45.00681)</span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span> ORLEANS  (-72.02493 45.00677)</span>
<span class='c'>#&gt; <span style='color: #555555;'># … with 18,332 more rows</span></span></code></pre>

</div>

Vertices are useful if you need to input something that requires points but you were handed a boundary or polygon layer (I use this kind of thing to set depth values at 0 along coastlines when calculating bathymetry, for example). This is good for GIS function stuff, but if you're doing any custom geometry processing or just need coordinates for ggplot2 or some base R function, you'll need straight up `x` and `y` vectors. If so, the new [`wk_coords()`](https://paleolimbot.github.io/wk/reference/wk_vertices.html) function is just for you!

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='o'>(</span><span class='nv'>vt_coords</span> <span class='o'>&lt;-</span> <span class='nf'>tibble</span><span class='nf'>::</span><span class='nf'><a href='https://tibble.tidyverse.org/reference/as_tibble.html'>as_tibble</a></span><span class='o'>(</span><span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_vertices.html'>wk_coords</a></span><span class='o'>(</span><span class='nv'>vt</span><span class='o'>)</span><span class='o'>)</span><span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 18,342 x 5</span></span>
<span class='c'>#&gt;    feature_id part_id ring_id     x     y</span>
<span class='c'>#&gt;         <span style='color: #555555; font-style: italic;'>&lt;int&gt;</span>   <span style='color: #555555; font-style: italic;'>&lt;int&gt;</span>   <span style='color: #555555; font-style: italic;'>&lt;int&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;dbl&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;dbl&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span>          1       2       1 -<span style='color: #BB0000;'>71.9</span>  45.0</span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span>          1       2       1 -<span style='color: #BB0000;'>71.9</span>  45.0</span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span>          1       2       1 -<span style='color: #BB0000;'>71.9</span>  45.0</span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span>          1       2       1 -<span style='color: #BB0000;'>72.0</span>  45.0</span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span>          1       2       1 -<span style='color: #BB0000;'>72.0</span>  45.0</span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span>          1       2       1 -<span style='color: #BB0000;'>72.0</span>  45.0</span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span>          1       2       1 -<span style='color: #BB0000;'>72.0</span>  45.0</span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span>          1       2       1 -<span style='color: #BB0000;'>72.0</span>  45.0</span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span>          1       2       1 -<span style='color: #BB0000;'>72.0</span>  45.0</span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span>          1       2       1 -<span style='color: #BB0000;'>72.0</span>  45.0</span>
<span class='c'>#&gt; <span style='color: #555555;'># … with 18,332 more rows</span></span></code></pre>

</div>

And, of course, sometimes you get handed a bunch of coordinates but you really want an sf object. For this case there is [`wk_linestring()`](https://paleolimbot.github.io/wk/reference/wk_linestring.html), [`wk_polygon()`](https://paleolimbot.github.io/wk/reference/wk_linestring.html), and [`wk_collection()`](https://paleolimbot.github.io/wk/reference/wk_linestring.html). For example, to reconstruct the original sf object starting with coordinates we could do:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>vt_poly_reconstructed</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_linestring.html'>wk_polygon</a></span><span class='o'>(</span>
  <span class='nf'><a href='https://paleolimbot.github.io/wk/reference/xy.html'>xy</a></span><span class='o'>(</span><span class='nv'>vt_coords</span><span class='o'>$</span><span class='nv'>x</span>, <span class='nv'>vt_coords</span><span class='o'>$</span><span class='nv'>y</span>, crs <span class='o'>=</span> <span class='s'>"WGS84"</span><span class='o'>)</span>,
  feature_id <span class='o'>=</span> <span class='nv'>vt_coords</span><span class='o'>$</span><span class='nv'>feature_id</span>,
  ring_id <span class='o'>=</span> <span class='nv'>vt_coords</span><span class='o'>$</span><span class='nv'>ring_id</span>
<span class='o'>)</span>

<span class='nv'>vt_multipoly_reconstructed</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_linestring.html'>wk_collection</a></span><span class='o'>(</span>
  <span class='nv'>vt_poly_reconstructed</span>,
  geometry_type <span class='o'>=</span> <span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_meta.html'>wk_geometry_type</a></span><span class='o'>(</span><span class='s'>"multipolygon"</span><span class='o'>)</span>,
  feature_id <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/seq.html'>seq_along</a></span><span class='o'>(</span><span class='nv'>vt_poly_reconstructed</span><span class='o'>)</span>
<span class='o'>)</span>

<span class='nf'><a href='https://r-spatial.github.io/sf/reference/st_as_sfc.html'>st_as_sfc</a></span><span class='o'>(</span><span class='nv'>vt_multipoly_reconstructed</span><span class='o'>)</span>
<span class='c'>#&gt; Geometry set for 14 features </span>
<span class='c'>#&gt; Geometry type: MULTIPOLYGON</span>
<span class='c'>#&gt; Dimension:     XY</span>
<span class='c'>#&gt; Bounding box:  xmin: -73.4379 ymin: 42.72697 xmax: -71.46539 ymax: 45.01667</span>
<span class='c'>#&gt; Geodetic CRS:  WGS 84</span>
<span class='c'>#&gt; First 5 geometries:</span>
<span class='c'>#&gt; MULTIPOLYGON (((-71.92088 45.00785, -71.92933 4...</span>
<span class='c'>#&gt; MULTIPOLYGON (((-73.23344 44.66446, -73.23341 4...</span>
<span class='c'>#&gt; MULTIPOLYGON (((-73.10283 44.67616, -73.16068 4...</span>
<span class='c'>#&gt; MULTIPOLYGON (((-72.77108 43.93907, -72.78996 4...</span>
<span class='c'>#&gt; MULTIPOLYGON (((-72.70141 43.22634, -72.73021 4...</span></code></pre>

</div>

### dplyr integration

There's nothing new about dplyr's ability to work with vectors in wk 0.5, but the new functions are well-suited to dplyr's [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html) and [`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html) as well as the newish auto-unpacking feature in [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) and [`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html). For example, to keep all the attributes when calling [`wk_coords()`](https://paleolimbot.github.io/wk/reference/wk_vertices.html) you can do:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://dplyr.tidyverse.org'>dplyr</a></span><span class='o'>)</span>

<span class='nv'>vt</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://tibble.tidyverse.org/reference/as_tibble.html'>as_tibble</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/group_by.html'>group_by</a></span><span class='o'>(</span><span class='nv'>CNTYNAME</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/summarise.html'>summarise</a></span><span class='o'>(</span><span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_vertices.html'>wk_coords</a></span><span class='o'>(</span><span class='nv'>geometry</span><span class='o'>)</span><span class='o'>)</span>
<span class='c'>#&gt; `summarise()` has grouped output by 'CNTYNAME'. You can override using the `.groups` argument.</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 18,342 x 6</span></span>
<span class='c'>#&gt; <span style='color: #555555;'># Groups:   CNTYNAME [14]</span></span>
<span class='c'>#&gt;    CNTYNAME feature_id part_id ring_id     x     y</span>
<span class='c'>#&gt;    <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>         <span style='color: #555555; font-style: italic;'>&lt;int&gt;</span>   <span style='color: #555555; font-style: italic;'>&lt;int&gt;</span>   <span style='color: #555555; font-style: italic;'>&lt;int&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;dbl&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;dbl&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span> ADDISON           1       2       1 -<span style='color: #BB0000;'>73.0</span>  44.3</span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span> ADDISON           1       2       1 -<span style='color: #BB0000;'>73.0</span>  44.3</span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span> ADDISON           1       2       1 -<span style='color: #BB0000;'>73.0</span>  44.3</span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span> ADDISON           1       2       1 -<span style='color: #BB0000;'>73.0</span>  44.3</span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span> ADDISON           1       2       1 -<span style='color: #BB0000;'>73.0</span>  44.3</span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span> ADDISON           1       2       1 -<span style='color: #BB0000;'>73.0</span>  44.3</span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span> ADDISON           1       2       1 -<span style='color: #BB0000;'>73.0</span>  44.3</span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span> ADDISON           1       2       1 -<span style='color: #BB0000;'>73.0</span>  44.3</span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span> ADDISON           1       2       1 -<span style='color: #BB0000;'>73.0</span>  44.3</span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span> ADDISON           1       2       1 -<span style='color: #BB0000;'>73.0</span>  44.3</span>
<span class='c'>#&gt; <span style='color: #555555;'># … with 18,332 more rows</span></span></code></pre>

</div>

To build back up a geometry you can also use [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html) and [`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html) in their more traditional roles (returning one row per group). This is a tiny bit slower but *so* much easier to read.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>vt_coords</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/group_by.html'>group_by</a></span><span class='o'>(</span><span class='nv'>feature_id</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/summarise.html'>summarise</a></span><span class='o'>(</span>geom <span class='o'>=</span> <span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_linestring.html'>wk_polygon</a></span><span class='o'>(</span><span class='nf'><a href='https://paleolimbot.github.io/wk/reference/xy.html'>xy</a></span><span class='o'>(</span><span class='nv'>x</span>, <span class='nv'>y</span>, crs <span class='o'>=</span> <span class='s'>"WGS84"</span><span class='o'>)</span><span class='o'>)</span><span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 14 x 2</span></span>
<span class='c'>#&gt;    feature_id geom                                                              </span>
<span class='c'>#&gt;         <span style='color: #555555; font-style: italic;'>&lt;int&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;wk_wkb&gt;</span>                                                          </span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span>          1 &lt;POLYGON ((-71.9209 45.0079, -71.9293 45.0081, -71.9458 45.0084..…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span>          2 &lt;POLYGON ((-73.2334 44.6645, -73.2334 44.6663, -73.2336 44.6681..…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span>          3 &lt;POLYGON ((-73.1028 44.6762, -73.1607 44.6975, -73.1619 44.698...&gt;</span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span>          4 &lt;POLYGON ((-72.7711 43.9391, -72.79 43.9453, -72.7852 43.9522...&gt; </span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span>          5 &lt;POLYGON ((-72.7014 43.2263, -72.7302 43.2333, -72.7507 43.2382..…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span>          6 &lt;POLYGON ((-73.0961 43.3072, -73.1146 43.3083, -73.1227 43.3087..…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span>          7 &lt;POLYGON ((-72.9966 45.0148, -73.0094 45.015, -73.0162 45.0152...&gt;</span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span>          8 &lt;POLYGON ((-71.4654 45.0132, -71.4654 45.0134, -71.4654 45.0136..…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span>          9 &lt;POLYGON ((-72.6051 44.7904, -72.6057 44.7907, -72.6069 44.7913..…</span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span>         10 &lt;POLYGON ((-71.853 44.7011, -71.8462 44.7076, -71.8413 44.7123...&gt;</span>
<span class='c'>#&gt; <span style='color: #555555;'>11</span>         11 &lt;POLYGON ((-72.3122 44.1854, -72.3206 44.1882, -72.3283 44.1907..…</span>
<span class='c'>#&gt; <span style='color: #555555;'>12</span>         12 &lt;POLYGON ((-72.2231 44.4238, -72.2233 44.4241, -72.2235 44.4243..…</span>
<span class='c'>#&gt; <span style='color: #555555;'>13</span>         13 &lt;POLYGON ((-72.8527 43.8336, -72.8614 43.8362, -72.8685 43.8382..…</span>
<span class='c'>#&gt; <span style='color: #555555;'>14</span>         14 &lt;POLYGON ((-72.9759 44.295, -72.997 44.2992, -73.0058 44.301...&gt;</span></code></pre>

</div>

The new coordinate functions make dplyr more accessible for doing raw coordinate processing if you're into that kind of thing. If you'll recall the [short formula](https://en.wikipedia.org/wiki/Shoelace_formula) for the signed area of a polygon, you can check the winding direction of your polygons without leaving dplyr (the polygons here are wound correctly, hence the positive areas).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>vt</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://tibble.tidyverse.org/reference/as_tibble.html'>as_tibble</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/group_by.html'>group_by</a></span><span class='o'>(</span><span class='nv'>CNTYNAME</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/summarise.html'>summarise</a></span><span class='o'>(</span><span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_vertices.html'>wk_coords</a></span><span class='o'>(</span><span class='nv'>geometry</span><span class='o'>)</span>, .groups <span class='o'>=</span> <span class='s'>"keep"</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/summarise.html'>summarise</a></span><span class='o'>(</span>
    signed_area <span class='o'>=</span> <span class='m'>0.5</span> <span class='o'>*</span> <span class='nf'><a href='https://rdrr.io/r/base/sum.html'>sum</a></span><span class='o'>(</span>
      <span class='o'>(</span><span class='nf'><a href='https://dplyr.tidyverse.org/reference/lead-lag.html'>lag</a></span><span class='o'>(</span><span class='nv'>x</span>, <span class='m'>1</span><span class='o'>)</span> <span class='o'>-</span> <span class='nf'><a href='https://dplyr.tidyverse.org/reference/nth.html'>first</a></span><span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>*</span> <span class='o'>(</span><span class='nv'>y</span> <span class='o'>-</span> <span class='nf'><a href='https://dplyr.tidyverse.org/reference/lead-lag.html'>lag</a></span><span class='o'>(</span><span class='nv'>y</span>, <span class='m'>2</span><span class='o'>)</span><span class='o'>)</span>,
      na.rm <span class='o'>=</span> <span class='kc'>TRUE</span>
    <span class='o'>)</span>
  <span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 14 x 2</span></span>
<span class='c'>#&gt;    CNTYNAME   signed_area</span>
<span class='c'>#&gt;    <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>            <span style='color: #555555; font-style: italic;'>&lt;dbl&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span> ADDISON         0.235 </span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span> BENNINGTON      0.194 </span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span> CALEDONIA       0.243 </span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span> CHITTENDEN      0.182 </span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span> ESSEX           0.198 </span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span> FRANKLIN        0.203 </span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span> GRAND ISLE      0.057<span style='text-decoration: underline;'>0</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span> LAMOILLE        0.137 </span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span> ORANGE          0.201 </span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span> ORLEANS         0.213 </span>
<span class='c'>#&gt; <span style='color: #555555;'>11</span> RUTLAND         0.273 </span>
<span class='c'>#&gt; <span style='color: #555555;'>12</span> WASHINGTON      0.203 </span>
<span class='c'>#&gt; <span style='color: #555555;'>13</span> WINDHAM         0.228 </span>
<span class='c'>#&gt; <span style='color: #555555;'>14</span> WINDSOR         0.282</span></code></pre>

</div>

### First-class coordinate transforms

Some of the coolest new stuff in GIS is actually in JavaScript, like the [really awesome tools for animated projections](https://bost.ocks.org/mike/example/) in D3. The tools in D3 work on arbitrary coordinate transforms (read: PROJ), but the tools that work on the transforms don't have to know anything about datums or projections...they just care about a coordinate moving from one place to the next. This kind of thing is really common in GIS and visualization and deserved first-class support in wk. For those paying close attention to s2 development, I also need it to make geometry represented in Cartesian space valid on the sphere given an arbitrary projection (currently only [implemented](https://r-spatial.github.io/s2/reference/s2_unprojection_filter.html) for plate carree).

Starting small, though, wk just provides the framework so that other packages can do cool stuff that I don't need to maintain (maybe). I did put in enough transforms to make sure every thing was tested, which includes an affine transform and transforms that set/drop coordinate values (most usefully, Z and M).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_transform.html'>wk_transform</a></span><span class='o'>(</span><span class='nv'>vt</span>, <span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_trans_affine.html'>wk_affine_rescale</a></span><span class='o'>(</span><span class='nv'>vt</span>, <span class='nf'><a href='https://paleolimbot.github.io/wk/reference/rct.html'>rct</a></span><span class='o'>(</span><span class='m'>0</span>, <span class='m'>0</span>, <span class='m'>1</span>, <span class='m'>1</span><span class='o'>)</span><span class='o'>)</span><span class='o'>)</span>
<span class='c'>#&gt; Simple feature collection with 14 features and 1 field</span>
<span class='c'>#&gt; Geometry type: MULTIPOLYGON</span>
<span class='c'>#&gt; Dimension:     XY</span>
<span class='c'>#&gt; Bounding box:  xmin: 0 ymin: 0 xmax: 1 ymax: 1</span>
<span class='c'>#&gt; CRS:           NA</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 14 x 2</span></span>
<span class='c'>#&gt;    CNTYNAME                                                             geometry</span>
<span class='c'>#&gt;  <span style='color: #555555;'>*</span> <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>                                                          <span style='color: #555555; font-style: italic;'>&lt;MULTIPOLYGON&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span> ORLEANS    (((0.7690821 0.9961481, 0.7647967 0.9962621, 0.7564697 0.9963774,…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span> GRAND ISLE (((0.1036546 0.8461755, 0.1036727 0.846988, 0.103599 0.847776, 0.…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span> CHITTENDEN (((0.1698733 0.8512869, 0.1405409 0.8606129, 0.1399308 0.8608186,…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span> WINDSOR    (((0.338057 0.5293715, 0.3284853 0.5321012, 0.330888 0.5351043, 0…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span> WINDHAM    (((0.3733756 0.2180931, 0.3587752 0.2211338, 0.3483849 0.2232952,…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span> BENNINGTON (((0.1732828 0.2533885, 0.1639036 0.2538759, 0.1598167 0.254059, …</span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span> FRANKLIN   (((0.2237507 0.9991795, 0.2172121 0.9992838, 0.2137688 0.9993384,…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span> ESSEX      (((1 0.9984975, 0.9999926 0.998561, 0.9999861 0.9986474, 0.999955…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span> LAMOILLE   (((0.4221812 0.9011965, 0.4218882 0.9013238, 0.4213146 0.9015626,…</span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span> CALEDONIA  (((0.8035071 0.8621686, 0.8069441 0.8649961, 0.809428 0.867068, 0…</span>
<span class='c'>#&gt; <span style='color: #555555;'>11</span> ORANGE     (((0.5706808 0.6369557, 0.5664359 0.6381655, 0.5625502 0.6392656,…</span>
<span class='c'>#&gt; <span style='color: #555555;'>12</span> WASHINGTON (((0.6158429 0.741074, 0.6157443 0.7411901, 0.6156621 0.741298, 0…</span>
<span class='c'>#&gt; <span style='color: #555555;'>13</span> RUTLAND    (((0.2967002 0.4833058, 0.2922765 0.484459, 0.2886918 0.4852998, …</span>
<span class='c'>#&gt; <span style='color: #555555;'>14</span> ADDISON    (((0.2342294 0.6848386, 0.2235227 0.686667, 0.2190376 0.687431, 0…</span>
<span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_set_z.html'>wk_set_z</a></span><span class='o'>(</span><span class='nv'>vt</span>, <span class='m'>0</span><span class='o'>)</span>
<span class='c'>#&gt; Simple feature collection with 14 features and 1 field</span>
<span class='c'>#&gt; Geometry type: MULTIPOLYGON</span>
<span class='c'>#&gt; Dimension:     XYZ</span>
<span class='c'>#&gt; Bounding box:  xmin: -73.4379 ymin: 42.72697 xmax: -71.46539 ymax: 45.01667</span>
<span class='c'>#&gt; z_range:       zmin: 0 zmax: 0</span>
<span class='c'>#&gt; Geodetic CRS:  WGS 84</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 14 x 2</span></span>
<span class='c'>#&gt;    CNTYNAME                                                             geometry</span>
<span class='c'>#&gt;  <span style='color: #555555;'>*</span> <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>                                                      <span style='color: #555555; font-style: italic;'>&lt;MULTIPOLYGON [°]&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span> ORLEANS    Z (((-71.92088 45.00785 0, -71.92933 45.00812 0, -71.94575 45.008…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span> GRAND ISLE Z (((-73.23344 44.66446 0, -73.23341 44.66632 0, -73.23355 44.668…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span> CHITTENDEN Z (((-73.10283 44.67616 0, -73.16068 44.69752 0, -73.16189 44.697…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span> WINDSOR    Z (((-72.77108 43.93907 0, -72.78996 43.94532 0, -72.78522 43.952…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span> WINDHAM    Z (((-72.70141 43.22634 0, -72.73021 43.2333 0, -72.75071 43.2382…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span> BENNINGTON Z (((-73.0961 43.30715 0, -73.1146 43.30827 0, -73.12266 43.30869…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span> FRANKLIN   Z (((-72.99655 45.0148 0, -73.00945 45.01503 0, -73.01624 45.0151…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span> ESSEX      Z (((-71.46539 45.01323 0, -71.4654 45.01338 0, -71.46541 45.0135…</span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span> LAMOILLE   Z (((-72.60514 44.79044 0, -72.60572 44.79073 0, -72.60685 44.791…</span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span> CALEDONIA  Z (((-71.85297 44.70108 0, -71.84619 44.70755 0, -71.84129 44.712…</span>
<span class='c'>#&gt; <span style='color: #555555;'>11</span> ORANGE     Z (((-72.31223 44.18541 0, -72.3206 44.18818 0, -72.32826 44.1907…</span>
<span class='c'>#&gt; <span style='color: #555555;'>12</span> WASHINGTON Z (((-72.22314 44.42381 0, -72.22334 44.42408 0, -72.2235 44.4243…</span>
<span class='c'>#&gt; <span style='color: #555555;'>13</span> RUTLAND    Z (((-72.85266 43.8336 0, -72.86138 43.83624 0, -72.86845 43.8381…</span>
<span class='c'>#&gt; <span style='color: #555555;'>14</span> ADDISON    Z (((-72.97588 44.29505 0, -72.997 44.29923 0, -73.00585 44.30098…</span></code></pre>

</div>

The point of this all, though, is that extension packages can make their own transforms. There's no C++ wrapper for this yet but the C is relatively minimal.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'>#include "cpp11.hpp"
using namespace cpp11;
#include "wk-v1.h"
#include "wk-v1-impl.c"

typedef struct {
  double dx;
  double dy;
} bump_trans_t;

int bump_trans_trans(R_xlen_t feature_id, const double* xyzm_in, double* xyzm_out, void* trans_data) {
  bump_trans_t* data = (bump_trans_t*) trans_data;
  xyzm_out[0] = xyzm_in[0] + data->dx;
  xyzm_out[1] = xyzm_in[1] + data->dy;
  return WK_CONTINUE;
}

void bump_trans_finalizer(void* trans_data) {
  delete (bump_trans_t*) trans_data;
}

[[cpp11::linking_to(wk)]]
[[cpp11::register]]
sexp bump_trans_new(double dx, double dy) {
  wk_trans_t* trans = wk_trans_create();
  trans->trans = &bump_trans_trans;
  trans->finalizer = &bump_trans_finalizer;
  trans->trans_data = new bump_trans_t {dx, dy};
  return wk_trans_create_xptr(trans, R_NilValue, R_NilValue);
}</code></pre>

</div>

You do need a tiny bit of R infrastructure to make this work smoothly:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>bump_trans</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>dx</span> <span class='o'>=</span> <span class='m'>0</span>, <span class='nv'>dy</span> <span class='o'>=</span> <span class='m'>0</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_trans_inverse.html'>new_wk_trans</a></span><span class='o'>(</span><span class='nf'>bump_trans_new</span><span class='o'>(</span><span class='nv'>dx</span>, <span class='nv'>dy</span><span class='o'>)</span>, <span class='s'>"bump_trans"</span><span class='o'>)</span>
<span class='o'>&#125;</span></code></pre>

</div>

Then your transform is accessible for anything that needs it! Most algorithms will probably also need an implementation of [`wk_trans_inverse()`](https://paleolimbot.github.io/wk/reference/wk_trans_inverse.html) to return the inverse operation.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_transform.html'>wk_transform</a></span><span class='o'>(</span><span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wkt.html'>wkt</a></span><span class='o'>(</span><span class='s'>"POINT (0 0)"</span><span class='o'>)</span>, <span class='nf'>bump_trans</span><span class='o'>(</span><span class='m'>12</span>, <span class='m'>13</span><span class='o'>)</span><span class='o'>)</span>
<span class='c'>#&gt; &lt;wk_wkt[1]&gt;</span>
<span class='c'>#&gt; [1] POINT (12 13)</span></code></pre>

</div>

### Plotting

As a side effect of some of this, plotting now "just works" without the wkutils package for the built-in vector types. It isn't particularly fast or glamourous, but it's good enough for a basic "get this geometry on my screen". Previously this was done using a confusing circular dependency on wkutils. It's used for [`plot()`](https://r-spatial.github.io/sf/reference/plot.html) for [`wkb()`](https://paleolimbot.github.io/wk/reference/wkb.html) and [`wkt()`](https://paleolimbot.github.io/wk/reference/wkt.html), but also works for arbitrary data types with a [`wk_handle()`](https://paleolimbot.github.io/wk/reference/wk_handle.html) method via [`wk_plot()`](https://paleolimbot.github.io/wk/reference/wk_plot.html).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_plot.html'>wk_plot</a></span><span class='o'>(</span><span class='nv'>vt</span><span class='o'>)</span>
<span class='nf'><a href='https://paleolimbot.github.io/wk/reference/wk_plot.html'>wk_plot</a></span><span class='o'>(</span><span class='nv'>vt_vertices</span>, add <span class='o'>=</span> <span class='kc'>T</span><span class='o'>)</span>
</code></pre>
<img src="figs/unnamed-chunk-14-1.png" width="700px" style="display: block; margin: auto;" />

</div>

### What's next?

So far wk development has focused on getting all the nuts and bolts in place so that extensions can do really awesome stuff with few dependencies. Now is that time! I'm hoping to get transforms working for PROJ so that s2 can do a better job creating valid spherical geometry from projected coordinates. Finally, I'm hoping to get some file readers working so that the lazy nature of the handler/filter system can really shine.

