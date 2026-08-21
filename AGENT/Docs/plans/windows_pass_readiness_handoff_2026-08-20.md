---
Type: plan
Status: Superseded — all four questions answered and executed the same day; see [v078_round_out_handoff_2026-08-20.md](v078_round_out_handoff_2026-08-20.md) it
Last verified: 2026-08-20
Tracker: WINDOWS-PASS-READINESS-2026-08-20, SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19, UNMET-REASON-TEXT-TABLE-2026-08-20, V076-RETURN-RESIDUE-2026-08-16
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Getting the next Windows pass ready — Handoff (2026-08-20)

Written at the end of the session that built `UNMET-REASON-TEXT-TABLE-2026-08-20`
([session note](../../Session%20Notes/2026-08-20-21-08-08Z-unmet-reason-text-table.md)),
which was the last thing the control plane wanted done *before* the batched native-host
trip. That ordering argument is now discharged, so the trip is the next real move.

Integration tip `db114bbb`. Last shipped build: **v0.7.7** at `cfc7749f`, 2026-08-12.

## 1. Questions for the owner — these gate everything below

Answer these four and the rest is mechanical. Three of them change what gets built, so
guessing wrong means cutting the build twice.

### Q1. What version does the next Windows build carry — `v0.7.8` or `v0.8.0`?

`agent/integration` is **265 commits ahead of `agent/stable-release`** and 8 days past
v0.7.7. That is not a patch-sized delta by volume, and the responsive-UI programme has
been calling its target `v0.8.0` in row names since 2026-08-08
(`V080-RESPONSIVE-MAIN-MENU-2026-08-08`). Against that, the responsive redesign is not
finished — `SMALL-SCREEN-UI-REDESIGN-2026-08-05` is still `in_progress`.

This is not cosmetic. `test_release_metadata.gd:98` asserts a checklist exists at
`AGENT/Docs/playtests/playtest_checklist_v<version>.md` and names the current version, so
the number decides the filename, the BUILD STAMP, and the tag.

**Recommendation: `v0.7.8`.** Call `v0.8.0` when the responsive redesign actually lands,
rather than spending the version number on the build that happens to precede it.

### Q2. What goes in the build? Three branches are unmerged and carry host-testable work.

| Branch | Commits | Row | Would the host trip test it? |
|---|---|---|---|
| `agent/from-integration/unmet-reason-text-table` | 2 | `UNMET-REASON-TEXT-TABLE-2026-08-20` | **Yes — and `[ANN-5]` is worthless without it.** |
| `agent/from-integration/v080-responsive-main-menu` | 2 | `V080-RESPONSIVE-MAIN-MENU-2026-08-08` | Yes, it is a visual-pass row |
| `agent/from-integration/responsive-layout-context-scope` | 5 | `UI-PHASE0-UNBLOCKED-ITEMS-2026-08-16` | Yes, it is a visual-pass row |

All three are `in_review`. **A build is only as good as what is merged into it** — an
`in_review` branch that misses the merge is simply absent from the exe, and its row waits
another whole trip. The text-table branch is the sharp case: `[ANN-5]` asks what a screen
reader announces, and without that branch it announces `req.has_item`.

**Recommendation: merge all three into `agent/integration` first**, each after a review
pass, then cut. If any one of them is not ready, cut without it and say so on the
checklist rather than delaying the trip.

### Q3. Is this trip Windows-only, or Windows plus a phone/browser leg?

The control plane says *"batch every native-host item into one session."* Taken literally
that is wrong, and this is the finding worth acting on: **the open host-gated rows are not
one environment, they are three.** Of the fourteen open rows wanting a host, **three can
never be answered on a Windows desktop** — see §3. Putting them on a Windows checklist
guarantees three unanswerable items and a return that looks partly failed.

**Recommendation: cut the Windows trip to Windows-answerable items only**, and let the
iOS/mobile-web rows keep waiting for their own device session. They are already
`in_progress`/`4-validation` and none of them blocks `PREP-V1-S01`.

### Q4. Do you have a screen reader available on the Windows box?

`[ANN-5]` — *does a Windows screen reader already announce `tooltip_text`?* — is the whole
reason `SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19` is `blocked`, and it is the
single highest-value item on the trip. Narrator ships with Windows; NVDA is free. Either
works, but **the answer depends on which one**, so record which was used.

If no screen reader is available, say so now: that item comes off the checklist, the row
stays blocked, and the trip is worth less but still worth taking.

## 2. What the release line actually looks like

Verified by ancestry on 2026-08-20, not read from row status:

- `agent/integration` → 265 commits ahead of `agent/stable-release`, 915 ahead of
  `agent/playtest-release`.
- **Nothing is stranded on the release lines.** `integration..stable` and
  `integration..playtest` are both **0**, and the `v0.7.7` tag commit `cfc7749f` is an
  ancestor of `agent/integration`.

So promotion is a clean fast-forward, not a reconciliation. That is worth stating because
the last two release rounds were not: the v0.6.0 round diverged both ways and cost a
session to untangle.

## 3. The host-gated inventory — fourteen rows, three environments

The control plane names four items (`[ANN-5]`, `[ANN-3]`'s remainder, `IMPL-FOG-RENDER`'s
visual pass, `V076-RETURN-RESIDUE`). A sweep of `coordination/tasks.json` on 2026-08-20
finds **fourteen** open rows wanting a native host, a screen reader, or a visual pass.
Re-read this list before booking, and note that "wants a host" and "is ready for one" are
different questions.

### 3a. Windows-answerable and ready — put these on the checklist

| Row | Status | What the host answers |
|---|---|---|
| `SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19` | `blocked` | `[ANN-5]`: does a screen reader announce `tooltip_text`? **Highest value on the trip.** |
| `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` | `in_review` | Native keyboard/controller pass — this row's **sole** remaining item |
| `UNMET-REASON-TEXT-TABLE-2026-08-20` | `in_review` | Gated reasons read as sentences on a real display (needs Q2) |
| `IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN-2026-08-01` | `in_review` | Terrain variant visual pass; already on `agent/integration` |
| `V080-RESPONSIVE-MAIN-MENU-2026-08-08` | `in_review` | Main-menu responsiveness across size classes (needs Q2) |
| `UI-PHASE0-UNBLOCKED-ITEMS-2026-08-16` | `in_review` | Token/role/slider/scrollbar paint (needs Q2) |
| `SMALL-SCREEN-UI-REDESIGN-2026-08-05` | `in_progress` | Partially — a desktop window can be resized down, but not everything |

### 3b. Windows-answerable but NOT ready — these need in-container work first

| Row | Why not ready |
|---|---|
| `IMPL-FOG-RENDER-2026-08-02` | `planned`, not built. Fog **computes but draws nothing** until this slice ships. There is nothing to look at. |
| `LIB-V1-S07` | `planned`. The hostile-input hardening is the build; the Windows playtest is its exit check, not its start. |
| `PREP-V1-S01` | `planned`, and downstream of the trip rather than part of it. |
| `TEXT-ENTRY-MODE-REGISTRY-2026-07-26` | Umbrella row; work lives on `TEXT-V1` slice branches. |

### 3c. Not a Windows desktop at all — do not put these on the checklist

| Row | Needs |
|---|---|
| `IOS-DEVICE-PWA-VERIFICATION-2026-08-03` | A physical iPhone |
| `MOBILE-WEB-UX-GAPS-2026-08-03` | A mobile browser |
| `DEDICATED-TOUCH-CONTROLS-2026-08-03` | A touch device |

### 3d. `V076-RETURN-RESIDUE-2026-08-16` — partly a host item, partly not

Three unresolved items from the returned v0.7.6 checklist. Only one is a host observation:

1. **A truncated sentence, and only the owner can finish it.** Section 5's third item
   stops mid-word: *"browser cancel is fine, but I think that when a download was canceled
   then the "*. Something was observed about a cancelled download and never written down.
   This is **not** a host task — it is a question for you, and it costs a minute now versus
   a whole round later.
2. **Two migration checks are untested, not failed**, and the tester said why: *"not sure
   how to test this."* This is a **testability gap, and it is prep work for this trip**:
   the checklist asks for adversarial states (unmapped destination ids, ambiguous aliases,
   corrupt source data, failed commit) that the tester has no way to produce. Either ship
   deliberately-corrupt fixtures with the build or drop the items — asking again unchanged
   will return "not sure how to test this" again.
3. Cross-package and chained migration are likewise untested rather than failed.

## 4. The readiness sequence, once the questions are answered

1. **Merge what Q2 selects** into `agent/integration`, each with its own review pass.
2. **Close the testability gap in §3d item 2** — corrupt-source fixtures the owner can
   actually load, or the items come off the checklist. This is the one piece of prep that
   is real engineering rather than release mechanics.
3. **Fast-forward `agent/integration` → `agent/playtest-release`.** Clean per §2.
4. **Write `playtest_checklist_v<version>.md`** targeting §3a *only*. It must name the
   version or `test_release_metadata.gd` fails.
5. **Export and verify** — `scripts/export-windows.sh`, then confirm the BUILD STAMP was
   baked and record size and SHA-256. v0.6.1 shipped with a **v0.6.0 stamp** because a
   missing build record silently skipped the bake; the exporter now bakes and verifies, but
   check the stamp against the tag anyway.
6. **Tag** only after the checks pass, at the exact commit in the stamp.

## 5. Hazards specific to this round

**`[ANN-5]` has a false-verdict risk in both directions, and one of them is new.** The
text table now makes reasons render as sentences — but only in the surfaces that were
migrated. `CampaignManager._overworld_unmet_reason` was migrated this session; a surface
that still phrases its own reason would announce something that did not come from the
availability authority, and the trip would be measuring the wrong string without anyone
noticing. If Q2 excludes the text-table branch, **take `[ANN-5]` off the checklist
entirely** rather than running it against `req.has_item`.

**A gated surface can still be written that inherits nothing and fails nothing.**
`[EPUX-07]`/`[RPD-15]` lives in `ModalScreen` and `FocusNavigator`; `OverworldScreen` uses
neither and reproduced the exact defect one day after the shell-wide fix.
`AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20` exists to fix that and has not been built, so
the keyboard/controller pass in §3a should walk **every** availability surface, not a
sample.

**Do not trust row status for what is in the build.** Two rows in §3a are `in_review` for
residues that are deliberately not closeable in this container, and one (`SHELL-FOCUSABLE`)
is merged despite its status. Verify by ancestry.
