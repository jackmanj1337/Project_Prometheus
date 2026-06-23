# Player-Facing Feature Scope Map (Firming Driver)

**Started:** 2026-06-23
**Last verified:** 2026-06-23
**Status:** Active framing / driver — Planned firming work indexed here. **Navigation only, NOT a
second specification** (per DOC-005 the authoritative behavior lives in the owning GDD chapter; this
map only tracks *player-facing definition status* + points to owners).
**Purpose:** Drive the owner's sequencing decision (2026-06-23): **(1) finish defining all
player-facing features → (2) decide what the campaign builder gets to control → (3) decide how to
build it.** This is step (1)'s worklist. Builds on `GDD_Feature_Index.md` (the inventory) by adding a
**player-facing-firming lens** distinct from implementation status.

**Status legend (player-facing definition, NOT impl status):**
- **Firmed** — the player experience is fully specified (built or designed).
- **Designed** — player-facing behavior specified in a design/register, awaiting build.
- **Partial** — core firmed, but named sub-features are player-facing-undefined.
- **GAP** — player-facing behavior not yet defined → needs a firming pass (the worklist).
- **Out-of-scope (now)** — deferred beyond this pass.

---

## 1. Feature groups (from `GDD_Feature_Index.md`) × player-facing definition

| Feature group | P-F status | Owner / where defined | What's left to firm (the gap) |
| --- | --- | --- | --- |
| Combat calc & RNG | **Firmed** (target) | GDD_02 §Combat | none player-facing (two-RN = build/balance) |
| Weapon triangle & rank bonuses | **Firmed** (target) | GDD_04 | none player-facing |
| WEXP & equipment legality | **Firmed** | GDD_04 | none player-facing |
| EXP / leveling / promotion / reclass | **Firmed** | GDD_03, GDD_02 | none (modals exist) |
| Classes & class skills | **Firmed** (mechanic) | GDD_03, GDD_05 | content breadth = data, not a P-F mechanic gap |
| Terrain & movement | **Firmed** | GDD_06 | none |
| Objectives & map authoring | **Firmed** | GDD_06 | none |
| Faction scheduling + hotseat | **Firmed** | GDD_02 | none |
| Save / retry / suspend / rewind | **Firmed** | §2 firming A–J + `[CST-1..12]` | none (rewind *mechanic* = build) |
| UI / input / settings / accessibility | **Firmed / Designed** | GDD_07; input-mode design | gamepad reach = build, not P-F def |
| AI behavior | **Designed** | GDD_08; `[AIP-…]` + AI vision | difficulty-band UX surfaced, design-complete |
| Status conditions | **Designed** (M8) | GDD_02 §Status Conditions | minor UX check-backs only |
| **Skills (per-skill behavior)** | **Partial** | GDD_05; M9b content | **GAP: per-skill player-facing behavior/feedback for the content set (M9b)** |
| **Pair Up & Support** | **Partial** | GDD_05 | Pair Up firmed; **GAP: Support (H2) — ranks/affinity/convos/bonuses; Dual Strike/Guard/adjacent** |
| **Inventory / convoy / shops / economy** | **Partial / GAP** | GDD_04 | inventory/trade exist; **GAP: convoy (D), shop + economy (E)** |
| **Campaign flow & recruitment** | **Partial** | §2 firming; GDD_10 | flow firmed; **GAP: recruit mechanic (F)** |
| Online play | **Out-of-scope** | M15B (post-1.0) | — |

## 2. Player-facing systems designed-but-not-built (roadmap registers, not in the Feature Index yet)
All **Designed** (player-facing behavior specified), awaiting build — *not* gaps for this pass:
- Between-map **prep / deployment** screen (`[CST-5]`, firming C).
- **Fog of War / LoS** `[FOW-1..7]` · **Doors/chests** `[DCH-1..6]` · **Destructible terrain**
  `[DTR-1..8]` · **Map events/triggers** `[MET-1..9]` · **Stationary weapons** `[STW-1..6]`.
- **Map readability / threat range** `[MRD-1..6]` + individual threat range `[TUR-1..4]`.
- **Broken-weapon degraded mode** `[BWN-1..5]`.

## 3. The GAP worklist — player-facing firming still owed
These are the clusters with **undefined player-facing behavior**; finishing them completes step (1).
Each wants an A–J-style firming pass (player experience first, code-side after):
1. **Convoy / inventory management (branch D)** — shared store, prep trade, on-map access, `max_inventory=8`.
2. **Shop / economy (branch E)** — between-map buy/sell, gold sources/sinks, (forge later).
3. **Recruit — green→player (branch F)** — Talk/Recruit action + roster-join UX. (D-D prerequisite.)
4. **Support system (branch H2)** — ranks/affinity/conversations/combat bonuses. Large.
5. **Rescue system (branch H3)** — carry/drop, weight/CON, canto; Pair-Up/Rescue exclusivity prior.
6. **PvP / scenario mode** — standalone non-campaign match (reuses the preserved standings renderer).
7. *(Lighter)* **Skill content per-skill UX (M9b)** + **status-condition UX check-backs (M8)** — more
   content/polish than net-new mechanic definition; can ride their build milestones.

## 4. Sequencing (owner, 2026-06-23) + how this feeds the builder
1. **Finish the §3 GAP worklist** (this pass) — so the full player-facing surface is firmed.
2. **Then** the **campaign-builder authority pass** (the deferred 4a–4e authoring contract in
   `campaign_save_expectations_and_foundations_2026-06-23.md` §4): for each firmed feature, decide what
   a campaign author may **include / configure / exclude / mandate**. This map's feature list becomes
   that pass's checklist.
3. **Then** implementation (rides §2 + Package A execution).

**Not gated by Package A** (that gates §2 *execution*). DoD: firming docs are planning artifacts; each
cluster's GDD chapter + `GDD_Feature_Index` row update + roadmap status flip land **with its build**, not
during firming (the firming output is a player-facing design doc + a decisions register, per the §2 pattern).
