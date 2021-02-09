---
title: "Using R's cross-platform iconv wrapper from cpp11"
subtitle: ""
summary: ""
authors: []
tags: []
categories: []
date: 2021-02-07T20:37:02-04:00
lastmod: 2021-02-07T20:37:02-04:00
featured: false
draft: false
image:
  caption: ""
  focal_point: ""
  preview_only: false
projects: []
output: hugodown::md_document
rmd_hash: b5575bc6212438f5

---

<div class="highlight">

</div>

In some recent adventures parsing text embedded within binary files, I came across the need to correctly interpret input bytes from a file representing a character string. As a developer, you want to write software that protects users from ever having to deal with an encoding issue! I do a fair amount of (and like the challenge of) parsing old file formats that assumed system encoding, and in some cases I need to write (/enjoy writing and learning about) the parser in compiled code. So how does [`iconv()`](https://rdrr.io/r/base/iconv.html) work when you're trying to do this in C++?

The first principle is: always return a character vector with elements encoded as (and correctly marked as) UTF-8. In particular, Jim Hester has [written about this](https://www.jimhester.com/post/2020-08-20-best-os-for-r/#unicode-encodings) and [given an excellent overview in a talk about cpp11](https://www.jimhester.com/talk/2020-satrdays-cpp11/). As somebody who now spends 37.5 hours a week in Windows for work, I appreciate this more than I did before. Basically, R's default is to interpret the bytes of a string as system encoding, which for everything except Windows is UTF-8. In Windows, strings have to be correctly marked in order to be interpreted as UTF-8, and UTF-8 strings that are *not* marked will end up looking like this:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='c'>#&gt; [1] "QuÃ©bec"</span></code></pre>

</div>

In the recent talk about [cpp11](https://cpp11.r-lib.org/) I linked above, Jim Hester alludes to the idea that you should only deal with non UTF-8 encodings at the edges of your program. When reading user-supplied files, that's where we're at! I'll dig in with an example. I've taken the liberty of writing the great province of Québec's name [^1] to disk so that we have some files to work with:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>readr</span>::<span class='nf'><a href='https://readr.tidyverse.org/reference/read_file.html'>read_file</a></span>(<span class='s'>"qc.utf8.txt"</span>)
<span class='c'>#&gt; [1] "Québec"</span>
<span class='k'>readr</span>::<span class='nf'><a href='https://readr.tidyverse.org/reference/read_file.html'>read_file</a></span>(
  <span class='s'>"qc.windows1252.txt"</span>, 
  locale = <span class='k'>readr</span>::<span class='nf'><a href='https://readr.tidyverse.org/reference/locale.html'>locale</a></span>(encoding = <span class='s'>"windows-1252"</span>)
)
<span class='c'>#&gt; [1] "Québec"</span></code></pre>

</div>

The problem is that if you don't have a way to specify the input encoding, you get something like this:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>readr</span>::<span class='nf'><a href='https://readr.tidyverse.org/reference/read_file.html'>read_file</a></span>(<span class='s'>"qc.windows1252.txt"</span>)
<span class='c'>#&gt; [1] "Qu\xe9bec"</span></code></pre>

</div>

Or this:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='k'>readr</span>::<span class='nf'><a href='https://readr.tidyverse.org/reference/read_file.html'>read_file</a></span>(
  <span class='s'>"qc.utf8.txt"</span>, 
  locale = <span class='k'>readr</span>::<span class='nf'><a href='https://readr.tidyverse.org/reference/locale.html'>locale</a></span>(encoding = <span class='s'>"windows-1252"</span>)
)
<span class='c'>#&gt; [1] "QuÃ©bec"</span></code></pre>

</div>

To start off, I'll illustrate one way to read in some bytes from a file using cpp11's wrapper around C++:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'>#include <fstream>
#include <memory>
#include "cpp11.hpp"
using namespace cpp11;
namespace writable = cpp11::writable;

[[cpp11::register]]
std::string demo_read_file(std::string filename) {
  char buffer[1024];

  std::ifstream file; 
  file.open(filename, std::ifstream::binary);
  
  file.read(buffer, 1024);
  size_t n_read = file.gcount();
  file.close();
  
  return std::string(buffer, n_read);
}
</code></pre>

</div>

This function only reads the first 1024 bytes of the file, but this is ok for our purposes. Giving it a go on our files, we get the following:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>demo_read_file</span>(<span class='s'>"qc.utf8.txt"</span>)
<span class='c'>#&gt; [1] "Québec"</span>
<span class='nf'>demo_read_file</span>(<span class='s'>"qc.windows1252.txt"</span>)
<span class='c'>#&gt; [1] "Qu\xe9bec"</span></code></pre>

</div>

Lo and behold we get the weird output I foretold! This is because cpp11 marks anything that comes out of C++ as UTF-8, and the second file was not UTF-8 encoded:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/base/Encoding.html'>Encoding</a></span>(<span class='nf'>demo_read_file</span>(<span class='s'>"qc.utf8.txt"</span>))
<span class='c'>#&gt; [1] "UTF-8"</span>
<span class='nf'><a href='https://rdrr.io/r/base/Encoding.html'>Encoding</a></span>(<span class='nf'>demo_read_file</span>(<span class='s'>"qc.windows1252.txt"</span>))
<span class='c'>#&gt; [1] "UTF-8"</span></code></pre>

</div>

Enter iconv! In particular, the `Riconv()` function which is built in to R and accessible in C or C++ via the [`R_ext/Riconv.h` header](https://github.com/wch/r-source/blob/master/src/include/R_ext/Riconv.h). While you could attempt to link to a system library (that might have more encodings supported), using the built-in R one saves you from writing a configure script and the other complexities that arise when using a system library. Unfortunately, the headers don't give us much to go on:

``` c
void * Riconv_open (const char* tocode, const char* fromcode);
size_t Riconv (void * cd, const char **inbuf, size_t *inbytesleft,
           char  **outbuf, size_t *outbytesleft);
int Riconv_close (void * cd);
```

I am eternally grateful for [this post](https://blog.inventic.eu/2010/11/simple-iconv-libiconv-example/), which has to be one of the only readable examples of using [`iconv()`](https://rdrr.io/r/base/iconv.html) on the internet (my apologies if you have a good one that I missed). Basically, we need an output buffer that's big enough to hold the re-encoded string and to very carefully pass it to `Riconv()` [^2].

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'>#include <fstream>
#include <memory>
#include "cpp11.hpp"
using namespace cpp11;
namespace writable = cpp11::writable;

#include <R_ext/Riconv.h>

[[cpp11::register]]
std::string demo_read_file_enc(std::string filename, std::string encoding) {
  char buffer[1024];

  std::ifstream file; 
  file.open(filename, std::ifstream::in | std::ifstream::binary);
  
  file.read(buffer, 1024);
  size_t n_read = file.gcount();
  file.close();
  
  std::string str_source(buffer, n_read);
  
  void* iconv_handle = Riconv_open("UTF-8", encoding.c_str());
  if (iconv_handle == ((void*) -1)) {
    stop("Can't convert from '%s' to 'UTF-8'", encoding.c_str());
  }
  
  const char* in_buffer = str_source.c_str();
  char utf8_buffer[2048];
  char* utf8_buffer_mut = utf8_buffer;
  size_t in_bytes_left = n_read;
  size_t out_bytes_left = 2048;
  
  size_t result = Riconv(
    iconv_handle, 
    &in_buffer, &in_bytes_left,
    &utf8_buffer_mut, &out_bytes_left
  );
  
  Riconv_close(iconv_handle);
  
  if (result == ((size_t) -1) || (in_bytes_left != 0)) {
    stop("Failed to convert file contents to UTF-8");
  }
  
  return std::string(utf8_buffer, 2048 - out_bytes_left);
}
</code></pre>

</div>

The thing I missed the first 7 times I tried this was that `**outbuf` needs to be a separate pointer from `utf8_buffer` because it gets modified by `Riconv()`. Actually, everything except `inbuf` gets modified. Also, the error codes of `(void*) -1` and `(size_t) -1` I only got from reading the R source code for R's [`iconv()`](https://rdrr.io/r/base/iconv.html). Let's see if it worked!

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>demo_read_file_enc</span>(<span class='s'>"qc.utf8.txt"</span>, <span class='s'>"UTF-8"</span>)
<span class='c'>#&gt; [1] "Québec"</span>
<span class='nf'>demo_read_file_enc</span>(<span class='s'>"qc.windows1252.txt"</span>, <span class='s'>"windows-1252"</span>)
<span class='c'>#&gt; [1] "Québec"</span></code></pre>

</div>

The above example won't work for everything. In particular, I guessed that a buffer twice as big as the input would be enough to hold the output, which may or may not be true. Because the example did not call any C++ that could throw an exception between `Riconv_open()` and `Riconv_close()`, I didn't need to do anything fancy to manage the lifecycle of that handle. When I implemented this to [get the encoding right while reading DBF files](https://github.com/paleolimbot/shp), I used a C++ class with a deleter that called `Riconv_close()` to ensure it would not be forgotten about and leak memory.

[^1]: This is pretty close to exactly what inspired this: government-produced shapefiles generally have to support both French and English and require a some guessing about what encoding the computer generating the file was using that day.

[^2]: The degree of carefulness I exude when calling functions from other libraries is directly proportional to the number of [`*`](https://rdrr.io/r/base/Arithmetic.html) and [`&`](https://rdrr.io/r/base/Logic.html) symbols in the definition, and there are a lot of them here

