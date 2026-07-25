# Session Note - 2026-07-25 (prep/economy owner walk)

## What was done

Owner-led walk of the prep/economy bundle (`EPUX-01..28`), turning research
recommendations into ratified decisions and recording each into the research
doc plus the coordination tracker.

Ratified this session:

- **EPUX-01** — flat activity list (A) for the node interior, plus an optional
  author-enabled Fire Emblem Awakening-style **overworld map** for moving
  between nodes (strict linear advance is the default/fallback). Cleared nodes
  are **revisitable**.
- **Node traversal + cadence engine** (new) — a node's state advances on
  **triggers**: counters (`chapter_reached`, `chapters_elapsed`,
  `deployments_total`, `hours_played`, in `every`/`after` forms) and predicates
  from the shared condition registry. Counters latch inherently; predicates
  **latch by default with a reversible opt-in**, where reversible governs future
  access only (consumed content is permanent). Real-time cadence deferred
  post-v1 behind a mockable clock. Subscribers: activity set, battle target,
  activity variant, stock.
- **EPUX-16** — author-defined stock cadence, default infinite; folded into the
  cadence engine.
- **EPUX-14** — convoy has a **pricing subject** owner (author picks
  quartermaster or main character); subject-only, never a gatekeeper.
- **EPUX-11** — overflow routes to convoy; finite-cap terminal handling
  (player buys fail-before-commit; unavoidable acquisitions -> pending-items
  tray, default hold-pending); disabled-convoy cascade to per-unit-only storage.
- **Prep-hub structure** — top-level menu (Explore / Manage Roster / Map Preview
  / Save / Move to Next Primary Story Chapter / Start Battle), subject-first
  Explore, Manage Roster open registry (+ deployment WHO), Map Preview
  deployment WHERE (numbered start positions, auto-fill-in-order, player swap),
  per-unit energy budget as an optional wallet resource (default none, refill
  end-of-deployment), class change as one op with author-chosen delivery.
- **Shops** — stock is a first-class named entity shareable across on-map and
  Explore frontends; reason-keyed on-map inactive presentation.
- **Battlefield convoy access** (new) — an aura effect reusing the aura-skill
  radius machinery.
- **EPUX-05 / EPUX-08 / EPUX-18** — resolved by implication via the hub ruling.

Tracker: updated `DISCUSS-CONVOY-SHOP-UX`, `DISCUSS-PREP-HUB-UX`,
`DISCUSS-PREP-ACTIVITIES-UX`; added `DESIGN-OVERWORLD-CADENCE-2026-07-25`,
`DESIGN-PREP-HUB-STRUCTURE-2026-07-25`, and
`EFFECT-CONVOY-ACCESS-AURA-2026-07-25` (container repo `coordination/tasks.json`,
committed separately there).

## Commits claimed

- `f9c9c6ba7bde8148c02328d19b29993113f8c9c3` — Record EPUX-01/16 owner rulings + node traversal/cadence model
- `df4cd8299b6e44d3aa6b72e494899b38ce730e1d` — Ratify EPUX-14/11/05/08/18 + prep-hub structure, convoy, shops

## Gates

- `python3 AGENT/Docs/check_docs.py`: PASS, all 41 checks green.
- `python3 coordination/check_tasks.py` (container): PASS, 157 tasks valid.
- Pre-commit hooks (RNG, analyzer, scene integrity, gdformat/style): PASS.

## Next

Resume the `EPUX` walk: still open are EPUX-02, 03, 04, 06, 07, 09, 10, 12, 13,
15, 17, and 19..28. Several merely confirm an existing register and can be taken
as a batch. Then move ratified structure into implementation planning.
