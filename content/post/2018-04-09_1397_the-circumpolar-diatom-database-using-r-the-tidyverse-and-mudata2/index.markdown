---
title: 'The Circumpolar Diatom Database using R, the tidyverse, and mudata2'
author: Dewey Dunnington
date: '2018-04-09'
slug: []
categories: []
tags: ["Academia", "Circumpolar Diatom Database", "mudata", "R", "tidyverse", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2018-04-08T21:13:57+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

It is an exciting time for the integration of limnological and paleolimnological datasets. The <a href="https://www.waterqualitydata.us/">National (US) Water Quality Monitoring Council Water Quality Portal</a> has just made decades of state and federal water quality measurements available, the <a href="https://www.ncdc.noaa.gov/paleo-search/study/21171">Pages2k project</a> has collected hundreds of temperature proxy records for the last 2000 (ish) years, and the <a href="https://www.neotomadb.org/">Neotoma</a> database provides access to a large number of paleoecological datasets. For a final project in a course last fall, I chose to analyze the <a href="http://www.cen.ulaval.ca/CDD/About.aspx">Circumpolar Diatom Database (CDD)</a>, which is a collection of water chemistry and diatom assemblage data hosted by the Aquatic Paleoecology Laboratory at ULaval. In this post, we will (1) download and clean the data and metadata from the CDD website, and (2) use the <a href="https://cran.r-project.org/package=mudata2"><strong>mudata2</strong></a> package to extract some data. Part 2 is more exciting, so I'll put that first...



### The point of it all

This post takes a single webpage, and uses it to create a `mudata()` object. The [(Mostly) Universal Data](http://www.facetsjournal.com/doi/10.1139/facets-2017-0026) format is a format and R package that lets you store metadata (i.e., location, parameter, and dataset information) and data in a way that is easy to read, write, and subset. It's a good way to store clean data that will get used later, or distribute data for others to use. With it, we can do things like this:

``` r
library(mudata2)
cdd <- read_mudata("cdd.mudata")
cdd %>%
  select_datasets(ALERT, BYL) %>%
  filter_params(param_type == "diatom_count") %>%
  filter_data(value > 5)
```

    ## A mudata object aligned along <none>
    ##   distinct_datasets():  "ALERT", "BYL"
    ##   distinct_locations(): "A-A", "A-AA" ... and 35 more
    ##   distinct_params():    "ACsubato", "ACsuchla" ... and 56 more
    ##   src_tbls():           "data", "locations" ... and 3 more
    ## 
    ## tbl_data() %>% head():
    ## # A tibble: 6 x 5
    ##   dataset location param                                 value unit       
    ##   <chr>   <chr>    <chr>                                 <dbl> <chr>      
    ## 1 BYL     BI-02    Navicula rynchocephala                 6.82 % rel abund
    ## 2 BYL     BI-02    Staurosira construens var. subrotunda 17.3  % rel abund
    ## 3 BYL     BI-02    PIbalf                                 8.40 % rel abund
    ## 4 BYL     BI-02    SApinnat                              47.0  % rel abund
    ## 5 BYL     BI-23    Undetermined diatom [CDD]              6.76 % rel abund
    ## 6 BYL     BI-23    ACsuchla                               8.75 % rel abund

The resulting object contains all the information of the original object, but only for diatom data from the ALERT and BYL datasets, where relative abundance is greater than 5%. Similarly, one could find all the locations where silica was measured:

``` r
cdd %>%
  select_params(SiO2)
```

    ## A mudata object aligned along <none>
    ##   distinct_datasets():  "ALERT", "BYL" ... and 10 more
    ##   distinct_locations(): "A-A", "A-AA" ... and 402 more
    ##   distinct_params():    "SiO2"
    ##   src_tbls():           "data", "locations" ... and 3 more
    ## 
    ## tbl_data() %>% head():
    ## # A tibble: 6 x 5
    ##   dataset location param  value unit 
    ##   <chr>   <chr>    <chr>  <dbl> <chr>
    ## 1 BYL     BI-01    SiO2  0.0600 mg/L 
    ## 2 BYL     BI-02    SiO2  0.0700 mg/L 
    ## 3 BYL     BI-03    SiO2  0.270  mg/L 
    ## 4 BYL     BI-04    SiO2  0.660  mg/L 
    ## 5 BYL     BI-05    SiO2  1.44   mg/L 
    ## 6 BYL     BI-06    SiO2  1.02   mg/L

To get data out of the object, one can use the `tbl_data()` (or `tbl_data_wide()` for the classic parameter-wide version), `tbl_params()`, `tbl_datasets()` and `tbl_locations()` functions. Where on earth is the CDD, anyway?

``` r
cdd %>%
  tbl_locations() %>%
  ggplot(aes(x = long_w, y = lat_n, col = dataset)) +
  annotation_map(map_data("world"), fill = "white", col = "grey50") +
  geom_point() +
  coord_map("ortho") +
  theme(panel.background = element_rect(fill = "lightblue"))
```

![](unnamed-chunk-3-1.png)

For some good old-fashioned relative abundance diagrams, we can use `tbl_data()` to extract ggplot-friendly data (in this case, only plotting diatom abundance for diatoms with &gt;25% relative abundance somewhere).

``` r
cdd %>%
  select_datasets(ALERT) %>%
  filter_params(param_type == "diatom_count") %>%
  tbl_data() %>%
  group_by(param) %>%
  filter(any(value > 25)) %>%
  ungroup() %>%
  ggplot(aes(x = location, y = value)) +
  geom_col() +
  facet_grid(~param, space = "free_x", scales = "free_x") +
  coord_flip()
```

![](unnamed-chunk-4-1.png)

Convenient, right!? To get there, however, there is a long road of data cleaning ahead...

### Cleaning the data

Welcome to the data cleaning section! It is a story of intrigue, excitement, webscraping, and mildly complicated regular expressions. This section of the post is for those who are somewhat familiar with [data manipulation](http://r4ds.had.co.nz/transform.html) and [data tidying](http://r4ds.had.co.nz/tidy-data.html) using the [tidyverse](https://www.tidyverse.org/), and are looking to practice on a real-world dataset.

In this post I'll use the **tidyverse** core packages to do the hard work, the **lubridate** package to do some date parsing, the **curl** package to download files, the **rvest** package to extract data from web pages, the **readxl** package to read the spreadsheets that contain the data, and the **mudata2** package to organize the cleaned data at the end.

``` r
library(tidyverse)
```

I'll also use the `rename_friendly()` function below to make column names from the wild (in this case, Excel files that other people have created) easier to type in R. Essentially, it takes the current column names, makes them lowercase, and replaces any non-alpha-numeric character with an underscore. I promise this is useful...

``` r
rename_friendly <- function(df) {
  names(df) <- names(df) %>%
    str_to_lower() %>%
    str_replace_all("[^a-z0-9-_]+", "_") %>%
    str_remove("^_") %>%
    str_remove("_$") %>%
    tidy_names()
  df
}
```

### Extracting the dataset information

The CDD is one of the more accessible datasets on the web, in that the entire dataset is available for download, and the metadata is included on the website (notably in the [datasets table](http://www.cen.ulaval.ca/CDD/DatasetList.aspx)). We *could* copy and paste the table into a spreadsheet and then do some modifying, but that would be no fun. Instead, we will use the **rvest** package to extract the relevant information about each dataset from the table. Below, the page HTML is read using `read_html()`, and the tables are extracted using `html_table()` (the datasets table is the first one on the page, hence the `[[1]]`).

``` r
library(rvest)
# scrape datasets info from datasets page
datasets_page_url <- "http://www.cen.ulaval.ca/CDD/DatasetList.aspx"
datasets_page <- read_html(datasets_page_url)

datasets_table <- html_table(datasets_page)[[1]] %>%
  rename_friendly() %>%
  select(-data)
```

The datasets table is great for display, but in R we will need that information in a machine-understandable format. For example, the range of visit dates is a bit of a mess as extracted by `html_table()`:

``` r
datasets_table %>%
  select(dataset_code, visit_date) %>%
  head()
```

| dataset\_code | visit\_date                          |
|:--------------|:-------------------------------------|
| BYL           | June 3, 2005to August 5, 2006        |
| SAL           | April 1st, 2002to September 30, 2004 |
| SI            | July 12, 2004to July 18, 2004        |
| ALERT         | July 24, 2000to August 7, 2000       |
| MB            | July 12, 1999to July 21, 1999        |
| ABK           | August 15, 1997to September 7, 1997  |

In R, these are more useful as two columns of `Date` objects: `visit_date_start` and `visit_date_end`. The strategy I used was to use the `separate()` function to split the `visit_date` column using the text `"to"`, and then use the `mdy()` (month, date, year) function in the **lubridate** package to make them `Date` objects.

``` r
datasets_table <- datasets_table %>%
  separate(
    visit_date, 
    into = c("visit_date_start", "visit_date_end"), 
    sep = "to"
  ) %>%
  mutate(
    visit_date_start = lubridate::mdy(visit_date_start),
    visit_date_end = lubridate::mdy(visit_date_end)
  )

datasets_table %>%
  select(dataset_code, visit_date_start, visit_date_end) %>%
  head()
```

| dataset\_code | visit\_date\_start | visit\_date\_end |
|:--------------|:-------------------|:-----------------|
| BYL           | 2005-06-03         | 2006-08-05       |
| SAL           | 2002-04-01         | 2004-09-30       |
| SI            | 2004-07-12         | 2004-07-18       |
| ALERT         | 2000-07-24         | 2000-08-07       |
| MB            | 1999-07-12         | 1999-07-21       |
| ABK           | 1997-08-15         | 1997-09-07       |

The second column that is readable to humans but perhaps less useful in R is the `coordinates` column.

``` r
datasets_table %>%
  select(dataset_code, coordinates) %>%
  head()
```

| dataset\_code | coordinates                                   |
|:--------------|:----------------------------------------------|
| BYL           | LAT: 72.51° to 73.12°LONG: -79.25° to -80.08° |
| SAL           | LAT: 60.86° to 62.18°LONG: -69.56° to -75.72° |
| SI            | LAT: 64.21° to 65.21°LONG: -82.52° to -84.2°  |
| ALERT         | LAT: NA° to NA°LONG: NA° to NA°               |
| MB            | LAT: NA° to NA°LONG: NA° to NA°               |
| ABK           | LAT: 67.07° to 68.48°LONG: 23.52° to 17.67°   |

This is a little more complicated to parse, but each string is in the form `"(LAT or LON): (a number or NA)° to (a number or NA)°"`. Because the text is structured, we can use a regular expression and the `extract()` function to extract the numbers. Then, we can apply the `as.numeric()` function to the numbers we just extracted.

``` r
datasets_table <- datasets_table %>%
  extract(
    coordinates, 
    into = c("lat_min", "lat_max", "lon_min", "lon_max"),
    regex = "LAT: ([0-9.-]+|NA)° to ([0-9.-]+|NA)°LONG: ([0-9.-]+|NA)° to ([0-9.-]+|NA)°"
  ) %>%
  mutate_at(vars(lat_min, lat_max, lon_min, lon_max), as.numeric) 

datasets_table %>%
  select(dataset_code, lat_min, lat_max, lon_min, lon_max) %>%
  head()
```

| dataset\_code |  lat\_min|  lat\_max|  lon\_min|  lon\_max|
|:--------------|---------:|---------:|---------:|---------:|
| BYL           |     72.51|     73.12|    -79.25|    -80.08|
| SAL           |     60.86|     62.18|    -69.56|    -75.72|
| SI            |     64.21|     65.21|    -82.52|    -84.20|
| ALERT         |        NA|        NA|        NA|        NA|
| MB            |        NA|        NA|        NA|        NA|
| ABK           |     67.07|     68.48|     23.52|     17.67|

There are two columns in the online table that contain links, which aren't kept by `html_table()`, which only extracts the text. The links will be useful for us when we need to download the data for each dataset, but even if we weren't, it would be useful information to have as a column in our `datasets_table`. The approach I took for this was to create a data.frame (tibble) of all the links, then filter out the ones I needed (the data link and the more information link) separately. Essentially, it is looking for text in the web page that looks like `<a href="...data_(dataset code).zip">...</a>` for the data link, and `<a href="...DatasetInfo2.aspx...">(dataset code)</a>` for the dataset info link. Finally, it uses a `left_join()` to add this information to the `datasets_table`.

``` r
dataset_page_links <- tibble(
  node = html_nodes(datasets_page, "a"),
  href = html_attr(node, "href"),
  text = html_text(node)
)

dataset_links_tbl <- dataset_page_links %>%
  select(data_link = href) %>%
  extract(
    data_link, 
    into = "dataset_code", 
    regex = "data_([a-z]+).zip$", 
    remove = FALSE
  ) %>%
  mutate(dataset_code = str_to_upper(dataset_code)) %>%
  filter(!is.na(dataset_code))

dataset_info_links_tbl <- dataset_page_links %>%
  filter(str_detect(href, "DatasetInfo2.aspx")) %>%
  select(dataset_code = text, info_link = href) %>%
  mutate(info_link = paste0("http://www.cen.ulaval.ca/CDD/", info_link))

datasets_table <- datasets_table %>%
  left_join(dataset_links_tbl, by = "dataset_code") %>%
  left_join(dataset_info_links_tbl, by = "dataset_code")

datasets_table %>%
  select(dataset_code, data_link, info_link) %>%
  head()
```

| dataset\_code | data\_link                                         | info\_link                                                  |
|:--------------|:---------------------------------------------------|:------------------------------------------------------------|
| BYL           | <http://www.cen.ulaval.ca/cdd/data/data_byl.zip>   | <http://www.cen.ulaval.ca/CDD/DatasetInfo2.aspx?IDVisit=6>  |
| SAL           | <http://www.cen.ulaval.ca/cdd/data/data_sal.zip>   | <http://www.cen.ulaval.ca/CDD/DatasetInfo2.aspx?IDVisit=5>  |
| SI            | <http://www.cen.ulaval.ca/cdd/data/data_si.zip>    | <http://www.cen.ulaval.ca/CDD/DatasetInfo2.aspx?IDVisit=7>  |
| ALERT         | <http://www.cen.ulaval.ca/cdd/data/data_alert.zip> | <http://www.cen.ulaval.ca/CDD/DatasetInfo2.aspx?IDVisit=15> |
| MB            | <http://www.cen.ulaval.ca/cdd/data/data_mb.zip>    | <http://www.cen.ulaval.ca/CDD/DatasetInfo2.aspx?IDVisit=16> |
| ABK           | <http://www.cen.ulaval.ca/cdd/data/data_abk.zip>   | <http://www.cen.ulaval.ca/CDD/DatasetInfo2.aspx?IDVisit=18> |

### Parsing the data

Now that we have the link for all the datasets, we can download them! Because they are ZIP files, we can extract them as well. To do this in one go, I used `pmap()` to take a tibble with the columns `url` and `destfile`, and apply the `curl_download()` function from the **curl** package to each row. The `curl_download()` function outputs the downloaded file, so we can then take the result and pipe it to the `unzip()` function, which extracts a zip file in the working directory.

``` r
datasets_table %>%
  select(url = data_link) %>%
  mutate(destfile = basename(url)) %>%
  pmap(curl::curl_download, quiet = TRUE) %>%
  map(unzip)
```

If all went well, you should have a whole lot of Excel files in your working directory, named something like `diatom_count_....xlsx` and `water_chemistry_....xlsx`. These excel files *are* the CDD, but what do they contain? We can use the **readxl** package to have a look.

``` r
library(readxl)
read_excel("diatom_count_byl.xlsx", skip = 1) %>%
  head()
```

| Diatom taxon                          | Taxon code |      BI-02|     BI-23|      BI-24|      BI-27|
|:--------------------------------------|:-----------|----------:|---------:|----------:|----------:|
| Chamaepinnularia grandupii            | NA         |  0.2624672|        NA|         NA|         NA|
| Diatoma monoliformis                  | NA         |         NA|        NA|  6.0000000|  1.4950166|
| Encyonema elginense                   | NA         |         NA|        NA|  0.1980198|         NA|
| Encyonema fogedii                     | NA         |         NA|        NA|  0.1980198|  0.8305648|
| Eunotia binularis                     | NA         |         NA|        NA|  1.5841584|         NA|
| Fragilaria construens var. subrotunda | NA         |         NA|  4.373757|         NA|         NA|

``` r
read_excel("water_chemistry_byl.xlsx", skip = 1) %>%
  select(1:7) %>%
  head()
```

| Lake \# |  Lat (°N)|  Long (°W)|  Alt (m)|  Depth (m)|  Area (ha)|   pH|
|:--------|---------:|----------:|--------:|----------:|----------:|----:|
| BI-01   |  73.13333|  -80.10000|        8|        2.8|      84491|  6.7|
| BI-02   |  73.05000|  -80.13333|       10|        2.1|      18265|  6.3|
| BI-03   |  73.18333|  -79.86667|       10|       10.0|      17916|  7.0|
| BI-04   |  73.18333|  -79.86667|       10|        4.0|      30113|  7.0|
| BI-05   |  73.20000|  -79.85000|       10|        9.5|      47481|  7.0|
| BI-06   |  73.20000|  -79.85000|       10|       10.5|      70546|  6.7|

It looks like the `diatom_counts...` spreadsheets have one row for each taxon, with locations as columns, whereas the `water_chemistry...` spreadsheets have one row for each location, with each water quality parameter. Additionally, the `water_chemistry...` spreadsheets have information about each location that is unlikely to change with time. This is perhaps a semantic difference, but an important one for structuring the data, as water quality measurements and the relative abundance of diatom taxa are measurements from the CDD, and the location/altitude/depth/area information are not measurements in quite the same way.

The two tables contain similar information that is structured in slightly different ways: one is "location-wide", and the other is "parameter-wide". One way to combine them is to make them both tables that have one row per measurement. From a tidy data standpoint, this means we can `gather()` values that are in columns into rows. Here is what it looks like for both spreadsheets (note that the negative numbers mean all the columns *except* those ones):

``` r
read_excel("diatom_count_byl.xlsx", skip = 1) %>%
  gather(-1, -2, key = "lake", value = "rel_abundance") %>%
  rename_friendly() %>%
  head()
```

| diatom\_taxon                         | taxon\_code | lake  |  rel\_abundance|
|:--------------------------------------|:------------|:------|---------------:|
| Chamaepinnularia grandupii            | NA          | BI-02 |       0.2624672|
| Diatoma monoliformis                  | NA          | BI-02 |              NA|
| Encyonema elginense                   | NA          | BI-02 |              NA|
| Encyonema fogedii                     | NA          | BI-02 |              NA|
| Eunotia binularis                     | NA          | BI-02 |              NA|
| Fragilaria construens var. subrotunda | NA          | BI-02 |              NA|

``` r
read_excel("water_chemistry_byl.xlsx", skip = 1) %>%
  select(-(2:6)) %>%
  gather(-1, key = "param", value = "value") %>%
  rename_friendly() %>%
  head()
```

| lake  | param |  value|
|:------|:------|------:|
| BI-01 | pH    |    6.7|
| BI-02 | pH    |    6.3|
| BI-03 | pH    |    7.0|
| BI-04 | pH    |    7.0|
| BI-05 | pH    |    7.0|
| BI-06 | pH    |    6.7|

As I mentioned above, some of the information in the water chemistry spreadsheet is more suited to a "location information" table (similar to our "dataset information" table above).

``` r
read_excel("water_chemistry_byl.xlsx", skip = 1) %>%
  select(1:6) %>%
  rename_friendly() %>%
  head()
```

| lake  |    lat\_n|    long\_w|  alt\_m|  depth\_m|  area\_ha|
|:------|---------:|----------:|-------:|---------:|---------:|
| BI-01 |  73.13333|  -80.10000|       8|       2.8|     84491|
| BI-02 |  73.05000|  -80.13333|      10|       2.1|     18265|
| BI-03 |  73.18333|  -79.86667|      10|      10.0|     17916|
| BI-04 |  73.18333|  -79.86667|      10|       4.0|     30113|
| BI-05 |  73.20000|  -79.85000|      10|       9.5|     47481|
| BI-06 |  73.20000|  -79.85000|      10|      10.5|     70546|

The code above works for *one* dataset, but we have 15! Because the files are well-named and all structured the same way, we can write a function to read a single dataset for each table type from above.

``` r
read_diatom_count <- function(dataset_code) {
  paste0("diatom_count_", str_to_lower(dataset_code), ".xlsx") %>%
    read_excel(skip = 1) %>%
    gather(-1, -2, key = "lake", value = "rel_abundance") %>%
    rename_friendly() %>%
    mutate(dataset_code = dataset_code)
}

read_water_chemistry <- function(dataset_code) {
  paste0("water_chemistry_", str_to_lower(dataset_code), ".xlsx") %>%
    read_excel(skip = 1) %>%
    select(-(2:6)) %>%
    gather(-1, key = "label", value = "value") %>%
    rename_friendly() %>%
    mutate(dataset_code = dataset_code)
}

read_lake_info <- function(dataset_code) {
  paste0("water_chemistry_", str_to_lower(dataset_code), ".xlsx") %>%
    read_excel(skip = 1) %>%
    select(1:6) %>%
    rename_friendly() %>%
    mutate(dataset_code = dataset_code)
}
```

Then, we can apply the functions along the list of dataset codes (`map_`) and combining the resulting data frames by row (`_dfr`) to make one big table for each data type.

``` r
diatom_counts <- datasets_table %>%
  pull(dataset_code) %>%
  map_dfr(read_diatom_count)

water_chemistry <- datasets_table %>%
  pull(dataset_code) %>%
  map_dfr(read_water_chemistry)

lake_info <- datasets_table %>%
  pull(dataset_code) %>%
  map_dfr(read_lake_info)
```

### Creating a mudata object

A mudata object (standing for [(Mostly) Universal Data](http://www.facetsjournal.com/doi/10.1139/facets-2017-0026)) is a way to store cleaned data so that it's amenable to reading, writing, documentation, and subsetting. It's implemented in the [**mudata2** package](https://cran.r-project.org/package=mudata2), and consists of five tables: **data** (a one-measurement-per-row table), **locations** (a table containing location information), **params** (a table containing parameter information), **datasets** (a table containing dataset information), and **columns** (containing column documentation). For a demo of why this might be useful in this context, see the the beginning of the this post.

We already have the raw data for these tables, but the column names used by **mudata2** (`dataset`, `location`, `param`, and `value`) are slightly different than what we have used so far. The datasets table is the closest to its final form, with the `dataset_code` column needing to be renamed to `dataset`.

``` r
datasets_table <- datasets_table %>%
  rename(dataset = dataset_code)
```

The locations table is close as well, but using the benefit of hindsight I can tell you that four locations that are included in the diatom counts are not documented in the lake info table. The `mudata()` function (which combines all these tables) is *really* picky about referential integrity, so we have to add those locations here to avoid an error later.

``` r
locations_table <- lake_info %>%
  rename(location = lake, dataset = dataset_code) %>%
  bind_rows(
    tibble(
      dataset = c("ALERT", "ALERT", "MB", "ISACH"),
      location = c("A-LDL2", "A-Self0cm", "MB-WS", "I-C")
    )
  )
```

The parameter table doesn't explicitly exist yet, but we can create it by finding distinct combinations of `dataset` and `label` in the water chemistry table. The params table is a good place to put units, although the param identifier is not, so I've extracted the unit (if it exists) to a separate column.

``` r
params_water_chemistry <- water_chemistry %>%
  rename(dataset = dataset_code) %>%
  filter(!is.na(value)) %>%
  distinct(dataset, label) %>%
  extract(
    label, 
    into = c("param", "unit"), 
    regex = "(.*?)\\s*\\((.*?)\\)", 
    remove = FALSE
  ) %>%
  mutate(param = coalesce(param, label)) %>%
  mutate(param_type = "water_chemistry")
```

This is usually a good place to make sure that everything is measured in the same unit. Luckily, each parameter only has one unit!

``` r
params_water_chemistry %>%
  group_by(param) %>%
  summarise(n_units = n_distinct(unit)) %>%
  filter(n_units > 1) %>%
  pull(param)
```

    ## character(0)

The diatom counts are a little more complicated, since they are identified by both `diatom_taxon` and `taxon_code`. The mudata format needs one unique identifier for each parameter, and because not all `diatom_taxon` values have a `taxon_code` (which is consistent across the CDD), we can `coalesce()` the two columns. That is, we can *prefer* the value of `taxon_code`, but if it is missing, we can fall back on the value of `diatom_taxon` instead.

It isn't explicit anywhere I could find on the CDD website, but the values associated with each taxon appear to be percent relative abundance values (in general, they all add up to 100 for each location). Because there's a unit for the water chemistry parameters, I decided to add this tidbit of information to the diatom count parameters as well.

``` r
params_diatom_count <- diatom_counts %>%
  rename(dataset = dataset_code) %>%
  filter(!is.na(rel_abundance)) %>%
  distinct(dataset, diatom_taxon, taxon_code) %>%
  mutate(param = coalesce(na_if(taxon_code, "(blank)"), diatom_taxon)) %>%
  mutate(label = diatom_taxon) %>%
  mutate(param_type = "diatom_count") %>%
  mutate(unit = "% rel abund")
```

Finally, we can combine the two parameter tables to make the final table.

``` r
params_table <- bind_rows(params_water_chemistry, params_diatom_count)
```

All that's left is the data table! The `water_chemistry` and `diatom_counts` tables are almost in the right form, but we need to make sure that the `param` identifiers we assigned in the previous step are the same ones that get used in the data table. It's also nice to have the `unit` next to the `value`, which makes reading the table a bit easier.

``` r
data_water_chemistry <- water_chemistry %>%
  filter(!is.na(value)) %>%
  rename(dataset = dataset_code, location = lake) %>%
  left_join(params_table, by = c("dataset", "label")) %>%
  select(dataset, location, param, value, unit)

data_diatom_counts <- diatom_counts %>%
  filter(!is.na(rel_abundance)) %>%
  rename(dataset = dataset_code, location = lake, value = rel_abundance) %>%
  left_join(params_table, by = c("dataset", "diatom_taxon", "taxon_code")) %>%
  select(dataset, location, param, value, unit)

data_table <- bind_rows(data_water_chemistry, data_diatom_counts)
```

Now it's `mudata()` time! Usually the data table contains some kind of qualifying information about each measurement (e.g., time collected, depth collected in the water column), but because of how the original data were structured, there was no place for this information. The `mudata()` function calls these `x_columns` (they're usually on the `x` axis of plots), but here there are none (hence `character(0)`).

``` r
library(mudata2)
cdd_mudata <- mudata(
  data = data_table,
  locations = locations_table,
  params = params_table,
  datasets = datasets_table,
  x_columns = character(0)
)

cdd_mudata
```

    ## A mudata object aligned along <none>
    ##   distinct_datasets():  "ABK", "ALERT" ... and 13 more
    ##   distinct_locations(): "A-A", "A-AA" ... and 569 more
    ##   distinct_params():    "ACaltaic", "ACamoena" ... and 1145 more
    ##   src_tbls():           "data", "locations" ... and 3 more
    ## 
    ## tbl_data() %>% head():
    ## # A tibble: 6 x 5
    ##   dataset location param value unit 
    ##   <chr>   <chr>    <chr> <dbl> <chr>
    ## 1 BYL     BI-01    pH     6.70 <NA> 
    ## 2 BYL     BI-02    pH     6.30 <NA> 
    ## 3 BYL     BI-03    pH     7.00 <NA> 
    ## 4 BYL     BI-04    pH     7.00 <NA> 
    ## 5 BYL     BI-05    pH     7.00 <NA> 
    ## 6 BYL     BI-06    pH     6.70 <NA>

The default `print()` function suggests a few ways to interact with the object, but what we're after here is the `write_mudata()` function, which writes the collection of tables to a folder (or ZIP file or JSON file, but folder is usually the most useful).

``` r
write_mudata_dir(cdd_mudata, "cdd.mudata")
```

