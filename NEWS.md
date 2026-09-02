# grainPlan (development version)

## Bug fixes

* `plan_nitrogen_rate()`, `plan_nitrogen_rate_from_manifest()`,
  `plan_variety()`, `plan_variety_from_manifest()`, and `plan_grade_target()`
  raised a correctly-typed decline inside `decideR` (an abstained
  `decideR::decision`, itself stamped `decideR_abstention`), but returned an
  unstamped outer `grain_decision` whenever the wrapped decision abstained --
  whether from ordinary evidence-driven abstention, a manifest producer's own
  typed abstention, or a manifest declaring an `inferential_target` the verb
  does not price. The outer object's class stayed
  `c("grainPlan::grain_decision", "S7_object")` regardless, invisible to the
  ORCHESTRA fleet's producer-agnostic decline predicate
  (`is_orchestra_decline()`). Fixed: the outer `grain_decision`'s class vector
  is now prepended with `grainPlan_abstention` and `orchestra_refusal`
  whenever `@abstained` is `TRUE`, matching `decideR`'s own stamping
  convention. Prepending, not replacing, so `@` access and the registered
  `print.grain_decision` method are unaffected. What is refused is unchanged
  -- only how the decline is signalled to a fleet-level gate (GP-03
  closeout).

## Documentation

* The nitrogen-rate vignette chunk drew an independent posterior column per
  candidate rate; `decideR`'s decisiveness gate is a *paired* comparison, so
  independent columns inflated the between-rate contrast variance and could
  mask a real, decisive profit difference. The chunk now shares one residual
  draw across rate columns, with the coupling requirement documented in-line
  (GP-01).
* The vignette's headline nitrogen example priced `lasrosas.corn` yield
  (quintals/ha) at $0.25/unit, roughly 100x below a realistic grain price, so
  the "profit-optimal" recommendation degenerated to the status-quo rate with
  no comment. Repriced to $22/quintal; the example now recommends a non-zero
  rate and a new captioned figure shows the profit-vs-rate curve behind it
  (GP-15, GP-16).
* The variety-ranking vignette chunk used each genotype's plot-level residual
  spread as the posterior standard deviation of the genotype *mean*, which
  overstates that uncertainty by roughly the square root of the replicate
  count; corrected to the standard error of the mean (`sd / sqrt(n)`). The
  prose claiming "the recommendation is the leading genotype" is now
  consistent with the printed decision, which previously abstained (GP-07).
* The variety short-list ledger printed integer candidate indices with no
  genotype label; the vignette now joins the variety names back onto the
  ledger before printing (GP-08).
* Printing a `decideR::grade_band_value` schedule dumped its closure body and
  a run-specific memory address into the rendered vignette; it is now
  rendered as its `breaks`/`values`/`labels` attributes (GP-14).
* The grade-target example's cost was high enough relative to the quality
  shift that the profit-optimal action degenerated to the status quo, at
  which point the printed rationale ("raising the posterior probability of
  clearing a higher quality band") did not describe what a zero-input action
  does; the example cost was lowered so the demonstration reaches a genuine,
  non-degenerate recommendation, and the full candidate ledger is now shown.
* Minor grammar and naming fixes: "nitrogen response trial" hyphenated to
  "nitrogen-response trial"; the `lasrosas.corn` trial location corrected to
  "Las Rosas" (agridat's own spelling), from the vignette's prior "Lasrosas
  farm".
* `README.Rmd` now renders without pandoc smart-punctuation substitution
  (`md_extensions: -smart`), so `README.md` no longer carries Unicode en
  dashes in prose; regenerated.
* The vignette was restructured to the orchestra's vignette quality bar: a
  stated grower question up front, a fixed Why/What/Do/Read/Limits/What-to-
  read-next/Reproduce shape, two `ggplot2` figures (a profit-vs-rate curve
  and the wheat protein-band schedule) replacing the base-graphics plot and
  the raw attribute dump, every table through `knitr::kable()`, and a new
  season-composition example showing a plan that inherits an upstream
  manifest producer's own typed abstention alongside a grounded decision,
  read against the plan's `grain_plan_table()` and `grain_is_grounded()`
  output. The `besag.met` variety example is now labelled `crop = "corn"`
  (the trial is 64 corn hybrids across six North Carolina counties, not
  wheat); citations added for both `agridat` sources (Anselin, Bongiovanni
  & Lowenberg-DeBoer, 2004; Besag & Higdon, 1999).

## Bug fixes

* `plan_nitrogen_rate()` now errors on a `constraint` argument, which
  `decideR::decide_input_rate()` silently dropped (it honours only
  `min_ess`/`ess` out of `...`) -- a caller capping the candidate rate set saw
  the cap vanish with no warning (GP-02).
* `plan_nitrogen_rate_from_manifest()` and `plan_variety_from_manifest()` now
  check two manifest-contract obligations before pricing draws: a producer's
  own typed abstention (`summary$abstained`, contract v1.1) forces the
  status-quo action instead of a confident recommendation (GP-03), and a
  declared `inferential_target` other than one the verb is built to price
  does the same (GP-04). Both previously rode straight through to a priced
  answer.

## Development

* Restored the `R-CMD-check` GitHub Actions workflow (dropped at `c6069e7` for
  lack of a cross-repo secret to read the private `decideR` dependency);
  green once `GH_PAT` is added to the repo.

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
