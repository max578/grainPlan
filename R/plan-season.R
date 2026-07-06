# =============================================================================
# The orchestrator: a season plan
# =============================================================================
# The "orchestrator" the package name promises: compose several grain decisions
# into one provenance-carrying season plan. The composition is deliberately
# simple and honest -- an ordered container that combines the decisions'
# grounding worst-case (via decideR::combine_grounding) so the plan inherits the
# weakest provenance among its parts, and flags partial abstention so a report
# never reads a confident headline over a plan with a declined component. There
# is no clever cross-decision optimisation in v0.1: a season plan is the sum of
# its grounded decisions, and its integrity is the firewall applied at the plan
# level. That keeps the v0.1 orchestrator a clean, auditable container, which is
# what a first release of a consequential grain tool should be.

#' Compose grain decisions into a season plan
#'
#' Gather an ordered list of [grain_decision] objects into one [grain_plan] -- a
#' single provenance-carrying recommendation for a season or field. The plan's
#' grounding is the worst case across its decisions (via
#' `decideR::combine_grounding()`), so a plan that rests on any unverified
#' decision is itself unverified: the Independent Oracle Principle applied one
#' level up. The plan is flagged `partial_abstention` when at least one decision
#' abstained, which a grower-facing report surfaces so a confident headline is
#' never read over a plan with a declined component.
#'
#' The decisions are stored in the order given -- the order they apply through
#' the season (variety choice at sowing, then a nitrogen rate, then an in-season
#' grade-target top-up, say). v0.1 composes by sequencing and worst-case
#' grounding only; it does not re-optimise across decisions (a deliberately
#' simple, auditable first orchestrator).
#'
#' @param decisions A list of [grain_decision] objects, in the order they apply.
#' @param crop The crop the plan concerns; defaults to the crop of the first
#'   decision.
#' @param season A short label for the season or field (default `"season"`).
#' @param metadata A named list of free-form plan metadata.
#' @return A [grain_plan] object.
#' @examples
#' set.seed(1L)
#' rates <- seq(0, 150, by = 25)
#' ymax  <- rnorm(800L, 5.5, 0.3)
#' yld   <- vapply(rates, function(r) 3 + (ymax - 3) * (1 - exp(-r / 70)),
#'                 numeric(800L))
#' n_dec <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
#'                             crop = "wheat",
#'                             grounding = decideR::grounding_grounded())
#' varieties <- c("Scepter", "Vixen", "Calibre")
#' merit <- vapply(c(5.2, 5.4, 4.9), function(m) rnorm(800L, m, 0.25),
#'                 numeric(800L))
#' v_dec <- plan_variety(merit, varieties, crop = "wheat",
#'                       grounding = decideR::grounding_grounded())
#' plan_season(list(v_dec, n_dec), crop = "wheat", season = "2026 paddock 7")
#' @seealso [grain_plan] for the returned object; the `plan_*()` verbs that
#'   build the decisions.
#' @family grain-objects
#' @export
plan_season <- function(decisions, crop = NULL, season = "season",
                        metadata = list()) {
  .check_decision_list(decisions)
  if (length(decisions) == 0L) {
    stop("`decisions` must hold at least one grain_decision", call. = FALSE)
  }
  if (is.null(crop)) {
    crop <- decisions[[1L]]@crop
  }

  # Worst-case grounding: the plan is grounded only if every decision is. Read
  # each decision's own grounding token and combine through decideR's canonical
  # rule, so the plan never claims a stronger provenance than its weakest part.
  tokens <- vapply(decisions, function(d) as.character(d@grounding),
                   character(1L))
  grounding <- decideR::combine_grounding(tokens)
  partial <- any(vapply(decisions, function(d) isTRUE(d@abstained),
                        logical(1L)))

  grain_plan(
    decisions          = decisions,
    crop               = crop,
    season             = season,
    grounding          = grounding,
    partial_abstention = partial,
    metadata           = metadata)
}

# -----------------------------------------------------------------------------
# Internal: decision-list validation
# -----------------------------------------------------------------------------

# Validate that every element of the supplied list is a grain_decision, the
# single precondition plan_season relies on. Named so plan_season's body reads
# as its intent (r_style invariant 9).
#
# @noRd
.check_decision_list <- function(decisions) {
  if (!is.list(decisions)) {
    stop("`decisions` must be a list of grain_decision objects", call. = FALSE)
  }
  ok <- vapply(decisions, function(d) S7::S7_inherits(d, grain_decision),
               logical(1L))
  if (length(ok) > 0L && !all(ok)) {
    stop("every element of `decisions` must be a grain_decision", call. = FALSE)
  }
  invisible(TRUE)
}

# -----------------------------------------------------------------------------
# Plan reporting
# -----------------------------------------------------------------------------

#' Summarise a grain plan as a data frame
#'
#' Flatten a [grain_plan] into a one-row-per-decision `data.frame` for a report
#' or a console table: the decision kind, the recommended action and its unit,
#' whether it abstained, and its grounding token. The plan's worst-case
#' grounding and partial-abstention flag are carried as attributes so a report
#' header can read them without re-deriving them.
#'
#' @param plan A [grain_plan].
#' @return A `data.frame` with one row per decision and columns `kind`,
#'   `action`, `unit`, `abstained`, `grounding`, plus the attributes
#'   `plan_grounding` and `partial_abstention`.
#' @examples
#' set.seed(1L)
#' rates <- seq(0, 150, by = 25)
#' ymax  <- rnorm(800L, 5.5, 0.3)
#' yld   <- vapply(rates, function(r) 3 + (ymax - 3) * (1 - exp(-r / 70)),
#'                 numeric(800L))
#' n_dec <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
#'                             crop = "wheat",
#'                             grounding = decideR::grounding_grounded())
#' grain_plan_table(plan_season(list(n_dec), crop = "wheat"))
#' @seealso [plan_season()] for the plan; [grain_plan] for the object.
#' @family grain-objects
#' @export
grain_plan_table <- function(plan) {
  if (!S7::S7_inherits(plan, grain_plan)) {
    stop("`plan` must be a grain_plan object", call. = FALSE)
  }
  rows <- lapply(plan@decisions, function(d) {
    data.frame(
      kind      = d@kind,
      action    = format(d@action),
      unit      = d@unit,
      abstained = isTRUE(d@abstained),
      grounding = as.character(d@grounding),
      stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  if (is.null(out)) {
    out <- data.frame(kind = character(0L), action = character(0L),
                      unit = character(0L), abstained = logical(0L),
                      grounding = character(0L), stringsAsFactors = FALSE)
  }
  attr(out, "plan_grounding") <- as.character(plan@grounding)
  attr(out, "partial_abstention") <- isTRUE(plan@partial_abstention)
  out
}
