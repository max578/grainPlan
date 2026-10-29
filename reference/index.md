# Package index

## Grain decisions

The grain-semantics verbs – each wraps decideR’s engine with grain
meaning and returns a grain_decision.

- [`plan_nitrogen_rate()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate.md)
  : Plan a nitrogen rate for a grain crop
- [`plan_nitrogen_rate_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate_from_manifest.md)
  : Plan a nitrogen rate from an upstream orchestra manifest
- [`plan_variety()`](https://max578.github.io/grainPlan/reference/plan_variety.md)
  : Plan a variety choice from a multi-environment trial or genomic
  posterior
- [`plan_variety_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_variety_from_manifest.md)
  : Plan a variety choice from a breeding-values manifest
- [`plan_grade_target()`](https://max578.github.io/grainPlan/reference/plan_grade_target.md)
  : Plan a grade target under a quality-band payoff

## The orchestrator

Compose grain decisions into a provenance-carrying season plan.

- [`plan_season()`](https://max578.github.io/grainPlan/reference/plan_season.md)
  : Compose grain decisions into a season plan
- [`grain_plan_table()`](https://max578.github.io/grainPlan/reference/grain_plan_table.md)
  : Summarise a grain plan as a data frame

## Grain value library

Reusable, documented grain value and loss schedules built from published
grade conventions.

- [`wheat_protein_bands()`](https://max578.github.io/grainPlan/reference/wheat_protein_bands.md)
  : Wheat protein-band value schedule
- [`barley_malting_premium()`](https://max578.github.io/grainPlan/reference/barley_malting_premium.md)
  : Barley malting-premium value schedule
- [`n_rate_economics()`](https://max578.github.io/grainPlan/reference/n_rate_economics.md)
  : Nitrogen-rate economics

## Result objects

The S7 result types and their predicate.

- [`grain_decision()`](https://max578.github.io/grainPlan/reference/grain_decision.md)
  : A grain decision – a recommended grain action with context and
  grounding
- [`grain_plan()`](https://max578.github.io/grainPlan/reference/grain_plan.md)
  : A grain plan – an ordered season of grain decisions with combined
  grounding
- [`grain_is_grounded()`](https://max578.github.io/grainPlan/reference/grain_is_grounded.md)
  : Is a grain decision or plan grounded?
- [`print.grain_decision`](https://max578.github.io/grainPlan/reference/print.grain_decision.md)
  : Print a grain decision
- [`print.grain_plan`](https://max578.github.io/grainPlan/reference/print.grain_plan.md)
  : Print a grain plan
- [`print(`*`<n_rate_economics>`*`)`](https://max578.github.io/grainPlan/reference/print.n_rate_economics.md)
  : Print nitrogen-rate economics
