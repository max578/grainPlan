# Compose grain decisions into a season plan

Gather an ordered list of
[grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
objects into one
[grain_plan](https://max578.github.io/grainPlan/reference/grain_plan.md)
– a single provenance-carrying recommendation for a season or field. The
plan's grounding is the worst case across its decisions (via
[`decideR::combine_grounding()`](https://rdrr.io/pkg/decideR/man/combine_grounding.html)),
so a plan that rests on any unverified decision is itself unverified:
the Independent Oracle Principle applied one level up. The plan is
flagged `partial_abstention` when at least one decision abstained, which
a grower-facing report surfaces so a confident headline is never read
over a plan with a declined component.

## Usage

``` r
plan_season(decisions, crop = NULL, season = "season", metadata = list())
```

## Arguments

- decisions:

  A list of
  [grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
  objects, in the order they apply.

- crop:

  The crop the plan concerns; defaults to the crop of the first
  decision.

- season:

  A short label for the season or field (default `"season"`).

- metadata:

  A named list of free-form plan metadata.

## Value

A
[grain_plan](https://max578.github.io/grainPlan/reference/grain_plan.md)
object.

## Details

The decisions are stored in the order given – the order they apply
through the season (variety choice at sowing, then a nitrogen rate, then
an in-season grade-target top-up, say). v0.1 composes by sequencing and
worst-case grounding only; it does not re-optimise across decisions (a
deliberately simple, auditable first orchestrator).

## See also

[grain_plan](https://max578.github.io/grainPlan/reference/grain_plan.md)
for the returned object; the `plan_*()` verbs that build the decisions.

Other grain-objects:
[`grain_decision()`](https://max578.github.io/grainPlan/reference/grain_decision.md),
[`grain_is_grounded()`](https://max578.github.io/grainPlan/reference/grain_is_grounded.md),
[`grain_plan()`](https://max578.github.io/grainPlan/reference/grain_plan.md),
[`grain_plan_table()`](https://max578.github.io/grainPlan/reference/grain_plan_table.md)

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
varieties <- c("Scepter", "Vixen", "Calibre")
merit <- vapply(c(5.2, 5.4, 4.9), function(m) rnorm(800L, m, 0.25),
                numeric(800L))
v_dec <- plan_variety(merit, varieties, crop = "wheat",
                      grounding = decideR::grounding_grounded())
plan_season(list(v_dec, n_dec), crop = "wheat", season = "2026 paddock 7")
#> <grain_plan> 2026 paddock 7 -- 2 decisions  [grounded]
#>   - [decide  ] variety       : Vixen variety
#>   - [decide  ] nitrogen_rate : 150 kg N/ha
```
