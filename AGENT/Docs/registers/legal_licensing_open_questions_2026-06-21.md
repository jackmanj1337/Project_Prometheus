---
Type: register
Status: RESOLVED 2026-07-20
Last verified: 2026-07-20
Register: LEG-1..5
Resolved-in: 2026-07-20 — decision_record_2026-07-20_leg_licensing_gate.md (questions answered; gate not cleared: LEG-2 remedy + LEG-4 asset audit outstanding)
---

# DOC-012 / OPEN-12 — Legal / Licensing (§3) — Research/Decision Doc + Open Questions

**Started:** 2026-06-21d
**Status:** **RESOLVED 2026-07-20** (see banner below; register retained as history).
**DIFFERENT treatment:** this is a
**research/decision doc, NOT a code-grounded technical plan** (flagged as such in session
note 2026-06-21c so it isn't mistaken for an implementation plan). A blocking pre-1.0 gate.
**Source:** `planning_backlog_2026-06-20.md` §3; `GDD_10` §Legal/Licensing Gate (DOC-012 /
OPEN-12, lines 847–853); session note 2026-06-21c "Different treatment".
**Owner:** a **DOC-012 decision record** (the deliverable this becomes).
**Relationship to D-A:** runs **AFTER** the public-identity rename; the rename does NOT
resolve licensing.
**⚠️ Not legal advice.** I am not a lawyer; this register frames the questions and options
so the project owner can decide and, where warranted, seek qualified counsel.
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

> **RESOLVED 2026-07-20.** LEG-1..5 are answered in
> `../decisions/decision_record_2026-07-20_leg_licensing_gate.md`. **Read that first** —
> this register's framing below is superseded on one central point.
>
> **[LEG-1] found there is no source corpus.** The rules are the owner's own design,
> FE-inspired but not authored from any published handbook. §1 "State today" and the GDD
> both assume a "source handbook" that does not exist; treat those passages as historical.
> That collapses the corpus-license analysis — the largest part of this gate — entirely.
>
> **The gate is answered but not cleared.** Two items remain: the FE-derived *numeric
> values* called out in [LEG-2] (audit pending, `LEG-AUDIT-FE-NUMBERS-2026-07-20`) and the
> per-asset audit in [LEG-4], which is now the largest remaining work. §4's art-asset
> policy stands unchanged and is still the governing guidance.

---

## 1. State today

- **Blocking pre-1.0 gate, no research doc exists.** Before any public release, the source
  handbook/corpus license for derivative digital works must be researched and an attribution
  strategy decided.
- **Scope (from the GDD):** *all corpus-derived rules, text, and structural content.*
- **Two things are entangled but distinct:**
  1. **Mechanics/rules derived from a tabletop or published corpus** (the "source handbook"
     the GDD references) — game *mechanics* are generally not copyrightable, but specific
     *expression* (rule text, tables, named content) can be.
  2. **Fire Emblem–derived names/identity** — handled by the **D-A rename** (a separate
     gate), which removes the trademarked/character identity surface. DOC-012 is about the
     *corpus*, not the FE names.
- **No attribution/licenses file** is present for any borrowed structural content.

## 2. What this doc must produce (the DOC-012 decision record)

1. **Identify the source corpus/corpora** precisely — which published material the rules,
   tables, and structural content derive from, and under what license that material is
   distributed (e.g. an OGL/ORC-style open license, all-rights-reserved, CC, etc.).
2. **Determine what is reusable** — the idea/expression split for that corpus: which
   mechanics are free to reimplement, which *text/tables* must be rewritten or licensed.
3. **Decide the attribution strategy** — required notices, a `LICENSES`/`ATTRIBUTION` file,
   any "compatible with"/"derived from" statements, and what must NOT be copied verbatim.
4. **Confirm no residual trademarked identity** post-D-A (cross-check the rename's coverage).
5. **A go/no-go checklist** the release process gates on.

## 3. Open questions register

### [LEG-1] Source corpus identification — what exactly are we deriving from?  **[RESOLVED]**
The whole analysis depends on naming the source. (User-owned input — I can't know the corpus
from the code alone; the GDD says "source handbook" without naming a license.)
- **A — User/owner names the corpus + its license** so the analysis can be concrete.
- **B — Enumerate likely candidates** from the GDD's mechanics (weapon triangle, growth/
  caps, class promotion, support ranks…) and ask which the rules were authored from.
- **Rec: B → then A** — I can list the structural content that *looks* corpus-derived from the
  GDD, but the owner must confirm the actual source and its license terms. That confirmation
  is the gating input.
- **Resolution:** **[RESOLVED 2026-07-20]** — **there is no source corpus.** The rules are
  the owner's own design, FE-inspired but not authored from a published handbook. The GDD's
  "source handbook" phrasing is inaccurate and is queued for correction. See
  `decisions/decision_record_2026-07-20_leg_licensing_gate.md`.

### [LEG-2] Mechanics vs expression — reimplement-clean vs license  **[RESOLVED]**
- **A — Clean-room reimplement mechanics; rewrite all rule TEXT in original wording.**
  Mechanics (formulas, the triangle, growth systems) are reimplemented; no verbatim tables/
  prose from the corpus ship. Lowest legal exposure, no license dependency.
- **B — Rely on an open license** (if the corpus is under OGL/ORC/CC) and ship with the
  required notices, reusing permitted text.
- **Rec: A unless [LEG-1] confirms a permissive license** — clean reimplementation +
  original wording is the safest default and avoids depending on license interpretation; if
  the corpus turns out to be openly licensed (B), that's a bonus that permits reuse with
  attribution. Decide once [LEG-1] is answered.
- **Resolution:** **[RESOLVED 2026-07-20 — A, by construction; one exception outstanding]**
  [LEG-1] removed the corpus, so there is no rule text to rewrite and no license to
  interpret. **Exception:** some numeric values were taken from FE wiki data. Owner intent is
  that FE-derived numbers live in `Campaign_Pack_FE` (internal testing only, never
  published), not in the public source tree. These values are the *live balance* in
  `data/weapons/*.tres` and `data/classes/*.tres`, so the remedy is not a file move — it is
  retune-in-place, or a real split via `B3-CAMPAIGN-RULES`. **Remedy deferred pending
  `LEG-AUDIT-FE-NUMBERS-2026-07-20`**, which measures the actual exposure first. LEG-2 is
  answered in principle but **unremediated**; the gate is not cleared until the audit reports.

### [LEG-3] Attribution artifact + placement  **[RESOLVED]**
- **A — A `LICENSES.md` / `ATTRIBUTION.md` at repo root + an in-game credits/legal screen
  entry**, listing any required notices, asset licenses (sprites, fonts), and engine (Godot
  MIT). Standard, discoverable.
- **B — Repo file only** (no in-game surface yet).
- **Rec: A** — most open licenses + asset licenses (and Godot itself) require attribution to
  be *shown* to users, so an in-game legal/credits entry is the safe target; the repo file is
  the canonical source. (Engine + any third-party assets need this regardless of [LEG-1/2].)
- **Resolution:** **[RESOLVED 2026-07-20 — B for now, A deferred]** `ATTRIBUTION.md` at repo
  root is the canonical source and is the only required artifact today. The in-game
  legal/credits screen is **deferred, not cancelled** — Godot (MIT) and most asset licenses
  require attribution be *shown* to users, so it becomes a **release blocker at the first
  public RC**. Tracked as `LEG-INGAME-ATTRIBUTION-2026-07-20` so it does not resurface as a
  surprise at the release gate.

### [LEG-4] Third-party assets audit (orthogonal but in-scope)  **[RESOLVED]**
Beyond the rules corpus: sprites, tilesets, fonts, SFX have their own licenses.
- **A — Audit every bundled asset's license now** and record it in the attribution file
  (placeholder FE-ripped sprites must be replaced before public release — overlaps D-A and
  the sprite-importer/asset-pipeline work).
- **Rec: A (no real alternative for a public release)** — placeholder/ripped art is a hard
  blocker for any public build; the asset audit belongs in this gate. Cross-ref the
  `map_sprite_importer` plan (the pipeline that ingests *owned* art to replace placeholders).
- **Resolution:** **[RESOLVED 2026-07-20 — A, as recommended]** No alternative exists for a
  public release. The sourcing/redistribution **policy** in §4 (analysis 2026-06-22h) stands as
  written; the per-asset **audit** itself still runs at release. The `map_sprite_importer`
  register points here as a pre-import gate. With [LEG-1] resolved, this is now the **largest
  remaining item** in the gate.

### [LEG-5] When does this gate run, and what unblocks it?  **[RESOLVED]**
- **A — After D-A rename, before the first public RC.** D-A removes FE identity; DOC-012
  then clears the corpus + assets. Both are pre-1.0 release gates.
- **Rec: A** (matches the GDD's stated ordering) — the rename must land first (so the
  licensing review isn't reviewing FE-named content); DOC-012 is the final legal clearance
  before any public release. It does not block internal/playtest builds.
- **Resolution:** **[RESOLVED 2026-07-20 — A, as recommended]** The gate runs after the REN
  public-identity rename and before the first public RC. It does **not** block internal or
  playtest builds; v0.5.2 and its successors are unaffected. Includes a REN cross-check
  confirming no residual trademarked identity.

## 4. Art-asset licensing policy (release-art sourcing) — analysis 2026-06-22h

Expands [LEG-4] with the sourcing/redistribution policy worked out 2026-06-22h. **⚠️ Not legal
advice** (see header). **Owner-stated inputs:** release under **MIT + Commons Clause** (source-
available, no-sell); first-release art = **32px** FE-style; later tier = 64px. **Driving fact:** a
**source-available public repo redistributes every committed file**, so the asset license — not the
project license — governs what may ship in source.

### 4.1 The governing principle
- **Project license ≠ asset license.** MIT + Commons Clause covers the project's *original* work;
  every third-party asset keeps **its own** license. You cannot relicense someone else's art by
  committing it. Maintain a per-asset manifest (ties [LEG-3]: `ATTRIBUTION.md` / `ASSET_LICENSES`).
- **The crux is redistribution, not price.** Shipping a "no-redistribute" pack *inside an exported
  build* is normal, permitted use even for a free game. **Committing the raw asset files to the
  public repo is redistribution of the assets as assets** — which most paid packs forbid. So the
  filter is "public source tree," not "free game."

### 4.2 License whitelist for anything committed to the public repo
Ordered by fitness for a public MIT+Commons-Clause repo that **might monetize later**:
1. **CC0** — redistributable, no attribution, survives a future switch to selling, no DRM clause. **Preferred.**
2. **OGA-BY / CC-BY** — redistributable, attribution required, sale-safe (OGA-BY removes the DRM clause).
- **Avoid:** **CC-BY-NC / "non-commercial"** (Commons Clause makes these *usable now* since you are
  not selling, but they **permanently foreclose monetization** — a trap); **CC-BY-SA / GPL**
  copyleft (redistributable but imposes ShareAlike on art derivatives + a Steam/iOS DRM-clause
  problem); **"no-redistribute" paid packs** (PIPOYA / HEROES 99 / Zerie etc.) for *committed* art.

### 4.3 Rules
- **Committed (public-repo) art:** CC0 or OGA-BY only.
- **No-redistribute paid packs:** allowed **only inside exported builds as placeholder**, never in
  the public source tree.
- **Fire Emblem fan art / rips:** dev placeholder **only**; **never** in a public source-available
  repo (that *publishes* the infringement in source form). No license the project applies cures the
  underlying Nintendo IP — you cannot license what you do not own. Cured only by *replacement*.
- **Commission = cleanest for a source-available project.** With **full copyright assignment
  (work-for-hire)** you own the art outright → license it freely, trivially public-repo-safe and
  sale-safe, and you can order the **FE-specific classes no pack covers** (mounted cavalry,
  pegasus/wyvern fliers). This sidesteps the entire per-asset compatibility maze.

### 4.4 Resolution-tier interaction (informs the sprite importer / `SPRITE_SOURCE_SIZE`)
- The biggest **public-repo-safe breadth source — the LPC generator restricted to CC0/OGA-BY layers
  — is ~64px, not 32**, so it fits the **later 64px tier**, not the 32px first release.
- For the **32px first release**, the redistributable pool collapses to **fragmented CC0
  OpenGameArt sets** (piecemeal, no fliers/mounts) → **commission** is the reliable route to a
  cohesive owned roster.

### 4.5 Candidate sources (2026-06-22h scan; verify each license at use-time)
- Public-repo-safe: **OpenGameArt** CC0/OGA-BY sets (32px, fragmented); **Kenney** (all CC0, weak on
  FE-class characters); **LPC** CC0/OGA-BY subset (~64px, strong breadth, fits the 64px tier).
- **Build-only placeholder (not committable):** PIPOYA 32×32 (4-dir, "no redistribute"); **HEROES
  99** (32px, GBA-FE style, modular, great license **but** overworld 4-dir sprites still in
  development — battle anims only today); Zerie Tiny RPG.

## 5. Notes
- This is the **one item on the list that is not a coding task** — its output is a decision
  record + an attribution file, not a code change (though [LEG-4]'s asset replacement is
  real work). Kept distinct so it isn't scheduled as an implementation slice.
- **Strong recommendation:** for the corpus-license question ([LEG-1]/[LEG-2]), get the
  actual license text in front of the owner and, if there's any ambiguity about derivative
  digital works, consult qualified counsel before the public release. The cost of a wrong
  call here is far higher than for any gameplay decision on this list.
