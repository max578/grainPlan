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

test_that("plan_variety(constraint = none-feasible) abstains via no_feasible_action", {
  merit <- .fixture_merit_draws(means = c(5.2, 5.8, 4.9, 5.3), sd = 0.2)
  gd <- plan_variety(merit, c("Scepter", "Vixen", "Calibre", "Denison"),
                     incumbent = "Scepter",
                     grounding = decideR::grounding_grounded(),
                     constraint = function(action) FALSE)
  expect_true(gd@abstained)
  expect_equal(gd@decision@abstain_reason, "no_feasible_action")
  expect_equal(gd@action, "Scepter")
  expect_match(gd@rationale, "no variety is feasible")
})

test_that("the decide() shim computes the correct expected merit (independent check)", {
  # F2 guard: grainPlan feeds a pre-built utility matrix through decideR::decide()
  # with `draws` used for length only. This independently recomputes the
  # downside-aware merit from first principles and asserts the candidate ledger's
  # expected utilities match, so a future decideR change that read `draws` values
  # would break this test rather than silently mis-decide in the field.
  set.seed(21L)
  merit <- cbind(A = stats::rnorm(3000L, 5.0, 0.4),
                 B = stats::rnorm(3000L, 5.3, 0.4))
  ra <- 0.5
  centres <- colMeans(merit)
  u <- vapply(seq_len(ncol(merit)),
              function(j) merit[, j] - ra * pmax(centres[j] - merit[, j], 0),
              numeric(nrow(merit)))
  expected <- colMeans(u)

  gd <- plan_variety(merit, risk_aversion = ra, decisive_prob = 0.2,
                     grounding = decideR::grounding_grounded())
  led <- gd@decision@candidates
  expect_equal(led$expected_utility[order(led$action)], unname(expected),
               tolerance = 1e-9)
})

# -- F1: point-GEBV uncertainty is resolved from the manifest, never fabricated --

test_that("point GEBVs use the manifest PEV when the caller supplies no gebv_sd", {
  gebv <- c(g1 = 0.2, g2 = 1.1, g3 = -0.3, g4 = 0.5)
  m <- .mini_manifest(
    outputs  = list(gebv = gebv, pev = c(0.04, 0.04, 0.04, 0.04)),
    metadata = list(grounding = decideR::grounding_grounded()))
  set.seed(3L)
  gd <- plan_variety_from_manifest(m, risk_aversion = 0.5)
  expect_equal(gd@action, "g2")
  expect_equal(gd@context$gebv_sd_source, "manifest_pev")
  expect_true(isTRUE(gd@context$reconstructed_posterior))
})

test_that("point GEBVs use a manifest reliability plus genetic variance", {
  gebv <- c(g1 = 0.2, g2 = 1.1, g3 = -0.3, g4 = 0.5)
  m <- .mini_manifest(
    outputs  = list(gebv = gebv, reliability = c(0.9, 0.9, 0.9, 0.9)),
    metadata = list(grounding = decideR::grounding_grounded(),
                    genetic_var = 0.16))
  set.seed(3L)
  gd <- plan_variety_from_manifest(m, risk_aversion = 0.5)
  expect_equal(gd@context$gebv_sd_source, "manifest_reliability")
  expect_false(gd@abstained)
})

test_that("point GEBVs with no uncertainty and no caller gebv_sd is an error", {
  gebv <- c(g1 = 0.2, g2 = 1.1, g3 = -0.3, g4 = 0.5)
  m <- .fixture_gebv_manifest(gebv, decideR::grounding_grounded())
  expect_error(plan_variety_from_manifest(m, risk_aversion = 0.5),
               "will not fabricate")
})

test_that("an explicit caller gebv_sd is recorded as the source and wins", {
  gebv <- c(g1 = 0.2, g2 = 1.1, g3 = -0.3, g4 = 0.5)
  m <- .mini_manifest(
    outputs  = list(gebv = gebv, pev = c(0.04, 0.04, 0.04, 0.04)),
    metadata = list(grounding = decideR::grounding_grounded()))
  set.seed(3L)
  gd <- plan_variety_from_manifest(m, risk_aversion = 0.5, gebv_sd = 0.2)
  expect_equal(gd@context$gebv_sd_source, "caller")
})

test_that("the reconstruction SD scale drives decide-vs-abstain (no hidden default)", {
  # Two caller SDs straddling the decisiveness threshold flip the decision: a
  # tight posterior decides the leading genotype, a broad one abstains to the
  # incumbent. This is exactly the dependence F1 makes explicit instead of hiding
  # behind gebv_sd = 1.
  gebv <- c(g1 = 0, g2 = 0.6)
  m <- .fixture_gebv_manifest(gebv, decideR::grounding_grounded())

  set.seed(101L)
  tight <- plan_variety_from_manifest(m, risk_aversion = 0, incumbent = "g1",
                                      gebv_sd = 0.1, n_draws = 4000L,
                                      decisive_prob = 0.6)
  set.seed(101L)
  broad <- plan_variety_from_manifest(m, risk_aversion = 0, incumbent = "g1",
                                      gebv_sd = 3.0, n_draws = 4000L,
                                      decisive_prob = 0.6)
  expect_false(tight@abstained)
  expect_equal(tight@action, "g2")
  expect_true(broad@abstained)
  expect_equal(broad@action, "g1")
})

test_that("a manifest with no grounding token anywhere reads as unverified", {
  # F3 guard: exercise the grounding-token reader's honest fallback directly.
  gebv <- c(g1 = 0.2, g2 = 1.1)
  m <- .mini_manifest(outputs = list(gebv = gebv))   # no grounding set
  gd <- plan_variety_from_manifest(m, gebv_sd = 0.2)
  expect_false(grain_is_grounded(gd))
})

test_that("the genomic manifest tail abstains when the producer itself declared an abstention (GP-03)", {
  # Contract v1.1's typed abstain state (`summary$abstained`) must force
  # abstention even when the grounding token alone reads "grounded" -- before
  # the fix, `.manifest_grounding_token()` never consulted it and this
  # manifest was priced as a confident switch to "g2".
  gebv <- c(g1 = 0.2, g2 = 1.1, g3 = -0.3, g4 = 0.5)
  m <- .fixture_gebv_manifest(gebv, decideR::grounding_grounded(),
                              summary = list(abstained = TRUE))
  gd <- plan_variety_from_manifest(m, risk_aversion = 0.5, gebv_sd = 0.2,
                                   incumbent = "g1")
  expect_true(gd@abstained)
  expect_equal(gd@action, "g1")
  expect_equal(gd@decision@abstain_reason, "producer_abstained")
})

test_that("the genomic manifest tail abstains on the wrong inferential_target (GP-04)", {
  # A manifest whose declared inferential_target is not "breeding_values"
  # must not be priced as a GEBV posterior at all -- before the fix there was
  # no check, and reading a mismatched payload risked either a confident wrong
  # answer or an opaque payload error.
  gebv <- c(g1 = 0.2, g2 = 1.1, g3 = -0.3, g4 = 0.5)
  m <- .fixture_gebv_manifest(gebv, decideR::grounding_grounded())
  m@metadata$inferential_target <- "predictions"
  gd <- plan_variety_from_manifest(m, risk_aversion = 0.5, gebv_sd = 0.2,
                                   incumbent = "g1")
  expect_true(gd@abstained)
  expect_equal(gd@action, "g1")
  expect_equal(gd@decision@abstain_reason, "wrong_inferential_target")
})

test_that("a manifest declaring breeding_values still decides (GP-04, negative)", {
  gebv <- c(g1 = 0.2, g2 = 1.1, g3 = -0.3, g4 = 0.5)
  m <- .fixture_gebv_manifest(gebv, decideR::grounding_grounded())
  m@metadata$inferential_target <- "breeding_values"
  set.seed(3L)
  gd <- plan_variety_from_manifest(m, risk_aversion = 0.5, gebv_sd = 0.2)
  expect_false(gd@abstained)
  expect_equal(gd@action, "g2")
})
