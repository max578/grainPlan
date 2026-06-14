# =============================================================================
# The grain value / loss library
# =============================================================================
# This file is grainPlan's consolidation point: the grain value and loss
# schedules the ORCHESTRA runs kept hand-building inline -- protein-band
# economics, malting premiums, nitrogen-rate economics -- collected here once,
# documented, parameterised, and reusable, so a practitioner stops re-deriving
# them. Each schedule wraps a `decideR` loss primitive (`grade_band_value()` /
# its utility) with real grain-economic structure, or returns a small named
# economics object a decision verb consumes.
#
# Every default price structure here is ILLUSTRATIVE and built from publicly
# documented grain-grade conventions (the Australian wheat/barley receival
# standards and the published grade-band shape: a step-up payoff as a quality
# threshold is cleared). They are NOT receival prices from any private or
# GRDC-origin source (program binding 10: GRDC firewall absolute; the orchestra
# is generic and downstream-consumable). Callers supply their own current prices
# for a real decision; the defaults exist so an example, a test, or a first
# pass runs without a price sheet to hand. References are named in the docs.

# Validate that a vector of band breaks is usable as a grade-band schedule:
# numeric, non-empty, strictly increasing, no NA. Delegated to a named helper so
# each library schedule reads as its economic intent, not a wall of checks
# (r_style invariant 9).
.check_bands <- function(breaks, what) {
  if (!is.numeric(breaks) || length(breaks) == 0L || anyNA(breaks)) {
    stop(sprintf("`%s` must be a non-empty numeric vector with no NA", what),
         call. = FALSE)
  }
  if (is.unsorted(breaks, strictly = TRUE)) {
    stop(sprintf("`%s` must be strictly increasing", what), call. = FALSE)
  }
  invisible(TRUE)
}

#' Wheat protein-band value schedule
#'
#' The canonical Australian milling-wheat payoff: a price per tonne that steps
#' up as grain protein clears each receival band. This is the schedule the
#' orchestra runs kept hand-building when they priced a quality-graded wheat
#' decision; `wheat_protein_bands()` consolidates it into a first-class,
#' documented `decideR::grade_band_value()` schedule so a decision can price
#' protein without re-deriving the band table.
#'
#' The default `breaks` are the protein thresholds that separate the broad
#' Australian wheat grades by protein -- feed below the milling floor, then the
#' standard milling grades (Australian Standard White, Australian Premium White)
#' and the high-protein hard grades (Australian Hard, Australian Prime Hard) --
#' and the default `values` are an illustrative step-up of dollars per tonne
#' across them. The band shape (a step at each protein threshold) follows the
#' published Grain Trade Australia wheat standards; the dollar values are
#' illustrative and not receival prices. Supply current prices for a real
#' decision.
#'
#' @param breaks A strictly increasing numeric vector of protein thresholds in
#'   percent (default `c(10.5, 11.5, 13.0)`, the milling / hard / prime-hard
#'   edges).
#' @param values A numeric vector of dollar-per-tonne band payoffs, of length
#'   `length(breaks) + 1`, ordered from the lowest (feed) band up (default an
#'   illustrative `c(300, 330, 360, 400)`).
#' @return A `decideR::grade_band_value` schedule: a vectorised function from a
#'   protein outcome to its band payoff in dollars per tonne, carrying the
#'   schedule for inspection.
#' @references Grain Trade Australia, *Wheat Standards* (publicly published
#'   receival standards; band thresholds), and the broad Australian wheat grade
#'   classes (AGW Feed, ASW, APW, AH, APH). Dollar values are illustrative.
#' @examples
#' v <- wheat_protein_bands()
#' v(c(9.5, 11.0, 11.5, 13.4))
#' v
#' @seealso [barley_malting_premium()] for the barley counterpart;
#'   [plan_grade_target()] for the decision that consumes it.
#' @family grain-value
#' @export
wheat_protein_bands <- function(breaks = c(10.5, 11.5, 13.0),
                                values = c(300, 330, 360, 400)) {
  .check_bands(breaks, "breaks")
  if (length(values) != length(breaks) + 1L) {
    stop(sprintf(
      "`values` must have one more element than `breaks` (%d bands need %d values)",
      length(breaks), length(breaks) + 1L), call. = FALSE)
  }
  labels <- .wheat_band_labels(breaks)
  decideR::grade_band_value(breaks = breaks, values = values, labels = labels)
}

# Build human-readable wheat-grade labels for a protein-band schedule. The names
# track the broad Australian wheat classes when the default three-break grid is
# used; otherwise a plain interval label is built so a custom grid still prints
# sensibly.
#
# @noRd
.wheat_band_labels <- function(breaks) {
  if (identical(breaks, c(10.5, 11.5, 13.0))) {
    return(c("Feed (<10.5)", "ASW [10.5, 11.5)", "APW [11.5, 13.0)",
             "AH/APH (>=13.0)"))
  }
  edges <- c(-Inf, breaks, Inf)
  vapply(seq_len(length(breaks) + 1L),
         function(i) sprintf("[%s, %s)", format(edges[i]),
                             format(edges[i + 1L])),
         character(1L))
}

#' Barley malting-premium value schedule
#'
#' The barley counterpart to [wheat_protein_bands()]: a price per tonne that
#' carries a malting premium when grain protein falls inside the malting window
#' and drops to the feed price outside it. Malting barley is the textbook
#' two-sided quality payoff -- protein that is too low or too high both miss the
#' malting grade -- which a single rising step schedule cannot express, so this
#' schedule pays the premium only across the central band.
#'
#' The default `window` is the broad malting protein window in percent and the
#' default prices are an illustrative feed price and malting premium in dollars
#' per tonne. The window shape (a premium inside an acceptance band, feed
#' outside) follows the published Barley Australia / Grain Trade Australia
#' malting receival conventions; the dollar values are illustrative and not
#' receival prices. Supply current prices for a real decision.
#'
#' @param window A length-two numeric vector `c(low, high)` giving the malting
#'   protein window in percent (default `c(9.5, 12.5)`).
#' @param feed_price The feed price in dollars per tonne paid outside the
#'   window (default an illustrative `280`).
#' @param malting_premium The premium in dollars per tonne added to the feed
#'   price inside the window (default an illustrative `60`).
#' @return A `decideR::grade_band_value` schedule: a vectorised function from a
#'   protein outcome to its dollar-per-tonne payoff, paying
#'   `feed_price + malting_premium` inside the window and `feed_price` outside.
#' @references Barley Australia and Grain Trade Australia malting barley
#'   receival standards (the malting protein window). Dollar values are
#'   illustrative.
#' @examples
#' v <- barley_malting_premium()
#' v(c(8.0, 10.5, 13.0))
#' v
#' @seealso [wheat_protein_bands()] for the wheat counterpart;
#'   [plan_grade_target()] for the decision that consumes it.
#' @family grain-value
#' @export
barley_malting_premium <- function(window = c(9.5, 12.5), feed_price = 280,
                                   malting_premium = 60) {
  if (!is.numeric(window) || length(window) != 2L || anyNA(window) ||
        window[1L] >= window[2L]) {
    stop("`window` must be a length-two increasing numeric vector `c(low, high)`",
         call. = FALSE)
  }
  .check_price(feed_price, "feed_price")
  .check_price(malting_premium, "malting_premium")
  malting <- feed_price + malting_premium
  decideR::grade_band_value(
    breaks = window,
    values = c(feed_price, malting, feed_price),
    labels = c(sprintf("feed (<%g)", window[1L]),
               sprintf("malting [%g, %g)", window[1L], window[2L]),
               sprintf("feed (>=%g)", window[2L])))
}

#' Nitrogen-rate economics
#'
#' The reusable economic bundle a nitrogen-rate decision prices against: the
#' grain price, the nitrogen price, and the resulting per-draw profit utility
#' \eqn{p_y\,y - p_n\,r}. This is the second hand-built economic that the
#' orchestra runs kept re-deriving inline; `n_rate_economics()` consolidates it
#' into a named, documented object holding both the prices and the utility
#' function the decision engine consumes, so a profit-priced rate decision reads
#' as its economics rather than as an anonymous lambda.
#'
#' The utility is the textbook nitrogen-response economics: revenue is the grain
#' price times yield, the cost is the nitrogen price times the rate, and profit
#' is their difference. Yield and rate are in whatever units the caller's yield
#' draws and rate grid use (tonnes per hectare and kilograms of nitrogen per
#' hectare in the common case); the prices must be in matching units (dollars
#' per tonne and dollars per kilogram of nitrogen).
#'
#' @param price_grain The grain price per unit yield (e.g. dollars per tonne).
#' @param price_n The nitrogen price per unit rate (e.g. dollars per kilogram
#'   of nitrogen).
#' @return A list with class `n_rate_economics` holding `price_grain`,
#'   `price_n`, and `utility`, where `utility(rate, yield)` returns the profit
#'   per draw -- the function form `decideR::decide()` and
#'   `decideR::decide_rate_from_manifest()` consume.
#' @references Standard nitrogen-response profit economics (revenue less
#'   nitrogen cost); the per-tonne / per-kilogram convention follows the broad
#'   Australian grains gross-margin framework.
#' @examples
#' e <- n_rate_economics(price_grain = 350, price_n = 1.3)
#' e$utility(rate = 80, yield = c(4.0, 4.5, 5.0))
#' e
#' @seealso [plan_nitrogen_rate()] for the decision that consumes it.
#' @family grain-value
#' @export
n_rate_economics <- function(price_grain, price_n) {
  .check_price(price_grain, "price_grain")
  .check_price(price_n, "price_n")
  force(price_grain)
  force(price_n)
  out <- list(
    price_grain = price_grain,
    price_n     = price_n,
    utility     = function(rate, yield) price_grain * yield - price_n * rate
  )
  class(out) <- "n_rate_economics"
  out
}

#' Print nitrogen-rate economics
#'
#' @param x An [n_rate_economics] object.
#' @param ... Ignored, for compatibility with [print()].
#' @return `x`, invisibly.
#' @examples
#' print(n_rate_economics(price_grain = 350, price_n = 1.3))
#' @export
print.n_rate_economics <- function(x, ...) {
  cat("<n_rate_economics>\n")
  cat(sprintf("  grain price : %s / unit yield\n", format(x$price_grain)))
  cat(sprintf("  N price     : %s / unit N\n", format(x$price_n)))
  cat("  profit      : price_grain * yield - price_n * rate\n")
  invisible(x)
}
