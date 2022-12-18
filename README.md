
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Flexible hierarchical nowcasting <a href='https://package.epinowcast.org'><img src='man/figures/logo.png' align="right" height="139" /></a>

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R-CMD-check](https://github.com/epinowcast/epinowcast/workflows/R-CMD-check/badge.svg)](https://github.com/epinowcast/epinowcast/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/epinowcast/epinowcast/branch/main/graph/badge.svg)](https://app.codecov.io/gh/epinowcast/epinowcast)

[![Universe](https://epinowcast.r-universe.dev/badges/epinowcast)](https://epinowcast.r-universe.dev/)
[![MIT
license](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/epinowcast/epinowcast/blob/master/LICENSE.md/)
[![GitHub
contributors](https://img.shields.io/github/contributors/epinowcast/epinowcast)](https://github.com/epinowcast/epinowcast/graphs/contributors)

[![DOI](https://zenodo.org/badge/422611952.svg)](https://zenodo.org/badge/latestdoi/422611952)

Tools to enable flexible and efficient hierarchical nowcasting of
right-truncated epidemiological time-series using a semi-mechanistic
Bayesian model with support for a range of reporting and generative
processes. Nowcasting, in this context, is gaining situational awareness
using currently available observations and the reporting patterns of
historical observations. This can be useful when tracking the spread of
infectious disease in real-time: without nowcasting, changes in trends
can be obfuscated by partial reporting or their detection may be delayed
due to the use of simpler methods like truncation. While the package has
been designed with epidemiological applications in mind, it could be
applied to any set of right-truncated time-series count data.

## Getting started and learning more

This README is a good place to get started with `epinowcast`, in particular the following installation and quick start sections. As you make use of the package, or if your problem requires a richer feature set than presented here, we also provide a range of other documentation, case studies, and spaces for the community to interact with each other. Below is a short list of current resources.

- [Package website](https://package.epinowcast.org/): This includes a function reference, model outline, and case studies making use of the package.
- [Organisation website](https://www.epinowcast.org/): This includes links to our other resources as well as guest posts from community members and schedules for any related seminars being run by community members.
- [Directory of example scripts](https://github.com/epinowcast/epinowcast/tree/main/inst/examples): Not as fleshed out as our complete case studies these scripts are used during package developemnt and each showcase a subset of package functionality. Often newly introduced features will be explored here before surfacing in other areas of our documentation.
- [Community forum](https://community.epinowcast.org/): Our community forum is where development of tools is discussed, along with related research from our members and discussions between users. If you are interested in real-time analysis of infectious disease this is likely a good place to start regardless of if you end up making use of `epinowcast`.

## Installation

### Installing the package

Install the stable development version of the package with:

``` r
install.packages("epinowcast", repos = "https://epinowcast.r-universe.dev")
```

Alternatively, install the stable development from GitHub using the
following,

``` r
remotes::install_github("epinowcast/epinowcast", dependencies = TRUE)
```

The unstable development version can also be installed from GitHub using
the following,

``` r
remotes::install_github("epinowcast/epinowcast@develop", dependencies = TRUE)
```

### Installing CmdStan

If you don’t already have CmdStan installed then, in addition to
installing `epinowcast`, it is also necessary to install CmdStan using
CmdStanR’s `install_cmdstan()` function to enable model fitting in
`epinowcast`. A suitable C++ toolchain is also required. Instructions
are provided in the [*Getting started with
CmdStanR*](https://mc-stan.org/cmdstanr/articles/cmdstanr.html)
vignette. See the [CmdStanR
documentation](https://mc-stan.org/cmdstanr/) for further details and
support.

``` r
cmdstanr::install_cmdstan()
```

## Quick start

In this quick start we use COVID-19 hospitalisations by date of positive
test in Germany available up to the 1st of October 2021 to demonstrate
the specification and fitting of a simple nowcasting model using
`epinowcast`. Examples using more complex models are available in the
package vignettes and in the papers linked to in the literature
vignette.

### Package

As well as `epinowcast` this quick start makes use of `data.table` and
`ggplot2` which are both installed when `epinowcast` is installed.

``` r
library(epinowcast)
library(data.table)
library(ggplot2)
```

### Data

Nowcasting is effectively the estimation of reporting patterns for
recently reported data. This requires data on these patterns for
previous observations and typically this means the time series of data
as reported on multiple consecutive days (in theory non-consecutive days
could be used but this is not yet supported in `epinowcast`). For this
quick start these data are sourced from the [Robert Koch Institute via
the Germany Nowcasting
hub](https://github.com/KITmetricslab/hospitalization-nowcast-hub/wiki/Truth-data#role-an-definition-of-the-seven-day-hospitalization-incidence)
where they are deconvolved from weekly data and days with negative
reported hospitalisations are adjusted.

Below we first filter for a snapshot of retrospective data available 40
days before the 1st of October that contains 40 days of data and then
produce the nowcast target based on the latest available
hospitalisations by date of positive test.

``` r
nat_germany_hosp <-
  germany_covid19_hosp[location == "DE"][age_group %in% "00+"] |>
  enw_filter_report_dates(latest_date = "2021-10-01")

retro_nat_germany <- nat_germany_hosp |>
  enw_filter_report_dates(remove_days = 40) |>
  enw_filter_reference_dates(include_days = 40)
retro_nat_germany
#>      reference_date location age_group confirm report_date
#>              <IDat>   <fctr>    <fctr>   <int>      <IDat>
#>   1:     2021-07-13       DE       00+      21  2021-07-13
#>   2:     2021-07-14       DE       00+      22  2021-07-14
#>   3:     2021-07-15       DE       00+      28  2021-07-15
#>   4:     2021-07-16       DE       00+      19  2021-07-16
#>   5:     2021-07-17       DE       00+      20  2021-07-17
#>  ---                                                      
#> 857:     2021-07-14       DE       00+      72  2021-08-21
#> 858:     2021-07-15       DE       00+      69  2021-08-22
#> 859:     2021-07-13       DE       00+      59  2021-08-21
#> 860:     2021-07-14       DE       00+      72  2021-08-22
#> 861:     2021-07-13       DE       00+      59  2021-08-22
```

``` r
latest_germany_hosp <- nat_germany_hosp |>
  enw_latest_data() |>
  enw_filter_reference_dates(remove_days = 40, include_days = 40)
head(latest_germany_hosp, n = 10)
#>     reference_date location age_group confirm report_date
#>             <IDat>   <fctr>    <fctr>   <int>      <IDat>
#>  1:     2021-07-13       DE       00+      60  2021-10-01
#>  2:     2021-07-14       DE       00+      74  2021-10-01
#>  3:     2021-07-15       DE       00+      69  2021-10-01
#>  4:     2021-07-16       DE       00+      49  2021-10-01
#>  5:     2021-07-17       DE       00+      67  2021-10-01
#>  6:     2021-07-18       DE       00+      51  2021-10-01
#>  7:     2021-07-19       DE       00+      36  2021-10-01
#>  8:     2021-07-20       DE       00+      96  2021-10-01
#>  9:     2021-07-21       DE       00+      94  2021-10-01
#> 10:     2021-07-22       DE       00+      99  2021-10-01
```

### Data preprocessing and model specification

Process reported data into format required for `epinowcast` and return
in a `data.table`. At this stage specify grouping (i.e age, location) if
any. It can be useful to check this output before beginning to model to
make sure everything is as expected.

``` r
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 40)
pobs
#>                    obs          new_confirm              latest
#>                 <list>               <list>              <list>
#> 1: <data.table[860x9]> <data.table[860x11]> <data.table[41x10]>
#>    missing_reference  reporting_triangle      metareference          metareport
#>               <list>              <list>             <list>              <list>
#> 1: <data.table[0x6]> <data.table[41x42]> <data.table[41x9]> <data.table[80x12]>
#>             metadelay  time snapshots     by groups max_delay   max_date
#>                <list> <int>     <int> <list>  <int>     <num>     <IDat>
#> 1: <data.table[40x4]>    41        41             1        40 2021-08-22
```

Construct a parametric lognormal intercept only model for the date of
reference using the metadata produced by `enw_preprocess_data()`. Note
that `epinowcast` uses a sparse design matrix for parametric delay
distributions to reduce runtimes so the design matrix shows only unique
rows with `index` containing the mapping to the full design matrix.

``` r
reference_module <- enw_reference(~1, distribution = "lognormal", data = pobs)
```

Construct a model with a random effect for the day of report using the
metadata produced by `enw_preprocess_data()`.

``` r
report_module <- enw_report(~ (1 | day_of_week), data = pobs)
```

Construct a model with a lognormal random walk on expected cases. See
`enw_expectation()` for other suggested choices.

``` r
expectation_module <- enw_expectation(
  ~ 0 + (1 | day), data = pobs
)
```

### Model fitting

First compile the model. This step can be left to `epinowcast` but here
we want to use multiple cores per chain to speed up model fitting and so
need to compile the model with this feature turned on.

``` r
model <- enw_model(threads = TRUE)
```

We now fit the model and produce a nowcast using this fit. Note that
here we use two chains each using two threads as a demonstration but in
general using 4 chains is recommended. Also note that warm-up and
sampling iterations have been set below default values to reduce compute
requirements but this may not be sufficient for many real world use
cases. Finally, note that here we have silenced fitting progress and
potential warning messages for the purposes of keeping this quick start
short but in general this should not be done.

``` r
options(mc.cores = 2)
nowcast <- epinowcast(pobs,
  expectation = expectation_module,
  reference = reference_module,
  report = report_module,
  fit = enw_fit_opts(,
    save_warmup = FALSE, pp = TRUE,
    chains = 2, threads_per_chain = 2,
    iter_sampling = 500, iter_warmup = 500,
    show_messages = FALSE, refresh = 0
  ),
  model = model
)
#> Running MCMC with 2 parallel chains, with 2 thread(s) per chain...
#> 
#> Chain 1 finished in 45.3 seconds.
#> Chain 2 finished in 46.6 seconds.
#> 
#> Both chains finished successfully.
#> Mean chain execution time: 45.9 seconds.
#> Total execution time: 46.8 seconds.
```

### Results

Print the output from `epinowcast` which includes diagnostic
information, the data used for fitting, and the `cmdstanr` object.

``` r
nowcast
#>                    obs          new_confirm              latest
#>                 <list>               <list>              <list>
#> 1: <data.table[860x9]> <data.table[860x11]> <data.table[41x10]>
#>    missing_reference  reporting_triangle      metareference          metareport
#>               <list>              <list>             <list>              <list>
#> 1: <data.table[0x6]> <data.table[41x42]> <data.table[41x9]> <data.table[80x12]>
#>             metadelay  time snapshots     by groups max_delay   max_date
#>                <list> <int>     <int> <list>  <int>     <num>     <IDat>
#> 1: <data.table[40x4]>    41        41             1        40 2021-08-22
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          fit
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       <list>
#> 1: <CmdStanMCMC>\n  Inherits from: <CmdStanFit>\n  Public:\n    clone: function (deep = FALSE) \n    cmdstan_diagnose: function () \n    cmdstan_summary: function (flags = NULL) \n    code: function () \n    constrain_variables: function (unconstrained_variables, transformed_parameters = TRUE, \n    data_file: function () \n    diagnostic_summary: function (diagnostics = c("divergences", "treedepth", "ebfmi"), \n    draws: function (variables = NULL, inc_warmup = FALSE, format = getOption("cmdstanr_draws_format", \n    expose_functions: function (global = FALSE, verbose = FALSE) \n    functions: environment\n    grad_log_prob: function (unconstrained_variables, jacobian_adjustment = TRUE) \n    hessian: function (unconstrained_variables, jacobian_adjustment = TRUE) \n    init: function () \n    init_model_methods: function (seed = 0, verbose = FALSE, hessian = FALSE) \n    initialize: function (runset) \n    inv_metric: function (matrix = TRUE) \n    latent_dynamics_files: function (include_failed = FALSE) \n    log_prob: function (unconstrained_variables, jacobian_adjustment = TRUE) \n    loo: function (variables = "log_lik", r_eff = TRUE, ...) \n    lp: function () \n    metadata: function () \n    num_chains: function () \n    num_procs: function () \n    output: function (id = NULL) \n    output_files: function (include_failed = FALSE) \n    print: function (variables = NULL, ..., digits = 2, max_rows = getOption("cmdstanr_max_rows", \n    profile_files: function (include_failed = FALSE) \n    profiles: function () \n    return_codes: function () \n    runset: CmdStanRun, R6\n    sampler_diagnostics: function (inc_warmup = FALSE, format = getOption("cmdstanr_draws_format", \n    save_data_file: function (dir = ".", basename = NULL, timestamp = TRUE, random = TRUE) \n    save_latent_dynamics_files: function (dir = ".", basename = NULL, timestamp = TRUE, random = TRUE) \n    save_object: function (file, ...) \n    save_output_files: function (dir = ".", basename = NULL, timestamp = TRUE, random = TRUE) \n    save_profile_files: function (dir = ".", basename = NULL, timestamp = TRUE, random = TRUE) \n    summary: function (variables = NULL, ...) \n    time: function () \n    unconstrain_variables: function (variables) \n    variable_skeleton: function (transformed_parameters = TRUE, generated_quantities = TRUE) \n  Private:\n    draws_: -1472.68 -1480.46 -1483.15 -1481.61 -1475.92 -1473.17 -1 ...\n    init_: NULL\n    inv_metric_: list\n    metadata_: list\n    model_methods_env_: environment\n    profiles_: NULL\n    read_csv_: function (variables = NULL, sampler_diagnostics = NULL, format = getOption("cmdstanr_draws_format", \n    sampler_diagnostics_: 7 7 7 7 8 7 8 7 7 7 7 7 7 7 7 7 7 7 7 8 7 7 7 8 7 8 7 8  ...\n    warmup_draws_: NULL\n    warmup_sampler_diagnostics_: NULL
#>          data  fit_args samples max_rhat divergent_transitions
#>        <list>    <list>   <int>    <num>                 <num>
#> 1: <list[99]> <list[8]>    1000     1.03                     0
#>    per_divergent_transitions max_treedepth no_at_max_treedepth
#>                        <num>         <num>               <int>
#> 1:                         0             8                 190
#>    per_at_max_treedepth run_time
#>                   <num>    <num>
#> 1:                 0.19     46.8
```

Summarise the nowcast for the latest snapshot of data.

``` r
nowcast |>
  summary(probs = c(0.05, 0.95)) |>
  head(n = 10)
#>     reference_date report_date .group max_confirm location age_group confirm
#>             <IDat>      <IDat>  <num>       <int>   <fctr>    <fctr>   <int>
#>  1:     2021-07-14  2021-08-22      1          72       DE       00+      72
#>  2:     2021-07-15  2021-08-22      1          69       DE       00+      69
#>  3:     2021-07-16  2021-08-22      1          47       DE       00+      47
#>  4:     2021-07-17  2021-08-22      1          65       DE       00+      65
#>  5:     2021-07-18  2021-08-22      1          50       DE       00+      50
#>  6:     2021-07-19  2021-08-22      1          36       DE       00+      36
#>  7:     2021-07-20  2021-08-22      1          94       DE       00+      94
#>  8:     2021-07-21  2021-08-22      1          91       DE       00+      91
#>  9:     2021-07-22  2021-08-22      1          99       DE       00+      99
#> 10:     2021-07-23  2021-08-22      1          86       DE       00+      86
#>     cum_prop_reported delay prop_reported    mean median        sd    mad    q5
#>                 <num> <num>         <num>   <num>  <num>     <num>  <num> <num>
#>  1:                 1    39             0  72.000     72 0.0000000 0.0000    72
#>  2:                 1    38             0  69.058     69 0.2582687 0.0000    69
#>  3:                 1    37             0  47.084     47 0.3115141 0.0000    47
#>  4:                 1    36             0  65.199     65 0.4578303 0.0000    65
#>  5:                 1    35             0  50.237     50 0.5010809 0.0000    50
#>  6:                 1    34             0  36.221     36 0.4943717 0.0000    36
#>  7:                 1    33             0  94.473     94 0.7333545 0.0000    94
#>  8:                 1    32             0  91.731     92 0.9140429 1.4826    91
#>  9:                 1    31             0 100.082    100 1.0716457 1.4826    99
#> 10:                 1    30             0  87.188     87 1.1661972 1.4826    86
#>       q95      rhat  ess_bulk  ess_tail
#>     <num>     <num>     <num>     <num>
#>  1:    72        NA        NA        NA
#>  2:    70 1.0011355  918.9261  889.6518
#>  3:    48 0.9986122  983.1341  956.9033
#>  4:    66 1.0018708  847.5928  829.2765
#>  5:    51 0.9981939  940.7106  982.9728
#>  6:    37 1.0003449  964.9386  688.1506
#>  7:    96 0.9996765  933.6563  862.0788
#>  8:    93 1.0020911 1029.4539 1042.8840
#>  9:   102 1.0034394  885.0471  905.0852
#> 10:    89 0.9991941 1092.2618 1028.0614
```

Plot the summarised nowcast against currently observed data (or
optionally more recent data for comparison purposes).

``` r
plot(nowcast, latest_obs = latest_germany_hosp)
```

<img src="man/figures/README-nowcast-1.png" width="100%" />

Plot posterior predictions for observed notifications by date of report
as a check of how well the model reproduces the observed data.

``` r
plot(nowcast, type = "posterior") +
  facet_wrap(vars(reference_date), scale = "free")
```

<img src="man/figures/README-pp-1.png" width="100%" />

Rather than using the methods supplied for `epinowcast` directly,
package functions can also be used to extract nowcast posterior samples,
summarise them, and then plot them. This is demonstrated here by
plotting the 7 day incidence for hospitalisations.

``` r
# extract samples
samples <- summary(nowcast, type = "nowcast_samples")

# Take a 7 day rolling sum of both samples and observations
cols <- c("confirm", "sample")
samples[, (cols) := lapply(.SD, frollsum, n = 7),
  .SDcols = cols, by = ".draw"
][!is.na(sample)]
#>        reference_date report_date .group max_confirm location age_group confirm
#>                <IDat>      <IDat>  <num>       <int>   <fctr>    <fctr>   <int>
#>     1:     2021-07-20  2021-08-22      1          94       DE       00+     433
#>     2:     2021-07-20  2021-08-22      1          94       DE       00+     433
#>     3:     2021-07-20  2021-08-22      1          94       DE       00+     433
#>     4:     2021-07-20  2021-08-22      1          94       DE       00+     433
#>     5:     2021-07-20  2021-08-22      1          94       DE       00+     433
#>    ---                                                                         
#> 33996:     2021-08-22  2021-08-22      1          45       DE       00+    1093
#> 33997:     2021-08-22  2021-08-22      1          45       DE       00+    1093
#> 33998:     2021-08-22  2021-08-22      1          45       DE       00+    1093
#> 33999:     2021-08-22  2021-08-22      1          45       DE       00+    1093
#> 34000:     2021-08-22  2021-08-22      1          45       DE       00+    1093
#>        cum_prop_reported delay prop_reported .chain .iteration .draw sample
#>                    <num> <num>         <num>  <int>      <int> <int>  <num>
#>     1:                 1    33             0      1          1     1    434
#>     2:                 1    33             0      1          2     2    433
#>     3:                 1    33             0      1          3     3    434
#>     4:                 1    33             0      1          4     4    435
#>     5:                 1    33             0      1          5     5    435
#>    ---                                                                     
#> 33996:                 1     0             1      2        496   996   2302
#> 33997:                 1     0             1      2        497   997   2496
#> 33998:                 1     0             1      2        498   998   2143
#> 33999:                 1     0             1      2        499   999   2136
#> 34000:                 1     0             1      2        500  1000   1983
latest_germany_hosp_7day <- copy(latest_germany_hosp)[
  ,
  confirm := frollsum(confirm, n = 7)
][!is.na(confirm)]

# Summarise samples
sum_across_last_7_days <- enw_summarise_samples(samples)

# Plot samples
enw_plot_nowcast_quantiles(sum_across_last_7_days, latest_germany_hosp_7day)
```

<img src="man/figures/README-week_nowcast-1.png" width="100%" />

## Learning more

The package has extensive documentation as well as vignettes describing
the underlying methodology, and several case studies. Please see [the
package site](https://package.epinowcast.org) for details. Note that the
development version of the package also has supporting documentation
which are available [here](https://package.epinowcast.org/dev).

## Citation

If using `epinowcast` in your work please consider citing it using the
following,

    #> 
    #> To cite epinowcast in publications use:
    #> 
    #>   Sam Abbott, Adrian Lison, and Sebastian Funk (2021). epinowcast:
    #>   Flexible hierarchical nowcasting, DOI: 10.5281/zenodo.5637165
    #> 
    #> A BibTeX entry for LaTeX users is
    #> 
    #>   @Article{,
    #>     title = {epinowcast: Flexible hierarchical nowcasting},
    #>     author = {Sam Abbott and Adrian Lison and Sebastian Funk},
    #>     journal = {Zenodo},
    #>     year = {2021},
    #>     doi = {10.5281/zenodo.5637165},
    #>   }

## How to make a bug report or feature request

Please briefly describe your problem and what output you expect in an
[issue](https://github.com/epinowcast/epinowcast/issues). If you have a
question, please don’t open an issue. Instead, ask on our [Q and A
page](https://github.com/epinowcast/epinowcast/discussions/categories/q-a).
See our [contributing
guide](https://github.com/epinowcast/epinowcast/blob/main/CONTRIBUTING.md)
for more information.

## Contributing

We welcome contributions and new contributors\! We particularly
appreciate help on priority problems in the
[issues](https://github.com/epinowcast/epinowcast/issues). Please check
and add to the issues, and/or add a [pull
request](https://github.com/epinowcast/epinowcast/pulls). See our
[contributing
guide](https://github.com/epinowcast/epinowcast/blob/main/CONTRIBUTING.md)
for more information.

If interested in expanding the functionality of the underlying model
note that `epinowcast` allows users to pass in their own models meaning
that alternative parameterisations, for example altering the forecast
model used for inferring expected observations, may be easily tested
within the package infrastructure. Once this testing has been done
alterations that increase the flexibility of the package model and
improves its defaults are very welcome via pull request or other
communication with the package authors. Even if not wanting to add your
updated model to the package please do reach out as we would love to
hear about your use case.

## Code of Conduct

Please note that the `epinowcast` project is released with a
[Contributor Code of
Conduct](https://package.epinowcast.org/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.
