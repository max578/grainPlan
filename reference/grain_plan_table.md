# Summarise a grain plan as a data frame

Flatten a
[grain_plan](https://max578.github.io/grainPlan/reference/grain_plan.md)
into a one-row-per-decision `data.frame` for a report or a console
table: the decision kind, the recommended action and its unit, whether
it abstained, and its grounding token. The plan's worst-case grounding
and partial-abstention flag are carried as attributes so a report header
can read them without re-deriving them.

## Usage

``` r
grain_plan_table(plan)
```

## Arguments

- plan:

  A
  [grain_plan](https://max578.github.io/grainPlan/reference/grain_plan.md).

## Value

A `data.frame` with one row per decision and columns `kind`, `action`,
`unit`, `abstained`, `grounding`, plus the attributes `plan_grounding`
and `partial_abstention`.

## See also

[`plan_season()`](https://max578.github.io/grainPlan/reference/plan_season.md)
for the plan;
[grain_plan](https://max578.github.io/grainPlan/reference/grain_plan.md)
for the object.

Other grain-objects:
[`grain_decision()`](https://max578.github.io/grainPlan/reference/grain_decision.md),
[`grain_is_grounded()`](https://max578.github.io/grainPlan/reference/grain_is_grounded.md),
[`grain_plan()`](https://max578.github.io/grainPlan/reference/grain_plan.md),
[`plan_season()`](https://max578.github.io/grainPlan/reference/plan_season.md)

## Examples

``` r
set.seed(1L)
rates <- seq(0, 150, by = 25)
ymax  <- rnorm(800L, 5.5, 0.3)
yld   <- vapply(rates, function(r) 3 + (ymax - 3) * (1 - exp(-r / 70)),
                numeric(800L))
n_dec <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                            crop = "wheat",
                            grounding = decideR::grounding_grounded())
grain_plan_table(plan_season(list(n_dec), crop = "wheat"))
#>            kind action    unit abstained grounding
#> 1 nitrogen_rate    150 kg N/ha     FALSE  grounded
```
