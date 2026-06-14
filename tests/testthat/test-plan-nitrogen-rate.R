# The nitrogen-rate verb: grounded evidence decides; unverified evidence
# abstains to the status quo (the inherited IOP firewall); the manifest entry
# point reads draws + grounding straight off an S7 manifest.

test_that("grounded yield evidence yields a decided positive rate", {
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  gd <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                           crop = "wheat",
                           grounding = decideR::grounding_grounded())
  expect_s7_class(gd, grain_decision)
  expect_equal(gd@kind, "nitrogen_rate")
  expect_equal(gd@crop, "wheat")
  expect_equal(gd@unit, "kg N/ha")
  expect_false(gd@abstained)
  expect_true(grain_is_grounded(gd))
  expect_true(gd@action > 0)              # a positive profit-optimal rate
  expect_true(S7::S7_inherits(gd@decision, decideR::decision))
})

test_that("unverified yield evidence abstains to the safe rate (firewall)", {
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  gd <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                           crop = "wheat", safe_rate = 0,
                           grounding = decideR::grounding_unverified())
  expect_true(gd@abstained)
  expect_false(grain_is_grounded(gd))
  expect_equal(gd@action, 0)              # held at the status quo
  expect_equal(gd@decision@abstain_reason, "input_ungrounded")
  expect_match(gd@rationale, "unverified")
})

test_that("grounded-decides vs unverified-abstains differ ONLY by grounding", {
  # The decisive firewall test: identical draws, prices, and grid; flipping the
  # grounding token is the only difference, and it flips decide -> abstain.
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  grounded <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                                 grounding = decideR::grounding_grounded())
  unverified <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                                   grounding = decideR::grounding_unverified())
  expect_false(grounded@abstained)
  expect_true(unverified@abstained)
  expect_true(grounded@action > unverified@action)
})

test_that("the manifest entry point decides from a grounded S7 manifest", {
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  m <- .fixture_yield_manifest(yld, decideR::grounding_grounded())
  gd <- plan_nitrogen_rate_from_manifest(m, rates, price_grain = 350,
                                         price_n = 1.3, crop = "wheat")
  expect_false(gd@abstained)
  expect_true(grain_is_grounded(gd))
  expect_true(gd@action > 0)
  expect_equal(gd@context$evidence, "orchestra_manifest")
  expect_equal(gd@context$emitter_package, "test")
})

test_that("the manifest entry point abstains on an unverified manifest", {
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  m <- .fixture_yield_manifest(yld, decideR::grounding_unverified())
  gd <- plan_nitrogen_rate_from_manifest(m, rates, price_grain = 350,
                                         price_n = 1.3)
  expect_true(gd@abstained)
  expect_false(grain_is_grounded(gd))
  expect_equal(gd@action, 0)
})

test_that("plan_nitrogen_rate validates the draws matrix shape", {
  expect_error(
    plan_nitrogen_rate(1:10, rates = c(0, 50), price_grain = 300,
                       price_n = 1),
    "matrix with one column per rate")
})
