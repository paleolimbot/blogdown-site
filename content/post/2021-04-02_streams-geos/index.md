---
title: "Stream networks using R and GEOS"
subtitle: ""
summary: ""
authors: []
tags: []
categories: []
date: 2021-04-01T20:37:02-04:00
lastmod: 2021-04-01T20:37:02-04:00
featured: false
draft: false
image:
  caption: ""
  focal_point: ""
  preview_only: false
projects: []
output: hugodown::md_document
rmd_hash: 89101b394bc2b8dd

---

Almost exactly a year ago I wrote a [post on using R and sf to work with stream networks](/post/2020/stream-networks-using-r-and-sf/). The post was about low-level analysis with the [Nova Scotia stream network](https://nsgi.novascotia.ca/gdd/) to find upstream networks of various lakes so that I could approximate the catchments without a province-wide DEM analysis.

If you read the post, you'll realize that it's not just you, it's a tiny bit awkward to work with some of these low-level details. I wrote that post early pandemic and spent a good part of the next few months working on the [geos package](https://github.com/paleolimbot/geos/), which interacts with GEOS (which also powers much of sf) at a lower level and exposes some really nice functions for doing nuts-and-bolts geometry work. I'm in the process of preparing the [libgeos 3.9.1-1](https://github.com/paleolimbot/libgeos/issues/7) and [geos 0.1.0](https://github.com/paleolimbot/geos/issues/38) release, and thought I'd revisit the idea of stream network analysis to see if I can make the analysis a little less awkward.

I'll start with the same example data I used in the last post, loaded with the trusty [sf package](https://r-spatial.github.io/sf).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/base/library.html'>library</a></span>(<span class='k'><a href='https://r-spatial.github.io/sf'>sf</a></span>)
<span class='nf'><a href='https://rdrr.io/r/base/library.html'>library</a></span>(<span class='k'><a href='https://paleolimbot.github.io/geos'>geos</a></span>)

<span class='k'>lakes_sf</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_read.html'>read_sf</a></span>(<span class='s'>"lakes.shp"</span>)
<span class='k'>rivers_sf</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_read.html'>read_sf</a></span>(<span class='s'>"rivers.shp"</span>)</code></pre>

</div>

## A pure geos approach

Because I'm testing the geos package, I'm going to convert the objects to [`geos_geometry()`](https://rdrr.io/pkg/geos/man/as_geos_geometry.html) right away (all `geos_*()` functions call [`as_geos_geometry()`](https://rdrr.io/pkg/geos/man/as_geos_geometry.html) internally, too, if you ever want to save a step in a one-off calculation). If you inspect the rivers geometry you'll notice that the rivers geometry is a `MULTILINESTRING`. For what we're about to do we need to use the fact that the start point of one river segment is the end point of another, and so we need to break the linestrings out of their containers. In sf you'd do [`st_cast(, "LINESTRING")`](https://rdrr.io/pkg/sf/man/st_cast.html). In geos you can use [`geos_unnest()`](https://rdrr.io/pkg/geos/man/geos_unnest.html), which has nothing to do with the sf spec but provides some options for dealing with (potentially nested) collections.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>lakes</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/as_geos_geometry.html'>as_geos_geometry</a></span>(<span class='k'>lakes_sf</span>)
<span class='k'>rivers</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/as_geos_geometry.html'>as_geos_geometry</a></span>(<span class='k'>rivers_sf</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_unnest.html'>geos_unnest</a></span>(keep_multi = <span class='kc'>FALSE</span>)</code></pre>

</div>

The test lake I'll use is East Lake, near Dartmouth, Nova Scotia.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>east_lake</span> <span class='o'>&lt;-</span> <span class='k'>lakes</span>[<span class='m'>4</span>]

<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>lakes</span>, col = <span class='s'>"grey80"</span>, border = <span class='m'>NA</span>)
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>rivers</span>, lwd = <span class='m'>0.5</span>, add = <span class='k'>T</span>)
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>east_lake</span>, col = <span class='m'>NA</span>, border = <span class='s'>"red"</span>, add = <span class='k'>T</span>)
</code></pre>
<img src="figs/unnamed-chunk-3-1.png" width="700px" style="display: block; margin: auto;" />

</div>

The big difference between the sf approach I used in the previous post and the geos approach in this one is the use of [`geos_point_start()`](https://rdrr.io/pkg/geos/man/geos_centroid.html) and [`geos_point_end()`](https://rdrr.io/pkg/geos/man/geos_centroid.html) to extract the start and end points of each river segment. Along with [`geos_point_n()`](https://rdrr.io/pkg/geos/man/geos_centroid.html), [`geos_project()`](https://rdrr.io/pkg/geos/man/geos_project.html), and [`geos_interpolate()`](https://rdrr.io/pkg/geos/man/geos_project.html), there are some useful functions for dealing with lineal geometries. This stream network is defined such that the upstream segment can be found by looking for a segment where the end point is the start point of the one you're interested in. It seems tiny, but the [`geos_point_start()`](https://rdrr.io/pkg/geos/man/geos_centroid.html) and [`geos_point_end()`](https://rdrr.io/pkg/geos/man/geos_centroid.html) make the process much cleaner. We can cache these because we're going to refer to them frequently.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>river_start</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_centroid.html'>geos_point_start</a></span>(<span class='k'>rivers</span>)
<span class='k'>river_end</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_centroid.html'>geos_point_end</a></span>(<span class='k'>rivers</span>)

<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>rivers</span>[<span class='m'>1</span>])
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>river_start</span>[<span class='m'>1</span>], add = <span class='k'>T</span>, col = <span class='s'>"blue"</span>)
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>river_end</span>[<span class='m'>1</span>], add = <span class='k'>T</span>, col = <span class='s'>"red"</span>)
</code></pre>
<img src="figs/unnamed-chunk-4-1.png" width="700px" style="display: block; margin: auto;" />

</div>

Because we're going to look up end points repeatedly (maybe millions of times), we're going to build an [R-tree index](https://en.wikipedia.org/wiki/R-tree) on the end points of all the segments and use the `*_matrix()` predicates to search.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>river_end_index</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_strtree.html'>geos_strtree</a></span>(<span class='k'>river_end</span>)
<span class='k'>river_start_index</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_strtree.html'>geos_strtree</a></span>(<span class='k'>river_start</span>)</code></pre>

</div>

If you've spent time working with binary predicates like [`st_intersects()`](https://rdrr.io/pkg/sf/man/geos_binary_pred.html) in sf, you'll be familiar with the return type: a [`list()`](https://rdrr.io/r/base/list.html) where each item in the list refers to the query features and the indices in each item refer to position in index. For example, to find the positions of the river end points that intersect our sample lake, you could do the following:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_disjoint_matrix.html'>geos_intersects_matrix</a></span>(<span class='k'>east_lake</span>, <span class='k'>river_end_index</span>)
<span class='c'>#&gt; [[1]]</span>
<span class='c'>#&gt;  [1] 146  66  67  78  86  88  87  89  92  38  58  62</span></code></pre>

</div>

To get the actual end points you'd need to do `river_end[c(146, 66, ...)]`, but in our case we don't really care about the end points, we're using the positions to identify `river_start`, `rivers`, or `river_end` depending on what we need to do next.

Identifying inlets and outlets is also slightly easier knowing the start and end points of a segment: if a segment has its start point inside the lake, it's an outlet. Nova Scotia is a great case to test edge cases here because many lakes have more than one outlet and the river network is a little screwy as a result (many lakes in the interior of the province flow more than one direction depending on where the power company wants to send it...try encoding *that* in a shapefile). Also complicating things is that the river and lake files are slightly misaligned (about 0.5 m difference depending on where you are in the province). For East Lake, the simple start/end segment thing works (we'll revisit how to get around the 0.5 m difference thing in a bit).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>east_lake_inlet_which</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/sets.html'>setdiff</a></span>(
  <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_disjoint_matrix.html'>geos_touches_matrix</a></span>(<span class='k'>east_lake</span>, <span class='k'>river_end_index</span>)[[<span class='m'>1</span>]],
  <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_disjoint_matrix.html'>geos_contains_matrix</a></span>(<span class='k'>east_lake</span>, <span class='k'>river_start_index</span>)[[<span class='m'>1</span>]]
)

<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>east_lake</span>)
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>rivers</span>[<span class='k'>east_lake_inlet_which</span>], add = <span class='k'>T</span>)
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>river_end</span>[<span class='k'>east_lake_inlet_which</span>], add = <span class='k'>T</span>)
</code></pre>
<img src="figs/unnamed-chunk-7-1.png" width="700px" style="display: block; margin: auto;" />

</div>

A final detail is that we can cache the upstream segment lookup for every segment in the data set. This takes a barely noticeable amount of space and time even for the entire data set (250,000 segments). You can do this in sf ([`st_equals()`](https://rdrr.io/pkg/sf/man/geos_binary_pred.html)) and s2 (`s2_equals_matrix()`) as well; both use indexes to compute the result efficiently for large data sets.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>upstream_lookup</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_disjoint_matrix.html'>geos_equals_matrix</a></span>(<span class='k'>river_start</span>, <span class='k'>river_end_index</span>)</code></pre>

</div>

(Note: I'm using the pre-computed index here but you can pass any object with an [`as_geos_geometry()`](https://rdrr.io/pkg/geos/man/as_geos_geometry.html) method as the index if you don't need to save it. Computing the index doesn't take very long even for big data sets, so unless you're running code in a loop this is probably what you want to do).

Finally, we can define our recursive upstream segment finder. Getting the recursion right took a few tries, but the main idea is that the upstream segment from the current segment is the one whose end point is the current segment's start point. Here `seg_which` is a vector of positions and upstream direct is a [`list()`](https://rdrr.io/r/base/list.html) (hence the [`unlist()`](https://rdrr.io/r/base/unlist.html) and [`lapply()`](https://rdrr.io/r/base/lapply.html)).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>upstream_segments</span> <span class='o'>&lt;-</span> <span class='nf'>function</span>(<span class='k'>seg_which</span>, <span class='k'>lookup</span> = <span class='k'>upstream_lookup</span>, <span class='k'>recursive_limit</span> = <span class='m'>100</span>) {
  <span class='kr'>if</span> (<span class='k'>recursive_limit</span> <span class='o'>&lt;=</span> <span class='m'>0</span>) {
    <span class='nf'><a href='https://rdrr.io/r/base/message.html'>message</a></span>(<span class='s'>"Recursion limit reached"</span>)
    <span class='nf'><a href='https://rdrr.io/r/base/function.html'>return</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/numeric.html'>numeric</a></span>())
  }
  
  <span class='k'>upstream_direct</span> <span class='o'>&lt;-</span> <span class='k'>lookup</span>[<span class='k'>seg_which</span>]
  
  <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(
    <span class='nf'><a href='https://rdrr.io/r/base/unlist.html'>unlist</a></span>(<span class='k'>upstream_direct</span>), 
    <span class='nf'><a href='https://rdrr.io/r/base/unlist.html'>unlist</a></span>(
      <span class='nf'><a href='https://rdrr.io/r/base/lapply.html'>lapply</a></span>(
        <span class='k'>upstream_direct</span>,
        <span class='k'>upstream_segments</span>,
        lookup = <span class='k'>lookup</span>,
        recursive_limit = <span class='k'>recursive_limit</span> <span class='o'>-</span> <span class='m'>1</span>
      )
    )
  )
}</code></pre>

</div>

Let's look up the inlet network for East Lake!

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>east_lake_inlet_network_which</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(
  <span class='k'>east_lake_inlet_which</span>,
  <span class='nf'>upstream_segments</span>(<span class='k'>east_lake_inlet_which</span>)
)

<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>rivers</span>[<span class='k'>east_lake_inlet_network_which</span>])
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>east_lake</span>, add = <span class='k'>T</span>)
</code></pre>
<img src="figs/unnamed-chunk-10-1.png" width="700px" style="display: block; margin: auto;" />

</div>

Cool! With that under our belt, let's see if the approach scales to the whole network. Again, we'll use sf to read in our shapefiles.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>rivers_ns_sf</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_read.html'>read_sf</a></span>(<span class='s'>"~/Dropbox/delineatens/dem/streams.shp"</span>)
<span class='k'>lakes_ns_sf</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_read.html'>read_sf</a></span>(<span class='s'>"~/Dropbox/delineatens/dem/lakes.shp"</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_transform.html'>st_transform</a></span>(<span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_crs.html'>st_crs</a></span>(<span class='k'>rivers_ns_sf</span>))</code></pre>

</div>

Like above, we'll compute the start and end points and the [`geos_geometry()`](https://rdrr.io/pkg/geos/man/as_geos_geometry.html) version of the lakes and rivers. Also we'll compute the indexes because we're going to compute some predicate values in a loop. Of this, [`geos_unnest()`](https://rdrr.io/pkg/geos/man/geos_unnest.html) is the only noticeable slowdown (as we'll see below, using [`st_cast("LINESTRING")`](https://rdrr.io/pkg/sf/man/st_cast.html) is much faster).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>lakes_ns</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/as_geos_geometry.html'>as_geos_geometry</a></span>(<span class='k'>lakes_ns_sf</span>)
<span class='k'>rivers_ns</span> <span class='o'>&lt;-</span> <span class='k'>rivers_ns_sf</span> <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://rdrr.io/pkg/geos/man/as_geos_geometry.html'>as_geos_geometry</a></span>() <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_unnest.html'>geos_unnest</a></span>(keep_multi = <span class='kc'>FALSE</span>, keep_empty = <span class='kc'>TRUE</span>)

<span class='k'>river_start_ns</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_centroid.html'>geos_point_start</a></span>(<span class='k'>rivers_ns</span>)
<span class='k'>river_end_ns</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_centroid.html'>geos_point_end</a></span>(<span class='k'>rivers_ns</span>)

<span class='k'>rivers_index_ns</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_strtree.html'>geos_strtree</a></span>(<span class='k'>rivers_ns</span>)
<span class='k'>river_start_index_ns</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_strtree.html'>geos_strtree</a></span>(<span class='k'>river_start_ns</span>)
<span class='k'>river_end_index_ns</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_strtree.html'>geos_strtree</a></span>(<span class='k'>river_end_ns</span>)

<span class='k'>upstream_lookup_ns</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_disjoint_matrix.html'>geos_equals_matrix</a></span>(<span class='k'>river_start_ns</span>, <span class='k'>river_end_index_ns</span>)</code></pre>

</div>

I mentioned above that we need a slightly different approach to compute the inlets and outlets when the lakes and rivers layer aren't quite aligned (normally there is a segment start/end at the edge of the lake). The differernce in our case is about 0.5 m, which I suspect has to do with the NAD83/WGS84 projection difference with updated PROJ. In any case, the approach we used for East Lake doesn't scale to the whole data set. What we really need is [`st_is_within_distance()`](https://rdrr.io/pkg/sf/man/geos_binary_pred.html) or `s2_dwithin_matrix()` (which will probably be included in the upcoming or a future geos release). An important consideration is that buffering the lake is not an option: the biggest lake in the province takes 8 seconds to buffer (compared to 0.1 seconds to compute the entire upstream network!). My approach here is to find the places where the stream network intersects the boundary and then find the nearest segment end point to that. This fails where two streams enter a lake at the same point (which happens in this data set); I'll demo the combined sf-geos approach below that makes this more robust.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>lake</span> <span class='o'>&lt;-</span> <span class='k'>lakes_ns</span>[<span class='m'>399</span>]
<span class='k'>lake_boundary</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_centroid.html'>geos_boundary</a></span>(<span class='k'>lake</span>)
<span class='k'>lake_inlet_outlet_which</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_disjoint_matrix.html'>geos_intersects_matrix</a></span>(<span class='k'>lake_boundary</span>, <span class='k'>rivers_index_ns</span>)[[<span class='m'>1</span>]]
<span class='k'>lake_inlet_outlet_pt</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_intersection.html'>geos_intersection</a></span>(<span class='k'>rivers_ns</span>[<span class='k'>lake_inlet_outlet_which</span>], <span class='k'>lake_boundary</span>)
<span class='k'>lake_inlet_outlet_which</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_nearest.html'>geos_nearest</a></span>(<span class='k'>lake_inlet_outlet_pt</span>, <span class='k'>river_end_index_ns</span>)

<span class='k'>lake_inlet_which</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/sets.html'>setdiff</a></span>(
  <span class='k'>lake_inlet_outlet_which</span>,
  <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_disjoint_matrix.html'>geos_contains_matrix</a></span>(<span class='k'>lake</span>, <span class='k'>river_start_index_ns</span>)[[<span class='m'>1</span>]]
)

<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>lakes_ns</span>[<span class='m'>399</span>])
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>river_end_ns</span>[<span class='k'>lake_inlet_which</span>], add =  <span class='k'>T</span>)
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>rivers_ns</span>[<span class='k'>lake_inlet_outlet_which</span>], col = <span class='s'>"blue"</span>, add = <span class='k'>T</span>)
</code></pre>
<img src="figs/unnamed-chunk-13-1.png" width="700px" style="display: block; margin: auto;" />

</div>

We can functionify this so that we can [`lapply()`](https://rdrr.io/r/base/lapply.html) along the entire lakes data set using our `upstream_segments()` function with our much bigger upstream lookup table.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>lake_upstream_segments</span> <span class='o'>&lt;-</span> <span class='nf'>function</span>(<span class='k'>lake</span>) {
  <span class='k'>lake_boundary</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_centroid.html'>geos_boundary</a></span>(<span class='k'>lake</span>)
  <span class='k'>lake_inlet_outlet_which</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_disjoint_matrix.html'>geos_intersects_matrix</a></span>(<span class='k'>lake_boundary</span>, <span class='k'>rivers_index_ns</span>)[[<span class='m'>1</span>]]
  <span class='k'>lake_inlet_outlet_pt</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_intersection.html'>geos_intersection</a></span>(<span class='k'>rivers_ns</span>[<span class='k'>lake_inlet_outlet_which</span>], <span class='k'>lake_boundary</span>)
  <span class='k'>lake_inlet_outlet_which</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_nearest.html'>geos_nearest</a></span>(<span class='k'>lake_inlet_outlet_pt</span>, <span class='k'>river_end_index_ns</span>)
  
  <span class='k'>lake_inlet_which</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/sets.html'>setdiff</a></span>(
    <span class='k'>lake_inlet_outlet_which</span>,
    <span class='nf'><a href='https://rdrr.io/pkg/geos/man/geos_disjoint_matrix.html'>geos_contains_matrix</a></span>(<span class='k'>lake</span>, <span class='k'>river_start_index_ns</span>)[[<span class='m'>1</span>]]
  )
  
  <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(
    <span class='k'>lake_inlet_which</span>,
    <span class='nf'>upstream_segments</span>(
      <span class='k'>lake_inlet_which</span>,
      lookup = <span class='k'>upstream_lookup_ns</span>,
      recursive_limit = <span class='m'>5000</span>
    )
  )
}

<span class='k'>test_segments</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/unique.html'>unique</a></span>(<span class='nf'>lake_upstream_segments</span>(<span class='k'>lakes_ns</span>[<span class='m'>399</span>]))
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>rivers_ns</span>[<span class='k'>test_segments</span>])
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>lakes_ns</span>[<span class='m'>399</span>], col = <span class='m'>NA</span>, border = <span class='s'>"red"</span>, add = <span class='k'>T</span>)
</code></pre>
<img src="figs/unnamed-chunk-14-1.png" width="700px" style="display: block; margin: auto;" />

</div>

I picked this lake because I happen to know a bit about the drainage network. But does it work for a bigger, more complicated lake? (Shown: Lake Rossignol, the biggest lake in the province).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>test_segments</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/unique.html'>unique</a></span>(<span class='nf'>lake_upstream_segments</span>(<span class='k'>lakes_ns</span>[<span class='m'>226</span>]))
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>rivers_ns</span>[<span class='k'>test_segments</span>])
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>lakes_ns</span>[<span class='m'>226</span>], col = <span class='m'>NA</span>, border = <span class='s'>"red"</span>, add = <span class='k'>T</span>)
</code></pre>
<img src="figs/unnamed-chunk-15-1.png" width="700px" style="display: block; margin: auto;" />

</div>

In the earlier post I noted that the largest network in the province could be calculated in 10 seconds and that the whole province could be analyzed in under an hour. At the time I was pretty excited about this. The above code can compute the biggest network in the province in 0.1 seconds and can analyze my 650-lake data set in about 3 seconds:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/base/system.time.html'>system.time</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/lapply.html'>lapply</a></span>(<span class='k'>lakes_ns</span>, <span class='k'>lake_upstream_segments</span>))
<span class='c'>#&gt;    user  system elapsed </span>
<span class='c'>#&gt;   2.660   0.048   2.719</span></code></pre>

</div>

## A pure sf approach

The insane speed difference I just quoted has little to do with sf or geos and more to do with the fact that I didn't really know what I was doing when I wrote the last post. Knowing what I do now, let's see how fast I can make sf do the same thing. We've already read the data into sf form, but we need to break the stream segments out of their multi-geometry container. As I noted above, [`st_cast()`](https://rdrr.io/pkg/sf/man/st_cast.html) is usually much faster than [`geos_unnest()`](https://rdrr.io/pkg/geos/man/geos_unnest.html) (5 seconds vs. 20 seconds).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>rivers_ns_sf_line</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_cast.html'>st_cast</a></span>(<span class='k'>rivers_ns_sf</span>, <span class='s'>"LINESTRING"</span>)
<span class='c'>#&gt; Warning in st_cast.sf(rivers_ns_sf, "LINESTRING"): repeating attributes for all sub-geometries for which they may not be constant</span></code></pre>

</div>

The start/end point thing is a bit awkward. If I weren't trying to avoid the geos package on purpose here I'd just do `geos_point_(start|end)() %>% st_as_sf()`; however, for the purposes of this post, I'm going to stick to sf. In my previous post I used [`st_cast(, "POINT")`](https://rdrr.io/pkg/sf/man/st_cast.html), but this is really slow (3 minutes) for all of Nova Scotia. We only need to resolve two points from each segment, not all of them, so we can use the internal structure of the sf linestring (a matrix) to extract the first and last coordinate. All together this is about 20 seconds (it's about 0.2 seconds with [`geos_point_start()`](https://rdrr.io/pkg/geos/man/geos_centroid.html) + [`geos_point_end()`](https://rdrr.io/pkg/geos/man/geos_centroid.html)).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>rivers_ns_sf_start</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/lapply.html'>lapply</a></span>(
  <span class='k'>rivers_ns_sf_line</span><span class='o'>$</span><span class='k'>geometry</span>, 
  <span class='nf'>function</span>(<span class='k'>x</span>) <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st.html'>st_point</a></span>(<span class='k'>x</span>[<span class='m'>1</span>, , drop = <span class='kc'>FALSE</span>])
) <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_as_sfc.html'>st_as_sfc</a></span>(crs = <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_crs.html'>st_crs</a></span>(<span class='k'>rivers_ns_sf_line</span>))

<span class='k'>rivers_ns_sf_end</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/lapply.html'>lapply</a></span>(
  <span class='k'>rivers_ns_sf_line</span><span class='o'>$</span><span class='k'>geometry</span>, 
  <span class='nf'>function</span>(<span class='k'>x</span>) <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st.html'>st_point</a></span>(<span class='k'>x</span>[<span class='nf'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span>(<span class='k'>x</span>), , drop = <span class='kc'>FALSE</span>])
) <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_as_sfc.html'>st_as_sfc</a></span>(crs = <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_crs.html'>st_crs</a></span>(<span class='k'>rivers_ns_sf_line</span>))</code></pre>

</div>

Creating the segment lookup table is similar in speed and syntax to [`geos_equals_matrix()`](https://rdrr.io/pkg/geos/man/geos_disjoint_matrix.html):

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>upstream_lookup_sf</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/sf/man/geos_binary_pred.html'>st_equals</a></span>(<span class='k'>rivers_ns_sf_start</span>, <span class='k'>rivers_ns_sf_end</span>)</code></pre>

</div>

I talked a big game earlier about how using [`st_is_within_distance()`](https://rdrr.io/pkg/sf/man/geos_binary_pred.html) would be nice for the purposes of solving the slight difference between the lake and river layers. It turns out that's pretty slow (for the big lake, Lake Rossignol, it took about 30 seconds) and so I didn't do it here as it would wreck the comparison. The only difference here is that I pre-compute the binary predicates because there is no index that we can query on repeat and rebuilding it for each lake takes about 5 seconds (for comparison, computing the network for Lake Major takes less than half a second).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>lake_boundary_sf</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/sf/man/geos_unary.html'>st_boundary</a></span>(<span class='k'>lakes_ns_sf</span><span class='o'>$</span><span class='k'>geometry</span>)
<span class='k'>lake_not_inlet_sf</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/sf/man/geos_binary_pred.html'>st_intersects</a></span>(<span class='k'>lakes_ns_sf</span><span class='o'>$</span><span class='k'>geometry</span>, <span class='k'>rivers_ns_sf_start</span>)
<span class='k'>lake_maybe_inlet</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/sf/man/geos_binary_pred.html'>st_intersects</a></span>(<span class='k'>lake_boundary_sf</span>, <span class='k'>rivers_ns_sf_line</span>)

<span class='k'>lake_inlet_outlet_pt</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/sf/man/geos_binary_ops.html'>st_intersection</a></span>(
  <span class='k'>rivers_ns_sf_line</span><span class='o'>$</span><span class='k'>geometry</span>[<span class='k'>lake_maybe_inlet</span>[[<span class='m'>399</span>]]], 
  <span class='k'>lake_boundary_sf</span>[<span class='m'>399</span>]
)

<span class='k'>lake_inlet_which</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/sets.html'>setdiff</a></span>(
  <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_nearest_feature.html'>st_nearest_feature</a></span>(<span class='k'>lake_inlet_outlet_pt</span>, <span class='k'>rivers_ns_sf_end</span>),
  <span class='k'>lake_not_inlet_sf</span>[[<span class='m'>399</span>]]
)

<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>lakes_ns_sf</span><span class='o'>$</span><span class='k'>geometry</span>[<span class='m'>399</span>])
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>rivers_ns_sf_end</span>[<span class='k'>lake_inlet_which</span>], add = <span class='k'>T</span>)
</code></pre>
<img src="figs/unnamed-chunk-20-1.png" width="700px" style="display: block; margin: auto;" />

</div>

If you'll look at `upstream_segments()` you'll notice that it doesn't work with geometry at all (just the lookup table), so we can re-use it with the sf-derived lookups and our inlet/outlet code from above.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>lake_upstream_segments_sf</span> <span class='o'>&lt;-</span> <span class='nf'>function</span>(<span class='k'>lake_id</span>) {
  <span class='k'>lake_inlet_outlet_pt</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/sf/man/geos_binary_ops.html'>st_intersection</a></span>(
    <span class='k'>rivers_ns_sf_line</span><span class='o'>$</span><span class='k'>geometry</span>[<span class='k'>lake_maybe_inlet</span>[[<span class='k'>lake_id</span>]]], 
    <span class='k'>lake_boundary_sf</span>[<span class='k'>lake_id</span>]
  )
  
  <span class='k'>lake_inlet_which</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/sets.html'>setdiff</a></span>(
    <span class='nf'><a href='https://rdrr.io/pkg/sf/man/st_nearest_feature.html'>st_nearest_feature</a></span>(<span class='k'>lake_inlet_outlet_pt</span>, <span class='k'>rivers_ns_sf_end</span>),
    <span class='k'>lake_not_inlet_sf</span>[[<span class='k'>lake_id</span>]]
  )
  
  <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(
    <span class='k'>lake_inlet_which</span>,
    <span class='nf'>upstream_segments</span>(
      <span class='k'>lake_inlet_which</span>,
      lookup = <span class='k'>upstream_lookup_sf</span>,
      recursive_limit = <span class='m'>5000</span>
    )
  )
}

<span class='k'>test_segments</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/unique.html'>unique</a></span>(<span class='nf'>lake_upstream_segments_sf</span>(<span class='m'>399</span>))
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>rivers_ns_sf_line</span><span class='o'>$</span><span class='k'>geometry</span>[<span class='k'>test_segments</span>])
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>lakes_ns_sf</span><span class='o'>$</span><span class='k'>geometry</span>[<span class='m'>399</span>], col = <span class='m'>NA</span>, border = <span class='s'>"red"</span>, add = <span class='k'>T</span>)
</code></pre>
<img src="figs/unnamed-chunk-21-1.png" width="700px" style="display: block; margin: auto;" />

</div>

On the big network we looked at earlier it generates the same network and takes \~1.7 seconds.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>test_segments</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/unique.html'>unique</a></span>(<span class='nf'>lake_upstream_segments_sf</span>(<span class='m'>226</span>))
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>rivers_ns_sf_line</span><span class='o'>$</span><span class='k'>geometry</span>[<span class='k'>test_segments</span>])
<span class='nf'><a href='https://rdrr.io/pkg/sf/man/plot.html'>plot</a></span>(<span class='k'>lakes_ns_sf</span><span class='o'>$</span><span class='k'>geometry</span>[<span class='m'>226</span>], col = <span class='m'>NA</span>, border = <span class='s'>"red"</span>, add = <span class='k'>T</span>)
</code></pre>
<img src="figs/unnamed-chunk-22-1.png" width="700px" style="display: block; margin: auto;" />

</div>

I imagine there's some variability in the final timing, but I can get through all the lakes in about 6 minutes locally. Far better than my quote of an hour!

## How I'd actually do it

In both approaches I was being a purist to see if there was any point to using geos for something like this. It's the use case I imagined when I wrote it: where you want to do a lot of nuts-and-bolts calculations in a loop. If I were doing this in real life today I'd use a mix of sf, s2, and geos, since they're all really good at various parts of the calculation. As of this writing `s2_dwithin()` is a still too slow to be useful here and I haven't quite found the solution I'd like for the inlet/outlet thing (probably I'd use something like [`geos_set_precision()`](https://rdrr.io/pkg/geos/man/geos_centroid.html) to put all vertices on a common grid).

