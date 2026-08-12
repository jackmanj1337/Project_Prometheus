---
Type: register
Status: OPEN — agenda prepared 2026-08-12, no session yet held
Last verified: 2026-08-12
Register: UBS-1..9
Tracker: UNIFIED-UI-PROGRAMME-2026-08-12
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Unbuilt Screens — Research and Question Agenda

**Why this exists.** `[UUI-15]` holds every unbuilt screen out of the wireframe album until
its design questions are answered. Drawing them first would manufacture decisions that
deserve an owner walk, and the album's whole value is that it is drawn to ratified answers.
This document is the list of sessions to run and what each has to settle before a wireframe
can be drawn.

**What it is not.** It does not re-derive anything already decided. `UI-ARCH-01..06`, the
interaction vocabulary, `[MCH-1..8]`, `[PVP-1..8]`, `[ICO-1..6]` and the prep-hub structure
are all accepted; each session starts from them.

**The pattern every one of these rows already asks for** — a campaign-library-style research
doc plus an owner-questions packet with stable ids, then a branch-by-branch walk recording
decisions — is the format. Nothing here invents a new process.

---

## The finding that should shape the schedule

**Several of these sessions converge on the same vocabulary, and running them independently
would produce competing answers to one question.** `DISCUSS-DIFFICULTY-DEATH-UX`'s own
reference already records this for the combat-feedback trio: three independent research docs
would give three vocabularies for *"when the engine does something to a unit the player did
not command, how does the player learn that it happened, and why."*

The same shape appears twice more:

- **Shop, convoy and forge are one transaction surface.** All three quote a cost, reserve,
  commit or refund through the same live `ResourceLedger`, and all three need an item
  selector. Designing them separately produces three selectors.
- **Compendium search, campaign-editor search and any future filter are one text-entry
  problem.** The compendium's non-modal search field is the **first text field in the
  program that is not inside a modal FileDialog** — which is what makes it the trigger for
  `DESIGN-TEXT-ENTRY-SERVICE-2026-07-31`: arbitration (two fields must not both drive one
  on-screen keyboard) and OS-keyboard lifecycle (show/hide plus height, so a results list
  resizes). No `virtual_keyboard` handling exists anywhere in `scripts/` today.

So the sessions are grouped below by shared vocabulary, not by screen.

---

## Cross-cutting questions — answer once, before any group

These four are inputs to several sessions. Answering them inside one session and not the
others is how the vocabularies diverge.

### [UBS-1] The engine-action feedback vocabulary

When the engine does something to a unit the player did not command — a skill procs, a
status ticks, a support bonus applies, a death triggers — how does the player learn *that it
happened*, *why*, and *to whom*? Feeds `DISCUSS-DIFFICULTY-DEATH-UX`,
`DISCUSS-SKILL-STATUS-FEEDBACK`, `DISCUSS-SUPPORT-UX` and `DISCUSS-COMBAT-ACTIONS-UX`.
Handoff already written:
[`combat_feedback_research_session_handoff_2026-08-07.md`](../plans/combat_feedback_research_session_handoff_2026-08-07.md).

### [UBS-2] The transaction surface

One quote → reserve → commit → refund presentation shared by shop, convoy and forge, over
the live `ResourceLedger` / `CostSpec` / `ResourceTransaction` spine and the single
`party_gold` wallet. Includes the shared item selector — the convoy plan's Slice 4 already
specifies "a pure `PanelSelector` paired with the shop plan's selector UX", so the pairing
is intended and just needs designing once.

### [UBS-3] Non-modal text entry

Arbitration and OS-keyboard lifecycle for a search field that is not inside a modal.
Blocks the compendium and the campaign editor. Settle
`DESIGN-TEXT-ENTRY-SERVICE-2026-07-31`'s seam before either is drawn.

### [UBS-4] Where dialogue sits relative to the control region

`[UUI-16]` puts dialogue in pack-themed territory and `[UUI-5]` bounds modals to the game
view — but dialogue is not a modal and not a HUD panel, and nothing has said which it is. In
Compact the answer decides whether a dialogue box eats the map, the control band, or
neither. This is the one cross-cutting question with **no existing row that owns it**.

---

## The sessions

### [UBS-5] Dialogue presentation — `DISCUSS-DIALOGUE-UX-2026-07-23` *(in_review)*

The furthest along; a research doc and questions packet are the stated first deliverable.

**Must settle before a wireframe:** box placement and height at each size class; speaker
name and portrait treatment given that images are *always present, never informative*;
choice list presentation and how it inherits the ~4-row Compact budget; the backlog
surface; skip and auto controls in touch mode where there is no key to hold; input
arbitration against the control region; and the save-boundary spec — what a save taken
mid-conversation restores to. Plus `[UBS-4]`.

### [UBS-6] The transaction group — `B4-SHOP-ECONOMY` + `B4-CONVOY`

Sequence: convoy first (items need a home before they can be bought), then shop.

**Must settle:** the shared selector's shape at Compact, where a list *is* the screen;
convoy capacity presentation and the key-items exemption (`CNV-2`, `CEX-16`); the `SHP-6`
sell-price model, resolved in session notes but never built or drawn; refresh cadence; and
how a reserved-but-uncommitted transaction is shown if the player backs out. Code foothold:
`SaveData.gd:271-279` already persists `party.convoy.entries` with a malformed→legacy-items
fallback, but no `ConvoyService` and no UI exist. `TileActions.gd` declares `shop` as a
reserved placeholder action.

### [UBS-7] Reference compendium — `IMPL-REFERENCE-COMPENDIUM`

**Blocked on `[UBS-3]`.** Native search, category, history and deep-link UI — no Markdown
parsing, no embedded browser.

**Must settle:** search field placement and the results-list resize behaviour when a
keyboard opens; category navigation at Compact; history and deep-link affordances; and
whether the compendium is chrome or pack-themed. `[UUI-16]` does not name it, and the
argument runs both ways — it describes pack content, but it is reachable outside a campaign.

### [UBS-8] Campaign editor UI — `DISCUSS-CAMPAIGN-EDITOR-UI` + `DESIGN-CAMPAIGN-EDITOR-UX`

Owner-gated: *"talk UI before it gets built, and that applies to the whole campaign editor,
not just the asset manager."*

**Already settled, do not re-open:** distribution (full integration in all builds,
runtime-gated, OR-warning), the author/player boundary, and — new on 2026-08-12 — that the
editor is **chrome-themed and shares its theme with the Main Menu, pack management and
Campaign Library** (`[UUI-14]`).

**Must settle:** panel layout for a desktop-first mouse+keyboard tool; authoring workflows;
the encounter/balance test environment and its own fixtures, which are explicitly *not* the
player save model; fixture generation; developer-mode surfaces (`CL-ADV-01` unpacked packs,
`CL-ADV-02` deep author validator); the non-blocking author version-bump note
(`CL-ADV-03`); and the asset-manager surfaces against `CSA-11`, `CSA-17`, `CSA-18`. It
should adopt the `UUI-4` list/detail/action components rather than growing its own.

**Note the inversion:** the 2026-08-10 palette decision makes the editor the *first*
consumer of the `[UUI-13]` role vocabulary, because it generates one flat RGBA panel per
role for a new pack. If the editor cannot enumerate the roles well enough to generate a
panel for each, the role list is underspecified — which is a free consistency check on
`[UUI-13]`.

### [UBS-9] In-game credits — `LEG-INGAME-ATTRIBUTION-2026-07-20`

Smallest of the set and the only one with a hard deadline: `LEG-3` chose repo-file-only
(`ATTRIBUTION.md`) for now, but Godot ships under MIT and most asset licences require
attribution be **shown to users**, not merely recorded in a repo file. It becomes a
**release blocker at the first public RC**.

**Must settle:** scrolling versus paged presentation; how pack-supplied attribution composes
with engine attribution given one pack is active at a time; and whether the shipped theme
assets published through Pack 0 (`[UUI-14]`) need their own attribution entry — they will,
if authors are copying them into packs.

---

## Deliberately deferred, not scheduled

These need the same treatment eventually but nothing downstream waits on them, and
scheduling them now would crowd out the five above.

| Row | Why it waits |
|---|---|
| `DISCUSS-RECRUIT-CAPTURE-UX-2026-07-23` | Depends on `[UBS-5]`'s conversation transition |
| `DISCUSS-SUPPORT-UX-2026-07-23` | Depends on `[UBS-1]`'s feedback vocabulary |
| `DISCUSS-PVP-MODE-UX-2026-07-24` | Design is resolved (`PVP-1..8`); build-dep is training-hall + hotseat, later in v1 |
| `DISCUSS-AVATAR-MYUNIT-UX-2026-07-24` | An in/out feasibility call, not a layout question |
| `DISCUSS-MINIGAMES-SEAM-UX-2026-07-24` | Very likely post-v1; near-term ask is only "don't architecturally block it" |

---

## Recommended order

1. **`[UBS-1]`** — the feedback vocabulary. Three scheduled rows already converge on it and
   the handoff is written.
2. **`[UBS-4]` + `[UBS-5]`** — dialogue, including where it sits relative to the control
   region. It is `in_review`, so it is closest to ready, and `[UBS-4]` has no other owner.
3. **`[UBS-3]`** — non-modal text entry. Small, and it unblocks two sessions.
4. **`[UBS-2]` + `[UBS-6]`** — the transaction group, convoy before shop.
5. **`[UBS-7]`** — compendium, once `[UBS-3]` lands.
6. **`[UBS-8]`** — the campaign editor, last of the scheduled set because it is the largest
   and because `[UUI-13]`'s role list should be exercised by the theme assembler first.
7. **`[UBS-9]`** — credits, any time, but before the first public RC.

Each session's wireframes are drawn to the conventions the proof set establishes, and land
in the album as a new sheet rather than a new document.
