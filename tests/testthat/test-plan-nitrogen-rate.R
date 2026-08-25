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

test_that("a caller grounding override flips the manifest verb both ways", {
  # F4: the nitrogen manifest verb now honours a grounding override, matching the
  # variety manifest verb. Forcing unverified on a grounded manifest abstains;
  # forcing grounded on an unverified manifest decides.
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)

  m_grounded <- .fixture_yield_manifest(yld, decideR::grounding_grounded())
  forced_off <- plan_nitrogen_rate_from_manifest(
    m_grounded, rates, price_grain = 350, price_n = 1.3,
    grounding = decideR::grounding_unverified())
  expect_true(forced_off@abstained)
  expect_equal(forced_off@action, 0)

  m_unverified <- .fixture_yield_manifest(yld, decideR::grounding_unverified())
  forced_on <- plan_nitrogen_rate_from_manifest(
    m_unverified, rates, price_grain = 350, price_n = 1.3,
    grounding = decideR::grounding_grounded())
  expect_false(forced_on@abstained)
  expect_true(grain_is_grounded(forced_on))
  expect_true(forced_on@action > 0)
})

test_that("an effective-sample-size floor abstains via low_ess", {
  # F6: exercises the low_ess abstention branch and its shared rationale, which
  # was previously untested at the grain-wrapper layer.
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  gd <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                           grounding = decideR::grounding_grounded(),
                           min_ess = 1e9)
  expect_true(gd@abstained)
  expect_equal(gd@decision@abstain_reason, "low_ess")
  expect_equal(gd@action, 0)
  expect_match(gd@rationale, "too few effective draws")
})

test_that("scaling both prices leaves the recommended rate unchanged", {
  # F6: a metamorphic invariant on the economics. Profit is linear in the two
  # prices, so a common positive rescale scales every candidate's expected profit
  # by the same factor and cannot move the argmax rate.
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  base <- plan_nitrogen_rate(yld, rates, price_grain = 300, price_n = 1.2,
                             grounding = decideR::grounding_grounded())
  scaled <- plan_nitrogen_rate(yld, rates, price_grain = 900, price_n = 3.6,
                               grounding = decideR::grounding_grounded())
  expect_equal(base@action, scaled@action)
})

test_that("plan_nitrogen_rate errors on a `constraint` it cannot honour (GP-02)", {
  # decideR::decide_input_rate() hardcodes constraint = NULL and only reads
  # min_ess/ess out of `...`; before the fix, `constraint` vanished silently
  # and the unconstrained rate (175) was returned as if the cap had applied.
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  expect_error(
    plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                       grounding = decideR::grounding_grounded(),
                       constraint = function(r) r <= 50),
    "constraint")
})

test_that("the manifest verb abstains when the producer itself declared an abstention (GP-03)", {
  # Contract v1.1's typed abstain state (`summary$abstained`) must force
  # abstention even when the grounding token alone reads "grounded" -- before
  # the fix this manifest was priced as a confident 175 kg N/ha.
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  m <- .fixture_yield_manifest(yld, decideR::grounding_grounded(),
                               summary = list(abstained = TRUE))
  gd <- plan_nitrogen_rate_from_manifest(m, rates, price_grain = 350,
                                         price_n = 1.3)
  expect_true(gd@abstained)
  expect_equal(gd@action, 0)
  expect_equal(gd@decision@abstain_reason, "producer_abstained")
  expect_match(gd@rationale, "declined to produce a result")
})

test_that("the manifest verb abstains on a manifest declaring the wrong inferential_target (GP-04)", {
  # A manifest whose declared inferential_target is not one this verb prices
  # (e.g. "marker_associations") must not be priced as a yield posterior --
  # before the fix it was, returning a confident 175 kg N/ha.
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  m <- .fixture_yield_manifest(
    yld, decideR::grounding_grounded())
  m@metadata$inferential_target <- "marker_associations"
  gd <- plan_nitrogen_rate_from_manifest(m, rates, price_grain = 350,
                                         price_n = 1.3)
  expect_true(gd@abstained)
  expect_equal(gd@action, 0)
  expect_equal(gd@decision@abstain_reason, "wrong_inferential_target")
})

test_that("a manifest declaring an accepted inferential_target still decides (GP-04, negative)", {
  # A declared target that IS accepted must not be caught by the new check.
  rates <- seq(0, 200, by = 25)
  yld <- .fixture_yield_draws(rates)
  m <- .fixture_yield_manifest(yld, decideR::grounding_grounded())
  m@metadata$inferential_target <- "predictions"
  gd <- plan_nitrogen_rate_from_manifest(m, rates, price_grain = 350,
                                         price_n = 1.3)
  expect_false(gd@abstained)
  expect_true(gd@action > 0)
})
