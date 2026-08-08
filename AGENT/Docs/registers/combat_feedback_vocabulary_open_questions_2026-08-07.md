---
Type: register
Status: OPEN
Last verified: 2026-08-08
Register: CFB-1..18
---

# Combat Feedback Vocabulary — Owner Questions and Decisions

**Started:** 2026-08-08, the first owner walk of
[`combat_feedback_vocabulary_research_2026-08-07.md`](../design/combat_feedback_vocabulary_research_2026-08-07.md),
the shared `CFB` doc the `SKF`/`CAU`/`DUX` rows all read. This register is the live source of
truth for `CFB-n` status — the research doc's own "open questions" section now just points here
rather than duplicating.

**Session-by-session, not closed in one sitting** — per the handoff's own caution, this trio was
never meant to close in one session. This walk moved fast on the presentation/choreography shape
and deliberately deferred one hard question (animation reuse, `[CFB-18]`) to next-session
research rather than guess at an engine-architecture commitment.

## Resolved decisions — 2026-08-08

### [CFB-1] Failed activation-chance roll gets no feedback — **RESOLVED**
Silence. `SkillData.activation_chance_stat`/`activation_divisor` model a real per-skill roll that
can miss; a miss is genuinely "nothing happened," unlike an immunity/negation (`[CFB-2]`, still
open) where an external cause explains the non-event. Established by the choreography decision
below, which only shows skills "that activate."

### [CFB-5] Callout-volume/clutter control — **RESOLVED, reframed**
Originally framed as an author-authored per-skill channel override. Resolved instead as a
**player-facing settings checkbox list** disabling notification categories — see `[CFB-12]`.
Authors do not get a per-skill visibility override in v1.

### [CFB-9] Combat choreography model — **RESOLVED (provisional — "for now")**
One cycle, repeated independently for every strike in an exchange (initial attack, counter,
follow-up/double):
1. Every skill/bonus that activates for this strike shows its name + icon above its holder's
   head, one at a time, in activation order (icon may be transparent if none authored).
2. The attacking unit backs up slightly, runs partway into the defender's tile (a stylized clash
   position — the unit's logical tile never changes), plays an impact sound, holds one frame, then
   retreats to its resting position, alongside "Hit XX" / "No Damage" / "Miss" text.
3. On a Miss, the defending unit backs up half a tile away from the attacker before returning, so
   the units never visually overlap.

Explicitly a first pass, expected to be revised once real art/animation work starts.

### [CFB-10] Resolution pipeline + start/end callout placement — **RESOLVED**
Code-verified pipeline (`CombatResolver.gd`): **Phase A** (once per exchange, before any strike) —
pair-up bonuses → `active_modifiers` → allied `on_combat_apply_modifiers` auras → equip-item
modifiers → `on_combat_start_negate` pre-pass → `on_combat_start` (Vantage gets flagged here) —
**then** strike order (Vantage-flip / attacker / counter / follow-up, each running the per-strike
`on_attack → on_hit → on_damaged → on_kill` sequence) — **then Phase D** (once per exchange, after
every strike) — `on_combat_end`.

Both Phase A and Phase D get **exactly one callout section**, once per whole exchange — not
repeated per strike. This mirrors the code structure directly: both phases are already dispatched
once, attacker-then-defender, outside the strike loop.

Note: `on_defend` is spec vocabulary with **zero dispatch code anywhere** in `CombatResolver.gd`
or `SkillHandler.gd` — do not design its ordering relative to `on_attack`; it does not exist yet.

### [CFB-11] Callout scope = every Phase A/D modifier source, not just skills — **RESOLVED**
Pair-up bonuses, the generic `active_modifiers` bucket, ally auras
(`on_combat_apply_modifiers`), equip-item modifiers, and actual `SkillData` triggers **all** get a
callout. No "is this a real skill" filtering.

### [CFB-12] Player-facing notification-category checkboxes — **RESOLVED, one sub-item open**
Proposed groups: **Skill activations**, **Pair-Up bonuses**, **Equipment bonuses**, **Ally aura
effects**, **Status effects** (reserved row, inert until `ConditionManager` leaves stub status
under M8/M9).

**Still open:** does the generic `active_modifiers` bucket fold into "Skill activations" for
display (proposed, not yet confirmed), or get its own row? A player can't tell it apart from a
skill without deep inspection, which is the argument for folding it in.

### [CFB-14] Reserve a seam for a future detailed/cinematic renderer — **RESOLVED**
A later, higher-fidelity "Full" battle-scene renderer (in the spirit of classic Fire Emblem /
Fire Emblem Engage's close-up combat view) consumes the **same** ordered per-exchange event stream
as the `[CFB-9]` "Simple" choreography. Adding it later is a new presentation implementation, not
a new event/data model. See the research doc's comparable-systems section for what could and
couldn't be confirmed about recent FE titles' own animation settings.

### [CFB-15] Per-player, per-context detail/speed setting — **RESOLVED**
Three tiers — **Off** (fast, no choreography, closest to today's instant `combat_resolved`) /
**Simple** (`[CFB-9]`, built now) / **Full** (`[CFB-14]`'s seam, not built) — set independently
**per local player/seat**, for three contexts:
- their own turn
- not their turn, but one of their units is the attacker or the defender in this exchange
- not their turn and neither unit is theirs (spectate)

"Involved" is scoped to **attacker/defender only** for now — explicitly does not (yet) cover
indirect participants from the unbuilt redirect/cover/reactive-reposition interceptor family;
revisit once that family is built. The `[CFB-12]` category checkboxes only apply when the tier is
`Simple` or `Full` — `Off` skips everything, categories included.

### [CFB-16] Full-tier gating — **RESOLVED (coarse), OPEN (fine)**
**Coarse (resolved):** `Full` is only offered as a selectable tier at all if the active campaign
pack declares (via `[CFB-17]` asset presence) any cinematic art — no dead option pointing at
nothing.

**Fine (still open):** within an offered `Full` tier, a specific unit/strike lacking the asset for
that specific combination falls back to `Simple` automatically — proposed, not contradicted, but
whether that fallback is silent or the player is told once is not yet decided.

### [CFB-17] Author capability declaration = asset presence, not a separate flag — **RESOLVED**
A class/weapon/skill record either has an authored on-map-attack-asset reference and/or a
cinematic-art reference, or it doesn't — that presence **is** the author's declaration. No
redundant boolean flag to keep in sync with the actual assets, matching how `SkillData
.release_available` already keeps unfinished content inert without a second bookkeeping field. A
derived pack-level summary badge (for a campaign-library "supports cinematic battles" indicator)
can be computed from that presence later if wanted, not hand-authored.

The `[CFB-9]` approach-toward-enemy-square animation is an **engine-guaranteed default** requiring
no authored assets at all — a zero-content pack never has a broken or missing animation state,
just the plainest one.

## Still open — carried to next session

### [CFB-2] Immunity/negation feedback threshold — **OPEN**
Tension with `[CFB-11]`: "every bonus gets a callout" was decided, but an immunity/negation isn't
a bonus — it's an attempted-and-blocked effect. Does it get the same always-on treatment as
`[CFB-11]`'s modifier sources, or does it need its own rule? Not yet decided either way.

### [CFB-3] Combat log surface style — **OPEN**
Always-open sidebar, opt-in overlay, or opened on demand? Note from this session: `[CFB-9]`'s live
choreography now carries most of what a log would have shown, so the log's role may be narrower
than the research doc originally scoped it — probably a "what happened while I wasn't looking"
reconstruction aid (useful for AI turns) rather than the primary channel. Revisit the framing, not
just the UI shape, next session.

### [CFB-4] Log content symmetric with `PER-9`, or per-viewer — **OPEN**

### [CFB-6] Status icon placement and interaction — **OPEN**
Blocked on `ConditionManager` leaving stub status regardless of when this is decided.

### [CFB-7] Banner budget — **OPEN**
Note from this session: with the above-head callout channel (`[CFB-9]`) now covering most
skill/modifier events, banners' remaining role is probably narrower than the research doc
scoped — likely rare/dramatic only (a revival, a full negation of a signature skill). Revisit
scope, not just the list of candidate events.

### [CFB-8] Hidden-actor event redaction — **OPEN**

### [CFB-13] Does disabling a notification category also skip its time budget? — **OPEN, assumed pending confirmation**
Stated as an assumption during the walk ("disabling a group doesn't just hide its callout, it
skips the beat entirely") and not contradicted, but never explicitly confirmed either — the
conversation moved on to `[CFB-14]`/`[CFB-15]` before it was answered directly. Confirm next
session rather than treat as settled.

### [CFB-18] Animation-selection hooks (source / method / skill trigger / crit) — **OPEN — next-session research**
Owner's stated goal: allow visual variation **without re-authoring a full animation per variant**
— e.g. a simple axe and a fancy axe share the same swing motion with different weapon art, or a
fire spell and a lightning spell share the same cast gesture with different effects layered on
top. Additionally: a specific attack method, an active skill trigger, or a crit should be able to
swap in a distinct swing/animation when applicable.

**Not yet decided, and explicitly deferred rather than guessed at:** whether the hook resolves to
genuine compositing — multiple animation layers (base motion + skill overlay + crit flourish)
playing simultaneously, which is real `AnimationTree` blending work — or a single best-matching
clip chosen by priority order (skill-specific → crit → weapon/method default → engine generic),
which is a lookup table, no blending required.

**Next-session task:** research animation-reuse architecture before deciding. Starting points to
scope, not yet investigated: Godot `AnimationPlayer`/`AnimationTree` animation libraries and blend
layers; attachment-point sprite/texture swapping over a shared skeleton or shared frame timing;
how classic FE-style sprite work separates base motion from weapon art today (if it does). The
resolution keys are already settled regardless of mechanism — `cause_id` (skill trigger), the
strike's weapon/method (source), and crit status, reusing fields the `[CFB]` event record already
carries — only the compositing-vs-lookup technical commitment is open.

## Next session

1. Animation-reuse research (`[CFB-18]`), before any further animation-hook decisions.
2. Resume the walk: `[CFB-2]`, `[CFB-3]`/`[CFB-4]` (now re-scope the log's role first), `[CFB-6]`,
   `[CFB-7]` (re-scope banner role first), `[CFB-8]`.
3. Confirm the two flagged sub-items: `[CFB-12]`'s `active_modifiers` fold-in, `[CFB-13]`'s
   disable-skips-time assumption, `[CFB-16]`'s silent-vs-notify fallback.
4. `CAU`/`DUX` packets have not been started — `SKF`-adjacent choreography decisions above will
   need to be checked against `CAU`'s named action family once that packet opens.
