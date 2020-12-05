---
title: "Hacking Seabird HEX files using R and the tidyverse"
subtitle: ""
summary: ""
authors: []
tags: []
categories: []
date: 2020-12-05T10:10:14-04:00
lastmod: 2020-12-05T10:10:14-04:00
featured: false
draft: false
image:
  caption: ""
  focal_point: ""
  preview_only: false
projects: []
output: hugodown::md_document
rmd_hash: 4c244ae0834adb75

---

Avid readers of this blog, if there are any, would have figured out that I really love [low-level data IO](/post/2016/raspberry-pi-pure-python-infrared-remote-control) and [hacking proprietary file formats](post/2016/processing-sub-bottom-profiling-data-in-python) so that I can use the data in the open-source (mostly) software that I know and love. At my new position I was assigned to attend [Seabird University](https://www.seabird.com/training-videos), an excellent six-session training course on how to acquire and process oceanographic data using Seabird instruments and software. My brain went straight for one thing: can I do this in R?

The SeaSoft family of software for Seabird instruments is professionally built and uses high-quality published data proessing methods. SeaSoft only run on Windows, however, and many of these methods can also be applied using open-source oceanographic software such as the [oce package for R](https://dankelley.github.io/oce/). There is one step, however, whose low-level details are poorly documented: the converting of .hex files read from an instrument to .cnv files with human-readable outputs.

I'll use the data provided for the homework assignment ("cast1.hex") to take a stab at it along with the trusty [tidyverse](https://tidyverse.org) family of R packages.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/base/library.html'>library</a></span>(<span class='k'><a href='http://tidyverse.tidyverse.org'>tidyverse</a></span>)
<span class='nf'>read_lines</span>(<span class='s'>"cast1.hex"</span>)[<span class='m'>1</span><span class='o'>:</span><span class='m'>20</span>]
<span class='c'>#&gt;  [1] "* Sea-Bird SBE 19plus V2 Data File:"                         </span>
<span class='c'>#&gt;  [2] "* FileName = Cast1.hex"                                      </span>
<span class='c'>#&gt;  [3] "* Software Version Seasave V 7.26.7.121"                     </span>
<span class='c'>#&gt;  [4] "* Temperature SN = 0001"                                     </span>
<span class='c'>#&gt;  [5] "* Conductivity SN = 0001"                                    </span>
<span class='c'>#&gt;  [6] "* Append System Time to Every Scan"                          </span>
<span class='c'>#&gt;  [7] "* System UpLoad Time = Jun 04 2020 06:51:13"                 </span>
<span class='c'>#&gt;  [8] "* NMEA Latitude = 66 37.82718 S"                             </span>
<span class='c'>#&gt;  [9] "* NMEA Longitude = 063 19.93296 E"                           </span>
<span class='c'>#&gt; [10] "* NMEA UTC (Time) = Jun 04 2020 06:50:05"                    </span>
<span class='c'>#&gt; [11] "* Store Lat/Lon Data = Append to Every Scan"                 </span>
<span class='c'>#&gt; [12] "** Ship: SBS University"                                     </span>
<span class='c'>#&gt; [13] "** Station: Unit 1"                                          </span>
<span class='c'>#&gt; [14] "** Operator: Somebody"                                       </span>
<span class='c'>#&gt; [15] "* Real-Time Sample Interval = 0.2500 seconds"                </span>
<span class='c'>#&gt; [16] "* System UTC = Jun 04 2020 06:51:13"                         </span>
<span class='c'>#&gt; [17] "*END*"                                                       </span>
<span class='c'>#&gt; [18] "045ECA0B581F0803427BBDA9430501FF2C813F1448CC339FFE80E199D85E"</span>
<span class='c'>#&gt; [19] "045ECA0B581D0803427BBCA94E0502FF2B813B1448CC339FFE80E199D85E"</span>
<span class='c'>#&gt; [20] "045ECA0B58190803417BBDA94A0509FF2E81371448CC339FFE81E199D85E"</span></code></pre>

</div>

The first things to notice are (1) this is a text file, (2) there's some header information that might be useful, and (3) the rest of the file is made up of lines exactly 60 characters long. As the file extension indicates, these are hexadecimal representations of bytes sent by the unit. R has a vector type for bytes ([`raw()`](https://rdrr.io/r/base/raw.html)), so a good first step might be to parse the file into an object that looks like [`list(raw(), raw(), raw(), ...)`](https://rdrr.io/r/base/list.html) so that we can inspect the values for what they are (strings of bytes). There are more efficient hex parsers out there, but for now we just need something that works:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>line_to_raw</span> <span class='o'>&lt;-</span> <span class='nf'>function</span>(<span class='k'>line</span>) {
  <span class='k'>line_raw</span> <span class='o'>&lt;-</span> <span class='nf'>str_sub</span>(
    <span class='k'>line</span>,
    <span class='nf'><a href='https://rdrr.io/r/base/seq.html'>seq</a></span>(<span class='m'>1</span>, <span class='nf'><a href='https://rdrr.io/r/base/nchar.html'>nchar</a></span>(<span class='k'>line</span>) <span class='o'>-</span> <span class='m'>1</span>, <span class='m'>2</span>),
    <span class='nf'><a href='https://rdrr.io/r/base/seq.html'>seq</a></span>(<span class='m'>2</span>, <span class='nf'><a href='https://rdrr.io/r/base/nchar.html'>nchar</a></span>(<span class='k'>line</span>), <span class='m'>2</span>)
  )
  <span class='nf'><a href='https://rdrr.io/r/base/raw.html'>as.raw</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span>(<span class='s'>"0x"</span>, <span class='k'>line_raw</span>))
}

<span class='k'>lines_hex</span> <span class='o'>&lt;-</span> <span class='nf'>read_lines</span>(<span class='s'>"cast1.hex"</span>, skip = <span class='m'>17</span>)
<span class='k'>lines_raw</span> <span class='o'>&lt;-</span> <span class='nf'>map</span>(<span class='k'>lines_hex</span>, <span class='k'>line_to_raw</span>)

<span class='nf'><a href='https://rdrr.io/r/utils/head.html'>head</a></span>(<span class='k'>lines_raw</span>, <span class='m'>3</span>)
<span class='c'>#&gt; [[1]]</span>
<span class='c'>#&gt;  [1] 04 5e ca 0b 58 1f 08 03 42 7b bd a9 43 05 01 ff 2c 81 3f 14 48 cc 33 9f fe</span>
<span class='c'>#&gt; [26] 80 e1 99 d8 5e</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; [[2]]</span>
<span class='c'>#&gt;  [1] 04 5e ca 0b 58 1d 08 03 42 7b bc a9 4e 05 02 ff 2b 81 3b 14 48 cc 33 9f fe</span>
<span class='c'>#&gt; [26] 80 e1 99 d8 5e</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; [[3]]</span>
<span class='c'>#&gt;  [1] 04 5e ca 0b 58 19 08 03 41 7b bd a9 4a 05 09 ff 2e 81 37 14 48 cc 33 9f fe</span>
<span class='c'>#&gt; [26] 81 e1 99 d8 5e</span></code></pre>

</div>

The second thing I noticed was that some of the bytes stay the same for every scan. This isn't limited to just one value, but shows up many times over the course of the file. To find out how prevalent this was, I did what everybody should do with raw data the first time they open it: plot! For strings of bytes this is a bit non-standard, but after reading David Robinson's [excelent post about plotting the structure of the Enron Excel attachments](https://rpubs.com/dgrtwo/tidying-enron), I decided on a similar approach.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>lines_tbl</span> <span class='o'>&lt;-</span> <span class='nf'>tibble</span>(
  lines_hex = <span class='k'>lines_hex</span>,
  lines_raw = <span class='k'>lines_raw</span>,
  scan = <span class='nf'><a href='https://rdrr.io/r/base/seq.html'>seq_along</a></span>(<span class='k'>lines_raw</span>),
  pos = <span class='nf'><a href='https://rdrr.io/r/base/lapply.html'>lapply</a></span>(<span class='k'>lines_raw</span>, <span class='k'>seq_along</span>)
)

<span class='k'>lines_tbl</span> <span class='o'>%&gt;%</span>
  <span class='nf'>select</span>(<span class='k'>scan</span>, <span class='k'>pos</span>, <span class='k'>lines_raw</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'>unnest</span>(<span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='k'>lines_raw</span>, <span class='k'>pos</span>)) <span class='o'>%&gt;%</span>
  <span class='nf'>ggplot</span>(<span class='nf'>aes</span>(x = <span class='k'>pos</span>, y = <span class='k'>scan</span>, fill = <span class='nf'><a href='https://rdrr.io/r/base/integer.html'>as.integer</a></span>(<span class='k'>lines_raw</span>))) <span class='o'>+</span>
  <span class='nf'>geom_raster</span>() <span class='o'>+</span>
  <span class='nf'>scale_y_reverse</span>() <span class='o'>+</span>
  <span class='nf'>scale_x_continuous</span>(breaks = <span class='m'>1</span><span class='o'>:</span><span class='m'>30</span>) <span class='o'>+</span>
  <span class='nf'>coord_cartesian</span>(expand = <span class='kc'>FALSE</span>)
</code></pre>
<img src="figs/unnamed-chunk-3-1.png" width="700px" style="display: block; margin: auto;" />

</div>

It looks like there are many columns of bytes in this category (changing infrequently), but others change rapidly.

At this point, we need some information about what's in the file. This is a cast of a sensor array that was lowered into the ocean, probably soaked at the surface for some amount of time, and was then lowered and possibly retrieved at some point. The point is, the values represented by scans next to each other are probably representative of similar if not identical values (seawater properties are unlikely to change that quickly). Another thing we know is that the values that are output here are uncalibrated measurements. That is, they don't represent temperature or conductivity, they represent the voltages and/or frequencies measured by the sensor.

From hacking previous file formats, I already guessed that each line was probably a bunch of unsigned integers glued together somehow. When searching the hex file format, I came across [this Matlab script](http://mooring.ucsd.edu/software/matlab/doc/toolbox/data/sbe/read_hex.html) which gave some clues as to how these fields are represented on a different Seabird sensor. Basically, it looks like each collection of 2, 3, or 4 bytes is representing an unsigned integer that is then multiplied by some number to get the voltage.

Putting both of these together, we can figure out where the groups of bytes are: as integer values change slowly, the most significant digit is likely to change the slowest, whereas the least significant digit (the ones place) is likely to change the fastest:

(animation)

Guessing the most significant digit of everything up to byte position 19 is reasonably straightforward: there is clearly a most and least significant pattern of change in the columns. After that I did some guessing: byte 20 has the same value (14) for almost every scan, and the last four positions seemed to represent something whose least significant byte was on the left (i.e., little endian rather than big endian). In the middle were six columns that didn't change much at all. Six bytes can represent a really really big integer which seemed unlikely when so much effort appears to be made to minimize the number of bytes in the scan, so I split it into two and assumed big endian (I have the benefit of hindsight here...in practice I experimented with a few combinations).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>cols</span> <span class='o'>&lt;-</span> <span class='nf'>tibble</span>(
  start = <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='m'>1</span>, <span class='m'>4</span>, <span class='m'>7</span>, <span class='m'>10</span>, <span class='m'>12</span>, <span class='m'>14</span>, <span class='m'>16</span>, <span class='m'>18</span>, <span class='m'>20</span>, <span class='m'>21</span>, <span class='m'>24</span>, <span class='m'>27</span>),
  size = <span class='nf'><a href='https://rdrr.io/r/base/diff.html'>diff</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='k'>start</span>, <span class='m'>31</span>)),
  big_endian = <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span>(<span class='kc'>TRUE</span>, <span class='m'>11</span>), <span class='kc'>FALSE</span>),
  name = <span class='nf'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span>(<span class='s'>"col"</span>, <span class='k'>start</span>)
)

<span class='k'>cols</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 12 x 4</span></span>
<span class='c'>#&gt;    start  size big_endian name </span>
<span class='c'>#&gt;    <span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;lgl&gt;</span><span>      </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span><span>     1     3 TRUE       col1 </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span><span>     4     3 TRUE       col4 </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span><span>     7     3 TRUE       col7 </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span><span>    10     2 TRUE       col10</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span><span>    12     2 TRUE       col12</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span><span>    14     2 TRUE       col14</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span><span>    16     2 TRUE       col16</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span><span>    18     2 TRUE       col18</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span><span>    20     1 TRUE       col20</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span><span>    21     3 TRUE       col21</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>11</span><span>    24     3 TRUE       col24</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>12</span><span>    27     4 FALSE      col27</span></span></code></pre>

</div>

Now the problem of how to make these integers that we can work with! Again, there are faster solutions, but for now we just need something that works. The key hurdle here is that pretty much nothing can read a 3-byte long integer, so we have to pad it with a fourth byte on the right or left depending on which endian we're dealing with. I chose to use base R's [`readBin()`](https://rdrr.io/r/base/readBin.html) here with a [`rawConnection()`](https://rdrr.io/r/base/rawConnection.html) rather than drop into compiled code just yet. Note also `scale` and `offset` as a foreshadowing of transformations to come.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>extract_raw_uint</span> <span class='o'>&lt;-</span> <span class='nf'>function</span>(<span class='k'>x</span>, <span class='k'>start</span>, <span class='k'>size</span>, <span class='k'>big_endian</span>, <span class='k'>scale</span> = <span class='m'>1</span>, <span class='k'>offset</span> = <span class='m'>0</span>, <span class='k'>...</span>) {
  <span class='k'>x</span> <span class='o'>&lt;-</span> <span class='k'>x</span>[<span class='k'>start</span><span class='o'>:</span>(<span class='k'>start</span> <span class='o'>+</span> <span class='k'>size</span> <span class='o'>-</span> <span class='m'>1</span>)]
  
  <span class='c'># need to pad size 3 bytes to 4 for R to read</span>
  <span class='kr'>if</span> (<span class='k'>size</span> <span class='o'>==</span> <span class='m'>3</span> <span class='o'>&amp;&amp;</span> <span class='k'>big_endian</span>) {
    <span class='k'>x</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/raw.html'>as.raw</a></span>(<span class='m'>0x00</span>), <span class='k'>x</span>)
    <span class='k'>size</span> <span class='o'>&lt;-</span> <span class='m'>4</span>
  } <span class='kr'>else</span> <span class='kr'>if</span> (<span class='k'>size</span> <span class='o'>==</span> <span class='m'>3</span> <span class='o'>&amp;&amp;</span> <span class='o'>!</span><span class='k'>big_endian</span>) {
    <span class='k'>x</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='k'>x</span>, <span class='nf'><a href='https://rdrr.io/r/base/raw.html'>as.raw</a></span>(<span class='m'>0x00</span>))
    <span class='k'>size</span> <span class='o'>&lt;-</span> <span class='m'>4</span>
  }
  
  <span class='k'>con</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/rawConnection.html'>rawConnection</a></span>(<span class='k'>x</span>)
  <span class='nf'><a href='https://rdrr.io/r/base/on.exit.html'>on.exit</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/connections.html'>close</a></span>(<span class='k'>con</span>))
  <span class='c'># R can't read a four-byte unsigned integer...approximate with signed for now</span>
  <span class='k'>value</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/readBin.html'>readBin</a></span>(
    <span class='k'>con</span>, 
    <span class='s'>"integer"</span>, n = <span class='m'>1</span>,
    size = <span class='k'>size</span>, 
    endian = <span class='kr'>if</span> (<span class='k'>big_endian</span>) <span class='s'>"big"</span> <span class='kr'>else</span> <span class='s'>"little"</span>, 
    signed = <span class='k'>size</span> <span class='o'>&gt;=</span> <span class='m'>4</span>
  )
  <span class='k'>value</span> <span class='o'>/</span> <span class='k'>scale</span> <span class='o'>+</span> <span class='k'>offset</span>
}</code></pre>

</div>

I strategically named the columns of `cols` and arguments of `extract_raw_uint()` the same so that we can use `pmap()` to iterate over and extract the integer values. The syntax is a little awkward here...below is as clean as I could get this.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>extract_raw_uint_tbl</span> <span class='o'>&lt;-</span> <span class='nf'>function</span>(<span class='k'>x</span>, <span class='k'>cols</span>) {
  <span class='k'>values</span> <span class='o'>&lt;-</span> <span class='nf'>pmap</span>(<span class='k'>cols</span>, <span class='k'>extract_raw_uint</span>, x = <span class='k'>x</span>)
  <span class='nf'><a href='https://rdrr.io/r/base/names.html'>names</a></span>(<span class='k'>values</span>) <span class='o'>&lt;-</span> <span class='k'>cols</span><span class='o'>$</span><span class='k'>name</span>
  <span class='nf'>as_tibble</span>(<span class='k'>values</span>)
}

<span class='k'>values_int</span> <span class='o'>&lt;-</span> <span class='k'>lines_tbl</span> <span class='o'>%&gt;%</span>
  <span class='nf'>select</span>(<span class='k'>scan</span>, <span class='k'>lines_raw</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'>unnest</span>(<span class='k'>lines_raw</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'>group_by</span>(<span class='k'>scan</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'>summarise</span>(<span class='nf'>extract_raw_uint_tbl</span>(<span class='k'>lines_raw</span>, cols = <span class='k'>cols</span>))
<span class='c'>#&gt; `summarise()` ungrouping output (override with `.groups` argument)</span>

<span class='k'>values_int</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 10,000 x 13</span></span>
<span class='c'>#&gt;     scan   col1   col4   col7 col10 col12 col14 col16 col18 col20  col21  col24</span>
<span class='c'>#&gt;    <span style='color: #555555;font-style: italic;'>&lt;int&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span><span>     1 </span><span style='text-decoration: underline;'>286</span><span>410 </span><span style='text-decoration: underline;'>743</span><span>455 </span><span style='text-decoration: underline;'>525</span><span>122 </span><span style='text-decoration: underline;'>31</span><span>677 </span><span style='text-decoration: underline;'>43</span><span>331  </span><span style='text-decoration: underline;'>1</span><span>281 </span><span style='text-decoration: underline;'>65</span><span>324 </span><span style='text-decoration: underline;'>33</span><span>087    20 4.77</span><span style='color: #555555;'>e</span><span>6 1.05</span><span style='color: #555555;'>e</span><span>7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span><span>     2 </span><span style='text-decoration: underline;'>286</span><span>410 </span><span style='text-decoration: underline;'>743</span><span>453 </span><span style='text-decoration: underline;'>525</span><span>122 </span><span style='text-decoration: underline;'>31</span><span>676 </span><span style='text-decoration: underline;'>43</span><span>342  </span><span style='text-decoration: underline;'>1</span><span>282 </span><span style='text-decoration: underline;'>65</span><span>323 </span><span style='text-decoration: underline;'>33</span><span>083    20 4.77</span><span style='color: #555555;'>e</span><span>6 1.05</span><span style='color: #555555;'>e</span><span>7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span><span>     3 </span><span style='text-decoration: underline;'>286</span><span>410 </span><span style='text-decoration: underline;'>743</span><span>449 </span><span style='text-decoration: underline;'>525</span><span>121 </span><span style='text-decoration: underline;'>31</span><span>677 </span><span style='text-decoration: underline;'>43</span><span>338  </span><span style='text-decoration: underline;'>1</span><span>289 </span><span style='text-decoration: underline;'>65</span><span>326 </span><span style='text-decoration: underline;'>33</span><span>079    20 4.77</span><span style='color: #555555;'>e</span><span>6 1.05</span><span style='color: #555555;'>e</span><span>7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span><span>     4 </span><span style='text-decoration: underline;'>286</span><span>413 </span><span style='text-decoration: underline;'>743</span><span>451 </span><span style='text-decoration: underline;'>525</span><span>121 </span><span style='text-decoration: underline;'>31</span><span>676 </span><span style='text-decoration: underline;'>43</span><span>336  </span><span style='text-decoration: underline;'>1</span><span>283 </span><span style='text-decoration: underline;'>65</span><span>323 </span><span style='text-decoration: underline;'>33</span><span>085    20 4.77</span><span style='color: #555555;'>e</span><span>6 1.05</span><span style='color: #555555;'>e</span><span>7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span><span>     5 </span><span style='text-decoration: underline;'>286</span><span>413 </span><span style='text-decoration: underline;'>743</span><span>443 </span><span style='text-decoration: underline;'>525</span><span>121 </span><span style='text-decoration: underline;'>31</span><span>676 </span><span style='text-decoration: underline;'>43</span><span>347  </span><span style='text-decoration: underline;'>1</span><span>300 </span><span style='text-decoration: underline;'>65</span><span>330 </span><span style='text-decoration: underline;'>33</span><span>082    20 4.77</span><span style='color: #555555;'>e</span><span>6 1.05</span><span style='color: #555555;'>e</span><span>7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span><span>     6 </span><span style='text-decoration: underline;'>286</span><span>413 </span><span style='text-decoration: underline;'>743</span><span>412 </span><span style='text-decoration: underline;'>525</span><span>120 </span><span style='text-decoration: underline;'>31</span><span>676 </span><span style='text-decoration: underline;'>43</span><span>337  </span><span style='text-decoration: underline;'>1</span><span>299 </span><span style='text-decoration: underline;'>65</span><span>324 </span><span style='text-decoration: underline;'>33</span><span>087    20 4.77</span><span style='color: #555555;'>e</span><span>6 1.05</span><span style='color: #555555;'>e</span><span>7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span><span>     7 </span><span style='text-decoration: underline;'>286</span><span>415 </span><span style='text-decoration: underline;'>743</span><span>365 </span><span style='text-decoration: underline;'>525</span><span>120 </span><span style='text-decoration: underline;'>31</span><span>676 </span><span style='text-decoration: underline;'>43</span><span>342  </span><span style='text-decoration: underline;'>1</span><span>299 </span><span style='text-decoration: underline;'>65</span><span>322 </span><span style='text-decoration: underline;'>33</span><span>083    20 4.77</span><span style='color: #555555;'>e</span><span>6 1.05</span><span style='color: #555555;'>e</span><span>7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span><span>     8 </span><span style='text-decoration: underline;'>286</span><span>416 </span><span style='text-decoration: underline;'>743</span><span>320 </span><span style='text-decoration: underline;'>525</span><span>120 </span><span style='text-decoration: underline;'>31</span><span>677 </span><span style='text-decoration: underline;'>43</span><span>342  </span><span style='text-decoration: underline;'>1</span><span>298 </span><span style='text-decoration: underline;'>65</span><span>327 </span><span style='text-decoration: underline;'>33</span><span>078    20 4.77</span><span style='color: #555555;'>e</span><span>6 1.05</span><span style='color: #555555;'>e</span><span>7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span><span>     9 </span><span style='text-decoration: underline;'>286</span><span>416 </span><span style='text-decoration: underline;'>743</span><span>240 </span><span style='text-decoration: underline;'>525</span><span>122 </span><span style='text-decoration: underline;'>31</span><span>676 </span><span style='text-decoration: underline;'>43</span><span>339  </span><span style='text-decoration: underline;'>1</span><span>259 </span><span style='text-decoration: underline;'>65</span><span>331 </span><span style='text-decoration: underline;'>33</span><span>071    20 4.77</span><span style='color: #555555;'>e</span><span>6 1.05</span><span style='color: #555555;'>e</span><span>7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span><span>    10 </span><span style='text-decoration: underline;'>286</span><span>416 </span><span style='text-decoration: underline;'>743</span><span>169 </span><span style='text-decoration: underline;'>525</span><span>123 </span><span style='text-decoration: underline;'>31</span><span>675 </span><span style='text-decoration: underline;'>43</span><span>339  </span><span style='text-decoration: underline;'>1</span><span>262 </span><span style='text-decoration: underline;'>65</span><span>324 </span><span style='text-decoration: underline;'>33</span><span>082    20 4.77</span><span style='color: #555555;'>e</span><span>6 1.05</span><span style='color: #555555;'>e</span><span>7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'># … with 9,990 more rows, and 1 more variable: col27 </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span></span></code></pre>

</div>

Cool! We indeed have a data frame of values that don't change very much between scans, which was what we optimized for when picking the byte positions. I've been a bit cagey about what we know about the file so far - in this case we do have some information about which values should be present. Usually you will have a .xmlcon file with this information or a .cnv file that contains some output that might give you a clue. In my case, I had the .xmlcon file and access to a Windows computer, so I ran "Data conversion" extracting the voltage and frequency channels as well as the latitude, longitude, and time variables since the .xmlcon file indicated that these variables were present for each scan.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>converted</span> <span class='o'>&lt;-</span> <span class='nf'>read_fwf</span>(
  <span class='s'>"cast1.cnv"</span>,
  col_positions = <span class='nf'>fwf_widths</span>(
    widths = <span class='nf'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span>(<span class='m'>11</span>, <span class='m'>15</span>), 
    col_names = <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(
      <span class='s'>"prdM"</span>, <span class='s'>"v0"</span>, <span class='s'>"v1"</span>, <span class='s'>"v2"</span>, <span class='s'>"v3"</span>, <span class='s'>"timeY"</span>, <span class='s'>"timeS"</span>, <span class='s'>"scan"</span>, <span class='s'>"latitude"</span>, 
      <span class='s'>"longitude"</span>, <span class='s'>"nbytes"</span>, <span class='s'>"f0"</span>, <span class='s'>"f1"</span>, <span class='s'>"f2"</span>, <span class='s'>"flag"</span>
    )
  ),
  col_types = <span class='nf'>cols</span>(.default = <span class='nf'>col_double</span>()),
  skip = <span class='m'>189</span>
)

<span class='k'>converted</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 10,000 x 15</span></span>
<span class='c'>#&gt;     prdM    v0     v1    v2    v3  timeY timeS  scan latitude longitude nbytes</span>
<span class='c'>#&gt;    <span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>    </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>     </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span><span> 0.85   3.31 0.097</span><span style='text-decoration: underline;'>7</span><span>  4.98  2.52 1.59</span><span style='color: #555555;'>e</span><span>9  0        1    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7     60</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span><span> 0.85   3.31 0.097</span><span style='text-decoration: underline;'>8</span><span>  4.98  2.52 1.59</span><span style='color: #555555;'>e</span><span>9  0.25     2    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7    120</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span><span> 0.829  3.31 0.098</span><span style='text-decoration: underline;'>3</span><span>  4.98  2.52 1.59</span><span style='color: #555555;'>e</span><span>9  0.5      3    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7    180</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span><span> 0.828  3.31 0.097</span><span style='text-decoration: underline;'>9</span><span>  4.98  2.52 1.59</span><span style='color: #555555;'>e</span><span>9  0.75     4    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7    240</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span><span> 0.828  3.31 0.099</span><span style='text-decoration: underline;'>2</span><span>  4.98  2.52 1.59</span><span style='color: #555555;'>e</span><span>9  1        5    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7    300</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span><span> 0.807  3.31 0.099</span><span style='text-decoration: underline;'>1</span><span>  4.98  2.52 1.59</span><span style='color: #555555;'>e</span><span>9  1.25     6    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7    360</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span><span> 0.807  3.31 0.099</span><span style='text-decoration: underline;'>1</span><span>  4.98  2.52 1.59</span><span style='color: #555555;'>e</span><span>9  1.5      7    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7    420</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span><span> 0.807  3.31 0.099   4.98  2.52 1.59</span><span style='color: #555555;'>e</span><span>9  1.75     8    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7    480</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span><span> 0.85   3.31 0.096</span><span style='text-decoration: underline;'>1</span><span>  4.98  2.52 1.59</span><span style='color: #555555;'>e</span><span>9  2        9    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7    540</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span><span> 0.871  3.31 0.096</span><span style='text-decoration: underline;'>3</span><span>  4.98  2.52 1.59</span><span style='color: #555555;'>e</span><span>9  2.25    10    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7    600</span></span>
<span class='c'>#&gt; <span style='color: #555555;'># … with 9,990 more rows, and 4 more variables: f0 </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span style='color: #555555;'>, f1 </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span style='color: #555555;'>, f2 </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span style='color: #555555;'>,</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>#   flag </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span></span></code></pre>

</div>

With the "answers", we can compare with our integer values to see which integers extracted from the scan correspond to values generated by SeaSoft. I'm using Spearman's here because whatever the calibration functions are, they have to be one-to-one relationships along the reported range of values. This let us figure out the relationships without knowing anything about the calibration functions themselves!

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>combinations</span> <span class='o'>&lt;-</span> <span class='nf'>inner_join</span>(
  <span class='k'>values_int</span> <span class='o'>%&gt;%</span> <span class='nf'>pivot_longer</span>(<span class='o'>-</span><span class='k'>scan</span>),
  <span class='k'>converted</span> <span class='o'>%&gt;%</span> <span class='nf'>pivot_longer</span>(<span class='o'>-</span><span class='k'>scan</span>),
  by = <span class='s'>"scan"</span>,
  suffix = <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='s'>"_int"</span>, <span class='s'>"_converted"</span>)
) <span class='o'>%&gt;%</span> 
  <span class='nf'>mutate</span>(
    name_int = <span class='nf'>as_factor</span>(<span class='k'>name_int</span>), 
    name_converted = <span class='nf'>as_factor</span>(<span class='k'>name_converted</span>)
  )

<span class='k'>combinations_perfect</span> <span class='o'>&lt;-</span> <span class='k'>combinations</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>group_by</span>(<span class='k'>name_int</span>, <span class='k'>name_converted</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'>summarise</span>(r = <span class='nf'><a href='https://rdrr.io/r/stats/cor.html'>cor</a></span>(<span class='k'>value_int</span>, <span class='k'>value_converted</span>, method = <span class='s'>"spearman"</span>)) <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/MathFun.html'>abs</a></span>(<span class='k'>r</span>) <span class='o'>&gt;</span> <span class='m'>0.996</span>)

<span class='k'>combinations_perfect</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>ggplot</span>(<span class='nf'>aes</span>(<span class='k'>name_int</span>, <span class='k'>name_converted</span>, fill = <span class='k'>r</span>)) <span class='o'>+</span>
  <span class='nf'>geom_tile</span>() <span class='o'>+</span>
  <span class='nf'>scale_y_discrete</span>(drop = <span class='kc'>FALSE</span>) <span class='o'>+</span>
  <span class='nf'>scale_x_discrete</span>(drop = <span class='kc'>FALSE</span>)
</code></pre>
<img src="figs/unnamed-chunk-8-1.png" width="700px" style="display: block; margin: auto;" />

</div>

Using this, we have a match for most of the columns and integer values with the exception of the column at byte position 10. At byte position 20, this is a value that never changes and likely corresponds to flag, which also never changes (there are no scans flagged as bad in the subset we're looking at). Column 27 looks like it has a few matches but this is because `timeY`, `timeS` and `nbytes` are also correlated (bytes because the instrument was writing at at a constant baud rate over a serial port). This plot also gives us the relationships between the raw frequency/voltage channels and the parameters themselves, which we can use to apply the calibration functions later on!

We're almost done hacking the binary part of the format. What remains is to figure out which `scale` and `offset` to apply to each integer value to generate the frequency and/or voltage associated with each integer value. The [Matlab script](http://mooring.ucsd.edu/software/matlab/doc/toolbox/data/sbe/read_hex.html) mentioned above was really useful as well...the values "13.107" and "256" come up a lot in that script and do here as well. I print out the scale and its inverse here because the inverse is usually a prettier number (this is how I parameterized the integer read function).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>combinations_perfect</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>left_join</span>(<span class='k'>combinations</span>, by = <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='s'>"name_int"</span>, <span class='s'>"name_converted"</span>)) <span class='o'>%&gt;%</span> 
  <span class='nf'>group_by</span>(<span class='k'>name_int</span>, <span class='k'>name_converted</span>) <span class='o'>%&gt;%</span>
  <span class='nf'>summarise</span>(
    <span class='k'>broom</span>::<span class='nf'><a href='https://rdrr.io/pkg/generics/man/tidy.html'>tidy</a></span>(<span class='nf'><a href='https://rdrr.io/r/stats/lm.html'>lm</a></span>(<span class='k'>value_converted</span> <span class='o'>~</span> <span class='k'>value_int</span>))
  ) <span class='o'>%&gt;%</span> 
  <span class='nf'>select</span>(<span class='k'>name_int</span>, <span class='k'>name_converted</span>, <span class='k'>term</span>, <span class='k'>estimate</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'>pivot_wider</span>(names_from = <span class='k'>term</span>, values_from = <span class='k'>estimate</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'>mutate</span>(inverse_scale = <span class='m'>1</span> <span class='o'>/</span> <span class='k'>value_int</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'>mutate_all</span>(<span class='o'>~</span><span class='nf'>map_chr</span>(<span class='k'>.</span>, <span class='k'>format</span>))
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 18 x 5</span></span>
<span class='c'>#&gt; <span style='color: #555555;'># Groups:   name_int, name_converted [18]</span></span>
<span class='c'>#&gt;    name_int name_converted `(Intercept)` value_int    inverse_scale</span>
<span class='c'>#&gt;    <span style='color: #555555;font-style: italic;'>&lt;fct&gt;</span><span>    </span><span style='color: #555555;font-style: italic;'>&lt;fct&gt;</span><span>          </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>         </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>        </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>        </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span><span> col1     f0             1.266599e-09  1            1            </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span><span> col4     f1             -8.817092e-06 0.00390625   256          </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span><span> col7     prdM           -11191.77     0.02131351   46.9186      </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span><span> col7     timeY          1591236507    0.03319315   30.12669     </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span><span> col7     timeS          -16760.23     0.03277659   30.50958     </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span><span> col7     nbytes         -4022396      7.866382     0.1271232    </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span><span> col7     f2             -3.20375e-09  1            1            </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span><span> col12    v0             3.946036e-06  7.6295e-05   13107.02     </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span><span> col14    v1             3.828182e-06  7.629482e-05 13107.05     </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span><span> col16    v2             -1.737767e-06 7.62951e-05  13107        </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>11</span><span> col18    v3             -6.53366e-06  7.629525e-05 13106.98     </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>12</span><span> col21    latitude       -26.2144      -7.8125e-08  -12800000    </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>13</span><span> col24    longitude      66.84671      7.812493e-08 12800011     </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>14</span><span> col27    prdM           -975886284    0.6132813    1.630573     </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>15</span><span> col27    timeY          -1.617432e-05 1            1            </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>16</span><span> col27    timeS          -1570569041   0.9870012    1.01317      </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>17</span><span> col27    nbytes         -376936569722 236.8803     0.004221542  </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>18</span><span> col27    f2             -45792152310  28.77773     0.03474909</span></span></code></pre>

</div>

Usefully, there are a number of places where the scale is 1 (meaning that the integer values don't have to be transformed into frequencies or voltages). I'm dubious of the latitude/longitude regression because the spread of the values is so small, and I can't find any meaning in the numbers -26.2144 or 66.84671. Coming back to our `cols` specification, we can add in what we've figured out about the scale and offset for these columns.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>cols_final</span> <span class='o'>&lt;-</span> <span class='nf'>tibble</span>(
  start = <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='m'>1</span>, <span class='m'>4</span>, <span class='m'>7</span>, <span class='m'>10</span>, <span class='m'>12</span>, <span class='m'>14</span>, <span class='m'>16</span>, <span class='m'>18</span>, <span class='m'>20</span>, <span class='m'>21</span>, <span class='m'>24</span>, <span class='m'>27</span>),
  size = <span class='nf'><a href='https://rdrr.io/r/base/diff.html'>diff</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='k'>start</span>, <span class='m'>31</span>)),
  big_endian = <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='nf'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span>(<span class='kc'>TRUE</span>, <span class='m'>11</span>), <span class='kc'>FALSE</span>),
  name = <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='s'>"f0"</span>, <span class='s'>"f1"</span>, <span class='s'>"f2"</span>, <span class='s'>"ukn"</span>, <span class='s'>"v0"</span>, <span class='s'>"v1"</span>, <span class='s'>"v2"</span>, <span class='s'>"v3"</span>, <span class='s'>"flag"</span>, <span class='s'>"latitude"</span>, <span class='s'>"longitude"</span>, <span class='s'>"timeY"</span>),
  scale = <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>( <span class='m'>1</span>,  <span class='m'>256</span>,    <span class='m'>1</span>,     <span class='m'>1</span>, <span class='nf'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span>(<span class='m'>13107</span>, <span class='m'>4</span>),               <span class='m'>1</span>,  <span class='o'>-</span><span class='m'>12800000</span>,    <span class='m'>12800000</span>,       <span class='m'>1</span>),
  offset = <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span>(<span class='m'>0</span>,    <span class='m'>0</span>,    <span class='m'>0</span>,     <span class='m'>0</span>, <span class='nf'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span>(<span class='m'>0</span>, <span class='m'>4</span>),                   <span class='m'>0</span>,   <span class='o'>-</span><span class='m'>26.2144</span>,    <span class='m'>66.84671</span>,       <span class='m'>0</span>)
)

<span class='k'>values</span> <span class='o'>&lt;-</span> <span class='k'>lines_tbl</span> <span class='o'>%&gt;%</span>
  <span class='nf'>select</span>(<span class='k'>scan</span>, <span class='k'>lines_raw</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'>unnest</span>(<span class='k'>lines_raw</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'>group_by</span>(<span class='k'>scan</span>) <span class='o'>%&gt;%</span> 
  <span class='nf'>summarise</span>(<span class='nf'>extract_raw_uint_tbl</span>(<span class='k'>lines_raw</span>, cols = <span class='k'>cols_final</span>))

<span class='k'>values</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 10,000 x 13</span></span>
<span class='c'>#&gt;     scan     f0    f1     f2   ukn    v0     v1    v2    v3  flag latitude</span>
<span class='c'>#&gt;    <span style='color: #555555;font-style: italic;'>&lt;int&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>    </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span><span>     1 </span><span style='text-decoration: underline;'>286</span><span>410 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>122 </span><span style='text-decoration: underline;'>31</span><span>677  3.31 0.097</span><span style='text-decoration: underline;'>7</span><span>  4.98  2.52    20    -</span><span style='color: #BB0000;'>26.6</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span><span>     2 </span><span style='text-decoration: underline;'>286</span><span>410 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>122 </span><span style='text-decoration: underline;'>31</span><span>676  3.31 0.097</span><span style='text-decoration: underline;'>8</span><span>  4.98  2.52    20    -</span><span style='color: #BB0000;'>26.6</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span><span>     3 </span><span style='text-decoration: underline;'>286</span><span>410 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>121 </span><span style='text-decoration: underline;'>31</span><span>677  3.31 0.098</span><span style='text-decoration: underline;'>3</span><span>  4.98  2.52    20    -</span><span style='color: #BB0000;'>26.6</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span><span>     4 </span><span style='text-decoration: underline;'>286</span><span>413 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>121 </span><span style='text-decoration: underline;'>31</span><span>676  3.31 0.097</span><span style='text-decoration: underline;'>9</span><span>  4.98  2.52    20    -</span><span style='color: #BB0000;'>26.6</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span><span>     5 </span><span style='text-decoration: underline;'>286</span><span>413 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>121 </span><span style='text-decoration: underline;'>31</span><span>676  3.31 0.099</span><span style='text-decoration: underline;'>2</span><span>  4.98  2.52    20    -</span><span style='color: #BB0000;'>26.6</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span><span>     6 </span><span style='text-decoration: underline;'>286</span><span>413 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>120 </span><span style='text-decoration: underline;'>31</span><span>676  3.31 0.099</span><span style='text-decoration: underline;'>1</span><span>  4.98  2.52    20    -</span><span style='color: #BB0000;'>26.6</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span><span>     7 </span><span style='text-decoration: underline;'>286</span><span>415 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>120 </span><span style='text-decoration: underline;'>31</span><span>676  3.31 0.099</span><span style='text-decoration: underline;'>1</span><span>  4.98  2.52    20    -</span><span style='color: #BB0000;'>26.6</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span><span>     8 </span><span style='text-decoration: underline;'>286</span><span>416 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>120 </span><span style='text-decoration: underline;'>31</span><span>677  3.31 0.099</span><span style='text-decoration: underline;'>0</span><span>  4.98  2.52    20    -</span><span style='color: #BB0000;'>26.6</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span><span>     9 </span><span style='text-decoration: underline;'>286</span><span>416 </span><span style='text-decoration: underline;'>2</span><span>903. </span><span style='text-decoration: underline;'>525</span><span>122 </span><span style='text-decoration: underline;'>31</span><span>676  3.31 0.096</span><span style='text-decoration: underline;'>1</span><span>  4.98  2.52    20    -</span><span style='color: #BB0000;'>26.6</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span><span>    10 </span><span style='text-decoration: underline;'>286</span><span>416 </span><span style='text-decoration: underline;'>2</span><span>903. </span><span style='text-decoration: underline;'>525</span><span>123 </span><span style='text-decoration: underline;'>31</span><span>675  3.31 0.096</span><span style='text-decoration: underline;'>3</span><span>  4.98  2.52    20    -</span><span style='color: #BB0000;'>26.6</span></span>
<span class='c'>#&gt; <span style='color: #555555;'># … with 9,990 more rows, and 2 more variables: longitude </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span style='color: #555555;'>, timeY </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span></span></code></pre>

</div>

Compare with converted values:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>converted</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>select</span>(<span class='nf'>any_of</span>(<span class='nf'><a href='https://rdrr.io/r/base/colnames.html'>colnames</a></span>(<span class='k'>values</span>)))
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 10,000 x 12</span></span>
<span class='c'>#&gt;     scan     f0    f1     f2    v0     v1    v2    v3  flag latitude longitude</span>
<span class='c'>#&gt;    <span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>    </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>     </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span><span>     1 </span><span style='text-decoration: underline;'>286</span><span>410 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>122  3.31 0.097</span><span style='text-decoration: underline;'>7</span><span>  4.98  2.52     0    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span><span>     2 </span><span style='text-decoration: underline;'>286</span><span>410 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>122  3.31 0.097</span><span style='text-decoration: underline;'>8</span><span>  4.98  2.52     0    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span><span>     3 </span><span style='text-decoration: underline;'>286</span><span>410 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>121  3.31 0.098</span><span style='text-decoration: underline;'>3</span><span>  4.98  2.52     0    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span><span>     4 </span><span style='text-decoration: underline;'>286</span><span>413 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>121  3.31 0.097</span><span style='text-decoration: underline;'>9</span><span>  4.98  2.52     0    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span><span>     5 </span><span style='text-decoration: underline;'>286</span><span>413 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>121  3.31 0.099</span><span style='text-decoration: underline;'>2</span><span>  4.98  2.52     0    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span><span>     6 </span><span style='text-decoration: underline;'>286</span><span>413 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>120  3.31 0.099</span><span style='text-decoration: underline;'>1</span><span>  4.98  2.52     0    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span><span>     7 </span><span style='text-decoration: underline;'>286</span><span>415 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>120  3.31 0.099</span><span style='text-decoration: underline;'>1</span><span>  4.98  2.52     0    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span><span>     8 </span><span style='text-decoration: underline;'>286</span><span>416 </span><span style='text-decoration: underline;'>2</span><span>904. </span><span style='text-decoration: underline;'>525</span><span>120  3.31 0.099   4.98  2.52     0    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span><span>     9 </span><span style='text-decoration: underline;'>286</span><span>416 </span><span style='text-decoration: underline;'>2</span><span>903. </span><span style='text-decoration: underline;'>525</span><span>122  3.31 0.096</span><span style='text-decoration: underline;'>1</span><span>  4.98  2.52     0    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span><span>    10 </span><span style='text-decoration: underline;'>286</span><span>416 </span><span style='text-decoration: underline;'>2</span><span>903. </span><span style='text-decoration: underline;'>525</span><span>123  3.31 0.096</span><span style='text-decoration: underline;'>3</span><span>  4.98  2.52     0    -</span><span style='color: #BB0000;'>26.6</span><span>      67.7</span></span>
<span class='c'>#&gt; <span style='color: #555555;'># … with 9,990 more rows, and 1 more variable: timeY </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span></span></code></pre>

</div>

Perhaps in a future post I'll be able to cover (1) making it pretty and (2) making it fast!

