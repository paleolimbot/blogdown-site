---
title: 'Abbreviating journal titles using BibTex & R'
author: Dewey Dunnington
date: '2017-11-04'
slug: []
categories: []
tags: ["Academia", "bibtex", "R", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2017-11-04T17:09:55+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

It seems that the tools for writing papers in R/RStudio keep getting better and better, to the point where it is rare that I have something I need to do to write a paper that happens outside of RStudio. One of these things is abbreviating journal names, because for whatever reason the checkbox that does this within <a href="http://zotero.org/">Zotero</a>'s BibTex export doesn't work particularly well. My way around this in the past was to wait until the article was about to be submited, and figure everything out in Microsoft Word at the very end. For my last submission (mostly as a break from fixing comma splices), I decided to automate the abbreviating of journals to save myself another manual step that, realistically, I was probably going to forget to do anyway.


There's a whole lot of journals out there, but luckily there are a bunch of sources that have collected journal abbreviations in a form that are more or less machine-readable. I used the [UBC Library Journal Abbreviation Page](http://woodward.library.ubc.ca/research-help/journal-abbreviations/), with a short and kind of messy web-scraping script. Whatever the source, you will end up with a data frame that looks like this:

``` r
abbrevs <- tribble(
  ~title,                                 ~abbrev,
  "Environmental Science and Technology", "Environ. Sci. Technol.",
  "Journal of Paleolimnology",            "J. Paleolimnol."
)
```

Given this list, I needed a function that could take a journal title and turn it into an abbreviation. This is problematic because my BibTex file contained a number of oddly formatted journal titles (in particular, there were a few ways of encoding the "&" in "Environmental Science & Technology", in addition to some inconsistent spacing/capitalization). To get around this, I built a function that is a kind of one-way hash of a journal title that turns it to lower case and strips non-numeric characters (as well as "and"), so that all the spellings of ES&T could be identified as such.

``` r
id_journal <- function(j) {
  # make lower case
  str_to_lower(j) %>% 
    # strip "and" symbols
    str_replace_all("\\band\\b", "") %>% 
    # remove non a-z characters
    str_replace_all("[^a-z]", "")
}

id_journal("Environmental Science & Technology")
```

    ## [1] "environmentalsciencetechnology"

``` r
id_journal("environmental science and technology")
```

    ## [1] "environmentalsciencetechnology"

Then, I built a function to abbreviate (a vector of) journal titles using the new `id_journal()` function and `match()`. This has the nice property that journals without an abbreviation become `NA`.

``` r
# make function to abbreviate any journal title
abbreviate_journal <- function(j) {
  matches <- match(id_journal(j), id_journal(abbrevs$title))
  set_names(abbrevs$abbrev[matches], j)
}

abbreviate_journal("Environmental Science & Technology")
```

    ## Environmental Science & Technology 
    ##           "Environ. Sci. Technol."

The more complicated bit comes in doing a search and replace on journal titles from the `.bib` file (see the end of this post for the `sample_bib` file). I used a regular expression to look for text that looked like `journal = {Journal of Paleolimnology}` within the `.bib` file to extract journal titles that needed abbreviating.

``` r
journal_strings <- sample_bib %>%
  # match journal strings
  str_match("journal\\s*=\\s*\\{(.*?)\\}") %>% 
  # convert to a tibble, change column names
  as_tibble() %>%
  select(journal_string = V2)

journal_strings %>%
  filter(!is.na(journal_string))
```

    ## # A tibble: 2 x 1
    ##                           journal_string
    ##                                    <chr>
    ## 1              Journal of Paleolimnology
    ## 2 "Environmental Science \\& Technology"

Given a list of journal titles, we can then use the `abbreviate_journal()` function to look up the abbreviation.

``` r
journal_abbrevs <- journal_strings %>%
  # abbreviate the journal using our function from above
  mutate(journal_abbrev = abbreviate_journal(journal_string)) 

journal_abbrevs %>%
  filter(!is.na(journal_string))
```

    ## # A tibble: 2 x 2
    ##                           journal_string         journal_abbrev
    ##                                    <chr>                  <chr>
    ## 1              Journal of Paleolimnology        J. Paleolimnol.
    ## 2 "Environmental Science \\& Technology" Environ. Sci. Technol.

Then, we can use `str_replace()` to do a vectorized search and replace, searching `sample_bib` (the original text, with one element per line) for the original journal title, replacing it with the journal abbreviation.

``` r
fixed_lines <- journal_abbrevs %>%
  # search the old title and replace the new title
  mutate(fixed_line = str_replace(sample_bib,
                                  fixed(journal_string), 
                                  journal_abbrev)) 

fixed_lines %>%
  filter(!is.na(journal_string)) %>%
  select(fixed_line)
```

    ## # A tibble: 2 x 1
    ##                                fixed_line
    ##                                     <chr>
    ## 1        "\tjournal = {J. Paleolimnol.},"
    ## 2 "\tjournal = {Environ. Sci. Technol.},"

The `fixed_line` column we just created actually has quite a few `NA` values, because `str_replace()` propogates missing values that are in the search or replace vector (and any line that didn't have a journal or had an abbreviation that wasn't found would generate this). We can replace any line that has an `NA` value with the original vector using `coalesce()`, which fills `NA` values from the first vector with values from the second.

``` r
final_lines <- fixed_lines %>%
  # where there was no journal or no abbreviation, we have NAs
  # which we can replace using coalesce()
  mutate(final_line = coalesce(fixed_line, sample_bib)) 
```

Finally, we can export the final vector of lines. For this last paper, I wrote a second `.bib` file ("bibliography\_abbreved.bib"), and refered to that in my RMarkdown file. That way, when I inevitably had to update the original file, I could re-abbreviate all the journals using this script.

``` r
final_lines %>%
  # print the result
  pull(final_line) %>% paste(collapse = "\n") %>% cat()
```


    @article{dunnington_geochemical_2016,
        title = {A geochemical perspective on the impact of development at {Alta} {Lake}, {British} {Columbia}, {Canada}},
        volume = {56},
        doi = {10.1007/s10933-016-9919-x},
        number = {4},
        journal = {J. Paleolimnol.},
        author = {Dunnington, Dewey W. and Spooner, Ian S. and White, Chris E. and Cornett, R. Jack and Williamson, Dave and Nelson, Mike},
        year = {2016},
        pages = {315-330}
    }

    @article{anderson_lake_2017,
        title = {Lake {Recovery} {Through} {Reduced} {Sulfate} {Deposition}: {A} {New} {Paradigm} for {Drinking} {Water} {Treatment}},
        volume = {51},
        doi = {10.1021/acs.est.6b04889},
        number = {3},
        journal = {Environ. Sci. Technol.},
        author = {Anderson, Lindsay E. and Krkošek, Wendy H. and Stoddart, Amina K. and Trueman, Benjamin F. and Gagnon, Graham A.},
        year = {2017},
        pages = {1414-1422}
    }

It seems surprising that I couldn't find a ready-to-go abbreviater out there, and the only thing I can think of as a reason why is that the official list of abbreviations is somehow copyrighted. It seems like there should be an additional field in the BibTex/CSL format to handle multiple journal titles for multiple situations (or maybe there is and is just not implemented in Zotero). In the meantime, this hack of a solution seems to do the trick...

(for reference, the original `.bib` file...)

    @article{dunnington_geochemical_2016,
        title = {A geochemical perspective on the impact of development at {Alta} {Lake}, {British} {Columbia}, {Canada}},
        volume = {56},
        doi = {10.1007/s10933-016-9919-x},
        number = {4},
        journal = {Journal of Paleolimnology},
        author = {Dunnington, Dewey W. and Spooner, Ian S. and White, Chris E. and Cornett, R. Jack and Williamson, Dave and Nelson, Mike},
        year = {2016},
        pages = {315-330}
    }

    @article{anderson_lake_2017,
        title = {Lake {Recovery} {Through} {Reduced} {Sulfate} {Deposition}: {A} {New} {Paradigm} for {Drinking} {Water} {Treatment}},
        volume = {51},
        doi = {10.1021/acs.est.6b04889},
        number = {3},
        journal = {Environmental Science \& Technology},
        author = {Anderson, Lindsay E. and Krkosek, Wendy H. and Stoddart, Amina K. and Trueman, Benjamin F. and Gagnon, Graham A.},
        year = {2017},
        pages = {1414-1422}
    }

