---
title: "wk version 0.4.0!"
subtitle: ""
summary: ""
authors: []
tags: []
categories: []
date: 2021-03-02T20:37:02-04:00
lastmod: 2021-03-02T20:37:02-04:00
featured: false
draft: false
image:
  caption: ""
  focal_point: ""
  preview_only: false
projects: []
output: hugodown::md_document
rmd_hash: 0605242b1ed8702b

---

<div class="highlight">

</div>

About the time the COVID-19 pandemic began, I started getting interested in some low-level geometry programming in R. Around that time the [vctrs](https://vctrs.r-lib.org) package was starting to mature and [dplyr version 1.0.0](https://www.tidyverse.org/blog/2020/06/dplyr-1-0-0/) had just been released. In particular, vctrs provided a template for how a minimal but carefully-designed nuts-and-bolts framework can inspire an extensible ecosystem of packages enabling dplyr to continue doing all the useful stuff that users depend on. I was also struck by the fact that packages that implement a vctrs class (1) don't have to depend on vctrs and (2) work with dplyr *without either dplyr nor the package knowing anything about eachother*.

The [sf package](https://r-spatial.github.io/sf) is truly awesome. I think of sf as the dplyr of spatial: it does all the *useful* stuff. But if sf is the dplyr, what would a vctrs of geometry in R look like? What are the nuts and bolts of geometry in R?

I've [written](https://github.com/paleolimbot/geovctrs) and [rewritten](https://github.com/paleolimbot/wkutils) and [rewritten](https://fishandwhistle.net/post/2020/wk-package-preview/) a few versions of this over the last year: wk 0.4.0 is the convergence of the features I included in previous iterations and the lightweight-ness that I was hoping for. It all starts with:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/base/library.html'>library</a></span>(<span class='k'><a href='https://paleolimbot.github.io/wk'>wk</a></span>)</code></pre>

</div>

Vector classes
--------------

One concept that shows up on repeat in geometry/spatial packages is the concept of a "point". The vctrs package made this possible with [record-style vectors](https://vctrs.r-lib.org/articles/s3-vector.html#record-style-objects) that store data under the hood in something like a data frame. This is efficient in R because it involves few memory allocations (one per dimension) and few garbage collections (because there is only one object per dimension). Also, most points start out as vectors of x and y coordinates anyway, so including them in a record-style vector means a copy can sometimes be avoided. For thousands of points the difference is negligible. For millions of points, it starts to add up. In wk, you can construct these as [`xy()`](https://rdrr.io/pkg/wk/man/xy.html), [`xyz()`](https://rdrr.io/pkg/wk/man/xy.html), [`xym()`](https://rdrr.io/pkg/wk/man/xy.html), or [`xyzm()`](https://rdrr.io/pkg/wk/man/xy.html) depending on your dimensions:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'>(<span class='k'>point</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/wk/man/xy.html'>xy</a></span>(<span class='m'>1</span><span class='o'>:</span><span class='m'>5</span>, <span class='m'>1</span><span class='o'>:</span><span class='m'>5</span>))
<span class='c'>#&gt; &lt;wk_xy[5]&gt;</span>
<span class='c'>#&gt; [1] (1 1) (2 2) (3 3) (4 4) (5 5)</span></code></pre>

</div>

2D rectangles also show up on repeat in geometry/spatial packages as [sf's bounding box](https://r-spatial.github.io/sf/reference/st_bbox.html), raster's Extent, sp's bbox, terra's SpatExtent, base R's `xlim` and `ylim`, and I'm sure it's been implemented many other ways. In wk you can construct these using [`rct()`](https://rdrr.io/pkg/wk/man/rct.html):

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'>(<span class='k'>rectangle</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/wk/man/rct.html'>rct</a></span>(<span class='m'>0</span>, <span class='m'>0</span>, <span class='m'>10</span>, <span class='m'>5</span>))
<span class='c'>#&gt; &lt;wk_rct[1]&gt;</span>
<span class='c'>#&gt; [1] [0 0 10 5]</span></code></pre>

</div>

Circles are less common but they can be difficult to represent. Often they are approximated as a polygon with some number of segments around the outside, but this looses some precision depending on how many points the author thought would be a reasonable approximation. In wk you can create these using [`crc()`](https://rdrr.io/pkg/wk/man/crc.html):

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'>(<span class='k'>circle</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/wk/man/crc.html'>crc</a></span>(<span class='m'>0</span>, <span class='m'>0</span>, <span class='m'>10</span>))
<span class='c'>#&gt; &lt;wk_crc[1]&gt;</span>
<span class='c'>#&gt; [1] [0 0, r = 10]</span></code></pre>

</div>

Geometric primitives are all well and good, but the package would be useless without a way to represent lines, polygons, and collections thereof. For these, the [`wkb()`](https://rdrr.io/pkg/wk/man/wkb.html) and [`wkt()`](https://rdrr.io/pkg/wk/man/wkt.html) classes are provided: they mark a [`list()`](https://rdrr.io/r/base/list.html) of [`raw()`](https://rdrr.io/r/base/raw.html) (well-known binary) or character vector (well-known text) as containing geometry so that they can be printed, plotted, and combined accordingly. WKB and WKT also show up on repeat: most software libraries used in geometry processing have a way to export or import WKT or WKB.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'>(<span class='k'>text</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wkt.html'>wkt</a></span>(<span class='s'>"POINT (30 20)"</span>))
<span class='c'>#&gt; &lt;wk_wkt[1]&gt;</span>
<span class='c'>#&gt; [1] POINT (30 20)</span>
(<span class='k'>binary</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wkb.html'>as_wkb</a></span>(<span class='s'>"POINT (30 20)"</span>))
<span class='c'>#&gt; &lt;wk_wkb[1]&gt;</span>
<span class='c'>#&gt; [1] &lt;POINT (30 20)&gt;</span></code></pre>

</div>

Vector classes matter because they contain just enough information to relate them to other geometry vectors. This means that if you have some function that returns a geometry, you should be able to return the simplest possible thing and rely on the casting/concatenation rules to do the right thing if the user needs to combine these with something returned by another function. Using the objects we created above:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>vctrs</span>::<span class='nf'><a href='https://vctrs.r-lib.org/reference/vec_c.html'>vec_c</a></span>(<span class='k'>text</span>, <span class='k'>binary</span>)
<span class='c'>#&gt; &lt;wk_wkt[2]&gt;</span>
<span class='c'>#&gt; [1] POINT (30 20) POINT (30 20)</span>
<span class='k'>vctrs</span>::<span class='nf'><a href='https://vctrs.r-lib.org/reference/vec_c.html'>vec_c</a></span>(<span class='k'>rectangle</span>, <span class='k'>binary</span>)
<span class='c'>#&gt; &lt;wk_wkb[2]&gt;</span>
<span class='c'>#&gt; [1] &lt;POLYGON ((0 0, 10 0, 10 5...&gt; &lt;POINT (30 20)&gt;</span>
<span class='k'>vctrs</span>::<span class='nf'><a href='https://vctrs.r-lib.org/reference/vec_c.html'>vec_c</a></span>(<span class='k'>circle</span>, <span class='k'>binary</span>)
<span class='c'>#&gt; &lt;wk_wkb[2]&gt;</span>
<span class='c'>#&gt; [1] &lt;POLYGON ((10 0, 9.98027 0.627905, 9.92115 1.25333...&gt;</span>
<span class='c'>#&gt; [2] &lt;POINT (30 20)&gt;</span>
<span class='k'>vctrs</span>::<span class='nf'><a href='https://vctrs.r-lib.org/reference/vec_c.html'>vec_c</a></span>(<span class='k'>circle</span>, <span class='k'>point</span>)
<span class='c'>#&gt; &lt;wk_wkb[6]&gt;</span>
<span class='c'>#&gt; [1] &lt;POLYGON ((10 0, 9.98027 0.627905, 9.92115 1.25333...&gt;</span>
<span class='c'>#&gt; [2] &lt;POINT (1 1)&gt;                                         </span>
<span class='c'>#&gt; [3] &lt;POINT (2 2)&gt;                                         </span>
<span class='c'>#&gt; [4] &lt;POINT (3 3)&gt;                                         </span>
<span class='c'>#&gt; [5] &lt;POINT (4 4)&gt;                                         </span>
<span class='c'>#&gt; [6] &lt;POINT (5 5)&gt;</span></code></pre>

</div>

Missing from these examples are the segment and the triangle, which should probably exist in the wk package or elsewhere. If it turns out wk actually sees some use, they will likely be added to a future version.

sf support
----------

The sf package has classes for many of these concepts. In particular, [`sf::st_sfc()`](https://rdrr.io/pkg/sf/man/sfc.html) is a vector (and vctr) of geometries just like [`wkb()`](https://rdrr.io/pkg/wk/man/wkb.html) and [`wkt()`](https://rdrr.io/pkg/wk/man/wkt.html). At the time of this writing, casting and concatenation don't work with vectors from wk (but will in the future!). You can always use `as_*()` and [`sf::st_as_sfc()`](https://rdrr.io/pkg/sf/man/st_as_sfc.html) to work around this:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'>(<span class='k'>circle_sf</span> <span class='o'>&lt;-</span> <span class='k'>sf</span>::<span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_as_sfc.html'>st_as_sfc</a></span>(<span class='k'>circle</span>))
<span class='c'>#&gt; Geometry set for 1 feature </span>
<span class='c'>#&gt; geometry type:  POLYGON</span>
<span class='c'>#&gt; dimension:      XY</span>
<span class='c'>#&gt; bbox:           xmin: -10 ymin: -10 xmax: 10 ymax: 10</span>
<span class='c'>#&gt; CRS:            NA</span>
<span class='c'>#&gt; POLYGON ((10 0, 9.980267 0.6279052, 9.921147 1....</span></code></pre>

</div>

Low-level extensibility
-----------------------

The wk package manages coercion among its many vector types using a \~100-line header that defines a "handler". This handler responds to bits of geometric information as they are encountered by the "reader". Thus, the wk package contains readers and handlers for all of its vector classes and links them together to perform each set of conversions. This architecture was a huge step forward in this release: [before](https://fishandwhistle.net/post/2020/wk-package-preview/), these readers and handlers were "header-only", which meant a lot of duplicated compiling and the need for "handlers" to decide in advance which vector classes they were going to support. In the new release these concerns are fully separated: readers read, handlers handle, neither needs to know that the other exists. For those keen, there is a [new vignette](https://paleolimbot.github.io/wk/dev/articles/articles/programming.html) describing the philosophy of readers, handlers, filters, and how to write them in C and C++.

It should be noted that the zero-alloc reader/handler thing isn't a new concept - this type of framework has been [written in Rust](https://github.com/georust/geozero/) and includes many more readers and handlers. In comparison to the Rust version, wk's framework is focused on simplicity and commits to R as the language in which the objects should be interacted with. With the [extendr crate](https://github.com/extendr/extendr) it might be possible to link these together! Very cool, but a battle for another day.

High-level extensibility
------------------------

The C/C++-level extensibility in the latest version is not useful without an R-level interface allowing the user to mix and match readers, filters, and handlers. The [`wk_handle()`](https://rdrr.io/pkg/wk/man/wk_handle.html) generic takes care of selecting the proper reader for a given object; various `*_handler()` constructors make fresh handler objects that generate a result. For example, the [`wk_bbox_handler()`](https://rdrr.io/pkg/wk/man/wk_bbox.html) can be run with all of the geometry vector types we defined above:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_handle.html'>wk_handle</a></span>(<span class='k'>point</span>, <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_bbox.html'>wk_bbox_handler</a></span>())
<span class='c'>#&gt; &lt;wk_rct[1]&gt;</span>
<span class='c'>#&gt; [1] [1 1 5 5]</span>
<span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_handle.html'>wk_handle</a></span>(<span class='k'>binary</span>, <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_bbox.html'>wk_bbox_handler</a></span>())
<span class='c'>#&gt; &lt;wk_rct[1]&gt;</span>
<span class='c'>#&gt; [1] [30 20 30 20]</span>
<span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_handle.html'>wk_handle</a></span>(<span class='k'>circle_sf</span>, <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_bbox.html'>wk_bbox_handler</a></span>())
<span class='c'>#&gt; &lt;wk_rct[1]&gt;</span>
<span class='c'>#&gt; [1] [-10 -10 10 10]</span></code></pre>

</div>

The [`wk_handle()`](https://rdrr.io/pkg/wk/man/wk_handle.html) method is probably not useful for users but does allow developers to create functions that support a wide variety of inputs. For example, it is more likely that a user might use [`wk_bbox()`](https://rdrr.io/pkg/wk/man/wk_bbox.html) (which was written using this pattern) to achieve the above result:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_bbox.html'>wk_bbox</a></span>(<span class='k'>point</span>)
<span class='c'>#&gt; &lt;wk_rct[1]&gt;</span>
<span class='c'>#&gt; [1] [1 1 5 5]</span>
<span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_bbox.html'>wk_bbox</a></span>(<span class='k'>circle_sf</span>)
<span class='c'>#&gt; &lt;wk_rct[1] with CRS=NA&gt;</span>
<span class='c'>#&gt; [1] [-10 -10 10 10]</span></code></pre>

</div>

In addition to vectors of geometries, there is a [`wk_handle()`](https://rdrr.io/pkg/wk/man/wk_handle.html) method for data frames and tibbles. This means that, like sf objects are data frames with sfc vectors, any data.frame that contains exactly one handleable column can be used interchangeably with its geometry column:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_bbox.html'>wk_bbox</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/data.frame.html'>data.frame</a></span>(xy = <span class='k'>point</span>))
<span class='c'>#&gt; &lt;wk_rct[1]&gt;</span>
<span class='c'>#&gt; [1] [1 1 5 5]</span></code></pre>

</div>

To facilitate transformations, [`wk_restore()`](https://rdrr.io/pkg/wk/man/wk_identity.html) is provided to reconcile the transformed geometry with the original object. The only built-in transformation is the [`wk_identity()`](https://rdrr.io/pkg/wk/man/wk_identity.html), which is mostly provided to test this pattern:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>xy_tbl</span> <span class='o'>&lt;-</span> <span class='k'>tibble</span>::<span class='nf'><a href='https://tibble.tidyverse.org/reference/tibble.html'>tibble</a></span>(xy = <span class='k'>point</span>)
<span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_identity.html'>wk_restore</a></span>(<span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_handle.html'>wk_handle</a></span>(<span class='k'>xy_tbl</span>, <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_writer.html'>xy_writer</a></span>()), <span class='k'>xy_tbl</span>)
<span class='c'>#&gt; # A tibble: 5 x 1</span>
<span class='c'>#&gt;   xy     </span>
<span class='c'>#&gt;   &lt;wk_xy&gt;</span>
<span class='c'>#&gt; 1 (1 1)  </span>
<span class='c'>#&gt; 2 (2 2)  </span>
<span class='c'>#&gt; 3 (3 3)  </span>
<span class='c'>#&gt; 4 (4 4)  </span>
<span class='c'>#&gt; 5 (5 5)</span></code></pre>

</div>

Coordiniate Reference System propagation
----------------------------------------

Technically the ability to attach, propagate, and check consistency of CRS objects could be delegated to a future package that makes "spatial-aware" versions of the classes in wk. However, coordinate reference systems aren't just a spatial phenomenon: graphics devices in R define several of them as well (user, device, normalized). Also, without a framework to deal with coordinate reference systems, developers would have to import *another* package. The latest wk release attempts to deal with CRS objects without knowing anything about them, delegating detection of equality via the [`wk_crs_equal_generic()`](https://rdrr.io/pkg/wk/man/wk_crs_equal.html) S3 generic. This allows code like the following to work:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>vctrs</span>::<span class='nf'><a href='https://vctrs.r-lib.org/reference/vec_c.html'>vec_c</a></span>(
  <span class='nf'><a href='https://rdrr.io/pkg/wk/man/xy.html'>xy</a></span>(<span class='m'>1</span>, <span class='m'>0</span>, crs = <span class='m'>4326</span>), 
  <span class='nf'><a href='https://rdrr.io/pkg/wk/man/rct.html'>rct</a></span>(<span class='m'>0</span>, <span class='m'>2</span>, <span class='m'>3</span>, <span class='m'>4</span>, crs = <span class='k'>sf</span>::<span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_crs.html'>st_crs</a></span>(<span class='m'>4326</span>))
)
<span class='c'>#&gt; &lt;wk_wkb[2] with CRS=4326&gt;</span>
<span class='c'>#&gt; [1] &lt;POINT (1 0)&gt;                &lt;POLYGON ((0 2, 3 2, 3 4...&gt;</span></code></pre>

</div>

...and code like this to fail:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>vctrs</span>::<span class='nf'><a href='https://vctrs.r-lib.org/reference/vec_c.html'>vec_c</a></span>(
  <span class='nf'><a href='https://rdrr.io/pkg/wk/man/xy.html'>xy</a></span>(<span class='m'>1</span>, <span class='m'>0</span>, crs = <span class='m'>4327</span>), 
  <span class='nf'><a href='https://rdrr.io/pkg/wk/man/rct.html'>rct</a></span>(<span class='m'>0</span>, <span class='m'>2</span>, <span class='m'>3</span>, <span class='m'>4</span>, crs = <span class='k'>sf</span>::<span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_crs.html'>st_crs</a></span>(<span class='m'>4326</span>))
)
<span class='c'>#&gt; Error: CRS objects '4327' and 'WGS 84' are not equal.</span></code></pre>

</div>

A special value, [`wk_crs_inherit()`](https://rdrr.io/pkg/wk/man/wk_crs_inherit.html), can be used to inherit the coordinate system of whatever it is combined with:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>vctrs</span>::<span class='nf'><a href='https://vctrs.r-lib.org/reference/vec_c.html'>vec_c</a></span>(<span class='nf'><a href='https://rdrr.io/pkg/wk/man/xy.html'>xy</a></span>(<span class='m'>1</span>, <span class='m'>0</span>, crs = <span class='m'>4327</span>), <span class='nf'><a href='https://rdrr.io/pkg/wk/man/xy.html'>xy</a></span>(<span class='m'>NA</span>, <span class='m'>NA</span>, crs = <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_crs_inherit.html'>wk_crs_inherit</a></span>()))
<span class='c'>#&gt; &lt;wk_xy[2] with CRS=4327&gt;</span>
<span class='c'>#&gt; [1] ( 1  0) (NA NA)</span></code></pre>

</div>

CRS objects can be anything and are not validated until they need to be compared with another CRS object during concatenation or a binary operation. This framework is experimental but was designed to facilitate the fewest number of coercion between CRS objects as this can lead to loss of information.

A few useful handlers
---------------------

In order to test that the handlers and readers work as intended, a few useful handlers live in the wk package and were added as R-level functions in the latest release. The [`wk_meta()`](https://rdrr.io/pkg/wk/man/wk_meta.html) function gives vector-level and feature-level meta information for any object with a [`wk_handle()`](https://rdrr.io/pkg/wk/man/wk_handle.html) method:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_meta.html'>wk_vector_meta</a></span>(<span class='k'>circle_sf</span>)
<span class='c'>#&gt;   geometry_type size has_z has_m</span>
<span class='c'>#&gt; 1             3    1 FALSE FALSE</span>
<span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_meta.html'>wk_meta</a></span>(<span class='k'>circle_sf</span>)
<span class='c'>#&gt;   geometry_type size has_z has_m srid precision</span>
<span class='c'>#&gt; 1             3    1 FALSE FALSE   NA         0</span></code></pre>

</div>

The [`wk_format()`](https://rdrr.io/pkg/wk/man/wk_format.html) function gives a truncated version of the WKT (that is very fast as it never involves parsing the entire geometry!)

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_format.html'>wk_format</a></span>(<span class='k'>circle_sf</span>)
<span class='c'>#&gt; [1] "POLYGON ((10 0, 9.980267 0.6279052, 9.921147 1.253332, 9.822873 1.873813, 9.685832 2.486899, 9.510565 3.09017..."</span></code></pre>

</div>

Finally, the [`wk_bbox()`](https://rdrr.io/pkg/wk/man/wk_bbox.html) function gives the 2D cartesian bounding box (min/max of all coordinates):

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_bbox.html'>wk_bbox</a></span>(<span class='k'>circle_sf</span>)
<span class='c'>#&gt; &lt;wk_rct[1] with CRS=NA&gt;</span>
<span class='c'>#&gt; [1] [-10 -10 10 10]</span></code></pre>

</div>

A motivating example
--------------------

Let's say you had a big shapefile of points and wanted to read in the values as a matrix to do some processing. My example here is about 11 million points of XYZ representing the [Nova Scotia Digital Terrain Model](https://nsgi.novascotia.ca/gdd/). The current fastest way to do that (probably) is using [mdsumner](https://github.com/mdsumner/)'s [vapour](https://cran.r-project.org/package=vapour) package (which is a lightweight interface to GDAL), read into sf format without assigning class attributes, then extract the coordinates. The whole process involves some off-label usage of sf to skip some unnecessary slow bits.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>big_shp_file</span> <span class='o'>&lt;-</span> <span class='s'>"~/Desktop/BASE_DTM_Points_SHP_UT83v3_CGVD28/LF_DTM_POINT_10K.shp"</span>

<span class='k'>bench</span>::<span class='nf'><a href='https://rdrr.io/pkg/bench/man/mark.html'>mark</a></span>(expr = {
  <span class='k'>big_wkb</span> <span class='o'>&lt;-</span> <span class='k'>vapour</span>::<span class='nf'><a href='https://rdrr.io/pkg/vapour/man/vapour_read_geometry.html'>vapour_read_geometry</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/path.expand.html'>path.expand</a></span>(<span class='k'>big_shp_file</span>))
  <span class='k'>big_sf_bare</span> <span class='o'>&lt;-</span> <span class='k'>sf</span>:::<span class='nf'>CPL_read_wkb</span>(<span class='k'>big_wkb</span>)
  <span class='k'>big_matrix</span> <span class='o'>&lt;-</span> <span class='k'>sf</span>::<span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_coordinates.html'>st_coordinates</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/structure.html'>structure</a></span>(<span class='k'>big_sf_bare</span>, class = <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='s'>"sfc_POINT"</span>, <span class='s'>"sfc"</span>)))
})
<span class='c'>#&gt; Warning: Some expressions had a GC in every iteration; so filtering is disabled.</span>
<span class='c'>#&gt; # A tibble: 1 x 6</span>
<span class='c'>#&gt;   expression      min   median `itr/sec` mem_alloc `gc/sec`</span>
<span class='c'>#&gt;   &lt;bch:expr&gt; &lt;bch:tm&gt; &lt;bch:tm&gt;     &lt;dbl&gt; &lt;bch:byt&gt;    &lt;dbl&gt;</span>
<span class='c'>#&gt; 1 expr          48.9s    48.9s    0.0205     1.1GB    0.102</span>

<span class='nf'><a href='https://rdrr.io/r/utils/head.html'>head</a></span>(<span class='k'>big_matrix</span>)
<span class='c'>#&gt;          X       Y     Z</span>
<span class='c'>#&gt; 1 518610.8 4987722 110.9</span>
<span class='c'>#&gt; 2 518611.5 4987685 117.2</span>
<span class='c'>#&gt; 3 518674.0 4987710 107.0</span>
<span class='c'>#&gt; 4 518674.2 4987646 103.7</span>
<span class='c'>#&gt; 5 518424.9 4987720 108.8</span>
<span class='c'>#&gt; 6 518425.6 4987682 113.7</span></code></pre>

</div>

In the wk framework, the steps are to (1) pick your data source, then (2) pick your handler. The package includes a data structure that closely matches a matrix (the [`xyz()`](https://rdrr.io/pkg/wk/man/xy.html) vector class) and handler to write it (the [`xy_writer()`](https://rdrr.io/pkg/wk/man/wk_writer.html)). To test my theory I wrote a [proof-of-concept shapefile reader](https://github.com/paleolimbot/shp) and found that this can be done about 10 times faster.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/base/library.html'>library</a></span>(<span class='k'><a href='https://github.com/paleolimbot/shp'>shp</a></span>)

<span class='k'>bench</span>::<span class='nf'><a href='https://rdrr.io/pkg/bench/man/mark.html'>mark</a></span>(expr = {
  <span class='k'>big_xy</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_handle.html'>wk_handle</a></span>(
    <span class='nf'><a href='https://rdrr.io/pkg/shp/man/shp_geometry.html'>shp_geometry</a></span>(<span class='k'>big_shp_file</span>),
    <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_writer.html'>xy_writer</a></span>()
  )
  
  <span class='k'>big_matrix2</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/matrix.html'>as.matrix</a></span>(<span class='k'>big_xy</span>)
})
<span class='c'>#&gt; # A tibble: 1 x 6</span>
<span class='c'>#&gt;   expression      min   median `itr/sec` mem_alloc `gc/sec`</span>
<span class='c'>#&gt;   &lt;bch:expr&gt; &lt;bch:tm&gt; &lt;bch:tm&gt;     &lt;dbl&gt; &lt;bch:byt&gt;    &lt;dbl&gt;</span>
<span class='c'>#&gt; 1 expr           1.8s     1.8s     0.555     917MB        0</span>

<span class='nf'><a href='https://rdrr.io/r/utils/head.html'>head</a></span>(<span class='k'>big_matrix2</span>)
<span class='c'>#&gt;             x       y     z</span>
<span class='c'>#&gt; [1,] 518610.8 4987722 110.9</span>
<span class='c'>#&gt; [2,] 518611.5 4987685 117.2</span>
<span class='c'>#&gt; [3,] 518674.0 4987710 107.0</span>
<span class='c'>#&gt; [4,] 518674.2 4987646 103.7</span>
<span class='c'>#&gt; [5,] 518424.9 4987720 108.8</span>
<span class='c'>#&gt; [6,] 518425.6 4987682 113.7</span></code></pre>

</div>

The exciting bit for me is the flexibility: you can just as easily read to WKB...

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>big_wkb</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_handle.html'>wk_handle</a></span>(
  <span class='nf'><a href='https://rdrr.io/pkg/shp/man/shp_geometry.html'>shp_geometry</a></span>(<span class='k'>big_shp_file</span>),
  <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_writer.html'>wkb_writer</a></span>()
)</code></pre>

</div>

...or sf...

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>big_sf</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_handle.html'>wk_handle</a></span>(
  <span class='nf'><a href='https://rdrr.io/pkg/shp/man/shp_geometry.html'>shp_geometry</a></span>(<span class='k'>big_shp_file</span>),
  <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_writer.html'>sfc_writer</a></span>()
)</code></pre>

</div>

...without changing any compiled code.

Handlers aren't limited to writing geometry vectors: some of the more compelling uses for them are calculations like a bounding box that require iterating through every coordinate but don't need to allocate memory for all of them at once. This is really fast, since allocation can become limiting once the size of the data gets big enough.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/base/system.time.html'>system.time</a></span>(
  <span class='k'>big_bbox</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_handle.html'>wk_handle</a></span>(
    <span class='nf'><a href='https://rdrr.io/pkg/shp/man/shp_geometry.html'>shp_geometry</a></span>(<span class='k'>big_shp_file</span>),
    <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_bbox.html'>wk_bbox_handler</a></span>()
  )
)
<span class='c'>#&gt;    user  system elapsed </span>
<span class='c'>#&gt;   0.295   0.195   0.507</span>

<span class='k'>big_bbox</span>
<span class='c'>#&gt; &lt;wk_rct[1]&gt;</span>
<span class='c'>#&gt; [1] [228907.9 4807442 765781.3 5234426]</span></code></pre>

</div>

Another compelling use-case is applying transformations to a really big data set. If you wanted to do a projection, affine transformation, or simplification (or all three!), you could write filters that do this one coordinate at a time and string them together. The only filter implemented in the wk package is the [`wk_identity_filter()`](https://rdrr.io/pkg/wk/man/wk_identity.html) but it's enough to demonstrate the idea:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/base/system.time.html'>system.time</a></span>({
  <span class='k'>big_filtered</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_handle.html'>wk_handle</a></span>(
    <span class='nf'><a href='https://rdrr.io/pkg/shp/man/shp_geometry.html'>shp_geometry</a></span>(<span class='k'>big_shp_file</span>),
    <span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_identity.html'>wk_identity_filter</a></span>(<span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_identity.html'>wk_identity_filter</a></span>(<span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_identity.html'>wk_identity_filter</a></span>(<span class='nf'><a href='https://rdrr.io/pkg/wk/man/wk_writer.html'>xy_writer</a></span>())))
  )
})
<span class='c'>#&gt;    user  system elapsed </span>
<span class='c'>#&gt;   0.689   0.563   1.708</span></code></pre>

</div>

In this example, the filters are operating one coordinate at a time, rather than functions applied on a sequence of copies. The syntax leaves something to be desired, but that's the (future) job of some package other than wk!

Acknowledgements
----------------

I have to thank the [\#rstats Twitter family](https://twitter.com/hashtag/rstats) for serving as my outlet as I developed various versions of this over the last year. In particular, conversations with [edzer](https://github.com/edzer/), [mdsumner](https://github.com/mdsumner/), and [dcooley](https://github.com/dcooley/) formed the basis for wk. There are few features of wk that some combination of [edzer](https://github.com/edzer/), [mdsumner](https://github.com/mdsumner/), and/or [dcooley](https://github.com/dcooley/) have not implemented better somewhere else.

