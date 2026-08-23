---
Role: dated
Type: playtest
Status: Returned and triaged - build rejected, four display-gated rows resolved
Last verified: 2026-08-07
---

# v0.7.0 Windows Round — Return Record and Disposition

**Returned:** 2026-08-07
**Build:** `v0.7.0`, BUILD STAMP commit `6cf2c89a`, verified in both returned logs
**Checklist:** `evidence/v0.7.0/returned_checklist.md`
**Decision sheet:** `evidence/v0.7.0/returned_decision_sheet.md`
**Evidence packet:** `evidence/v0.7.0/` — 2 logs, 7 screenshots, both completed documents, `SHA256SUMS.txt`
**Root-cause review:** [`../../Code Reviews/playtest_v0.7.0_root_cause_review_2026-08-07.md`](../../Code%20Reviews/playtest_v0.7.0_root_cause_review_2026-08-07.md)

**Verdict: reject `6cf2c89a` as a release candidate; accept the round as successful.**

Those are not in tension. The round existed to buy answers that a container cannot produce,
and it bought them: an installed pack played to a result for the first time, `[PCM-7]` was
decided, the pad question was settled, and the size-class seam got its first live look. It
also found six blockers, two of which are content-correctness defects that had been sitting
in the build undetected because every suite asserts values round-trip rather than that
anything acts on them.

**This return was triaged the same day it arrived, against the code.** The reason that is
worth stating: the v0.6.0 logs came back complete and then sat uninspected while the items
they answered stayed recorded as outstanding. Every finding below cites a file and line or a
log record.

## Section results

| § | Item | Result |
|---|---|---|
| 1 | Build identity — hashes, BUILD STAMP, debug vs release banner | **PASS** — stamp `0.7.0 / 6cf2c89a` in both executables; §8 confirms the banner is present under debug and absent under release |
| 2 | Windows resolution sweep, menu scale, HUD anchoring, viewport scale | **FAIL** — `V070-01`, `V070-08`, `V070-09`, `V070-12`; contextual menus and the Viewport Scale re-anchor passed |
| 2 | Free text: mouse, level-up, enemy XP, phase banner | **FAIL** — `V070-03`, `V070-04`, `V070-09`; two further reports unreproducible |
| 2a | Size-class seam — first look | **PASS** — stacking below 1024 confirmed as the right call, class change preserves state, settles once; `V070-13` found alongside |
| 3 | Controller — navigation, hot-plug, one-per-press, joypad button 1 | **PASS** — Bluetooth Xbox controller; no double-bind problem observed |
| 4 | Text entry and FileDialog | **FAIL** — `V070-06`; the round's headline value `escape_consumed_by` did not come back and *could not have* |
| 5 | Campaign-pack lifecycle | **MIXED** — the encounter played to a result (the row's exit); `V070-05`, `V070-07`, plus two already-scheduled items |
| 5a | What real content proves | **PASS** with one exception — both packs installed, four factions acted, all five objective types stated, promotion offered, terrain numbers behaved; `V070-02` found here |
| 6 | Save recovery | **NOT RUN** — owner-deferred: *"We are not worried about cross version save recovery until v1 stabilizes"* |
| 7 | Carry-forward | **PASS** — no v0.3.0 resize-trace file; the Escape half is §4 |
| 8 | Return requirements | **PASS** except `escape_consumed_by`, which `V070-06` explains |

## Findings, and what each one is going to cost

Full analysis in the root-cause review. The disposition column is the answer to the question
this triage was asked: *do not repair a surface the responsive redesign is about to rewrite.*

| Id | Severity | Finding | Disposition |
|---|---|---|---|
| `V070-01` | Blocker | First-launch content scale derived from the **screen**, applied to a 1280×720 **window** → main menu unusable above 1080p | **Fix now** — the redesign consumes this value, it does not replace it |
| `V070-02` | Blocker | `uses_mag` absent from every extracted weapon → all tomes deal STR−DEF instead of MAG−RES | **Fix now** — validator, extractor, re-emit both packs |
| `V070-03` | Blocker | Left click does not select in the default `follow` mouse mode | **Fix now** — one branch, contradicts a ratified design |
| `V070-04` | Blocker | `exp_gaining_factions` is persisted, displayed and tested, and read by nothing | **Fix now** — enemies gain EXP and level mid-battle |
| `V070-05` | Blocker | Invalid pack refused correctly, then fails silently — the error text exists and is never shown | **Fix now** — ~4 lines; it is a checklist item's exit condition |
| `V070-06` | Blocker | Escape guard never engaged all session, and its own instrumentation writes nothing | **Fix now** — make it observable *before* re-running §4 |
| `V070-07` | Medium | Save-slot budget keyed on `campaign_id` alone; two packs sharing a campaign id share the budget | **Fold in** to the save-identity rows |
| `V070-08` | Medium | HUD editor toolbar overflows and overlaps; panels strand on mid-edit resize | **Fold in** to the display-layers discussion + map-HUD conversion |
| `V070-09` | Medium | Phase banner panel hard-coded to 1280 px | **Fix now** — two scene properties |
| `V070-10` | Medium | Prep rules summary renders raw JSON at unbounded height | **Fold in** to `PREP-V1-S01` |
| `V070-11` | Low | ~3,200 `push_error` calls for absent skill ids in one session | **Fix now** — report once per activation |
| `V070-12` | Low | Viewport Scale has no window-relative ceiling | **Fix now** — same change as `V070-01` |
| `V070-13` | Medium | Menus lay out correctly only after a resize | **Fold in** to the eleven screen conversions |

Five reports are **no action** — the size-class boundary inconsistency is hysteresis working
as designed, the surviving built-in Proving Grounds is already scheduled for deletion, the
grey bar and the keyboard lockout are unreproducible from the evidence, and the mage damage
report is `V070-02` rather than a combat change. Each is recorded with its reasoning in the
review so none of them comes back as a new finding next round.

## What this return unblocks

### Closed by the evidence

- **`BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND-2026-07-24`** — closed. §3, on a Bluetooth
  Xbox controller: *"worked fine."* The `confirm=joy(1,0)` / `cancel=joy(2,1)` overlap was
  latent, and a real pad on the Campaign Library surfaces did not surface it. Named pad, as
  the row required.
- **`IMPL-ZERO-CONTENT-BASE-PACK`** — its exit has always been *"selected pack through one
  encounter"*, and §5 records exactly that, with §5a confirming the board was populated,
  four factions acted, all five objective types stated their conditions, promotion fired,
  and terrain numbers behaved. `V070-02` is a defect **in** the extraction, not a failure of
  the exit; it is tracked separately so this row does not stay open on it.
- **`IMPL-CROSSING-RESOLVER-2026-08-01`** — `[PCM-7]` answered: **yes, a crossing trigger
  that fires commits the move, effect or not.** That was the row's only outstanding owner
  call. Wire the ruling and close.
- **`PP-V060-CHECKLIST-CARRYFORWARD-2026-07-29`** — four of its five items are satisfied:
  hot-plug telemetry (§3), the log-inspection set (BUILD STAMP, runtime environment,
  `PLAYTEST CONTEXT`, controller telemetry all present; no `[V030 TRACE]`, no resize-trace
  file per §7), and the Retry-after-Save / one-per-press regressions (§3). Item 4, package
  save validation, is owner-deferred with §6. Item 3 is the FileDialog Escape bug, which
  already has its own row — so this row closes rather than being kept alive by a duplicate.

### Unblocked to start

- **`IMPL-ZERO-CONTENT-EXPORT-GATE` (Slice 4).** Its trigger reads *"delete project-data
  compatibility only after playable base pack and pack-aware loads pass."* Both now have.
  This is also the correct and only fix for the tester's *"still has the preinstaled packless
  proving grounds"* and *"switching packs — no change noticed."* Do not patch those
  symptoms; delete the source.
- **The eleven screen conversions.** `SIZE-CLASS-SEAM-2026-08-06` got the live look it was
  waiting for and came back clean on every property it was worried about: it settles once,
  a class change preserves selection, scroll and open More Info, and driving it from
  Viewport Scale behaves identically to dragging the window. The one item the design
  recorded as wanting a human's eye — *"Unit Details stacks below 1024 logical px"* — was
  confirmed as the right call in the 900–1023 band. Start at Main Menu, per the programme.

### Decisions to carry into that work

From the returned decision sheet, all four answered questions:

1. **Load Game and Campaign Library may stay large.** On Windows they may use the whole
   window; on web they are restricted to the game viewport. New constraint, not previously
   captured: *"make sure to consider rounded corners and notches/punchouts"* — that is a
   safe-area requirement on menu chrome, and it belongs with the existing safe-area work
   rather than being rediscovered on a phone.
2. **The centred main-menu column is right.** Two additions: it **must scroll**, so that
   large fonts or a small screen never put an option out of reach; and the title card may be
   **dropped** when vertical space is scarce. Both are Compact-class requirements and both
   land in the first conversion.
3. **The identity-diagonal default is right in principle**, and `V070-01` is what makes it
   wrong in practice. Also raised: *"consider looking into increasing the max menu scale, but
   that might be stepping onto the toes of the mobile ui redesign"* — it is; menu density is
   already a redesign token, so hold it there rather than raising `MenuScale`'s ceiling
   independently.
5. **`[PCM-7]`: yes**, firing commits the move.

Decision 4 (terrain variants) was returned unanswerable and is treated as such — see below.

### Still blocked, and the chain behind it

**`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` does not close.** This is the outcome the
round most wanted and did not get. §4 failed and, per `V070-06`, the guard emits nothing when
it fails, so the value that was supposed to let three redundant Escape stages be deleted on
evidence is simply absent.

Its claim on `SettingsManager.gd`, `SettingsScreen.gd` and `SettingsScreen.tscn` therefore
stays held, and everything queued behind it stays queued: the Settings screen conversion,
Menu Mode and information density becoming persisted settings, and `TEXT-V1-S06`.

**This now collides with `V070-01`,** which is a blocker living in `SettingsManager.gd` — the
claimed file. The claim was written when that file was expected to free up this week. Two
workable orders, and the choice is a scheduling call rather than a technical one:

- **Preferred:** land `V070-01` and `V070-12` as a narrow amendment *within* the text-entry
  row's claim, since that branch already owns the file and the change does not touch text
  entry. Costs nothing, keeps one owner.
- **Alternative:** release the claim down to `FileDialogInputGuard.gd` and the text-entry
  directory, and let `SettingsManager.gd` return to the pool. Cleaner long-term, but it
  reopens the seven-row path collision the redesign was split up to avoid.

**`IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN-2026-08-01` does not close, and not because of the
code.** The pack shipped in this bundle authors **no terrain variants** and contains **zero
asset files**, so there was nothing for the tester to look at — the honest answer to decision
4's *"What was supposed to be seen here?"* is *nothing was*. Dark-green forest and brown
mountain are the untextured fallback. Before this row queues for another visual pass, the
pack needs at least one terrain with two authored variants and at least one pack-introduced
terrain with its own tile source; otherwise the next round returns the same non-answer.

## Deliberately unchanged

`MOBILE-WEB-UX-GAPS-2026-08-03`, `IOS-DEVICE-PWA-VERIFICATION-2026-08-03` and
`DEDICATED-TOUCH-CONTROLS-2026-08-03` were held for the mobile pass and stay held.
`IMPL-FOG-RENDER-2026-08-02` was in neither round and was correctly not reported.
`IMPL-VIEWPORT-ANCHORING-2026-07-31` remains closed as superseded; nothing in this return
re-opens it.

## What the next bundle has to carry

Not a plan — the ordering belongs in
[`../plans/responsive_ui_programme_2026-08-06.md`](../plans/responsive_ui_programme_2026-08-06.md).
These are the conditions this return places on whatever ships next:

1. **`V070-06`'s instrumentation must land before §4 is re-asked.** Re-running the same test
   against the same silent guard returns the same nothing. This is the second consecutive
   round to lose this item.
2. **The pack must be re-emitted after `V070-02`,** and the new validator check is what
   proves the re-emission worked. A bundle carrying the current packs cannot answer anything
   about magic combat.
3. **The pack must author terrain variants** before `IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN`
   is put back on a display-gated list.
4. **Per-screen conversion branches carry their own Compact capture, taken without an
   intervening resize** — `V070-13` is invisible to a capture taken after one.
