# Session Note - 2026-08-06-21-14-04Z

## Branch context

- Branch: `agent/integration`
- Base branch: `agent/integration`
- Base SHA: `a9d7ee83`
- Coordination Work ID: `SMALL-SCREEN-UI-REDESIGN-2026-08-05`

## What was done

A consistency pass over every note, plan and doc the day's decisions touched, then an
open-questions sweep to open the next session.

**Real drift found, not just formatting.** The redesign design doc's Sequencing section had
gone stale in four ways at once: it still told the reader to "pick over" the viewport-anchoring
branch (which is an ancestor of integration — there was never anything to salvage), it did not
mark steps 1 and 2 done, and it ordered **Settings second** in the screen conversions when that
screen is now late because `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` claims it. Anyone
following that doc would have started the wrong screen and then gone looking for a branch that
did not need salvaging.

Fixed by making the programme plan the **single owner of ordering** and saying so in both
files: the plan is right about order, the design docs are right about why. The design doc keeps
the reasons and now carries the correction inline rather than the wrong instruction.

**A live contradiction inside one file.** `GDD_07_UI_UX.md` says the design floor is superseded
by 360×640, and thirty lines earlier says the mobile default is "fitted to the 1280×720 design
floor". Both were accurate — about different things — which is what made it worth chasing:

`SettingsManager.fit_content_scale_factor_for_size` hard-codes `1280.0 / 720.0`, and **that
constant is the direct cause of the measured 2.7 CSS px portrait type.** A 1179×2556 phone
fitted to 1280×720 snaps to scale 0.5 → a 2358×5112 logical viewport. Against the ratified
360×640 floor the same phone resolves to 3.0 → 393×852 → Compact at 16 CSS px.

It is deliberately **not** flipped. Before the screen conversions land it would make portrait
large and broken instead of small and unclipped, and `SettingsManager.gd` is claimed until the
Windows return anyway. Recorded as sequenced debt in three places so it is found on purpose
rather than rediscovered.

**The controller plan still described an overlay model.** Amended with the dead-space rule,
including the reconciliation that matters: `Fullscreen Overlay` stays valid as the player's
opt-in (the occlusion decision is "player choice, default never"), and the editor's
controller-collision guides are still useful — they simply only have work to do once a player
has opted into overlapping, because under the derived model a collision is impossible.

**Open-questions inventory** written as `AGENT/Docs/plans/open_questions_inventory_2026-08-06.md`.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

## Gates

- `python3 AGENT/Docs/check_docs.py` — PASS, 43 checks (after `gen_docs_index.py`).
- `bash run_tests.sh` — **PASS, 131 suites.**
- `python3 coordination/check_tasks.py` — OK, 345 rows, no conflicts.
- Claim check before each edit: `GDD_07_UI_UX.md` and the v0.7.0 decision sheet were free;
  `GDD_Feature_Index.md`, `project_control_plane_2026-06-29.md` and `GDD_10_Roadmap.md` are
  claimed by `IMPL-ZERO-CONTENT-FAMILIES` and were left alone.

## Next

**General planning and scheduling.** Start from the open-questions inventory. Its three
findings worth carrying into that session:

1. **One decision blocks a whole half of the responsive programme** — the landscape game-view
   rectangle, on `MOBILE-WEB-CONTROLLER-2026-08-04`. Everything else in the programme is
   scheduling, not deciding.
2. **The Windows visual bundle is the schedule's critical path, not one task among many.**
   `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` is display-gated *and* claims the Settings
   files, so closing it releases four separate pieces of work.
3. **Twenty-plus design discussions are unscheduled rather than blocked**, and the inventory
   groups them by what one session could close together. The old "sequence new screens behind
   viewport anchoring" constraint still applies in substance — anything designing a new screen
   should be designed against the size classes rather than authored twice.

A tracker-hygiene note for the same session: nine rows are stale at 14+ days, all `planned`,
all in that discussion set. Schedule or retire.
