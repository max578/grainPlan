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

test_that("print methods emit the expected lines and return invisibly", {
  rates <- seq(0, 150, by = 25)
  yld <- .fixture_yield_draws(rates, n = 600L)
  gd <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                           grounding = decideR::grounding_grounded())
  out <- capture.output(print(gd))
  expect_match(out[1], "<grain_decision> RECOMMENDED\\s+\\[grounded\\]")
  expect_true(any(grepl("kind\\s+: nitrogen_rate", out)))
  expect_true(any(grepl("action\\s+:", out)))
  expect_true(any(grepl("why\\s+:", out)))          # the rationale line prints
  expect_invisible(print(gd))

  # an abstaining decision prints its ABSTAINED status
  ab <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                           grounding = decideR::grounding_unverified())
  expect_output(print(ab), "ABSTAINED")

  plan <- plan_season(list(gd), crop = "wheat", season = "S1")
  out_p <- capture.output(print(plan))
  expect_match(out_p[1], "<grain_plan> S1 -- 1 decision\\s+\\[grounded\\]")
  expect_true(any(grepl("nitrogen_rate", out_p)))
  expect_invisible(print(plan))
})
