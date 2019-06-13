---
title: 'Line-by-line, row-by-row...'
author: Dewey Dunnington
date: '2017-03-27'
slug: []
categories: []
tags: ["parsing", "R", "text files", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2017-03-27T15:19:48+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---



The [NatChem database](https://www.ec.gc.ca/natchem/default.asp?lang=En&n=90EDB4BC-1) from [Environment Canada](https://www.ec.gc.ca/) contains the best long-term atmospheric monitoring data that exists for Canada, similar to the National Atmospheric Deposition Program (NADP) in the US. Unlike the NADP, the distribution format associated with NatChem data is a hideous export format that looks like it was used by SAS at one point.

``` r
readLines("natchem_sample.CSV", n=6)
```

    ## [1] "*DATA EXCHANGE STANDARD VERSION,NATCHEM PRECIP 2003/01/17 (1.01),,,,,,,,,"                                                                                  
    ## [2] "*COMMENT,For information on this file please see the NAtChem web site http://www.ec.gc.ca/natchem/"                                                         
    ## [3] "*COMMENT,Network descriptions and links to home pages are provided on the NAtChem web site."                                                                
    ## [4] "*COMMENT,Data Originators or NAtChem Staff may occasionally revise data files. Users should download the latest version of each file before using the data."
    ## [5] "*COMMENT,The flags and comments provided with the original data have been mapped to the NAtChem standard flags."                                            
    ## [6] "*COMMENT,Please contact NAtChem if you want DES files with the original network flags and comments."

If an easy way to import this data to R exists, I can't find it. In particular, `read.csv()` produces ugly results, and using Excel to remove extraneous information is both time-consuming and results in significant data loss (since an Excel user is unlikely to keep other tables that may exist other than the data itself). So instead, with an eye towards including a driver for this data type in the [rclimateca package](https://cran.r-project.org/package=readr), I decided to look into line-by-line parsing in R.

### Reading files line-by-line in R

While other languages (Python in particular) make it easy to iterate through files by line, this strategy has never been popular in R. There is, in large part, no need to read a file line-by-line, in large part due to the excellent `read.csv()` and `read.delim()` functions (plus the [readr](https://cran.r-project.org/package=readr) package for even more). An exception to this is data distributed in non-standard formats, such as CSVs with lots of header information. The NatChem format probably contains the most header information that I have ever seen in a CSV (even compared with Environment Canada's historical climate data distribution format, which has a large number of extraneous rows containing location, parameter, and flag information), which means to automatically parse these files we need the line-by-line strategy.

For small files, it's possible to use `readLines()` with the filename as the first argument, then iterate through each line using a `for` loop (`readLines()` returns a character vector with one element per line). This strategy gets more difficult when the files get large, and is especially inefficient if most of the information in the file will be disregarded anyway. Still, it's incredibly easy, and worth demonstrating.

``` r
lines <- readLines("natchem_sample.CSV")
head(lines)
```

    ## [1] "*DATA EXCHANGE STANDARD VERSION,NATCHEM PRECIP 2003/01/17 (1.01),,,,,,,,,"                                                                                  
    ## [2] "*COMMENT,For information on this file please see the NAtChem web site http://www.ec.gc.ca/natchem/"                                                         
    ## [3] "*COMMENT,Network descriptions and links to home pages are provided on the NAtChem web site."                                                                
    ## [4] "*COMMENT,Data Originators or NAtChem Staff may occasionally revise data files. Users should download the latest version of each file before using the data."
    ## [5] "*COMMENT,The flags and comments provided with the original data have been mapped to the NAtChem standard flags."                                            
    ## [6] "*COMMENT,Please contact NAtChem if you want DES files with the original network flags and comments."

The more "Python-esque" method is also simple, but not intuitive to R users because it involves an object with a mutable state. Most objects in R are copied whenever they are modified, or more specifically, calling a function with an object as an argument almost never results in that object being modified in the calling environment. This is fairly useful in most cases, but reading a file is not one of those cases. Enter one of the few natively mutable objects in R: the "file connection".

``` r
connection <- file("natchem_sample.CSV")
open(connection)
for(i in 1:6) {
  print(readLines(connection, n=1))
}
```

    ## [1] "*DATA EXCHANGE STANDARD VERSION,NATCHEM PRECIP 2003/01/17 (1.01),,,,,,,,,"
    ## [1] "*COMMENT,For information on this file please see the NAtChem web site http://www.ec.gc.ca/natchem/"
    ## [1] "*COMMENT,Network descriptions and links to home pages are provided on the NAtChem web site."
    ## [1] "*COMMENT,Data Originators or NAtChem Staff may occasionally revise data files. Users should download the latest version of each file before using the data."
    ## [1] "*COMMENT,The flags and comments provided with the original data have been mapped to the NAtChem standard flags."
    ## [1] "*COMMENT,Please contact NAtChem if you want DES files with the original network flags and comments."

``` r
close(connection)
```

The strategy is fairly simple: open a "file connection" to the file, and call `readLines()` to read a line and advance the pointer. **Always `close()` the connection when you are finished!** If you don't, R will yell at you at some point telling you that you never closed the connection. Notice that the `connection` object is modified when passed to `open()`, `readLines()` and `close()`, whereas in "normal" R code you would have to do something like `connection <- open(connection)` to acheive a similar result. Language details aside, this approach avoids the possible danger of loading a huge file into memory by accident (although if the file does not have any line endings, this is still a problem).

So far the above strategy works if we know we have to read a fixed number of lines, but in most cases the number of lines in the file is unknown. After some experimentation, it seems that `readLines()` will return `character(0)` when there are no more lines in the file (not to be confused with an empty string `""`, which is an empty line). We can use this in conjunction with a `while` loop to loop through every line in the file.

``` r
connection <- file("natchem_sample.CSV")
open(connection)
line <- readLines(connection, n=1)
while(length(line) > 0) {
  # do something with each line
  # ...
  # read a new line
  line <- readLines(connection, n=1)
}
close(connection)
```

### Processing the lines

So far we can iterate through lines, but what's the point? In this case, we need to exctract specific information about the contents of the files. To this end, there are two (among others) useful functions: `scan()` and `grepl()`. The `scan()` function was built to parse delimited text, which covers most of the things that are read in a line-by-line strategy (such as NatChem).

``` r
connection <- file("natchem_sample.CSV")
open(connection)
first_line <- readLines(connection, n=1)
line1_elements <- scan(text=first_line, what = character(1), sep=",")
close(connection)

line1_elements
```

    ##  [1] "*DATA EXCHANGE STANDARD VERSION"  "NATCHEM PRECIP 2003/01/17 (1.01)"
    ##  [3] ""                                 ""                                
    ##  [5] ""                                 ""                                
    ##  [7] ""                                 ""                                
    ##  [9] ""                                 ""                                
    ## [11] ""

There are a number of arguments to `scan()` that control what it's looking for and how it will find it, although the only ones I've personally used are `quiet=TRUE` (which suppresses the message that reports how many items have been read) and `strip.white=TRUE` (which strips whitespace). Many of these are also options in `read.csv()`, although if you're making use of them it's a good sign that you should probably be using `read.csv()` or something similar to read your data.

The second thing that is useful is searching for specific text in a line (for example, a line that may suggest that table information exists in a specific loction). In the NatChem format, there are lines that read `*TABLE BEGINS` and `*TABLE ENDS` at the beginning and end of table data, respectively. Thus, we can use `grepl()` to search for lines that contain these strings to delineate where tables begin and end.

``` r
connection <- file("natchem_sample.CSV")

table_start <- integer(0)
table_end <- integer(0)

open(connection)
line <- readLines(connection, n=1)
line_number <- 1L
while(length(line) > 0) {
  # check for table begin/end
  if(grepl("*TABLE BEGINS", line, fixed = TRUE)) {
    table_start <- c(table_start, line_number)
  } else if(grepl("*TABLE ENDS", line, fixed = TRUE)) {
    table_end <- c(table_end, line_number)
  }
  
  # read a new line (and increment line number)
  line <- readLines(connection, n=1)
  line_number <- line_number + 1
}
close(connection)

rbind(table_start, table_end)
```

    ##             [,1] [,2] [,3] [,4] [,5]
    ## table_start   35   60   75   98  120
    ## table_end     51   65   85  101  189

It's worth noting that `grepl()` takes its arguments in reversed order to what you would expect based on other vectorized R functions (that is, `grepl("what you're looking for", where_to_look))`. By default, the search term in `grepl()` is a regular expression, which you can disable by using `fixed=TRUE`. Unless you actually want to use a [regular expression](https://en.wikipedia.org/wiki/Regular_expression), it's best to use `fixed=TRUE` since many common characters are reserved in regular expressions and may produce unexpected results. For a more consistent implementation of regular expression matching, see the [stringr](https://cran.r-project.org/package=stringr) package.

### Extracting the tables

Just extracting the start and end lines of the tables isn't particularly useful without the table name/column information data, which is also provided in NatChem files. These lines look like `*TABLE NAME,...` and `*TABLE COLUMN NAME,...,...,...`, respectively. Using these data, we can read a full specification of each table into a `list`.

``` r
connection <- file("natchem_sample.CSV")

# these will be updated as the file is read
table_start <- NA
table_end <- NA
table_name <- NA
table_columns <- NA

# this will contain the output
tables <- list()

open(connection)
line <- readLines(connection, n=1)
line_number <- 1L
while(length(line) > 0) {
  # check for table begin/end
  if(grepl("*TABLE BEGINS", line, fixed = TRUE)) {
    # update the table start line number
    table_start <- line_number
    
  } else if(grepl("*TABLE ENDS", line, fixed = TRUE)) {
    # update the table end line number
    table_end <- line_number
    
    # on table end, update 'tables' with a full specification
    tables[[length(tables)+1]] <- list(name=table_name, 
                                       columns=table_columns,
                                       start=table_start, 
                                       end=table_end)
    
  } else if(grepl("*TABLE NAME,", line, fixed = TRUE)) {
    # update the table name
    line_fields <- scan(text=line, sep=",", 
                        what = character(1), quiet = TRUE)
    table_name <- line_fields[2]
    
  } else if(grepl("*TABLE COLUMN NAME,", line, fixed = TRUE)) {
    # update the column names
    line_fields <- scan(text=line, sep=",", 
                        what = character(1), quiet = TRUE)
    table_columns <- line_fields[2:length(line_fields)]
  }
  
  # read a new line (and increment line number)
  line <- readLines(connection, n=1)
  line_number <- line_number + 1
}
close(connection)

tables[1]
```

    ## [[1]]
    ## [[1]]$name
    ## [1] "Network comments: office"
    ## 
    ## [[1]]$columns
    ##  [1] "Comment codes: office" "Description"          
    ##  [3] ""                      ""                     
    ##  [5] ""                      ""                     
    ##  [7] ""                      ""                     
    ##  [9] ""                      ""                     
    ## 
    ## [[1]]$start
    ## [1] 35
    ## 
    ## [[1]]$end
    ## [1] 51

Of course, there's still much room for improvement, but that's the gist of it. Overall, reading files line-by-line isn't usually what you want, but in my case of reading hundreds of NatChem files at a time, it is the most robust solution in a language that wasn't really built to handle it. The syntax needed to update variables without a fixed length is lacking in R, which makes writing code like the above awkward (in general it is terrible practice to use `c()` to update a vector, but if the output isn't of known length, there aren't any easy alternatives).

### Vectorized Solutions

There are some vectorized solutions to the above examples, that may be appropriate if the parsing is simple. For example, reading the line numbers of `*BEGIN TABLE` and `*END TABLE` is easy to do using `readLines()` and `grep()` (which is essentially `which(grepl(...))`).

``` r
lines <- readLines("natchem_sample.CSV")
rbind(grep("*TABLE BEGINS", lines, fixed = TRUE), 
      grep("*TABLE ENDS", lines, fixed = TRUE))
```

    ##      [,1] [,2] [,3] [,4] [,5]
    ## [1,]   35   60   75   98  120
    ## [2,]   51   65   85  101  189

Extracting more information gets more complicated, especially if some information is omitted. The above example breaks down very quickly if anything is malformed about the file, since the parsing will fail with an unhelpful error message if for some reason there is no `*TABLE ENDS` after table data.

### Performance

Normally looping in R is thought of as slow, but in this case, it's not as slow as you might expect. If we use `vapply()` to create a stripped-down version of the native `readLines()` and benchmark, it looks like the native `readLines()` is a little faster, but not enough to be noticable unless the files start to get huge (in which case a line-by-line strategy may end up faster due to reduced memory allocation). With variable-length output (i.e. using `c()` to create variable length output vectors), it's likely that looping will get progressively slower with longer files. Still, if there are only a few lines that need extracting, it may be worth it.

``` r
readLines_R <- function(csvfile, n=6) {
  connection <- file(csvfile)
  open(connection)
  lines <- vapply(1:n, function(i) readLines(connection, n=1), 
                  character(1))
  close(connection)
  return(lines)
}

library(microbenchmark)
microbenchmark(readLines("natchem_sample.CSV", n=6), 
               readLines_R("natchem_sample.CSV", n=6))
```

    ## Unit: microseconds
    ##                                      expr     min      lq      mean
    ##    readLines("natchem_sample.CSV", n = 6)  85.383  86.772  90.44636
    ##  readLines_R("natchem_sample.CSV", n = 6) 113.100 115.400 120.09061
    ##    median      uq     max neval
    ##   87.6335  89.716 180.586   100
    ##  116.5595 121.016 162.676   100

### Parsing NatChem

The full parsing of the NatChem format will be available soon though the [rclimateca](https://cran.r-project.org/package=rclimateca) package, along with (hopefully) an extractor for HYDAT hydrological data (which is, as you may have guessed, in a completely different format).

