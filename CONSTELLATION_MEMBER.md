# Orchestra membership — grainPlan

> **This project is a MEMBER of the Orchestra** (one coordination structure;
> reconciled 2026-06-03). Joined 2026-06-14 (graduated planned -> built). The
> leader-node is **ORCHESTRA_dev** (governance, roster, contracts, TACI,
> publication); the technical inference hub is **flexyBayes** (the
> dependency-DAG sink). This file is grainPlan's back-pointer to that charter and
> a map of my siblings.

- **My role:** decision orchestration — the grain-specific decision
  orchestrator, the **practitioner last-mile** that turns an upstream member's
  inference result into an actionable grain-production plan. I am a thin
  grain-semantics + orchestration layer on top of **decideR** (the analogue of
  how `flexyBayesOrchestra` composes `flexyBayes`): I add grain meaning,
  consolidate the grain value/loss schedules the orchestra runs kept
  hand-building, and compose decisions into a season plan. I do not reinvent
  decision theory, manifest reading, or the grounding firewall.
- **Contracts I own:** none. I am a pure consumer/orchestrator at the tail.
- **Contracts I honour (consume):** **C2 / C2 v2** `orchestra_manifest` — I
  consume an upstream manifest (yield draws, `breeding_values` GEBVs) **via
  decideR's duck-typed manifest tail** (`decideR::decide_from_manifest()` /
  `decideR::decide_rate_from_manifest()`); I take **no** dependency on the
  manifest constructor package, the composition-layer convention.
- **What I produce:** a `grain_plan` (an ordered, provenance-carrying season of
  `grain_decision` objects) and `grain_decision` (one recommended grain action
  wrapping a `decideR::decision`). I do **not** emit a manifest from the package
  (the decisions->manifest adapter, if ever wanted, lives in the integration
  layer, like decideR's `decideR_node.R`).
- **My edges (acyclic):** grainPlan -> **decideR** (hard `Imports:`) only.
  Upstream inference members reach me **through the manifest**, never through a
  code edge: PESTO / TACI yield posterior -> (manifest) -> grainPlan; flexyBayes
  genomics `breeding_values` -> (manifest) -> grainPlan. **Nothing imports
  grainPlan** — the orchestra DAG stays a DAG with me as a leaf at the
  decision tail.
- **What binds me (charter invariants):**
  - *Standalone-functional* — `R CMD check` clean; my only sibling dependency is
    decideR (`Imports:`, declared via `Remotes: max578/decideR` for
    reproducibility since decideR is not on CRAN). No upstream-member dependency.
  - *Contracts, not internals* — I read the manifest by its public contract
    through decideR's tail, never by special-casing a producer.
  - *Leader-directed adoption* — I align my R&D to the leader-node's published
    direction; the leader arbitrates.
  - *Manifest is load-bearing; GRDC firewall absolute (only public/synthetic
    grain data + published grade conventions — no GRDC numbers); max578
    namespace; grain anchor; L99 craft* (program bindings).
  - *IOP firewall inherited* — every grain decision routes its grounding through
    decideR's `combine_grounding()` / abstention, so an `[unverified]` upstream
    input forces an honest abstention to the status quo, not a confident wrong
    plan.

## My siblings (the full roster — so I am informed about the others)

| Member | Role | Class |
|---|---|---|
| flexyBayes | inference hub (owns C1/C4/C5/C7); genomics + MET | open |
| PESTO | calibration + manifest source (C2) | open |
| kernR | validation + TACI engine + ACI metric | open |
| proxymix | KL-optimal proxy compression; C4 consumer | open |
| gretaR | engine — torch MCMC | open |
| koine | synthesis — fourth opinion | open |
| terroir | data collector (C6) | open |
| kalmix | state-space / N-of-1 ITS causal | open (MIT) |
| masque | data sovereignty (clones) | open |
| apsimR | external engine — APSIM Next Gen | open (MIT-src + combined-GPL) |
| flexyBayesOrchestra | composition layer (koine backend, genomic oracle) | open |
| decideR | **decision layer (MY BASE — I Import it)** | open |
| gpfield | spatial GP / change-of-support member | open (MIT) |
| **grainPlan** | **decision orchestration (this member)** | open (MIT) |

Planned: `genoR` (marker-model niche), `janusplot` (candidate
diagnostic-visualisation hub).

**Canonical charter:** `ORCHESTRA_dev/ORCHESTRA.md` (mirrored in the MaxAIbase
brain, open tier). **Contract detail + dependency DAG:**
`flexyBayes_dev/CONSTELLATION.md`.

I remain independently developed and separately publishable. Membership is
cooperation, not coupling.
