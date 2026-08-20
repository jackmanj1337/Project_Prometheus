---
Type: plan
Status: Active — next-session execution handoff; build the unmet-reason text table before the native-host trip
Last verified: 2026-08-20
Tracker: UNMET-REASON-TEXT-TABLE-2026-08-20, PREP-V1-S01, REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Unblocking `PREP-V1-S01` — Handoff (2026-08-20)

Written at the end of the session that cleared all four of `PREP-V1-S01`'s original
blockers ([session note](../../Session%20Notes/2026-08-20-19-40-00Z-prep-v1-s01-blocker-clearance.md)).
Integration tip `28881b72`.

## Where `PREP-V1-S01` actually stands

Six of its seven dependencies are done or not blocking:

| Dependency | State | Blocking? |
|---|---|---|
| `B3-PHB-REGISTRY-2026-07-19` | `completed` | No |
| `ENGINE-PREDICATE-UNMET-REASON-2026-07-26` | `completed` | No |
| `B3-REQ-F16-BUILD-2026-08-18-2026-08-19` | `completed` 2026-08-20 | No |
| `DESIGN-OVERWORLD-CADENCE-2026-07-25` | `in_review`, **merged** `0da644f9` | No — consumable today |
| `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` | `in_review`, **merged** | No — inherit it, don't reimplement |
| `REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27` | `planned` | **Decide, don't run** — §3 below |
| `UNMET-REASON-TEXT-TABLE-2026-08-20` | `planned` | **Yes. This is the gate.** |

Verify the two `in_review` merges **by ancestry**, not by row status — both rows stay
`in_review` for residues that are deliberately not closeable in this container.

## 1. Next session — the assignment

**Build `UNMET-REASON-TEXT-TABLE-2026-08-20`. Do not start `PREP-V1-S01`.**

The session ends when a gated entry's unmet reason renders as a real player-facing
sentence, on at least one live surface, with a test that asserts the *rendered text*.

```bash
scripts/agent-work --repo Project_Prometheus start --tool codex \
  --slug unmet-reason-text-table --area text \
  --path scripts/text/TextDB.gd --path project.godot \
  --path scripts/tests/test_text_db.gd
```

Re-check the coordination registry before accepting those paths. If the decision in §1.2
lands on an autoload, `project.godot` is claimed by other rows periodically — check first.

### 1.1 What was measured on 2026-08-20 (do not re-derive)

- **Zero `req.*` keys exist.** A search across every `.json`, `.csv` and `.tres` in the
  repo returns nothing for `req.has_trait`, `req.in_group` or `req.has_skill`.
- **`TextDB` is not an autoload.** `project.godot`'s `[autoload]` block has no entry. The
  class is `scripts/text/TextDB.gd`; its only consumer is `scripts/tests/test_text_db.gd`
  against `scripts/tests/fixtures/text/basic.json`.
- **So `render_reason` always takes its null branch.** `RequirementSystem.render_reason
  (reason, text_db)` returns `String(reason.text_key)` verbatim when `text_db` is null,
  and no production caller can obtain one. A player reads `req.has_item`.
- **`RequirementSystem._ready()` registers twelve predicates**, each with a normal and an
  inverse key — **twenty-four keys**, countable from that function. Value sources
  (`campaign_var`, `literal_context`) carry no text keys.

### 1.2 The one decision this row needs

**How does a caller reach a text database?** Two options, and this should be ruled once
rather than defaulted silently:

- **Autoload.** Every consumer reads `/root/TextDB`. Matches how the rest of the shell
  reaches shared services and costs one line in `project.godot`. Downside: a global, and
  `RequirementSystem` is already autoload index 0 — check load order before assuming.
- **Explicit injection.** Each consumer is handed a table. Keeps the dependency visible
  and testable, at the cost of every call site threading it through.

Recommendation: **autoload**, because the alternative means every future availability
surface has to remember to thread a table, and this session already demonstrated that
"every new surface must remember X" does not hold (§4).

### 1.3 A naming mismatch to settle in the same breath

The `B3-TEXT` fixture uses `requirement.level` / `requirement.item`; `RequirementSystem`
emits `req.*`. One of the two is wrong. Pick one prefix and make the fixture and the
registrations agree — a fixture that demonstrates a convention nothing else uses is worse
than no fixture.

### 1.4 The test hazard — this is the important part

**Assert on rendered text, never on non-emptiness.** Both fallbacks return a non-empty,
plausible-looking string for a key that does not exist:

- `render_reason` with no table returns the bare key (`req.has_item`).
- `TextDB.tr_key` returns `#missing:req.has_item`.

Every "is it non-empty?" assertion passes in both cases, whether or not the table was
ever consulted. This is the same shape as the vacuous assertion caught in this session's
overworld work (an empty status matching an empty tooltip), and the announcement-channel
session note flagged it independently. Note the useful asymmetry: **`TextDB`'s fallback is
loud and `render_reason`'s is silent**, so wiring the table in is itself a diagnostic
improvement even before a single key is authored.

### 1.5 Second migration site, deliberately left behind

`CampaignManager._overworld_unmet_reason` phrases overworld reasons as plain English
sentences (`"Clear %s first."`, `"Not reached yet."`) **because the shared table was
empty**. That is a documented stopgap, not a pattern to copy. Once the table exists, that
function is the second thing to migrate — but migrate it, don't leave two conventions.

## 2. Then: the batched native-host session — and why the order matters

The control plane already recommends batching every native-host item into one trip rather
than spending a host visit on a single observation. The tracker currently shows **ten**
rows wanting a native host or a visual pass, not the four the control plane names — worth
re-reading that list before booking the trip.

**Do §1 first.** `SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19` is `blocked` on
`[ANN-5]`: *does a Windows screen reader already announce `tooltip_text`?* That question is
answered by listening to what gets read out. Today the answer would be a screen reader
reading **`req.has_item`** aloud, which tests the announcement path against a string no
player will ever hear and risks a false verdict in either direction. Authoring the table
first makes the host trip test real sentences, which is the only version of that test
worth the trip.

Also in the batch: `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17`'s native
keyboard/controller pass, which is that row's sole remaining item.

## 3. Decide the portfolio-review re-scope (owner call, cheap)

`REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27` stays `planned` and should **not** be run
as its handoff is written — see
[`accepted_portfolio_review_rescope_2026-08-20.md`](accepted_portfolio_review_rescope_2026-08-20.md).
§2 of that document proposes keeping three of its four deliverables and dropping the
first-tranche readiness verdict. That needs a yes/no before anyone builds the evidence
matrix, because the matrix's shape depends on the answer.

Note this row is a `PREP-V1-S01` dependency. If the re-scope is accepted, the honest move
is to close it as superseded and let its successor carry the edge — otherwise
`PREP-V1-S01` waits on a row nobody intends to execute.

## 4. Standing hazard for anyone building an availability surface

`[EPUX-07]`/`[RPD-15]` is implemented in `ModalScreen` and `FocusNavigator`. **It is not
inheritable by construction.** `OverworldScreen` is a bare `Control` using neither and
reproduced the exact defect one day after it was fixed shell-wide — gated entries with no
reason and no all-gated entry-focus fallback — and **nothing failed**. No test, no check,
no hook.

`PREP-V1-S01` builds a gated surface. Check by hand that gated entries stay focusable and
carry a reason, and take the reason from the availability authority rather than phrasing it
in the screen (`[EPUX-04]`). If a durable fix is wanted — a shared availability-list
builder, or a check that a `disabled` `BaseButton` carries a reason — it needs its own row.

## 5. Parked, in rough priority order

- **`REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20`** — `RequirementFormulaRegistry` still ships
  beside `FormulaEvaluator`, and `RequirementSystem` has no production callers outside the
  cadence engine. Pairs naturally with whichever row first migrates a real consumer.
- **`OVERWORLD-GRAPH-CANVAS-2026-08-20`** — the surface is a `ScrollContainer` of buttons,
  not the ruled pan/zoom canvas. A rebuild must carry the availability work forward, not
  redo it.
- **Cadence A1 residues** — `hours_played` has no producer and stays behind the deferred
  clock seam; predicate triggers evaluate with a context carrying only campaign flags and
  vars, which `[EPUX]`'s own worked examples (`roster_power >= X`, `unit_in_roster`) will
  need widened. Both live on `DESIGN-OVERWORLD-CADENCE-2026-07-25`.
- **`B4-PREP-MAP-DEPLOYMENT-2026-07-22`** — all three dependencies are now satisfied
  (`R1` is `completed`; the shell row is merged). It is startable, and its slice 2d
  consumes the shell fix rather than reimplementing it.

## 6. Tooling trap found this session

`scripts/agent-add-task.sh` **dedupes on `--run-id`**. A second row registered with a run
id already used creates nothing, prints `registered <FIRST-ROW-ID>`, and exits 0. Changing
`--slug` and `--branch` does not help. Generate a fresh run id per row and **verify against
`coordination/tasks.json`** rather than trusting the printed id.

Related: `--append-reference` text goes through the shell, so a single quote inside it
(e.g. quoting a GDScript call verbatim) fails the command with `unmatched "`. Paraphrase.
