---
title: Cribbage in R using R6 and vctrs
author: Dewey Dunnington
date: '2020-02-23'
slug: cribbage-in-r-using-r6-and-vctrs
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2020-02-23T09:09:00-04:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

This week in random R tutorials...how to program a deck of cards as a [vctrs](https://vctrs.r-lib.org/) class, using [R6](https://r6.r-lib.org/) to keep track of multiple player hands! It was inspired by the [deck of cards tutorial](https://rstudio-education.github.io/hopr/project-2-playing-cards.html) in Hands On Programming with R, except this version is more about creating interfaces than about learning R programming. It was also inspired by a game of cribbage with my wife, in which there were many exclamations of "oooooh! which cards should I leave to the crib!?". It's not until the end of the post that  I do the  simulation, but that's where this is all headed.

First, we need a way to represent a "card". In Hands On Programming with R they use a data frame...here I'm going to use strings, mostly a "vector" of cards makes sense to me. It's not too much of a stretch that the following represents  the 4 of diamonds, the 4 of clubs, the jack of hearts, and the 4 of spades.


```r
sample_cards <- c("4d", "4c", "Jh", "4s")
```

From there, we can do some string manipulation to get the information we need out of a card. I've coded this specific to cribbage, where aces are low, but you could code another game by rearranging the factor levels (the  case of aces high *and* low is tricky...you'd need another function that computes a `diff()` of some kind).


```r
library(stringr)

card_suit <- function(x) {
  str_extract(x, "[a-z]$")
}

card_rank <- function(x) {
  factor(
    str_extract(x, "^1?[0-9JQK]"),
    levels = c(1:10, "J", "Q", "K")
  )
}

card_value <- function(x) {
  number <- as.numeric(str_extract(x, "^[0-9]+"))
  number[is.na(number)] <- 10
  number
}

card_suit(sample_cards)
```

```
## [1] "d" "c" "h" "s"
```

```r
card_rank(sample_cards)
```

```
## [1] 4 4 J 4
## Levels: 1 2 3 4 5 6 7 8 9 10 J Q K
```

```r
card_value(sample_cards)
```

```
## [1]  4  4 10  4
```

### Scoring a cribbage hand

There's a couple of key concepts in [scoring cribbage](https://bicyclecards.com/how-to-play/cribbage/), one of which is the "fifteen" (cards whose value adds to 15 count for two points). Given a vector of cards, we can compute this using `card_value()`:


```r
is_fifteen <- function(x) {
  sum(card_value(x)) == 15
}

is_fifteen(c("Jd", "5h"))
```

```
## [1] TRUE
```

```r
is_fifteen(c("Jd", "4h"))
```

```
## [1] FALSE
```

Next is the pair. Pairs count for two points, but only works for two-card combinations (three-of-a-kind is counted as three pairs).


```r
is_pair <- function(x) {
  (length(x) == 2) && (card_rank(x[1]) == card_rank(x[2]))
}

is_pair(c("Jd", "Jh"))
```

```
## [1] TRUE
```

```r
is_pair(c("Jd", "Jh", "Jc"))
```

```
## [1] FALSE
```

```r
is_pair(c("Jd", "4h"))
```

```
## [1] FALSE
```

A run here is defined as sequential `card_rank()`s of 3 or more:


```r
is_run <- function(x) {
  ranks <- card_rank(x)
  (length(x) >= 3) &&
    all(diff(sort(as.integer(ranks))) == 1)
}

is_run(c("9h", "Jsd", "10d"))
```

```
## [1] TRUE
```

```r
is_run(c("9h", "10d", "Qs"))
```

```
## [1] FALSE
```

```r
is_run(c("9h", "10d"))
```

```
## [1] FALSE
```

The flush here is identical `card_suits()` of the entire hand and maybe the starter, depending on whether it's the crib or not (a flush in the crib requires the starter card to be the same suit as the flush in the hand). The crib logic can't be dealt with here, so `is_flush()` just tests for identical suit.


```r
is_flush <- function(x) {
  length(unique(card_suit(x))) == 1
}

is_flush(c("4h", "3h"))
```

```
## [1] TRUE
```

```r
is_flush(c("4h", "3d"))
```

```
## [1] FALSE
```

Finally, we have nibs (sometimes "nobs" or "the right jack"), which is one point if it's the same suit as the starter card (the card that got turned up when the non-dealer cut the deck after the crib discard).


```r
is_nibs <- function(x, starter) {
  (length(x) == 1) && 
    (card_rank(x) == "J") &&
    (card_suit(x) == card_suit(starter))
}

is_nibs("Jh", starter = "8h")
```

```
## [1] TRUE
```

```r
is_nibs("4h", starter = "8h")
```

```
## [1] FALSE
```

```r
is_nibs("Jh", starter = "8d")
```

```
## [1] FALSE
```

I think it makes the scoring code a little easier if there's functions for each *number* of cards, particularly because the strategy I had in mind operates on all the unique combinations of the hand. In that case, shorter runs would get double-counted (1, 2, 3, 4 gets counted as four points, not two runs of 3).


```r
score_five <- function(x) {
  is_fifteen(x) * 2 + 
    is_run(x) * 5
}

score_four <- function(x, count_runs) {
  is_fifteen(x) * 2 + 
    is_run(x) * 4 * count_runs
}

score_three <- function(x, count_runs) {
  is_fifteen(x) * 2 +
    is_run(x) * 3 * count_runs
}

score_two <- function(x) {
  is_fifteen(x) * 2 + 
    is_pair(x) * 2
}
```

Now we're ready to score! There's a few things that make this tricky, notably the whole "flush doesn't count in in the crib without all the cards" rule. I also make liberal use of the fact that `TRUE` gets coerced to `1` when used with math (without it, there's a lot of `ifelse()`s and it looks ugly).


```r
library(purrr)

card_combn <- function(x, m) {
  combn(x, m, simplify = FALSE)
}

score_hand <- function(hand, starter, crib = FALSE) {
  full_hand <- c(hand, starter)
  
  score <- score_five(full_hand)
  
  if (crib) {
    score <- score + is_flush(full_hand) * 5
  } else if (is_flush(full_hand)) {
    score <- score + 5
  } else if (is_flush(hand)) {
    score <- score + 4
  }
  
  has_nibs <- any(map_lgl(hand, is_nibs, starter))
  score <- score + has_nibs * 1
  
  has_run <- is_run(full_hand)
  hand_four <- card_combn(full_hand, 4)
  scores_four <- map_dbl(hand_four, score_four, count_run = !has_run)
  
  has_run <- any(map_lgl(hand_four, is_run))
  hand_three <- card_combn(full_hand, 3)
  scores_three <- map_dbl(hand_three, score_three, count_run = !has_run)
  
  hand_two <- card_combn(full_hand, 2)
  scores_two <- map_dbl(hand_two, score_two)
  
  score +
    sum(scores_four) + 
    sum(scores_three) +
    sum(scores_two)
}
```

Let's see if it scores the perfect hand!


```r
score_hand(c("5h", "5d", "5s", "Jc"), starter = "5c")
```

```
## [1] 29
```

...and this one ("fifteen two, fifteen four, pair six, and a run for nine!"):


```r
score_hand(c("5h", "6d", "7s", "Jc"), starter = "Jd")
```

```
## [1] 9
```

...and *this* one ("fifteen two, fifteen four, and a run for eight!"):


```r
score_hand(c("5h", "6d", "7s", "8h"), starter = "Jd")
```

```
## [1] 8
```

Finally, we make sure that flushes are counted properly:


```r
score_hand(c("2h", "6h", "8h", "Kh"), starter = "Jh")
```

```
## [1] 5
```

```r
score_hand(c("2h", "6h", "8h", "Kh"), starter = "Jh", crib = TRUE)
```

```
## [1] 5
```

```r
score_hand(c("2h", "6h", "8h", "Kh"), starter = "Jd")
```

```
## [1] 4
```

```r
score_hand(c("2h", "6h", "8h", "Kh"), starter = "Jd", crib = TRUE)
```

```
## [1] 0
```

### Playing cards in vctrs

It's a little hard to look at the vector `c("5h", "5d", "5s", "Jc")` and intuitively know we're looking at a deck of cards. To make it a bit more magical (and easier to debug), I think that a [vctrs](https://vctrs.r-lib.org/) class would work well here. We essentially have a character vector subclass, and if we want to make sure that validation, subsetting, subset assignment, coercion, and `c()` work properly, there's no easier way to do it than vctrs.


```r
library(vctrs)
```

The next few chunks are basically the same as the [intro tutorial](https://vctrs.r-lib.org/articles/s3-vector.html), but instead of extending a numeric class, we're extending a character class. The `new_card()` function is minimal...it performs no coercion, it just makes sure the data is the right type and gives it a class. `validate_card()` makes sure it's an actual card value, and `card()` does validation and coersion. Both `card()` and `new_card()` have a default length of zero so they can be used as prototypes in `vec_cast()`.


```r
new_card <- function(x = character()) {
  vec_assert(x, character())
  new_vctr(x, class = "card")
}

validate_card <- function(x) {
  is_valid <- is.na(x) | str_detect(vec_data(x), "^(10[cdhs])|([1-9JQK][cdhs])$")
  if (any(!is_valid)) {
    bad_values <- paste(unique(x[!is_valid]), collapse = ", ")
    stop(glue::glue("Bad card values: {bad_values}"))
  }
  
  invisible(x)
}

card <- function(x = character()) {
  x <- vec_cast(x, character())
  # '__NA__' is a very werid but common value that is passed in
  # in some versions of the R notebook
  x[x == "__NA__"] <- NA_character_
  cards <- new_card(x)
  validate_card(cards)
  cards
}
```

Right off the bat we get a reasonable print method:


```r
card("4h")
```

```
## <card[1]>
## [1] 4h
```

...but some really basic coercion doesn't work:


```r
as.character(card("4h"))
```

```
## Error: Can't cast `x` <card> to `to` <character>.
```

```r
c(card("4h"), "4d")
```

```
## Error: No common type for `..1` <card> and `..2` <character>.
```

```r
c(card("4h"), card("4d"))
```

```
## <card[2]>
## [1] 4h 4d
```

To make these work, we'll need [some boilerplate](https://vctrs.r-lib.org/articles/s3-vector.html#double-dispatch). It's a bit of code to wrap one's mind around, but it's easy to get coercion wrong, and there's no easier way to get it right than the vctrs style.


```r
vec_ptype2.card <- function(x, y, ...) UseMethod("vec_ptype2.card", y)
vec_ptype2.card.default <- function(x, y, ..., x_arg = "x", y_arg = "y") {
  vec_default_ptype2(x, y, x_arg = x_arg, y_arg = y_arg)
}

vec_cast.card <- function(x, to, ...) UseMethod("vec_cast.card")
vec_cast.card.default <- function(x, to, ...) vec_default_cast(x, to)
```

Without the implementing the basic methods, we're actually in a worse-off spot than we were:


```r
as.character(card("4h"))
```

```
## Error: Can't cast `x` <card> to `to` <character>.
```

```r
c(card("4h"), "4d")
```

```
## Error: No common type for `..1` <card> and `..2` <character>.
```

```r
c(card("4h"), card("4d"))
```

```
## Error: Can't cast `x` <card> to `to` <card>.
```

With some basic method implementations, we can get most of the behaviour one would expect to "just work". Again, from a developer perspective it's a bit of code, but from the user's perspective it "just works".


```r
vec_ptype2.card.card <- function(x, y, ...) new_card()
vec_ptype2.card.character <- function(x, y, ...) character()
vec_ptype2.character.card <- function(x, y, ...) character()

vec_cast.card.card <- function(x, to, ...) x
vec_cast.card.character <- function(x, to, ...) card(x)
vec_cast.character.card <- function(x, to, ...) vec_data(x)

as.character(card("4h"))
```

```
## [1] "4h"
```

```r
c(card("4h"), "4d")
```

```
## [1] "4h" "4d"
```

```r
c(card("4h"), card("4d"))
```

```
## <card[2]>
## [1] 4h 4d
```

In addition to `c()` and `as.character()` working like we'd expect, we're protected against invalid playing card values in the constructor and in subset assignment:


```r
card("4r")
```

```
## Error in validate_card(cards): Bad card values: 4r
```

```r
cards <- card(c("4d", "4h"))
cards[1] <- "4r"
```

```
## Error in validate_card(cards): Bad card values: 4r
```

```r
cards[1:2] <- c("5d", "5h")
cards
```

```
## <card[2]>
## [1] 5d 5h
```

It's really hard to get the details right implementing it yourself!

Another way to make the playing card class "magical" is to introduce pretty printing. There are [unicode characters for the suits](https://en.wikipedia.org/wiki/Playing_cards_in_Unicode), which we can use in a `format()` method implementation to get pretty printing on the console (and pretty printing in a tibble!). I'm using a [named character vector as a lookup table](https://adv-r.hadley.nz/subsetting.html#lookup-tables) here, which I think makes the format method quite succinct.


```r
format.card <- function(x, ...) {
  unicode_suits <- c(
    "c" = "\U2663", "d" = "\U2666",
    "h" = "\U2665", "s" = "\U2660"
  )
  
  number <- card_rank(x)
  suit <- card_suit(x)
  
  unicode_cards <- str_c(number, unicode_suits[suit])
  format(str_pad(unicode_cards, 3), quote = FALSE, ...)
}

card(c("4c", "Jd"))
```

```
## <card[2]>
## [1]  4♣  J♦
```

```r
tibble::tibble(x = card(c("4c", "Jd")))
```

```
## # A tibble: 2 x 1
##   x     
##   <card>
## 1  4♣   
## 2  J♦
```

Even *more* magical would  be colour! This can be done using the [crayon](https://github.com/r-lib/crayon) (or [cli](https://cli.r-lib.org/)) package and a [pillar](https://github.com/r-lib/pillar)::pillar_shaft() implementation to get coloured output in tibble printing (unfortunately this doesn't show up in blogdown output, but it's really cool looking!). I think blue makes sense for `NA`, because black or red might make it blend in as a regular card.


```r
card_format_color <- function(x, ...) {
  colors <- c(
    "c" = "black", "d" = "red", 
    "h" = "red" , "s" = "black"
  )
  color <- colors[card_suit(x)]
  color[is.na(color)] <- "blue"

  unicode_cards <- format(x, ...)
  unicode_cards[color == "red"] <- crayon::red(unicode_cards[color == "red"])
  unicode_cards[color == "blue"] <- crayon::blue(unicode_cards[color == "blue"])
  unicode_cards
}

pillar_shaft.card <- function(x, ...) {
  pillar::new_pillar_shaft_simple(card_format_color(x))
}

tibble::tibble(x = card(c("4c", "Jd", NA)))
```

```
## # A tibble: 3 x 1
##   x     
##   <card>
## 1  4♣   
## 2  J♦   
## 3 NA
```

I can't find a better way to get this into the print method than by rewriting R's default print method, but it's just so magical! The key bit is that you can implement `obj_print_data()` to use the default vctrs header.


```r
obj_print_data.card <- function(x, ..., width = 43) {
  if (length(x) == 0) {
    return(invisible(x))
  }
  
  unicode_cards <- card_format_color(x)
  
  label_width <- nchar(length(x)) + 3
  card_width <- max((width + 1 - label_width) %/% 4, 1)
  card_rows <- ((length(x) - 1) %/% card_width) + 1
  
  for (row in seq_len(card_rows)) {
    first_index <- ((row - 1) * card_width) + 1
    last_index <- min(first_index + card_width - 1, length(x))
    cat(
      str_c(
        str_pad(str_c("[", first_index, "]"), width = label_width, side = "right"), 
        str_c(unicode_cards[first_index:last_index], collapse = " "),
        "\n"
      )
    )
  }
  
  invisible(x)
}

card(c("5c", "Jh"))
```

```
## <card[2]>
## [1]  5♣  J♥
```

I know, it's probably over the top for this post, but it just looks so nice! And it makes it a lot easier to count cribbage hands when the cards actually look a tiny bit like cards.


```r
# print the whole deck!
card(
  c(
    paste0(c(1:10, "J", "Q", "K"), "c"),
    paste0(c(1:10, "J", "Q", "K"), "d"),
    paste0(c(1:10, "J", "Q", "K"), "h"),
    paste0(c(1:10, "J", "Q", "K"), "s")
  )
)
```

```
## <card[52]>
## [1]   1♣  2♣  3♣  4♣  5♣  6♣  7♣  8♣  9♣
## [10] 10♣  J♣  Q♣  K♣  1♦  2♦  3♦  4♦  5♦
## [19]  6♦  7♦  8♦  9♦ 10♦  J♦  Q♦  K♦  1♥
## [28]  2♥  3♥  4♥  5♥  6♥  7♥  8♥  9♥ 10♥
## [37]  J♥  Q♥  K♥  1♠  2♠  3♠  4♠  5♠  6♠
## [46]  7♠  8♠  9♠ 10♠  J♠  Q♠  K♠
```

### Decks, hands, and piles

You could program a game of cribbage without using mutable objects, but I think it's easier to read with the mutable objects (maybe because I started programming in Python and Java, where pretty much *everything* is a mutable object). In R, the best supported way to do this is the [R6 package](https://r6.r-lib.org/).


```r
library(R6)
```

Let's start with a mutable `CardPile`, which is an abstraction of a deck, a hand, and the pile of cards that accumulates during play. All of these things are ordered vectors of cards that can have cards drawn and put in at the top or bottom. If you're new to R6, the [R6 introduction vignette](https://r6.r-lib.org/articles/Introduction.html) is an excellent introduction.


```r
CardPile <- R6Class(
  "CardPile",
  public = list(
    
    pile = NULL,
    
    initialize = function(pile = card()) {
      self$pile <- vec_cast(pile, card())
    },
    
    reset = function() {
      self$pile <- card()
    },
    
    shuffle = function() {
      self$pile <- self$pile[sample(seq_along(self$pile), replace = FALSE)]
      invisible(self)
    },
    
    peek = function(index) {
      self$pile[index]
    },
    
    draw = function(index) {
      value <- self$peek(index)
      self$pile <- self$pile[-index]
      value
    },
    
    put = function(value) {
      self$pile <- vec_c(value, self$pile)
      invisible(self)
    },
    
    draw_value = function(value) {
      value <- vec_cast(value, card())
      removed_values <- vec_cast(intersect(value, self$pile), card())
      
      if (length(value) != length(removed_values)) {
        missing_vals <- str_c(
          card_format_color(
            vec_cast(setdiff(value, self$pile), card())
          ), 
          collapse = ", "
        )
        
        stop(glue::glue("Cards not in pile: {missing_vals}"))
      }
      
      self$pile <- vec_cast(setdiff(self$pile, value), card())
      removed_values
    },
    
    size = function() {
      length(self$pile)
    },
    
    print = function(...) {
      cat(glue::glue("<{class(self)[1]}> with {self$size()} cards:\n\n", sep = ""))
      obj_print_data(self$pile)
      invisible(self)
    }
  )
)
```

A `Deck` is a `CardPile` that starts with all the cards in it.


```r
all_cards <- function() {
  card(
    c(
      paste0(c(1:10, "J", "Q", "K"), "c"),
      paste0(c(1:10, "J", "Q", "K"), "d"),
      paste0(c(1:10, "J", "Q", "K"), "h"),
      paste0(c(1:10, "J", "Q", "K"), "s")
    )
  )
}

Deck <- R6Class(
  "Deck", inherit = CardPile,
  public = list(
    initialize = function(pile = all_cards()) {
      super$initialize(pile = pile)
    }
  )
)
```

Because we return `self` from `CardPile$shuffle()`, we can do stuff like this:


```r
deck <- Deck$new()$shuffle()
deck
```

```
## <Deck> with 52 cards:
## [1]   1♦  7♥  8♣  2♥  4♥  1♣  J♦  Q♦  5♣
## [10]  2♠  3♥  2♣  4♠  8♦  J♣  Q♣ 10♥  K♥
## [19]  9♣  6♣  7♣ 10♠  Q♥  Q♠  K♠  5♠  1♠
## [28]  J♠ 10♣  3♠  K♦  7♠  6♥  8♥  4♦  6♠
## [37] 10♦  1♥  J♥  5♥  3♦  9♥  9♦  9♠  K♣
## [46]  2♦  3♣  5♦  7♦  8♠  6♦  4♣
```

Some methods don't modify the pile:


```r
deck$peek(1)
```

```
## <card[1]>
## [1]  1♦
```

```r
deck$peek(52)
```

```
## <card[1]>
## [1]  4♣
```

```r
deck
```

```
## <Deck> with 52 cards:
## [1]   1♦  7♥  8♣  2♥  4♥  1♣  J♦  Q♦  5♣
## [10]  2♠  3♥  2♣  4♠  8♦  J♣  Q♣ 10♥  K♥
## [19]  9♣  6♣  7♣ 10♠  Q♥  Q♠  K♠  5♠  1♠
## [28]  J♠ 10♣  3♠  K♦  7♠  6♥  8♥  4♦  6♠
## [37] 10♦  1♥  J♥  5♥  3♦  9♥  9♦  9♠  K♣
## [46]  2♦  3♣  5♦  7♦  8♠  6♦  4♣
```

But some methods do:


```r
deck$draw(1)
```

```
## <card[1]>
## [1]  1♦
```

```r
deck$draw_value("5h")
```

```
## <card[1]>
## [1]  5♥
```

```r
deck
```

```
## <Deck> with 50 cards:
## [1]   7♥  8♣  2♥  4♥  1♣  J♦  Q♦  5♣  2♠
## [10]  3♥  2♣  4♠  8♦  J♣  Q♣ 10♥  K♥  9♣
## [19]  6♣  7♣ 10♠  Q♥  Q♠  K♠  5♠  1♠  J♠
## [28] 10♣  3♠  K♦  7♠  6♥  8♥  4♦  6♠ 10♦
## [37]  1♥  J♥  3♦  9♥  9♦  9♠  K♣  2♦  3♣
## [46]  5♦  7♦  8♠  6♦  4♣
```

### Playing virtual cribbage

I think we're ready to program a game of cribbage!^[For now we're going to skip the question of *why* I'm playing cribbage with myself in RMarkdown on a Sunday evening.] We start with a shuffled deck of cards, dealing six cards from the top of the deck to each player. The crib is empty for now, but is an empty `CardPile` for when the players (both me, in this case) decide what to discard.


```r
deck <- withr::with_seed(324, Deck$new()$shuffle())
dealer <- CardPile$new(deck$draw(1:6))
other_player <- CardPile$new(deck$draw(1:6))
crib <- CardPile$new()
```

Let's take a look at the hands!


```r
dealer
```

```
## <CardPile> with 6 cards:
## [1]  8♥  4♥  8♠  8♦ 10♥  5♦
```

```r
other_player
```

```
## <CardPile> with 6 cards:
## [1]  1♣  K♥ 10♣  J♥  7♣  K♠
```

I think the best move for the dealer is to leave the 10 and the 5 in the crib, and for the other player to keep  the two kings and the jack (in the off chance it's the nibs). I think the ace leaves the best chance for the starter card to give some points, which leaves the 10 and the 7 for the crib.


```r
crib$put(
  c(
    dealer$draw_value(c("10h", "5d")),
    other_player$draw_value(c("10c", "7c"))
  )
)
```

Now it's time for the cut! Or in `CardPile` terminology, `draw()` a card at a random index.


```r
starter <- deck$draw(sample(deck$size(), 1))
starter
```

```
## <card[1]>
## [1]  8♣
```

I'm going to skip the pegging because it's too verbose, but it can be done with some `clone()`ing of the hands and another `CardPile` for the discard pile. 

Finally, we score the hands and the crib:


```r
score_hand(dealer$pile, starter = starter)
```

```
## [1] 12
```

```r
score_hand(other_player$pile, starter = starter)
```

```
## [1] 2
```

```r
score_hand(crib$pile, starter = starter,  crib = TRUE)
```

```
## [1] 8
```

### Simulations

I had a great time programming all of this, but it's more useful in the context of simulations. For example, given a hand of six cards, what's the best choice to pick for crib discards?


```r
deck <- Deck$new()$shuffle()
hand <- CardPile$new(deck$draw(1:6))
hand
```

```
## <CardPile> with 6 cards:
## [1]  5♦  J♥  6♠  4♥  5♠  2♣
```

Generating all the possible discards (and thus hands) is one part of the solution:


```r
# all possible discards + hands
possible_discards <- card_combn(hand$pile, 2)
possible_hands <- map(possible_discards, function(discard) {
  new_hand <- hand$clone()
  new_hand$draw_value(discard)
  new_hand$pile
})
```

...and generating a bunch of potential starter cards is another. We haven't dealt the other player's hand, so the  remainder of the deck (`deck$pile`) is currently everything that we know about it.




```r
library(tidyverse)

possible_combos <- crossing(
  tibble(hand = possible_hands, hand_which = seq_along(hand)),
  tibble(starter = deck$pile)
) %>% 
  mutate(score = map2_dbl(hand, starter, score_hand)) %>% 
  group_by(hand_which) %>% 
  summarise(mean_score = mean(score), max_score = max(score)) %>% 
  arrange(desc(mean_score))

possible_combos
```

```
## # A tibble: 15 x 3
##    hand_which mean_score max_score
##         <int>      <dbl>     <dbl>
##  1          9      16.0         24
##  2          5       9.85        17
##  3         15       9.85        17
##  4         12       9.67        17
##  5         14       9.5         16
##  6         10       8.85        15
##  7          1       8.39        14
##  8          8       8.39        14
##  9          6       6.30        12
## 10          7       6.13        12
## 11          2       4.96         9
## 12         11       4.96         9
## 13          3       4.87         8
## 14         13       4.87         8
## 15          4       2.37         8
```

```r
possible_hands[[possible_combos$hand_which[1]]]
```

```
## <card[4]>
## [1]  5♦  6♠  4♥  5♠
```

Of course, this doesn't take into account the possibility that you discard points (or possible points) into somebody else's (or your own!) crib, but that is a battle for another day.
