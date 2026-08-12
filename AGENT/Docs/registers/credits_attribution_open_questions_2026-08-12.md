---
Type: register
Status: OPEN — research prepared, owner walk not started
Last verified: 2026-08-12
Register: CRD-1..10
Tracker: LEG-INGAME-ATTRIBUTION-2026-07-20
---

# Credits and Attribution — Owner Questions

Research: [Credits and Attribution](../design/credits_attribution_comparative_research_2026-08-12.md)

### [CRD-1] What is the source of truth?

- **A — Hand-maintained screen and file.** For: simple. Against: guaranteed drift.
- **B — Structured validated notices generate both.** For: one authority. Against: schema and
  renderer work.
- **Recommendation:** B.

### [CRD-2] Which notice sets compose?

- **A — Every installed pack.** For: exhaustive library. Against: falsely treats packs as loaded
  together and overwhelms users.
- **B — Engine/application plus active pack and active theme.** For: matches the runtime model.
  Against: inactive-pack notices require selecting that pack or inspecting its metadata.
- **Recommendation:** B; pack-management may offer a separate per-pack notice preview.

### [CRD-3] Where is Credits reachable?

- **A — Main Menu only.** For: obvious chrome location. Against: active-pack notices are harder
  to reach mid-campaign.
- **B — Main Menu and in-campaign Settings, same screen.** For: always reachable. Against:
  duplicate entry points.
- **Recommendation:** B.

### [CRD-4] How does Compact navigate long notices?

- **A — One continuous scroll.** For: simplest. Against: poor return position and scanning.
- **B — Category list then entry list/detail.** For: consistent with responsive records.
  Against: an extra step.
- **Recommendation:** B; Expanded uses simultaneous list/detail.

### [CRD-5] Is search required for v1?

- **A — Yes.** For: large notice sets. Against: creates a dependency on non-modal text entry.
- **B — No; categories and deterministic sorting suffice initially.** For: keeps credits
  independent. Against: slower for extreme packs.
- **Recommendation:** B; preserve a later search seam.

### [CRD-6] What may authors suppress?

- **A — Any provenance field.** For: cleaner presentation. Against: can hide licence duties.
- **B — Optional provenance narrative only; required attribution never.** For: compliant by
  construction. Against: authors have less aesthetic control.
- **Recommendation:** B.

### [CRD-7] How are links handled?

- **A — Open directly.** For: convenient. Against: web/native availability and safety.
- **B — Display URI, copy action, and confirmed external open where supported.** For: portable
  and deliberate. Against: more controls.
- **Recommendation:** B.

### [CRD-8] How are theme assets credited?

- **A — Fold into engine notices.** For: shorter. Against: copied Pack 0 themes lose provenance.
- **B — Theme is a distinct notice source carried when active or redistributed.** For: durable
  copying obligations. Against: another section.
- **Recommendation:** B.

### [CRD-9] What validator behavior applies?

- **A — Missing notices always warn.** For: permissive. Against: public builds can violate terms.
- **B — Draft packs warn; release-complete/public export fails when a recorded obligation lacks
  its required notice.** For: aligns severity with distribution. Against: obligations must be
  classified correctly upstream.
- **Recommendation:** B.

### [CRD-10] What evidence closes the feature?

- **A — Screen renders sample text.** For: easy. Against: does not prove composition or parity.
- **B — Engine-only, active-pack and active-theme fixtures; Compact/Expanded navigation;
  required-text preservation; generated-file parity; keyboard/controller/touch access.** For:
  proves the contract. Against: larger test set.
- **Recommendation:** B.
