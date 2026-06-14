# The variety verb: a downside-aware merit ranking that decides on grounded
# evidence and keeps the incumbent on unverified evidence; the genomic manifest
# entry point reads GEBVs (draws or points) off a breeding_values manifest.

test_that("a clearly best variety is recommended on grounded evidence", {
  # variety 2 has the highest mean and the same spread -> it must lead.
  merit <- .fixture_merit_draws(means = c(5.2, 5.8, 4.9, 5.3), sd = 0.2)
  varieties <- c("Scepter", "Vixen", "Calibre", "Denison")
  gd <- plan_variety(merit, varieties, risk_aversion = 0.5,
                     grounding = decideR::grounding_grounded())
  expect_equal(gd@kind, "variety")
  expect_equal(gd@unit, "variety")
  expect_false(gd@abstained)
  expect_true(grain_is_grounded(gd))
  expect_equal(gd@action, "Vixen")
})

test_that("unverified merit keeps the incumbent (firewall)", {
  merit <- .fixture_merit_draws(means = c(5.2, 5.8, 4.9, 5.3), sd = 0.2)
  varieties <- c("Scepter", "Vixen", "Calibre", "Denison")
  gd <- plan_variety(merit, varieties, incumbent = "Scepter",
                     grounding = decideR::grounding_unverified())
  expect_true(gd@abstained)
  expect_false(grain_is_grounded(gd))
  expect_equal(gd@action, "Scepter")             # the incumbent, kept
  expect_match(gd@rationale, "unverified")
})

test_that("risk aversion flips the expected-merit ranking", {
  # variety A: higher mean but a broad, volatile spread (a large one-sided
  # downside below its mean); variety B: slightly lower mean but tight. A keeps
  # the higher MEAN, so the risk-NEUTRAL expected-merit ranking leads with A;
  # under risk aversion the downside penalty drops A's expected merit below B's,
  # so the ranking leads with B. This isolates the loss mechanism: the leading
  # candidate in the decision ledger flips with the risk weight. (decideR's
  # per-draw decisiveness gate against the incumbent is a separate guard, tested
  # elsewhere; here a low `decisive_prob` lets the expectation-based ranking
  # stand so the loss mechanism is what is under test.)
  set.seed(7L)
  a <- stats::rnorm(2000L, 5.6, 1.4)             # high mean, volatile
  b <- stats::rnorm(2000L, 5.45, 0.12)           # steady
  merit <- cbind(A = a, B = b)
  stopifnot(mean(merit[, "A"]) > mean(merit[, "B"]))   # A leads on the mean

  lead <- function(gd) {
    led <- gd@decision@candidates
    as.character(gd@context$varieties[which.max(led$expected_utility)])
  }
  neutral <- plan_variety(merit, risk_aversion = 0, decisive_prob = 0.2,
                          grounding = decideR::grounding_grounded())
  averse <- plan_variety(merit, risk_aversion = 3, decisive_prob = 0.2,
                         grounding = decideR::grounding_grounded())
  expect_equal(lead(neutral), "A")               # higher mean leads when neutral
  expect_equal(lead(averse), "B")                # steady leads under aversion
  expect_equal(averse@action, "B")               # and is recommended
})

test_that("the genomic manifest tail decides from point GEBVs", {
  gebv <- c(g1 = 0.2, g2 = 1.1, g3 = -0.3, g4 = 0.5)
  m <- .fixture_gebv_manifest(gebv, decideR::grounding_grounded())
  set.seed(3L)
  gd <- plan_variety_from_manifest(m, risk_aversion = 0.5, gebv_sd = 0.2)
  expect_false(gd@abstained)
  expect_true(grain_is_grounded(gd))
  expect_equal(gd@action, "g2")                  # the top GEBV
  expect_true(isTRUE(gd@context$reconstructed_posterior))
})

test_that("the genomic manifest tail abstains on an unverified manifest", {
  gebv <- c(g1 = 0.2, g2 = 1.1, g3 = -0.3, g4 = 0.5)
  m <- .fixture_gebv_manifest(gebv, decideR::grounding_unverified())
  set.seed(3L)
  gd <- plan_variety_from_manifest(m, risk_aversion = 0.5, gebv_sd = 0.2,
                                   incumbent = "g1")
  expect_true(gd@abstained)
  expect_equal(gd@action, "g1")
})

test_that("the genomic manifest tail consumes a GEBV draws matrix", {
  set.seed(5L)
  draws <- cbind(g1 = stats::rnorm(500L, 0.2, 0.3),
                 g2 = stats::rnorm(500L, 1.0, 0.3))
  m <- .fixture_gebv_manifest(draws, decideR::grounding_grounded())
  gd <- plan_variety_from_manifest(m, risk_aversion = 0.5)
  expect_equal(gd@action, "g2")
  expect_false(isTRUE(gd@context$reconstructed_posterior))
})

test_that("plan_variety validates inputs", {
  expect_error(plan_variety(1:10), "non-empty numeric matrix")
  merit <- .fixture_merit_draws()
  expect_error(plan_variety(merit, varieties = c("a", "b")), "one name per")
  expect_error(plan_variety(merit, risk_aversion = -1), "non-negative")
  expect_error(plan_variety(merit, incumbent = "nope"),
               "not one of the candidate")
})
