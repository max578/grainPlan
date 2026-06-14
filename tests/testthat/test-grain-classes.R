# The S7 result types: construction, validation, the grounding predicate, and
# the print methods.

test_that("grain_decision validates its grounding token and kind", {
  expect_error(
    grain_decision(grounding = "ungrounded"),
    "canonical grounding token")
  expect_error(
    grain_decision(grounding = decideR::grounding_grounded(),
                   kind = "not_a_kind"),
    "@kind must be one of")
  # a valid minimal object constructs
  gd <- grain_decision(grounding = decideR::grounding_grounded(),
                       kind = "nitrogen_rate", action = 90, unit = "kg N/ha")
  expect_s7_class(gd, grain_decision)
  expect_true(grain_is_grounded(gd))
})

test_that("grain_plan validates its members and grounding", {
  expect_error(
    grain_plan(grounding = "bogus"),
    "canonical grounding token")
  expect_error(
    grain_plan(decisions = list("x"),
               grounding = decideR::grounding_grounded()),
    "must be a grain_decision")
})

test_that("grain_is_grounded reads the worst-case token", {
  grounded <- grain_decision(grounding = decideR::grounding_grounded(),
                             kind = "variety")
  unverified <- grain_decision(grounding = decideR::grounding_unverified(),
                               kind = "variety")
  expect_true(grain_is_grounded(grounded))
  expect_false(grain_is_grounded(unverified))
})

test_that("print methods emit without error and return invisibly", {
  rates <- seq(0, 150, by = 25)
  yld <- .fixture_yield_draws(rates, n = 600L)
  gd <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                           grounding = decideR::grounding_grounded())
  expect_output(print(gd), "grain_decision")
  expect_output(print(gd), "RECOMMENDED")
  plan <- plan_season(list(gd), crop = "wheat", season = "S1")
  expect_output(print(plan), "grain_plan")
  expect_invisible(print(plan))
})
