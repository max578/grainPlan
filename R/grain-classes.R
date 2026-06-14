# =============================================================================
# The grain decision and grain plan objects
# =============================================================================
# grainPlan's two native result types sit one level above decideR's `decision`.
# A `grain_decision` wraps exactly one `decideR::decision` and the grain context
# that gives it meaning -- the crop, the decision kind (a nitrogen rate, a
# variety choice, a grade target), and the units the recommended action is
# expressed in. A `grain_plan` is an ordered season's worth of grain decisions
# carried together with a single grounding label combined worst-case across
# them, so a plan that rests on any unverified decision abstains as a whole.
#
# Both are S7 objects, matching the federation (masque, PESTO, kernR, proxymix,
# decideR are all S7). The grounding label is stored beside the numbers and
# never inferred from them -- the same Independent Oracle Principle discipline
# decideR's `decision` keeps. grainPlan does NOT re-implement grounding: it
# imports decideR's canonical tokens and worst-case combination, so the
# federation never drifts on the label.

#' A grain decision -- a recommended grain action with context and grounding
#'
#' The unit grainPlan recommends: exactly one `decideR::decision` wrapped with
#' the grain context that gives it agronomic meaning. Where a bare `decision`
#' records "action 90, expected utility 1840, grounded", a `grain_decision`
#' records "apply 90 kg/ha of nitrogen to this wheat crop, grounded, profit
#' $1840/ha" -- the same decision, read in grain terms.
#'
#' The object carries the wrapped `decision` whole (in `decision`) so nothing
#' decideR computed is lost, and lifts the fields a practitioner reads first to
#' the top: the `crop`, the decision `kind`, the recommended `action` and its
#' `unit`, whether the decision `abstained`, and the `grounding` token. The
#' grounding is copied from the wrapped decision, never recomputed, so a
#' `grain_decision` can never claim a stronger provenance than the decision it
#' wraps.
#'
#' @param decision The wrapped `decideR::decision` object.
#' @param crop The crop the decision concerns (e.g. `"wheat"`, `"barley"`,
#'   `"corn"`).
#' @param kind The decision kind, one of `"nitrogen_rate"`, `"variety"`, or
#'   `"grade_target"`.
#' @param action The recommended action, lifted from the wrapped decision (the
#'   `safe_action` when the decision abstained).
#' @param unit A short string naming the units of `action` (e.g. `"kg N/ha"`,
#'   `"variety"`, `"protein %"`).
#' @param abstained `TRUE` when the wrapped decision declined the
#'   utility-maximal action.
#' @param grounding A canonical grounding token, copied from the wrapped
#'   decision.
#' @param rationale A short human-readable sentence explaining the
#'   recommendation, suitable for a grower-facing report.
#' @param context A named list of free-form grain context (prices, the
#'   candidate set, the dataset attribution).
#' @return A `grain_decision` S7 object.
#' @examples
#' set.seed(1L)
#' rates <- seq(0, 150, by = 25)
#' ymax  <- rnorm(800L, 5.5, 0.3)
#' yld   <- vapply(rates, function(r) 3 + (ymax - 3) * (1 - exp(-r / 70)),
#'                 numeric(800L))
#' gd <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
#'                          crop = "wheat",
#'                          grounding = decideR::grounding_grounded())
#' gd@action
#' @seealso [grain_plan] for a season of decisions; [plan_nitrogen_rate()],
#'   [plan_variety()], and [plan_grade_target()] for the verbs that build it.
#' @family grain-objects
#' @export
grain_decision <- S7::new_class(
  "grain_decision",
  properties = list(
    decision  = S7::new_property(S7::class_any, default = NULL),
    crop      = S7::new_property(S7::class_character, default = NA_character_),
    kind      = S7::new_property(S7::class_character, default = NA_character_),
    action    = S7::new_property(S7::class_any, default = NULL),
    unit      = S7::new_property(S7::class_character, default = NA_character_),
    abstained = S7::new_property(S7::class_logical, default = FALSE),
    # Literal default rather than decideR::grounding_unverified() so the class
    # definition does not depend on decideR's load order; the validator pins it
    # to a canonical token.
    grounding = S7::new_property(S7::class_character, default = "[unverified]"),
    rationale = S7::new_property(S7::class_character, default = NA_character_),
    context   = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    canon <- c(decideR::grounding_grounded(), decideR::grounding_unverified())
    if (length(self@grounding) != 1L || !self@grounding %in% canon) {
      return("@grounding must be exactly one canonical grounding token")
    }
    if (length(self@abstained) != 1L || is.na(self@abstained)) {
      return("@abstained must be a single non-NA logical")
    }
    known_kinds <- c("nitrogen_rate", "variety", "grade_target")
    if (length(self@kind) != 1L || (!is.na(self@kind) &&
          !self@kind %in% known_kinds)) {
      return(sprintf("@kind must be one of %s",
                     paste(known_kinds, collapse = ", ")))
    }
    NULL
  }
)

#' A grain plan -- an ordered season of grain decisions with combined grounding
#'
#' The orchestrator's output: a sequence of [grain_decision] objects gathered
#' into one provenance-carrying season plan. The plan's `grounding` is the
#' worst case across its decisions (via `decideR::combine_grounding()`), so a
#' plan that rests on any unverified decision is itself `[unverified]` -- the
#' Independent Oracle Principle applied at the plan level. A plan is
#' `partial_abstention` when at least one of its decisions abstained, which a
#' report surfaces so a grower never reads a confident headline over a plan
#' with a declined component.
#'
#' @param decisions A list of [grain_decision] objects, in the order they apply
#'   through the season.
#' @param crop The crop the plan concerns.
#' @param season A short label for the season or field the plan covers.
#' @param grounding A canonical grounding token, combined worst-case across the
#'   decisions.
#' @param partial_abstention `TRUE` when at least one decision in the plan
#'   abstained.
#' @param metadata A named list of free-form plan metadata.
#' @return A `grain_plan` S7 object.
#' @examples
#' set.seed(1L)
#' rates <- seq(0, 150, by = 25)
#' ymax  <- rnorm(800L, 5.5, 0.3)
#' yld   <- vapply(rates, function(r) 3 + (ymax - 3) * (1 - exp(-r / 70)),
#'                 numeric(800L))
#' n_dec <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
#'                             crop = "wheat",
#'                             grounding = decideR::grounding_grounded())
#' plan_season(list(n_dec), crop = "wheat", season = "2026 paddock 7")
#' @seealso [plan_season()] for the constructor; [grain_decision] for the unit.
#' @family grain-objects
#' @export
grain_plan <- S7::new_class(
  "grain_plan",
  properties = list(
    decisions          = S7::new_property(S7::class_list, default = list()),
    crop               = S7::new_property(S7::class_character,
                                          default = NA_character_),
    season             = S7::new_property(S7::class_character,
                                          default = NA_character_),
    grounding          = S7::new_property(S7::class_character,
                                          default = "[unverified]"),
    partial_abstention = S7::new_property(S7::class_logical, default = FALSE),
    metadata           = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    canon <- c(decideR::grounding_grounded(), decideR::grounding_unverified())
    if (length(self@grounding) != 1L || !self@grounding %in% canon) {
      return("@grounding must be exactly one canonical grounding token")
    }
    if (length(self@partial_abstention) != 1L ||
          is.na(self@partial_abstention)) {
      return("@partial_abstention must be a single non-NA logical")
    }
    ok_members <- vapply(self@decisions,
                         function(d) S7::S7_inherits(d, grain_decision),
                         logical(1L))
    if (length(ok_members) > 0L && !all(ok_members)) {
      return("every element of @decisions must be a grain_decision")
    }
    NULL
  }
)

# -----------------------------------------------------------------------------
# Predicates
# -----------------------------------------------------------------------------

#' Is a grain decision or plan grounded?
#'
#' A convenience predicate reading the grounding label of a [grain_decision] or
#' [grain_plan]. A grower-facing report, or a downstream automation that must
#' refuse to act on unverified evidence, gates on this. It mirrors
#' `decideR::is_grounded()` one level up, reading the grain object's own
#' worst-case grounding token.
#'
#' @param x A [grain_decision] or [grain_plan].
#' @return `TRUE` when the object's grounding is `decideR::grounding_grounded()`.
#' @examples
#' set.seed(1L)
#' rates <- seq(0, 150, by = 25)
#' ymax  <- rnorm(800L, 5.5, 0.3)
#' yld   <- vapply(rates, function(r) 3 + (ymax - 3) * (1 - exp(-r / 70)),
#'                 numeric(800L))
#' gd <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
#'                          crop = "wheat",
#'                          grounding = decideR::grounding_grounded())
#' grain_is_grounded(gd)
#' @family grain-objects
#' @export
grain_is_grounded <- function(x) {
  if (S7::S7_inherits(x, grain_decision) || S7::S7_inherits(x, grain_plan)) {
    return(identical(as.character(x@grounding),
                     decideR::grounding_grounded()))
  }
  stop("`x` must be a grain_decision or grain_plan object", call. = FALSE)
}

# -----------------------------------------------------------------------------
# Printing
# -----------------------------------------------------------------------------

#' Print a grain decision
#'
#' @param x A [grain_decision].
#' @param ... Ignored, for compatibility with [print()].
#' @return `x`, invisibly.
#' @examples
#' set.seed(1L)
#' rates <- seq(0, 150, by = 25)
#' ymax  <- rnorm(800L, 5.5, 0.3)
#' yld   <- vapply(rates, function(r) 3 + (ymax - 3) * (1 - exp(-r / 70)),
#'                 numeric(800L))
#' print(plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
#'                          crop = "wheat",
#'                          grounding = decideR::grounding_grounded()))
#' @name print.grain_decision
S7::method(print, grain_decision) <- function(x, ...) {
  status <- if (isTRUE(x@abstained)) "ABSTAINED" else "RECOMMENDED"
  cat(sprintf("<grain_decision> %s  [%s]\n", status, x@grounding))
  cat(sprintf("  crop   : %s\n", x@crop))
  cat(sprintf("  kind   : %s\n", x@kind))
  cat(sprintf("  action : %s %s\n", format(x@action), x@unit))
  if (!is.na(x@rationale)) {
    cat(sprintf("  why    : %s\n", x@rationale))
  }
  invisible(x)
}

#' Print a grain plan
#'
#' @param x A [grain_plan].
#' @param ... Ignored, for compatibility with [print()].
#' @return `x`, invisibly.
#' @examples
#' set.seed(1L)
#' rates <- seq(0, 150, by = 25)
#' ymax  <- rnorm(800L, 5.5, 0.3)
#' yld   <- vapply(rates, function(r) 3 + (ymax - 3) * (1 - exp(-r / 70)),
#'                 numeric(800L))
#' gd <- plan_nitrogen_rate(yld, rates, price_grain = 350, price_n = 1.3,
#'                          crop = "wheat",
#'                          grounding = decideR::grounding_grounded())
#' print(plan_season(list(gd), crop = "wheat", season = "2026 paddock 7"))
#' @name print.grain_plan
S7::method(print, grain_plan) <- function(x, ...) {
  n <- length(x@decisions)
  flag <- if (isTRUE(x@partial_abstention)) "  (partial abstention)" else ""
  cat(sprintf("<grain_plan> %s -- %d decision%s  [%s]%s\n",
              x@season, n, if (n == 1L) "" else "s", x@grounding, flag))
  for (d in x@decisions) {
    mark <- if (isTRUE(d@abstained)) "ABSTAIN " else "decide  "
    cat(sprintf("  - [%s] %-13s : %s %s\n", mark, d@kind,
                format(d@action), d@unit))
  }
  invisible(x)
}
