---
Type: register
Status: RESOLVED — L10N-1..18 ruled 2026-08-13
Last verified: 2026-08-13
Register: L10N-1..18
Tracker: LOCALIZATION-I18N-SCOPE-2026-08-12
Resolved-in: this register — owner walk 2026-08-13
---

# Localization Scope — Owner Questions

Research: [Localization Scope](../design/localization_scope_2026-08-12.md)

## Disposition — walked 2026-08-13

**The answer is B everywhere except `[L10N-13]`, which is C.** Every recommendation was
adopted. Five were ruled with substantive discussion because they change what gets built —
`L10N-1`, `L10N-7`, `L10N-11`, `L10N-12`, `L10N-13` — and the rest were adopted as
recommended, several of them because a ratified decision had already forced the answer.

**Why this register could not wait.** Three of the five ruled questions are being decided
*by construction* right now: the responsive conversions are rewriting every scene, and the
text-expansion budget (`L10N-7`) and left-to-right direction assumptions (`L10N-11`/`L10N-12`)
harden into each one as it is written. This row was registered on 2026-08-12 as a gap — there
was no localization row anywhere in the tracker, and no size-class or density decision had
been taken with it in mind. It is answered before the conversions bake in the answer.

**Answers that were forced rather than chosen:**

| Question | Forced by |
|---|---|
| `L10N-3` pack-owned catalogues | `[ICO-1..6]` — one pack active, completely self-contained |
| `L10N-9` never translate registry IDs | Save durability and cross-reference stability |
| `L10N-6` live locale change | The responsive contract already requires live recomposition; `[TSV-24]` already preserves focus across it |

### [L10N-1] What is the release scope?

- **A — English-only architecture.** For: smallest immediate build. Against: responsive
  scenes bake English assumptions and later retrofit is expensive.
- **B — Localization-ready v1, English guaranteed.** For: builds the seam during UI rewrite
  without promising translations. Against: infrastructure has no immediate language payoff.
- **C — Multiple translated locales in v1.** For: strongest reach and proof. Against: adds
  translation, QA and support scope before content stabilizes.
- **Recommendation:** B.

**Owner ruling (2026-08-13): B — localization-ready architecture, English the only guaranteed language.**

The seam is built during the responsive UI rewrite; no translations are promised for v1. The
reason this is not deferrable is timing rather than demand: the responsive conversions are
rewriting every scene right now, and option A would harden English assumptions into all of
them at exactly the moment they are cheapest to avoid. The infrastructure has no immediate
language payoff and is not expected to.

Option C is additionally weak here — with zero-content packs there is little shipped text to
translate.

### [L10N-2] How are engine strings identified?

- **A — English source text as key.** For: easy authoring. Against: copy edits invalidate keys.
- **B — Stable semantic message IDs.** For: durable and context-friendly. Against: requires a
  catalogue and lookup discipline.
- **Recommendation:** B; English is fallback text, never identity.

**Adopted as recommended (owner walk 2026-08-13).** B — stable semantic message IDs. English is fallback
text, never identity, so a copy edit cannot invalidate a key. Same reasoning as the
open-registry principle in `AGENTS.md`: the durable thing is the id, not the display string.

### [L10N-3] Who owns campaign-pack translations?

- **A — Engine catalogue.** For: one place. Against: violates pack self-containment.
- **B — Each pack ships its own locale catalogues.** For: self-contained distribution and
  independent updates. Against: authors carry more validation work.
- **Recommendation:** B; engine translates chrome only.

**Adopted as recommended (owner walk 2026-08-13).** B — each pack ships its own locale catalogues; the engine
translates chrome only. This is **forced**, not chosen: `[ICO-1..6]` ratified that one pack is
active at a time and is completely self-contained, so an engine catalogue holding pack strings
would be the cross-pack dependency that model forbids.

### [L10N-4] What locale fallback chain applies?

- **A — Exact locale or English.** For: deterministic. Against: wastes language-family matches.
- **B — exact → language → pack default → engine English.** For: graceful and conventional.
  Against: more provenance to display in diagnostics.
- **Recommendation:** B, with the chosen source exposed in validation reports.

**Adopted as recommended (owner walk 2026-08-13).** B — exact locale → language → pack default → engine English,
with the source that actually supplied each string exposed in validation reports. The
provenance display is what makes `[L10N-14]`'s partial-coverage packs debuggable.

### [L10N-5] What is the initial locale?

- **A — Always English.** For: predictable. Against: poor first-run experience.
- **B — OS preference with explicit in-game override.** For: Godot recommendation and user
  control. Against: first screen can expose untested locale defects.
- **Recommendation:** B, falling back safely before first render.

**Adopted as recommended (owner walk 2026-08-13).** B — OS preference with an explicit in-game override, falling
back safely before first render. Under `[L10N-1]` a non-English OS resolves through the
`[L10N-4]` chain to English, which is the guaranteed language rather than a failure.

### [L10N-6] Can locale change live?

- **A — Restart required.** For: simple state. Against: poor comparison/accessibility flow.
- **B — Live reflow preserving focus, selection and scroll.** For: matches responsive contract.
  Against: every component must react correctly.
- **Recommendation:** B; locale change is another live layout transition.

**Adopted as recommended (owner walk 2026-08-13).** B — locale changes live, preserving focus, selection and
scroll.

Worth stating why this is affordable: the responsive contract **already** requires every
component to survive live recomposition when the size class changes, and `[TSV-24]` just
ruled that focus, selection and scroll survive that transition. A locale change is the same
transition with a different trigger, so this reuses machinery rather than adding it.

### [L10N-7] What text-expansion budget is enforced?

- **A — Existing ~1.3× guidance.** For: already designed. Against: insufficient for some labels.
- **B — Pseudolocalized 1.4× plus longest-token testing.** For: stronger proof. Against: may
  force more wrapping or shorter source copy.
- **Recommendation:** B, while values truncate after labels rather than before them.

**Owner ruling (2026-08-13): B — pseudolocalized 1.4× plus longest-token testing.**

Raised from the `~1.3×` in `responsive_ui_redesign_2026-08-06.md`. 1.3× is a real-world
average, and averages are not what clips: German compound nouns and short-label cases
routinely exceed it, and short labels are exactly the ones with no slack. The pseudolocale is
generated and captured automatically at every durable viewport, so the cost is in the
layouts it forces to change, not in the testing.

**Values truncate after labels, never before them.** And the floor is already tight — the
shop album measures 4.3 rows at 360×640 — so some source copy will have to get shorter rather
than some layout getting taller.

### [L10N-8] How is plural and grammatical variation authored?

- **A — Concatenate fragments.** For: easy in English. Against: grammatically invalid broadly.
- **B — Full messages with named parameters and plural categories.** For: translator context
  and reorderability. Against: formatter contract required.
- **Recommendation:** B; prohibit UI sentence construction from fragments.

**Adopted as recommended (owner walk 2026-08-13).** B — full messages with named parameters and plural
categories, and **UI sentence construction from concatenated fragments is prohibited**. The
prohibition is the load-bearing half: fragment assembly is valid in English and
grammatically broken almost everywhere else, and it is the kind of thing that gets written
accidentally. Candidate for a `check_docs.py`-style guard under DoD#2.

### [L10N-9] Are registry IDs translated?

- **A — Sometimes, for readability.** For: fewer display fields. Against: breaks stable identity.
- **B — Never; translate separate display keys.** For: durable saves and references.
  Against: schemas carry another field.
- **Recommendation:** B.

**Adopted as recommended (owner walk 2026-08-13).** B — registry IDs are never translated; display keys are
separate fields. Forced by save durability and cross-reference stability, the same reason
`[TSV-11]` commits exact instance IDs rather than display stacks.

### [L10N-10] How are user-authored names handled?

- **A — Treat them as keys.** For: uniform lookup. Against: accidental collisions and privacy.
- **B — Render verbatim, with optional authored localized variants.** For: preserves intent.
  Against: mixed-language screens remain possible.
- **Recommendation:** B.

**Adopted as recommended (owner walk 2026-08-13).** B — user-authored names render verbatim, with optional
authored localized variants. Treating them as lookup keys would risk collisions and leak
player-entered text into a catalogue. Mixed-language screens remain possible and are
accepted. Consistent with the free-text handling in `TEXT-06`.

### [L10N-11] What RTL commitment belongs in v1?

- **A — Defer all RTL.** For: less testing. Against: component direction assumptions harden.
- **B — RTL-ready mirroring and bidi tests, no guaranteed translation.** For: protects the
  architecture. Against: creates test cases without a shipping locale.
- **C — Fully supported RTL locale.** For: definitive proof. Against: translation/QA scope.
- **Recommendation:** B.

**Owner ruling (2026-08-13): B — RTL-ready mirroring and bidi tests, no shipping RTL locale in v1.**

Same timing argument as `[L10N-1]`, and sharper: every component written during the
responsive rewrite hardens a left-to-right assumption, and there is no cheap later moment to
undo that, because the components are being written now. The commitment is architectural, not
a promise of a locale. This does create bidi test cases with no shipping locale behind them,
which is accepted.

### [L10N-12] What is mirrored?

- **A — Every visual element.** For: simple rule. Against: maps, directional icons and numeric
  conventions may become wrong.
- **B — Reading/navigation structure only; semantic spatial content opts out.** For: correct
  bidi behavior. Against: components need explicit direction metadata.
- **Recommendation:** B.

**Owner ruling (2026-08-13): B — mirror reading and navigation structure only; semantic spatial content opts out.**

Ruled with `[L10N-11]`. Mirroring applies to reading order and navigation; the tactical map,
directional icons and numeric conventions **explicitly do not mirror**, because their spatial
arrangement carries meaning rather than reading direction.

The consequence is a build obligation: components need **explicit direction metadata**, and a
component that fails to declare it must default to the safe case rather than silently
mirroring a map.

### [L10N-13] How is glyph coverage guaranteed?

- **A — System fallback.** For: small downloads. Against: absent on Web and inconsistent.
- **B — Engine-bundled fallback per supported script.** For: deterministic. Against: size and
  font licensing cost.
- **C — Pack font must cover every locale it declares, with engine emergency fallback.** For:
  preserves themes and catches tofu. Against: validator complexity.
- **Recommendation:** C, with bundled fallback for engine-guaranteed locales.

**Owner ruling (2026-08-13): C — a pack's font must cover every locale that pack declares; the engine bundles fallback only for locales it guarantees itself.**

Puts the obligation where the choice is made. Fonts are pack-swappable, so a pack that
declares Japanese must ship a font that renders it; the validator catches tofu at authoring
time instead of a player discovering it. Pack themes are preserved rather than overridden by
an engine fallback.

Two costs, both accepted: validator complexity, and the engine still bundling fallback for
its own guaranteed locales — which under `[L10N-1]` is English alone for now, so the web
export pays almost nothing today. Each bundled font is also a `[CRD]` notice entry.

### [L10N-14] May a pack declare a locale without complete coverage?

- **A — Yes, silent fallback.** For: incremental community translation. Against: hidden mixed
  language and hard-to-report gaps.
- **B — Declare completeness level and report missing keys.** For: supports drafts honestly.
  Against: adds manifest vocabulary.
- **Recommendation:** B; release-complete packs warn or fail according to declared status.

**Adopted as recommended (owner walk 2026-08-13).** B — a pack declares a completeness level for each locale and
missing keys are reported; release-complete packs warn or fail according to that declared
status. Supports incremental community translation honestly instead of silently serving mixed
language. Mirrors `[CRD-9]`'s draft-warns / release-fails severity model.

### [L10N-15] How are localized images and voices represented?

- **A — Encode locale in filenames.** For: familiar. Against: scanning and naming authority.
- **B — Explicit locale-to-asset mapping in the pack catalogue.** For: validated and open.
  Against: more records.
- **Recommendation:** B, using existing semantic asset groups.

**Adopted as recommended (owner walk 2026-08-13).** B — explicit locale-to-asset mapping in the pack catalogue,
not locale encoded in filenames. Uses the existing semantic asset groups from `[CSA]` rather
than inventing a naming authority, and it is validatable.

### [L10N-16] What automated proof is mandatory?

- **A — Unit lookup tests only.** For: fast. Against: misses clipping and direction.
- **B — missing-key/glyph checks, pseudolocale captures at all durable viewports, bidi cases,
  and live-locale state tests.** For: tests actual failure modes. Against: larger matrix.
- **Recommendation:** B, with representative screen sampling after component reuse is proven.

**Adopted as recommended (owner walk 2026-08-13).** B — mandatory proof is missing-key and glyph checks,
pseudolocale captures at all durable viewports, bidi cases, and live-locale state tests
(`[L10N-6]`). Representative screen sampling is acceptable once component reuse is proven,
which is what keeps the matrix from growing with every screen.

### [L10N-17] How are translator notes stored?

- **A — External spreadsheet only.** For: translator familiarity. Against: drifts from source.
- **B — Versioned context, character limits and screenshots keyed beside message IDs.** For:
  durable review. Against: tooling work.
- **Recommendation:** B; exporters may produce external formats from it.

**Adopted as recommended (owner walk 2026-08-13).** B — versioned context, character limits and screenshots stored
beside the message IDs, with exporters producing external formats from that. The catalogue is
the source of truth; a spreadsheet is an export, never the authority.

### [L10N-18] What is explicitly deferred?

- **A — Nothing; build all localization tooling now.** For: completeness. Against: scope blowout.
- **B — Defer translation marketplace, machine translation, voice dubbing and community
  moderation; keep their import/export seams open.** For: bounded v1. Against: later products
  still need design.
- **Recommendation:** B.

**Adopted as recommended (owner walk 2026-08-13).** B — translation marketplace, machine translation, voice
dubbing and community moderation are **deferred**, with their import/export seams left open.
Bounded v1; each is its own product later.

## Consequences of the ruled set

1. **The responsive rewrite gains two hard constraints, effective immediately.** Layouts are
   proven against a **1.4× pseudolocale** at every durable viewport, not the `~1.3×` in
   `responsive_ui_redesign_2026-08-06.md`; and every component declares **explicit direction
   metadata**, defaulting to the non-mirroring case when it does not. A component written
   without either is written wrong, and the cheapest moment to catch that is now.

2. **`responsive_ui_redesign_2026-08-06.md` needs its 1.3× figure updated**, or the two
   documents will give different budgets to the same layouts. That edit is owed.

3. **Some source copy gets shorter.** At 360×640 the shop album measures 4.3 rows of content;
   there is no room to absorb 1.4× by growing the layout, so labels absorb it instead. Values
   truncate after labels, never before.

4. **Fragment-assembled UI sentences are prohibited** (`[L10N-8]`), which is a mechanical,
   checkable rule and therefore owes an automated check under DoD#2.

5. **Nothing is promised to a player.** `[L10N-1]` buys architecture, not languages. Every
   locale resolves through `[L10N-4]` to guaranteed English until someone ships a catalogue,
   and the bidi tests exist with no shipping RTL locale behind them by design.

6. **The engine's font burden stays near zero for now.** `[L10N-13]` puts coverage on the pack
   that declares the locale, and the engine bundles fallback only for locales it guarantees —
   English alone today. The web export pays almost nothing. Each bundled font is a `[CRD]`
   notice entry when that changes.
