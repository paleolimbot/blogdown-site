---
title: 'Summarising SQL Translation for multiple dbplyr backends'
author: Dewey Dunnington
date: '2019-04-09'
slug: []
categories: []
tags: ["dbplyr", "R", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2019-04-09T19:09:19+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

Inspired by <a href="http://twitter.com/gshotwell">@gshotwell</a>, I decided to have a look into bulk translating a ton of functions to SQL. <a href="https://db.rstudio.com/dplyr/">The dplyr system to translate R code to SQL</a> is really cool, but I’ve had some trouble in the past using it to write backend-agnostic code because of slightly different implementations of functions in different database backends.

<blockquote class="twitter-tweet" data-lang="en">

<p lang="en" dir="ltr">

Is there a reference document somewhere of which dplyr commands work on
various database backends?
<a href="https://twitter.com/hashtag/rstats?src=hash&amp;ref_src=twsrc%5Etfw">\#rstats</a>

</p>

— Gordon Shotwell (@gshotwell)
<a href="https://twitter.com/gshotwell/status/1115653121269796865?ref_src=twsrc%5Etfw">April
9,
2019</a>

</blockquote>

<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

I should also mention that Bob Rudis posted a solution to this as well that includes more backends (this post only considers the ones directly in <b>dbplyr</b>).

<blockquote class="twitter-tweet" data-lang="en">

<p lang="en" dir="ltr">

So still not as hard as I thought but did require some wrangling
<a href="https://t.co/YMSG2XdXR7">pic.twitter.com/YMSG2XdXR7</a>

</p>

— boB 🇷udis (@hrbrmstr)
<a href="https://twitter.com/hrbrmstr/status/1115685618426818561?ref_src=twsrc%5Etfw">April
9,
2019</a>

</blockquote>

<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>



As per my usual analysis, I’ll be using the **tidyverse**, with the addition of **dbplyr** since that’s what this post is about.

``` r
library(dbplyr)
library(tidyverse)
```

The first step for me was to figure out which translations are available. The `sql_translate_env()` function provides a custom object that contains the translations, with the `names()` attribute containing a translated function listing. That’s great, because to automatically make a list of translated function calls, we’ll need their names.

``` r
sql_translate_env(simulate_dbi())
```

    ## <sql_variant>
    ## scalar:    -, :, !, !=, (, [, [[, {, *, /, &, &&, %%, %>%, %in%,
    ## scalar:    ^, +, <, <=, ==, >, >=, |, ||, $, abs, acos, as_date,
    ## scalar:    as_datetime, as.character, as.Date, as.double,
    ## scalar:    as.integer, as.integer64, as.logical, as.numeric,
    ## scalar:    as.POSIXct, asin, atan, atan2, between, bitwAnd,
    ## scalar:    bitwNot, bitwOr, bitwShiftL, bitwShiftR, bitwXor, c,
    ## scalar:    case_when, ceil, ceiling, coalesce, cos, cosh, cot,
    ## scalar:    coth, day, desc, exp, floor, hour, if, if_else, ifelse,
    ## scalar:    is.na, is.null, log, log10, mday, minute, month, na_if,
    ## scalar:    nchar, now, paste, paste0, pmax, pmin, qday, round,
    ## scalar:    second, sign, sin, sinh, sql, sqrt, str_c, str_conv,
    ## scalar:    str_count, str_detect, str_dup, str_extract,
    ## scalar:    str_extract_all, str_flatten, str_glue, str_glue_data,
    ## scalar:    str_interp, str_length, str_locate, str_locate_all,
    ## scalar:    str_match, str_match_all, str_order, str_pad,
    ## scalar:    str_remove, str_remove_all, str_replace,
    ## scalar:    str_replace_all, str_replace_na, str_sort, str_split,
    ## scalar:    str_split_fixed, str_squish, str_sub, str_subset,
    ## scalar:    str_to_lower, str_to_title, str_to_upper, str_trim,
    ## scalar:    str_trunc, str_view, str_view_all, str_which, str_wrap,
    ## scalar:    substr, switch, tan, tanh, today, tolower, toupper,
    ## scalar:    trimws, wday, xor, yday, year
    ## aggregate: cume_dist, cummax, cummean, cummin, cumsum, dense_rank,
    ## aggregate: first, lag, last, lead, max, mean, median, min,
    ## aggregate: min_rank, n, n_distinct, nth, ntile, order_by,
    ## aggregate: percent_rank, quantile, rank, row_number, sum, var
    ## window:    cume_dist, cummax, cummean, cummin, cumsum, dense_rank,
    ## window:    first, lag, last, lead, max, mean, median, min,
    ## window:    min_rank, n, n_distinct, nth, ntile, order_by,
    ## window:    percent_rank, quantile, rank, row_number, sum, var

``` r
names(sql_translate_env(simulate_dbi())) %>% head()
```

    ## [1] "-"  ":"  "!"  "!=" "("  "["

To generate the translated SQL, I used the `translate_sql()` function. This can lead to a few endpoints, which include valid SQL, or various error messages.

``` r
translate_sql(abs(arg1))
```

    ## <SQL> ABS(`arg1`)

``` r
translate_sql(arg1 %in% arg2)
```

    ## <SQL> `arg1` IN `arg2`

``` r
translate_sql(str_match(arg1))
```

    ## Error: str_match() is not available in this SQL variant

``` r
translate_sql(abs(arg1, arg2))
```

    ## Error: Invalid number of args to SQL ABS. Expecting 1

To make this automated, we’ll need a way to test individual functions with arguments. The `translate_sql_()` function is designed for pre-quoted calls, which we can generate using the `call()` function.

``` r
translate_sql_(
  list(call("%in%", quote(arg1), quote(arg2))), 
  con = simulate_dbi()
)
```

    ## <SQL> `arg1` IN `arg2`

Finally, we need a function to (1) generate a test call with an arbitrary number of arguments, and (2) a function to turn that call into SQL. There is probably a more elegant way to do this than calling `do.call` on the `call` function, but I’m not sure what it is since these functions don’t to tidy evaluation (it’s possible that `translate_sql_()` handles tidy evaluation). The `arg1`, `arg2` ... pattern is a bit crude, but I couldn’t find a way to get the signatures of the functions for each SQL variant.

``` r
test_call <- function(fun_name, n_args = 1) {
  args <- map(seq_len(n_args), ~sym(paste0("arg", .x))) %>%
    map(enquote)
  do.call(call, c(list(fun_name), args))
}

test_translate <- function(call, con = simulate_dbi()) {
  translate_sql_(
    list(call),
    con = con
  )
}

test_translate(test_call("abs", 1))
```

    ## <SQL> ABS(`arg1`)

``` r
test_translate(test_call("%in%", 2))
```

    ## <SQL> `arg1` IN `arg2`

``` r
test_translate(test_call("avg", 3))
```

    ## <SQL> avg(`arg1`, `arg2`, `arg3`)

The whole point of this post is to look at the different SQL variants, and to do that we need connection objects to each of them. For testing, **dbplyr** provides the `simulate_*()` family of functions to generate fake connection objects. This is also a bit of clumsy code, but it does provide us with a tibble of connection objects and variant names.

``` r
sql_variants <- tibble(
  variant = getNamespace("dbplyr") %>%
    names() %>%
    str_subset("^simulate_") %>%
    str_remove("^simulate_"),
  test_connection = map(
    variant,
    ~getNamespace("dbplyr")[[paste0("simulate_", .x)]]()
  ),
  fun_name = map(test_connection, ~unique(names(sql_translate_env(.x)))),
)

sql_variants
```

    ## # A tibble: 11 x 3
    ##    variant  test_connection            fun_name   
    ##    <chr>    <list>                     <list>     
    ##  1 hive     <S3: Hive>                 <chr [164]>
    ##  2 mysql    <S3: MySQLConnection>      <chr [163]>
    ##  3 access   <S3: ACCESS>               <chr [167]>
    ##  4 sqlite   <S3: SQLiteConnection>     <chr [166]>
    ##  5 postgres <S3: PostgreSQLConnection> <chr [168]>
    ##  6 odbc     <S3: OdbcConnection>       <chr [164]>
    ##  7 dbi      <S3: TestConnection>       <chr [162]>
    ##  8 teradata <S3: Teradata>             <chr [166]>
    ##  9 impala   <S3: Impala>               <chr [164]>
    ## 10 oracle   <S3: Oracle>               <chr [164]>
    ## 11 mssql    <S3: Microsoft SQL Server> <chr [166]>

Now we need to make a very long list of function calls and (try to) translate them to SQL. As we saw above, we’ll need to be able to handle errors, warnings, and messages, in addition to capturing the result. I did this using the `safely()` and `quietly()` adverbs in the **purrr** package. I also use the `crossing()` function from the **tidyr**
package, which is kind of like `expand.grid()` but with data frames, in that it generates a new data frame with lots of combinations. In this case, I chose to evaluate each function with 0, 1, 2, 3, and 50 arguments, for every SQL variant, for every function. This works out to about 9,000 function calls and takes about a minute to complete.

``` r
translations <- crossing(
  tibble(
    n_args = c(0:3, 50)
  ),
  sql_variants
) %>%
  unnest(fun_name, .drop = FALSE) %>%
  mutate(
    call = map2(fun_name, n_args, test_call),
    translation = map2(
      call, test_connection, 
      quietly(safely(test_translate))
    ),
    r = map_chr(call, ~paste(format(.x), collapse = "")),
    sql = map_chr(translation, ~first(as.character(.x$result$result))),
    messages = map_chr(translation, ~paste(.x$messages, collapse = "; ") %>% na_if("")),
    warnings = map_chr(translation, ~paste(.x$warnings, collapse = "; ") %>% na_if("")),
    errors = map_chr(translation, ~first(as.character(.x$result$error)))
  )

translations %>%
  filter(!is.na(sql), n_args == 1) %>%
  select(variant, n_args, r, sql)
```

    ## # A tibble: 900 x 4
    ##    variant n_args r                  sql                      
    ##    <chr>    <dbl> <chr>              <chr>                    
    ##  1 hive         1 -arg1              -`arg1`                  
    ##  2 hive         1 !arg1              NOT(`arg1`)              
    ##  3 hive         1 (arg1)             (`arg1`)                 
    ##  4 hive         1 {    arg1}         (`arg1`)                 
    ##  5 hive         1 abs(arg1)          ABS(`arg1`)              
    ##  6 hive         1 acos(arg1)         ACOS(`arg1`)             
    ##  7 hive         1 as_date(arg1)      CAST(`arg1` AS DATE)     
    ##  8 hive         1 as_datetime(arg1)  CAST(`arg1` AS TIMESTAMP)
    ##  9 hive         1 as.character(arg1) CAST(`arg1` AS STRING)   
    ## 10 hive         1 as.Date(arg1)      CAST(`arg1` AS DATE)     
    ## # … with 890 more rows

Of course, this doesn’t take into account window or aggregation functions in their entirity, but it does a reasonable job at summarising how various functions are translated by `translate_sql()`. It isn’t a perfect summary, but below is my best attempt at capturing this in one graphic. In the future this could turn into a useful summary of how
things are translated and how consistent the results are, but for that it needs a bit more rigour. Enjoy\!

![](unnamed-chunk-8-1.png)<!-- -->


