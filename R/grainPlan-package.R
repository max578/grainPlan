#' grainPlan: Grain-Specific Decision Orchestration on Top of Decision Theory
#'
#' grainPlan is the practitioner last-mile of the ORCHESTRA agricultural
#' analytics stack: it turns an upstream member's inference result into an
#' actionable grain-production plan. It is a thin grain-semantics layer built on
#' the 'decideR' decision engine -- it reuses that engine
#' (`decideR::decide()`), its manifest-native pipeline tail
#' (`decideR::decide_from_manifest()`), its grade-band loss library
#' (`decideR::grade_band_value()`), and its grounding firewall
#' (`decideR::combine_grounding()`), and adds the grain economics those
#' decisions kept re-deriving. The package never reinvents decision theory,
#' manifest reading, or the Independent Oracle Principle firewall; it composes
#' them with grain meaning.
#'
#' @keywords internal
"_PACKAGE"

# Register S7 methods (the `print` methods for `grain_decision` and
# `grain_plan`) with the base generics they extend. Required because those
# generics live outside grainPlan.
.onLoad <- function(libname, pkgname) {
  S7::methods_register()
}
