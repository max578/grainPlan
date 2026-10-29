# Nitrogen-rate economics

The reusable economic bundle a nitrogen-rate decision prices against:
the grain price, the nitrogen price, and the resulting per-draw profit
utility \\p_y\\y - p_n\\r\\. This is the second hand-built economic that
the orchestra runs kept re-deriving inline; `n_rate_economics()`
consolidates it into a named, documented object holding both the prices
and the utility function the decision engine consumes, so a
profit-priced rate decision reads as its economics rather than as an
anonymous lambda.

## Usage

``` r
n_rate_economics(price_grain, price_n)
```

## Arguments

- price_grain:

  The grain price per unit yield (e.g. dollars per tonne).

- price_n:

  The nitrogen price per unit rate (e.g. dollars per kilogram of
  nitrogen).

## Value

A list with class `n_rate_economics` holding `price_grain`, `price_n`,
and `utility`, where `utility(rate, yield)` returns the profit per draw
– the function form
[`decideR::decide()`](https://rdrr.io/pkg/decideR/man/decide.html) and
[`decideR::decide_rate_from_manifest()`](https://rdrr.io/pkg/decideR/man/decide_rate_from_manifest.html)
consume.

## Details

The utility is the textbook nitrogen-response economics: revenue is the
grain price times yield, the cost is the nitrogen price times the rate,
and profit is their difference. Yield and rate are in whatever units the
caller's yield draws and rate grid use (tonnes per hectare and kilograms
of nitrogen per hectare in the common case); the prices must be in
matching units (dollars per tonne and dollars per kilogram of nitrogen).

## References

Standard nitrogen-response profit economics (revenue less nitrogen
cost); the per-tonne / per-kilogram convention follows the broad
Australian grains gross-margin framework.

## See also

[`plan_nitrogen_rate()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate.md)
for the decision that consumes it.

Other grain-value:
[`barley_malting_premium()`](https://max578.github.io/grainPlan/reference/barley_malting_premium.md),
[`wheat_protein_bands()`](https://max578.github.io/grainPlan/reference/wheat_protein_bands.md)

## Examples

``` r
e <- n_rate_economics(price_grain = 350, price_n = 1.3)
e$utility(rate = 80, yield = c(4.0, 4.5, 5.0))
#> [1] 1296 1471 1646
e
#> $price_grain
#> [1] 350
#> 
#> $price_n
#> [1] 1.3
#> 
#> $utility
#> function (rate, yield) 
#> price_grain * yield - price_n * rate
#> <bytecode: 0x56007338f648>
#> <environment: 0x560076dda188>
#> 
#> attr(,"class")
#> [1] "n_rate_economics"
```
