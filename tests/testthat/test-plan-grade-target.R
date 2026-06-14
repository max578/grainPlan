# The grade-target verb: a grade-band (threshold-economics) decision that
# decides on grounded evidence, abstains on unverified, and respects input cost.

test_that("a worthwhile protein lift is recommended on grounded evidence", {
  # Baseline protein sits just under the APW band edge; a strong, cheap top-up
  # clears the +30 band step on most draws, so pushing the input pays.
  set.seed(11L)
  protein <- stats::rnorm(3000L, mean = 11.2, sd = 0.4)
  v <- wheat_protein_bands()
  gd <- plan_grade_target(
    protein, actions = seq(0, 60, by = 10), value = v,
    quality_shift = function(rate, p) p + 0.05 * rate, cost = 0.2,
    crop = "wheat", grounding = decideR::grounding_grounded())
  expect_equal(gd@kind, "grade_target")
  expect_false(gd@abstained)
  expect_true(grain_is_grounded(gd))
  expect_true(gd@action > 0)
})

test_that("unverified quality evidence holds the status quo (firewall)", {
  set.seed(11L)
  protein <- stats::rnorm(3000L, mean = 11.0, sd = 0.5)
  v <- wheat_protein_bands()
  gd <- plan_grade_target(
    protein, actions = seq(0, 60, by = 10), value = v,
    quality_shift = function(rate, p) p + 0.03 * rate, cost = 1.0,
    grounding = decideR::grounding_unverified())
  expect_true(gd@abstained)
  expect_false(grain_is_grounded(gd))
  expect_equal(gd@action, 0)
})

test_that("a prohibitive cost makes the status quo win even when grounded", {
  set.seed(11L)
  protein <- stats::rnorm(3000L, mean = 11.0, sd = 0.5)
  v <- wheat_protein_bands()
  # cost per unit far exceeds any band step -> no action clears the bar.
  gd <- plan_grade_target(
    protein, actions = seq(0, 60, by = 10), value = v,
    quality_shift = function(rate, p) p + 0.03 * rate, cost = 1000,
    grounding = decideR::grounding_grounded())
  expect_equal(gd@action, 0)
})

test_that("plan_grade_target requires a grade_band_value schedule", {
  protein <- stats::rnorm(100L, 11, 0.5)
  expect_error(
    plan_grade_target(protein, actions = c(0, 10), value = function(x) x),
    "grade_band_value")
  expect_error(
    plan_grade_target(numeric(0L), actions = c(0, 10),
                      value = wheat_protein_bands()),
    "non-empty numeric vector")
})

test_that("the barley malting schedule drives a grade-target decision", {
  # Baseline protein sits below the malting window; a top-up lifts it in.
  set.seed(13L)
  protein <- stats::rnorm(3000L, mean = 8.8, sd = 0.3)
  v <- barley_malting_premium(window = c(9.5, 12.5), feed_price = 280,
                              malting_premium = 80)
  gd <- plan_grade_target(
    protein, actions = c(0, 40), value = v,
    quality_shift = function(rate, p) p + 0.03 * rate, cost = 0.5,
    crop = "barley", grounding = decideR::grounding_grounded())
  expect_equal(gd@crop, "barley")
  expect_false(gd@abstained)
  expect_equal(gd@action, 40)               # the top-up clears into malting
})
