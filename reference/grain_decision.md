# A grain decision – a recommended grain action with context and grounding

The unit grainPlan recommends: exactly one
[`decideR::decision`](https://rdrr.io/pkg/decideR/man/decision.html)
wrapped with the grain context that gives it agronomic meaning. Where a
bare `decision` records "action 90, expected utility 1840, grounded", a
`grain_decision` records "apply 90 kg/ha of nitrogen to this wheat crop,
grounded, profit \$1840/ha" – the same decision, read in grain terms.

## Usage

``` r
grain_decision(
  decision = NULL,
  crop = NA_character_,
  kind = NA_character_,
  action = NULL,
  unit = NA_character_,
  abstained = FALSE,
  grounding = "ungrounded",
  rationale = NA_character_,
  context = list()
)
```

## Arguments

- decision:

  The wrapped
  [`decideR::decision`](https://rdrr.io/pkg/decideR/man/decision.html)
  object.

- crop:

  The crop the decision concerns (e.g. `"wheat"`, `"barley"`, `"corn"`).

- kind:

  The decision kind, one of `"nitrogen_rate"`, `"variety"`, or
  `"grade_target"`.

- action:

  The recommended action, lifted from the wrapped decision (the
  `safe_action` when the decision abstained).

- unit:

  A short string naming the units of `action` (e.g. `"kg N/ha"`,
  `"variety"`, `"protein %"`).

- abstained:

  `TRUE` when the wrapped decision declined the utility-maximal action.

- grounding:

  A canonical grounding token, copied from the wrapped decision.

- rationale:

  A short human-readable sentence explaining the recommendation,
  suitable for a grower-facing report.

- context:

  A named list of free-form grain context (prices, the candidate set,
  the dataset attribution).

## Value

A `grain_decision` S7 object.

## Details

The object carries the wrapped `decision` whole (in `decision`) so
nothing decideR computed is lost, and lifts the fields a practitioner
reads first to the top: the `crop`, the decision `kind`, the recommended
`action` and its `unit`, whether the decision `abstained`, and the
`grounding` token. The grounding is copied from the wrapped decision,
never recomputed, so a `grain_decision` can never claim a stronger
provenance than the decision it wraps.

## See also

[grain_plan](https://max578.github.io/grainPlan/reference/grain_plan.md)
for a season of decisions;
[`plan_nitrogen_rate()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate.md),
[`plan_variety()`](https://max578.github.io/grainPlan/reference/plan_variety.md),
and
[`plan_grade_target()`](https://max578.github.io/grainPlan/reference/plan_grade_target.md)
for the verbs that build it.

Other grain-objects:
[`grain_is_grounded()`](https://max578.github.io/grainPlan/reference/grain_is_grounded.md),
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
gd@action
#> [1] 150
```
