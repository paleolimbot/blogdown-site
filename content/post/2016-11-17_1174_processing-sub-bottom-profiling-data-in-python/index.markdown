---
title: 'Processing sub-bottom profiling data in Python'
author: Dewey Dunnington
date: '2016-11-17'
slug: []
categories: []
tags: ["HydroBox", "nmea", "Python", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2016-11-17T16:16:56+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

In addition to processing bathymetric data, my research on lakes requires sub-bottom profiling, or the collection of low-energy seismic data collected similarly to bathymetric data. The system we use is the SyQwest HydroBox, which, due to many hardware and software limitations, has been particularly frustrating. Still, when it does work properly, the HydroBox data has been invaluable to our lakes research. Unfortunately, the software supplied with the HydroBox is not particularly good at visualizing the collected data after collection.


![a look at the supplied interface](hb_ss1.png)

As you can see, the only option for visualization following collection is to play back the file from the beginning (and if you change window settings the playback often resets unexpectedly). It's quite maddening to deal with, and in the past I've had to make figures by stitching together multiple screenshots in MS Paint. This assumes the boat travelled at constant velocity and requires some manual typing in of coordinates to figure out exactly where the section is geographically. Needless to say, absolutely un-ideal.

So what are the alternatives? The HydroBox is fully compatible with proprietary solutions such as [HyPack](http://www.hypack.com/new/), [HydroPro](http://construction.trimble.com/products-and-solutions/hydropro-software), and [SonarWiz](https://www.chesapeaketech.com/products/sonarwiz-sidescan/), but for a small fry like me these are expensive and have capabilities far beyond what I need. Plus, my sometimes out-of-control programming habit needs an outlet.

## Hacking the HydroBox

The HydroBox saves playback to a `.odc` file, in a format that looks much like NMEA (but is not quite). I think the output is in something called 'ODEC' format, but if the documentation of this format is on the internet, I haven't been able to find it (in fact, there are only two mentions of the PNTI sentence that makes up the format on the internet). To illustrate, here's some data I collected during my M.Sc. thesis ([get the data here](20140711114326.odc)).

```python
with open('sample_odc/20140711101028.odc', 'rb') as f:
    for row in range(6):
        print(f.readline())
```

    b'$PNTI,101,!,00.11,00.49,0,*2F\r\n'
    b'$PNTI,103,X,0,0,1,0,0,1,0,H,*3D\r\n'
    b'$PNTI,105,W,0,20,0,29,98,1500,0,0,0,G,*37\r\n'
    b'$PNTI,171,07/11/14,10:10:28,0.00,*0E\r\n'
    b"$PNTI,111,H,1,00000,0,0020,0000,03296,\xff\xff\xff\xff\xff\xff\xff\xadW4D0\x14\x00\x00\x000\x01\x00 \x02\x00\x10\x000\x00\x00\x00\x00\x13\x00\x00!@\x12B\x00\x000\x00\x01 \x10\x120\x00\x00 \x02\x00\x00\x03!\x01\x021\x00\x00\x00\x00C\x00\x00DBFDs\x98\xaa\x8ahU\x87\xa9\x88hQv\x87\x99\x8au\x88\x99\x9a\xa9\x8a\x99xx\x01\x02@\xa7\x9aE\x98gWSF\x87\x88H\x00\x00\x00\x86Gf\x16\x00w\x06\x00\x86\x87x\x01 \x00u7#\x81x\x89vi\x03\x81\x89\x97\x88\x89\x98x\x89'\x01\x86%\x10\x98\x88\x89\x97\x88\x99\xa8\x99\xaa\x99\x8a\x06\x82x\x02d`fw\xa9\xb9\x9a&\x85y\x98\x98\x8a\xa9h%\x03U\x12\x84h\x99yTE\x96\x9a\xb8\x89F\xa8\x9a\xaaWc\xaa\x99\x9b\xa9\x8a5,*EA\r\n"
    b'$PNTI,151,07/11/14,17:10:28.17, 50.108116667,-122.981900000,181.1, 0.4,*04\r\n'

The first thing you'll notice is that we have to read the file in binary (hence the `'rb'`), because the file is not strictly (but contains some) text. The format for each line in the file is `$PNTI,...,...`, where the first `...` is some three-digit number that presumably tells us something about the data that follows (the second `...`). As far as I can tell from my examination of the data I've collected over the years, the types of sentences that are output are as follows:
<div>
<table class="dataframe" border="1">
<thead>
<tr style="text-align: right;">
<th>Type</th>
<th>Example Data</th>
<th>Count</th>
</tr>
</thead>
<tbody>
<tr>
<td>$PNTI,101</td>
<td>b'$PNTI,101,!,00.12,00.38,0,*2A'</td>
<td>6</td>
</tr>
<tr>
<td>$PNTI,103</td>
<td>b'$PNTI,103,A,2,0,0,0,0,15,0,A,*1B'</td>
<td>12</td>
</tr>
<tr>
<td>$PNTI,105</td>
<td>b'$PNTI,105,C,1,120,0,6,48,4921,0,C,*2D'</td>
<td>122</td>
</tr>
<tr>
<td>$PNTI,111</td>
<td>b'$PNTI,111,C,1,04987,0,0120,0000,03296,\xa7\xcd\x9bW\x00\x00\x00\x00\x...</td>
<td>147384</td>
</tr>
<tr>
<td>$PNTI,151</td>
<td>b'$PNTI,151,10/12/05,14:28:23.64, 43.106417233,-76.234257950, 0.0, 0.0...</td>
<td>147353</td>
</tr>
<tr>
<td>$PNTI,152</td>
<td>b'$PNTI,152,11/09/16,22:26:55, 11/09/16 22:26:55,*19'</td>
<td>1</td>
</tr>
<tr>
<td>$PNTI,171</td>
<td>b'$PNTI,171,10/12/05,14:28:23,0.46,*0D'</td>
<td>6</td>
</tr>
</tbody>
</table>
</div>
In playback mode, the non-depth reflection data is displayed on the lefthand side in something that looks like this. Trying to link these two is currently my only method for determining the meaning of the data, althogh with some more experience in geophysics I'm sure I could do a little better. The following is my best guess as to what the output data means (note that there are quite a few question marks).

![the details](hb_ss2.png)

### PNTI 171: Date/time at start of file

`$PNTI,171,10/12/05,14:28:23,0.46,*0D`

Easiest first, this looks like straight up date/time information in the format `PNTI,171,MM/DD/YY,HH:mm:ss,*FF`. My best guess is that the time is UTC, and this sentence appears to only exist at the beginning of ODC files. This can be parsed using Python's `datetime.datetime` object (`datetime.strptime(timestamp), '%m/%d/%y %H:%M:%S')`).

### PNTI 103: Settings at start of file

`$PNTI,103,A,2,0,0,0,0,15,0,A,*1B`

The PNTI 103 sentence is similar to the PNTI 105 sentence (below), but always appears at the beginning of files and sometimes (not often) at other places within the file.

### PNTI 105: Settings changed

`$PNTI,105,C,1,120,0,6,48,4921,0,C,*2D`

This sentence occurs when settings are changed during data collection. I'm unsure what the significance of the letters are, except that the last letter appears in the PNTI 111 sentences that follow, and the first one doesn't necessarily. The format is `PNTI,105,[A-Z],[0 or 1],RANGE,0,LF_GAIN,HF_GAIN,????,0,[A-Z],*2D`. The ???? is always 4 digits and for all of our data is 1500 (for some of the sample data it is &gt;4000 and variable).

### PNTI 152: Annotation

`$PNTI,152,11/09/16,22:26:55, 11/09/16 22:26:55,*19`

This sentence only came up once in my examination of the data, and I think it is what happens when you 'annotate'. The one example I have has an annotation that is just the date and time, but I think this is just the default text and was likely added by accident. The format is `PNTI,152,MM/DD/YY,HH:mm:ss,ANNOTATION TEXT,*FF`.

### PNTI 151: Lat/Lon Data

`$PNTI,151,10/12/05,14:28:23.64, 43.106417233,-76.234257950, 0.0, 0.0,*36`

This sentence carries the GPS data (which includes a mega accurate date/time to the hundredth of a second). Unlike NMEA lat/lon, the lat/lon data in this sentence are in decimal degrees. The format is `PNTI,151,MM/DD/YY,HH:mm:ss.ss, LATITUDE,LONGITUDE, ELEVATION, HDOP(?),*36`. The HDOP is a guess, but it is the only other piece of information I can think of that would be reported in this way (it is generally a decimal number less than 1.0). The datetime can be parsed using Python's `datetime.datetime` object (`datetime.strptime(time + date[:date.rfind('.')]), '%m/%d/%y %H:%M:%S')`). This truncates the hundredths of a second, but if you want them back you can use `.replace(microsecond=...)`.

### PNTI 111: Reflection data

`$PNTI,111,C,1,04987,0,0120,0000,03296,\xa7\xcd\x9bW\x00\x00\x00\x00\x00\x00\x10\x02\x00\x00\x00...`

This sentence carries the real data, and since most of that data is in binary form, it is the reason we cannot process the files as ASCII text (as we would other NMEA data). Because this is the bulk of the data, we will examine values from this sentence closely.
<div>
<table class="dataframe" border="1">
<thead>
<tr style="text-align: right;">
<th>Column</th>
<th>Best Guess</th>
<th>Values</th>
</tr>
</thead>
<tbody>
<tr>
<td>1</td>
<td>Sentence ID</td>
<td>$PNTI</td>
</tr>
<tr>
<td>2</td>
<td>Sentence ID</td>
<td>111</td>
</tr>
<tr>
<td>3</td>
<td>From previous PNTI 105?</td>
<td>D, E, F, G, I, J, K, L, M, N, Q, S, U, V, W, X, Y, Z</td>
</tr>
<tr>
<td>4</td>
<td>LF (1), HF(2)</td>
<td>1, 2</td>
</tr>
<tr>
<td>5</td>
<td>Depth * 100 (m)?</td>
<td>00000, 00150, 00151, 00152, 00153, 00155, 00156, 00157, 00158, 00160, 0...</td>
</tr>
<tr>
<td>6</td>
<td>Always 0</td>
<td>0</td>
</tr>
<tr>
<td>7</td>
<td>Range (metres)</td>
<td>0005, 0010, 0020, 0030, 0040, 0060, 0120</td>
</tr>
<tr>
<td>8</td>
<td>Unknown (mostly 0000)</td>
<td>000/, 0000, 0002, 0003, 0005, 0008, 0009, 0011, 0013, 1547, 1858, 1946,...</td>
</tr>
<tr>
<td>9</td>
<td>Always 03296</td>
<td>03296</td>
</tr>
<tr>
<td>10</td>
<td>Amplitude data</td>
<td>1, 182, 193, 200</td>
</tr>
</tbody>
</table>
</div>
The final column (column 10) carries amplitude response data, which is what is shown in the main area of the hydrobox playback window. The values shown above are lengths, which are usually 200 but it appears this can vary slightly. Each byte represents a value between 0 and 255 corresponding to the response amplitude. This data is transmitted approximately 10 times per second.

## A note on checksums

You will notice the `*XX` string at the end of every line...this is the NMEA checksum. For some reason, most data fails the NMEA checksum (perhaps I've written my checksum algorithm wrong, but I don't think I have). Therefore, it is necessary to use other means to verify the integrity of the data.

## Extracting the data

Given our newfound enlightenment on the `.odc` files output by the HydroBox software, we can extract the data. All we really need is the date/time, range, lat/lon, depth, and the amplitude data to make a pretty picture (and perhaps do some processing). ODC files can get rather large and so I would suggest that instead of loading everything into memory, it is better to write a generic handler function that gets called with the above fields that can be changed depending on the application. If using HF and LF, one could write two such functions, since the data from one probably shouldn't be mixed with the other.

```python
def handle_data(datetime, lon, lat, depth, depthrange, data):
    ## do something
    pass
```

Given appropriate handler functions, looping through the file can be done with the same code each time (I've also added a `startline` and `maxlines` argument in case reading a partial file is preferable). Note that I've added a check for the return value, so that the data handlers can tell the loop when to stop reading. This is useful if you've created some kind of finite data structure (like a NumPy array) to hold the data (you can `return False` to stop reading the file. Using `maxlines` is still a little safer (since data handlers aren't called when lines are malformed).


```python
def read_odc(filename, startline=1, checksum=False, maxlines=0, handle_hf=None, handle_lf=None):
    with open(filename, 'rb') as f:
        # these data are on different lines than the data itself,
        # so they need to be updated
        lon = float('nan')
        lat = float('nan')
        datetime = 'NA'
        
        linenum = 0
        for line in f:
            linenum += 1
            if linenum < startline:
                continue
            elif maxlines > 0 and (linenum-startline) > maxlines:
                break
            elif checksum and not nmea_checksum(line):
                continue
            
            if line.startswith(b'$PNTI,151'):
                try:
                    parts = line.decode('ascii').split(',')
                    lon = float(parts[5])
                    lat = float(parts[4])
                    datetime = ' '.join(parts[2:4])
                except UnicodeDecodeError:
                    # invalid bytes in string
                    pass
                except ValueError:
                    # string can't be parsed as a float
                    pass
                except IndexError:
                    # there aren't enough fields (probably malformed line)
                    pass
            elif line.startswith(b'$PNTI,111'):
                try:
                    # need to treat as a binary string
                    parts = line.split(b',')
                    depth = float(parts[4].decode('ascii')) / 100.0
                    depthrange = float(parts[6].decode('ascii'))
                    # convert to ints
                    data = [b for b in parts[9]]
                    freqtype = int(parts[3].decode('ascii'))
                except UnicodeDecodeError:
                    # invalid bytes in string
                    continue
                except ValueError:
                    # string can't be parsed as a float
                    continue
                except IndexError:
                    # there aren't enough fields (probably malformed line)
                    continue
                if freqtype == 1 and handle_lf is not None:
                    if handle_lf(datetime=datetime, lon=lon, lat=lat, depth=depth, 
                              depthrange=depthrange, data=data) is False:
                        break
                elif freqtype == 2 and handle_hf is not None:
                    if handle_hf(datetime=datetime, lon=lon, lat=lat, depth=depth, 
                              depthrange=depthrange, data=data) is False:
                        break

            
def handle_data_lf(datetime, lon, lat, depth, depthrange, data):
    print('LF Datetime: %s, Lon: %.5f, Lat: %.5f, Depth: %s, Depth Range: %s' %\
            (datetime, lon, lat, depth, depthrange))
    
def handle_data_hf(datetime, lon, lat, depth, depthrange, data):
    print('HF Datetime: %s, Lon: %.5f, Lat: %.5f, Depth: %s, Depth Range: %s' %\
            (datetime, lon, lat, depth, depthrange))
    
read_odc('sample_odc/20051012142823.odc', maxlines=20, handle_lf=handle_data_lf,
        handle_hf=handle_data_hf)
```

    LF Datetime: NA, Lon: nan, Lat: nan, Depth: 49.87, Depth Range: 120.0
    HF Datetime: 10/12/05 14:28:23.64, Lon: -76.23426, Lat: 43.10642, Depth: 49.31, Depth Range: 120.0
    LF Datetime: 10/12/05 14:28:23.64, Lon: -76.23426, Lat: 43.10642, Depth: 49.87, Depth Range: 120.0
    HF Datetime: 10/12/05 14:28:23.69, Lon: -76.23426, Lat: 43.10642, Depth: 49.31, Depth Range: 120.0
    LF Datetime: 10/12/05 14:28:23.75, Lon: -76.23426, Lat: 43.10642, Depth: 51.78, Depth Range: 120.0
    HF Datetime: 10/12/05 14:28:23.75, Lon: -76.23426, Lat: 43.10642, Depth: 49.27, Depth Range: 120.0
    LF Datetime: 10/12/05 14:28:23.80, Lon: -76.23426, Lat: 43.10642, Depth: 49.83, Depth Range: 120.0
    HF Datetime: 10/12/05 14:28:23.86, Lon: -76.23426, Lat: 43.10642, Depth: 49.23, Depth Range: 120.0


Of course, printing the output doesn't really help anybody, but writing to a CSV is a little bit more helpful. The problem still exists of dealing with the reflection data (200 elements long), which I've dealt with in the past by converting each integer (from 0 to 255) to a 2-character hex digit. This allows other programs (like R, or reading the file back in to Python) the ability to read the data more easily. Even looking at the hex string can be useful (non zeros tend to pop out quite nicely).

```python
with open('sample_odc/output_lf.csv', 'w') as out:
    out.write('datetime,lon,lat,depth,depthrange,data\n')
    def handle_data_lf(datetime, lon, lat, depth, depthrange, data):
        out.write(','.join((datetime, str(lon), str(lat), str(depth), str(depthrange),
                           ''.join(['%0.2X' % val for val in data]))) + '\n')
    read_odc('sample_odc/20051012142823.odc', handle_lf=handle_data_lf)

pd.read_csv('sample_odc/output_lf.csv').head()
```

<div>
<table class="dataframe" border="1">
<thead>
<tr style="text-align: right;">
<th>datetime</th>
<th>lon</th>
<th>lat</th>
<th>depth</th>
<th>depthrange</th>
<th>data</th>
</tr>
</thead>
<tbody>
<tr>
<td>NaN</td>
<td>NaN</td>
<td>NaN</td>
<td>49.87</td>
<td>120.0</td>
<td>A7CD9B5700000000000010020000000000000000000000...</td>
</tr>
<tr>
<td>10/12/05 14:28:23.64</td>
<td>-76.234264</td>
<td>43.106416</td>
<td>49.87</td>
<td>120.0</td>
<td>A7CD9B0700000000000000000000000000000000000000...</td>
</tr>
<tr>
<td>10/12/05 14:28:23.75</td>
<td>-76.234264</td>
<td>43.106416</td>
<td>51.78</td>
<td>120.0</td>
<td>A7CD9B6800000000000000000000000000000000000000...</td>
</tr>
<tr>
<td>10/12/05 14:28:23.80</td>
<td>-76.234264</td>
<td>43.106416</td>
<td>49.83</td>
<td>120.0</td>
<td>B7CD9B2700000000000000320000000000000000000000...</td>
</tr>
<tr>
<td>10/12/05 14:28:23.91</td>
<td>-76.234264</td>
<td>43.106416</td>
<td>50.36</td>
<td>120.0</td>
<td>A7CD9B6800210000000000010000000000000000000000...</td>
</tr>
</tbody>
</table>
</div>



For visuzliation, there are a few options. The easiest is the 'dumb' option, whereby the depthrange is ignored. I often do not change the depth range for this express purpose, but for other options you can see below.

**Note**: We are going to start loading the data into memory, so be very careful when reading an entire file, as the files can get really, really big. Make sure you try a small amount of data before going big!


```python
import numpy as np

alldata = []
def handle_data_lf(datetime, lon, lat, depth, depthrange, data):
    # because the data is not always exactly 200 elements long,
    # we need to manually ensure the output is 200 elements
    # or it won't load into numpy properly
    if len(data) == 200:
        alldata.append(data)
    elif len(data) > 200:
        alldata.append(data[:200])
    else:
        alldata.append(data + [0 for i in range(200-len(data))])

read_odc('sample_odc/20110627125717.odc', handle_lf=handle_data_lf)

np.array(alldata)
```




    array([[255, 255, 255, ...,   0,   0,   0],
           [255, 255, 255, ...,   0,   0,   0],
           [255, 255, 255, ...,  35,   0,   0],
           ..., 
           [255, 255, 255, ...,  68,  68,  51],
           [255, 255, 255, ...,  35,   1,   0],
           [255, 255, 255, ...,  85,  52,  51]])




```python
import matplotlib.pylab as plt
%matplotlib inline

plt.imshow(np.array(alldata).T, aspect='auto')
```




    <matplotlib.image.AxesImage at 0x11012cba8>




![png](output_17_1.png)


The 'dumb' way works great, except when there is a change in the depth range, which makes the output inconsistent. There are probably a few approaches, but the first that comes to mind is getting the data in x/y/z, where the x is the ping number (or distance along a transect), y is the actual depth of the measurement, and z is the strength of the return.


```python
xs = []
ys = []
zs = []
pingnum = 0
def handle_data_lf(datetime, lon, lat, depth, depthrange, data):
    global pingnum
    
    if len(data) > 200:
        data = data[:200]
    elif len(data) < 200:
        data = data + [0 for i in range(200-len(data))]
    for i in range(200):
        xs.append(pingnum)
        ys.append(i*depthrange/200.0)
        zs.append(data[i])
    
    pingnum += 1
    if pingnum == 500:
        return False
read_odc('sample_odc/20051012142823.odc', handle_lf=handle_data_lf)

df = pd.DataFrame({'x':xs, 'y':ys, 'z':zs})
df.head()
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>x</th>
      <th>y</th>
      <th>z</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>0</td>
      <td>0.0</td>
      <td>167</td>
    </tr>
    <tr>
      <th>1</th>
      <td>0</td>
      <td>0.6</td>
      <td>205</td>
    </tr>
    <tr>
      <th>2</th>
      <td>0</td>
      <td>1.2</td>
      <td>155</td>
    </tr>
    <tr>
      <th>3</th>
      <td>0</td>
      <td>1.8</td>
      <td>87</td>
    </tr>
    <tr>
      <th>4</th>
      <td>0</td>
      <td>2.4</td>
      <td>0</td>
    </tr>
  </tbody>
</table>
</div>



Unfortunately there is no easy way to plot this without interpolation, although if what is desired is a true transect using distance as the x-axis, this is probably the only way. A less involved method (ignoring distance along the transect) is to pick a depth range at the start, and resample each array as the file is read.


```python
plot_depthrange = 40.0
plot_npixels = 500
plot_res = plot_depthrange / plot_npixels
depthvals = np.arange(0, plot_depthrange, plot_res)
alldata = []

def handle_data_lf(datetime, lon, lat, depth, depthrange, data):
    if depthrange == 0:
        return
    if len(data) > 200:
        data = data[:200]
    elif len(data) < 200:
        data = data + [0 for i in range(200-len(data))]
    old_depthvals = np.arange(0, depthrange, depthrange/200.0)
    resampled = np.interp(depthvals, old_depthvals, data, right=0)
    alldata.append(resampled)
    

read_odc('sample_odc/20140711114326.odc', startline=29000,
         maxlines=6000, handle_lf=handle_data_lf)
plt.imshow(np.array(alldata).T, aspect='auto')
```




    <matplotlib.image.AxesImage at 0x1083e7080>




![png](output_21_1.png)


## Closing comments

Processing data from the HydroBox isn't easy, and it can't be said that the HydroBox program does a much better job. At least the above code allows the user some flexibility on cropping, resampling, and parsing some of the data for the purposes of diagrams and further geoprocessing.

