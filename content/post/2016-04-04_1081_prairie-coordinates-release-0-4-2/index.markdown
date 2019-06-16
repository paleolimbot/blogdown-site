---
title: 'Prairie Coordinates release 0.4.2'
author: Dewey Dunnington
date: '2016-04-04'
slug: []
categories: []
tags: ["prairie coordinates", "Releases"]
subtitle: ''
summary: ''
authors: []
lastmod: '2016-04-04T13:39:43+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
aliases: [/archives/1081]
---


After an email complaint about the app crashing when the "search by GPS" screen was loaded, I looked into some of the changes that were introduced with the Android 6.0 platform. The issue was a `SecurityException` that was thrown because in Android 6.0, certain permissions require the app to explicitly ask the user, including the GPS permission. This move appears to be in line with the iOS devices, although it would be nice to have some warning from Google when issues like this break backwards compatibility with existing apps since apps are almost all ratings-driven. Luckily my users continue to be great and keep telling me about problems instead of complaining about them!

Check out the new release on the [Google Play Store](https://play.google.com/store/apps/details?id=ca.fwe.pcoordplus)
