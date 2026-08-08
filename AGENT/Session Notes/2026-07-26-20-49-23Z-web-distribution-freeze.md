# Session Note - 2026-07-26 (web distribution freeze)

Single-purpose branch carrying one GDD change from the licensing/content-architecture
close-out. The rest of that thread is tracker-only.

## What was done

`GDD_00_Overview.md` Platform Targets said Web was a **"Playtest distribution channel
and slice-first portfolio demo target"**. The 2026-07-26 content directive routes owner
playtests onto `Campaign_Pack_FE` content, whose ratified rule is **never public, never
in a shipped build** — a rule that exists because a public *build* redistributes FE art
just as a public repo does. A hosted web playtest build is public, so the two statements
could not both hold.

Owner ruling: **freeze web distribution** until the data extraction completes and
`FE-EXPORT-GUARD` enforces. Recorded in the GDD rather than only in the tracker because
the document was actively advertising web as a live playtest channel.

The scope is narrow on purpose:

- **Frozen** — distributing any web build, playtest or demo.
- **Not frozen** — building a web export locally to test. Nothing is published, so
  `EXP-UI-WEB-PLAYWRIGHT` and ordinary development are unaffected.
- **Lift condition** — extraction complete **and** the guard enforcing, at which point
  the guard is the control and the blanket freeze is redundant.

## Commits claimed

- `8aa23f49b1280b1635d10e6f3fb259b4cf5ca41f` — gdd: freeze web build distribution until extraction and the FE guard land

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS** (42 checks).
- Pre-commit: gdformat/gdlint PASS, scene-integrity PASS, evidence-matrices PASS.
  Godot suite skipped — docs-only.

## Next

**Merge note:** `agent/from-integration/text-entry-governance` also edits `GDD_00`,
adding a Deck-OSK release gate immediately after this same table. Both are additive
release-gate entries in the same region, so expect a trivial conflict when the branches
meet — **keep both sections.**

Tracker row `FREEZE-WEB-DISTRIBUTION-2026-07-26` closes when the lift condition is met.
