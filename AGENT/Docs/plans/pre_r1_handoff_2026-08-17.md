---
Role: dated
Type: handoff
Status: Active
Last verified: 2026-08-17
Tracker: R1-PLAN-CORPUS-COHESION-REVIEW-2026-08-16
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Next-session handoff — R1 is next, and everything in front of it is clear

The 2026-08-16/17 session swept the tracker, closed eight rows on evidence, and cleared
`R1`'s working set. This is what is left and the order to take it in.

**Read this before the tracker.** Every item below has a row; this document exists because
the *ordering* between them, and the reasons behind three of the decisions, are not
reconstructible from row prose alone.

---

## 1. Run `R1` — the plan-corpus cohesion review

`R1-PLAN-CORPUS-COHESION-REVIEW-2026-08-16`. It is the single item in front of **both**
halves of v0.8.0, and it is a review session, not a build.

**Why it is due now.** It sits at the end of Stage A in
[`research_and_discussion_sequencing_2026-08-13.md`](research_and_discussion_sequencing_2026-08-13.md);
both Stage A sessions (`S1`, `S2`) are complete, and the research programme it was deferred
behind finished on 2026-08-16 when the last two albums were approved. `R2` is in the same
position and can follow it.

**Its working set is clear.** The pre-R1 sweep executed, not just reported:

| Document | State |
|---|---|
| `unified_ui_programme_2026-08-12.md` | Claimed by `R1` (instance c) |
| `responsive_ui_programme_2026-08-06.md` | Claimed by `R1` |
| The doc role manifest (deleted 2026-08-23) | Claimed by `R1` |
| `open_questions_inventory_2026-08-06.md` | Claimed by `R1` |
| `unified_ui_decisions_2026-08-12.md` | **Deliberately not released** — see below |
| `responsive_ui_redesign_2026-08-06.md` | Stays with `SMALL-SCREEN-UI-REDESIGN`, which owes the one edit `R1` would make |
| `research_and_discussion_sequencing_2026-08-13.md` | Stays with `RESEARCH-SEQUENCING`, where `R1` is defined |

> **The register was withheld on purpose.** `R1` re-derives *plans* against registers. A
> ratified register is amended only through its owning row under `DOC-014` — naming the
> decision, quoting what it ruled, and stating the reason that outranks it. If `R1` finds
> `UUI` itself wrong, it goes back to `UNIFIED-UI-PROGRAMME` rather than editing in passing.

**Start with the precedence diff.** Every walk that went well here was preceded by one —
`S3` for `NMTE`, `S9` for `CEUI`, the latter recorded as *"the highest-value one in the
programme."* `R1`'s five instances are headed "**Known** instances waiting" against 108 plan
documents, so the enumeration is explicitly incomplete. Diff first, then re-derive.

**Two correction debts `R1` owns** (the owner assigned these to `R1` rather than paying them
early):

- `open_questions_inventory_2026-08-06.md:98` still lists `DRC-1..33` as **OPEN**; the
  register is **RESOLVED**. `REGISTERS.md` still carries the inventory as an OPEN register.
  This correction was assigned to `S1`, which is marked complete and never made it.
- `GDD_10_Roadmap.md:508` still reads *"Design floor ratified at 1280×720"* — the retired
  floor. `GDD_07_UI_UX.md:128-132` already carries the superseding text, so this is a
  copy-across, not a judgement. No open row claims `GDD_10` any more.

---

## 2. Phase 0 — and the deadline inside it

`UI-PHASE0-UNBLOCKED-ITEMS-2026-08-16`, rescoped to four items **in this order**:

1. **Context-scope `ResponsiveLayout`** (`[CEUI-S3]` call 1)
2. Add the `dense` token column (`[UUI-11]`)
3. Publish the role list into `ui_ux_interaction_vocabulary_2026-07-24.md` (`[UUI-13]`)
4. `SettingsScreen` slider and scrollbar paint in `manasoul_ui.tres` (`[UITH-6]` first half)

**Item 1 has a deadline nobody had written down.** Context-scoping is cheap *only* while
`ResponsiveLayout` has one production consumer. Verified 2026-08-16: `UnitDetailsScreen.gd:108,122`
is the only one — and the held branch `agent/from-integration/v080-responsive-main-menu`
**already adds a second** at `MainMenu.gd:88`. So the window closes when the v0.8.0 release
window opens, and narrows again with each of the seven screen conversions.

That is why the work moved out of `EDITOR-BUILD-PREREQUISITES-2026-08-14` (where it read as
undated planned work) and into Phase 0, ahead of the release window. `InputModeManager`'s
context-scoping — the other half of `[CEUI-S3]` call 1 — stayed on the editor row; it has no
comparable deadline.

**Do item 1 before item 2.** Adding a token column to a file about to be restructured is the
wrong order.

Items 3 and 4 are order-independent and unclaimed, so they can start immediately.

---

## 3. `S7` — the last zero-content stage

`IMPL-ZERO-CONTENT-BASE-PACK`. The execution hold is **lifted**; the plan is written up under
"S7 readiness" in
[`zero_content_slice2_closeout_and_skills_schedule_2026-08-07.md`](zero_content_slice2_closeout_and_skills_schedule_2026-08-07.md).
All three blockers that document recorded are discharged, and S1–S6's output is verified
present in the tree. **It is one session's work.**

Two things to carry into it:

- **Terrain variant content is now in S7's scope.** `IMPL-TERRAIN-VARIANTS` has been
  headless-green since 2026-08-01 and unverifiable because both pack branches carry **zero
  files under `assets/`**. It came off the display-gated list — it is blocked on authoring,
  not on a display. S7 must emit at least one terrain with two visually distinct variants and
  one pack-introduced terrain with its own tile source.
- **These are the first art assets either pack will ship**, so `CSA-35` licensing and `CSA-6`
  `rights_status` validation bind for the first time, and
  `LEG-ENGINE-ASSET-PROVENANCE-2026-07-26` — a dependency of this row — is still open.
  **Do not emit art whose provenance is not recorded.** Unprovenanced art in a public pack is
  harder to undo than a delayed terrain pass.

The exit's last clause — *a unit with an authored skill demonstrably fires it* — cannot be
closed headlessly with confidence. It wants the next bundle.

---

## 4. Before any bundle ships

**`v0.7.0_onboarding_web.md:36` still carries a literal `<commit>` placeholder**
(`--build-stamp "v0.7.0 <commit>"`). Returned web evidence cannot be attributed to a commit
while it is there, which voids `IOS-DEVICE-PWA-VERIFICATION`'s whole return. The pinned commit
must also contain `6779677c`, the `experimentalVK` export-preset fix, or every touch
text-entry result comes back invalidated by an already-fixed bug. **No row owns this.**

**The display-gated list is stale.** `v0.7.0_windows_round_display_gated_tasks.md` lists six
rows, four of which are now closed. The v0.8.0 round needs a fresh one. Current state:

- *Ready to look at:* palette swap (normal/done for two factions, forced fallback, HP-bar
  faction cue, movement frames, Compatibility shader compilation), and the Main Menu human pass.
- *Needs a phone, not just a display:* mobile controller, small-screen portrait frame
  containment, mobile-web UX gaps, dedicated touch controls.
- *Not ready:* terrain variants (see §3), iOS PWA verification (see the placeholder above).

---

## 5. Decisions still waiting on the owner

Blocks C–F of the 2026-08-16 review were never walked. In rough order of cost:

- **`STAGING-PROMOTION-2026-08-10`** — container `agent/staging-area` → `main`, PR #32, 352
  commits, verified CLEAN. Agents must not merge to `main`. `AGENTS-DOCS-LINE-POLICY` has
  waited on it since 2026-07-31.
- **`DECISION-ZERO-CONTENT-BLOCKER-GATES-2026-07-23`** — open since 2026-07-23. Its questions
  document never landed on `agent/integration`; it survives only on the archive tag
  `archive/agent/from-integration/campaign-data-research`, so the tracker row is the record.
- **The licensing chain** — `LEG-2` remedy and `LEG-4` asset audit outstanding (the register
  reads RESOLVED while the record says the gate was never cleared), provenance for the 51
  engine art assets, and — new from `UUI-14` — the built-in themes published through Pack 0
  need terms permitting authors to copy them, *before* publishing.
- **`V076-RETURN-RESIDUE-2026-08-16`** — three items from the returned v0.7.6 checklist. Two
  need owner recall: a browser-cancel finding whose note **stops mid-sentence**, and two
  migration checks marked "not sure how to test this".
- **`SHP-1..5`** — every price in the shop album is illustrative until these land.
- **Settings persistence scope** (`S12`), **settings export partition**, **curated UI element
  combinations** (ruled to exist by `[CEUI-S7]`, never designed), and **seven `5-backlog`
  rows** carrying an explicit "needs owner go/no-go".

---

## 6. Housekeeping

- **Responsive prep proof set (corrected 2026-08-29)** — the durable eight-viewport image
  is `AGENT/Docs/design/responsive_prep_deployment_researched_eight_viewports.png`, beside
  the research document that embeds it. Its SHA-256 matched the loose researched preview
  byte-for-byte. The three temporary copies under the container's `design-previews/` were
  removed, including two superseded drafts, and the stopgap ignore rule was retired.
- **`track.py` has no `--phase`, `--blockers` or `--depends-on` on `update`.** Every tracker
  change in this session that touched those fields had to be a hand-edit on the docs line.
  That is also why 19 rows had drifted to no phase at all. Worth closing the gap in the tool.

---

## What this session changed, for context

Eight rows closed on evidence: `V070-WINDOWS-RETURN-TRIAGE` (after merging its branch —
the entire v0.7.0 return evidence base lived only on it), `IMPL-CROSSING-RESOLVER` (after
adding the effect-less `[PCM-7]` coverage the fixture structurally could not produce),
`V071-RETURN-TRIAGE`, `V070-RETURN-FIXES`, both `V076` rows,
`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT` (which dropped a v0.8.0 gate), and
`GENERAL-PLANNING-SCHEDULING` (superseded on all three of its findings).

One stale blocker cleared: `REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27` was blocked on
an accepted stable tag and a reconciliation that both landed at v0.7.7. It transitively
gated 47 rows.

Twenty-three documents were recovered from invisibility in `INDEX.md` — their `Type:` values
sat outside the DSR-1 taxonomy, which drops a document silently while every check stays
green. `check_docs.py` check `[45]` now catches it. Two of the twenty-three were `R1`'s own
named targets.
