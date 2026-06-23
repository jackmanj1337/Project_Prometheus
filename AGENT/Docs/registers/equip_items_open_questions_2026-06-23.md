---
Type: register
Status: OPEN
Last verified: 2026-06-23
Register: EQP-1..5
---

# Equip Items / Accessories Firming (#3) — Player-Facing Design + Open Questions

**Started:** 2026-06-23k
**Status:** Planning draft — register OPEN. Pairs with convoy (`[CNV]`); has a **half-built mechanic**
in code, so this firming also reconciles real code debt.
**Source:** `player_facing_scope_map_2026-06-23.md` §3b #3 (FIRM v1, "dig-more-later").
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded — verified 2026-06-23k)
- **`InventoryEntry`** (`entry_type=="equip"`) carries four flat fields: `accuracy/damage/crit/dodge`.
  `forged_mods: Dictionary` is **separate** (reserved for forging/M10, deferred).
- **`CombatResolver._apply_equip_item_modifiers()` (`scripts/core/CombatResolver.gd:225`)** loops a unit's
  inventory and, for **every** `is_equip()` entry, adds its 4 fields into the combat mod dict.
  → **passive-while-held, no action, no slot, no exclusivity, applied ONLY at combat time.**
- **`ItemData.item_type`** has `"equip"`; `uses == -1` = "infinite / equippable".
- **`until_unequipped`** duration is defined in `GameConstants` + rendered by `StatBreakdown`
  ("until unequipped") but has **zero producers** — orphaned. Equip bonuses never appear on the
  character sheet out of combat (they're combat-duration only).
- **Stale comments:** `InventoryEntry.gd` "M10 forging — no code reads this yet" is **false** (CombatResolver
  reads the 4 fields); the "Equipment bonus fields (equip type — M10 forging)" header conflates **equip
  accessories** with **forging**.
- **Planned named items** (scope map): Full Guard, Iron Rune, Knight Ring, Wing Guard, Laguz Guard — several
  need **more than 4 combat fields** (Knight Ring = move/canto; Iron Rune = crit-immunity; Laguz/Wing Guard).

## 2. What this pass produces
The equip-item player-facing mechanic + the stat/effect model + the `until_unequipped` wiring decision,
and the code-debt cleanup that lands with the build.

## 3. Open questions register

### [EQP-1] Activation model — passive-while-held vs equip slot/action  **[OPEN]**
- **A — Passive-while-held** (current code): holding an equip item applies its bonus; no action, no slot,
  no exclusivity. Zero new UI; but 5 held = 5 stacked bonuses, and "equip" is a misnomer.
- **B — Equip slot + action:** a unit has accessory slot(s); equipping is an action (prep / unit menu);
  only equipped items apply → exclusivity + sheet visibility. New UI; FE-accurate.
- **C — Hybrid:** passive-while-held but capped (N "active" accessory slots; player picks which apply).
- **Rec: B** — "equip" should mean equipping; a slot gives exclusivity (balance) + a clean producer for
  `until_unequipped` (EQP-4) + out-of-combat sheet visibility. A is lowest-effort but unbounded-stacking
  and invisible on the sheet. Owner's call — it sets the build size.
- **Resolution:** _[OPEN]_

### [EQP-2] Slot count / exclusivity (contingent on EQP-1)  **[OPEN]**
- **A — Single accessory slot** (one equipped accessory per unit). Simplest exclusivity; extensible.
- **B — N slots** (author/rule `max_accessory_slots`).
- **Rec: A** — one accessory slot for v1; a rule-driven N is later data growth. (If EQP-1→A passive, this
  becomes a cap on simultaneous equip bonuses; if EQP-1→B, it's the slot count.)
- **Resolution:** _[OPEN]_

### [EQP-3] Grantable stat/effect model — beyond the 4 combat fields  **[OPEN]**
- **A — General modifier model:** an equip item grants a list of `active_modifiers` (stat → delta, any
  stat incl. STR/DEF/MOV) applied as `until_unequipped` duration, **plus** optional effect hooks
  (movement-type change, skill grant, crit-immunity). The named items need this. The 4 flat fields become a
  convenience subset or migrate in.
- **B — Combat-only (4 fields) for v1;** defer stat/skill/movement-granting accessories.
- **Rec: A** — the planned named items (Knight Ring move, Iron Rune crit-immunity, Laguz Guard) require
  >4 fields; build the general model now (it also gives EQP-4 its producer). Reuses the existing
  `add_modifier`/`active_modifiers` machinery.
- **Resolution:** _[OPEN]_

### [EQP-4] `until_unequipped` wiring — give the orphaned label a producer  **[OPEN]**
- **A — Wire it up:** equipping (EQP-1) / holding produces real `until_unequipped` `active_modifiers`
  (removed on unequip), so bonuses show on the character sheet (in + out of combat) and the existing label
  has a producer. Supersedes combat-time-only application.
- **B — Remove the orphaned label/duration;** keep combat-time-only application (bonus invisible on sheet).
- **Rec: A** — wiring removes the "no producer" debt and makes equip bonuses visible on the sheet (good UX);
  ties to EQP-3 (the granted modifiers ARE `until_unequipped`). Combat-time-only (B) hides the bonus.
- **Resolution:** _[OPEN]_

### [EQP-5] Code-debt cleanup (lands with the build)  **[OPEN]**
- **A — Reconcile in the same change:** fix the false `InventoryEntry.gd` "no code reads this yet" comment;
  **separate equip-accessory fields from forging** in the comments/headers (`forged_mods` stays forging/
  deferred); add a `test_equip_items.gd` for the chosen mechanic. DoD#2-style.
- **Rec: A** — the comments actively mislead; reconcile + test with the build (no standalone doc-only change).
- **Resolution:** _[OPEN]_

## 4. Notes
- **Forging (M10) stays deferred** and **distinct** from equip accessories — this register must not absorb it
  (only disentangle the comments). `forged_mods` is forging's; the equip bonus model is EQP-3's.
- **Save impact (§2):** equipped-accessory state is per-unit inventory (already serialized); a slot model
  (EQP-1→B) adds an "equipped accessory" pointer per unit — small per-save addition, reserve room.
- DoD: GDD chapter + `GDD_Feature_Index` row + roadmap status flip land **with the build**, not now.
