---
Role: dated
Type: plan
Status: Snapshot of 2026-08-06, dispositioned by R1 2026-08-18 — not a live inventory
Last verified: 2026-08-30
Tracker: R1-PLAN-CORPUS-COHESION-REVIEW-2026-08-16
---

# Open Questions Inventory — 2026-08-06

> **`R1` disposition, 2026-08-18 — confirmed superseded in substance, kept as a record.** This
> document is an *index* of what was undecided on 2026-08-06, and the row that owned it
> (`GENERAL-PLANNING-SCHEDULING-2026-08-06`) was closed as superseded on 2026-08-17. It is not
> re-derived, because re-deriving a snapshot rewrites history; it is dated instead.
>
> **What has closed since, section by section:** §1's landscape-rectangle question — the one it
> called "one decision blocks half the responsive programme" — was answered by `[UUI-1]`/`[UUI-2]`
> on 2026-08-12. §3's "one thing gating the most work" rested on a claim
> (`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT` holding `SettingsManager.gd`/`SettingsScreen.gd`/`.tscn`)
> that the unified UI programme **measured as false** on 2026-08-12, and that row is now
> `completed`. §5's "twenty-plus unscheduled discussions" is exactly what the `S1` disposition
> sweep did on 2026-08-13, and the research programme it fed finished on 2026-08-16. §6's `DRC`
> line was corrected in place by `R1` on 2026-08-17. **Authority repair, 2026-08-30:** §6's
> `MRD-8`/`PER` claim was also overtaken: `MRD-8` moved into the `PER` register and the owner
> resolved `PER-13..17` on 2026-08-30. The snapshot omitted the later `SKF-1..12` packet entirely;
> that register was fully disposed on 2026-08-13 (eleven resolved, `SKF-5` closed by precedence).
>
> The one paragraph still worth reading is §5's closing ordering constraint — anything designing a
> **new screen** waits for the per-screen conversion pattern or is designed against the size
> classes from the start. That is still true, and it is now `[UUI-15]`'s discharged hold plus
> Phase 3 of [`unified_ui_programme_2026-08-12.md`](unified_ui_programme_2026-08-12.md).

A sweep of what is genuinely undecided, gathered from the tracker, the open-question
registers and a consistency pass over the plans and design docs. It is an index, not a
decision record — each entry names the row or doc that owns the answer.

## 1. The responsive UI programme — nearly closed

Sequenced in [`responsive_ui_programme_2026-08-06.md`](responsive_ui_programme_2026-08-06.md).
Every design question raised in this programme was answered on 2026-08-06. **One decision is
outstanding, and it blocks a whole half of the work.**

| | Question | Owner | Blocks |
|---|---|---|---|
| **1.1** | **The landscape game-view rectangle.** Under the dead-space rule the control region is whatever the game view leaves over; landscape's default is full bleed, so it reserves nothing. 4:3 is the widest rectangle that still fits a split keyboard — make it the default, or offer a preset list? | `MOBILE-WEB-CONTROLLER-2026-08-04` | The entire landscape keyboard |

Everything else here is scheduling rather than deciding: the screen conversions, the 26%
portrait band, and the keyboard build. The portrait keyboard is fully specified and buildable
today.

## 2. Sequenced debt — decided, but not yet safe to do

Not open questions. Recorded so a planning session does not mistake them for available work.

- **The retired 1280×720 floor is still live in code.**
  `SettingsManager.fit_content_scale_factor_for_size` hard-codes `1280.0 / 720.0`, which is
  the direct cause of the 2.7 CSS px portrait type: it snaps a 1179×2556 phone to scale 0.5.
  Against the ratified 360×640 floor the same phone resolves to 3.0 and lands in Compact at
  16 CSS px. **Flipping it early makes portrait large and broken rather than small and
  unclipped**, so it goes with the screen conversions — and `SettingsManager.gd` is claimed
  until the Windows return regardless.
- **`GDD_10_Roadmap.md` still records the retired floor** in its `UI-VIEWPORT-ASPECT` row.
  One line, blocked by `IMPL-ZERO-CONTENT-FAMILIES`' claim.
- **The touch density tokens do not survive the keyboard** (gap 8→4, gutter 16→8). Needs to
  land as a named exception or a compact token variant, not a local override.

## 3. The one thing gating the most work

`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` is display-gated on the v0.7.0 visual bundle
**and** claims `SettingsManager.gd`, `SettingsScreen.gd` and `SettingsScreen.tscn`. Closing it
releases:

- the Settings screen conversion;
- Menu Mode and information density becoming persisted settings;
- dropping `system` from the text-entry vocabulary (`TEXT-V1-S06`);
- flipping the design-floor constant above.

Four separate pieces behind one return. **A planning session should treat the Windows visual
bundle as the schedule's critical path, not as one task among many.**

## 4. Flagged `decision_required` in the tracker

| Row | Topic |
|---|---|
| `DECISION-ZERO-CONTENT-BLOCKER-GATES-2026-07-23` | Which zero-content gaps block a release |
| `DECIDE-EDITOR-CONTENT-PALETTE-2026-07-31` | Campaign editor's content palette |
| `PROVENANCE-GUI-USABILITY-REVIEW-2026-07-28` | Provenance GUI usability |
| `PACK0-LICENSING-2026-07-19` | `in_progress`, decision-required phase |
| `PACKFE-LICENSING-2026-07-19` | `in_review`, decision-required phase |

Licensing is worth a specific look: `LEG-1..5` is marked RESOLVED, but the record notes the
**gate was not cleared** — the LEG-2 remedy and the LEG-4 asset audit are still outstanding.
A resolved register and an uncleared gate are easy to confuse when scheduling.

## 5. Design discussions not yet held

Twenty-plus rows sit in `1-planning-discussion`. They are not blocked; nobody has scheduled
them. Grouped by what a single session could close together:

- **Combat and unit UX:** `DISCUSS-COMBAT-ACTIONS-UX`, `DISCUSS-SKILL-STATUS-FEEDBACK`,
  `DISCUSS-DIFFICULTY-DEATH-UX`, `DISCUSS-SUPPORT-UX`, `DISCUSS-AVATAR-MYUNIT-UX`
- **Recruitment and story:** `DISCUSS-RECRUIT-CAPTURE-UX`, `DISCUSS-DIALOGUE-UX`,
  `DESIGN-ACTIVITY-EXIT-ROLLBACK`
- **Structure and cadence:** `DESIGN-PREP-HUB-STRUCTURE`, `DESIGN-OVERWORLD-CADENCE`
- **Editor:** `DESIGN-CAMPAIGN-EDITOR-UX`, `DISCUSS-CAMPAIGN-EDITOR-UI`,
  `DECIDE-EDITOR-CONTENT-PALETTE`
- **Sync and backup:** `INVESTIGATE-CLOUD-SYNC-THIRD-PARTY`,
  `INVESTIGATE-FIRST-PARTY-SYNC-SERVER`, `BACKLOG-FULL-LIBRARY-BACKUP`,
  `BACKLOG-RUNSAVE-SEARCH-ARCHIVE`, `BACKLOG-BRANDED-EXTENSIONS-OS-ASSOCIATION`
- **Engine seams:** `ENGINE-PREDICATE-UNMET-REASON`, `ENGINE-ITEM-HELD-PREDICATE`,
  `IMPL-ASYNC-PROGRESS-CANCEL`
- **Other:** `DISCUSS-PVP-MODE-UX`, `DISCUSS-MINIGAMES-SEAM-UX`,
  `BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND` (display-gated — it needs a real pad, so it
  belongs to the Windows bundle rather than a discussion session)

**Note the ordering constraint the redesign creates:** `DESIGN-PREP-HUB-STRUCTURE`,
`DISCUSS-CAMPAIGN-EDITOR-UI` and the shop/forging rows were originally sequenced *behind*
viewport anchoring so their screens would not be authored twice. That reason still holds
under the redesign — anything that designs a **new screen** should either wait for the
per-screen conversion pattern to be established or be designed against the size classes from
the start.

## 6. Registers still marked OPEN

- ~~`DRC-1..33` — dialogue, recruitment and capture research questions~~ **RESOLVED 2026-08-13**,
  fully walked across four sittings. Corrected 2026-08-17 by `R1`; the correction was assigned to
  `S1`, which is marked complete and never made it.
- ~~`MRD-1..8` — map readability~~ **RESOLVED.** `MRD-8` was absorbed into `PER-13..17`; the
  earlier claim that the perception-masking authority did not exist was wrong.
- `PER-1..17` — **RESOLVED 2026-08-30.** `PER-1..12` were already resolved on 2026-06-27;
  the owner then resolved the absorbed path-execution boundary as `PER-13..17`.
- `SKF-1..12` — **RESOLVED 2026-08-13** (eleven owner rulings; `SKF-5` closed by precedence
  against `[CFB-1]`). This later packet was absent from the 2026-08-06 snapshot.

## 7. Stale-row hygiene

`check_tasks.py` reports nine rows with no update in 14 days, all `planned` and all in §5
above. They are stale in the "nobody has touched this" sense rather than the "this is rotting"
sense — but a planning session is the right moment to either schedule or retire them.
