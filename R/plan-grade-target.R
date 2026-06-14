# =============================================================================
# Grain decision: grade target
# =============================================================================
# The quality-economics decision -- how hard to push a quality-driving input
# (nitrogen for protein, say) when the payoff is graded by a delivery standard
# rather than smooth in the outcome. This is the decision decideR's grade-band
# loss was built to serve, and the comment in decideR's loss-grade-band.R names
# grainPlan explicitly as its intended consumer. Here grainPlan supplies the
# grain semantics: the value schedule comes from grainPlan's value library
# ([wheat_protein_bands()] / [barley_malting_premium()]), the action shifts the
# quality outcome through a grower-meaningful response, and the result is a
# [grain_decision]. The engine, the threshold economics, and the firewall are
# decideR's.

#' Plan a grade target under a quality-band payoff
#'
#' Choose how hard to push a quality-driving input when the grain payoff steps
#' at a delivery-standard threshold (a wheat protein band, a barley malting
#' window) rather than rising smoothly. It is a grain-semantics wrapper over
#' `decideR::decide()` driven by a grade-band loss: the value schedule prices
#' each quality band, the utility is the band payoff of the shifted quality
#' outcome less the input cost, and the expected utility decideR averages over
#' the draws is governed by each band's posterior probability -- exactly the
#' threshold economics a quality-graded decision faces. It abstains to the
#' status-quo action when the quality evidence is unverified or no action is
#' clearly better.
#'
#' `quality_draws` is a numeric vector of posterior draws of the baseline
#' quality outcome (grain protein, say) under no extra input. `actions` is the
#' candidate input grid (a nitrogen-rate grid, say). `quality_shift(action,
#' quality)` returns the realised quality under an action -- the additive
#' default `quality + action` suits a unit that lifts quality one-for-one, and a
#' supplied function suits a saturating or partial response. `value` is a
#' grade-band schedule from grainPlan's value library (or any
#' `decideR::grade_band_value()`), and `cost` prices the input.
#'
#' @param quality_draws A numeric vector of posterior draws of the baseline
#'   quality outcome under the status-quo action.
#' @param actions A numeric vector of candidate input levels (the grid the
#'   decision chooses over).
#' @param value A `decideR::grade_band_value` schedule pricing the quality
#'   bands -- typically [wheat_protein_bands()] or [barley_malting_premium()].
#' @param quality_shift A function `function(action, quality)` returning the
#'   realised quality under the action, or `NULL` for the additive default
#'   `quality + action`.
#' @param cost A per-unit input cost (a single number applied as
#'   `cost * action`), a function `function(action)`, or `0` for no cost.
#' @param crop The crop the decision concerns (default `"wheat"`).
#' @param grounding One or more grounding tokens for the quality evidence;
#'   combined worst-case.
#' @param safe_action The action returned on abstention (default the first
#'   element of `actions`, the status quo).
#' @param decisive_prob Minimum posterior probability that the leading action
#'   beats the status quo (passed to `decideR::decide()`).
#' @param ... Further arguments passed to the decision core (e.g. `min_ess`).
#' @return A [grain_decision] of kind `"grade_target"` whose `action` is the
#'   recommended input level.
#' @examples
#' set.seed(1L)
#' # Baseline protein draws; a nitrogen top-up lifts protein additively.
#' protein <- rnorm(2000L, mean = 11.0, sd = 0.6)
#' v <- wheat_protein_bands()
#' plan_grade_target(protein, actions = seq(0, 60, by = 10), value = v,
#'                   quality_shift = function(rate, p) p + 0.02 * rate,
#'                   cost = 1.3, crop = "wheat",
#'                   grounding = decideR::grounding_grounded())
#' @seealso [wheat_protein_bands()] and [barley_malting_premium()] for the value
#'   schedules; [decideR::grade_band_utility()] for the loss; [decideR::decide()]
#'   for the engine.
#' @family grain-decisions
#' @export
plan_grade_target <- function(quality_draws, actions, value,
                              quality_shift = NULL, cost = 0, crop = "wheat",
                              grounding = decideR::grounding_unverified(),
                              safe_action = NULL, decisive_prob = 0.6, ...) {
  if (!is.numeric(quality_draws) || length(quality_draws) == 0L) {
    stop("`quality_draws` must be a non-empty numeric vector", call. = FALSE)
  }
  if (!is.numeric(actions) || length(actions) == 0L) {
    stop("`actions` must be a non-empty numeric vector", call. = FALSE)
  }
  if (!inherits(value, "grade_band_value")) {
    stop("`value` must be a decideR::grade_band_value() schedule -- e.g. ",
         "wheat_protein_bands() or barley_malting_premium()", call. = FALSE)
  }
  grounding <- decideR::combine_grounding(grounding)
  if (is.null(safe_action)) {
    safe_action <- actions[[1L]]
  }

  # Reuse decideR's grade-band utility builder whole: it turns the value
  # schedule + the quality response + the cost into the function decideR::decide
  # consumes. The threshold economics (expected utility governed by each band's
  # posterior probability) are decideR's, not re-implemented here.
  u <- decideR::grade_band_utility(value, quality_shift = quality_shift,
                                   cost = cost)

  d <- decideR::decide(
    draws       = quality_draws,
    utility     = u,
    candidates  = actions,
    labels      = sprintf("action=%g", actions),
    grounding   = grounding,
    safe_action = safe_action,
    safe_label  = sprintf("action=%g (status quo)", safe_action),
    decisive_prob = decisive_prob,
    method      = "grade_band_threshold_economics",
    inputs      = list(actions = actions, bands = attr(value, "labels")),
    metadata    = list(domain = "grain_quality"),
    ...)

  context <- list(actions = actions, value = value,
                  bands = attr(value, "labels"), evidence = "quality_draws")
  .wrap_grade_decision(d, crop = crop, context = context)
}

# Lift a decideR grade-target `decision` into a grain_decision, copying the
# grounding straight off the wrapped decision and composing a grower-facing
# rationale that names the threshold economics at work.
#
# @noRd
.wrap_grade_decision <- function(d, crop, context) {
  grounding <- .decision_grounding(d)
  if (isTRUE(d@abstained)) {
    rationale <- switch(
      d@abstain_reason,
      input_ungrounded = paste0(
        "Held at the status-quo input: the quality evidence is unverified, ",
        "so the firewall declines to chase a grade on it."),
      insufficient_evidence = paste0(
        "Held at the status-quo input: lifting the input does not clearly ",
        "improve the graded payoff on the posterior."),
      sprintf("Held at the status-quo input (%s).", d@abstain_reason))
  } else {
    rationale <- sprintf(
      paste0("Set the input to %g for the %s crop: it maximises the expected ",
             "graded payoff ($%s/t) by raising the posterior probability of ",
             "clearing a higher quality band, net of input cost."),
      d@action, crop, format(d@expected_utility, digits = 5L))
  }
  grain_decision(
    decision  = d,
    crop      = crop,
    kind      = "grade_target",
    action    = d@action,
    unit      = "input level",
    abstained = isTRUE(d@abstained),
    grounding = grounding,
    rationale = rationale,
    context   = context)
}
