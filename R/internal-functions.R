# =============================================================================
# Internal helpers
# =============================================================================
# Small, un-exported utilities shared across grainPlan's sources. Kept here
# rather than scattered so the export surface stays readable (r_style
# invariant 8). grainPlan deliberately keeps a lean Import surface (decideR,
# S7, stats), so anything tiny enough to define locally is defined here rather
# than pulling a dependency.

# Validate a price that must be a single finite non-negative number. Used by the
# grain value library, where a negative or non-finite price is a caller error
# that should fail loudly at the point of entry rather than propagate into a
# silently-wrong economic schedule.
#
# @noRd
.check_price <- function(x, what) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0) {
    stop(sprintf("`%s` must be a single finite non-negative number", what),
         call. = FALSE)
  }
  invisible(TRUE)
}

# Pull the canonical grounding token off a decideR `decision`. A `decision`
# always carries exactly one canonical token in its `@grounding` property
# (decideR's validator enforces this), so this is a thin, named accessor that
# keeps the call sites in the grain layer readable.
#
# @noRd
.decision_grounding <- function(d) {
  as.character(d@grounding)
}

# Compose a grower-facing abstention rationale for one of decideR's abstain
# reasons. Shared by every decision wrapper so all four reasons decideR can emit
# (`input_ungrounded`, `insufficient_evidence`, `no_feasible_action`, `low_ess`)
# get plain-language phrasing in every verb, and so the phrasing lives in one
# place rather than three drifting switch blocks (r_style invariant 9). The verb
# supplies its own nouns: `lead` is the "held at the status quo" clause (a rate,
# an input, a kept incumbent), `evidence` names the posterior at stake, `subject`
# is the candidate noun (a rate, a variety, an input level), and `act` is the
# thing the firewall declines to do. The final arm keeps a generic template so a
# reason decideR adds later degrades to an honest sentence rather than an error.
#
# @noRd
.abstain_rationale <- function(reason, lead, evidence, subject, act) {
  switch(
    reason,
    input_ungrounded = sprintf(
      paste0("%s: %s is unverified, so the Independent Oracle Principle ",
             "firewall declines to %s."),
      lead, evidence, act),
    insufficient_evidence = sprintf(
      "%s: no candidate %s is clearly better than the status quo on the posterior.",
      lead, subject),
    no_feasible_action = sprintf("%s: no %s is feasible.", lead, subject),
    low_ess = sprintf("%s: too few effective draws to decide.", lead),
    producer_abstained = sprintf(
      paste0("%s: the upstream evidence producer itself declined to ",
             "produce a result, so the recommendation is withheld."),
      lead),
    wrong_inferential_target = sprintf(
      "%s: the upstream manifest is not the kind of evidence that prices a %s.",
      lead, subject),
    sprintf("%s (%s).", lead, reason))
}

# -----------------------------------------------------------------------------
# Manifest-contract checks (GP-03, GP-04)
# -----------------------------------------------------------------------------

# Read whether the upstream producer itself declared a typed abstention on the
# manifest (contract v1.1's `summary` slot, `manifest_summary(headline,
# abstained, metrics)`) -- distinct from the grounding token, and not consulted
# by decideR's duck-typed manifest tail. Duck-typed off `summary` (the contract
# slot), with a `metadata$summary` fallback for a manifest that nests its
# summary there; anything that does not resolve to a single `TRUE` is read as
# "not declared", never fabricated as a refusal.
#
# @noRd
.manifest_producer_abstained <- function(m) {
  summ <- .manifest_prop(m, "summary")
  if (is.null(summ)) {
    meta <- .manifest_prop(m, "metadata", default = list())
    summ <- meta[["summary"]]
  }
  isTRUE(summ[["abstained"]])
}

# Read the manifest's declared `inferential_target` (contract v1.1, the
# `orchestra_manifest` metadata slot naming what an inference result
# represents -- `"predictions"`, `"parameters"`, `"breeding_values"`, etc.),
# duck-typed off `metadata`. `NA_character_` when the manifest carries none (an
# older or non-conforming producer never declared the field): callers treat
# that as "not declared", a field a consumer cannot yet check, never as a
# refusal by omission.
#
# @noRd
.manifest_inferential_target <- function(m) {
  meta <- .manifest_prop(m, "metadata", default = list())
  tgt <- meta[["inferential_target"]]
  if (is.character(tgt) && length(tgt) == 1L) tgt else NA_character_
}

# Check a manifest against the two contract obligations a consumer owes it
# before trusting its draws: a producer's own typed abstention always wins
# (GP-03); otherwise, when the manifest declares an `inferential_target`, it
# must be one this verb is built to price (GP-04). Returns the abstain reason
# string ("producer_abstained" / "wrong_inferential_target") that applies, or
# `NULL` when the manifest clears both checks. `accepted_targets` names the
# targets this verb honours.
#
# @noRd
.manifest_contract_violation <- function(manifest, accepted_targets) {
  if (.manifest_producer_abstained(manifest)) {
    return("producer_abstained")
  }
  declared <- .manifest_inferential_target(manifest)
  if (!is.na(declared) && !declared %in% accepted_targets) {
    return("wrong_inferential_target")
  }
  NULL
}

# Build a decideR `decision` object that refuses outright, for use when a
# manifest fails a contract check (GP-03/GP-04) -- checked before any draws or
# payload are read, so the refusal never depends on what the (wrong or
# declined) manifest happens to carry. `grounding` is always the un-grounded
# token: a forced contract refusal is never reported as grounded, whatever the
# manifest's own token says.
#
# @noRd
.manifest_contract_refusal <- function(reason, safe_action, safe_label,
                                       method, manifest) {
  decideR::decision(
    action           = safe_action,
    action_label     = paste0(safe_label, " [", reason, "]"),
    expected_utility = NA_real_,
    candidates       = NULL,
    grounding        = decideR::grounding_unverified(),
    abstained        = TRUE,
    abstain_reason   = reason,
    safe_action      = safe_action,
    method           = method,
    inputs           = list(
      manifest_run_id = .manifest_prop(manifest, "run_id",
                                       default = NA_character_),
      emitter_package = .manifest_prop(manifest, "emitter_package",
                                       default = NA_character_)),
    metadata         = list(domain = "manifest_contract_check"))
}

# -----------------------------------------------------------------------------
# ORCHESTRA cross-member refusal/abstention contract (GP-03 closeout, 2026-08-26)
# -----------------------------------------------------------------------------
# The federation's leader-side predicate `is_orchestra_decline()`
# (`ORCHESTRA_dev/integration/refusal_contract.R`) recognises a member's
# decline producer-agnostically by a naming convention on the RETURNED
# OBJECT's `class()` vector: a structured refusal ends in `_refusal`, a
# structured abstention ends in `_abstention`, or the object carries the
# explicit `orchestra_refusal` marker class. decideR already stamps its own
# `decision` this way (`decideR:::.stamp_abstention_class()` prepends
# `"decideR_abstention"`), but grainPlan's OUTER `grain_decision` wrapper
# never re-stamped itself -- a caller who receives a `grain_decision` sees
# only `c("grainPlan::grain_decision", "S7_object")` regardless of whether the
# wrapped decision abstained, so a cross-member gate built on the fleet
# predicate was blind to every abstained grain decision (matrix path, a
# manifest producer's own typed abstention, and a manifest whose declared
# `inferential_target` this verb does not price all reach here with
# `@abstained == TRUE`, since `.manifest_contract_refusal()` sets that field
# too -- one stamp point covers all three).
#
# `.stamp_grain_decline_class()` prepends BOTH `"grainPlan_abstention"` (the
# naming-convention suffix) and `"orchestra_refusal"` (the explicit marker) so
# the object is recognised by either half of the fleet predicate. Prepending
# (never replacing) preserves S7 property access and S7 method dispatch --
# `@` access and the registered `print.grain_decision` method both keep
# working with the extra classes present (verified in
# `test-orchestra-refusal-contract.R`), exactly as decideR's own
# `.stamp_abstention_class()` already relies on for its `decision` objects.
#
# @noRd
.stamp_grain_decline_class <- function(x) {
  if (isTRUE(x@abstained)) {
    cls <- class(x)
    if (!any(cls == "grainPlan_abstention")) {
      cls <- c("grainPlan_abstention", cls)
    }
    if (!any(cls == "orchestra_refusal")) {
      cls <- c("orchestra_refusal", cls)
    }
    class(x) <- cls
  }
  x
}
