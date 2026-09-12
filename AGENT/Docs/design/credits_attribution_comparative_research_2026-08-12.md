---
Role: dated
Type: design
Status: Research recorded; owner questions open
Last verified: 2026-08-12
Tracker: LEG-INGAME-ATTRIBUTION-2026-07-20
---

# Credits and Attribution — Comparative Research

## Boundary

This packet designs the always-reachable player-facing notices surface. It does not determine
whether an asset's licence is valid; provenance and release validation remain upstream.

Godot is MIT-licensed and its guidance requires projects to preserve its licence and remember
third-party notices for assets such as textures, music and fonts. That guidance is not legal
advice, so the design must carry recorded obligations rather than attempt to infer law at
runtime. Source: [Godot: Complying with licenses](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html).

Exactly one self-contained campaign pack is active, so the surface composes two sets—not an
installed-library union: engine/application notices plus the active pack's notices. Chrome
credits remain reachable without a pack. Required attribution is non-suppressible even when
the pack chooses a minimal provenance profile.

## Recommendation

Provide a searchable-but-not-required two-level screen: categories and entries on wide
layouts, category page then entries on Compact. Show engine/application, active campaign,
theme and licences as distinct sections. Render structured records with verbatim required
notice text and optional source links/copy actions. Generate both the in-game view and
`ATTRIBUTION.md` from one validated notice model so they cannot drift.

Owner decisions are `CRD-1..10` in the companion register.
