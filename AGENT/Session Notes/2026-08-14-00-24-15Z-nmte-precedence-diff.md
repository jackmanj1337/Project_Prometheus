# Session Note - 2026-08-14-00-24-15Z

## Branch context

- Branch: `agent/integration` (plan/design docs live on the docs line)
- Base branch: `agent/integration`
- Base SHA: `711d3cbc` (tip when the session opened)
- Coordination Work ID: `S3-NMTE-PRECEDENCE-DIFF-2026-08-14`

## What was done

**`S3` of the research sequencing plan — the `NMTE-1..20` precedence diff — is written, and it
is the fifth `DOC-014` check in the series.** The owner chose to run the research and
discussion schedule before the `R1` plan-corpus cohesion review, so `R1` is deferred, not
skipped. `NMTE` is `UBS-3`, the last live cross-cutting gate on the unbuilt-screen agenda, and
the last unwalked packet of the written set.

`AGENT/Docs/design/nmte_precedence_diff_2026-08-14.md`. Sources diffed: `TEXT-01..15` across
all three text-entry documents, the Compact mobile design ratified 2026-08-06, `EPUX-15`,
`UUI-11`, `L10N-1..18`, `RPD-15` as promoted, `CEUI`'s held-search clause, and the built code.

**Five for five: the packet cites no ratified id.** Same headline as `RPD`, with a difference
that changes the verdict — **`NMTE`'s research is accurately grounded in the built code**. It
read `TextEntryService`, `TextEntrySession`, `FileDialogInputGuard`, the modal overlay and
`ResponsiveLayout` correctly, and knows about the OS-keyboard suppression in prose. What it
missed is the *decision corpus*: fifteen ratified `TEXT` rulings and the four registers ruled
either side of it.

**The finding is a collision, not an omission.** The Compact design ratified 2026-08-06 says,
of the keyboard taking the control band, *"the controller is simply unavailable while typing,
**which is acceptable because a text session is modal**."* `NMTE` exists to design non-modal
text entry, and `NMTE-3`, `NMTE-9` and `NMTE-12` are all written as though modality were an
open choice at every size class. Both rulings can stand — Compact's is arithmetic (240px of
content at 360×640) and the landscape split keeps the field visible in place — but **modality
is size-class-conditional and Compact is already ruled**, and nobody has said so. Walking
`NMTE-12`'s recommendation B as written would ratify something unachievable in Compact.

**Disposition of the twenty:** three closed by precedence and not to be walked — `NMTE-4` (the
handoff mechanism *and* its recommended default are built as `dismissal_policy`), `NMTE-10`
(`TEXT-01`/`TEXT-05`/`TEXT-14`/`TEXT-14a`, and `TextEntryRegistry.resolve()` implements the
ruling line for line), `NMTE-16` (`TEXT-06` as revised 2026-07-30 is a ratified rule carrying a
DoD#2 check, with `EPUX-15` as its worked example). Six narrowed, three live conflicts, two
promoted, six unaffected.

**The cleanest moved assumption:** `NMTE-11` asks how native keyboard height should affect
layout. **The project deliberately has no native keyboard** — `export_presets.cfg:110` sets
`html/experimental_virtual_keyboard=false`, `test_web_export_preset.gd` guards it, and `grep
virtual_keyboard scripts/` returns only that test's comments. The question descends from a note
added to `IMPL-REFERENCE-COMPENDIUM` on 2026-07-31, six days *before* the ruling that removed
the mechanism it asks about. Only the available-content-rect signal survives.

**Two questions the packet never asks, and both should go first.** (1) *Is non-modal filtering
in v1 at all?* Every named consumer is cut, backlogged or unwalked — `EPUX-15` cut free-text
search from v1 by owner ruling, `IMPL-REFERENCE-COMPENDIUM` is phase `5-backlog`, `CEUI` is
unwalked with search explicitly held for this packet. That is not an argument against walking
it, but it decides how much of `NMTE-11`/`12`/`13` is worth deciding today. (2) `NMTE-17` cites
"the non-modal status-message model" as established — **it is not**; there is no announcement,
live-region or screen-reader vocabulary anywhere in the corpus, and answering it as written
means inventing a shell-wide accessibility model inside a text-entry walk. That is the shape
`RPD-15` was promoted out of prep for.

**Three propagation debts found; two paid this session.**

1. **A live, user-visible defect.** The 2026-08-06 ruling said *"drop `system`"* from Settings
   while keeping the registry constant. The constant was kept; **the Settings row never was**.
   Traced through the built path: `_configured_mode()` returns `system` → `resolve()` finds no
   backend and degrades to `hardware` → `TextEntryOverlay.gd:62` hides the key grid. On a touch
   device with the OS keyboard suppressed, selecting **"System Keyboard"** gave the player a
   text field with no way to type. Fixed with its guard test.
2. **`NMTE`'s own `Tracker:` row was stale twice over.**
   `DESIGN-TEXT-ENTRY-SERVICE-2026-07-31` still says "deliberately not built yet" (the service
   is an autoload at `project.godot:35`) and still describes
   `FileDialogInputGuard._resolved_text_entry_mode()` as its problem — that function no longer
   exists. Corrected in place, with the thing that *is* outstanding recorded instead: **the
   service has zero production callers**, so the one-owner-of-printable-input ruling is built
   but not adopted.
3. **Unpaid, and already owed elsewhere:** `responsive_ui_redesign_2026-08-06.md`'s `1.3×`
   figure against `L10N-7`'s ratified 1.4×. Left with `L10N`, which already recorded it.

Nothing was reopened. The register carries a READ FIRST banner naming the three closed
questions so a walk does not reintroduce them.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`, claimed as we went.

- `0d69e87a` writes the precedence diff, banners the register, and registers the doc on the
  control plane (432 insertions across four files).
- `f7f29aca` drops the `system` row from Settings and guards it — debt 1 above.

Tracker updates went to the docs line (`agent/staging-area`) through
`scripts/agent-update-task.sh`: `S3` registered and closed, and
`DESIGN-TEXT-ENTRY-SERVICE-2026-07-31` corrected.

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS**, all 44 checks. One earned its keep:
  `[active-doc-ownership]` refused the diff until it was named on the control plane, which is
  the check that stops a design doc from existing outside the navigation tables.
- `python3 AGENT/Docs/gen_docs_index.py` — regenerated; `INDEX.md` gained the new design doc.
- `bash run_tests.sh` — **all suites green**, run in full before the code commit.
  `test_settings_screen: 33 passed`, `test_text_entry: 24 passed`,
  `test_text_entry_service: 36 passed`, `test_web_export_preset: 3 passed`.
- `bash scripts/ci/check_gdscript_style.sh --fix` — PASS, 320 files unchanged.
- `python3 scripts/ci/check_session_commit_claims.py --fix` — claimed after each commit; 772
  post-bootstrap commits audited, PASS.

## Next

**`S4` — the `NMTE-1..20` owner walk — is the next session**, and the diff's §7 is its running
order: the v1 scope question first, the modality question second, then the four genuinely open
questions (`NMTE-2`, `NMTE-14`, `NMTE-19`, `NMTE-20`), then the narrowed residues. Do not walk
`NMTE-4`, `NMTE-10` or `NMTE-16`. Spin `NMTE-17`'s announcement half out as a shell-level row
rather than answering it in a text-entry walk.

`NMTE` resolving lifts the last `UBS` gate blocking two downstream sessions — `S7`'s compendium
packet and `CEUI`'s search rows.

**`R1` is deferred, not cancelled.** The plan-corpus cohesion review still stands between the
schedule and any build work: `B4-PREP-MAP-DEPLOYMENT-2026-07-22` cites a decision source
predating `RPD-1..18`, and the merged `DRC-V1-S00..S11` + `PREP-V1-S01..S08` build order shares
four primitives with no ordering between them. Picking up a build row before `R1` risks
building `EPUX-24`'s transaction core twice.
