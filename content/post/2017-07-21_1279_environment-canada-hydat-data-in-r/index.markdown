---
title: 'Environment Canada HYDAT data in R'
author: Dewey Dunnington
date: '2017-07-21'
slug: []
categories: []
tags: ["hydatr R hydrology", "Releases"]
subtitle: ''
summary: ''
authors: []
lastmod: '2017-07-21T11:54:24+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
aliases: [/archives/1279]
---

The <a href="http://www.ec.gc.ca/rhc-wsc/default.asp?lang=en&n=9018B5EC-1">HYDAT database</a> contains over 1 GB of hydrological observation data collected by <a href="http://ec.gc.ca/">Environment Canada</a>. The database is freely available from the Environment Canada website, however extracting data can be difficult. Recently a student in our lab was working with this data, so I adapted some previously shotty code that cleaned up the somewhat difficult to navigate database into a <a href="https://github.com/paleolimbot/hydatr">nice unit-tested R package</a>. Not doing much work in the hydrology sector myself, I'd love some feedback on what is useful and not useful about the package! Some basic usage is demonstrated below.


Installation
------------

You can install hydatr from github with:

``` r
# install.packages("devtools")
devtools::install_github("paleolimbot/hydatr")
```

Finding Hydro Stations
----------------------

Find hydro sites:

``` r
hydat_find_stations("lower sackville, NS", year = 1999:2012)
#> # A tibble: 10 x 8
#>    STATION_NUMBER dist_from_query_km
#>             <chr>              <dbl>
#>  1        01EJ004          0.9861109
#>  2        01EJ001          5.1509276
#>  3        01DG003          8.8762890
#>  4        01DJ005         74.3590516
#>  5        01EF001         80.2094515
#>  6        01DC005        107.6006889
#>  7        01DP004        107.6301656
#>  8        01DL001        108.5261888
#>  9        01EE005        113.1515549
#> 10        01DC007        116.6305481
#> # ... with 6 more variables: STATION_NAME <chr>, FIRST_YEAR <int>,
#> #   LAST_YEAR <int>, LONGITUDE <dbl>, LATITUDE <dbl>,
#> #   DRAINAGE_AREA_GROSS <dbl>
```

Get detailed information about one hydro site:

``` r
as.list(hydat_station_info("01EJ004"))
#> $STATION_NUMBER
#> [1] "01EJ004"
#> 
#> $STATION_NAME
#> [1] "LITTLE SACKVILLE RIVER AT MIDDLE SACKVILLE"
#> 
#> $PROV_TERR_STATE_LOC
#> [1] "NS"
#> 
#> $LATITUDE
#> [1] 44.76447
#> 
#> $LONGITUDE
#> [1] -63.6875
#> 
#> $DRAINAGE_AREA_GROSS
#> [1] 13.1
#> 
#> $DRAINAGE_AREA_EFFECT
#> [1] NA
#> 
#> $STATUS_EN_HYD
#> [1] "Active"
#> 
#> $STATUS_EN_SED
#> [1] "Discontinued"
#> 
#> $REGIONAL_OFFICE_NAME_EN
#> [1] "DARTMOUTH"
#> 
#> $AGENCY_EN_CONTRIBUTOR
#> [1] "NOVA SCOTIA DEPARTMENT OF ENVIRONMENT"
#> 
#> $AGENCY_EN_OPERATOR
#> [1] "WATER SURVEY OF CANADA (DOE) (CANADA)"
#> 
#> $RHBN
#> [1] 0
#> 
#> $REAL_TIME
#> [1] 1
#> 
#> $DATUM_ID
#> [1] 10
#> 
#> $FIRST_YEAR
#> [1] 1980
#> 
#> $LAST_YEAR
#> [1] 2015
```

Get detailed information about all the hydro sites:

``` r
hydat_station_info()
#> # A tibble: 1,000 x 17
#>    STATION_NUMBER                                           STATION_NAME
#>             <chr>                                                  <chr>
#>  1        01AA002        DAAQUAM (RIVIERE) EN AVAL DE LA RIVIERE SHIDGEL
#>  2        01AD001      MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA
#>  3        01AD002                          SAINT JOHN RIVER AT FORT KENT
#>  4        01AD003            ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE
#>  5        01AD004                         SAINT JOHN RIVER AT EDMUNDSTON
#>  6        01AD005           MADAWASKA (RIVIERE) AU RESERVOIR TEMISCOUATA
#>  7        01AD008                         LONG (LAC) PRES DE LES ETROITS
#>  8        01AD009                           CABANO (RIVIERE) AU LAC LONG
#>  9        01AD012 SAINT-FRANCOIS (RIVIERE) EN AVAL DU LAC SAINT-FRANCOIS
#> 10        01AD013 SAINT-FRANCOIS (RIVIERE) EN AVAL DU LAC SAINT-FRANCOIS
#> # ... with 990 more rows, and 15 more variables:
#> #   PROV_TERR_STATE_LOC <chr>, LATITUDE <dbl>, LONGITUDE <dbl>,
#> #   DRAINAGE_AREA_GROSS <dbl>, DRAINAGE_AREA_EFFECT <dbl>,
#> #   STATUS_EN_HYD <chr>, STATUS_EN_SED <chr>,
#> #   REGIONAL_OFFICE_NAME_EN <chr>, AGENCY_EN_CONTRIBUTOR <chr>,
#> #   AGENCY_EN_OPERATOR <chr>, RHBN <int>, REAL_TIME <int>, DATUM_ID <int>,
#> #   FIRST_YEAR <int>, LAST_YEAR <int>
```

Extracting Data
---------------

The following methods extract data from the database given the correct station number:

``` r
hydat_flow_monthly("01AD001")
#> # A tibble: 880 x 9
#>    STATION_NUMBER                                      STATION_NAME  YEAR
#>             <chr>                                             <chr> <int>
#>  1        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1918
#>  2        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1918
#>  3        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1918
#>  4        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1918
#>  5        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#>  6        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#>  7        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#>  8        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#>  9        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#> 10        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#> # ... with 870 more rows, and 6 more variables: MONTH <int>, DATE <date>,
#> #   MONTHLY_MEAN <dbl>, MONTHLY_TOTAL <dbl>, DAILY_MIN <dbl>,
#> #   DAILY_MAX <dbl>
hydat_flow_daily("01AD001")
#> # A tibble: 26,785 x 8
#>    STATION_NUMBER                                      STATION_NAME  YEAR
#>             <chr>                                             <chr> <int>
#>  1        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1918
#>  2        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1918
#>  3        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1918
#>  4        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1918
#>  5        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#>  6        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#>  7        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#>  8        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#>  9        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#> 10        01AD001 MADAWASKA (RIVIER) EN AVAL DU BARRAGE TEMISCOUATA  1919
#> # ... with 26,775 more rows, and 5 more variables: MONTH <int>, DAY <int>,
#> #   DATE <date>, FLOW <dbl>, FLOW_SYMBOL <chr>
hydat_level_monthly("01AD003")
#> # A tibble: 60 x 9
#>    STATION_NUMBER                                STATION_NAME  YEAR MONTH
#>             <chr>                                       <chr> <int> <int>
#>  1        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     1
#>  2        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     2
#>  3        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     3
#>  4        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     4
#>  5        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     5
#>  6        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     6
#>  7        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     7
#>  8        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     8
#>  9        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     9
#> 10        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011    10
#> # ... with 50 more rows, and 5 more variables: DATE <date>,
#> #   MONTHLY_MEAN <dbl>, MONTHLY_TOTAL <dbl>, DAILY_MIN <dbl>,
#> #   DAILY_MAX <dbl>
hydat_level_daily("01AD003")
#> # A tibble: 1,826 x 8
#>    STATION_NUMBER                                STATION_NAME  YEAR MONTH
#>             <chr>                                       <chr> <int> <int>
#>  1        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     1
#>  2        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     2
#>  3        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     3
#>  4        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     4
#>  5        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     5
#>  6        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     6
#>  7        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     7
#>  8        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     8
#>  9        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011     9
#> 10        01AD003 ST. FRANCIS RIVER AT OUTLET OF GLASIER LAKE  2011    10
#> # ... with 1,816 more rows, and 4 more variables: DAY <int>, DATE <date>,
#> #   LEVEL <dbl>, LEVEL_SYMBOL <chr>
hydat_sed_monthly("01AF006")
#> # A tibble: 26 x 9
#>    STATION_NUMBER                           STATION_NAME  YEAR MONTH
#>             <chr>                                  <chr> <int> <int>
#>  1        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     4
#>  2        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     5
#>  3        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     6
#>  4        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     7
#>  5        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     8
#>  6        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     9
#>  7        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1972     4
#>  8        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1972     5
#>  9        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1972     6
#> 10        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1972     7
#> # ... with 16 more rows, and 5 more variables: DATE <date>,
#> #   MONTHLY_MEAN <dbl>, MONTHLY_TOTAL <dbl>, DAILY_MIN <dbl>,
#> #   DAILY_MAX <dbl>
hydat_sed_daily("01AF006")
#> # A tibble: 794 x 7
#>    STATION_NUMBER                           STATION_NAME  YEAR MONTH   DAY
#>             <chr>                                  <chr> <int> <int> <int>
#>  1        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     4     1
#>  2        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     5     1
#>  3        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     6     1
#>  4        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     7     1
#>  5        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     8     1
#>  6        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1971     9     1
#>  7        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1972     4     1
#>  8        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1972     5     1
#>  9        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1972     6     1
#> 10        01AF006 BLACK BROOK NEAR ST-ANDRE-DE-MADAWASKA  1972     7     1
#> # ... with 784 more rows, and 2 more variables: DATE <date>, LOAD <dbl>
```

Advanced Functionality
----------------------

The package is built on top of `dplyr` and `RSQLite`, and also provides low-level access to the HYDAT database through these methods.

``` r
hydat_get_db() # gets the db that was loaded in hydat_load()
#> src:  sqlite 3.11.1 [/Library/Frameworks/R.framework/Versions/3.3/Resources/library/hydatr/Hydat_sqlite3_99999999.db]
#> tbls: AGENCY_LIST, ANNUAL_INSTANT_PEAKS, ANNUAL_STATISTICS,
#>   CONCENTRATION_SYMBOLS, DATA_SYMBOLS, DATA_TYPES, DATUM_LIST, DLY_FLOWS,
#>   DLY_LEVELS, MEASUREMENT_CODES, OPERATION_CODES, PEAK_CODES,
#>   PRECISION_CODES, REGIONAL_OFFICE_LIST, SAMPLE_REMARK_CODES,
#>   SED_DATA_TYPES, SED_DLY_LOADS, SED_DLY_SUSCON, SED_SAMPLES,
#>   SED_SAMPLES_PSD, SED_VERTICAL_LOCATION, SED_VERTICAL_SYMBOLS,
#>   sqlite_stat1, STATIONS, STN_DATA_COLLECTION, STN_DATA_RANGE,
#>   STN_DATUM_CONVERSION, STN_DATUM_UNRELATED, STN_OPERATION_SCHEDULE,
#>   STN_REGULATION, STN_REMARK_CODES, STN_REMARKS, STN_STATUS_CODES, VERSION
```

``` r
hydat_tbl("ANNUAL_INSTANT_PEAKS") # gets the db that was loaded in hydat_load()
#> # Source:   table<ANNUAL_INSTANT_PEAKS> [?? x 12]
#> # Database: sqlite 3.11.1
#> #   [/Library/Frameworks/R.framework/Versions/3.3/Resources/library/hydatr/Hydat_sqlite3_99999999.db]
#>    STATION_NUMBER DATA_TYPE  YEAR PEAK_CODE PRECISION_CODE MONTH   DAY
#>             <chr>     <chr> <int>     <chr>          <int> <int> <int>
#>  1        01AD002         Q  1940         H             NA     5     5
#>  2        01AD002         Q  1950         H             NA     4    23
#>  3        01AD002         Q  1960         H             NA     5     8
#>  4        01AD002         Q  1970         H             NA     5     3
#>  5        01AD002         Q  1980         H             NA     4    16
#>  6        01AD003         Q  1960         H             NA     5    12
#>  7        01AD003         Q  1970         H             NA     5     4
#>  8        01AD003         Q  1980         H             NA     4    18
#>  9        01AD004         Q  1970         H             NA     5     3
#> 10        01AD004         H  1980         H              8    12    13
#> # ... with more rows, and 5 more variables: HOUR <int>, MINUTE <int>,
#> #   TIME_ZONE <chr>, PEAK <dbl>, SYMBOL <chr>
```

Because the package is built on `dplyr`, using `dplyr` functions is a particularly good way to get the most out of the database.

``` r
library(dplyr)
peaks <- hydat_tbl("ANNUAL_INSTANT_PEAKS") %>%
  left_join(hydat_tbl("PEAK_CODES")) %>%
  collect() %>%
  mutate(DATE = lubridate::ymd(paste(YEAR, MONTH, DAY))) %>%
  select(STATION_NUMBER, DATE, PEAK_CODE = PEAK_EN, PEAK)
#> Warning: 7 failed to parse.
peaks
#> # A tibble: 1,000 x 4
#>    STATION_NUMBER       DATE PEAK_CODE     PEAK
#>             <chr>     <date>     <chr>    <dbl>
#>  1        01AD002 1940-05-05   Maximum 2460.000
#>  2        01AD002 1950-04-23   Maximum 1890.000
#>  3        01AD002 1960-05-08   Maximum 2580.000
#>  4        01AD002 1970-05-03   Maximum 2690.000
#>  5        01AD002 1980-04-16   Maximum 1590.000
#>  6        01AD003 1960-05-12   Maximum  203.000
#>  7        01AD003 1970-05-04   Maximum  251.000
#>  8        01AD003 1980-04-18   Maximum  125.000
#>  9        01AD004 1970-05-03   Maximum 2810.000
#> 10        01AD004 1980-12-13   Maximum  138.457
#> # ... with 990 more rows
```
