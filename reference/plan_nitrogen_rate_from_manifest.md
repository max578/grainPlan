# Plan a nitrogen rate from an upstream orchestra manifest

The manifest entry point to the nitrogen-rate decision: source the yield
draws and the producer's grounding token straight from an
`orchestra_manifest` emitted upstream (a PESTO inversion, a mechanistic
yield-response posterior), price them, and return a
[grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md).
It is the formalised crop-pipeline tail at the grain layer – a yield
posterior in, a profit-priced, grounding-aware nitrogen-rate plan out –
built directly on
[`decideR::decide_rate_from_manifest()`](https://rdrr.io/pkg/decideR/man/decide_rate_from_manifest.html),
which reads the manifest by its public contract (the draws matrix and
the grounding token) without grainPlan depending on the contract
package.

## Usage

``` r
plan_nitrogen_rate_from_manifest(
  manifest,
  rates,
  price_grain,
  price_n,
  crop = "wheat",
  grounding = NULL,
  safe_rate = 0,
  decisive_prob = 0.6,
  ...
)
```

## Arguments

- manifest:

  An `orchestra_manifest` carrying a yield-per-rate draws matrix (in
  `outputs` or `metadata$yield_draws`), one column per rate.

- rates:

  A numeric vector of candidate nitrogen rates, one per column of the
  manifest's draws matrix.

- price_grain:

  The grain price per unit yield.

- price_n:

  The nitrogen price per unit rate.

- crop:

  The crop the decision concerns (default `"wheat"`).

- grounding:

  Optional override for the manifest's own grounding token; `NULL`
  (default) uses the token the manifest carries, read worst-case.

- safe_rate:

  The fallback rate on abstention (default `0`).

- decisive_prob:

  Minimum posterior probability that the leading rate beats the status
  quo.

- ...:

  Further arguments passed to the decision core (e.g. `min_ess`,
  `draws_key`).

## Value

A
[grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
of kind `"nitrogen_rate"` whose `action` is the recommended rate. Held
at `safe_rate`, unpriced, when the manifest's own producer declared an
abstention (`summary$abstained`), or when it declares an
`inferential_target` other than `"predictions"` or `"parameters"`.

## Details

The grounding rides from the producer through the decision: an
unverified yield manifest forces the status-quo rate. grainPlan takes no
dependency on the manifest constructor; the manifest is read by
decideR's duck-typed tail. A caller who has independently grounded (or
wants to force `"ungrounded"` on) a manifest can override the producer's
token through `grounding`, matching
[`plan_variety_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_variety_from_manifest.md).

## See also

[`plan_nitrogen_rate()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate.md)
for the caller-assembled-matrix form;
[`decideR::decide_rate_from_manifest()`](https://rdrr.io/pkg/decideR/man/decide_rate_from_manifest.html)
for the underlying tail.

Other grain-decisions:
[`plan_grade_target()`](https://max578.github.io/grainPlan/reference/plan_grade_target.md),
[`plan_nitrogen_rate()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate.md),
[`plan_variety()`](https://max578.github.io/grainPlan/reference/plan_variety.md),
[`plan_variety_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_variety_from_manifest.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# `manifest` is an orchestra_manifest S7 object emitted upstream (a PESTO
# inversion or a mechanistic yield-response posterior), carrying a yield-per-rate
# draws matrix in its `outputs` slot (or `metadata$yield_draws`) and a
# grounding token in `metadata$grounding`. decideR's tail reads it by its
# public S7 contract, so grainPlan needs no dependency on the contract package.
rates <- seq(0, 200, by = 25)
plan_nitrogen_rate_from_manifest(manifest, rates,
                                 price_grain = 350, price_n = 1.3)
} # }
```
