# =============================================================================
# Grain decision: variety selection
# =============================================================================
# The breeding / agronomy decision -- which variety to sow -- expressed as a
# grain-semantics wrapper over decideR's expected-utility engine. A
# multi-environment trial (MET) or a genomic-prediction model gives posterior
# draws of each candidate variety's merit (its mean performance across
# environments, or its genomic estimated breeding value); the decision is to
# rank them under an explicit, downside-aware loss and recommend the leading
# variety -- abstaining when the merit evidence is un-grounded or no variety is
# clearly better than the incumbent. The engine is `decideR::decide()`; the
# candidates are the variety indices, the utility is downside-aware merit, and
# the firewall and abstention are decideR's. This is the synergy with the
# flexyBayes genomics targets: a `breeding_values` manifest feeds straight in.

# Build the downside-aware merit utility for a variety decision. For a candidate
# variety j, the utility at a draw is the variety's merit on that draw less a
# risk penalty: `risk_aversion` times the shortfall of the draw below the
# variety's own posterior mean (a one-sided downside penalty, so upside is not
# penalised). With `risk_aversion = 0` the rule is plain expected merit; raising
# it favours varieties whose downside is shallow -- the stability a grower wants
# from a sown variety. Returned as the per-draw, per-candidate utility matrix.
.variety_utility_matrix <- function(merit_draws, risk_aversion) {
  centres <- colMeans(merit_draws)
  n_cand <- ncol(merit_draws)
  vapply(
    seq_len(n_cand),
    function(j) {
      m <- merit_draws[, j]
      shortfall <- pmax(centres[j] - m, 0)
      m - risk_aversion * shortfall
    },
    numeric(nrow(merit_draws)))
}

#' Plan a variety choice from a multi-environment trial or genomic posterior
#'
#' Rank candidate grain varieties under a downside-aware merit loss and
#' recommend the leading one, abstaining when the merit evidence is unverified
#' or no variety is clearly better than the incumbent. It is a grain-semantics
#' wrapper over `decideR::decide()`: the variety indices are the candidate
#' actions, the utility is each variety's posterior merit less a one-sided
#' downside penalty (`risk_aversion` times the shortfall below the variety's own
#' mean, so a high-yielding but volatile line is discounted against a steady
#' one), and the grounding firewall plus abstention are decideR's.
#'
#' `merit_draws` is a numeric matrix of posterior merit draws with one column
#' per variety (rows are draws) -- the object a factor-analytic MET model emits
#' (a variety's mean across environments) or a genomic-prediction model emits
#' (its genomic estimated breeding value posterior). The recommendation is the
#' single leading variety; the full ranked ledger of every variety's expected
#' merit is carried in the wrapped decision's `candidates` for a short-list.
#'
#' The grounding rides from the evidence: an unverified merit posterior forces
#' the recommendation to the `incumbent` variety (the safe action), so a variety
#' is never switched on evidence the producer did not ground.
#'
#' @param merit_draws A numeric matrix of posterior merit draws, one column per
#'   variety (rows are draws).
#' @param varieties A character vector of variety names, one per column of
#'   `merit_draws`; defaults to the column names of `merit_draws`, then to
#'   `"v1"`, `"v2"`, ....
#' @param risk_aversion A non-negative number weighting the one-sided downside
#'   penalty (default `0.5`); `0` is plain expected merit.
#' @param incumbent The variety recommended on abstention -- the status-quo line
#'   a grower keeps when the evidence does not justify a switch; a variety name
#'   in `varieties`, or `NULL` to default to the first variety.
#' @param crop The crop the decision concerns (default `"wheat"`).
#' @param grounding One or more grounding tokens for the merit evidence;
#'   combined worst-case.
#' @param decisive_prob Minimum posterior probability that the leading variety
#'   beats the incumbent (passed to `decideR::decide()`).
#' @param ... Further arguments passed to the decision core (e.g. `min_ess`).
#' @return A [grain_decision] of kind `"variety"` whose `action` is the
#'   recommended variety name; the ranked short-list is in
#'   `decision@candidates` of the wrapped decision.
#' @examples
#' set.seed(1L)
#' varieties <- c("Scepter", "Vixen", "Calibre", "Denison")
#' means <- c(5.2, 5.4, 4.9, 5.3)
#' merit_draws <- vapply(means, function(m) rnorm(1000L, m, 0.25),
#'                       numeric(1000L))
#' plan_variety(merit_draws, varieties, crop = "wheat",
#'              grounding = decideR::grounding_grounded())
#' @seealso [plan_variety_from_manifest()] for a `breeding_values` manifest;
#'   [decideR::decide()] for the underlying engine.
#' @family grain-decisions
#' @export
plan_variety <- function(merit_draws, varieties = NULL, risk_aversion = 0.5,
                         incumbent = NULL, crop = "wheat",
                         grounding = decideR::grounding_unverified(),
                         decisive_prob = 0.6, ...) {
  if (!is.matrix(merit_draws) || nrow(merit_draws) == 0L ||
        ncol(merit_draws) == 0L) {
    stop("`merit_draws` must be a non-empty numeric matrix", call. = FALSE)
  }
  if (!is.numeric(risk_aversion) || length(risk_aversion) != 1L ||
        risk_aversion < 0) {
    stop("`risk_aversion` must be a single non-negative number", call. = FALSE)
  }
  n_cand <- ncol(merit_draws)
  varieties <- .resolve_varieties(varieties, merit_draws, n_cand)
  safe_idx <- .resolve_incumbent(incumbent, varieties)

  util_matrix <- .variety_utility_matrix(merit_draws, risk_aversion)
  grounding <- decideR::combine_grounding(grounding)

  # Decide over the variety indices: the candidate set is 1..n, the per-draw
  # utility of "choose variety j" is the jth column of the merit utility, and
  # the safe action is the incumbent's index. decideR's engine then applies the
  # grounding firewall and the decisive-versus-incumbent abstention exactly as
  # it does for a numeric rate grid.
  d <- decideR::decide(
    draws       = util_matrix[, 1L],
    utility     = function(action, theta) util_matrix[, action],
    candidates  = seq_len(n_cand),
    labels      = varieties,
    grounding   = grounding,
    safe_action = safe_idx,
    safe_label  = varieties[safe_idx],
    decisive_prob = decisive_prob,
    method      = "downside_aware_merit",
    inputs      = list(varieties = varieties, risk_aversion = risk_aversion),
    metadata    = list(domain = "breeding"),
    ...)

  variety <- varieties[[d@action]]
  context <- list(varieties = varieties, risk_aversion = risk_aversion,
                  incumbent = varieties[safe_idx], evidence = "merit_draws")
  .wrap_variety_decision(d, variety, crop = crop, context = context)
}

# Resolve variety names: caller-supplied, else the matrix column names, else a
# generated v1..vn. Validated to one name per column.
#
# @noRd
.resolve_varieties <- function(varieties, merit_draws, n_cand) {
  if (is.null(varieties)) {
    varieties <- colnames(merit_draws)
  }
  if (is.null(varieties)) {
    varieties <- paste0("v", seq_len(n_cand))
  }
  varieties <- as.character(varieties)
  if (length(varieties) != n_cand) {
    stop("`varieties` must have one name per column of `merit_draws`",
         call. = FALSE)
  }
  varieties
}

# Resolve the incumbent variety to its column index, defaulting to the first
# variety when none is named. A named incumbent not in the set is a caller
# error and stops loudly.
#
# @noRd
.resolve_incumbent <- function(incumbent, varieties) {
  if (is.null(incumbent)) {
    return(1L)
  }
  idx <- match(as.character(incumbent), varieties)
  if (is.na(idx)) {
    stop(sprintf("`incumbent` (%s) is not one of the candidate varieties",
                 sQuote(incumbent)), call. = FALSE)
  }
  idx
}

# Lift a decideR variety `decision` into a grain_decision, copying the grounding
# straight off the wrapped decision and composing the grower-facing rationale.
#
# @noRd
.wrap_variety_decision <- function(d, variety, crop, context) {
  grounding <- .decision_grounding(d)
  if (isTRUE(d@abstained)) {
    rationale <- switch(
      d@abstain_reason,
      input_ungrounded = paste0(
        "Kept the incumbent variety (", context$incumbent, "): the merit ",
        "evidence is unverified, so the firewall declines to switch on it."),
      insufficient_evidence = paste0(
        "Kept the incumbent variety (", context$incumbent, "): no candidate ",
        "variety is clearly better on the posterior."),
      sprintf("Kept the incumbent variety (%s) -- %s.", context$incumbent,
              d@abstain_reason))
  } else {
    rationale <- sprintf(
      paste0("Sow %s in the %s crop: it leads the downside-aware merit ",
             "ranking and clearly beats the incumbent (%s) on the posterior."),
      variety, crop, context$incumbent)
  }
  grain_decision(
    decision  = d,
    crop      = crop,
    kind      = "variety",
    action    = variety,
    unit      = "variety",
    abstained = isTRUE(d@abstained),
    grounding = grounding,
    rationale = rationale,
    context   = context)
}

#' Plan a variety choice from a breeding-values manifest
#'
#' The genomic entry point to the variety decision: read genomic estimated
#' breeding values (GEBVs) straight from a `breeding_values`
#' `orchestra_manifest` -- the manifest flexyBayes's genomics targets emit
#' (`genomic_summary()` lifted through the composition layer) -- and rank the
#' genotypes under the same downside-aware merit loss [plan_variety()] uses.
#' This closes the genomics-to-decision loop: a GBLUP posterior in, a
#' grounding-aware genotype recommendation out.
#'
#' The manifest is read by its public contract. GEBVs are sought in
#' `outputs$gebv` (the `breeding_values` payload shape) as either a numeric
#' vector of point GEBVs (one per genotype) or a matrix of GEBV draws (genotypes
#' in columns). The grounding token rides from the manifest exactly as the
#' nitrogen tail does -- an unverified breeding-values manifest forces the
#' incumbent. grainPlan takes no dependency on the manifest constructor; the
#' manifest is read by duck-typed S7 property access, the composition-layer
#' convention.
#'
#' When the manifest carries point GEBVs rather than draws, a posterior is
#' reconstructed per genotype from the GEBV and its reliability (a normal with
#' the GEBV as mean and `gebv_sd` as standard deviation, or a supplied
#' per-genotype standard deviation), so the downside-aware loss still has a
#' distribution to weigh; this reconstruction is recorded in the decision's
#' context and the grounding is unaffected.
#'
#' @param manifest A `breeding_values` `orchestra_manifest` (or any S7 object
#'   exposing `outputs` and `metadata` with a `gebv` payload).
#' @param genotypes A character vector of genotype names; defaults to the names
#'   on the GEBV payload, then to `"g1"`, `"g2"`, ....
#' @param risk_aversion A non-negative downside-penalty weight (default `0.5`).
#' @param incumbent The genotype recommended on abstention, or `NULL` for the
#'   first.
#' @param gebv_sd The per-genotype GEBV standard deviation used to reconstruct a
#'   posterior when the manifest carries point GEBVs (a single number or one per
#'   genotype; default `1`); ignored when the payload is a draws matrix.
#' @param n_draws The number of draws to reconstruct per genotype when the
#'   payload is point GEBVs (default `1000L`).
#' @param crop The crop the decision concerns (default `"wheat"`).
#' @param grounding Optional override for the manifest's own grounding token;
#'   defaults to the token the manifest carries.
#' @param decisive_prob Minimum posterior probability that the leading genotype
#'   beats the incumbent.
#' @param ... Further arguments passed to [plan_variety()].
#' @return A [grain_decision] of kind `"variety"` whose `action` is the
#'   recommended genotype name.
#' @examples
#' \dontrun{
#' # `manifest` is a breeding_values orchestra_manifest S7 object -- the manifest
#' # flexyBayes's genomics targets emit (genomic_summary lifted through the
#' # composition layer), carrying GEBVs in `outputs$gebv` and a grounding token
#' # in `metadata$grounding`. The manifest is read by duck-typed S7 property
#' # access, so grainPlan needs no dependency on the contract package.
#' plan_variety_from_manifest(manifest, risk_aversion = 0.5)
#' }
#' @seealso [plan_variety()] for the caller-assembled-matrix form.
#' @family grain-decisions
#' @export
plan_variety_from_manifest <- function(manifest, genotypes = NULL,
                                       risk_aversion = 0.5, incumbent = NULL,
                                       gebv_sd = 1, n_draws = 1000L,
                                       crop = "wheat", grounding = NULL,
                                       decisive_prob = 0.6, ...) {
  payload <- .manifest_gebv(manifest)
  g <- if (is.null(grounding)) .manifest_grounding_token(manifest) else grounding

  if (is.matrix(payload)) {
    merit_draws <- payload
    names_in <- colnames(payload)
    reconstructed <- FALSE
  } else {
    merit_draws <- .gebv_draws_from_points(payload, gebv_sd, n_draws)
    names_in <- names(payload)
    reconstructed <- TRUE
  }
  if (is.null(genotypes)) {
    genotypes <- names_in
  }

  gd <- plan_variety(
    merit_draws = merit_draws, varieties = genotypes,
    risk_aversion = risk_aversion, incumbent = incumbent, crop = crop,
    grounding = g, decisive_prob = decisive_prob, ...)
  gd@context <- c(gd@context,
                  list(evidence = "breeding_values manifest",
                       reconstructed_posterior = reconstructed))
  gd
}

# Read the GEBV payload off a breeding_values manifest by duck-typed S7 property
# access -- no dependency on the contract class. Returns the numeric vector or
# matrix of GEBVs, or stops when the manifest carries no `gebv` payload.
#
# @noRd
.manifest_gebv <- function(m) {
  outputs <- .manifest_prop(m, "outputs", default = NULL)
  gebv <- if (is.list(outputs)) outputs[["gebv"]] else NULL
  if (is.null(gebv)) {
    meta <- .manifest_prop(m, "metadata", default = list())
    gebv <- meta[["gebv"]]
  }
  if (is.null(gebv)) {
    stop(paste0("manifest carries no breeding values in `outputs$gebv` or ",
                "`metadata$gebv` -- is it a breeding_values manifest?"),
         call. = FALSE)
  }
  if (is.matrix(gebv)) {
    return(gebv)
  }
  # A named numeric vector of point GEBVs: keep the names (as.numeric() would
  # strip them, losing the genotype identities the variety ranking needs).
  out <- as.numeric(gebv)
  names(out) <- names(gebv)
  out
}

# Reconstruct a per-genotype posterior from point GEBVs and a reliability
# standard deviation, so the downside-aware loss has a distribution to weigh.
# Deterministic given the session seed; the reconstruction is flagged in the
# decision context, never as a stronger grounding.
#
# @noRd
.gebv_draws_from_points <- function(gebv, gebv_sd, n_draws) {
  n_g <- length(gebv)
  sds <- if (length(gebv_sd) == 1L) rep(gebv_sd, n_g) else gebv_sd
  if (length(sds) != n_g || any(sds < 0)) {
    stop("`gebv_sd` must be one non-negative number or one per genotype",
         call. = FALSE)
  }
  draws <- vapply(seq_len(n_g),
                  function(j) stats::rnorm(n_draws, gebv[j], sds[j]),
                  numeric(n_draws))
  colnames(draws) <- names(gebv)
  draws
}

# Read a named property off an S7 manifest without a hard contract dependency,
# mirroring decideR's duck-typed accessor. Returns `default` when the object is
# not an S7 object carrying the property.
#
# @noRd
.manifest_prop <- function(m, name, default = NULL) {
  ok <- isTRUE(tryCatch(S7::S7_inherits(m), error = function(e) FALSE)) &&
    name %in% S7::prop_names(m)
  if (ok) S7::prop(m, name) else default
}

# Read the grounding token a manifest carries, mirroring decideR's tail
# convention (metadata$grounding first, then the typed summary metric, then the
# honest un-grounded default). Validated downstream by the decision engine.
#
# @noRd
.manifest_grounding_token <- function(m) {
  meta <- .manifest_prop(m, "metadata", default = list())
  if (!is.null(meta[["grounding"]])) {
    return(as.character(meta[["grounding"]]))
  }
  summ <- .manifest_prop(m, "summary")
  if (!is.null(summ) && is.list(summ) && !is.null(summ$metrics$grounding)) {
    return(as.character(summ$metrics$grounding))
  }
  decideR::grounding_unverified()
}
