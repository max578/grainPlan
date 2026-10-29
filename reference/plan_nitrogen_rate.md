# Plan a nitrogen rate for a grain crop

The canonical grain decision: choose how much nitrogen to apply to a
crop by expected profit, abstaining to the status-quo rate when the
yield evidence is unverified or no rate is clearly better. It is a
grain-semantics wrapper over
[`decideR::decide_input_rate()`](https://rdrr.io/pkg/decideR/man/decide_input_rate.html)
– the profit maximisation, the grounding firewall, and the abstention
logic are decideR's; grainPlan supplies the grain economics
([`n_rate_economics()`](https://max578.github.io/grainPlan/reference/n_rate_economics.md)),
the crop context, a grower-facing rationale, and the
[grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
result.

## Usage

``` r
plan_nitrogen_rate(
  yield_draws,
  rates,
  price_grain,
  price_n,
  crop = "wheat",
  grounding = decideR::grounding_unverified(),
  safe_rate = 0,
  decisive_prob = 0.6,
  ...
)
```

## Arguments

- yield_draws:

  A numeric matrix of posterior yield draws, one column per candidate
  rate (rows are draws).

- rates:

  A numeric vector of candidate nitrogen rates, one per column of
  `yield_draws`.

- price_grain:

  The grain price per unit yield (passed to
  [`n_rate_economics()`](https://max578.github.io/grainPlan/reference/n_rate_economics.md)).

- price_n:

  The nitrogen price per unit rate (passed to
  [`n_rate_economics()`](https://max578.github.io/grainPlan/reference/n_rate_economics.md)).

- crop:

  The crop the decision concerns (default `"wheat"`).

- grounding:

  One or more grounding tokens for the yield evidence; combined
  worst-case and passed to the decision engine.

- safe_rate:

  The fallback rate on abstention (default `0`, the no-input status
  quo).

- decisive_prob:

  Minimum posterior probability that the leading rate beats the status
  quo (passed to
  [`decideR::decide()`](https://rdrr.io/pkg/decideR/man/decide.html)).

- ...:

  Further arguments passed to the decision core (e.g. `min_ess`).
  `constraint` is rejected with an error:
  [`decideR::decide_input_rate()`](https://rdrr.io/pkg/decideR/man/decide_input_rate.html)
  does not honour a rate constraint and would otherwise drop it silently
  (use
  [`plan_nitrogen_rate_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate_from_manifest.md),
  which does honour one, or cap `rates` before calling).

## Value

A
[grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
of kind `"nitrogen_rate"` whose `action` is the recommended rate.

## Details

Pass either a yield-draws matrix (`yield_draws`, one column per
candidate rate, rows are posterior draws – the object a PESTO inversion
or a mechanistic yield-response posterior produces) together with
`rates`, or an upstream `orchestra_manifest` to
[`plan_nitrogen_rate_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate_from_manifest.md),
which sources the draws and the grounding token straight from the
manifest. Either way the grounding rides from the evidence through the
decision: an unverified yield posterior forces the status-quo rate,
never a confident wrong recommendation.

## See also

[`plan_nitrogen_rate_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate_from_manifest.md)
for the manifest entry point;
[`n_rate_economics()`](https://max578.github.io/grainPlan/reference/n_rate_economics.md)
for the economics;
[`decideR::decide_input_rate()`](https://rdrr.io/pkg/decideR/man/decide_input_rate.html)
for the underlying engine.

Other grain-decisions:
[`plan_grade_target()`](https://max578.github.io/grainPlan/reference/plan_grade_target.md),
[`plan_nitrogen_rate_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate_from_manifest.md),
[`plan_variety()`](https://max578.github.io/grainPlan/reference/plan_variety.md),
[`plan_variety_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_variety_from_manifest.md)

## Examples

``` r
set.seed(1L)
rates <- seq(0, 200, by = 25)
# diminishing-returns yield response with posterior noise
mu <- 3 + 2.5 * (1 - exp(-rates / 80))
yield_draws <- vapply(mu, function(m) rnorm(1500L, m, 0.3), numeric(1500L))
plan_nitrogen_rate(yield_draws, rates, price_grain = 350, price_n = 1.3,
                   crop = "wheat",
                   grounding = decideR::grounding_grounded())
#> <grain_decision> RECOMMENDED  [grounded]
#>   crop   : wheat
#>   kind   : nitrogen_rate
#>   action : 175 kg N/ha
#>   why    : Apply 175 kg N/ha to the wheat crop: it maximises expected profit ($1596.9/unit area) and clearly beats the status quo on the posterior.
```
