# Campaign Rules Firming Notes — 2026-05-25

Purpose: keep a short list of design constraints visible while the Phase 3
campaign loop is still being specified.

## Decision locked today

- `pair_up`, `support`, and `rescue` should be treated as **campaign rules**.
- They should not be implemented as ad-hoc map flags unless a future campaign
  mode explicitly overrides the default ruleset.

## Why this matters

- These rules affect the save schema, because they change long-term unit state
  and what data must persist between maps.
- They affect prep/deployment UX, because the player needs one clear place to
  understand and manage the current campaign rules.
- They affect roster/content authoring, because map balance, skill value, and
  unit identity shift a lot depending on whether these systems are enabled.

## Related design areas that should be firmed up together

- Campaign structure:
  chapter progression, map unlock flow, branching, and what "Continue" loads.
- Save/load ownership:
  which state belongs to the campaign save, which belongs only to a mid-battle
  suspend save, and which values are derived from static content.
- Prep/deployment flow:
  deployment limits, benching, convoy access, inventory management, and whether
  support/pair-up/rescue setup can be changed before battle.
- Progression rules:
  skill cap enforcement, inventory cap enforcement, promotion/reclass
  persistence, forge persistence, and any support-rank or rescue-related state.
- UI surfaces:
  where the player can read the active campaign rules and how rule-dependent
  actions are explained when unavailable.

## Questions to answer before the full campaign loop is built

1. Are these campaign rules chosen only on `New Game`, or can they change later?
2. If they can change later, is that a per-save permanent toggle, a difficulty
   preset, or a chapter-by-chapter override?
3. What state must persist for each rule?
   Pair Up: existing pairings only, or also support progression / affinity data?
   Support: rank, affinity, unlocked conversations, passive bonuses?
   Rescue: carried unit state, canto interactions, move penalties, drop rules?
4. How do Pair Up and Rescue coexist?
   Mutual exclusion is the safest default unless a later ruleset explicitly says
   otherwise.
5. Does the prep screen allow rule-dependent setup?
   Examples: form Pair Ups pre-map, break Pair Ups, review support bonuses,
   assign convoy inventory with rescue-ready weight/CON considerations.
6. How does save migration behave when a later version adds or reshapes any of
   these systems?

## Recommended defaults

- Campaign rules are selected on `New Game` and stored in the campaign save.
- They remain stable for the life of that save unless there is a deliberate
  ruleset-migration feature.
- Campaign saves store rule flags explicitly, not inferred from content.
- Pair Up and Rescue should be designed as mutually exclusive until a concrete
  combined ruleset is specified and tested.
- Support data should be versioned separately from map runtime state so future
  save migrations stay manageable.

## Follow-up

- When the between-map save/load design starts, use this note as a checklist.
- When the prep/deployment screen is specced, fold the settled answers back into
  the relevant GDD files and remove any resolved questions from this note.
