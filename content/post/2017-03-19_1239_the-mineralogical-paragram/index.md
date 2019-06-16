---
title: 'The Mineralogical Paragram'
author: Dewey Dunnington
date: '2017-03-19'
slug: []
categories: []
tags: ["General", "geology", "R"]
subtitle: ''
summary: ''
authors: []
lastmod: '2017-03-19T20:26:15+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
aliases: [/archives/1239]
---



Matt Hall from [Agile Geoscience](https://agilescientific.com/) recently wrote a [post](https://agilescientific.com/blog/2017/3/16/the-quick-green-forsterite) on the problem of finding the shortest possible pangram (sentence containing all letters in the alphabet) using only [mineral names](https://github.com/softwareunderground/undersampledradio/blob/master/data/IMA_mineral_names.txt). The post goes into the details on the [set cover problem](https://en.wikipedia.org/wiki/Set_cover_problem), of which assembling a pangram from a list of minerals is one example. Matt's best solution, "quartz kvanefjeldite abswurmbachite pyroxmangite", contained 45 characters and four mineral names, and its timing coincided with a weekend where my other options were to proofread a 50-page report or do my taxes. Trying to beat 45 characters seemed using weighted random sampling seemed like a much better use of a Saturday afternoon.

One approach (see [Agile's notebook](https://github.com/softwareunderground/undersampledradio/blob/master/Mineral_name_pangrams.ipynb)) would be to iterate through all possible combinations of mineral names until a pangram is found. This assumes the number of mineral names needed to form the shortest pangram is known, and that the search can be performed in such an order that the shortest combinations float to the top of the list, since iterating through every combination of 4 mineral names is a decades-long endeavour (and longer if 5 names are required).

Another approach would be to assemble pangram randomly on a name-by-name basis, keeping only the shortest. One way to do this might be to pick minerals that are the most probable to result in a short name that covers the whole alphabet. This might mean picking the first mineral name that is short, doesn't repeat letters, and contains less frequent letters (such as 'quartz'). I've done this in R (with packages dplyr and ggplot2), since my random sampling in Python is a bit rusty. First, we need to load the data.

``` r
# load the mineral names, letters of the alphabet
minnames <- readLines("mineralnames.txt")
chars <- strsplit("abcdefghijklmnopqrstuvwxyz", "")[[1]]
```

Second, we need to define a 'coverage' function that returns the number of unique letters based on the input.

``` r
alphacoverage <- function(chars) {
  # strip anything that isn't a-z from the lowercase input
  splits <- strsplit(gsub("[^a-z]", "", tolower(chars)), "")
  vapply(splits, function(x) length(unique(x)), integer(1))
}

alphacoverage("the Quick brown fox jumps over the lazy doG.")
```

    ## [1] 26

To use weighted random sampling, we need to quantify a couple of parameters that could be useful for probability weighting.

``` r
# create a data frame with information about each mineral
minerals <- data.frame(name=minnames, 
                       coverage=alphacoverage(minnames), 
                       stringsAsFactors = FALSE)

# create a matrix of letter coverage
lettercoverage <- vapply(chars, 
                         function(char) grepl(char, minnames), 
                         logical(3912))
colnames(lettercoverage) <- chars
rownames(lettercoverage) <- minnames

# calculate a letter 'score', with the rarest letters the highest
lettersums <- colSums(lettercoverage)
letterscore <- max(lettersums) / lettersums

# plot letter scores
data.frame(letter=chars, score=letterscore) %>%
  ggplot(aes(letter, score)) + geom_bar(stat="identity")
```


<figure><img src="unnamed-chunk-3-1.png"/><figcaption>New game: mineralogical scrabble. Fun for the whole family! Your friends will all love you.</figcaption></figure>



For quantifying good words to include, the idea of "word score", "coverage density", and "score density" (or word score for unique letters divided by string length) might be useful in weighting random sampling:

``` r
# coverage density: coverage / length
minerals$coverage_density <- minerals$coverage / nchar(minerals$name)
# calculate scores for minerals: unique letters times the 'usefulness' of the letters
minerals$score <- vapply(minnames, function(name) {
  sum(letterscore[unique(strsplit(gsub("[^a-z]", 
                                       "", tolower(name)), 
                                  "")[[1]])])
}, numeric(1))
# calculate score density for minerals: score / length of word
minerals$score_density <- minerals$score / nchar(minerals$name)
head(arrange(minerals, desc(score_density)))
```

| name        |  coverage|  coverage\_density|   score|  score\_density|
|:------------|---------:|------------------:|-------:|---------------:|
| quartz      |         6|               1.00|  121.42|           20.24|
| naquite     |         7|               1.00|  105.38|           15.05|
| taseqite    |         6|               0.75|  101.83|           12.73|
| queitite    |         5|               0.62|  101.69|           12.71|
| quijarroite |         9|               0.82|  139.29|           12.66|
| qusongite   |         9|               1.00|  113.88|           12.65|

Unsurprisingly, 'quartz' tops the list by far (has a q and a z and repeats no letters). A function to describe the dissimilarity in letter coverage between two mineral names might also be useful:

``` r
name_dissimilarity <- function(name1, name2) {
  letters1 <- strsplit(name1, "")[[1]]
  letters2 <- strsplit(name2, "")[[1]]
  sum(xor(chars %in% letters1, chars %in% letters2))
}
# the length of the symmetric difference:
# "r", "z", "n", "i", "e"
name_dissimilarity("quartz", "naquite") 
```

    ## [1] 5

Finally, we need a function to assemble an arbitrary number of mineral names to form a pangram. The first word we'll choose based on the "score density" we calculated above, and after that, pick each mineral name (up to 20) based on the mineral names that cover the greatest number of missing letters, randomly sampling ties based on the length of the mineral name.

``` r
assemble_pangram <- function(maxwords=20, seed=NULL) {
  if(is.null(seed)) {
    # randomly pick the first word weighted by score density
    name <- minnames[sample(length(minnames), size=1, 
                            prob=minerals$score_density)]
  } else {
    # use the seed as the first name(s)
    name <- seed
  }
  
  words <- length(name)
  while(words < maxwords) {
    # only use mineral names that aren't already included
    minnames2 <- minnames[!(minnames %in% name)]
    # calculate coverage dissimilarity
    diffs <- mapply(name_dissimilarity, paste(name, collapse=""),
                    minnames2)
    # select only those names with maximum dissimilarity
    minnames2 <- minnames2[diffs == max(diffs)]
    # add new name to the list, randomly picking ties weighted by 2/n chars
    chars <- nchar(minnames2)
    name <- c(name, minnames2[sample(length(minnames2), size=1, 
                                     prob=2/(chars/max(chars)))])
    # if it covers all 26 letters, return the names
    if(alphacoverage(paste(name, collapse = " ")) == 26) return(name)
    words <- words + 1
  }
  # if nothing after maxwords, return NULL
  NULL
}
assemble_paragram()
```

    ## [1] "grechishchevite" "hexamolybdenum"  "witzkeite"       "jeppeite"       
    ## [5] "tin"             "hafnon"          "ice"             "queitite"

The result, of course, isn't always short, but *is* always a pangram. Sample enough times (40000, for the purposes of this post), and some short names should start to pop up (I know, using `plyr` to loop and the superassignment operator to modify isn't the best form, but it displays a helpful progress bar...).

``` r
set.seed(1500) # for replicability
shortest <- character(0)
plyr::a_ply(1:40000, 1, .fun=function(i) { # about 8 hours
  result <- paste(assemble_pangram(), collapse=" ")
  shortest <- shortest[!is.na(shortest)]
  if(!is.null(result) && !(result %in% shortest)) {
    # keep the 100 best at all times
    shortest <- c(result, shortest[!is.na(shortest)])
    shortest <<- shortest[order(nchar(gsub(" ", "", shortest)), 
                                na.last = TRUE)][1:100]
  }
}, .progress = "time")
# write results to disk
write(shortest, "panagram_psample.txt")
# display results
shortest[1:10]
```

    ##  [1] "johnwalkite gypsum quartz fedotovite ice blixite" 
    ##  [2] "arhbarite gypsum kvanefjeldite wilcoxite quartz"  
    ##  [3] "makovickyite sulphur xifengite jedwabite quartz"  
    ##  [4] "jeppeite hexamolybdenum wicksite fivegite quartz" 
    ##  [5] "kvanefjeldite gypsum schorl tewite blixite quartz"
    ##  [6] "pyroxmangite fukuchilite jedwabite sveite quartz" 
    ##  [7] "fukuchilite pyroxmangite jedwabite ivsite quartz" 
    ##  [8] "fukuchilite pyroxmangite jedwabite sveite quartz" 
    ##  [9] "wicksite hexamolybdenum fivegite quartz jeppeite" 
    ## [10] "jeppeite hexamolybdenum wicksite quartz fivegite"

It looks as though the [best I can get in 8 hours](panagram_psample.txt) (overnight) is 43 characters, which is a tie between the first three listed above. The solution "makovickyite sulphur xifengite jedwabite quartz" also popped up in a previous trial run of the above, which suggests this list is fairly stable. Interestingly, even though quartz and gypsum show up in nearly all the solutions, using them as the first one (or two) mineral name(s) instead of randomly selecting it inhibits a random search of the solution space, since fewer options are considered for random selection. That said, many names show up more frequently than others in the top 100, and they aren't the same as the order of the "score density" used to weight the sampling of the first mineral name.

``` r
names <- unlist(strsplit(shortest, " "), use.names = FALSE)
namesdf <- data.frame(name=names, stringsAsFactors = FALSE) %>%
  group_by(name) %>%
  summarise(count=length(name)) %>%
  filter(count > 2) %>%
  arrange(desc(count))

# arrange names
namesdf$name <- factor(namesdf$name, levels=rev(namesdf$name))

ggplot(namesdf, aes(name, count)) + 
  geom_bar(stat="identity") +
  coord_flip()
```

![](unnamed-chunk-10-1.png)

A few ideas for improving the search:

* Removing minerals with duplicated lettersets might speed things up. A cursory examination of `paste(sort(unique(x)), collapse="")` from the output of `strsplit()` suggests that this would reduce the number of minerals to sift through each step from 3912 to 3187. 
* Learn from the past: use mineral names common in previously short pangram to inform subsequent attempts.
* Expand random search of names for names other than the first. Once the first name is picked, there is not much room for random search, since the next name is the name that adds the most letters to the result. There may be a better metric to weight than purely name dissimilarity.

Perhaps when I'm done my Ph.D. thesis, proofreading all the reports, and finished my taxes, some time will pop up to solve this pressing issue once and for all.
