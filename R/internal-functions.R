# =============================================================================
# Internal helpers
# =============================================================================
# Small, un-exported utilities shared across grainPlan's sources. Kept here
# rather than scattered so the export surface stays readable (r_style
# invariant 8). grainPlan deliberately keeps a lean Import surface (decideR,
# S7, stats), so anything tiny enough to define locally is defined here rather
# than pulling a dependency.

# Null-coalescing helper -- return the right operand when the left is NULL.
# Used to apply defaults to optional arguments. Defined locally (not imported)
# to keep the three-Import surface.
#
# @noRd
`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}

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
