---
Type: register
Status: RESOLVED — CRD-1..10 ruled 2026-08-13
Last verified: 2026-08-13
Register: CRD-1..10
Tracker: LEG-INGAME-ATTRIBUTION-2026-07-20
Resolved-in: this register — owner walk 2026-08-13
---

# Credits and Attribution — Owner Questions

Research: [Credits and Attribution](../design/credits_attribution_comparative_research_2026-08-12.md)

## Disposition — walked 2026-08-13

**Every recommendation adopted — B throughout.** `CRD-8` and `CRD-9` were ruled with
discussion; the remaining eight were adopted as recommended, most of them determined by
licence obligation rather than preference.

**The scope question `[UBS-9]` left implicit, ruled here.** `[UBS-9]` says credits becomes a
release blocker at "the first public RC", and the project is already hosting web playtest
builds — so the trigger needed testing against reality.

> **Owner ruling (2026-08-13): the existing PWA playtest hosting is *not* public
> distribution.** It is limited distribution to the owner for playtest purposes, so the
> attribution obligation remains **scheduled, not live**, and credits stays behind the
> convoy/shop work in the queue.
>
> **The condition that ruling depends on:** the hosting genuinely stays unlisted and is not
> handed to third parties. Widening it — an open link, a store page, a public build — makes
> the obligation live immediately and moves this row to the front. Whoever widens
> distribution owns re-checking this.

### [CRD-1] What is the source of truth?

- **A — Hand-maintained screen and file.** For: simple. Against: guaranteed drift.
- **B — Structured validated notices generate both.** For: one authority. Against: schema and
  renderer work.
- **Recommendation:** B.

**Adopted as recommended (owner walk 2026-08-13).** B — structured validated notices are the single source of
truth and generate both the in-game screen and the repo file. Option A guarantees drift
between the two, and a hand-maintained legal artifact is the DoD#2 anti-pattern: a written
obligation with no check rots.

### [CRD-2] Which notice sets compose?

- **A — Every installed pack.** For: exhaustive library. Against: falsely treats packs as loaded
  together and overwhelms users.
- **B — Engine/application plus active pack and active theme.** For: matches the runtime model.
  Against: inactive-pack notices require selecting that pack or inspecting its metadata.
- **Recommendation:** B; pack-management may offer a separate per-pack notice preview.

**Adopted as recommended (owner walk 2026-08-13).** B — engine/application notices plus the **active** pack and
**active** theme. Forced by `[ICO-1..6]`: packs are never loaded together, so listing every
installed pack would assert a composition model the engine does not have. Pack management may
offer a separate per-pack notice preview for inspecting an inactive pack.

### [CRD-3] Where is Credits reachable?

- **A — Main Menu only.** For: obvious chrome location. Against: active-pack notices are harder
  to reach mid-campaign.
- **B — Main Menu and in-campaign Settings, same screen.** For: always reachable. Against:
  duplicate entry points.
- **Recommendation:** B.

**Adopted as recommended (owner walk 2026-08-13).** B — reachable from the Main Menu and from in-campaign
Settings, rendering the same screen. Active-pack notices must be reachable mid-campaign, which
is the case A cannot serve.

### [CRD-4] How does Compact navigate long notices?

- **A — One continuous scroll.** For: simplest. Against: poor return position and scanning.
- **B — Category list then entry list/detail.** For: consistent with responsive records.
  Against: an extra step.
- **Recommendation:** B; Expanded uses simultaneous list/detail.

**Adopted as recommended (owner walk 2026-08-13).** B — Compact navigates category list → entry list/detail;
Expanded shows list and detail simultaneously. This is the `[UUI-4]` list/detail/action
convention rather than a credits-specific layout, and it gives a return position that one
continuous scroll cannot.

### [CRD-5] Is search required for v1?

- **A — Yes.** For: large notice sets. Against: creates a dependency on non-modal text entry.
- **B — No; categories and deterministic sorting suffice initially.** For: keeps credits
  independent. Against: slower for extreme packs.
- **Recommendation:** B; preserve a later search seam.

**Adopted as recommended (owner walk 2026-08-13).** B — no search in v1; categories and deterministic sorting
suffice, with a search seam preserved. Deliberately keeps credits **independent of
`[NMTE-1..20]`**, which is written but unwalked — option A would make a release-blocking
legal screen depend on an unresolved text-entry design.

### [CRD-6] What may authors suppress?

- **A — Any provenance field.** For: cleaner presentation. Against: can hide licence duties.
- **B — Optional provenance narrative only; required attribution never.** For: compliant by
  construction. Against: authors have less aesthetic control.
- **Recommendation:** B.

**Adopted as recommended (owner walk 2026-08-13).** B — authors may suppress optional provenance narrative only;
**required attribution can never be suppressed**. Compliant by construction. Authors lose some
aesthetic control, which is the correct trade for a licence duty.

### [CRD-7] How are links handled?

- **A — Open directly.** For: convenient. Against: web/native availability and safety.
- **B — Display URI, copy action, and confirmed external open where supported.** For: portable
  and deliberate. Against: more controls.
- **Recommendation:** B.

**Adopted as recommended (owner walk 2026-08-13).** B — display the URI, offer a copy action, and open externally
only where supported and confirmed. Direct opening is unreliable on web and undesirable
without confirmation anywhere.

### [CRD-8] How are theme assets credited?

- **A — Fold into engine notices.** For: shorter. Against: copied Pack 0 themes lose provenance.
- **B — Theme is a distinct notice source carried when active or redistributed.** For: durable
  copying obligations. Against: another section.
- **Recommendation:** B.

**Owner ruling (2026-08-13): B — the theme is a distinct notice source, carried when active or when redistributed.**

This is the question `[UBS-9]` flagged as unanswered, and `[UUI-14]` is what makes it urgent:
Pack 0 ships the theme assets and authors are **expected to copy them** into their own packs.
Under option A that copy strands the provenance in the engine's notice set, where it no longer
describes the thing being shipped — so the copy goes out uncredited.

Making the theme its own notice source means the obligation travels with the asset and the
validator can see whether it did. Costs one more section on the screen.

### [CRD-9] What validator behavior applies?

- **A — Missing notices always warn.** For: permissive. Against: public builds can violate terms.
- **B — Draft packs warn; release-complete/public export fails when a recorded obligation lacks
  its required notice.** For: aligns severity with distribution. Against: obligations must be
  classified correctly upstream.
- **Recommendation:** B.

**Owner ruling (2026-08-13): B — draft packs warn; release-complete or public export fails when a recorded obligation lacks its required notice.**

Severity tracks distribution. An author iterating on a pack they may never distribute is not
blocked; a build that leaves the machine cannot omit a required notice.

**This has an unmet upstream dependency.** It only works if obligations are classified
correctly, and `LEG-4`'s asset audit — outstanding since 2026-07-20 — is what does that
classification. Until it lands, the validator can only fail on obligations someone has already
recorded, so a *missing* record still passes. That gap is the audit's, not the validator's,
but it should not be mistaken for coverage.

### [CRD-10] What evidence closes the feature?

- **A — Screen renders sample text.** For: easy. Against: does not prove composition or parity.
- **B — Engine-only, active-pack and active-theme fixtures; Compact/Expanded navigation;
  required-text preservation; generated-file parity; keyboard/controller/touch access.** For:
  proves the contract. Against: larger test set.
- **Recommendation:** B.

**Adopted as recommended (owner walk 2026-08-13).** B — the closing evidence is engine-only, active-pack and
active-theme fixtures; Compact and Expanded navigation; required-text preservation;
generated-file parity against `[CRD-1]`; and keyboard, controller and touch access. Rendering
sample text proves none of the composition this feature exists to get right.

## Consequences of the ruled set

1. **`LEG-3` is superseded in principle, not yet in fact.** `LEG-3` chose repo-file-only
   (`ATTRIBUTION.md`) as an interim. `[CRD-1]` makes structured notices the source of truth
   and generates *both* the screen and that file, so `ATTRIBUTION.md` becomes an output rather
   than an authority. Nothing changes until the generator exists.

2. **`LEG-4`'s asset audit is now load-bearing and still outstanding.** `[CRD-9]`'s
   release-fails severity can only fail on obligations that have been *recorded*. An asset
   whose obligation nobody classified still passes silently. The audit — open since
   2026-07-20 — is what closes that hole, and until it does, a green validator is not proof of
   compliance.

3. **Three notice sources, not two.** Engine, active pack, and **active theme** (`[CRD-8]`).
   The theme is separate specifically because `[UUI-14]` expects authors to copy Pack 0's
   theme assets into their own packs, and the obligation has to travel with the copy.

4. **Credits is deliberately independent of every unwalked register.** No search means no
   dependency on `[NMTE-1..20]` (`[CRD-5]`); `[UUI-4]`'s list/detail convention means no
   bespoke layout (`[CRD-4]`). This row can be built whenever it is scheduled, without waiting
   on anything except `LEG-4`.

5. **The deadline is conditional, and the condition is not self-enforcing.** Credits is not
   blocking today only because playtest hosting stays unlisted. That is a fact about how the
   builds are distributed, not a property of the code, so nothing will fail if it stops being
   true. See the disposition note above.
