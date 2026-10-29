# Plan a variety choice from a breeding-values manifest

The genomic entry point to the variety decision: read genomic estimated
breeding values (GEBVs) straight from a `breeding_values`
`orchestra_manifest` – the manifest flexyBayes's genomics targets emit
(`genomic_summary()` lifted through the composition layer) – and rank
the genotypes under the same downside-aware merit loss
[`plan_variety()`](https://max578.github.io/grainPlan/reference/plan_variety.md)
uses. This closes the genomics-to-decision loop: a GBLUP posterior in, a
grounding-aware genotype recommendation out.

## Usage

``` r
plan_variety_from_manifest(
  manifest,
  genotypes = NULL,
  risk_aversion = 0.5,
  incumbent = NULL,
  gebv_sd = NULL,
  n_draws = 1000L,
  crop = "wheat",
  grounding = NULL,
  decisive_prob = 0.6,
  ...
)
```

## Arguments

- manifest:

  A `breeding_values` `orchestra_manifest` (or any S7 object exposing
  `outputs` and `metadata` with a `gebv` payload).

- genotypes:

  A character vector of genotype names; defaults to the names on the
  GEBV payload, then to `"g1"`, `"g2"`, ....

- risk_aversion:

  A non-negative downside-penalty weight (default `0.5`).

- incumbent:

  The genotype recommended on abstention, or `NULL` for the first.

- gebv_sd:

  Optional per-genotype GEBV standard deviation used to reconstruct a
  posterior from point GEBVs (a single number or one per genotype). When
  `NULL` (default) the uncertainty is read from the manifest (PEV,
  standard error, or reliability plus genetic variance); when the
  manifest carries none, supply this rather than let the function guess.
  Ignored when the payload is a draws matrix.

- n_draws:

  The number of draws to reconstruct per genotype when the payload is
  point GEBVs (default `1000L`).

- crop:

  The crop the decision concerns (default `"wheat"`).

- grounding:

  Optional override for the manifest's own grounding token; defaults to
  the token the manifest carries.

- decisive_prob:

  Minimum posterior probability that the leading genotype beats the
  incumbent.

- ...:

  Further arguments passed to
  [`plan_variety()`](https://max578.github.io/grainPlan/reference/plan_variety.md).

## Value

A
[grain_decision](https://max578.github.io/grainPlan/reference/grain_decision.md)
of kind `"variety"` whose `action` is the recommended genotype name.
Held at the incumbent, unread, when the manifest's own producer declared
an abstention (`summary$abstained`), or when it declares an
`inferential_target` other than `"breeding_values"`.

## Details

The manifest is read by its public contract. GEBVs are sought in
`outputs$gebv` (the `breeding_values` payload shape) as either a numeric
vector of point GEBVs (one per genotype) or a matrix of GEBV draws
(genotypes in columns). The grounding token rides from the manifest
exactly as the nitrogen tail does – an unverified breeding-values
manifest forces the incumbent. grainPlan takes no dependency on the
manifest constructor; the manifest is read by duck-typed S7 property
access, the composition-layer convention.

When the manifest carries point GEBVs rather than a draws matrix, the
downside-aware loss still needs a distribution to weigh, so a
per-genotype normal posterior is reconstructed with the GEBV as its
mean. The standard deviation is the genotype's own genomic uncertainty,
resolved in this order and never fabricated silently:

1.  an explicit caller `gebv_sd` (a single value or one per genotype) if
    supplied, which always wins;

2.  a per-genotype prediction-error variance on the manifest
    (`outputs$pev` or `metadata$pev`), used as \\sd_j = \sqrt{PEV_j}\\;

3.  a per-genotype standard error on the manifest (`outputs$gebv_se`,
    `outputs$se`, or `metadata$gebv_sd`), used directly;

4.  a per-genotype reliability (`outputs$reliability` or
    `metadata$reliability`) together with an additive-genetic variance
    (`metadata$genetic_var`), used as \\sd_j =
    \sqrt{\sigma^2_a\\(1-r^2_j)}\\ from the standard reliability-PEV
    relation (Mrode, 2014).

When none of these is available the function stops rather than invent an
uncertainty scale a point GEBV cannot carry: a genotype switch must not
turn on a magic constant. The resolved source is recorded in the
decision's `context` as `gebv_sd_source`, and the reconstruction never
strengthens the grounding.

## References

Mrode, R. A. (2014). *Linear Models for the Prediction of Animal
Breeding Values* (3rd ed.). CABI. The reliability-PEV relation \\r^2 =
1 - PEV/\sigma^2_a\\.

## See also

[`plan_variety()`](https://max578.github.io/grainPlan/reference/plan_variety.md)
for the caller-assembled-matrix form.

Other grain-decisions:
[`plan_grade_target()`](https://max578.github.io/grainPlan/reference/plan_grade_target.md),
[`plan_nitrogen_rate()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate.md),
[`plan_nitrogen_rate_from_manifest()`](https://max578.github.io/grainPlan/reference/plan_nitrogen_rate_from_manifest.md),
[`plan_variety()`](https://max578.github.io/grainPlan/reference/plan_variety.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# `manifest` is a breeding_values orchestra_manifest S7 object -- the manifest
# flexyBayes's genomics targets emit (genomic_summary lifted through the
# composition layer), carrying GEBVs in `outputs$gebv` and a grounding token
# in `metadata$grounding`. The manifest is read by duck-typed S7 property
# access, so grainPlan needs no dependency on the contract package.
plan_variety_from_manifest(manifest, risk_aversion = 0.5)
} # }
```
