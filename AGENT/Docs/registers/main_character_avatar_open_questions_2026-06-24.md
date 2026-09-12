---
Role: dated
Type: register
Status: RESOLVED 2026-06-24
Last verified: 2026-06-24
Register: MCH-1..8
Resolved-in: 2026-06-24g
---

# Main Character / Avatar (#20) — Player-Facing Design + Open Questions

**Started:** 2026-06-24 (session 2026-06-24g) — second branch of sync-cluster **A3** (roster identity
& relationships), after the Relationship system `[REL-1..9]`.
**Status:** RESOLVED 2026-06-24g. Unifies **Avatar / My Unit** and **story-defined main characters**
into **one class-orthogonal "main character" role** on `UnitData`. Avatar = a main character whose
defining fields are **player-authored** (author opts in per field). Spins out a new foundation
**F13** (text indirection / localization-ready string layer) from the name-substitution decision.
**Pattern:** mirrors `[IEQ]`/`[PXP]`/`[REL]`. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

Depends on `[REL]` (relationship hub + REL-8 exclusive slot) and **F13** (name/text indirection).
Hands the F1 schema-lock a roster reservation (MCH-7). Recruit/Capture (#4 ⇄ A4) is the next branch.

---

## 1. State today (code-grounded — verified 2026-06-24g)
- **No identity/role layer.** `UnitData` has only `is_default_roster` / `can_seize` — no avatar,
  portrait, lord, or main-character flags. No character-creation flow. No `avatar`/`portrait` refs
  anywhere in `scripts/`.
- **Loss machinery already exists.** `ObjectiveCondition` (`MapData.defeat_conditions`, evaluated by
  `TurnManager`) has a **`protect`** type — "every named `unit_ids` stays alive, else defeat." So
  "main character dies → game over" is **already expressible per-map**; the only new thing is making
  the role *imply* it (MCH-3).
- **Story text is not yet built** — no dialogue/string data format exists, so the F13 text-indirection
  convention is adopted now but its automated check is deferred until that data lands (F13 note).

---

## 2. Resolved decisions

### [MCH-1] Unified model — **RESOLVED: one class-orthogonal "main character" role**
Avatar units and author-defined story protagonists are the **same structure** — a `UnitData` carrying
an elevated **narrative-identity role**, *orthogonal to class*. They differ only in a **provenance**
flag: **author-fixed** (protagonist) vs **player-authored** (Avatar). No bespoke avatar system; Avatar
reuses the role + the relationship plumbing.

### [MCH-2] Role bundle — **RESOLVED: defaults-on, each independently overridable**
Flagging a unit a main character turns these **on by default**, each individually toggleable:
- **must-survive** (death = defeat — MCH-3),
- **relationship hub** (eligible for many relationships + the REL-8 exclusive top-rank slot — MCH-8),
- **dialogue name-substitution** (the unit's name is injected into story text via F13),
- **forced/locked deployment** (auto-deployed, can't be benched) — **overridable both per-character
  AND per-map** (a chapter may bench/remove the lead).

### [MCH-3] Must-survive — **RESOLVED: role implies a protect/defeat default, author overrides per-map**
The role **auto-adds a campaign-wide `protect` defeat default** (reusing the existing
`ObjectiveCondition` `protect` type) naming the unit. **Any map may override** (retreat/captured/
cameo chapters). Interacts with A5 difficulty: main-character death is game over **even in
casual/phoenix** modes unless a map overrides — confirm when A5 (Casual/Phoenix) is firmed.

### [MCH-4] Class decoupling — **RESOLVED: identity is a unit property, not a class**
"Main character" is **not** conferred by a Lord class. A main character may **start in any class,
reclass freely** (or within an author-restricted set), and **retains the role** throughout. Unique
classes remain available (just a `ClassData`) but are **never required** for main-character status.

### [MCH-5] Avatar player-authored fields — **RESOLVED: per-field author opt-in**
Avatar = a main character whose fields the **author opts the player into, per field**:
- **name** (free text — see the F13 grammar edge),
- **portrait** — pick-from-an-author-set **or** a format-constrained **file upload** (rides the
  campaign content model's **raw-loaded art** pipeline into the `user://` pack; only format/size
  validation is new),
- **starting class** (from an author-allowed set),
- **stat growths**,
- **special skill(s)**.
Each field is **independently enabled** — a campaign may let the player pick a class but fix growths,
etc.

### [MCH-6] Name / text indirection — **RESOLVED: by unit_id, via foundation F13**
All story/UI text references a unit by **`unit_id`**, resolved to a display name **at render time**;
text is **templated with named placeholders, never concatenated**. This is foundation **F13** (text
indirection / localization-ready string layer) — adopted as a convention now, multi-locale build
deferred. The **avatar's free-text name is a known hard edge** for languages with declension/gender
(accept imperfect grammar or constrain — decide later).

### [MCH-7] Save / F1 schema — **RESOLVED: reserve the roster identity fields**
Reserve in the F1 lock: the **role + bundle toggles** (MCH-2), the **provenance** flag, and the
**player-authored avatar fields** (custom name, portrait ref, chosen class, growth overrides, granted
skill ids). Per-map deployment override lives on map/objective data.

### [MCH-8] Relationship integration — **RESOLVED: main character is the relationship hub**
The "relationship hub" default (MCH-2) makes a main character eligible for many relationships and the
**REL-8 exclusive top-rank slot** — the Avatar "pair/marry with (almost) anyone" behavior, gated by
the same `CampaignRules` exclusivity toggle.

---

## 3. Forward surfaces (authoring/tuning, not open decisions)
- Avatar **gender/pronoun** selection + how pronouns thread through F13 templates (ties to the F13
  gender-variant forward surface).
- Portrait **upload format/size validation** rules (file types, dimensions, the seam/scale already
  in the art pipeline).
- **Boon/bane or stat-allocation UX** for avatar growths (MCH-5) — a creation-screen detail.
- **Multiple main characters** per campaign (co-lords): all are protected by default (MCH-3); whether
  "any one dies" vs "all must die" is the loss is a per-campaign authoring choice.

## 4. Notes
- **A3 hand-off:** Recruit/Capture (#4 ⇄ A4) is next; a recruited unit may itself be flagged a main
  character, and recruit conversations reuse the F13 indirection + REL-6 hooks.
- **DoD:** GDD section(s) + roadmap flip + any `check_docs` checks land **with the build**, not at
  firming time (per the established register pattern).
