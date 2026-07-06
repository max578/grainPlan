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
    sprintf("%s (%s).", lead, reason))
}
