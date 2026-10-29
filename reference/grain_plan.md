# A grain plan – an ordered season of grain decisions with combined grounding

The orchestrator's output: a sequence of
[grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
objects gathered into one provenance-carrying season plan. The plan's
`grounding` is the worst case across its decisions (via
[`decideR::combine_grounding()`](https://rdrr.io/pkg/decideR/man/combine_grounding.html)),
so a plan that rests on any unverified decision is itself `"ungrounded"`
– the Independent Oracle Principle applied at the plan level. A plan is
`partial_abstention` when at least one of its decisions abstained, which
a report surfaces so a grower never reads a confident headline over a
plan with a declined component.

## Usage

``` r
grain_plan(
  decisions = list(),
  crop = NA_character_,
  season = NA_character_,
  grounding = "ungrounded",
  partial_abstention = FALSE,
  metadata = list()
)
```

## Arguments

- decisions:

  A list of
  [grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
  objects, in the order they apply through the season.

- crop:

  The crop the plan concerns.

- season:

  A short label for the season or field the plan covers.

- grounding:

  A canonical grounding token, combined worst-case across the decisions.

- partial_abstention:

  `TRUE` when at least one decision in the plan abstained.

- metadata:

  A named list of free-form plan metadata.

## Value

A `grain_plan` S7 object.

## See also

[`plan_season()`](https://max578.github.io/grainPlan/reference/plan_season.md)
for the constructor;
[grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
for the unit.

Other grain-objects:
[`grain_decision()`](https://max578.github.io/grainPlan/reference/grain_decision.md),
[`grain_is_grounded()`](https://max578.github.io/grainPlan/reference/grain_is_grounded.md),
[`grain_plan_table()`](https://max578.github.io/grainPlan/reference/grain_plan_table.md),
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
plan_season(list(n_dec), crop = "wheat", season = "2026 paddock 7")
#> <grain_plan> 2026 paddock 7 -- 1 decision  [grounded]
#>   - [decide  ] nitrogen_rate : 150 kg N/ha
```
