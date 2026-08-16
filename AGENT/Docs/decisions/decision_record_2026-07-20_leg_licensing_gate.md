---
Type: decision-record
Status: Applied
Last verified: 2026-07-20
Decision IDs: LEG-1..5
---

# Decision Record — DOC-012 / OPEN-12 Legal & Licensing Gate (2026-07-20)

**⚠️ Not legal advice.** This record captures the owner's answers and the reasoning
around them. Where it says exposure is low, that is an engineering judgement, not a
legal opinion. The recommendation in the register to seek qualified counsel before a
public release still stands.

## Context

`legal_licensing_open_questions_2026-06-21.md` framed LEG-1..5 as a blocking pre-1.0
gate. The whole analysis was suspended on LEG-1: the GDD referenced a "source
handbook" without naming it or its license, so no idea/expression split could be
performed. The 2026-07-20 owner session resolved LEG-1, which collapsed most of the
gate.

## Decisions

| ID | Decision | Applied in |
|---|---|---|
| LEG-1 | **There is no source handbook.** The rules, tables, and structural content are the owner's own design, informed by playing Fire Emblem — not authored from a published tabletop corpus. The GDD's "source handbook" phrasing is inaccurate and must be corrected. | This record; GDD §Legal/Licensing Gate |
| LEG-2 | **Clean-room by construction, with one exception.** With no corpus there is no license to interpret and no rule text to rewrite. However, *some numeric values were taken from FE wiki data*. The owner's intent is that FE-derived numbers live in `Project_Prometheus_Campaign_Pack_FE` — internal testing only, never published — and not in the public source tree. **Remedy deferred pending an audit** (see below). | This record; `LEG-AUDIT-FE-NUMBERS-2026-07-20` |
| LEG-3 | **Repo file only for now.** `ATTRIBUTION.md` at repo root is the canonical source. The in-game legal/credits screen is **deferred**, not cancelled. | This record |
| LEG-4 | **Audit every bundled asset at release; record in the attribution file.** Unchanged from the register's recommendation. The sourcing/redistribution policy in register §4 stands: committed art is CC0 or OGA-BY only; no-redistribute paid packs are build-only placeholder; FE rips are dev placeholder and never enter a public source-available repo. | Register §4 (already drafted) |
| LEG-5 | **After the REN public-identity rename, before the first public RC.** Does not block internal or playtest builds. v0.5.2 and its successors are unaffected. | This record |

## Consequences

### The gate shrank, but did not close

LEG-1 removes the corpus-license question entirely — the largest and most
open-ended part of DOC-012. What remains is narrower and more concrete:

1. The **FE-derived numeric values** (LEG-2), pending audit.
2. The **asset audit** (LEG-4), which was always the real work and is unchanged.
3. A **REN cross-check** (LEG-5) confirming no residual trademarked identity.

Game *mechanics* — the weapon triangle, growth/cap systems, promotion, support
ranks — are generally not copyrightable, so an independently authored FE-inspired
system carries no corpus exposure. The residual risk surface is **names and
identity**, which the REN gate owns, and **art assets**, which LEG-4 owns.

### The FE-numbers remedy is not a file move

The owner's stated intent is to move FE-derived numbers into Pack_FE. Note that
these values are **not** held in a separate reference document — they are the live
balance values in `data/weapons/*.tres` and `data/classes/*.tres`. `iron_sword.tres`
carries `mt`/`hit`/`wt`/`uses`/`cost`; every class resource carries
`player_growth_rates`, `enemy_growth_rates`, and `stat_caps`. Relocating them
removes the public repo's game balance and requires replacement values.

Three remedies were considered:

- **Retune in place** — change flagged values so they are demonstrably
  independently derived. Cheapest; no architecture required. Raw stat numbers are
  weak copyright subjects, so this is likely proportionate.
- **Real split via B3 rule profiles** — the public repo ships a neutral baseline
  profile; Pack_FE carries the FE-faithful numbers as an internal testing profile.
  Cleanest, and matches the owner's stated intent, but blocks on
  `B3-CAMPAIGN-RULES-2026-07-19`, which is itself gated behind v0.5.2 acceptance.
- **Audit first** — **chosen.** Measure the actual exposure before picking a
  remedy. The affected set may be a handful of weapon rows rather than the whole
  balance table, in which case retuning in place is clearly proportionate and the
  B3 dependency is avoided.

`LEG-AUDIT-FE-NUMBERS-2026-07-20` carries the audit. Its output — which entries read
as transcribed vs independently tuned — selects the remedy. Until it reports, LEG-2
is **answered in principle but unremediated**, and the gate cannot be marked cleared.

### LEG-3 defers a requirement rather than removing one

Godot ships under MIT and most asset licenses require attribution be *shown to
users*, not merely recorded in a repo file. Choosing repo-file-only is fine while
builds are internal, but the in-game legal/credits entry becomes a **release
blocker** at the first public RC. It is registered as a follow-up so it does not
resurface as a surprise at the release gate.

### Documentation correction

The GDD's "source handbook" language (GDD_10 §Legal/Licensing Gate, lines 847-853)
asserts a corpus that does not exist. It should be corrected so a future reader —
human or agent — does not reopen this analysis on a false premise.

## Follow-ups

| Task | What |
|---|---|
| `LEG-AUDIT-FE-NUMBERS-2026-07-20` | Audit `data/weapons` and `data/classes` against FE reference values; report which entries read as transcribed. Selects the LEG-2 remedy. |
| `LEG-INGAME-ATTRIBUTION-2026-07-20` | In-game legal/credits screen. Deferred by LEG-3; blocks the first public RC. |
| GDD correction | Fix the "source handbook" phrasing in GDD_10 §Legal/Licensing Gate. |
| REN cross-check | Per LEG-5, confirm no residual trademarked identity after the rename lands. |
