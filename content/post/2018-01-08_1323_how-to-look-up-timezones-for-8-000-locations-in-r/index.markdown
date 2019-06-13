---
title: 'How to look up timezones for 8,000 locations in R'
author: Dewey Dunnington
date: '2018-01-08'
slug: []
categories: []
tags: ["R", "sf", "timezones", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2018-01-08T14:33:48+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

If you have ever worked with dates and times over a wide geographical area, you will know that timezone math is tedious but important. In the forthcoming update of the <a href="https://github.com/paleolimbot/rclimateca">rclimateca package</a>, the list of climate locations provided in the package will contain the UTC offsets for what Environment Canada calls <a href="http://climate.weather.gc.ca/glossary_e.html#l">“local standard time”</a>. Because the UTC offset for local standard time at each location is not provided with the list of locations from Environment Canada, I had to use the latitude and longitude of each site to obtain this information. The list of locations is long (&gt;8,000), and I ran into problems doing this using web APIs as a result of rate limits and a number of obviously wrong timezone assignments. In the end, I settled on using the shapefile output of <a href="https://github.com/evansiroky/timezone-boundary-builder/">Evan Siroky’s Timezone Boundary Builder</a> and the <a href="https://github.com/r-spatial/sf">simple features package</a> to solve the problem in about 4 lines! The most recent <a href="https://stackoverflow.com/questions/16086962/how-to-get-a-time-zone-from-a-location-using-latitude-and-longitude-coordinates">Stack Overflow answer for this problem</a> lists a number of resources, but not necessarily how to implement them in R. In this post I’ll document a few ways of finding the local timezone given only latitude and longitude of a site.



### Test Locations

In the [rclimateca package](https://github.com/paleolimbot/rclimateca) I did these excercises on all 8,000 locations, but for this post I'll just pick the first site from each province (see the end of the post for how to load this data for yourself).

| name                 | province |  latitude|  longitude|
|:---------------------|:---------|---------:|----------:|
| ABEE AGDM            | AB       |     54.28|    -112.97|
| ACTIVE PASS          | BC       |     48.87|    -123.28|
| PEACE RIVER OVERLAP  | MB       |     56.23|    -117.45|
| ACADIA FOREST EXP ST | NB       |     45.99|     -66.36|
| ARGENTIA A           | NL       |     47.30|     -54.00|
| ABERCROMBIE POINT    | NS       |     45.65|     -62.72|
| AKLAVIK A            | NT       |     68.22|    -135.01|
| ARVIAT AWOS          | NU       |     61.10|     -94.07|
| ATTAWAPISKAT         | ON       |     52.92|     -82.45|
| ALBANY               | PE       |     46.27|     -63.58|
| BARRIERE STONEHAM    | QC       |     47.17|     -71.25|
| ALAMEDA CDA EPF      | SK       |     49.25|    -102.28|
| AISHIHIK A           | YT       |     61.65|    -137.48|

### Using Geonames

The first hit when I googled this problem was a message from r-sig-geo that sugested using the [GeoNames Timezone API](http://www.geonames.org/export/web-services.html#timezone) (there is also a [GeoNames R package](https://cran.r-project.org/package=geonames) that, at the time of this writing, I cannot get to work). The GeoNames API has a rate limit of 2,000 requests per hour, which was a problem for me, but is probably sufficient for most small projects. Use of the API requires a [free account with GeoNames](http://www.geonames.org/login).

``` r
library(jsonlite)

get_timezone_geonames <- function(lon, lat) {
  # generate url for the geonames query
  url <- sprintf(
    "http://api.geonames.org/timezoneJSON?lat=%s&lng=%s&username=%s",
    lat, lon, geonames_user_id
  )
  
  # parse using jsonlite::fromJSON
  fromJSON(url)$timezoneId
}
```

This function was my solution to quickly parsing the output of the API. The response contains a few more fields, but all of these can be obtained from a few sources using the timezone identifier (e.g., "America/New\_York"). The function isn't vectorized, but we can use the `map2_chr()` function from the **purrr** package to apply it along our longitude and latitude vectors.

``` r
locs <- locs %>%
  mutate(tz_geonames = map2_chr(longitude, latitude, get_timezone_geonames))

locs %>%
  select(-latitude, -longitude)
```

| name                 | province | tz\_geonames          |
|:---------------------|:---------|:----------------------|
| ABEE AGDM            | AB       | America/Edmonton      |
| ACTIVE PASS          | BC       | America/Vancouver     |
| PEACE RIVER OVERLAP  | MB       | America/Edmonton      |
| ACADIA FOREST EXP ST | NB       | America/Moncton       |
| ARGENTIA A           | NL       | America/St\_Johns     |
| ABERCROMBIE POINT    | NS       | America/Halifax       |
| AKLAVIK A            | NT       | America/Yellowknife   |
| ARVIAT AWOS          | NU       | America/Rankin\_Inlet |
| ATTAWAPISKAT         | ON       | America/Toronto       |
| ALBANY               | PE       | America/Halifax       |
| BARRIERE STONEHAM    | QC       | America/Toronto       |
| ALAMEDA CDA EPF      | SK       | America/Regina        |
| AISHIHIK A           | YT       | America/Whitehorse    |

### Using the Google Maps Timezone API

The second options I tried was the [Google Maps Timezone API](https://developers.google.com/maps/documentation/timezone/intro). This API is similar to the GeoNames API, with slight differences to the input and output formats. Also, the Google Maps API requires a timestamp (number of seconds since 1970), although this doesn't affect the timezone ID. The Google Maps API has a rate limit of 50 requests per second and 1,500 per day, which limits its applicability to large projects. An API key is free and required.

``` r
get_timezone_google <- function(lon, lat) {
  # generate url for the google query
  timestamp <- "331161200"
  url <- sprintf(
    "https://maps.googleapis.com/maps/api/timezone/json?location=%s,%s&key=%s&timestamp=%s",
    lat, lon, google_api_key, timestamp
  )
  
  # parse using jsonlite::fromJSON
  fromJSON(url)$timeZoneId
}
```

``` r
locs <- locs %>%
  mutate(tz_google = map2_chr(longitude, latitude, get_timezone_google))

locs %>%
  select(-latitude, -longitude)
```

| name                 | province | tz\_geonames          | tz\_google        |
|:---------------------|:---------|:----------------------|:------------------|
| ABEE AGDM            | AB       | America/Edmonton      | America/Edmonton  |
| ACTIVE PASS          | BC       | America/Vancouver     | America/Vancouver |
| PEACE RIVER OVERLAP  | MB       | America/Edmonton      | America/Edmonton  |
| ACADIA FOREST EXP ST | NB       | America/Moncton       | America/Halifax   |
| ARGENTIA A           | NL       | America/St\_Johns     | America/St\_Johns |
| ABERCROMBIE POINT    | NS       | America/Halifax       | America/Halifax   |
| AKLAVIK A            | NT       | America/Yellowknife   | America/Edmonton  |
| ARVIAT AWOS          | NU       | America/Rankin\_Inlet | America/Winnipeg  |
| ATTAWAPISKAT         | ON       | America/Toronto       | America/Toronto   |
| ALBANY               | PE       | America/Halifax       | America/Halifax   |
| BARRIERE STONEHAM    | QC       | America/Toronto       | America/Toronto   |
| ALAMEDA CDA EPF      | SK       | America/Regina        | America/Regina    |
| AISHIHIK A           | YT       | America/Whitehorse    | America/Vancouver |

### Using Evan Siroky's Timezone Boundary Builder

My prefered solution to the timezone-by-location problem was using the shapefile output of [Evan Siroky's Timezone Boundary Builder](https://github.com/evansiroky/timezone-boundary-builder/) and the [simple features package](https://github.com/r-spatial/sf). Firstly, there is no limit to the number of locations, secondly, the output is more accurate than either GeoNames or Google (based on my use case of 8,000 obscure Canadian locations), and thirdly, it is more repeatable than using a web API because it completes in a negligible amount of time. It involves downloading a large-ish (50 MB) shapefile from the releases section of the Timezone Boundary Builder GitHub page (see the end of this post), and doing a spatial join using the `st_join()` function.

``` r
library(sf)

# load the timezone information
tz_polygons <- read_sf(
  "timezones.shapefile/dist/combined_shapefile.shp"
)

locs_sf <- locs %>%
  # turn the locs data frame into an sf-data frame
  st_as_sf(coords = c("longitude", "latitude"), 
           crs = 4326) %>%
  # do a left_join of the timezone polygons to the 
  # location point data
  st_join(tz_polygons)

# extract the timezone ID column from the locs_sf
# data frame, add it to the locs data frame
locs <- locs %>%
  mutate(tz_shp = locs_sf$tzid)

# print the result
locs %>%
  select(-latitude, -longitude)
```

| name                 | province | tz\_geonames          | tz\_google        | tz\_shp               |
|:---------------------|:---------|:----------------------|:------------------|:----------------------|
| ABEE AGDM            | AB       | America/Edmonton      | America/Edmonton  | America/Edmonton      |
| ACTIVE PASS          | BC       | America/Vancouver     | America/Vancouver | America/Vancouver     |
| PEACE RIVER OVERLAP  | MB       | America/Edmonton      | America/Edmonton  | America/Edmonton      |
| ACADIA FOREST EXP ST | NB       | America/Moncton       | America/Halifax   | America/Moncton       |
| ARGENTIA A           | NL       | America/St\_Johns     | America/St\_Johns | America/St\_Johns     |
| ABERCROMBIE POINT    | NS       | America/Halifax       | America/Halifax   | America/Halifax       |
| AKLAVIK A            | NT       | America/Yellowknife   | America/Edmonton  | America/Yellowknife   |
| ARVIAT AWOS          | NU       | America/Rankin\_Inlet | America/Winnipeg  | America/Rankin\_Inlet |
| ATTAWAPISKAT         | ON       | America/Toronto       | America/Toronto   | America/Toronto       |
| ALBANY               | PE       | America/Halifax       | America/Halifax   | America/Halifax       |
| BARRIERE STONEHAM    | QC       | America/Toronto       | America/Toronto   | America/Toronto       |
| ALAMEDA CDA EPF      | SK       | America/Regina        | America/Regina    | America/Regina        |
| AISHIHIK A           | YT       | America/Whitehorse    | America/Vancouver | America/Whitehorse    |

Even for these 13 locations, there are discrepancies among the timezone IDs returned by the three methods. In particular, I think the Google result is the least accurate, often assigning locations that may be closest but in the wrong political jurisdiction. In these locations the GeoNames result was identical to the shapefile result, but in my list of 8,000 locations, many errors occured in the GeoNames output that were not present in the shapefile output.

### Doing more

The timezone identifier is the key to the timezone information, but the useful data is the summer and winter UTC offsets. These data are available from a few locations: [Wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones), [GeoNames](https://www.iana.org/time-zones), and the [official timezone database](https://www.iana.org/time-zones). I found the GeoNames version to be the most easily accessible from R (it is a text file), but it doesn't contain the current or historical dates of daylight savings time adjustments.

### Getting the Files

To follow along to the code in this blog post, you will need to download the location list from Environment Canada, and download the timezone information from the Timezone Boundary Calculator GitHub releases page. To do so without leaving R, run the following code:

``` r
library(curl)
locs_url <- paste0(
  "ftp://client_climate@ftp.tor.ec.gc.ca/Pub/",
  "Get_More_Data_Plus_de_donnees/", 
  "Station%20Inventory%20EN.csv"
)
curl_download(data_url, "locs.csv")

province_abbrevs <- provinces <- c(
  "ALBERTA" = "AB",  
  "BRITISH COLUMBIA" = "BC",
  "MANITOBA" = "MB",  
  "NEW BRUNSWICK" = "NB",  
  "NEWFOUNDLAND" = "NL",
  "NORTHWEST TERRITORIES" = "NT",  
  "NOVA SCOTIA" = "NS",  
  "NUNAVUT" = "NU",
  "ONTARIO" = "ON",  
  "PRINCE EDWARD ISLAND" = "PE",  
  "QUEBEC" = "QC",
  "SASKATCHEWAN" = "SK",  
  "YUKON TERRITORY" = "YT"
)

locs <- read_csv("locs.csv", skip = 3) %>%
  select(name = Name, province = Province,
         latitude = `Latitude (Decimal Degrees)`,
         longitude = `Longitude (Decimal Degrees)`) %>%
  mutate(province = province_abbrevs[province]) %>%
  group_by(province) %>%
  slice(1) %>%
  ungroup()
```

``` r
# download the file
curl::curl_download(
  paste0(
    "https://github.com/evansiroky/",
    "timezone-boundary-builder/releases/download/",
    "2017c/timezones.shapefile.zip"
  ),
  "timezones.shapefile.zip",
  quiet = FALSE
)

# extract the archive
unzip(
  "timezones.shapefile.zip", 
  exdir = "timezones.shapefile"
)
```
