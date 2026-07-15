---
Type: register
Status: OPEN
Last verified: 2026-06-23
Register: REN-1..5
---

# D-A — Public-Identity Rename Gate (§3) — Draft Plan + Open Questions

**Started:** 2026-06-21d
**Status:** Planning draft — register OPEN. A mechanical data-pass plan + a release gate.
**Source:** `planning_backlog_2026-06-20.md` §3; `GDD_10` §Public-Identity Rename Gate
(D-A, lines 839–845); session note 2026-06-21c Tier 2 #10.
**Relationship to DOC-012:** **separate, consecutive gates** — rename FIRST, then the
legal/licensing review (`legal_licensing_open_questions_2026-06-21.md`). The rename does
NOT resolve licensing.
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

- **All Fire Emblem–derived names are placeholders** (factions, classes, items, GDD prose,
  data strings). The gate requires a data-pass rename to project-owned names **no later than
  the first public release-candidate**.
- **Names live in many surfaces:**
  - **Data `.tres`** under `data/` — `ClassData.display_name`, `WeaponData.display_name`,
    `ItemData.display_name`, `UnitData.unit_name`, `FactionData` names, `SkillData` names.
  - **IDs** (`id`/`class_id`/`weapon_id`/`unit_id`) — these are *referential keys* wired
    across maps, registries, skill_unlocks, promotes_to/from, reclass_options, effect_params,
    and the snapshot/save format. Renaming an **id** is a graph-wide change; renaming a
    **display_name** is cosmetic. The split is the central decision ([REN-2]).
  - **GDD prose** (`AGENT/GDD/*.md`) — descriptive text naming FE characters/classes.
  - **`map_registry.json`** labels + roster file references.
- **No mapping table exists** — there's no canonical placeholder→owned-name list yet.
- **Validation is strict** — `DataManager` cross-checks ids everywhere (class refs, promotes,
  reclass, map registry); a half-done id rename fails loud at boot (a useful safety net for
  this pass).

## 2. Draft plan

A rename is a **mechanical, high-blast-radius data pass** — its risk is *coverage* (missing
a string) and *referential integrity* (breaking an id graph), not design. Plan shape:
1. **Build the mapping table** — every placeholder name → project-owned name, grouped by
   surface (faction / class / item / weapon / skill / character / prose term).
2. **Decide the id-vs-display-name split** ([REN-2]) — almost certainly rename **only
   display names**, keep ids as opaque non-public keys.
3. **Pass scope + order** ([REN-3]) — data `.tres` first (boot-validated), then GDD prose,
   then registry labels.
4. **Coverage check** — a scan/grep for the placeholder corpus that fails CI if any banned
   placeholder string survives (DoD#2 — this is the durable enforcement).

## 3. Open questions register

### [REN-1] Owned-name source — who/what defines replacements?  **[OPEN]**
This is the one genuinely **user-owned** decision (not derivable from code): the actual new
names. (Recommendation can only be about *process*, not the names themselves.)
- **A — User supplies a names list** (the project owner names the factions/classes/items).
- **B — Draft a candidate set in the mapping table** for the user to approve/edit.
- **Rec: B as the working method** — I draft a candidate owned-name per placeholder in the
  table so there's something concrete to react to; the user owns final approval. The names
  themselves are a creative decision I can't make.
- **Resolution:** _[OPEN — needs the user's naming direction]_

### [REN-2] Rename IDs too, or display-names only?  **[OPEN]**
- **A — Display names ONLY; ids stay as opaque placeholders.** Ids are internal keys never
  shown to players; the save format, map registry, and cross-references all key on them.
  Renaming ids is a large, risky graph rewrite (and breaks every existing save/snapshot) for
  zero public benefit.
- **B — Rename ids too** (full purge, ids match the new names). "Cleaner" but breaks saves +
  every reference and gains nothing public-facing.
- **Rec: A** — ids are not public identity; only the *displayed* strings need to be
  project-owned. Keeping ids stable preserves the save format, the map registry, and the
  whole validated reference graph. This dramatically shrinks the pass and its risk.
- **Resolution:** _[OPEN]_

### [REN-3] Pass scope + ordering  **[OPEN]**
- **A — Data `.tres` `display_name`/`unit_name` first → GDD prose → registry labels.** Data
  first because `DataManager` boot-validation + the test suite catch breakage immediately;
  prose has no automated guard so it goes once data is green; labels last.
- **B — Prose first** (least risky to gameplay) then data.
- **Rec: A** — front-load the surfaces with automated guards (data, which boot-validates)
  so regressions surface fast; do the unguarded prose against the finished mapping table.
  Keep ids out of scope per [REN-2].
- **Resolution:** _[OPEN]_

### [REN-4] Coverage enforcement (DoD#2)  **[OPEN]**
A rename that misses strings is the failure mode; the gate needs a durable check.
- **A — Extend `check_docs.py` (and/or a test) with a placeholder-string scan** that fails
  if any name from a banned-placeholder list appears in data/prose. Runs in pre-commit + CI.
- **B — One-time manual grep**, no standing check.
- **Rec: A** — per the project's DoD#2 (a ratified mechanical rule lands its check in the
  same change), the banned-placeholder list belongs in `check_docs.py` so a reintroduced
  placeholder fails loud forever. This is also the gate's *completion* signal: green check =
  rename complete.
- **Resolution:** _[OPEN]_

### [REN-5] Save/back-compat of a pre-rename save  **[OPEN]**
- **A — No concern** (per [REN-2] → A, ids are unchanged, so saves keyed on ids load fine;
  only displayed strings differ). Pre-1.0 cross-version save migration is already deferred
  (§2b/I5).
- **Rec: A** — if ids stay stable, the rename is save-transparent. This is another reason to
  reject [REN-2] → B. No migration code needed.
- **Resolution:** _[OPEN]_

## 4. Slice sketch (provisional)
1. Build the placeholder→owned mapping table ([REN-1]/[REN-2]) — the deliverable that
   unblocks the pass; needs the user's naming direction.
2. Data `.tres` `display_name`/`unit_name` pass ([REN-3]); boot + tests green.
3. GDD prose pass.
4. `map_registry.json` labels.
5. `check_docs.py` placeholder-scan guard ([REN-4]) — the gate's completion check.

## 5. Notes
- This gate is **mostly mechanical execution** once the mapping table exists; the table (and
  the names in it) is the only creative/user-owned input. The rest is a guarded find-replace.
- Runs **before** DOC-012 (licensing); the two are consecutive release gates.
