# Wheat protein-band value schedule

The canonical Australian milling-wheat payoff: a price per tonne that
steps up as grain protein clears each receival band. This is the
schedule the orchestra runs kept hand-building when they priced a
quality-graded wheat decision; `wheat_protein_bands()` consolidates it
into a first-class, documented
[`decideR::grade_band_value()`](https://rdrr.io/pkg/decideR/man/grade_band_value.html)
schedule so a decision can price protein without re-deriving the band
table.

## Usage

``` r
wheat_protein_bands(breaks = c(10.5, 11.5, 13), values = c(300, 330, 360, 400))
```

## Arguments

- breaks:

  A strictly increasing numeric vector of protein thresholds in percent
  (default `c(10.5, 11.5, 13.0)`, the milling / hard / prime-hard
  edges).

- values:

  A numeric vector of dollar-per-tonne band payoffs, of length
  `length(breaks) + 1`, ordered from the lowest (feed) band up (default
  an illustrative `c(300, 330, 360, 400)`).

## Value

A
[`decideR::grade_band_value`](https://rdrr.io/pkg/decideR/man/grade_band_value.html)
schedule: a vectorised function from a protein outcome to its band
payoff in dollars per tonne, carrying the schedule for inspection.

## Details

The default `breaks` are the protein thresholds that separate the broad
Australian wheat grades by protein – feed below the milling floor, then
the standard milling grades (Australian Standard White, Australian
Premium White) and the high-protein hard grades (Australian Hard,
Australian Prime Hard) – and the default `values` are an illustrative
step-up of dollars per tonne across them. The band shape (a step at each
protein threshold) follows the published Grain Trade Australia wheat
standards; the dollar values are illustrative and not receival prices.
Supply current prices for a real decision.

## References

Grain Trade Australia, *Wheat Standards* (publicly published receival
standards; band thresholds), and the broad Australian wheat grade
classes (AGW Feed, ASW, APW, AH, APH). Dollar values are illustrative.

## See also

[`barley_malting_premium()`](https://max578.github.io/grainPlan/reference/barley_malting_premium.md)
for the barley counterpart;
[`plan_grade_target()`](https://max578.github.io/grainPlan/reference/plan_grade_target.md)
for the decision that consumes it.

Other grain-value:
[`barley_malting_premium()`](https://max578.github.io/grainPlan/reference/barley_malting_premium.md),
[`n_rate_economics()`](https://max578.github.io/grainPlan/reference/n_rate_economics.md)

## Examples

``` r
v <- wheat_protein_bands()
v(c(9.5, 11.0, 11.5, 13.4))
#> [1] 300 330 360 400
v
#> <grade_band_value> 4 bands
#>              band value
#>      Feed (<10.5)   300
#>  ASW [10.5, 11.5)   330
#>  APW [11.5, 13.0)   360
#>   AH/APH (>=13.0)   400
```
