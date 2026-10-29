# Print a grain plan

Print a grain plan

## Arguments

- x:

  A
  [grain_plan](https://max578.github.io/grainPlan/reference/grain_plan.md).

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
gd <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                         crop = "wheat",
                         grounding = decideR::grounding_grounded())
print(plan_season(list(gd), crop = "wheat", season = "2026 paddock 7"))
#> <grain_plan> 2026 paddock 7 -- 1 decision  [grounded]
#>   - [decide  ] nitrogen_rate : 150 kg N/ha
```
