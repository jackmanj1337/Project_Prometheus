---
Type: register
Status: OPEN — research prepared, owner walk not started
Last verified: 2026-08-12
Register: L10N-1..18
Tracker: LOCALIZATION-I18N-SCOPE-2026-08-12
---

# Localization Scope — Owner Questions

Research: [Localization Scope](../design/localization_scope_2026-08-12.md)

### [L10N-1] What is the release scope?

- **A — English-only architecture.** For: smallest immediate build. Against: responsive
  scenes bake English assumptions and later retrofit is expensive.
- **B — Localization-ready v1, English guaranteed.** For: builds the seam during UI rewrite
  without promising translations. Against: infrastructure has no immediate language payoff.
- **C — Multiple translated locales in v1.** For: strongest reach and proof. Against: adds
  translation, QA and support scope before content stabilizes.
- **Recommendation:** B.

### [L10N-2] How are engine strings identified?

- **A — English source text as key.** For: easy authoring. Against: copy edits invalidate keys.
- **B — Stable semantic message IDs.** For: durable and context-friendly. Against: requires a
  catalogue and lookup discipline.
- **Recommendation:** B; English is fallback text, never identity.

### [L10N-3] Who owns campaign-pack translations?

- **A — Engine catalogue.** For: one place. Against: violates pack self-containment.
- **B — Each pack ships its own locale catalogues.** For: self-contained distribution and
  independent updates. Against: authors carry more validation work.
- **Recommendation:** B; engine translates chrome only.

### [L10N-4] What locale fallback chain applies?

- **A — Exact locale or English.** For: deterministic. Against: wastes language-family matches.
- **B — exact → language → pack default → engine English.** For: graceful and conventional.
  Against: more provenance to display in diagnostics.
- **Recommendation:** B, with the chosen source exposed in validation reports.

### [L10N-5] What is the initial locale?

- **A — Always English.** For: predictable. Against: poor first-run experience.
- **B — OS preference with explicit in-game override.** For: Godot recommendation and user
  control. Against: first screen can expose untested locale defects.
- **Recommendation:** B, falling back safely before first render.

### [L10N-6] Can locale change live?

- **A — Restart required.** For: simple state. Against: poor comparison/accessibility flow.
- **B — Live reflow preserving focus, selection and scroll.** For: matches responsive contract.
  Against: every component must react correctly.
- **Recommendation:** B; locale change is another live layout transition.

### [L10N-7] What text-expansion budget is enforced?

- **A — Existing ~1.3× guidance.** For: already designed. Against: insufficient for some labels.
- **B — Pseudolocalized 1.4× plus longest-token testing.** For: stronger proof. Against: may
  force more wrapping or shorter source copy.
- **Recommendation:** B, while values truncate after labels rather than before them.

### [L10N-8] How is plural and grammatical variation authored?

- **A — Concatenate fragments.** For: easy in English. Against: grammatically invalid broadly.
- **B — Full messages with named parameters and plural categories.** For: translator context
  and reorderability. Against: formatter contract required.
- **Recommendation:** B; prohibit UI sentence construction from fragments.

### [L10N-9] Are registry IDs translated?

- **A — Sometimes, for readability.** For: fewer display fields. Against: breaks stable identity.
- **B — Never; translate separate display keys.** For: durable saves and references.
  Against: schemas carry another field.
- **Recommendation:** B.

### [L10N-10] How are user-authored names handled?

- **A — Treat them as keys.** For: uniform lookup. Against: accidental collisions and privacy.
- **B — Render verbatim, with optional authored localized variants.** For: preserves intent.
  Against: mixed-language screens remain possible.
- **Recommendation:** B.

### [L10N-11] What RTL commitment belongs in v1?

- **A — Defer all RTL.** For: less testing. Against: component direction assumptions harden.
- **B — RTL-ready mirroring and bidi tests, no guaranteed translation.** For: protects the
  architecture. Against: creates test cases without a shipping locale.
- **C — Fully supported RTL locale.** For: definitive proof. Against: translation/QA scope.
- **Recommendation:** B.

### [L10N-12] What is mirrored?

- **A — Every visual element.** For: simple rule. Against: maps, directional icons and numeric
  conventions may become wrong.
- **B — Reading/navigation structure only; semantic spatial content opts out.** For: correct
  bidi behavior. Against: components need explicit direction metadata.
- **Recommendation:** B.

### [L10N-13] How is glyph coverage guaranteed?

- **A — System fallback.** For: small downloads. Against: absent on Web and inconsistent.
- **B — Engine-bundled fallback per supported script.** For: deterministic. Against: size and
  font licensing cost.
- **C — Pack font must cover every locale it declares, with engine emergency fallback.** For:
  preserves themes and catches tofu. Against: validator complexity.
- **Recommendation:** C, with bundled fallback for engine-guaranteed locales.

### [L10N-14] May a pack declare a locale without complete coverage?

- **A — Yes, silent fallback.** For: incremental community translation. Against: hidden mixed
  language and hard-to-report gaps.
- **B — Declare completeness level and report missing keys.** For: supports drafts honestly.
  Against: adds manifest vocabulary.
- **Recommendation:** B; release-complete packs warn or fail according to declared status.

### [L10N-15] How are localized images and voices represented?

- **A — Encode locale in filenames.** For: familiar. Against: scanning and naming authority.
- **B — Explicit locale-to-asset mapping in the pack catalogue.** For: validated and open.
  Against: more records.
- **Recommendation:** B, using existing semantic asset groups.

### [L10N-16] What automated proof is mandatory?

- **A — Unit lookup tests only.** For: fast. Against: misses clipping and direction.
- **B — missing-key/glyph checks, pseudolocale captures at all durable viewports, bidi cases,
  and live-locale state tests.** For: tests actual failure modes. Against: larger matrix.
- **Recommendation:** B, with representative screen sampling after component reuse is proven.

### [L10N-17] How are translator notes stored?

- **A — External spreadsheet only.** For: translator familiarity. Against: drifts from source.
- **B — Versioned context, character limits and screenshots keyed beside message IDs.** For:
  durable review. Against: tooling work.
- **Recommendation:** B; exporters may produce external formats from it.

### [L10N-18] What is explicitly deferred?

- **A — Nothing; build all localization tooling now.** For: completeness. Against: scope blowout.
- **B — Defer translation marketplace, machine translation, voice dubbing and community
  moderation; keep their import/export seams open.** For: bounded v1. Against: later products
  still need design.
- **Recommendation:** B.
