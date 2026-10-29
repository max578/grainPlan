# grainPlan: Grain-Specific Decision Orchestration on Top of Decision Theory

grainPlan is the practitioner last-mile of the ORCHESTRA agricultural
analytics stack: it turns an upstream member's inference result into an
actionable grain-production plan. It is a thin grain-semantics layer
built on the 'decideR' decision engine – it reuses that engine
([`decideR::decide()`](https://rdrr.io/pkg/decideR/man/decide.html)),
its manifest-native pipeline tail
([`decideR::decide_from_manifest()`](https://rdrr.io/pkg/decideR/man/decide_from_manifest.html)),
its grade-band loss library
([`decideR::grade_band_value()`](https://rdrr.io/pkg/decideR/man/grade_band_value.html)),
and its grounding firewall
([`decideR::combine_grounding()`](https://rdrr.io/pkg/decideR/man/combine_grounding.html)),
and adds the grain economics those decisions kept re-deriving. The
package never reinvents decision theory, manifest reading, or the
Independent Oracle Principle firewall; it composes them with grain
meaning.

## See also

Useful links:

- <https://github.com/max578/grainPlan>

- <https://max578.github.io/grainPlan/>

- Report bugs at <https://github.com/max578/grainPlan/issues>

## Author

**Maintainer**: Max Moldovan <max.moldovan@gmail.com>
([ORCID](https://orcid.org/0000-0001-9680-8474))

Authors:

- Max Moldovan <max.moldovan@gmail.com>
  ([ORCID](https://orcid.org/0000-0001-9680-8474))
