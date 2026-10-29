# Plan a variety choice from a multi-environment trial or genomic posterior

Rank candidate grain varieties under a downside-aware merit loss and
recommend the leading one, abstaining when the merit evidence is
unverified or no variety is clearly better than the incumbent. It is a
grain-semantics wrapper over
[`decideR::decide()`](https://rdrr.io/pkg/decideR/man/decide.html): the
variety indices are the candidate actions, the utility is each variety's
posterior merit less a one-sided downside penalty (`risk_aversion` times
the shortfall below the variety's own mean, so a high-yielding but
volatile line is discounted against a steady one), and the grounding
firewall plus abstention are decideR's.

## Usage

``` r
plan_variety(
  merit_draws,
  varieties = NULL,
  risk_aversion = 0.5,
  incumbent = NULL,
  crop = "wheat",
  grounding = decideR::grounding_unverified(),
  decisive_prob = 0.6,
  ...
)
```

## Arguments

- merit_draws:

  A numeric matrix of posterior merit draws, one column per variety
  (rows are draws).

- varieties:

  A character vector of variety names, one per column of `merit_draws`;
  defaults to the column names of `merit_draws`, then to `"v1"`, `"v2"`,
  ....

- risk_aversion:

  A non-negative number weighting the one-sided downside penalty
  (default `0.5`); `0` is plain expected merit.

- incumbent:

  The variety recommended on abstention – the status-quo line a grower
  keeps when the evidence does not justify a switch; a variety name in
  `varieties`, or `NULL` to default to the first variety.

- crop:

  The crop the decision concerns (default `"wheat"`).

- grounding:

  One or more grounding tokens for the merit evidence; combined
  worst-case.

- decisive_prob:

  Minimum posterior probability that the leading variety beats the
  incumbent (passed to
  [`decideR::decide()`](https://rdrr.io/pkg/decideR/man/decide.html)).

- ...:

  Further arguments passed to the decision core (e.g. `min_ess`).

## Value

A
[grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
of kind `"variety"` whose `action` is the recommended variety name; the
ranked short-list is in `decision@candidates` of the wrapped decision.

## Details

`merit_draws` is a numeric matrix of posterior merit draws with one
column per variety (rows are draws) – the object a factor-analytic MET
model emits (a variety's mean across environments) or a
genomic-prediction model emits (its genomic estimated breeding value
posterior). The recommendation is the single leading variety; the full
ranked ledger of every variety's expected merit is carried in the
wrapped decision's `candidates` for a short-list.

The grounding rides from the evidence: an unverified merit posterior
forces the recommendation to the `incumbent` variety (the safe action),
so a variety is never switched on evidence the producer did not ground.

## See also

[`plan_variety_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_variety_from_manifest.md)
for a `breeding_values` manifest;
[`decideR::decide()`](https://rdrr.io/pkg/decideR/man/decide.html) for
the underlying engine.

Other grain-decisions:
[`plan_grade_target()`](https://max578.github.io/grainPlan/reference/plan_grade_target.md),
[`plan_nitrogen_rate()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate.md),
[`plan_nitrogen_rate_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate_from_manifest.md),
[`plan_variety_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_variety_from_manifest.md)

## Examples

``` r
set.seed(1L)
varieties <- c("Scepter", "Vixen", "Calibre", "Denison")
means <- c(5.2, 5.4, 4.9, 5.3)
merit_draws <- vapply(means, function(m) rnorm(1000L, m, 0.25),
                      numeric(1000L))
plan_variety(merit_draws, varieties, crop = "wheat",
             grounding = decideR::grounding_grounded())
#> <grain_decision> RECOMMENDED  [grounded]
#>   crop   : wheat
#>   kind   : variety
#>   action : Vixen variety
#>   why    : Sow Vixen in the wheat crop: it leads the downside-aware merit ranking and clearly beats the incumbent (Scepter) on the posterior.
```
