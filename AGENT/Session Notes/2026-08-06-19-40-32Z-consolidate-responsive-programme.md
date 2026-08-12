# Session Note - 2026-08-06-19-40-32Z

## Branch context

- Branch: `agent/integration`
- Base branch: `agent/integration`
- Base SHA: `cd8b858c` (size-class seam tip, merged here)
- Coordination Work ID: `TEXT-ENTRY-ON-MOBILE-COMPACT-2026-08-06`

## What was done

Consolidation pass. Two branches merged in, one research thread written up as a design doc,
and the sequencing that was scattered across five tracker rows pulled into a single plan.

**Merged onto the docs line.** `agent/from-integration/small-screen-ui-redesign` (the
responsive redesign design doc) and `agent/from-integration/size-class-seam` (the
`ResponsiveLayout` autoload). The redesign doc had been sitting on an unmerged branch —
exactly the "plan nobody can see without standing on that branch" that `AGENTS.md` forbids.
The seam had to land here because every screen conversion branches from integration and
needs it; leaving it aside would have made each conversion carry its own copy.

One conflict, in `AGENT/Session Notes/INDEX.md` — two same-day notes claiming the top row.
Both kept, newest first.

**Mobile text entry — the owner decision and the research behind it.** New design doc
`AGENT/Docs/design/text_entry_mobile_compact_2026-08-06.md`.

The decision: suppress the OS keyboard; our keyboard takes over the control band during a
text-entry session. The band is 288px in Compact and that is what a keyboard needs, so
nothing is covered and nothing floats.

The research answers "how do OS keyboards get away with keys that small?", because if the
trick transferred, the shipped ten-column layout would still be viable. It does not:

- Raw touchscreen text entry runs at **8–9% per-letter error**. The keys are not accurate;
  autocorrection is silently fixing it.
- Four mechanisms stack. Hit-area-≠-drawn-key and the per-key Gaussian spatial model
  transfer to us. The language model (1.67–1.87× fewer errors) and key-target resizing do
  **not** — because almost everything typed here is a proper noun, and proper nouns are
  out-of-vocabulary. Gboard keeps a parallel *literal* path specifically so OOV words can be
  typed at all. The mechanism that pays for small keys is the one worst at our only job.
- Measured in millimetres on a real 460ppi phone: an iPhone key is 6.18 × 7.29 mm *with the
  decoder*; the shipped grid at controller density is 5.70 mm — **smaller, with none of the
  correction**; the recommended 7-column reflow is 7.29 × 7.29 mm — **larger than an iPhone
  key on both axes**. Apple does not follow its own 44pt rule on its own keyboard: the keys
  meet it vertically and miss badly horizontally, because columns are what the language
  model disambiguates.

**One consolidated plan.** `AGENT/Docs/plans/responsive_ui_programme_2026-08-06.md`. It owns
no decisions — each belongs to a design doc named beside it — and exists because the
ordering lived in prose on individual rows and the same blocker was recorded three different
ways. Writing it surfaced the thing worth knowing: **three separate pieces of this programme
are queued behind one Windows return.** `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` is
display-gated and claims `SettingsManager.gd` and the Settings screen, so the Settings
conversion, persisting Menu Mode and information density, and dropping `system` from the
text-entry vocabulary are all waiting on the same session.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

`df166f22` and the seam merge bring both branches onto integration. `be2ff642` adds the two
docs, registers them, and corrects the bundle handoff, which still claimed the redesign doc
was unmerged.

## Gates

- `python3 AGENT/Docs/check_docs.py` — PASS, 43 checks, after
  `gen_docs_index.py` (checks 18 and 30 both bit: the generated manifests, then doc ownership).
- `bash run_tests.sh` — **PASS, 130 suites** on the merged tree.
- `bash scripts/ci/check_gdscript_style.sh` — PASS, 303 files.

**Ownership gotcha worth not rediscovering:** a new `AGENT/Docs/{plans,design}/*.md` fails
check 30 until its filename appears in the Control Plane, the Feature Index, or the role
manifest's ownership map. **Both `GDD_Feature_Index.md` and
`project_control_plane_2026-06-29.md` are claimed by `IMPL-ZERO-CONTENT-FAMILIES`**, so the
role manifest was the only available hook — and is the semantically correct one anyway,
since both new docs are cross-cutting. Do not reach for the Feature Index while that claim
stands.

## Next

**Immediate, unblocked, and cheap: verify `FEATURE_VIRTUAL_KEYBOARD` on the web export.**
One Playwright run. It decides whether OS-keyboard suppression is a real task or a no-op,
and every text-entry decision downstream currently assumes an answer nobody has measured.
`TextEntryService.gd` calls `_target.grab_focus()` on a real `LineEdit` while
`virtual_keyboard_enabled` defaults to `true`, so if the web DisplayServer implements it,
the OS keyboard raises on top of ours today.

Then screen conversions, one branch each, cheapest first: Main Menu → Campaign Library →
New Game → Roster → Unit sheet and More Info → Prep hub. Settings and the map HUD are
ordered behind the Windows return and the 26% band fix respectively — see the programme plan.

Three text-entry sub-decisions are open for the owner: keyboard layout, the field echo
strip, and the Settings vocabulary. Only the third is blocked.
