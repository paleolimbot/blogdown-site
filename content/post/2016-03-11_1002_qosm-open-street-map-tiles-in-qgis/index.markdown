---
title: 'qosm: Open Street Map tiles in QGIS'
author: Dewey Dunnington
date: '2016-03-11'
slug: []
categories: []
tags: ["gis", "PyQt", "Python", "qosm", "Releases"]
subtitle: ''
summary: ''
authors: []
lastmod: '2016-03-11T16:56:45+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

There was once a time in QGIS where getting Open Street Map basemaps was tricky. ArcGIS long since solved this problems with ready-made basemaps available with a few clicks, but in QGIS there was the <a href="https://plugins.qgis.org/plugins/openlayers_plugin/">OpenLayers plugin</a>, which was a rough go to use. In the first GIS short course I taught, this was the only option, so over Christmas break I decided to write something better. The result is <a href="https://plugins.qgis.org/plugins/qosm/">QOSM</a>, although since writing it I've discovered that the <a href="https://plugins.qgis.org/plugins/quick_map_services/">QuickMapServices plugin</a>, while much less searchable, is much more effective. Still the person in charge of the QGIS plugin repository let in the plugin saying it would help inspire improvement. 

[caption id="attachment_1003" align="none" width="491"]<img src="Screenshot-from-2016-03-11-16-38-11.png" alt="Adding a QOSM Layer" width="491" height="322" class="size-full wp-image-1003" /> Adding a QOSM Layer[/caption]

Still, I think my plugin does a few things better than QMS, but QMS really does everything I'd ever wanted a basemap plugin to do. The main difference is the cacheing - QOSM is designed to store tiles indefinitely and store a lot of them (it even has an option to cache everything for a whole area), whereas QMS is designed to download tiles on the fly (although you can change the global cacheing expiry time in QGIS main preferences to get QMS to cache things for longer).

[caption id="attachment_1005" align="none" width="336"]<img src="Screenshot-from-2016-03-11-16-51-09.png" alt="QOSM will happily download any number of tiles for a given area." width="336" height="247" class="size-full wp-image-1005" /> QOSM will happily download any number of tiles for a given area.[/caption]

The main benefit of writing QOSM was to get some insight into the <a href="http://docs.qgis.org/testing/en/docs/pyqgis_developer_cookbook/plugins.html">QGIS plugin structure</a>, which is quite powerful, if poorly documented. Plugins are written in Python (2), and allow easy creating of user interfaces using PyQt bindings for the Qt framework. The Python Console plugin allows users to easily run scripts that reference the QGIS Python interface, but plugins allow users to take control of the canavas, projects, loading layers, and even calling processing functions within the main user interface, and are distributed by the QGIS plugin repository. A <a href="http://docs.qgis.org/testing/en/docs/pyqgis_developer_cookbook/">manual of QGIS Python functionality</a> is available on the QGIS website, as well as the <a href="http://qgis.org/api/classQgisInterface.html">API reference</a> (the API reference is for the C++ classes, but calling these in Python works exactly the same in most cases).

So there you have it, it's a little anti-climatic, but if you need to load a hillshade layer or cache an entire province worth of tiles or aerial imagery, QOSM is what you're looking for.

[caption id="attachment_1004" align="none" width="600"]<img src="Screenshot-from-2016-03-11-16-40-18-1024x627.png" alt="A QOSM Tile Layer in QGIS" width="600" height="367" class="size-large wp-image-1004" /> A QOSM Tile Layer in QGIS[/caption]

[caption id="attachment_1006" align="none" width="605"]<img src="Screenshot-from-2016-03-11-16-43-43.png" alt="The QOSM Settings dialog." width="605" height="405" class="size-full wp-image-1006" /> The QOSM Settings dialog.[/caption]

