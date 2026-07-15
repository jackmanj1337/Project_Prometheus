---
Type: plan
Status: Active - implementation handoff
Last verified: 2026-07-15
---

# v0.4.0 Post-Build Code-Review Fix Handoff

## Scope

Fix the four defects found while reviewing `b55dffa..576e823`, the work after
the v0.4.0 Windows build-record commit, plus the owner-approved requirement that
changed campaign flags and variables restore with campaign saves. This is a
next-session handoff; it changes no production behavior.

## Settled Decisions

1. `CampaignManager` owns campaign-scoped `campaign.flags` and `campaign.vars`
   beside campaign position. Map-scoped flags/vars belong only to Retry, Rewind,
   and suspend; they do not carry through between-map saves.
2. Flags are an open author vocabulary: reject malformed shapes and empty ids,
   deduplicate strings, but add no enum or hardcoded id switch. Future MET/TCV
   registries can provide deeper reference/type validation.
3. Temporary `GameState.party_items: Array[String]` persists through the existing
   `party.convoy.entries[]` schema. Capture/restore preserves duplicates and an
   explicitly empty saved list clears stale live items. Add no second durable
   `party_items` field.
4. A terminal autosave remains visible in Load Game as a **campaign completion
   record**, but is not a resumable Continue target.
5. This immediate record remains a full save. It is the durable precursor/source
   for the later compact portable `CampaignStatusRecord` /
   `CampaignCompletionRecord` artifact already designed for New Game Plus and
   continuity between compatible or connected campaigns:
   - [`campaign_status_property_recruitment_plan_2026-06-29.md`](campaign_status_property_recruitment_plan_2026-06-29.md)
   - [`band6_mutable_campaign_state_implementation_plan_2026-07-03.md`](band6_mutable_campaign_state_implementation_plan_2026-07-03.md)
   Completion must retain authoritative facts from which that exporter can later
   derive campaign/version, ending/route/rank, flags/vars, roster/economy facts,
   and counters without replaying the run.
6. Validate successor launchability before consuming a pending victory. Failure
   leaves the result and Next action retryable.
7. Slot document + index updates use staged temporary writes and replacement. A
   failed index/pointer write must not replace the old slot while reporting false.

## Finding 1 - Party Items And Mutable Campaign State Do Not Round-Trip (High)

Evidence:

- `scripts/autoloads/GameState.gd:582` captures campaign gold and roster but not
  `party_items`, `campaign.flags`, or `campaign.vars`.
- `scripts/autoloads/GameState.gd:608` restores none of them and does not clear a
  stale live `party_items` list.
- `scripts/core/TurnManager.gd:1221` appends victory rewards to `party_items`, so
  restart loses them and an in-process load can inherit another run's items.
- `SaveData` and the F1 manifest already reserve `party.convoy.entries[]`,
  `campaign.flags`, and `campaign.vars`.

Implementation:

- Add `campaign_flags: Array[String]`, `campaign_vars: Dictionary`, and small
  open-registry read/write APIs to `CampaignManager`; clear on start/end and
  include them in all-or-nothing capture/restore.
- Add a compatibility codec between flat item ids and minimal convoy entries.
  Validate through `DataManager`, preserve duplicates, and restore `[]` as clear.
- Validate campaign ids, flags/vars, convoy items, roster, and rules into temporary
  values before mutating live owners.
- Include these campaign/party fields in ledger contexts where the F1 manifest
  requires Retry/Rewind restoration; never leak map flags into between-map state.

Exit tests: round-trip duplicate and empty item lists, changed flags, changed
vars, rules, gold, and roster; load slot B after A to prove empty fields clear
stale state; malformed flags/vars or unknown item ids fail without partial apply;
Retry item rollback and suspend behavior remain green.

## Finding 2 - Completed Autosave Is Continue's Unloadable Target (High)

`CampaignManager.commit_pending_result` saves after terminal advancement sets
`current_node_id == ""`; `SaveManager.get_continue_target` treats that slot as
resumable; MainMenu then rejects it as already complete.

Implementation:

- Store/derive an explicit slot-header lifecycle marker such as
  `campaign_state: "in_progress" | "completed"`; do not infer it from labels.
- Continue selection, including fallback, skips completed slots. Load Game lists
  and labels them as completion records.
- Selection shows completion/details or a clear non-error message and never tries
  to launch an empty node.
- Preserve the record as the future NG+/connected-campaign export source. Do not
  pull the full Band 6 portable-record importer into this repair accidentally.

Exit tests: terminal completion leaves a visible record; Continue picks the newest
resumable document despite a newer completion; with only completion records,
Continue is disabled and Load Game enabled; selection never reports a broken map.

## Finding 3 - Advance Commits Before Successor Validation (Medium)

`GameOverScreen._on_next` commits and autosaves before `launch_current_node`.
Failure consumes the result, advances durable position, and hides Next.

Implementation:

- Split launch preparation/validation from scene change. Resolve the successor,
  map binding, roster policy, and prepared roster before commit.
- After validation: commit once, autosave, launch. On failure retain position,
  pending victory, autosave, and enabled Next. Terminal completion needs no map.

Exit tests: an invalid successor changes nothing and remains retryable; a valid
one advances exactly once; terminal completion writes exactly one record.

## Finding 4 - Slot/Index/Continue Writes Are Non-Atomic (Medium)

`SaveManager.save_slot` overwrites `<slot>.json`, then separately writes the index
row and last-played pointer. Later failure returns false after replacing old data.

Implementation:

- Build final document and index (slot row plus pointer) in memory.
- Write validated JSON to same-directory temporary files, close/flush, then
  replace destinations with rollback/cleanup on failure.
- Treat the index as commit marker: readers see the old consistent pair or new
  consistent pair, never mixed state. Reuse for suspend/index where practical.

Exit tests: injected failures preserve prior document, metadata, ordering, and
Continue target; success updates all together; temporary files are cleaned.

## Recommended Commit Sequence

1. State completeness: flags/vars + item/convoy compatibility + transactional
   restore and tests.
2. Completion semantics: completed-record metadata, Continue filter, Load Game
   presentation, and CampaignStatusRecord cross-links.
3. Advance transaction: prepare/validate before commit.
4. Atomic disk transaction: staged-write helper and failure-injection tests.

## Documentation And Verification

- DoD#1: update affected `GDD_01` contracts and `GDD_10_Roadmap.md` in each
  behavior commit; reconcile Continue/Load Game in `GDD_07_Screens_Panels.md`.
- Update `f1_save_schema_manifest_2026-07-06.md` for implemented flag/var and
  convoy adapters plus completion metadata.
- Keep the full completed save distinct from, but cross-linked to, the future
  portable completion-record subset.
- If lifecycle metadata becomes a mechanical rule, add its check per DoD#2.

Run:

```bash
bash scripts/check_env.sh
python3 AGENT/Docs/check_docs.py
bash scripts/ci/check_rng_usage.sh
bash run_tests.sh
```

Baseline `576e823` was green: 31 doc checks, RNG guard, and all 80 suites.
