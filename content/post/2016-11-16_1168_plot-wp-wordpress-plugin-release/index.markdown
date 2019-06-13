---
title: 'Plot.wp Wordpress Plugin Release'
author: Dewey Dunnington
date: '2016-11-16'
slug: []
categories: []
tags: ["php", "Releases", "web development", "wordpress plugins"]
subtitle: ''
summary: ''
authors: []
lastmod: '2016-11-16T15:33:05+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

Most of my development stays away from the realm of the web, but recently I've been stewing over a method of compiling paleolimnological data in some centralized repository such that it can be retrieved dynamically. I was also browsing in a local bookstore a few months ago and came across an interesting book entitled <a href="https://www.amazon.com/Building-Web-Apps-WordPress-Application/dp/1449364071/ref=sr_1_4?ie=UTF8&qid=1479323852&sr=8-4&keywords=wordpress+web+application+development">Building Web Apps with WordPress: WordPress as an Application Framework</a>. My involvement with Wordpress has mostly been as a user, but in browsing the book I can appreciate how Wordpress takes care of the data structures and frameworks that are the foundation of any web application. As an exercise, I developed a <a href="https://en-ca.wordpress.org/plugins/plotwp/">tiny Wordpress plugin</a> that uses the <a href="https://plot.ly/javascript/">Plotly.js plotting API</a> to embed plots in posts and pages. It's not particularly useful at the moment (currently embedding a plot requires typing out JSON, which if you've ever tried it, is not fun), but it serves as a useful outlet to delve into the web development scene, from which I've so far been absent.

[plotly]
{
  "data": [{
    "x": [1, 2, 3, 4],
    "y": [27, 28, 29, 50],
    "mode": "lines+markers",
    "type": "scatter"
  }],
  "layout": {
    "margin": {
      "t": 40, "r": 40, "b": 40, "l":40
    }
  }
}
[/plotly] 

(An indicator of how hard this is to use is probably the fact that I couldn't muster a more impressive example plot than this for its inaugural release post)