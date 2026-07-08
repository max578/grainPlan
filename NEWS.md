# grainPlan 0.1.1

A safety and consistency release. No public function is removed or renamed, but
the genomic manifest tail changes behaviour in one deliberate way (below).

## Behaviour change

* `plan_variety_from_manifest()` no longer fabricates genomic uncertainty. When a
  manifest carries point GEBVs, the per-genotype reconstruction standard
  deviation is now resolved from the manifest itself (a prediction-error variance
  `pev`, a standard error `gebv_se`, or a `reliability` together with a
  `genetic_var`) or from an explicit caller `gebv_sd`. The previous silent
  default of `gebv_sd = 1` is gone: when no uncertainty is available the function
  now errors rather than let an arbitrary, scale-blind constant decide whether a
  variety switch fires or abstains. The resolved provenance is recorded in the
  decision context as `gebv_sd_source`. Callers who already pass `gebv_sd`
  explicitly are unaffected.

## Improvements

* `plan_nitrogen_rate_from_manifest()` gains a `grounding` override argument,
  matching `plan_variety_from_manifest()`, so a caller can force a manifest's
  grounding token either way.
* Abstention rationales are now exhaustive across every decision verb: all four
  abstention reasons decideR can emit (ungrounded input, insufficient evidence,
  no feasible action, too few effective draws) get plain-language, grower-facing
  phrasing from a single shared helper.
* Runnable manifest examples and a manifest walkthrough section were added to the
  vignette, and the README firewall example now executes on render.
* Added an explicit `R (>= 3.5.0)` floor (the S7 requirement) and an
  API-stability statement.

## Internal

* Removed an unused null-coalescing helper.
* Added targeted tests: the reconstruction-scale dependence, the low-effective-
  sample and no-feasible-action abstention branches, a functional grade-target
  cost, a nitrogen price-scaling invariant, and an independent verification that
  the variety decision computes the correct expected merit.

# grainPlan 0.1.0

First release. grainPlan is the grain-specific decision orchestrator of the
ORCHESTRA agricultural analytics stack -- the practitioner last-mile that turns
an upstream member's inference result into an actionable grain-production plan.
It is a thin grain-semantics layer on top of `decideR`, reusing that package's
decision engine, manifest-native pipeline tail, grade-band loss library, and
grounding firewall rather than re-implementing decision theory.

## New features

* Grain decision verbs that wrap `decideR`'s engine with grain meaning:
  `plan_nitrogen_rate()` and `plan_nitrogen_rate_from_manifest()` price a
  nitrogen rate by expected profit; `plan_variety()` and
  `plan_variety_from_manifest()` rank a variety from a multi-environment trial
  or a `breeding_values` manifest under a downside-aware merit loss;
  `plan_grade_target()` chooses a quality-driving input under a grade-band
  payoff.
* A reusable grain value / loss library that consolidates the economics the
  orchestra runs kept hand-building: `wheat_protein_bands()`,
  `barley_malting_premium()` (both `decideR::grade_band_value()` schedules built
  from published grade conventions), and `n_rate_economics()`.
* A season orchestrator: `plan_season()` composes several grain decisions into
  one `grain_plan`, combining their grounding worst-case so a plan resting on
  any unverified decision abstains as a whole; `grain_plan_table()` flattens a
  plan for a report.
* S7 result types `grain_decision` (one recommended grain action wrapping a
  `decideR::decision`) and `grain_plan` (an ordered season of decisions), with a
  `grain_is_grounded()` predicate and `print()` methods.
* The Independent Oracle Principle firewall is inherited and enforced at every
  verb: an `[unverified]` input forces abstention to the status quo, never a
  confident wrong recommendation.
