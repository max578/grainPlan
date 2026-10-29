# Is a grain decision or plan grounded?

A convenience predicate reading the grounding label of a
[grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
or
[grain_plan](https://max578.github.io/grainPlan/reference/grain_plan.md).
A grower-facing report, or a downstream automation that must refuse to
act on unverified evidence, gates on this. It mirrors
[`decideR::is_grounded()`](https://rdrr.io/pkg/decideR/man/is_grounded.html)
one level up, reading the grain object's own worst-case grounding token.

## Usage

``` r
grain_is_grounded(x)
```

## Arguments

- x:

  A
  [grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
  or
  [grain_plan](https://max578.github.io/grainPlan/reference/grain_plan.md).

## Value

`TRUE` when the object's grounding is
[`decideR::grounding_grounded()`](https://rdrr.io/pkg/decideR/man/grounding_tokens.html).

## See also

Other grain-objects:
[`grain_decision()`](https://max578.github.io/grainPlan/reference/grain_decision.md),
[`grain_plan()`](https://max578.github.io/grainPlan/reference/grain_plan.md),
[`grain_plan_table()`](https://max578.github.io/grainPlan/reference/grain_plan_table.md),
[`plan_season()`](https://max578.github.io/grainPlan/reference/plan_season.md)

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
grain_is_grounded(gd)
#> [1] TRUE
```
