---
title: Purposeful Issue Organizing
author: Dewey Dunnington
date: '2019-07-22'
slug: purposeful-issue-organizing
categories: []
tags:
  - R
  - issues
subtitle: ''
summary: ''
authors: []
lastmod: '2019-07-22T11:09:22-03:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

One of my ongoing tasks this summer was to organize the [open issues in ggplot2](https://github.com/tidyverse/ggplot2/issues). Every issue was opened by a user who thought ggplot2 should do something different than it currently was doing, and remained open because there was no consensus about how (or if) the current behavior should change. Before this internship I had always been the user, and had always been a little frustrated at the reluctance to change anything. After reading hundreds of issue comments (and sifting through the reverse-dependency checks that were completed prior to the release of [ggplot2 3.2.0](https://www.tidyverse.org/articles/2019/06/ggplot2-3-2-0/)), I get it: **ggplot2 has been around for 10 years and changing anything will probably cause an issue for somebody else**.

That said, I tried not to forget what it was like to be a user frustrated with a piece of software. I settled on the idea that **for every issue there is a user-facing issue and a developer-facing issue**. As maintainers we're familiar with the documentation and we're really good at using the software. It's easy to say things like, "you need to make a reprex", "you didn't read the documentation for X", or "you just need to do X". None of these responses result in a positive user experience, and every response is indexed by Google and shows up when the next person makes the same mistake. Dismissive responses also fail to acknowledge the developer-facing issue, and there is almost always a developer-facing issue. If nothing else, it's that the documentation was not clear, not accessible, or that there were confusing names (that `xlim(...)` and `ylim(...)` do different things than `coord_cartesian(xlim = ..., ylim = ...)` is a common source of confusion among issue-openers in ggplot2).

I certainly wasn't perfect, but inspired by excellent examples of issue gardening from repos maintained by the [tidyverse](https://tidyverse.org) team and [Greg Wilson](http://third-bit.com/)'s excellent [tidyverse instructor training](https://education.rstudio.com/trainers), I tried to approach issue organizing as an educational experience. By the end there were a couple of things that I tried to do on purpose:

- Provide a [reprex](https://reprex.tidyverse.org/) if possible to do so, particularly if the nature of the question suggested that it might not be possible for the person who opened the issue to figure out how to do so themselves. I could see how sometimes providing a reprex for the issue opener robs them of the opportunity to learn how, but making a really good one for somebody that was never going to I think is quite positive. I tried to ask the issue opener "is this what you meant by that?" after a few times getting it wrong.

- Provide a workaround, if possible. Issues show up when people search for error messages, and a good workaround will probably be useful for the tens to hundreds of other "lurkers" that read issue threads but might never open an issue. This serves to address the user-facing issue, and could be as simple as a link to the documentation ([pkgdown](https://pkgdown.r-lib.org/) sites are awesome for this). Workarounds can get out of hand quickly as the developer-facing issue discussion can get lost. A few times I referred people to [RStudio Community](https://community.rstudio.com/) or marked the comment as "off topic", but most times issue-openers were thankful, polite, and moved on. I think providing a workaround for a simpler/more general use case than that provided by the issue-opener is better than solving a specific issue...it requires the issue opener to do some work, but is more useful for the "lurkers" that stumble upon the issue thread later.

- Focus discussion on the developer-facing issue. Usually this involved re-titling the issue, adding tags, and/or adding a comment identifying the developer-facing issue. Sometimes this can be a question like "is it clear enough in the documentation that X should be Y?", or it might be identifying the exact feature that the issue opener is looking for. That isn't to say something needs to be done for every issue that is opened, but I think the step of figuring out what *could* be done needs to happen before deciding that it's not worth it.

- If it's decided that nothing should be done, give the issue-opener the opportunity to close the issue. It never feels nice to have an issue closed on you, particularly if the maintainer didn't actually understand your issue. I frequently misunderstood the issue that an issue-opener intended and have definitely given inadvertent misinformation when commenting on issue. I've had the same done to me by maintainers of other packages. Premature closing of an issue is a negative experience for an issue-opener that is easy to avoid.

As an issue opener you can do all of these things too, and maintainers will love you for it. Providing a [reprex](https://reprex.tidyverse.org/) is particularly time-saving and makes it far more likely that a maintainer is going to consider your issue. You can provide your own workaround, too. Demonstrating that the current workaround is totally crazy for a valid use-case is a good way to demonstrate that you have a feature worth adding (or a bug worth fixing). If you figure out what the developer-facing issue might be in advance, title your issue as such and focus the discussion on that. If you are just looking for help using a package (i.e., if you only have a user-facing issue), [RStudio Community](https://community.rstudio.com/) is a better fit (if there's a developer-facing issue, often someone there will suggest that you open an issue and will help you do so).

Whether you're an issue-opener or a maintainer, the advice from Greg's final slide of the tidyverse instructor training holds true: **Be kind - the rest is details**.
