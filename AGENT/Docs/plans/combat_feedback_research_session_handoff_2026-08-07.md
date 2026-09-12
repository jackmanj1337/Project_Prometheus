---
Role: dated
---

# Next-session handoff — the combat feedback research trio — 2026-08-07

Status: Active. Opens the three planning/discussion rows selected on 2026-08-07:
skill/status feedback, on-map combat actions UX, and difficulty/death-mode UX.

Last verified: 2026-08-07

Tracker: `DISCUSS-SKILL-STATUS-FEEDBACK-2026-07-23`, `DISCUSS-COMBAT-ACTIONS-UX-2026-07-24`,
`DISCUSS-DIFFICULTY-DEATH-UX-2026-07-23`.
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)

## The one thing to get right

**These three converge on a single shared feedback vocabulary, and writing them as three
independent research docs would produce three competing vocabularies for the same thing.**

`DISCUSS-COMBAT-ACTIONS-UX`'s own trigger already says so — *"Overlaps
DISCUSS-SKILL-STATUS-FEEDBACK's feedback vocabulary."* All three have to answer the same
underlying question in different costumes: **when the engine does something to a unit that
the player did not directly command, how does the player learn that it happened, why, and
to whom?** A skill activating, a counter firing, an immunity absorbing, a gambit landing, a
rescue resolving, a Phoenix revival — the same shape.

That is the competing-authority anti-pattern this codebase keeps paying for: terrain's six
tables owning one vocabulary, the two range authorities on weapons, the two claim models on
commits. Three independently-authored feedback vocabularies would be the next instance.

**Recommended shape:** one shared research doc establishing the vocabulary and the
interaction skeleton, then three question packets on top of it — not three parallel docs.

## What is actually open — narrower than the row titles suggest

Every *mechanical* register feeding these three is already RESOLVED. The open work is the
presentation layer over settled rules. Treat these as **inputs, not questions**, and do not
reopen them:

| Register | Covers | State |
|---|---|---|
| `SKL-1..6` | Skill model: personal / class-level / granted | RESOLVED 2026-06-23l |
| `LDC-1..9` | Loadout cap (skills, styles, granted sources) | RESOLVED 2026-06-27d |
| `DIF-1..7` | Casual/Phoenix + the difficulty axis, composing the AIP difficulty overlay | RESOLVED 2026-06-27d |
| `DTH-1..12` | Death-inventory disposition | RESOLVED 2026-06-27d |
| `STY-1..17` | Source + Style: combat arts, gambits, capture | RESOLVED 2026-06-24 |
| `DSP-1..17` | Displacement & carry: rescue, shove/swap/pivot | RESOLVED 2026-06-25 |
| `BAT-1..16` | Battalions / attached augments | RESOLVED 2026-06-25k, -27d |
| `AGT`, `SMV` | Action grant (dancer/refresh), secondary movement | RESOLVED |
| `RDR`, `CVR`, `RCT` | Redirect / cover / reaction interceptor family | RESOLVED 2026-06-26 |
| `VAL-1..13` | AI combat valuation | RESOLVED 2026-06-27 |

Per-row scope, read from the rows' own triggers rather than their titles:

- **`DISCUSS-SKILL-STATUS-FEEDBACK`** — the feedback vocabulary itself: activation, passive,
  counter, immunity, failure, attribution, and the combat log. This is the row that should
  own the shared doc.
- **`DISCUSS-COMBAT-ACTIONS-UX`** — targeting/selection/feedback UX for a named family whose
  mechanics are resolved: combat arts, gambits, reposition/shove/swap/pivot, dancer/refresh,
  secondary movement, rescue carry/drop, utility staves (Warp/Rescue/Hammerne). The row
  permits splitting per-action when picked up; each is named so none is lost.
- **`DISCUSS-DIFFICULTY-DEATH-UX`** — narrower than it reads: New Game **placement, copy,
  defaults, warnings, locked profile values, and mutability**. The modes themselves are
  `DIF-1..7`. `CampaignRules` already holds the sibling knobs (`leveling_method`,
  `max_skills`, `max_inventory`, `exp_gaining_factions`), which is where the new ones land.

## Substrate worth knowing before the session

- Death handling today is one binary: `CampaignRules.permadeath_enabled`, picked on the New
  Game screen. On → `data.is_incapacitated`, skipped in future deployment
  (`GameMap.gd:191`). Off → the unit returns intact. So **"permadeath off" is already a
  crude Casual mode and Phoenix does not exist** — the UX row is designing the surface over
  a substrate that is half-present.
- Difficulty must **compose** the AI composition engine's difficulty overlay (`AIP`), not
  fork a parallel AI-scaling system.
- The skills the feedback vocabulary describes are currently **inert under any pack** — see
  [`zero_content_slice2_closeout_and_skills_schedule_2026-08-07.md`](zero_content_slice2_closeout_and_skills_schedule_2026-08-07.md).
  That does not block this research (it is design, not build), but any claim about what a
  player observes today must not be taken from the v0.7.0 round, which was played with every
  skill inert.

## House pattern for these docs

Each row's trigger asks for the same deliverable, and there are worked examples to copy:

1. A **research doc** under `AGENT/Docs/design/` — see
   `campaign_library_ux_research_2026-07-23.md`,
   `ui_ux_architecture_research_and_questions_2026-07-24.md`, and
   `text_entry_strategy_research_and_questions_2026-07-26.md`.
2. An **owner-questions packet** with stable ids, walked branch-by-branch, decisions
   recorded as they are taken — the `CL-*` / `TEXT-*` / `CSA-*` pattern.
3. Register the new prefix in `AGENT/Docs/REGISTERS.md` (generated — run
   `python3 AGENT/Docs/gen_docs_index.py` and commit in the same change).

**Proposed ids.** Taken prefixes are listed in `REGISTERS.md`; these four are free as of
2026-08-07: `CFB` (the shared combat-feedback vocabulary — the doc all three read),
`SKF` (skill/status feedback specifics), `CAU` (combat actions UX),
`DUX` (difficulty/death New Game surface).

## Suggested order for the session

1. Write the shared `CFB` research doc first — the event taxonomy, who is told, when, where
   it surfaces (floating text, combat log, banner, unit panel), and what attribution a
   player is owed. Nothing else can be answered consistently before this.
2. Then the three packets, each referencing `CFB` rather than restating it.
3. `DUX` is the smallest and the most nearly buildable; `CAU` is the largest and is the one
   explicitly allowed to split per-action.

Do **not** try to close all three in one session. The rows say "discussed as time allows"
and the campaign-library precedent took several sittings.

## Settle in the session: a dependency edge that points the wrong way

`DISCUSS-SKILL-STATUS-FEEDBACK-2026-07-23` depends on `B5-SKILLS-CONDITIONS-2026-07-23`,
which is `5-backlog` and awaiting an owner go/no-go on whether to build the M9 skill and
condition model at all.

**That edge contradicts the row's own trigger**, which reads: *"Define a consistent feedback
vocabulary and interaction sheet **before** broad per-skill/status content implementation."*
The research is meant to precede the build, so the design row should not be gated on the
build row. Left as-is it reads as blocked when it is not — nothing about writing the `CFB`
vocabulary needs M9 to exist.

Deliberately not rewired in advance, because the fix touches a row that is itself pending an
owner decision. Settle it as part of this session, once the research has shown what the
vocabulary actually needs from the skill model:

- **Likely right:** drop the edge, and if an ordering statement is still wanted, add the
  reverse one — `B5-SKILLS-CONDITIONS` depends on `DISCUSS-SKILL-STATUS-FEEDBACK`. Checked
  2026-08-07: reversing it creates no cycle (`B5` → `DISCUSS-SKILL` → nothing, and
  `DISCUSS-COMBAT-ACTIONS-UX` → `DISCUSS-SKILL-STATUS-FEEDBACK` stays consistent).
- **Possible instead:** if the research concludes the vocabulary genuinely cannot be settled
  without the M9 model decided first, keep the edge and say so on the row — but say it
  explicitly rather than leaving it as an accident.

Note `track.py update` has no `--depends-on` and cannot remove a dependency, so whichever
way it goes, the edit is a hand-edit on the docs line: match on `task_id`, never a string
substitution, and write with `indent=2, ensure_ascii=False`.
