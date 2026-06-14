# Shared fixtures for grainPlan tests. A diminishing-returns yield-draws matrix
# (a saturating nitrogen response with posterior noise), a variety merit matrix,
# and a minimal S7 manifest-shaped object carrying yield draws or GEBVs and a
# grounding token. decideR's manifest tail reads a manifest by S7 property
# access (it requires a real S7 object, not a plain list), so the fixtures
# define a tiny S7 class exposing the contract's `outputs` / `metadata` /
# `run_id` / `emitter_package` properties -- duck-typed, no dependency on the
# real contract package. Kept here so each test reads as its assertion, not its
# setup.

.fixture_yield_draws <- function(rates = seq(0, 200, by = 25), n = 1200L,
                                 ymax_mean = 5.5, seed = 1L) {
  set.seed(seed)
  ymax <- stats::rnorm(n, ymax_mean, 0.3)
  vapply(rates, function(r) 3 + (ymax - 3) * (1 - exp(-r / 80)), numeric(n))
}

.fixture_merit_draws <- function(means = c(5.2, 5.4, 4.9, 5.3), n = 1000L,
                                 sd = 0.25, seed = 1L) {
  set.seed(seed)
  vapply(means, function(m) stats::rnorm(n, m, sd), numeric(n))
}

# A minimal S7 manifest-shaped class. It exposes exactly the properties
# decideR's duck-typed tail and grainPlan's variety tail read -- `outputs`,
# `metadata`, `run_id`, `emitter_package` -- and nothing else, so a test proves
# the tail reads any conforming S7 object by its public contract.
.mini_manifest <- S7::new_class(
  "mini_manifest",
  properties = list(
    outputs         = S7::new_property(S7::class_any, default = NULL),
    metadata        = S7::new_property(S7::class_list, default = list()),
    run_id          = S7::new_property(S7::class_character, default = "run-1"),
    emitter_package = S7::new_property(S7::class_character, default = "test")))

.fixture_yield_manifest <- function(yield_draws, grounding) {
  .mini_manifest(outputs = yield_draws,
                 metadata = list(grounding = grounding))
}

.fixture_gebv_manifest <- function(gebv, grounding) {
  .mini_manifest(outputs = list(gebv = gebv),
                 metadata = list(grounding = grounding))
}
