# Print a grain decision

Print a grain decision

## Arguments

- x:

  A
  [grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md).

- ...:

  Ignored, for compatibility with
  [`print()`](https://rdrr.io/r/base/print.html).

## Value

`x`, invisibly.

## Examples

``` r
set.seed(1L)
rates <- seq(0, 150, by = 25)
ymax  <- rnorm(800L, 5.5, 0.3)
yld   <- vapply(rates, function(r) 3 + (ymax - 3) * (1 - exp(-r / 70)),
                numeric(800L))
print(plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                         crop = "wheat",
                         grounding = decideR::grounding_grounded()))
#> <grain_decision> RECOMMENDED  [grounded]
#>   crop   : wheat
#>   kind   : nitrogen_rate
#>   action : 150 kg N/ha
#>   why    : Apply 150 kg N/ha to the wheat crop: it maximises expected profit ($1625.8/unit area) and clearly beats the status quo on the posterior.
```
