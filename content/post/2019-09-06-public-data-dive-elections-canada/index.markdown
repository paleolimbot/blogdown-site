---
title: "Public Data Dive: Canada's Elections"
author: Dewey Dunnington
date: '2019-09-06'
slug: public-data-dive-elections-canada
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2019-09-06T09:46:25-03:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---



Driving this week I heard an excellent piece on [the CBC's The Current](https://www.cbc.ca/radio/thecurrent) entitled [Set up to fail: Why women still don't win elections as often as men in Canada](https://ici.radio-canada.ca/info/2019/elections-federales/femmes-hommes-probabilites-vote-egalite-chateaux-forts/index-en.html). I love data science journalism, and the piece made me curious about the dataset, which the interviewee indicated was "downloaded from the parliament website".

The website in question is [here](https://lop.parl.ca/sites/ParlInfo/default/en_CA/ElectionsRidings/Elections), and it's a very cool summary from the Library of Parliament of every candidate who has ever run in a Federal election. Unfortunately it's using some kind of JavaScript to load, process, and display the data, so it's hard to web scrape (although possible using something like PhantomJS). When faced with this, I usually turn to Mozilla's "Network" tool, which looks for network requests from a page. I hit "refresh" and sure enough a 5-second download from a web API appeared.

It should be said that webscraping should be done responsibly (and legally!). I'm not an expert, but I checked the site's [robots.txt](https://lop.parl.ca/robots.txt) and the [Important Notices](https://lop.parl.ca/ImportantNotices-e.html) page to look for some provision that automated access was disallowed or discouraged. I didn't attempt to spoof my `User-Agent`, and I only queried the site once, using `curl::curl_download()`:


```r
curl::curl_download(
  "https://lop.parl.ca/ParlinfoWebApi/Parliament/GetCandidates",
  "candidates.xml"
)
```

The result is an XML file that looks something like this:

```xml
<ArrayOfElectionCandidateForWeb>
  <ElectionCandidateForWeb>
    <key>value</key>
    ...
  </ElectionCandidateForWeb>
  ...
</ArrayOfElectionCandidateForWeb>
```

Reading XML isn't quite as easy as JSON (or even HTML with the [rvest](http://rvest.tidyverse.org/) package), but the [xml2](https://xml2.r-lib.org/) package is quite good, and the simple structure of the XML is such that we can avoid having to learn XPATH to access its contents. Because the "key" is always the `xml_name()` of the node, and the value is always the `xml_text()` of the node, we can turn each `<ElectionCandidateForWeb>` node into a tibble using the following code:


```r
library(xml2)

read_candidate_node <- function(candidate_node) {
  children <- xml_children(candidate_node)
  values <- as.list(xml_text(children))
  names(values) <- xml_name(children)
  as_tibble(values)
}
```

The result of `xml_children()` is list-like, so we can use the [purrr](https://purrr.tidyverse.org/) functionals to apply `read_candidate_node()` along it:


```r
candidates_xml <- read_xml("candidates.xml")

candidates_raw <- candidates_xml %>%
  xml_children() %>%
  map_dfr(read_candidate_node)
```



The data is already clean, but we don't need all the columns, and because the [Conservative Party of Canada](https://en.wikipedia.org/wiki/Conservative_Party_of_Canada) is a fairly recent amalgamation of several conservative parties (including the Progressive Conservatives), to do any kind of analysis over time we need to sanitize the values. I'm also going to filter out elections that weren't general elections, restrict my analysis to the Liberal, Conservative (and Progressive Conservative), New Democratic, and Green parties (the [RadioCanada study](https://ici.radio-canada.ca/info/2019/elections-federales/femmes-hommes-probabilites-vote-egalite-chateaux-forts/index-en.html) includes an analysis of the Bloc Québécois, if you are interested).


```r
selected_parties <- c("Liberal", "Conservative", "New Democratic Party", "Green")

candidates <- candidates_raw %>%
  select(
    # information about the person
    PersonId, PersonLastFirstName, Gender,
    # information about the riding
    ConstituencyId,  ConstituencyEn, ProvinceEn,
    # information specific to the election
    ElectionId, ElectionDate, ParliamentNumber, IsGeneral,
    # information specific to each person + riding + election
    Votes, ResultLongEn, OtherResultLongEn,
    # information about the party
    PartyOrganizationId, PartyNameEn
  ) %>%
  rename_all(str_remove_all, "En|Long") %>%
  mutate_all(na_if, "") %>%
  mutate_at(vars(ends_with("Id"), Votes, ParliamentNumber), as.numeric) %>%
  mutate(
    ElectionDate = as.Date(ElectionDate),
    IsGeneral = IsGeneral == "true",
    PartyName = str_replace(
      PartyName, 
      "Progressive Conservative Party", 
      "Conservative Party of Canada"
    ) %>%
      str_remove(" Party of Canada")
  ) %>%
  filter(
    IsGeneral, 
    PartyName %in% selected_parties, 
    ElectionDate > as.Date("1920-01-01")
  ) %>%
  mutate(PartyName = factor(PartyName, levels = selected_parties))

candidates
```

```
## # A tibble: 21,248 x 15
##    PersonId PersonLastFirst… Gender ConstituencyId Constituency Province
##       <dbl> <chr>            <chr>           <dbl> <chr>        <chr>   
##  1     2417 Dussault, Josep… M                4796 Lévis        Quebec  
##  2     8009 Campbell, Colin… M                3160 Frontenac--… Ontario 
##  3     2644 McPhee, George … M               10165 Yorkton      Saskatc…
##  4     4935 Howe, Clarence … M                6628 Port Arthur  Ontario 
##  5        0 <NA>             M                 674 Athabaska    Alberta 
##  6        0 <NA>             F                8431 St. Antoine… Quebec  
##  7        0 <NA>             M                 808 Battle River Alberta 
##  8        0 <NA>             M               10006 Winnipeg No… Manitoba
##  9     4109 Robichaud, Loui… M                4131 Kent         New Bru…
## 10    16657 Maybank, Ralph   M               10014 Winnipeg So… Manitoba
## # … with 21,238 more rows, and 9 more variables: ElectionId <dbl>,
## #   ElectionDate <date>, ParliamentNumber <dbl>, IsGeneral <lgl>,
## #   Votes <dbl>, Result <chr>, OtherResult <chr>,
## #   PartyOrganizationId <dbl>, PartyName <fct>
```

Featuring prominently in the [RadioCanada study](https://ici.radio-canada.ca/info/2019/elections-federales/femmes-hommes-probabilites-vote-egalite-chateaux-forts/index-en.html) is the idea of "stronghold" ridings, or ridings that have consistently elected the same party for several elections. Because ridings change according to population distribution, the study matched ridings that changed geographically. A [historical riding list](https://lop.parl.ca/sites/ParlInfo/default/en_CA/ElectionsRidings/Ridings) is also available from the Library of Parliament website for those interested in matching up the ridings exactly, but as a quick substitute, I just used the name and province of the riding. To find ridings whose previous two elections had resulted in the same party being elected, I used a grouped mutate to calculate the vote percentage margin. Then I used a grouped mutate (after arranging each group by `ElectionDate`) plus `lag()` to compare previous values of `PartyName` and `VoteMargin`.


```r
strongholds <- candidates %>%
  
  # find out who won each election and by what percent of the vote
  group_by(ElectionId, ConstituencyId) %>%
  arrange(desc(Votes)) %>%
  mutate(
    VotePercent = Votes / sum(Votes) * 100,
    VoteMargin = VotePercent - lead(VotePercent, default = 0)
  ) %>%
  filter(VotePercent == max(VotePercent), Result == "Elected") %>%
  
  # look at the same constituency over time to determine "stronghold"
  # status
  group_by(Province, Constituency) %>%
  arrange(ElectionDate) %>%
  mutate(
    SamePartyVictory = lag(PartyName, 2) == lag(PartyName, 1),
    LargeVoteMargin = lag(VoteMargin, 1) >= 10 & lag(VoteMargin, 2) >= 10,
    WasStronghold = SamePartyVictory & LargeVoteMargin,
    StrongholdParty = if_else(WasStronghold, lag(PartyName, 1), PartyName[NA])
  ) %>%
  filter(!is.na(WasStronghold)) %>%
  select(Province, Constituency, ElectionDate, WasStronghold, StrongholdParty)

strongholds
```

```
## # A tibble: 4,710 x 5
## # Groups:   Province, Constituency [750]
##    Province       Constituency   ElectionDate WasStronghold StrongholdParty
##    <chr>          <chr>          <date>       <lgl>         <fct>          
##  1 Prince Edward… Queen's        1925-10-29   FALSE         <NA>           
##  2 Quebec         Témiscouata    1925-10-29   FALSE         <NA>           
##  3 Ontario        Ottawa (City … 1926-09-14   FALSE         <NA>           
##  4 Quebec         St. Denis      1926-09-14   TRUE          Liberal        
##  5 Quebec         Jacques Carti… 1926-09-14   TRUE          Liberal        
##  6 Quebec         Hochelaga      1926-09-14   TRUE          Liberal        
##  7 Quebec         Maisonneuve    1926-09-14   TRUE          Liberal        
##  8 Quebec         St. Mary       1926-09-14   TRUE          Liberal        
##  9 Quebec         St. James      1926-09-14   TRUE          Liberal        
## 10 Quebec         Laurier--Outr… 1926-09-14   TRUE          Liberal        
## # … with 4,700 more rows
```

This simple method of calculating "strongholds" isn't as robust as Radio Canada's, whose method was able to assess the stronghold status of many more ridings. My quick-and-dirty method probably has a bias towards rural ridings whose name might be less likely to change. Still, it allows us to continue with Radio Canada's analysis (knowing that our results might reflect a different population of candidates).

One of the first items in the story is that there is an increasing number of woman candidates over time, and that this is true for all major political parties. This is a classic `group_by()` and `summarise()` on `candidates`, with a grouped mutate to calculate the proportions:


```r
candidates_by_gender <- candidates %>%
  group_by(ElectionDate, Gender) %>%
  summarise(n = n()) %>%
  group_by(ElectionDate) %>%
  mutate(prop = n / sum(n))

candidates_by_gender
```

```
## # A tibble: 58 x 4
## # Groups:   ElectionDate [29]
##    ElectionDate Gender     n    prop
##    <date>       <chr>  <int>   <dbl>
##  1 1921-12-06   F          1 0.00490
##  2 1921-12-06   M        203 0.995  
##  3 1925-10-29   M        216 1      
##  4 1926-09-14   F          1 0.00495
##  5 1926-09-14   M        201 0.995  
##  6 1930-07-28   F          3 0.0133 
##  7 1930-07-28   M        222 0.987  
##  8 1935-10-14   F          1 0.00408
##  9 1935-10-14   M        244 0.996  
## 10 1940-03-26   M        243 1      
## # … with 48 more rows
```


```r
candidates_by_gender_by_party <- candidates %>%
  group_by(ElectionDate, PartyName, Gender) %>%
  summarise(n = n()) %>%
  group_by(ElectionDate, PartyName) %>%
  mutate(prop = n / sum(n))

candidates_by_gender_by_party
```

```
## # A tibble: 161 x 5
## # Groups:   ElectionDate, PartyName [81]
##    ElectionDate PartyName Gender     n    prop
##    <date>       <fct>     <chr>  <int>   <dbl>
##  1 1921-12-06   Liberal   F          1 0.00490
##  2 1921-12-06   Liberal   M        203 0.995  
##  3 1925-10-29   Liberal   M        216 1      
##  4 1926-09-14   Liberal   F          1 0.00495
##  5 1926-09-14   Liberal   M        201 0.995  
##  6 1930-07-28   Liberal   F          3 0.0133 
##  7 1930-07-28   Liberal   M        222 0.987  
##  8 1935-10-14   Liberal   F          1 0.00408
##  9 1935-10-14   Liberal   M        244 0.996  
## 10 1940-03-26   Liberal   M        242 1      
## # … with 151 more rows
```

<img src="unnamed-chunk-9-1.png" width="672" />

By this analysis it looks like the NDP recruits woman candidates at a higher-than-average proportion, while the Conservative parties have historically recruited at below-average levels. This is consistent with Radio Canada's analysis, which only covered the last three elections.

To crunch the numbers by stronghold, we need to assign a column with the riding type. Based on our "stronghold" metric, we can detect when (1) a candidate is running in a riding they are likely to win, (2) when a candidate is running in a riding that someone else is likely to win, (3) when the riding could elect any of the candidates, and (4) the stronghold status of the riding couldn't be determined (an `NA` value for `WasStronghold`). For this analysis I'm going to ditch the ridings that couldn't be determined, which was anywhere between 1/2 and 3/4 of the ridings, depending on the election (for comparison, Radio Canada's much better method was able to match 95% of ridings between 2015 and the present districts).


```r
woman_candidates_by_stronghold <- candidates %>%
  left_join(strongholds, by = c("Constituency", "Province", "ElectionDate")) %>%
  mutate(
    StrongholdStatus = case_when(
      WasStronghold & StrongholdParty == PartyName ~ "Easy-to-win",
      WasStronghold & StrongholdParty != PartyName ~ "Hard-to-win",
      is.na(WasStronghold) ~ NA_character_,
      TRUE ~ "Toss-up"
    )
  ) %>%
  filter(!is.na(StrongholdStatus)) %>%
  group_by(ElectionDate, StrongholdStatus, Gender) %>%
  summarise(n = n()) %>%
  group_by(ElectionDate, Gender) %>%
  mutate(prop = n / sum(n))

woman_candidates_by_stronghold
```

```
## # A tibble: 143 x 5
## # Groups:   ElectionDate, Gender [52]
##    ElectionDate StrongholdStatus Gender     n   prop
##    <date>       <chr>            <chr>  <int>  <dbl>
##  1 1925-10-29   Toss-up          M          3 1     
##  2 1926-09-14   Easy-to-win      M         59 0.922 
##  3 1926-09-14   Toss-up          M          5 0.0781
##  4 1930-07-28   Easy-to-win      M         69 0.972 
##  5 1930-07-28   Toss-up          M          2 0.0282
##  6 1935-10-14   Easy-to-win      M         70 0.946 
##  7 1935-10-14   Toss-up          M          4 0.0541
##  8 1940-03-26   Easy-to-win      M         85 0.924 
##  9 1940-03-26   Toss-up          M          7 0.0761
## 10 1945-06-11   Easy-to-win      M        127 0.531 
## # … with 133 more rows
```

<img src="unnamed-chunk-11-1.png" width="672" />

In Radio Canada's analysis, the percentage of women candidates who were placed in easy-to-win ridings was around 23%...in this analysis, it is more like 10% (a much more bleak picture for women candidates), probably because I wasn't able to detect the stronghold-or-not status of most ridings. The "set up to fail" headline of the article likely refers to the 25-50% of women candidates who are placed in a riding where they probably aren't going to win (the dark purple are of the graphic).
