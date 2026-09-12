---
Role: dated
Type: register
Status: RESOLVED 2026-07-20
Last verified: 2026-07-20
Register: REN-1..5
Resolved-in: 2026-07-20 — decision_record_2026-07-20_ren_public_identity.md (questions answered; the GDD prose pass and the banned-string check remain)
---

# D-A — Public-Identity Rename Gate (§3) — Draft Plan + Open Questions

**Started:** 2026-06-21d
**Status:** **RESOLVED 2026-07-20** (see banner below; register retained as history).
Originally framed as a mechanical data-pass plan + a release gate; it is a documentation pass.
**Source:** `planning_backlog_2026-06-20.md` §3; `GDD_10` §Public-Identity Rename Gate
(D-A, lines 839–845); session note 2026-06-21c Tier 2 #10.
**Relationship to DOC-012:** **separate, consecutive gates** — rename FIRST, then the
legal/licensing review (`legal_licensing_open_questions_2026-06-21.md`). The rename does
NOT resolve licensing.
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

> **RESOLVED 2026-07-20.** REN-1..5 are answered in
> `../decisions/decision_record_2026-07-20_ren_public_identity.md`. **Read that first** —
> §1 below is superseded on its central factual claim.
>
> **`data/` is clean.** A word-boundary scan on 2026-07-20 found *zero* FE-specific terms
> in any `.tres`, registry, or roster file. Class `display_name`s are generic RPG vocabulary
> (Archer, Cavalier, Paladin, Sage…) that Nintendo does not own. §1's "all FE-derived names
> are placeholders … data strings" overstates the data surface; treat it as historical.
>
> **This is a documentation pass, not a data pass.** All exposure is GDD prose. That inverts
> [REN-3]'s data-first ordering, removes the referential-graph and save-migration risk
> entirely, and makes the gate substantially cheaper than this plan assumed.

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

### [REN-1] Owned-name source — who/what defines replacements?  **[RESOLVED]**
This is the one genuinely **user-owned** decision (not derivable from code): the actual new
names. (Recommendation can only be about *process*, not the names themselves.)
- **A — User supplies a names list** (the project owner names the factions/classes/items).
- **B — Draft a candidate set in the mapping table** for the user to approve/edit.
- **Rec: B as the working method** — I draft a candidate owned-name per placeholder in the
  table so there's something concrete to react to; the user owns final approval. The names
  themselves are a creative decision I can't make.
- **Resolution:** **[RESOLVED 2026-07-20]** Scope is **character names + FE-coined terms +
  stripping "Fire Emblem" references**. The 9 character names (Chrom, Lucina, Marth, Micaiah,
  Sigurd, Seliph, Roy, Hector, Eliwood) and FE-coined vocabulary (Manakete, Falcon Knight)
  get owned replacements; the 49 mentions naming the franchise are removed. **Generic fantasy
  terms are KEPT** — pegasus, wyvern, valkyrie, troubadour, myrmidon, swordmaster are
  mythology and history, not FE's to own, and renaming them is effort without legal gain.
  Mapping table still to be drafted (`REN-GDD-PASS-2026-07-20`).

### [REN-2] Rename IDs too, or display-names only?  **[RESOLVED]**
- **A — Display names ONLY; ids stay as opaque placeholders.** Ids are internal keys never
  shown to players; the save format, map registry, and cross-references all key on them.
  Renaming ids is a large, risky graph rewrite (and breaks every existing save/snapshot) for
  zero public benefit.
- **B — Rename ids too** (full purge, ids match the new names). "Cleaner" but breaks saves +
  every reference and gains nothing public-facing.
- **Rec: A** — ids are not public identity; only the *displayed* strings need to be
  project-owned. Keeping ids stable preserves the save format, the map registry, and the
  whole validated reference graph. This dramatically shrinks the pass and its risk.
- **Resolution:** **[RESOLVED 2026-07-20 — A]** Display names only; ids stay opaque. Largely
  **moot today** since `data/` needs no rename at all, but confirmed as the standing rule for
  any future pass.

### [REN-3] Pass scope + ordering  **[RESOLVED]**
- **A — Data `.tres` `display_name`/`unit_name` first → GDD prose → registry labels.** Data
  first because `DataManager` boot-validation + the test suite catch breakage immediately;
  prose has no automated guard so it goes once data is green; labels last.
- **B — Prose first** (least risky to gameplay) then data.
- **Rec: A** — front-load the surfaces with automated guards (data, which boot-validates)
  so regressions surface fast; do the unguarded prose against the finished mapping table.
  Keep ids out of scope per [REN-2].
- **Resolution:** **[RESOLVED 2026-07-20 — ordering inverted]** The data-first recommendation
  is **moot**: `data/` is clean, so there is nothing to front-load. **GDD prose IS the pass**,
  followed by a completeness check on `map_registry.json` labels and roster references.

### [REN-4] Coverage enforcement (DoD#2)  **[RESOLVED]**
A rename that misses strings is the failure mode; the gate needs a durable check.
- **A — Extend `check_docs.py` (and/or a test) with a placeholder-string scan** that fails
  if any name from a banned-placeholder list appears in data/prose. Runs in pre-commit + CI.
- **B — One-time manual grep**, no standing check.
- **Rec: A** — per the project's DoD#2 (a ratified mechanical rule lands its check in the
  same change), the banned-placeholder list belongs in `check_docs.py` so a reintroduced
  placeholder fails loud forever. This is also the gate's *completion* signal: green check =
  rename complete.
- **Resolution:** **[RESOLVED 2026-07-20 — A]** Banned-string list lands as a new
  `check_docs.py` check, failing pre-commit and CI. **Scope it to `Project_Prometheus` only** —
  `Campaign_Pack_FE` is the designated home for FE-derivative material and says "fire emblem"
  deliberately, so sweeping it would fail permanently on correct content.
  (`REN-BANNED-STRING-CHECK-2026-07-20`)

### [REN-5] Save/back-compat of a pre-rename save  **[RESOLVED]**
- **A — No concern** (per [REN-2] → A, ids are unchanged, so saves keyed on ids load fine;
  only displayed strings differ). Pre-1.0 cross-version save migration is already deferred
  (§2b/I5).
- **Rec: A** — if ids stay stable, the rename is save-transparent. This is another reason to
  reject [REN-2] → B. No migration code needed.
- **Resolution:** **[RESOLVED 2026-07-20 — A]** No concern, and stronger than the rec assumed:
  ids are unchanged *and* no `display_name` changes either, since the pass touches only prose.
  Fully save-transparent. No migration code.

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
