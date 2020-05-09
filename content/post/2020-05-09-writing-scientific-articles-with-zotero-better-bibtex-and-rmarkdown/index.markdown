---
title: Getting started with Zotero, Better BibTeX, and RMarkdown
author: Dewey Dunnington
date: '2020-05-09'
slug: getting-started-zotero-better-bibtex-rmarkdown
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2020-05-09T10:29:58-03:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

I have to start with saying that there's a lot of ways to write scientific articles with all of these tools. In particular, there's some [great guides from rOpenSci](https://github.com/ropensci/rrrpkg), [packages with LaTeX templates for major publishers](https://github.com/rstudio/rticles), and [R packages to help with reproducible documents](https://github.com/benmarwick/rrtools). For all of these, I think there's some degree of familiarity with programming or LaTeX that's needed to get started. Everybody has their own workflow for writing (the hard part!), and I thought I'd share the barebones pieces of mine for anybody interested in getting started.

## Zotero

The [Zotero reference manager](https://zotero.org/) is at the heart of my workflow. In particular, I use the [browser plugin](https://www.zotero.org/download/connectors), which puts a little icon at the top right corner of a page and will automatically add the correct article metadata to your library whenever you're on a page with reference information. It's not always 100% correct, but it's always faster than entering all the information yourself! Zotero does lots of other organizing as well, but I almost always just hit the "import" button (which also downloads the PDF, if available) and move on. I've learned that if I don't give every article a "tag" or drag it into a collection, than it's unlikely that I'll find it again later on...

![The Zotero plugin for Firefox](browser-plugin.png)

## RMarkdown

RMarkdown is a big topic, but there's a few specific things about RMarkdown that make it really useful for articles. The first is formatting! Pretty much every scientific article you will ever write is composed of first, second, and third-level headings. In Markdown, these translate really well:

    # Introduction
    
    ...
    
    # Methods
    
    ...
    
    ## Study area
    
    ...
    
    ### Specific lake
    
    ...
    
You will need a suitable "reference docx" to convert these to Word in a way that's close to what you'll have to submit. You can use [the same default styles template that I use](StylesTemplate.docx) and modify the styles to your (or your supervisor's) liking.
    
Second is referencing: using Pandoc's reference format, you can embed plain-text references in your writing. The two forms I use are the classic "end of sentence" citation ("This thing is totally true (Dunnington 2018).") and the "references are nouns" citation ("Dunnington (2018) says this thing is totally true."). In RMarkdown, the first sentence would look like this: `This thing is totally true [@dunnington18].` ...and the second sentence would look like this: `@dunnington18 says this thing is totally true.`. Embedding references in this way is a life-saver if you have an article that might get submitted to multiple journals (or be included in your thesis *and* submitted to a journal). This is particularly true if you've ever submitted an article to a journal that requires numbered references. Your RMarkdown source will look the same! This is great for copy-and-paste friendly writing.

To make all this work, I use YAML front-matter that looks like this:

    ---
    title: "title of paper"
    author: "Author One^1^, Corresponding Author^1,\\*^"
    date: "^1^I co-opt the date field for affilitaions, and nobody has ever complained"
    output:
      word_document:
        reference_docx: StylesTemplate.docx
        keep_md: true
    csl: CJFAS.csl
    bibliography: references.bib
    ---
    
Here the `csl` is a file from the [Zotero style repository](https://www.zotero.org/styles) for the journal you're submitting to (or one close enough that you don't have to edit out a million commas and semi-colons right before you submit), and the `bibliography` is a file in BibLaTeX or BibTeX format (Zotero will happily export either). More on that in the next section!

## Better BibTex

The [Better BibTex plugin for Zotero](https://retorque.re/zotero-better-bibtex/) is what makes connecting Zotero to RMarkdown downright enjoyable! The plugin does a few things that make this work. First, it generates a "citation key" for all of your references. This is what you need to use RMarkdown-style citations, where  `@citation_key` refers to the item that has `citation_key` in your bibliography file. Because I keep references in my head as "Author [et al.] (Date)", I made Better BibTeX generate citation keys like this too. Once you've installed the plugin, the preferences are under a new tab in the Zotero preferences pane:

![The Better BibTeX preferences pane](bbt_prefs.png)

My "citation key format" is this, and you can [roll your own](https://retorque.re/zotero-better-bibtex/citing/#configurable-citekey-generator) if you keep references in your head differently. If you don't care about how this looks in your RMarkdown, you can use the default and use "Ctrl-Shift-C" in Zotero to copy the citation key (and then paste it into RMarkdown).

```
[auth.etal:lower:replace=.,_][>0][shortyear]|[veryshorttitle][shortyear]
```

I tend to write first and worry about citations later, but for huge documents it can be nice to keep your "bibliography.bib" file relatively up-to-date. I used to do this using a Zotero "collection" (folder) and  exporting (right click and "export item" in Zotero) on a regular basis, but that can actually be pretty rough to do if you update this frequently. To get around this, I wrote the [rbbt package](https://github.com/paleolimbot/rbbt) package, which includes an RStudio addin to insert the BibLaTeX/BibTeX version of whatever is currently selected in the Zotero window. I use this so frequently that I have it wired to a keyboard shortcut!

<video controls src="rbbt-addin.mp4"></video>

## Final thoughts

There's lots of ways to mix-and-match your workflow! The key message for me is that you shouldn't have to spend a lot of time formatting and referencing: the workflow should be about writing!
