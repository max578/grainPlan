# =============================================================================
# Grain decision: nitrogen rate
# =============================================================================
# The canonical grain decision -- how much nitrogen to apply -- expressed as a
# grain-semantics wrapper over decideR's profit-priced rate decision. The work
# decideR already does (expected-profit maximisation over a rate grid, the
# grounding firewall, abstention to the status-quo rate when the evidence is
# un-grounded or indecisive) is reused whole; grainPlan adds the grain meaning:
# the crop, the economics object, the grower-facing rationale, and the
# `grain_decision` wrapper. Two entry shapes are supported -- a caller-assembled
# yield-draws matrix, and an upstream `orchestra_manifest` -- both routed to the
# same decideR engine so the firewall behaves identically on either.

# -----------------------------------------------------------------------------
# Internal: decision-to-grain wrapper
# -----------------------------------------------------------------------------

# Lift a decideR `decision` into a grain_decision, copying the grounding token
# straight off the wrapped decision (never recomputing it) and composing the
# grower-facing rationale from the decision's own abstention record. Shared by
# the matrix and manifest entry points so both produce an identical wrapper.
.wrap_rate_decision <- function(d, crop, rates, economics, context) {
  grounding <- .decision_grounding(d)
  if (isTRUE(d@abstained)) {
    rationale <- .abstain_rationale(
      d@abstain_reason, lead = "Held at the status-quo rate",
      evidence = "the yield evidence", subject = "rate", act = "act on it")
  } else {
    rationale <- sprintf(
      paste0("Apply %g %s to the %s crop: it maximises expected profit ",
             "($%s/unit area) and clearly beats the status quo on the ",
             "posterior."),
      d@action, "kg N/ha", crop, format(d@expected_utility, digits = 5L))
  }
  grain_decision(
    decision  = d,
    crop      = crop,
    kind      = "nitrogen_rate",
    action    = d@action,
    unit      = "kg N/ha",
    abstained = isTRUE(d@abstained),
    grounding = grounding,
    rationale = rationale,
    context   = context)
}

# -----------------------------------------------------------------------------
# Decision verbs
# -----------------------------------------------------------------------------

#' Plan a nitrogen rate for a grain crop
#'
#' The canonical grain decision: choose how much nitrogen to apply to a crop by
#' expected profit, abstaining to the status-quo rate when the yield evidence is
#' unverified or no rate is clearly better. It is a grain-semantics wrapper over
#' `decideR::decide_input_rate()` -- the profit maximisation, the grounding
#' firewall, and the abstention logic are decideR's; grainPlan supplies the
#' grain economics ([n_rate_economics()]), the crop context, a grower-facing
#' rationale, and the [grain_decision] result.
#'
#' Pass either a yield-draws matrix (`yield_draws`, one column per candidate
#' rate, rows are posterior draws -- the object a PESTO inversion or a TACI
#' yield-response posterior produces) together with `rates`, or an upstream
#' `orchestra_manifest` to [plan_nitrogen_rate_from_manifest()], which sources
#' the draws and the grounding token straight from the manifest. Either way the
#' grounding rides from the evidence through the decision: an unverified yield
#' posterior forces the status-quo rate, never a confident wrong recommendation.
#'
#' @param yield_draws A numeric matrix of posterior yield draws, one column per
#'   candidate rate (rows are draws).
#' @param rates A numeric vector of candidate nitrogen rates, one per column of
#'   `yield_draws`.
#' @param price_grain The grain price per unit yield (passed to
#'   [n_rate_economics()]).
#' @param price_n The nitrogen price per unit rate (passed to
#'   [n_rate_economics()]).
#' @param crop The crop the decision concerns (default `"wheat"`).
#' @param grounding One or more grounding tokens for the yield evidence;
#'   combined worst-case and passed to the decision engine.
#' @param safe_rate The fallback rate on abstention (default `0`, the no-input
#'   status quo).
#' @param decisive_prob Minimum posterior probability that the leading rate
#'   beats the status quo (passed to `decideR::decide()`).
#' @param ... Further arguments passed to the decision core (e.g. `min_ess`).
#'   `constraint` is rejected with an error: `decideR::decide_input_rate()`
#'   does not honour a rate constraint and would otherwise drop it silently
#'   (use [plan_nitrogen_rate_from_manifest()], which does honour one, or cap
#'   `rates` before calling).
#' @return A [grain_decision] of kind `"nitrogen_rate"` whose `action` is the
#'   recommended rate.
#' @examples
#' set.seed(1L)
#' rates <- seq(0, 200, by = 25)
#' # diminishing-returns yield response with posterior noise
#' mu <- 3 + 2.5 * (1 - exp(-rates / 80))
#' yield_draws <- vapply(mu, function(m) rnorm(1500L, m, 0.3), numeric(1500L))
#' plan_nitrogen_rate(yield_draws, rates, price_grain = 350, price_n = 1.3,
#'                    crop = "wheat",
#'                    grounding = decideR::grounding_grounded())
#' @seealso [plan_nitrogen_rate_from_manifest()] for the manifest entry point;
#'   [n_rate_economics()] for the economics; [decideR::decide_input_rate()] for
#'   the underlying engine.
#' @family grain-decisions
#' @export
plan_nitrogen_rate <- function(yield_draws, rates, price_grain, price_n,
                               crop = "wheat",
                               grounding = decideR::grounding_unverified(),
                               safe_rate = 0, decisive_prob = 0.6, ...) {
  if (!is.matrix(yield_draws) || ncol(yield_draws) != length(rates)) {
    stop("`yield_draws` must be a matrix with one column per rate",
         call. = FALSE)
  }
  # `decideR::decide_input_rate()` hardcodes `constraint = NULL` and, of `...`,
  # honours only `min_ess`/`ess` -- anything else, `constraint` included, is
  # silently dropped by R's own `...` forwarding, not by any check of theirs or
  # ours. A caller passing a constraint here would see it vanish with no
  # warning (it *is* honoured on the manifest entry point, which routes
  # through a different decideR tail), so grainPlan owes the loud error itself.
  dots <- list(...)
  if ("constraint" %in% names(dots)) {
    stop(paste0(
      "`constraint` is not supported by `plan_nitrogen_rate()` -- ",
      "`decideR::decide_input_rate()` does not accept a constraint and would ",
      "silently ignore it. Use `plan_nitrogen_rate_from_manifest()` (which ",
      "honours `constraint`), or cap `rates` to the feasible set before ",
      "calling `plan_nitrogen_rate()`."), call. = FALSE)
  }
  econ <- n_rate_economics(price_grain = price_grain, price_n = price_n)

  d <- decideR::decide_input_rate(
    yield_draws = yield_draws, rates = rates,
    price_grain = econ$price_grain, price_input = econ$price_n,
    grounding = grounding, safe_rate = safe_rate,
    decisive_prob = decisive_prob, ...)

  context <- list(rates = rates, economics = econ,
                  evidence = "yield_draws matrix")
  .wrap_rate_decision(d, crop = crop, rates = rates, economics = econ,
                      context = context)
}

#' Plan a nitrogen rate from an upstream orchestra manifest
#'
#' The manifest entry point to the nitrogen-rate decision: source the yield
#' draws and the producer's grounding token straight from an
#' `orchestra_manifest` emitted upstream (a PESTO inversion, a TACI
#' yield-response posterior), price them, and return a [grain_decision]. It is
#' the formalised crop-pipeline tail at the grain layer -- a yield posterior in,
#' a profit-priced, grounding-aware nitrogen-rate plan out -- built directly on
#' `decideR::decide_rate_from_manifest()`, which reads the manifest by its
#' public contract (the draws matrix and the grounding token) without grainPlan
#' depending on the contract package.
#'
#' The grounding rides from the producer through the decision: an unverified
#' yield manifest forces the status-quo rate. grainPlan takes no dependency on
#' the manifest constructor; the manifest is read by decideR's duck-typed tail.
#' A caller who has independently grounded (or wants to force `[unverified]` on)
#' a manifest can override the producer's token through `grounding`, matching
#' [plan_variety_from_manifest()].
#'
#' @param manifest An `orchestra_manifest` carrying a yield-per-rate draws
#'   matrix (in `outputs` or `metadata$yield_draws`), one column per rate.
#' @param rates A numeric vector of candidate nitrogen rates, one per column of
#'   the manifest's draws matrix.
#' @param price_grain The grain price per unit yield.
#' @param price_n The nitrogen price per unit rate.
#' @param crop The crop the decision concerns (default `"wheat"`).
#' @param grounding Optional override for the manifest's own grounding token;
#'   `NULL` (default) uses the token the manifest carries, read worst-case.
#' @param safe_rate The fallback rate on abstention (default `0`).
#' @param decisive_prob Minimum posterior probability that the leading rate
#'   beats the status quo.
#' @param ... Further arguments passed to the decision core (e.g. `min_ess`,
#'   `draws_key`).
#' @return A [grain_decision] of kind `"nitrogen_rate"` whose `action` is the
#'   recommended rate. Held at `safe_rate`, unpriced, when the manifest's own
#'   producer declared an abstention (`summary$abstained`), or when it declares
#'   an `inferential_target` other than `"predictions"` or `"parameters"`.
#' @examples
#' \dontrun{
#' # `manifest` is an orchestra_manifest S7 object emitted upstream (a PESTO
#' # inversion or a TACI yield-response posterior), carrying a yield-per-rate
#' # draws matrix in its `outputs` slot (or `metadata$yield_draws`) and a
#' # grounding token in `metadata$grounding`. decideR's tail reads it by its
#' # public S7 contract, so grainPlan needs no dependency on the contract package.
#' rates <- seq(0, 200, by = 25)
#' plan_nitrogen_rate_from_manifest(manifest, rates,
#'                                  price_grain = 350, price_n = 1.3)
#' }
#' @seealso [plan_nitrogen_rate()] for the caller-assembled-matrix form;
#'   [decideR::decide_rate_from_manifest()] for the underlying tail.
#' @family grain-decisions
#' @export
plan_nitrogen_rate_from_manifest <- function(manifest, rates, price_grain,
                                             price_n, crop = "wheat",
                                             grounding = NULL, safe_rate = 0,
                                             decisive_prob = 0.6, ...) {
  econ <- n_rate_economics(price_grain = price_grain, price_n = price_n)

  # Contract checks first (GP-03, GP-04): a producer's own typed abstention, or
  # a declared `inferential_target` this verb does not price, forces the
  # status-quo rate before any draws are read -- decideR's tail reads neither
  # of these off the manifest, so grainPlan owes the check itself.
  violation <- .manifest_contract_violation(
    manifest, accepted_targets = c("predictions", "parameters"))
  if (!is.null(violation)) {
    d <- .manifest_contract_refusal(
      violation, safe_action = safe_rate,
      safe_label = sprintf("rate=%g (status quo)", safe_rate),
      method = "expected_profit", manifest = manifest)
  } else {
    # `grounding = NULL` lets decideR's tail read the manifest's own token; a
    # non-NULL override is forwarded verbatim, so the two manifest verbs share
    # the same override semantics.
    d <- decideR::decide_rate_from_manifest(
      manifest = manifest, rates = rates,
      price_grain = econ$price_grain, price_input = econ$price_n,
      grounding = grounding, safe_rate = safe_rate,
      decisive_prob = decisive_prob, ...)
  }

  context <- list(rates = rates, economics = econ,
                  evidence = "orchestra_manifest",
                  manifest_run_id = d@inputs$manifest_run_id,
                  emitter_package = d@inputs$emitter_package)
  .wrap_rate_decision(d, crop = crop, rates = rates, economics = econ,
                      context = context)
}
