# Plan a grade target under a quality-band payoff

Choose how hard to push a quality-driving input when the grain payoff
steps at a delivery-standard threshold (a wheat protein band, a barley
malting window) rather than rising smoothly. It is a grain-semantics
wrapper over
[`decideR::decide()`](https://rdrr.io/pkg/decideR/man/decide.html)
driven by a grade-band loss: the value schedule prices each quality
band, the utility is the band payoff of the shifted quality outcome less
the input cost, and the expected utility decideR averages over the draws
is governed by each band's posterior probability – exactly the threshold
economics a quality-graded decision faces. It abstains to the status-quo
action when the quality evidence is unverified or no action is clearly
better.

## Usage

``` r
plan_grade_target(
  quality_draws,
  actions,
  value,
  quality_shift = NULL,
  cost = 0,
  crop = "wheat",
  grounding = decideR::grounding_unverified(),
  safe_action = NULL,
  decisive_prob = 0.6,
  ...
)
```

## Arguments

- quality_draws:

  A numeric vector of posterior draws of the baseline quality outcome
  under the status-quo action.

- actions:

  A numeric vector of candidate input levels (the grid the decision
  chooses over).

- value:

  A
  [`decideR::grade_band_value`](https://rdrr.io/pkg/decideR/man/grade_band_value.html)
  schedule pricing the quality bands – typically
  [`wheat_protein_bands()`](https://max578.github.io/grainPlan/reference/wheat_protein_bands.md)
  or
  [`barley_malting_premium()`](https://max578.github.io/grainPlan/reference/barley_malting_premium.md).

- quality_shift:

  A function `function(action, quality)` returning the realised quality
  under the action, or `NULL` for the additive default
  `quality + action`.

- cost:

  A per-unit input cost (a single number applied as `cost * action`), a
  function `function(action)`, or `0` for no cost.

- crop:

  The crop the decision concerns (default `"wheat"`).

- grounding:

  One or more grounding tokens for the quality evidence; combined
  worst-case.

- safe_action:

  The action returned on abstention (default the first element of
  `actions`, the status quo).

- decisive_prob:

  Minimum posterior probability that the leading action beats the status
  quo (passed to
  [`decideR::decide()`](https://rdrr.io/pkg/decideR/man/decide.html)).

- ...:

  Further arguments passed to the decision core (e.g. `min_ess`).

## Value

A
[grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
of kind `"grade_target"` whose `action` is the recommended input level.

## Details

`quality_draws` is a numeric vector of posterior draws of the baseline
quality outcome (grain protein, say) under no extra input. `actions` is
the candidate input grid (a nitrogen-rate grid, say).
`quality_shift(action, quality)` returns the realised quality under an
action – the additive default `quality + action` suits a unit that lifts
quality one-for-one, and a supplied function suits a saturating or
partial response. `value` is a grade-band schedule from grainPlan's
value library (or any
[`decideR::grade_band_value()`](https://rdrr.io/pkg/decideR/man/grade_band_value.html)),
and `cost` prices the input.

## See also

[`wheat_protein_bands()`](https://max578.github.io/grainPlan/reference/wheat_protein_bands.md)
and
[`barley_malting_premium()`](https://max578.github.io/grainPlan/reference/barley_malting_premium.md)
for the value schedules;
[`decideR::grade_band_utility()`](https://rdrr.io/pkg/decideR/man/grade_band_utility.html)
for the loss;
[`decideR::decide()`](https://rdrr.io/pkg/decideR/man/decide.html) for
the engine.

Other grain-decisions:
[`plan_nitrogen_rate()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate.md),
[`plan_nitrogen_rate_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate_from_manifest.md),
[`plan_variety()`](https://max578.github.io/grainPlan/reference/plan_variety.md),
[`plan_variety_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_variety_from_manifest.md)

## Examples

``` r
set.seed(1L)
# Baseline protein draws; a nitrogen top-up lifts protein additively.
protein <- rnorm(2000L, mean = 11.0, sd = 0.6)
v <- wheat_protein_bands()
plan_grade_target(protein, actions = seq(0, 60, by = 10), value = v,
                  quality_shift = function(rate, p) p + 0.02 * rate,
                  cost = 1.3, crop = "wheat",
                  grounding = decideR::grounding_grounded())
#> <grain_decision> RECOMMENDED  [grounded]
#>   crop   : wheat
#>   kind   : grade_target
#>   action : 0 input level
#>   why    : Set the input to 0 for the wheat crop: it maximises the expected graded payoff ($330/t) by raising the posterior probability of clearing a higher quality band, net of input cost.
```
