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
