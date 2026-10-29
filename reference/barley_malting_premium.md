# Barley malting-premium value schedule

The barley counterpart to
[`wheat_protein_bands()`](https://max578.github.io/grainPlan/reference/wheat_protein_bands.md):
a price per tonne that carries a malting premium when grain protein
falls inside the malting window and drops to the feed price outside it.
Malting barley is the textbook two-sided quality payoff – protein that
is too low or too high both miss the malting grade – which a single
rising step schedule cannot express, so this schedule pays the premium
only across the central band.

## Usage

``` r
barley_malting_premium(
  window = c(9.5, 12.5),
  feed_price = 280,
  malting_premium = 60
)
```

## Arguments

- window:

  A length-two numeric vector `c(low, high)` giving the malting protein
  window in percent (default `c(9.5, 12.5)`).

- feed_price:

  The feed price in dollars per tonne paid outside the window (default
  an illustrative `280`).

- malting_premium:

  The premium in dollars per tonne added to the feed price inside the
  window (default an illustrative `60`).

## Value

A
[`decideR::grade_band_value`](https://rdrr.io/pkg/decideR/man/grade_band_value.html)
schedule: a vectorised function from a protein outcome to its
dollar-per-tonne payoff, paying `feed_price + malting_premium` inside
the window and `feed_price` outside.

## Details

The default `window` is the broad malting protein window in percent and
the default prices are an illustrative feed price and malting premium in
dollars per tonne. The window shape (a premium inside an acceptance
band, feed outside) follows the published Barley Australia / Grain Trade
Australia malting receival conventions; the dollar values are
illustrative and not receival prices. Supply current prices for a real
decision.

## References

Barley Australia and Grain Trade Australia malting barley receival
standards (the malting protein window). Dollar values are illustrative.

## See also

[`wheat_protein_bands()`](https://max578.github.io/grainPlan/reference/wheat_protein_bands.md)
for the wheat counterpart;
[`plan_grade_target()`](https://max578.github.io/grainPlan/reference/plan_grade_target.md)
for the decision that consumes it.

Other grain-value:
[`n_rate_economics()`](https://max578.github.io/grainPlan/reference/n_rate_economics.md),
[`wheat_protein_bands()`](https://max578.github.io/grainPlan/reference/wheat_protein_bands.md)

## Examples

``` r
v <- barley_malting_premium()
v(c(8.0, 10.5, 13.0))
#> [1] 280 340 280
v
#> <grade_band_value> 3 bands
#>                 band value
#>          feed (<9.5)   280
#>  malting [9.5, 12.5)   340
#>        feed (>=12.5)   280
```
