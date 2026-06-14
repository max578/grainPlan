# The orchestrator: plan_season composes grain decisions, combining their
# grounding worst-case so a plan resting on any unverified decision abstains as
# a whole -- the IOP firewall at the plan level.

.two_grounded_decisions <- function() {
  rates <- seq(0, 150, by = 25)
  yld <- .fixture_yield_draws(rates, n = 800L)
  n_dec <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                              crop = "wheat",
                              grounding = decideR::grounding_grounded())
  merit <- .fixture_merit_draws(means = c(5.2, 5.8, 4.9), sd = 0.2)
  v_dec <- plan_variety(merit, c("Scepter", "Vixen", "Calibre"), crop = "wheat",
                        grounding = decideR::grounding_grounded())
  list(n_dec = n_dec, v_dec = v_dec)
}

test_that("a plan of grounded decisions is grounded and not abstaining", {
  d <- .two_grounded_decisions()
  plan <- plan_season(list(d$v_dec, d$n_dec), crop = "wheat",
                      season = "2026 paddock 7")
  expect_s7_class(plan, grain_plan)
  expect_equal(length(plan@decisions), 2L)
  expect_true(grain_is_grounded(plan))
  expect_false(plan@partial_abstention)
  expect_equal(plan@crop, "wheat")
})

test_that("one unverified decision taints the whole plan (worst-case)", {
  d <- .two_grounded_decisions()
  rates <- seq(0, 150, by = 25)
  yld <- .fixture_yield_draws(rates, n = 800L)
  # an unverified nitrogen decision -> abstained -> taints the plan grounding
  bad <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
                            grounding = decideR::grounding_unverified())
  plan <- plan_season(list(d$v_dec, bad), crop = "wheat")
  expect_false(grain_is_grounded(plan))            # worst-case combination
  expect_true(plan@partial_abstention)             # one decision abstained
  expect_equal(as.character(plan@grounding),
               decideR::grounding_unverified())
})

test_that("plan_season defaults the crop to the first decision", {
  d <- .two_grounded_decisions()
  plan <- plan_season(list(d$n_dec))
  expect_equal(plan@crop, "wheat")
})

test_that("grain_plan_table flattens a plan with provenance attributes", {
  d <- .two_grounded_decisions()
  plan <- plan_season(list(d$v_dec, d$n_dec), crop = "wheat")
  tbl <- grain_plan_table(plan)
  expect_s3_class(tbl, "data.frame")
  expect_equal(nrow(tbl), 2L)
  expect_named(tbl, c("kind", "action", "unit", "abstained", "grounding"))
  expect_equal(attr(tbl, "plan_grounding"), decideR::grounding_grounded())
  expect_false(attr(tbl, "partial_abstention"))
})

test_that("plan_season validates its inputs", {
  expect_error(plan_season(list()), "at least one")
  expect_error(plan_season(list("not a decision")), "must be a grain_decision")
  expect_error(plan_season("nope"), "must be a list")
})

test_that("grain_is_grounded rejects a non-grain object", {
  expect_error(grain_is_grounded(42), "grain_decision or grain_plan")
})
