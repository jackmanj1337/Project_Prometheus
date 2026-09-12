---
Role: dated
Type: design
Status: Active framing / driver
Last verified: 2026-08-25
---

# Campaign & Save — Expectations, Foundations & Interaction Surfaces (Framing)

**Started:** 2026-06-23
**Last verified:** 2026-08-25
**Status:** Active framing / navigation layer — Planned design work indexed here, not yet walked.
**Purpose:** One map of (a) what the save + campaign features **build on**, and (b) how **players**
and **designers** interact with them — separating what is already firmed from the open frontier, so
the follow-on register walks (DMR, I3, the designer authoring contract) have a shared starting point.

**This doc decides nothing.** It is the navigation layer (like an index) over the substance, which
lives in the linked registers/plans. When a linked register resolves, update the firmed/open index
here (§5).

## Companion docs (the substance)
- **Player-facing (firmed):** `campaign_save_player_facing_firming_2026-06-21.md` (branches A–J).
- **Technical plan (firmed):** `campaign_save_technical_plan_2026-06-21.md` (architecture + slices).
- **Decisions register (firmed):** `campaign_save_open_decisions_2026-06-21.md` (`[CST-1..12]` RESOLVED;
  `[CST-13]` deferred to §2 execution kickoff).
- **Determinism substrate:** `rng_determinism_design_2026-06-11.md` (Package A / `RngService`).
- **Content-model direction (open):** `planning_backlog_2026-06-20.md` §2b branch **I3** (set 2026-06-23a).
- **DataManager decomposition (open):** `datamanager_decomposition_open_questions_2026-06-21.md` `[DMR-1..3]`.
- **Roadmap home:** `GDD/GDD_10_Roadmap.md` Open Items Register §A (§2 cluster) + §H (planning backlog).

---

## 1. The core insight everything hangs on
The save stores **state by id** and **binds to a campaign id**. Everything else (units, weapons,
items, classes, skills, rules, map placement) is **resolved by id against that campaign's own
self-contained content set** at load. *(Reframed 2026-06-23: `[ICO-1]` — the model is
**self-contained per-campaign packs**, not a `defaults ∪ overlay` merge; `select_campaign()`
**replaces** the content rather than merging.)* Two consequences frame all the work below:
- **Player interaction** is about *progressing and persisting* that state → already firmed (§2).
- **Designer interaction** is about *authoring the self-contained content/graph/rules* a campaign
  carries → the open frontier (branch I3 + the eventual GUI builder).
- The seam between them is the **`DataManager` per-campaign load** path (`[DMR-1..4]`, RESOLVED) +
  uniform **`user://` campaign enumeration** (`[ICO-5]`). Desktop ships no default campaign to
  seed; web alone retains a specified, not-yet-built seed/repair path for its one bundled pack.

---

## 2. What it builds on — the substrate stack (bottom → top)

| Layer | What it provides | Owner / contract | Status |
| --- | --- | --- | --- |
| **L0 — `RngService` (Package A)** | determinism → meaningful suspend `rng{map_seed, history_hash}`, the rewind/Turnwheel substrate | `rng_determinism_design_2026-06-11.md` | build-ready; **gates §2 execution** |
| **L1 — `SaveManager` + `SaveData` seam + `SaveCodec`** | I/O-free serialize/deserialize seam; JSON-primitive state by id; integrity hashes; export/import; slots | `[CST-1/2/9/10]` | designed |
| **L2 — `DataManager` per-campaign load** | `select_campaign()` loads a campaign's complete content set (replace); ids resolve against that one set | `[DMR-1..4]` | **seam RESOLVED 2026-06-23** (merge→replace-load per `[ICO-1]`) |
| **L3 — `CampaignData` graph + `MapData` + content set** | progression nodes (map refs, `next`, required/excluded/cap), reusable map geometry, weapons/items/classes/skills (+ labels, +art/icons) | graph `[CST-3/5/6]` designed; **content model `[ICO-1..6]` RESOLVED 2026-06-23 (self-contained)** | mixed |
| **L4 — `CampaignRules`** | per-save rule object; author mandates vs defaults; story-flip seam; rewind charges | `[CST-4/6/11]` | designed |

**Two data tiers** (content model RESOLVED 2026-06-23, `[ICO-1..6]` — *self-contained*, supersedes the
2026-06-23a overlay tiers): (1) campaign **package** = the campaign's **complete** content + labels +
art, in `user://` (installed, imported, or authored; no desktop "default campaign" is seeded) →
(2) per-playthrough **save** = state by id, binds to a campaign id, resolves against **that campaign's
own set**. **Art lives in the package, never in the save**, and is **raw-loaded** (no `.import`).

---

## 3. Player interaction surface — FIRMED (pointers only, do not re-open)
Authoritative: the firming doc (A–J) + technical plan. Summary of what a *player* touches:
- **Start/structure** — New Game → **campaign selector** (everything-is-a-campaign) → rules screen
  (mandated locked, defaults editable) → **prep**. Linear MVP over an overworld-ready graph. [A1–A3, CST-6]
- **Prep / deploy** — per-node required (forced) + roster minus excluded; fill up to `deployment_cap`;
  assign onto map start tiles; manual Save; Begin Battle. Benched units gain nothing. [C1–C3, CST-5]
- **Persist** — in-app slots + filesystem export/import (single `.json`, zip-sniff importer);
  auto + manual save; human-readable JSON + `save_label` + integrity hash. [B1/B2/B6, CST-9/10]
- **Resume** — Continue = resume-most-recent (suspend if newest, else latest between-map → prep);
  Load Game = slot picker. [A4]
- **Suspend** — persistent, re-loadable, offered in the idle FREE state between committed actions
  while the active faction is human-driven. [B3, CST-8]
- **Defeat** — multi-choice Game Over (reload recent / reload any / main menu / [Rewind] when the
  rule is on, charge count, grey at 0). [B5, CST-7/12]
- **Rules visibility** — read-only rules view in prep/pause; explicit notice when a story event
  flips a rule. [G1/G3]

---

## 4. Designer interaction surface — THE OPEN FRONTIER (expectations to define)
The actor here is a **campaign author**. Nothing below has a firmed authoring contract yet; this is
the substance of the next register walks. Five expectation clusters:

- **4a. Progression authoring.** Declare graph nodes: `node_id`, `map_id` (→ `map_registry`), `next`
  (linear now, branches/overworld later), and per-node `required_units` / `excluded_units` /
  `deployment_cap`. (Schema shape firmed by `[CST-3/5]`; the *authoring experience* is open.)
- **4b. Rules authoring.** Per-rule **mandate (locked)** vs **default (player-editable)`; designate
  `protected_fields` (tamper-warning baseline + author additions); define story-flip points that call
  `apply_rule_flip`. (Seam firmed `[CST-4/6/11]`; the authoring surface is open.)
- **4c. Content authoring — branch I3 `[ICO-1..6]` RESOLVED 2026-06-23 (SELF-CONTAINED).** A campaign
  authors a **complete, independent** content set (weapons/items/classes/skills + labels + art) — no
  runtime inheritance. The editor gives a new pack an authoring floor by **generating flat-colour
  RGBA panels as real files inside that pack**; curated UI-element combinations are distributed
  separately, not as a first-party palette pack. Resolved: include = self-contained (a); override = whole-resource, no merge (b);
  intent = authoring-time provenance `forked_from` only (c); versioning = provenance stamp
  `builder_content_version`, no gate (d); location = uniform `user://` enumeration, with a web-only
  bundled-pack seed/repair carve-out (e). **Net-new schema (f):** `icon: String` on `WeaponData`/`ItemData` + a `resolve_icon()`
  raw-Image helper (field+seam now, UI render deferred).
- **4d. Packaging & distribution — branch I3.** The distributable, **self-contained** campaign bundle
  (maps + roster + graph + rules + complete content + art) living in `user://`; export/import (importer
  already sniffs `PK\x03\x04` zip vs `{` json); `builder_content_version` provenance; no cross-version
  migration pre-1.0 (keep `format_version`). **Core ICO-5 build work:** uniform `user://`
  enumeration and raw-image loading. Web additionally owes the specified first-run seed/re-seed path
  for its one bundled first-party/generated/CC0 pack; desktop has no reset-to-default operation.
- **4e. The authoring tool.** GUI campaign editor vs hand-authored JSON. The firming deliberately kept
  saves/data human-readable + data-driven to keep both open; the GUI editor is the eventual authoring
  surface over 4a–4d (AI-vision §2/§GUI).

---

## 5. Firmed-vs-open index (keep in sync as registers resolve)

| Thread | Where | Status |
| --- | --- | --- |
| Player-facing flow (A–J) | firming doc | **firmed** |
| §2 technical decisions `[CST-1..12]` | decisions register | **firmed** |
| `[CST-13]` rewind fold-in | decisions register | deferred to §2 exec kickoff |
| L0 `RngService` | Package A design | build-ready (gates §2) |
| L2 `DataManager` per-campaign load seam `[DMR-1..4]` | DMR register | **RESOLVED 2026-06-23** (merge→replace-load per ICO-1) |
| L3 content model (I3 `[ICO-1..6]`) | ICO register | **RESOLVED 2026-06-23 — self-contained** |
| Item `icon` schema field | ICO register `[ICO-6]` | **RESOLVED** (String path + `resolve_icon()`; field now, render later) |
| Designer authoring contract (4a–4e) | (this doc seeds it) | **OPEN — no register yet** |
| GUI campaign editor | AI-vision §2/§GUI | OPEN (far) |

---

## 6. Recommended walk order (next sessions)
The designer side is the leverage point, and it forces the substrate decisions in the right order:
1. ~~**Walk `[DMR-1..3]`** (L2).~~ **DONE 2026-06-23:** `[DMR-1..4]` RESOLVED — load seam parameterized
   (`_load_all(source)` + `select_campaign()`). *(Note: `[DMR-4]`'s `_apply_overlay()` merge was later
   superseded by a replace-load when `[ICO-1]` chose self-contained.)*
2. ~~**Open the I3 content register** — ratify a–e + item `icon`.~~ **DONE 2026-06-23:** `[ICO-1..6]`
   RESOLVED — **owner reframed to SELF-CONTAINED** (no overlay); uniformly enumerate `user://`, with
   seed/re-seed limited to the web distribution carve-out; `icon: String` + `resolve_icon()`.
   Build weight moved to ICO-5 enumeration/raw loading plus the web-only repair path.
3. **RE-SEQUENCED (owner, 2026-06-23): finish the player-facing surface FIRST, then builder authority.**
   The designer authoring contract (4a–4e) is **deferred behind** a pass to *finish defining all
   player-facing features* — you can't decide what the builder controls until the full player-facing
   surface is firmed. Worklist + status map: `player_facing_scope_map_2026-06-23.md` (GAP clusters =
   convoy/shop/recruit/support/rescue/PvP). **Then** the 4a–4e authority pass uses that feature list as
   its checklist, **then** implementation.
4. Player side stays firmed where already firmed; the GAP clusters in the scope map are the open work.

**Build track is unchanged and independent:** Package A Step 1 (L0) is still the next *execution*
step; the L2/L3/4x work above is *design* and is not gated by it.
