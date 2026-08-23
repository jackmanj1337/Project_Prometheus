---
Role: dated
Type: plan
Status: Active — re-derived 2026-08-18 by R1 instance (c) against RPD, L10N, CEUI, DSX and CMP
Last verified: 2026-08-18
Decision source: ../registers/unified_ui_decisions_2026-08-12.md (UUI-1..19); ../registers/localization_scope_open_questions_2026-08-12.md (L10N-1..18); ../registers/responsive_prep_deployment_open_questions_2026-08-12.md (RPD-1..18); ../registers/campaign_editor_ui_open_questions_2026-08-12.md (CEUI-1..40, CEUI-S1..S52); ../registers/distribution_surface_open_questions_2026-08-15.md (DSX-1..29, DSX-S1..S29); ../registers/compendium_open_questions_2026-08-15.md (CMP-1..22)
Tracker: UNIFIED-UI-PROGRAMME-2026-08-12
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Unified UI Programme — consolidated plan — 2026-08-12

**Supersedes [`responsive_ui_programme_2026-08-06.md`](responsive_ui_programme_2026-08-06.md)**,
which sequenced four workstreams; this plan sequences eight. That document stays for its record
of what was done between 2026-08-06 and 2026-08-12.

> **Front matter added 2026-08-18, and it is load-bearing.** This document previously carried its
> `Status`/`Last verified` as prose, with no `Type:`. The `R1` re-derivation raised its `[RPD-n]`
> citations above three, at which point `gen_docs_index.py`'s heuristic classified **the plan** as
> a register and published a fabricated `RPD-1..8` range into `REGISTERS.md` — a catalog entry
> asserting eight decisions this document does not make. That is the second `gen_docs_index.py`
> defect recorded in `r1_plan_corpus_precedence_diff_2026-08-17.md` §6.4, reproduced live: `[46]`
> finds registers that are **hidden**, this one **fabricates** them. Declaring `Type: plan` stops
> it here; the general fix — the heuristic should never infer "register" for a document under
> `plans/`, since citing registers is what a plan *does* — is carried by `R3`.

> **Re-derived by `R1`, instance (c).** As written on 2026-08-12 this plan cited `UUI-1..19` and
> `UITH-1..8` and **nothing else**. Five registers governing screens it sequences have been ruled
> since — `RPD` and `L10N` (2026-08-13), `CEUI` (08-14), `DSX` (08-15), `CMP` (08-15/16) — and a
> citation-based check cannot see that, because a plan cannot cite a register that does not exist
> yet. See
> [`r1_plan_corpus_precedence_diff_2026-08-17.md`](../design/r1_plan_corpus_precedence_diff_2026-08-17.md)
> §1.2 and §4.3.
>
> **The order changed in three places, and two gates this plan was waiting on have closed.**
> `ResponsiveLayout` context-scoping enters Phase 0 *ahead of* the token column; a localization
> seam enters as Phase 2b, before the conversions; and the `UUI-15` album hold is discharged. The
> corrections are tabled in [§Corrections folded in](#corrections-folded-in-r1-instance-c).

**Why this exists.** The 2026-08-06 programme consolidated the responsive redesign, the size-class
seam, mobile text entry and the mobile-web controller. Four more workstreams have since
accumulated that each touch the same scenes and none of which that plan covers: pack-authorable
UI theming, the shared record-screen UI epic, the unratified display-layers discussion, and the
campaign editor UI. A deep search on 2026-08-12 found **54 open UI-impacting tracker rows**
against **23 built UI scenes**. This is the single sequencing view for all of it.

**This plan owns the ORDER.** Decisions belong to
[`unified_ui_decisions_2026-08-12.md`](../registers/unified_ui_decisions_2026-08-12.md)
(`UUI-1..19`) and to the design docs named beside each item. Where they disagree about
sequence, this file is right; where they disagree about why, they are.

*Boundary added 2026-08-18.* Two UI lines have acquired their own plans since and are **not**
sequenced here — [`prep_economy_implementation_plan.md`](prep_economy_implementation_plan.md)
(`PREP-V1-S01..S08`, including the distribution shell) and
[`b4_prep_deployment_handoff_2026-07-14.md`](b4_prep_deployment_handoff_2026-07-14.md)
(`B4-PREP-MAP-DEPLOYMENT`, including the dependent-choice layer). This plan owns the order
*between* them and the conversions; each owns its own internals.

**Wireframe album (proof set):**
[`wireframes/albums/unified_ui_proof_set_album.html`](../wireframes/albums/unified_ui_proof_set_album.html)
— 26 frames, six ratified viewports. *Corrected 2026-08-18: this line published only the Artifact
URL <https://claude.ai/code/artifact/34929585-0ec2-4e96-9040-b084ce5e7fe1>, which is not readable
offline and is not the authority. The album source is in-repo; the URL is the published copy.*

---

## The sources

| Source | Owns |
|---|---|
| [`unified_ui_decisions_2026-08-12.md`](../registers/unified_ui_decisions_2026-08-12.md) | `UUI-1..19` — the ratified answers this plan sequences |
| [`responsive_ui_redesign_2026-08-06.md`](../design/responsive_ui_redesign_2026-08-06.md) | Size classes, the 360×640 floor, density tokens, per-screen conversion |
| [`text_entry_mobile_compact_2026-08-06.md`](../design/text_entry_mobile_compact_2026-08-06.md) | The keyboard/controller handover and the keyboard layout |
| [`mobile_web_viewport_and_virtual_controller_implementation_plan_2026-08-04.md`](mobile_web_viewport_and_virtual_controller_implementation_plan_2026-08-04.md) | The control region: dead-space rule, landscape rectangle, the 26% defect |
| `UITH-1..8` (register file not on `agent/integration` — it lives on `agent/from-integration/ui-theming-alignment-agenda`) | Superseded in part by `UUI-8..10`, `UUI-13..14` |
| [`unbuilt_screen_research_agenda_2026-08-12.md`](../registers/unbuilt_screen_research_agenda_2026-08-12.md) | The questions the unbuilt screens need answered before they can be drawn |
| [`ui_ux_interaction_vocabulary_2026-07-24.md`](../design/ui_ux_interaction_vocabulary_2026-07-24.md) | Naming authority; gains the `UUI-13` role list |

**Added by the `R1` re-derivation, 2026-08-18** — five registers ruled after this plan was
written, each governing screens it sequences:

| Source | Owns |
|---|---|
| [`localization_scope_open_questions_2026-08-12.md`](../registers/localization_scope_open_questions_2026-08-12.md) | `L10N-1..18` — the 1.4× extent budget, declared direction, live locale change, the pack font obligation |
| [`responsive_prep_deployment_open_questions_2026-08-12.md`](../registers/responsive_prep_deployment_open_questions_2026-08-12.md) | `RPD-1..18` — prep composition at every class, the max workspace width, focusable-not-activatable |
| [`campaign_editor_ui_open_questions_2026-08-12.md`](../registers/campaign_editor_ui_open_questions_2026-08-12.md) | `CEUI-1..40`, `CEUI-S1..S52` — the editor's own scale and token column, the effective-pixel floor, context-scoped `ResponsiveLayout` |
| [`distribution_surface_open_questions_2026-08-15.md`](../registers/distribution_surface_open_questions_2026-08-15.md) | `DSX-1..29` — the distribution shell and the dependent-choice layer, two shared components this plan's eight workstreams do not contain |
| [`compendium_open_questions_2026-08-15.md`](../registers/compendium_open_questions_2026-08-15.md) | `CMP-1..22` — the compendium's composition and the provenance-display setting |

---

## Corrections folded in (`R1`, instance (c))

| # | What this plan said | What is ratified | Where |
|---|---|---|---|
| 1 | Phase 0 item 3 adds the `dense` column to `ResponsiveLayout.DENSITY_TOKENS` | **`ResponsiveLayout` must first become context-scoped.** An embedded game session needs the editor chrome at editor density while the game view derives its own class from its sub-viewport; the autoload holds one global `size_class`. Same for `InputModeManager`. Never add a column to a file about to be restructured | `[CEUI-S3]` call 1 |
| 2 | The token file ends at three columns (`touch`, `controller`, `dense`) | **Four.** The editor is a fourth column plus its own multiplier through the same assembler, with `min_target = 24` — not touch's 44, which would halve what the densest surfaces can show | `[CEUI-S1]`, `[CEUI-S50]`/`EW-9` |
| 3 | Density tokens publish a row *height* | **`--row` is a floor, not a height.** Rows grow when their content does. Measured: a name plus a sub-line is 35 px against a 28 px controller `--row`, a 25% overrun *before* the 1.4× extent applies | `[DSX-S22]` |
| 4 | "Every layout must survive ~1.3× text extent" (Known debt) | **1.4×, pseudolocalized, plus longest-token testing**, captured automatically at every durable viewport. 1.3× is a real-world average, and averages are not what clips | `[L10N-7]` |
| 5 | Nothing about text direction | **Every component declares its direction**; reading and navigation mirror, semantic spatial content (the tactical map, directional icons, numeric conventions) does not, and a component that declares nothing defaults to non-mirroring | `[L10N-11]`, `[L10N-12]` |
| 6 | "**No localization or i18n row exists anywhere in the tracker**" (Known debt) | **False since 2026-08-17.** `LOCALIZATION-L10N-BUILD-2026-08-17` exists and is a **dependency of the conversions**, ruled 2026-08-17: the seam lands *before* the screens bake fixed extents. New Phase 2b | `R1` §6.3 owner ruling |
| 7 | Conversions preserve focus, scroll and More Info across a live **class** change | Across a live **locale** change too — it is the same recomposition with a different trigger, which is what makes `[L10N-6]` affordable rather than new machinery | `[L10N-6]`, `[TSV-24]` |
| 8 | Phase 3 converts "Prep Hub" as one of seven screens | Prep is a **rebuild, not a conversion**: `B4-PREP-MAP-DEPLOYMENT` re-derived against `RPD`, with Slices 2–3 already built against the superseded design. It also builds the `[DSX-S4..S9]` dependent-choice layer, and Map Preview is a **canvas** — surfaces take the canvas region only, never the control band | `[RPD-1..8]`, `[DSX-S9]`, [`b4_prep_deployment_handoff_2026-07-14.md`](b4_prep_deployment_handoff_2026-07-14.md) |
| 9 | Nothing about a maximum workspace width | FHD and 4K **cap the workspace width** rather than stretching panes to the window | `[RPD-5]` |
| 10 | Settings "carries five things at once" | **Seven.** Add the `[CMP-S16]` provenance-display setting, and the editor display-settings group — whose persistence scope is **deliberately unruled** and inherited by `SETTINGS-PERSISTENCE-SCOPE-REVIEW-2026-08-13` | `[CMP-S16]`, `[CEUI-S1]` |
| 11 | Phase 5: "hold shop/convoy, reference compendium and campaign editor independently" until `UUI-15`'s named walks resolve | **All three walks closed and all three albums are approved** (`UBS-8` 08-15, `UBS-6`/`UBS-7` 08-16), so the hold is **discharged**. Under `[DSX-S29]` a `UBS` gate turns on its album being approved, not on its walk closing | `[DSX-S28]`, `[DSX-S29]`, `[CMP-S19]` |
| 12 | The eight workstreams are the whole UI surface | **Two shared components are missing from all eight**: the distribution shell (holder · pool · detail, shell-owned verb slot, N adapters, **nine** consumers) and the dependent-choice layer. Homed at `PREP-V1-S02` and `B4-PREP-MAP-DEPLOYMENT` by [`prep_economy_implementation_plan.md`](prep_economy_implementation_plan.md); the shell is a **consumer** of `UIREC-V1`'s primitives, not a peer | `[DSX-S1..S3]`, `[DSX-S9]` |
| 13 | The campaign editor is a workstream inside this programme's size-class system | The editor is **outside it**: it owns its own scale, font size and density, the player's Menu Scale does not reach it, and its `1920×880` floor is measured in **effective** pixels (`window ÷ editor scale`) — making it Expanded-only and single-state | `[CEUI-S1]`, `[CEUI-S2]`, `[CEUI-5]` |
| 14 | "The two things everything else is queued behind" — the Windows session and the v0.7.x acceptance gate | **Both closed.** `V07X-ACCEPTANCE-GATE-2026-08-11` is `completed`; `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` is `completed`. What actually remains is narrower and is restated below | `coordination/tasks.json`, 2026-08-18 |
| 15 | Two of the four "known debt" bullets | **Discharged by `R1` on 2026-08-17**: `GDD_10`'s retired floor is corrected (carrying the clause that the engine still hard-codes `1280×720` *deliberately* until the conversions land), and `UI-ARCH-02` is bannered | `r1_plan_corpus_precedence_diff` §5.2, §5.3 |
| 16 | The proof-set album is an Artifact URL | The album source is **in-repo** at `AGENT/Docs/wireframes/albums/`; the URL is the published copy, not the authority | `wireframes/albums/README.md` |

**Not folded in, deliberately.** `unified_ui_decisions_2026-08-12.md` (`UUI-1..19`) is untouched:
nothing here requires amending a ratified register, and under `DOC-014` that is done through the
register's owning row, naming the decision and the reason that outranks it. Nothing in this
re-derivation overturns a `UUI` ruling — every correction either post-dates one or fills a
silence.

---

## Done

| | Row | Landed |
|---|---|---|
| 1 | `IMPL-VIEWPORT-ANCHORING-2026-07-31` | Closed as superseded 2026-08-06. Its 1280×720 floor retired; its `content_scale_factor` work survives and is the foundation everything rests on. |
| 2 | `SIZE-CLASS-SEAM-2026-08-06` | `ResponsiveLayout` autoload on `agent/integration`: three classes, debounced republish, 24px hysteresis, both token sets. |
| 3 | `SUPPRESS-WEB-OS-KEYBOARD-2026-08-06` | `experimentalVK:false` in `export_presets.cfg`, guarded by `test_web_export_preset.gd`. |
| 4 | Mobile controller Slices 1, 2, 4 and the Slice 3 game-view editor | Built and browser-verified; tip `06a22b92`, held. |
| 5 | `V080-RESPONSIVE-MAIN-MENU-2026-08-08` | Built at `1b3acd81`, 133 suites green, held for the v0.8.0 window. |
| 6 | **The decision walk** | `UUI-1..19` ratified 2026-08-12. Closes the landscape rectangle, the 26% band, the theming register's live half, and the Menu Scale authority conflict. |

---

## The two things everything else is queued behind

> **Both closed, verified against the tracker 2026-08-18.** `V07X-ACCEPTANCE-GATE-2026-08-11` is
> `completed` (accepted on the v0.7.6 Windows and browser return) and
> `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` is `completed`. Neither paragraph below is a live
> blocker any more; both are kept because their *reasoning* still applies to the next round of
> display-gated work.
>
> **What is actually queued behind a Windows session now**, from the tracker rather than from this
> plan's prose: `SMALL-SCREEN-UI-REDESIGN-2026-08-05`, `MOBILE-WEB-UX-GAPS-2026-08-03`,
> `IOS-DEVICE-PWA-VERIFICATION-2026-08-03`, `DEDICATED-TOUCH-CONTROLS-2026-08-03` and
> `IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN-2026-08-01`. The Settings conversion is **not** among
> them: what it waited on was `SettingsManager.gd`, per the claim correction below.
>
> **What is queued behind the v0.8.0 window** is `V080-RELEASE-WINDOW-2026-08-11` itself, which is
> `planned` — the gate closing is what lets that row open, not what completes it.

**One Windows session with a phone and a pad.** `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`
is display-gated on it. Until it closes, the Settings conversion cannot be *validated*, the
text-entry vocabulary change cannot land, and the display-gated visual evidence stays
uncollected.

> **Claim correction, measured 2026-08-12.** This paragraph originally said that row claims
> `SettingsManager.gd`, `SettingsScreen.gd` and `SettingsScreen.tscn` — repeating an
> assertion in [`responsive_ui_programme_2026-08-06.md`](responsive_ui_programme_2026-08-06.md)
> and [`open_questions_inventory_2026-08-06.md`](open_questions_inventory_2026-08-06.md).
> **The tracker does not support it.** `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`'s
> `claimed_paths` is `scripts/ui/text_entry` only. Swept against every open row:
> `SettingsScreen.gd`, `SettingsScreen.tscn`, `ResponsiveLayout.gd`, `MenuScale.gd`,
> `manasoul_ui.tres` and `DisplayConfirmDialog.gd` are **all unclaimed**. The one real path
> claim is `SettingsManager.gd`, held by `V070-RETURN-FIXES-2026-08-07` (`in_review`).
>
> So the gate is narrower than three documents claim. **Menu Mode and information density
> becoming persisted settings, and flipping the 1280×720 design-floor constant, wait on
> `SettingsManager.gd`** — not on the Windows return. `UUI-18` waits on neither. Verify a
> claim against `coordination/tasks.json` before treating it as a blocker; prose drifts and
> the tracker is the machine-readable authority.

**The v0.7.x acceptance gate.** `V07X-ACCEPTANCE-GATE-2026-08-11` is the single machine-readable
boundary for every v0.8-held branch. Nothing in phase 1 below merges to `agent/integration`
before it closes.

---

## Order of work

### Phase 0 — unblocked now, no dependencies

Owned by `UI-PHASE0-UNBLOCKED-ITEMS-2026-08-16`. **Item 0 was added by the `R1` re-derivation and
goes first**; items 1–4 are unchanged in substance and renumbered nowhere, because two of them
turned out to be claimed.

0. **Context-scope `ResponsiveLayout` (and `InputModeManager`).** `[CEUI-S3]` requires it: the
   editor hosts a playable session, so the chrome must sit at editor density while the game view
   derives its own class from its sub-viewport, and today the autoload holds **one global**
   `size_class`, `menu_mode` and `logical_size` derived from the whole window.

   **This is dated work, and the date is the v0.8.0 window.** There is exactly one production
   consumer today (`UnitDetailsScreen.gd:108,122`); the held branch
   `agent/from-integration/v080-responsive-main-menu` already adds a second (`MainMenu.gd:88`),
   and every one of the seven conversions in Phase 3 adds more. It is a two-file change now and a
   migration after the window opens. **It also sequences item 3** — never add a token column to a
   file about to be restructured.

1. **`SettingsScreen` slider and scrollbar paint.** Eight `HSlider` nodes render
   engine-default grey inside ornate 9-slice panels on a screen players see today. Adding
   `HSlider` and `ScrollBar` to `manasoul_ui.tres` is a bounded change to one resource that
   depends on nothing else here. Largest visible difference for the least thrown-away work.
   *(This is `[UITH-6]`'s first half; the `Label`/`RichTextLabel` half is held for UIREC.)*
2. **Publish the role list** into
   [`ui_ux_interaction_vocabulary_2026-07-24.md`](../design/ui_ux_interaction_vocabulary_2026-07-24.md)
   and add the `theme_type_variation` adoption note. `UUI-13`. Blocks nothing and unblocks
   the editor's palette generation, the theme assembler, and every later conversion.
3. **The `dense` token column** in `ResponsiveLayout.DENSITY_TOKENS`. `UUI-11`. Pure
   addition; the keyboard is its first consumer but nothing breaks without one.

   *Three corrections, 2026-08-18.* **(a)** It runs after item 0, per `[CEUI-S3]`. **(b)** The
   file ends at **four** columns, not three: `[CEUI-S1]` gives the editor its own column with
   `min_target = 24`, landing with `dense` rather than being retrofitted around it — that column
   belongs to `EDITOR-BUILD-PREREQUISITES-2026-08-14`, which also **claims this file**, so the two
   additions are one coordination, not two edits. **(c)** Whatever the column publishes,
   `[DSX-S22]` rules the row token a **floor, not a height** — a name plus a sub-line measures
   35 px against a 28 px controller row, a 25% overrun before `[L10N-7]`'s 1.4× applies.
4. **Fix the Compact row-budget discrepancy** in
   `responsive_ui_redesign_2026-08-06.md` — the doc spends header 56 / footer 56, the tokens
   publish 72 / 64, and the real budget is 3.9 rows not 4.3. One-line correction.

   *Verified still owed, 2026-08-18.* The file is claimed by `SMALL-SCREEN-UI-REDESIGN-2026-08-05`,
   which records the same correction as a debt — **two rows are queued to make one edit; that row
   makes it.** `R1` confirmed the file's *other* owed correction (`~1.3×` → **1.4×** with declared
   direction, `[L10N-7]`/`[L10N-11]`/`[L10N-12]`) has landed at lines 212–219. The row budget has
   not. **Do not read the 4.3 in `[L10N-7]` or `[DSX-S11]` as corroboration** — the shop album
   independently measures 4.3 rows at the floor after its own chrome reduction, and arriving at
   the same number from different chrome is a coincidence, not a second source.

### Phase 1 — the v0.8.0 integration window

Owned by `V080-RELEASE-WINDOW-2026-08-11`. Opens on acceptance.

5. **Merge the three held branches** onto the accepted base, resolving drift *by behavior,
   not commit identity*. All three carry real drift: responsive Main Menu collides with the
   v0.7.6 `MainMenu.gd`/`.tscn` changes (3 conflicting regions, 125 commits behind);
   palette swap overlaps `DataManager`, `CampaignTier2Validators`, `ContentSession`;
   feature-coverage overlaps `PackManifest.gd`. Take Main Menu first, while the v0.7.6
   changes are freshest.
6. **Close the two outstanding visual gates** — the Main Menu human pass and the palette-swap
   Windows Compatibility-renderer evidence — in the same session as the v0.7.6 return.

### Phase 2 — the theme assembler

Nothing below this line can be built twice cheaply, so it goes before the conversions.

7. **Retire `MenuScale._scaled_theme()`.** `UUI-8`. Menu Scale becomes a multiplier on the
   density tokens and stops writing Themes. `MainMenu.gd:69`'s local opt-out becomes the
   general rule. This is the change that stops authored constants being silently discarded.
8. **Derive `content_margin_*` at theme-assembly time.** `UUI-9`. Ships with a guard that a
   StyleBox in a shipped theme carries no hand-set content margin.
9. **The pack theme contract.** `UUI-10`, `UUI-14`, `UUI-16`. Manifest gains a look/theme
   block; the chrome/in-campaign boundary is enforced in code, not by convention; Settings
   resolves its theme from whether a pack is active.
10. **Ship the built-in themes** — plain light, plain dark, fantasy parchment, pixelated
    retro sci-fi — and publish the same assets through the Pack 0 repo. **Licensing
    precondition:** they must carry terms permitting authors to copy them into their own
    packs, per `UUI-14`. Cross-check LEG-4 and the CSA clauses *before* publishing.

### Phase 2b — the localization seam

**Added 2026-08-18.** Owned by `LOCALIZATION-L10N-BUILD-2026-08-17`, now a dependency of
`V080-RESPONSIVE-SCREEN-CONVERSIONS-2026-08-11`. It sits here by owner ruling (`R1` §6.3) for one
reason: **the conversions bake extents and direction into every scene as they are written**, and
there is no cheap later moment to undo that.

L1. **The message-ID catalogue and lookup** — stable semantic IDs with English as fallback text,
     never identity (`L10N-2`); the exact → language → pack default → engine English chain with
     the supplying source exposed in validation reports (`L10N-4`); OS preference with an in-game
     override, resolving safely before first render (`L10N-5`).
L2. **The two constraints that bind every responsive component** — a **1.4× pseudolocale**
     generated and captured at every durable viewport (`L10N-7`), and **declared direction
     metadata** with non-mirroring as the default for a component that declares nothing
     (`L10N-11`, `L10N-12`). A component written without either is written wrong.
L3. **Live locale change** reusing the size-class recomposition path, preserving focus, selection
     and scroll (`L10N-6`, on `[TSV-24]`). No new machinery — the same transition, another trigger.
L4. **The pack obligations** — pack-owned catalogues (`L10N-3`, forced by `[ICO-1..6]`), a
     declared completeness level per locale with missing keys reported (`L10N-14`), and a pack
     font that covers every locale the pack declares, with engine fallback only for locales the
     engine guarantees (`L10N-13`). **This lands inside the Phase 2 pack theme contract**, not
     beside it: `UUI-10` already makes font face pack-authored, so glyph coverage is a validator
     on a manifest block that exists.
L5. **The prohibition, with its check.** UI sentences may not be assembled from concatenated
     fragments (`L10N-8`) — valid in English, broken almost everywhere else, and written by
     accident. Mechanical and checkable, so it owes an automated check in the same change under
     **DoD#2**.

Deferred by `L10N-18` and not in scope here: translation marketplace, machine translation, voice
dubbing, community moderation. Their import/export seams stay open.

### Phase 3 — screen conversions, one branch each

Owned by `V080-RESPONSIVE-SCREEN-CONVERSIONS-2026-08-11`. Order is durable:

> Campaign Library → New Game → Roster → Unit Details + More Info → Prep Hub → **Settings**
> → map HUD **last**

Every conversion must: be correct on first show without a synthetic resize; carry headless
coverage plus a Playwright capture at Compact; preserve focus, scroll and any open More Info
target across a live class change; and account for notches, punch-outs and rounded-corner
safe areas per `UUI-6`.

**Four obligations added to that contract, 2026-08-18:**

- **Survive a live *locale* change on the same terms as a live class change** — focus, selection
  and scroll preserved (`[L10N-6]`).
- **Declare direction**, and prove it with the bidi cases; a component that declares nothing
  defaults to not mirroring (`[L10N-11]`/`[L10N-12]`).
- **Capture at the 1.4× pseudolocale**, not only at the six viewports (`[L10N-7]`, `[L10N-16]`).
- **Cap the workspace width at FHD and 4K** rather than stretching panes to the window
  (`[RPD-5]`).

**Prep is not on this list as a conversion.** `Prep Hub` in the order above is
`B4-PREP-MAP-DEPLOYMENT-2026-07-22`, re-derived against `RPD` on 2026-08-17 — a **migration of
working code** (`PrepScreen.gd` is built, against the design that re-derivation supersedes), which
additionally builds the `[DSX-S4..S9]` dependent-choice layer as its first consumer. Its
composition is ruled by `[RPD-1..8]`, not by this plan: the map is the persistent primary surface,
surfaces take the **canvas region only, never the control band**, and three simultaneous panes are
rejected. See
[`b4_prep_deployment_handoff_2026-07-14.md`](b4_prep_deployment_handoff_2026-07-14.md).

11. **Record screens adopt the UIREC composition** rather than being made responsive in
    place. `UUI-4`. `UIREC-V1-S03` (wide/narrow adapters) and `S04` (list, detail, action
    components) are built *as* the Campaign Library conversion, not after it.
12. **Settings** is the largest single conversion and carries five things at once:
    the persisted Menu Mode and information density; the text-entry vocabulary cleanup
    (drop `system`, keep the registry constant); the dual-theme resolution from `UUI-16`;
    **section paging with a scrolling tab strip** (`UUI-19`); and the **reachability-risk
    confirm-or-revert** rework (`UUI-18`). Blocked on the Windows return.

    *Seven, as of 2026-08-18.* Two more settings have been ruled onto this screen since.
    **(6) The provenance-display setting** (`[CMP-S16]`) governs the entire display of authorship
    across the compendium and **may legitimately be set to zero**, because Credits is the
    attribution channel — so it is a real setting with a real off state, not a debug toggle.
    **(7) The editor display-settings group** (`[CEUI-S1]`): the editor owns its own scale, font
    size and density, so those rows exist and are **not** the player's Menu Scale. Their
    persistence scope — device, seat or global — is **deliberately unruled** and is inherited by
    `SETTINGS-PERSISTENCE-SCOPE-REVIEW-2026-08-13`. Do not answer it inside a conversion branch.
    Also note the editor inherits `UUI-18` with no new decision: an editor scale slider is
    exactly what `reachability_risk` means, and the dialog stays exempt from the setting it is
    confirming.

    `UUI-18` is separable from the rest and is the piece most worth landing early — it is a
    schema property plus a dialog that already exists and already works, and **both files it
    touches (`SettingsScreen.gd`, `DisplayConfirmDialog.gd`) are unclaimed**, so it is not
    gated on the Windows return at all. Two cautions.
    First, the dialog must be **exempt from the setting it is confirming**, or Viewport
    Scale 4.0 makes its own escape hatch unreadable. Second, `SettingsScreen._ready()`
    currently uses `confirm: true` to *also* decide which rows to hide where
    `is_display_config_supported()` is false; those two concerns share one flag today and
    must be separated, because a reachability-risk row is not automatically
    display-dependent.
13. **Flip the retired floor.** `SettingsManager.fit_content_scale_factor_for_size` still
    hard-codes `1280.0 / 720.0`. That is what makes a 1179×2556 phone snap to 0.5 and render
    2.7 CSS px type. **Do not flip it early** — before the conversions land it makes portrait
    large and broken rather than small and unclipped. Flip it with, or immediately after,
    the conversions.

### Phase 4 — the control region and text entry

14. **Landscape rectangle preset list, 4:3 default.** `UUI-1`, `UUI-2`. Blocks the landscape
    keyboard entirely.
15. **The 26% band → 55%, player-adjustable.** `UUI-3`. Must land *before* the conversions
    reach the map HUD.
16. **Text entry slices** `TEXT-V1-S01..S05` on the `dense` tokens from Phase 0. The portrait
    7-column layered keyboard and the landscape split keyboard are two reflows of one design.
17. **Map HUD conversion**, last, with the `UUI-7` fraction storage and all three V070-08
    consequences in the same change.

### Phase 5 — remaining held screens and released sheets

18. **Draw dialogue and credits when their album turn arrives.** Their design sessions are
    complete (`DLUX`/`DRC` and `CRD`); their implementation rows remain separate.
19. ~~**Hold shop/convoy, reference compendium and campaign editor independently.**~~
    **DISCHARGED 2026-08-18.** `UUI-15` released each group when its named walk resolved and
    lifted the final album hold when all three did. All three are resolved and all three albums
    are approved: `UBS-8`/`CEUI` (walk 08-14, album approved 08-15), `UBS-6`/`DSX` (walk 08-15,
    album approved 08-16), `UBS-7`/`CMP` (walk 08-15, album approved 08-16). Under `[DSX-S29]` a
    `UBS` gate turns on **its album being approved**, not on its walk closing — the stricter of
    the two standards, extended after `[DSX-S28]` found the gates were being released by
    different ones.

    **What replaces the hold**, since these groups are now buildable rather than held:

    - **Shop/convoy** builds as the **distribution surface** — one shell, N registered adapters
      across **nine** consumers (`[DSX-S1..S3]`), homed at `PREP-V1-S02` by
      [`prep_economy_implementation_plan.md`](prep_economy_implementation_plan.md). The shell is a
      **consumer** of `UIREC-V1`'s primitives, not a peer of them; if it splits badly in build,
      widen layer 1 rather than forking a second shell.
    - **The dependent-choice layer** (`[DSX-S4..S9]`) ships earlier than the shell, inside
      `B4-PREP-MAP-DEPLOYMENT` for v0.8.0, with deployment placement as consumer 1. It must
      **absorb** `RPD`'s select-then-select gesture rather than ship a second implementation.
    - **Reference compendium** builds to `CMP-1..22` — two regions with categories as the facet
      row (`[CMP-S3]`), a true back/forward history stack (`[CMP-S9]`), discovery scoped to the
      **run** rather than the save (`[CMP-S6]`), and `IMPL-REFERENCE-COMPENDIUM` as its row.
    - **Campaign editor** builds to `CEUI-1..40` + `CEUI-S1..S52` — and does so **outside this
      programme's size-class system**, per correction 13 above.

    Agenda kept for the record in
    [`unbuilt_screen_research_agenda_2026-08-12.md`](../registers/unbuilt_screen_research_agenda_2026-08-12.md).
    *Caution: that register's `Status:` header still reads "`UBS-6` walked, held pending album
    approval; `UBS-7` authored, walk pending", which was true on 2026-08-15 and is not now. The
    file is claimed by `RESEARCH-SEQUENCING-2026-08-13`; `R1` reported it rather than editing a
    register it does not own.*

---

## What this plan closes

| Was open as | Now |
|---|---|
| `DISCUSS-RESPONSIVE-DISPLAY-LAYERS-2026-08-02` — modal bounds, safe areas, HUD anchors | `UUI-5`, `UUI-6`, `UUI-7`. Menu-scale accessibility floor and supported scale test points remain open. |
| `SESSION-UI-THEMING-ALIGNMENT-2026-08-10` — `UITH-1..8` | `UITH-1/3/4/5` answered by `UUI-9/13/10/14`; `UITH-2` answered by `UUI-4`; `UITH-6` split across Phase 0 and Phase 3; `UITH-7` unchanged (reports not gates); `UITH-8` resolved — the V080 branch holds no infrastructure. |
| The landscape rectangle question on `MOBILE-WEB-CONTROLLER-2026-08-04` | `UUI-1`, `UUI-2`. |
| The keyboard token exception | `UUI-11`. |
| Confirm-or-revert reaching only `window_mode` and `resolution` | `UUI-18` — keyed on reachability risk instead, which catches `control_style = off` on a touch-only device. |
| Settings' 25-row Compact scroll | `UUI-19` — six pages, tabs on wide screens. Settings leaves UIREC and becomes a tabbed pager. |
| Menu Scale's future, deferred by `[UITH-1]` to "the responsive redesign" | `UUI-8`. |

## Verification burden

Information density ships in v1, so each screen is 3 size classes × 2 menu modes × 3
densities = **18 states**. Against 23 built screens that is 414 states, and the six album
viewports are the durable capture points within them.

The Windows visual pass is the scarce resource, so per-screen conversion branches must carry
their own headless coverage and a Compact capture **before** queueing for it — or the scarce
session gets spent finding things a test could have caught.

**`[L10N-16]` adds a mandatory proof set, 2026-08-18**, and it does not multiply the 414: missing-key
and glyph checks, **pseudolocale captures at all durable viewports**, bidi cases, and live-locale
state tests. Representative screen sampling is explicitly acceptable **once component reuse is
proven** — which is the clause that keeps the matrix from growing with every screen, and is a
reason to land `UIREC-V1` and the distribution shell before sampling is claimed.

**The editor is not in this count.** Per `[CEUI-S1]`/`[CEUI-S2]` it is Expanded-only and
single-state at an effective `1920×880`, with its own scale knob as the remedy below that — so it
contributes one state, not eighteen.

## Known debt this plan does not clear

- ~~**`GDD_10_Roadmap.md` still records the retired 1280×720 floor**~~ — **PAID 2026-08-17** by
  `R1` §5.2, and not as the plain copy-across it was assumed to be: the corrected text carries the
  clause that `SettingsManager` still hard-codes `1280.0 / 720.0` **deliberately** until the
  conversions land (Phase 3 item 13). Without that clause the entry reads as a defect report
  against working code.
- ~~**`ui_ux_architecture_research_and_questions_2026-07-24.md`** still states under
  `UI-TOOL-01` that the bridge "must stay absent from production exports"~~ — **PAID 2026-08-17**
  by `R1` §5.3: located and bannered. Both halves of `UI-ARCH-02` had moved — three size classes,
  not two compositions, and the "not a hard-coded device name" qualifier no longer holds.
- ~~**No localization or i18n row exists anywhere in the tracker.**~~ — **CLOSED.**
  `LOCALIZATION-I18N-SCOPE-2026-08-12` produced `L10N-1..18` on 2026-08-13 and
  `LOCALIZATION-L10N-BUILD-2026-08-17` is the build row, now a dependency of the conversions. The
  extent figure in the struck sentence was also **wrong in the unsafe direction**: `[L10N-7]`
  raised `~1.3×` to a pseudolocalized **1.4×** precisely because 1.3 is an average and short
  labels have no slack. See Phase 2b.
- **`MOBILE-WEB-CONTROLLER-2026-08-04` is substantial but `in_progress`**, and is not
  merge-ready as a whole. Slice 4's global opacity/scale, combination save/rename/delete,
  Slice 5 themes/haptics and Slice 6 album/matrix all remain.
