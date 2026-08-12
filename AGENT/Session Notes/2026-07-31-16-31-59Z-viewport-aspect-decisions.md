# Session Note - 2026-07-31-16-31-59Z-viewport-aspect-decisions

## Branch context

- Branch: `agent/from-integration/viewport-aspect-decisions`
- Base branch: `agent/integration`
- Base SHA: `a8a558bc19cb9402804b2b369fa8355b4e3f802f`
- Coordination Work ID: `UI-VIEWPORT-ASPECT-2026-07-31`

## What was done

Walked the owner through the four open questions in
`AGENT/Docs/design/viewport_expand_more_tiles_scoping_2026-07-11.md` §G and closed the
`UI-VIEWPORT-ASPECT` control-plane row, open since 2026-06-29.

**The first question was mis-posed and was corrected before it was answered, not after.**
The scoping doc called `stretch/aspect = "keep"` "the blocker" and the `keep`→`expand` flip
a trivial one-liner that would deliver "a bigger display shows more tiles". Measured on
Godot 4.6.3 (headless probe, base 1280×720, `canvas_items`, reading
`root.get_visible_rect().size`; `TILE_SIZE = 64`):

| aspect | 1280×720 | 1920×1080 | 2560×1440 | 1280×800 | 2560×1080 |
|---|---|---|---|---|---|
| `keep` | 20×11.2 | 20×11.2 | 20×11.2 | 20×11.2 | 20×11.2 |
| `expand` | 20×11.2 | **20×11.2** | **20×11.2** | 20×12.5 | 26.7×11.2 |

`expand` changes nothing on a larger *same-aspect* window — the scale is the smaller of the
two window/base ratios, and on 16:9 both are equal. It is a black-bar fix for
Deck/ultrawide/mobile only. Dropping the fixed base (`content_scale_size = (0,0)`) and
driving scale from an explicit `content_scale_factor` is what delivers the intent: at factor
1.0, 1080p shows 30×16.9 tiles and 1440p 40×22.5. Factor 1.5 @ 1080p and 2.0 @ 1440p both
reproduce today's view exactly — the identity diagonal, and therefore the safe ship default.

Decisions: (1) expand + explicit UI scale; (2) resolution list = presets + free resize;
(3) mobile default zoom deferred (no live mobile platform — `get_safe_area_insets()` is
hardcoded zero); (4) the ~11-scene anchoring refactor opens the UI/UX pass, ahead of the
prep hub, shop, forge, campaign editor, and compendium screens.

Newly opened by those answers and recorded, not solved: the default-factor derivation, the
`MenuScale` reconciliation (`MenuScale.gd:12` assumes `content_scale_factor` stays global 1
— `MENU_SCALE_LEVELS` must not stack on top of it), and the resize write-back rework.

Also corrected §B's claim that camera zoom is the *only* governor of pixel-perfectness: the
effective texel ratio is `content_scale_factor × camera zoom`, a product of two knobs.

## Commits claimed

- `6dd961fade90054b398b52f400c888af1521ff81` — Correct the viewport scoping doc against measurement and record the owner decisions

## Gates

- `python3 AGENT/Docs/check_docs.py` — PASS, all 43 checks green (caught an invalid
  control-plane Status value and two unknown Track ID references on the first attempt).
- `python3 AGENT/Docs/gen_docs_index.py` — regenerated `INDEX.md` after the header change.
- Full suite via `scripts/agent-push.sh --repo Project_Prometheus` — PASS, all suites green;
  receipt `audit/check-receipts/Project_Prometheus-full.json`.
- Tracker rows land separately in the container repo on
  `agent/from-staging-area/viewport-aspect-tracker` (`f9d2d63`):
  `UI-VIEWPORT-ASPECT-2026-07-31` (decision, completed) and
  `IMPL-VIEWPORT-ANCHORING-2026-07-31` (build slice, planned).
  `check_tasks.py` — OK, 223 tasks, no conflicts.

## Next

Write the implementation plan for `IMPL-VIEWPORT-ANCHORING-2026-07-31` against the recorded
decisions. It is serialized behind `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` — both add
a persisted setting to `scripts/autoloads/SettingsManager.gd`, and that row is still open
pending its Windows/visual return.

**Blocker raised this session, not fixed:** `coordination/tasks.json` has two divergent
copies — the container-repo working tree (223 rows after this change) and
`origin/agent/coordination` (234 rows, last written 2026-07-30). 67 rows exist only on the
latter and 54 only on the former; neither is a superset, and the same task can carry
different status and claimed paths in each. `agent-start-task.sh` registers into the
`agent/coordination` copy, which is why task registration for this session failed on a
phantom claim conflict against a row that is `completed` with a narrower claim in the
canonical copy. Reconciling the two needs an owner decision about which is authoritative.
