---
title: Really basic Stan
author: Dewey Dunnington
date: '2019-12-15'
slug: really-basic-stan
categories: []
tags: []
subtitle: ''
summary: ''
authors: []
lastmod: '2019-12-15T12:02:18-04:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---




Ever since I got a primer on Bayesian statistics from [Aaron McNeil](https://twitter.com/ma_macneil) in my *Analysis of Biological Data* course at Dalhousie, I've been Bayesian-curious. As an avid R user, the way to do Bayesian statistics (as far as I can tell) is [Stan](https://mc-stan.org/), "a state-of-the-art platform for statistical modeling and high-performance statistical computation". Other packages like [brms](https://github.com/paul-buerkner/brms) build on Stan for most use-cases; an excellent guide to doing statistics using *brms* is available as the online book [Statistical Rethinking with brms, ggplot2, and the tidyverse](https://bookdown.org/ajkurz/Statistical_Rethinking_recoded/).

Using *brms* is less intuitive (for me) with more complex models. My use-case is physically-based age-depth models, but there comes a point where writing Stan code is more expressive than the equivalent *brms* code, and because Bayesian stats can be complicated to explain to people, expressiveness is key! The rest of this post is the result of my adventures learning how to write Stan code. I'll be using the [tidyverse](https://tidyverse.org/) and [rstan](https://mc-stan.org/rstan/) for the rest of the post.


```r
library(tidyverse)
library(rstan)
```

## A Bayesian linear model

(based on the tutorial in the excellent [Stan documentation](https://mc-stan.org/docs/2_21/stan-users-guide/linear-regression.html))

Most of us have been using linear models ever since we learned how to insert a "best fit" line in Excel, which prints a nice equation in the form `y = m * x + b`. Because every point has some error (not *every* point is along the best-fit line), the model is actually more like `y = m * x + b + error`, and indeed, the assumptions that underly frequentist hypothesis testing for linear models assume that the residuals are normally distributed (mean of 0 with a standard deviation). I normally don't use fake data in posts, but here it's useful so that we see if the model is giving us the correct values.


```r
actual_slope <- 4.5
actual_intercept <- 12
actual_se <- 20

set.seed(2847)
linear_data <- tibble(
  x = 0:99,
  y = actual_slope * x + actual_intercept +
    rnorm(100, mean = 0, sd = actual_se)
)

ggplot(linear_data, aes(x, y)) + 
  geom_abline(
    slope = actual_slope, 
    intercept = actual_intercept,
    lty = 2, alpha = 0.7
  ) +
  geom_point()
```

<img src="unnamed-chunk-2-1.png" width="672" />

Of course, the "normal" way to fit the model (estimate *m* and *b*) is using `lm()`:


```r
lm_fit <- lm(y ~ x, data = linear_data)
summary(lm_fit)
```

```
## 
## Call:
## lm(formula = y ~ x, data = linear_data)
## 
## Residuals:
##     Min      1Q  Median      3Q     Max 
## -59.845 -16.378   2.149  15.298  43.582 
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept) 10.92106    4.16778    2.62   0.0102 *  
## x            4.49005    0.07273   61.73   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 21 on 98 degrees of freedom
## Multiple R-squared:  0.9749,	Adjusted R-squared:  0.9747 
## F-statistic:  3811 on 1 and 98 DF,  p-value: < 2.2e-16
```

Using Stan, there are more steps. First, we have to define the model. I usually do this in a character vector, but you can also define it in an RMarkdown chunk or a `.stan` file, where you'll get better RStudio syntax highlighting and autocompletion.


```r
stan_model_def <- "
data {
  int n;
  vector[n] x;
  vector[n] y;
}

parameters {
  real slope;
  real intercept;
  real standardError;
}

model {
  y ~ normal(slope * x + intercept, standardError);
}
"

stan_fit <- stan(
  model_code = stan_model_def,
  data = list(
    n = nrow(linear_data),
    x = linear_data$x,
    y = linear_data$y
  )
)
```


```r
stan_fit
```

```
## Inference for Stan model: f7e762c95082ee6612f2bddb48340f4c.
## 4 chains, each with iter=2000; warmup=1000; thin=1; 
## post-warmup draws per chain=1000, total post-warmup draws=4000.
## 
##                  mean se_mean   sd    2.5%     25%     50%     75%   97.5%
## slope            4.49    0.00 0.07    4.35    4.44    4.49    4.54    4.63
## intercept       10.83    0.10 4.17    2.61    8.05   10.85   13.67   19.02
## standardError   21.24    0.03 1.51   18.50   20.17   21.17   22.18   24.46
## lp__          -354.94    0.03 1.19 -358.04 -355.52 -354.63 -354.05 -353.53
##               n_eff Rhat
## slope          1587    1
## intercept      1599    1
## standardError  2179    1
## lp__           1571    1
## 
## Samples were drawn using NUTS(diag_e) at Sun Dec 15 17:29:45 2019.
## For each parameter, n_eff is a crude measure of effective sample size,
## and Rhat is the potential scale reduction factor on split chains (at 
## convergence, Rhat=1).
```

(For the rest of this post I'm only going to show the Stan code for clarity, but you should also know that `rstan::extract(stan_fit)` and `rstan::stan_plot(stan_fit)` are useful ways to extract information from the `stan_fit` object.)

The Stan model didn't get any mean estimates for the parameters were closer to the "true" values than the `lm()` version, but it does a way better job at assessing error: the "true" values are all between the 25% and 75% quantiles for the estimated parameters. The `lm()` version doesn't give any of this information (nor can it). All models are wrong, but at least the Stan model has an idea how wrong it actually is.

The above model doesn't actually incorporate the most important feature of Bayesian statistics, which is the incorporation of prior knowledge. This is more important with more non-linear relationships, which need some guidance to converge on a solution. These get defined as distributions for the parameters you are trying to estimate. To specify that the slope should be "somewhere around 5", for example, you could suggest that `slope ~ normal(5, 3)` (normally distributed with a mean of 5 and a standard deviation of 3). In Stan, these are added in the `model` block like so:


```stan
data {
  int n;
  vector[n] x;
  vector[n] y;
}

parameters {
  real slope;
  real intercept;
  real standardError;
}

model {
  intercept ~ normal(10, 5);
  slope ~ normal(5, 3);
  
  y ~ normal(slope * x + intercept, standardError);
}
```




```
## Inference for Stan model: eddebbf1e1c595e093b7f8cc31ff1391.
## 4 chains, each with iter=2000; warmup=1000; thin=1; 
## post-warmup draws per chain=1000, total post-warmup draws=4000.
## 
##                  mean se_mean   sd    2.5%     25%     50%     75%   97.5%
## slope            4.50    0.00 0.06    4.38    4.46    4.50    4.54    4.62
## intercept       10.40    0.07 3.20    4.03    8.30   10.49   12.52   16.44
## standardError   21.28    0.03 1.50   18.58   20.24   21.18   22.22   24.53
## lp__          -354.94    0.03 1.19 -358.09 -355.50 -354.64 -354.06 -353.55
##               n_eff Rhat
## slope          2137    1
## intercept      2116    1
## standardError  2537    1
## lp__           1625    1
## 
## Samples were drawn using NUTS(diag_e) at Sun Dec 15 17:30:24 2019.
## For each parameter, n_eff is a crude measure of effective sample size,
## and Rhat is the potential scale reduction factor on split chains (at 
## convergence, Rhat=1).
```

And, magically, Stan gets the slope bang on at 4.5 (the intercept isn't quite as good, but it's still well within the error bounds).

## Really basic Stan

Stan models get defined in 3 main parts: `data`, `parameters`, and  `model`. I like to think of Stan models as R functions that might look something like this:


```r
my_stan_model <- function(data) {
  parameter_values <- sample_priors(parameters)
  
  for (i in many_iterations) {
    log_probability <- evaluate(model, at = parameter_values, using = data)
    if (is_good_enough(log_probability)) {
      keep(parameter_values)
    }
    
    parameter_values <- update_parameter_values(parameter_values)
  }
  
  return(best(parameter_values))
}
```

Not being a statistician, I imagine I'm missing a lot of nuances here, but in the words of [Greg Wilson](http://teachtogether.tech/), "never hesitate to sacrifice the truth for clarity".

### Data

Let's start with the data, or where we define the inputs. For the linear model, the inputs were `x` and `y`, and because Stan needs to know the length of any of it's inputs before they're declared, we also need the input of `n`, or the number of points.

``` stan
data {
  int n;
  vector[n] x;
  vector[n] y;
}
```

You should include anything in `data` that you can compute in advance, or that you are going to change from model to model. In our case, this includes information about the prior distribution of `slope` and `intercept` (I hard-coded this in the example above, but it will be different when `x` and  `y` change, so it shouldn't be hard-coded).

``` stan
data {
  int n;
  vector[n] x;
  vector[n] y;
  real slopeEstimate;
  real slopeEstimateSigma;
  real interceptEstimate;
  real interceptEstimateSigma;
}
```

The only thing missing are constraints. Stan lets you specify bounds for the input data, which helps track down errors considerably (also nicely communicates what you intended each variable to represent). You can specify this in angled brackets after the variable type.

``` stan
data {
  int<lower=0> n;
  vector[n] x;
  vector[n] y;
  real slopeEstimate;
  real<lower=0> slopeEstimateSigma;
  real interceptEstimate;
  real<lower=0> interceptEstimateSigma;
}
```

Make sure to put a semi-colon after each line!

### Parameters

If the `data` are the things that you *do* know, `parameters` are the things that you *don't* know. They get defined in the same way as the data. For the linear model, we don't know the `slope`, the `intercept`, or the standard error of the residuals. Just like the `data`, they can have constraints as well (and need semi-colons after each line).

``` stan
parameters {
  real slope;
  real intercept;
  real<lower=0> standardError;
}
```

### Model

The `model` is where the magic happens! I think of this as a place where you can write things that are true, including prior probabilities and the relationships model itself.

``` stan
model {
  intercept ~ normal(interceptEstimate, interceptEstimateSigma);
  slope ~ normal(slopeEstimate, slopeEstimateSigma);
  
  y ~ normal(slope * x + intercept, standardError);
}
```

### Putting it all together


```stan
data {
  int<lower=0> n;
  vector[n] x;
  vector[n] y;
  real slopeEstimate;
  real<lower=0> slopeEstimateSigma;
  real interceptEstimate;
  real<lower=0> interceptEstimateSigma;
}

parameters {
  real slope;
  real intercept;
  real<lower=0> standardError;
}

model {
  intercept ~ normal(interceptEstimate, interceptEstimateSigma);
  slope ~ normal(slopeEstimate, slopeEstimateSigma);
  
  y ~ normal(slope * x + intercept, standardError);
}
```



Because we've added new `data` definitions, we need to add these to the `data` that we pass to `stan()`.


```r
stan_fit <- stan(
  ...,
  data = list(
    n = nrow(linear_data),
    x = linear_data$x,
    y = linear_data$y,
    slopeEstimate = 5,
    slopeEstimateSigma = 3,
    interceptEstimate = 10,
    interceptEstimateSigma = 3
  )
)

stan_fit
```


```
## Inference for Stan model: 4211910eaaac919092a7429e0e3d982b.
## 4 chains, each with iter=2000; warmup=1000; thin=1; 
## post-warmup draws per chain=1000, total post-warmup draws=4000.
## 
##                  mean se_mean   sd    2.5%     25%     50%     75%   97.5%
## slope            4.50    0.00 0.05    4.39    4.46    4.50    4.53    4.60
## intercept       10.31    0.06 2.42    5.47    8.69   10.38   11.97   15.07
## standardError   21.21    0.03 1.50   18.49   20.17   21.14   22.22   24.28
## lp__          -351.91    0.03 1.22 -355.13 -352.46 -351.61 -351.02 -350.52
##               n_eff Rhat
## slope          1940    1
## intercept      1916    1
## standardError  2560    1
## lp__           1831    1
## 
## Samples were drawn using NUTS(diag_e) at Sun Dec 15 17:31:00 2019.
## For each parameter, n_eff is a crude measure of effective sample size,
## and Rhat is the potential scale reduction factor on split chains (at 
## convergence, Rhat=1).
```

## A more complex example

Bayesian linear models are well-handled in the R universe (the above example could be condensed to  `brms::brm(y ~ x, data = linear_data)`), but more complex or discipline-specific models probably don't have a well-summarised equivalent.

As an example, I'll use radiometric dating. You might remember that radioactive elements decay exponentially, and can be modeled by the formula

``` r
amount <- function(t) initialAmount * exp(-decayConstant * t)
```

I deal in recent lake sediments, whose ages are usually estimated using measurements of ^210^Pb (which is radioactive). Usually we use a more complex model, but the earliest model (the CIC model) modeled the age of each slice in exactly this way, with the slight complication that there's some residual (background) ^210^Pb hanging around in all samples. We can model a fake core that uses exactly this principle using the [pb210 package](https://github.com/paleolimbot/pb210).


```r
known_background <- 15
known_background_error <- 5

# remotes::install_github("paleolimbot/pb210")
library(pb210) 
fake_core <- pb210_simulate_accumulation() %>%
  pb210_simulate_core(rep(1, 20)) %>%
  mutate(
    activity = activity + 
      rnorm(20, mean = known_background, sd = known_background_error)
  ) %>% 
  pb210_simulate_counting(count_time = lubridate::dhours(12)) %>% 
  select(depth, age, activity_estimate, activity_se)

fake_core
```

```
## # A tibble: 20 x 4
##    depth    age activity_estimate activity_se
##    <dbl>  <dbl>             <dbl>       <dbl>
##  1   0.5   5.04             583.        5.19 
##  2   1.5  15.2              416.        4.39 
##  3   2.5  25.5              330.        3.91 
##  4   3.5  35.9              232.        3.28 
##  5   4.5  46.6              167.        2.78 
##  6   5.5  57.4              124.        2.40 
##  7   6.5  68.4               76.6       1.88 
##  8   7.5  79.6               67.5       1.77 
##  9   8.5  91.1               55.6       1.60 
## 10   9.5 103.                43.1       1.41 
## 11  10.5 115.                32.7       1.23 
## 12  11.5 127.                26.6       1.11 
## 13  12.5 139.                32.5       1.23 
## 14  13.5 152.                27.0       1.12 
## 15  14.5 165.                19.3       0.945
## 16  15.5 178.                13.2       0.783
## 17  16.5 192.                18.8       0.934
## 18  17.5 206.                13.7       0.797
## 19  18.5 221.                19.3       0.944
## 20  19.5 236.                12.9       0.772
```

The Stan model for this is a bit more complicated, because we're trying to estimate more parameters (notably, the age of each slice). The model does very poorly if we don't give it *some* idea of what the ages of each slice are, and it turns out we really *do* know some things about how fast sediment could possibly accumulate, so it's not unrealistic to include it in the model. Something else I do here is loop within the `model` bit...I think it's possible to use vectorized notation (like for the linear model), but I think it's good to illustrate that you can loop here to capture more complex "truths".


```stan
data {
  int<lower=0> nSamples;
  real<lower=0> decayConstant;
  vector<lower=0>[nSamples] activity;
  vector<lower=0>[nSamples] sigmaActivity;
  vector<lower=0>[nSamples] ageEstimate;
  vector<lower=0>[nSamples] ageEstimateSigma;
  real backgroundActivityEstimate;
  real<lower=0> backgroundActivitySigma;
}

parameters {
  vector<lower=0>[nSamples] age;
  real<lower=0> initialActivity;
  real backgroundActivity;
}

model {
  initialActivity ~ normal(activity[1], sigmaActivity[1]);
  backgroundActivity ~ normal(backgroundActivityEstimate, backgroundActivitySigma);
  
  for (i in 1:nSamples)  {
    activity[i] ~ normal(
      backgroundActivity + initialActivity * exp(-decayConstant * age[i]),
      sigmaActivity[i]
    );
    age[i] ~ normal(ageEstimate[i], ageEstimateSigma[i]);
  }
}
```




```r
stan_fit
```

```
## Inference for Stan model: 9fcf7bf39a29564f039893a762baffeb.
## 4 chains, each with iter=5000; warmup=2500; thin=1; 
## post-warmup draws per chain=2500, total post-warmup draws=10000.
## 
##                      mean se_mean     sd   2.5%    25%    50%    75%
## age[1]               0.79    0.01   0.38   0.11   0.51   0.77   1.04
## age[2]              11.87    0.01   0.45  11.00  11.56  11.87  12.16
## age[3]              19.53    0.01   0.48  18.59  19.21  19.52  19.84
## age[4]              31.38    0.01   0.56  30.29  31.01  31.38  31.76
## age[5]              42.71    0.01   0.64  41.48  42.27  42.70  43.14
## age[6]              53.17    0.01   0.76  51.72  52.66  53.17  53.68
## age[7]              71.18    0.01   1.04  69.20  70.47  71.16  71.87
## age[8]              76.21    0.01   1.12  74.02  75.46  76.20  76.94
## age[9]              84.13    0.01   1.30  81.64  83.24  84.10  85.00
## age[10]             95.46    0.02   1.63  92.33  94.37  95.44  96.53
## age[11]            109.31    0.02   2.21 105.13 107.80 109.27 110.75
## age[12]            121.52    0.03   2.97 116.13 119.47 121.40 123.45
## age[13]            109.72    0.03   2.25 105.50 108.18 109.64 111.16
## age[14]            120.52    0.03   2.92 115.21 118.48 120.40 122.44
## age[15]            148.36    0.08   6.42 137.60 144.01 147.70 152.00
## age[16]            449.97    1.96 186.79 209.45 304.70 410.52 559.66
## age[17]            151.12    0.08   6.91 139.43 146.32 150.45 155.21
## age[18]            466.85    2.23 215.08 197.18 294.30 420.82 593.89
## age[19]            148.65    0.08   6.39 137.99 144.14 148.02 152.42
## age[20]            537.06    2.23 239.28 223.40 348.22 489.76 677.58
## initialActivity    582.99    0.08   4.99 573.55 579.55 582.90 586.38
## backgroundActivity  13.36    0.01   0.49  12.37  13.05  13.37  13.69
## lp__                80.50    0.05   3.30  73.10  78.50  80.83  82.85
##                      97.5% n_eff Rhat
## age[1]                1.57  4930    1
## age[2]               12.74  5669    1
## age[3]               20.48  6014    1
## age[4]               32.48  7262    1
## age[5]               43.97  7224    1
## age[6]               54.69  8111    1
## age[7]               73.26  9427    1
## age[8]               78.46  8081    1
## age[9]               86.73  9227    1
## age[10]              98.76  9172    1
## age[11]             113.91  8563    1
## age[12]             127.65  8278    1
## age[13]             114.36  7620    1
## age[14]             126.50  7974    1
## age[15]             162.68  7273    1
## age[16]             902.13  9125    1
## age[17]             166.61  6720    1
## age[18]             978.21  9276    1
## age[19]             162.94  6331    1
## age[20]            1106.82 11475    1
## initialActivity     592.86  3891    1
## backgroundActivity   14.27  3799    1
## lp__                 85.94  3768    1
## 
## Samples were drawn using NUTS(diag_e) at Sun Dec 15 17:31:37 2019.
## For each parameter, n_eff is a crude measure of effective sample size,
## and Rhat is the potential scale reduction factor on split chains (at 
## convergence, Rhat=1).
```

Lo and behold, we get estimates! I used age priors of 10 years per slice (with a sd of age times 2...fairly uninformative but realistic). The model does poorly in the lower sediment intervals, but correctly has high error there as well. I think it's amazing that it estimated the background so well! To do better, it would probably have to incorporate the background error somehow, but that is a battle for another day.
