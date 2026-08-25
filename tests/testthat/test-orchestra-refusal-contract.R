# Fleet cross-member refusal/abstention contract (ORCHESTRA_dev leader-side
# convention, `integration/refusal_contract.R`): a member's decline object
# must carry a `class()` entry ending in `_refusal` or `_abstention`, or the
# explicit `orchestra_refusal` marker, so a producer-agnostic gate recognises
# it without depending on any one member's namespace. Re-implemented here
# (not sourced from ORCHESTRA_dev) so this package's test suite never depends
# on a sibling workspace.
#
# GP-03/audit finding (2026-08-26 typed-refusals closeout): every
# `plan_*_from_manifest()` verb raises a correctly-typed decline INSIDE
# decideR (an abstained `decideR::decision`, itself stamped
# `decideR_abstention`), but the OUTER `grain_decision` grainPlan hands back
# to the caller was never stamped -- its class stayed
# `c("grainPlan::grain_decision", "S7_object")` regardless of `@abstained`,
# invisible to the fleet gate. Fixed by stamping `grainPlan_abstention` +
# `orchestra_refusal` onto the outer object whenever the wrapped decision
# abstained (which covers both a plain abstention and a manifest
# contract-refusal, since `.manifest_contract_refusal()` also sets
# `abstained = TRUE`).

.is_orchestra_decline <- function(x) {
  cls <- class(x)
  any(cls == "orchestra_refusal") || any(grepl("_(refusal|abstention)$", cls))
}

test_that("grain_decision from an abstained matrix decision is fleet-visible", {
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  gd <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                           crop = "wheat", safe_rate = 0,
                           grounding = decideR::grounding_unverified())
  expect_true(gd@abstained)
  # Demonstrates the pre-fix defect: the outer object's class carried neither
  # suffix nor marker even though decideR's OWN wrapped decision was already
  # stamped `decideR_abstention` one level down.
  expect_true(any(grepl("_abstention$", class(gd@decision))))
  expect_true(.is_orchestra_decline(gd),
             info = paste("outer grain_decision class:",
                          paste(class(gd), collapse = ", ")))
})

test_that("grain_decision from a decided (non-abstained) rate is NOT stamped", {
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  gd <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                           crop = "wheat",
                           grounding = decideR::grounding_grounded())
  expect_false(gd@abstained)
  expect_false(.is_orchestra_decline(gd))
  expect_false(any(class(gd) == "grainPlan_abstention"))
  expect_false(any(class(gd) == "orchestra_refusal"))
})

test_that("plan_nitrogen_rate_from_manifest() abstention is fleet-visible", {
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  manifest <- .fixture_yield_manifest(yld, grounding = decideR::grounding_unverified())
  gd <- plan_nitrogen_rate_from_manifest(manifest, rates,
                                         price_grain = 350, price_n = 1.3,
                                         crop = "wheat")
  expect_true(gd@abstained)
  expect_true(.is_orchestra_decline(gd),
             info = paste("outer grain_decision class:",
                          paste(class(gd), collapse = ", ")))
})

test_that("plan_nitrogen_rate_from_manifest() wrong inferential_target refusal is fleet-visible", {
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  manifest <- .fixture_yield_manifest(yld, grounding = decideR::grounding_grounded())
  manifest@metadata$inferential_target <- "structure"
  gd <- plan_nitrogen_rate_from_manifest(manifest, rates,
                                         price_grain = 350, price_n = 1.3,
                                         crop = "wheat")
  expect_true(gd@abstained)
  expect_equal(gd@decision@abstain_reason, "wrong_inferential_target")
  expect_true(.is_orchestra_decline(gd),
             info = paste("outer grain_decision class:",
                          paste(class(gd), collapse = ", ")))
})

test_that("plan_nitrogen_rate_from_manifest() producer-abstained manifest refusal is fleet-visible", {
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  manifest <- .fixture_yield_manifest(
    yld, grounding = decideR::grounding_grounded(),
    summary = list(headline = "no result", abstained = TRUE, metrics = list()))
  gd <- plan_nitrogen_rate_from_manifest(manifest, rates,
                                         price_grain = 350, price_n = 1.3,
                                         crop = "wheat")
  expect_true(gd@abstained)
  expect_equal(gd@decision@abstain_reason, "producer_abstained")
  expect_true(.is_orchestra_decline(gd),
             info = paste("outer grain_decision class:",
                          paste(class(gd), collapse = ", ")))
})

test_that("plan_variety_from_manifest() wrong inferential_target refusal is fleet-visible", {
  gebv <- c(g1 = 1.2, g2 = 0.8, g3 = 1.5)
  manifest <- .fixture_gebv_manifest(gebv, grounding = decideR::grounding_grounded())
  manifest@metadata$inferential_target <- "predictions"
  gd <- plan_variety_from_manifest(manifest)
  expect_true(gd@abstained)
  expect_equal(gd@decision@abstain_reason, "wrong_inferential_target")
  expect_true(.is_orchestra_decline(gd),
             info = paste("outer grain_decision class:",
                          paste(class(gd), collapse = ", ")))
})

test_that("plan_grade_target() abstained decision is fleet-visible (print + predicate)", {
  set.seed(1L)
  protein <- stats::rnorm(2000L, mean = 11.0, sd = 0.6)
  v <- wheat_protein_bands()
  gd <- plan_grade_target(protein, actions = seq(0, 60, by = 10), value = v,
                          quality_shift = function(rate, p) p + 0.02 * rate,
                          cost = 1.3, crop = "wheat",
                          grounding = decideR::grounding_unverified())
  expect_true(gd@abstained)
  expect_true(.is_orchestra_decline(gd))
  # print() must still work on the reclassed S7 object (prepending, not
  # replacing, the class vector -- S7 dispatch and @ access survive).
  expect_output(print(gd), "ABSTAINED")
  expect_equal(gd@kind, "grade_target")
})
