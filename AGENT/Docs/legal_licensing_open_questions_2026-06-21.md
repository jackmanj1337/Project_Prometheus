# DOC-012 / OPEN-12 — Legal / Licensing (§3) — Research/Decision Doc + Open Questions

**Started:** 2026-06-21d
**Status:** Planning draft — register OPEN. **DIFFERENT treatment:** this is a
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

### [LEG-1] Source corpus identification — what exactly are we deriving from?  **[OPEN]**
The whole analysis depends on naming the source. (User-owned input — I can't know the corpus
from the code alone; the GDD says "source handbook" without naming a license.)
- **A — User/owner names the corpus + its license** so the analysis can be concrete.
- **B — Enumerate likely candidates** from the GDD's mechanics (weapon triangle, growth/
  caps, class promotion, support ranks…) and ask which the rules were authored from.
- **Rec: B → then A** — I can list the structural content that *looks* corpus-derived from the
  GDD, but the owner must confirm the actual source and its license terms. That confirmation
  is the gating input.
- **Resolution:** _[OPEN — needs the owner to name the source corpus + license]_

### [LEG-2] Mechanics vs expression — reimplement-clean vs license  **[OPEN]**
- **A — Clean-room reimplement mechanics; rewrite all rule TEXT in original wording.**
  Mechanics (formulas, the triangle, growth systems) are reimplemented; no verbatim tables/
  prose from the corpus ship. Lowest legal exposure, no license dependency.
- **B — Rely on an open license** (if the corpus is under OGL/ORC/CC) and ship with the
  required notices, reusing permitted text.
- **Rec: A unless [LEG-1] confirms a permissive license** — clean reimplementation +
  original wording is the safest default and avoids depending on license interpretation; if
  the corpus turns out to be openly licensed (B), that's a bonus that permits reuse with
  attribution. Decide once [LEG-1] is answered.
- **Resolution:** _[OPEN]_

### [LEG-3] Attribution artifact + placement  **[OPEN]**
- **A — A `LICENSES.md` / `ATTRIBUTION.md` at repo root + an in-game credits/legal screen
  entry**, listing any required notices, asset licenses (sprites, fonts), and engine (Godot
  MIT). Standard, discoverable.
- **B — Repo file only** (no in-game surface yet).
- **Rec: A** — most open licenses + asset licenses (and Godot itself) require attribution to
  be *shown* to users, so an in-game legal/credits entry is the safe target; the repo file is
  the canonical source. (Engine + any third-party assets need this regardless of [LEG-1/2].)
- **Resolution:** _[OPEN]_

### [LEG-4] Third-party assets audit (orthogonal but in-scope)  **[OPEN]**
Beyond the rules corpus: sprites, tilesets, fonts, SFX have their own licenses.
- **A — Audit every bundled asset's license now** and record it in the attribution file
  (placeholder FE-ripped sprites must be replaced before public release — overlaps D-A and
  the sprite-importer/asset-pipeline work).
- **Rec: A (no real alternative for a public release)** — placeholder/ripped art is a hard
  blocker for any public build; the asset audit belongs in this gate. Cross-ref the
  `map_sprite_importer` plan (the pipeline that ingests *owned* art to replace placeholders).
- **Resolution:** _[OPEN]_

### [LEG-5] When does this gate run, and what unblocks it?  **[OPEN]**
- **A — After D-A rename, before the first public RC.** D-A removes FE identity; DOC-012
  then clears the corpus + assets. Both are pre-1.0 release gates.
- **Rec: A** (matches the GDD's stated ordering) — the rename must land first (so the
  licensing review isn't reviewing FE-named content); DOC-012 is the final legal clearance
  before any public release. It does not block internal/playtest builds.
- **Resolution:** _[OPEN]_

## 4. Notes
- This is the **one item on the list that is not a coding task** — its output is a decision
  record + an attribution file, not a code change (though [LEG-4]'s asset replacement is
  real work). Kept distinct so it isn't scheduled as an implementation slice.
- **Strong recommendation:** for the corpus-license question ([LEG-1]/[LEG-2]), get the
  actual license text in front of the owner and, if there's any ambiguity about derivative
  digital works, consult qualified counsel before the public release. The cost of a wrong
  call here is far higher than for any gameplay decision on this list.
