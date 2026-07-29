# Ruleset sample-pack authoring notes

Date: 2026-07-29

These are small conformance fixtures, not complete or redistributable ruleset
catalogues. Each pack follows one representative Cavalier advancement family far
enough to pressure a distinct part of trial v1:

- `fed20_sample`: branching promotion while parts of the source audit remain open;
- `awakening_sample`: branching promotion and class skill/source pressure;
- `fe7_sample`: fixed promotion plus male/female class variants.

The values are internal validation evidence derived from the private FE campaign-pack
review branches named in each source registry. They must not enter shipped content or
generated public reference exports without a separate rights and source-accuracy
review.

## Notes and pain points encountered

1. **Required maps can be empty.** FEd20 has unresolved bases, growths, caps, and WEXP
   baselines. Trial v1 requires the maps but permits `{}`, making an incomplete class
   indistinguishable from an intentionally statless class. Add a completeness rule:
   either required stat sets per rules profile, or explicit field-level
   `unknown`/`not_applicable` evidence that complete packs must resolve.
2. **Provenance cannot express ordinary exact transcription.** Occurrence records are
   allowed only for transformed/disputed/conflicting/ambiguous facts. That leaves no
   stable field-level citation for an exact value such as FE7 female Sword WEXP.
   Permit `transcribed` as a decision state, while continuing to require occurrence
   coverage only for non-literal decisions.
3. **Variants replace whole maps.** FE7 gender variants must repeat complete base and
   WEXP maps to change one value. This is predictable but error-prone. Keep replace
   semantics for v1, but generate an expanded preview and warn when a variant omits a
   key present in the base map.
4. **Eligibility facts are untyped strings.** `fact_contains_v1` accepts `sex`, but the
   class schema cannot prove that the owning unit schema registers that fact or its
   allowed values. Descriptor validation needs typed parameter bindings to a shared
   fact registry.
5. **Skill references cannot yet form a self-contained pack.** Awakening needs class
   unlocks, but this trial registry defines no `skill` document schema even though
   `skill_unlocks` declares skill references. The fixture therefore cannot include
   Discipline/Outdoor Fighter without relying on an external package. Add explicit
   dependency/import declarations to manifests and validate qualified cross-package
   references; do not silently treat bare ids as global.
6. **Promotion item identity is buried in generic parameters.** The three rulesets can
   share one route shape, but `item_cost_v1.parameters.item_id` has no declared typed
   reference in the registry. Descriptor registrations must declare parameter types
   and reference targets so a missing seal fails before preview.
7. **Advancement stat gains need source/destination variant policy.** FE7 promotion
   gains may depend on which class variant is selected. Edge variants can encode the
   result, but the contract does not state whether eligibility evaluates the source
   unit, destination class, or both. Add an explicit evaluation subject to variant
   descriptors and test it during preview and restore.
8. **Awakening reclass remains outside this slice.** A promotion-only class pack does
   not exercise unit-owned reclass destinations or cumulative-level pressure. Keep
   those in the separately tracked progression-pressure fixture rather than bloating
   class documents, but add a manifest dependency link so the two conformance suites
   are discoverable together.
9. **Display names are mandatory on mechanics records.** This is useful for edges and
   routes in editor tooling, but localization will eventually require a stable text
   key rather than one embedded English string. Add optional `display_name_key`
   before content schema v1 freezes.

## Recommended trial-v1 revisions before freeze

The blockers are typed descriptor references, package dependencies/qualified ids,
and completeness semantics for required maps. The remaining items can ship with
warnings or explicit follow-up tests, but should be decided before bulk class-family
transcription begins.
