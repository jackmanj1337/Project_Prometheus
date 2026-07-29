---
Type: plan
Status: Planned - playtest-waiting implementation handoff
Last verified: 2026-07-16
---

# Playtest-Waiting Work Queue Handoff - 2026-07-16

## Purpose

Make useful, dependency-valid progress while the v0.4.1 and campaign/save Windows
returns are outstanding. The Project Control Plane now owns the full candidate
queue and ordering. This handoff defines how to start draining it without
invalidating the external evidence already in flight.

Work on `agent/codex/2026-07-15/prep-save-followup`, or branch from its clean
head when isolation is useful. The current head includes the implemented
between-AI-activations suspend path and its evidence. Do not modify or rebuild the
existing `dd4f971` campaign/save artifact or either outstanding checklist package.

## Preemption rule

At the beginning of a session and before beginning each new logical commit, check
whether either live return has arrived. If it has, stop at the current green
commit and intake/triage the returned checklist, original log, platform/input
details, and screenshots before continuing this queue. Do not mix returned-result
repairs into an unfinished feature commit.

## Ordered implementation queue

### 1A. `B5-AI-MIN-SCORER` owner walkthrough

Before expanding tactical adoption beyond the bounded compatibility-preserving
slice, walk through
[`weapon_attack_scorer_preimplementation_decisions_2026-07-16.md`](weapon_attack_scorer_preimplementation_decisions_2026-07-16.md)
with the owner and record the selected options in its decision table. The review
must cover scope, adopting profiles, expected damage/kill probability, acceptable
sacrifice, strike order, weapon conservation, terrain/exposure, target/objective
value, tie-breaking, performance, and compatibility/save rollout.

This is a headless-safe planning task while the Windows evidence is outstanding.
It does not authorize implementation by itself. If playtest evidence returns,
preempt the walkthrough under the same rule as implementation work. Until the
relevant choices are settled, retain the shipped compatibility preset and do not
widen the tactical preset's live profile adoption.

### 1. `B5-AI-MIN-SCORER` - recommended first

Build the narrow deterministic scorer on the existing Projection Service and AI
profile composition seam.

This is **Slice 3A** of the AI plan, not the full track-closing scorer. It is
available now because it covers only weapon attacks the present AI already plans
and executes. `B5-SOURCE-STYLE`, remaining `B5-AI-COMPOSITION`, and `B3-MET`
still gate full action-palette parity in Slice 3B.

Bounded contract:

- score only actions the present AI can already plan and execute;
- use projection terms such as expected damage, lethal result, counter-damage,
  exposure, and target value;
- use no new randomness and resolve full ties with stable unit/tile identifiers;
- keep shipped profile behavior available as a compatibility preset;
- leave lookahead, hidden information, learned evaluation, and multi-activation
  search in `B7-AI-ADVANCED-VALUATION`;
- add score-component diagnostics useful in headless failures without spamming
  release logs.

On landing, mark `B5-AI-MIN-SCORER` **Split**, with the exact implemented subset
and remaining Slice 3B gates. Do not mark it Implemented until styles, staves,
AoE, gambits, capture, and other required action tuples use the shared scorer.

Start by reading the `B5-AI-MIN-SCORER`, `B5-AI-COMPOSITION`, and
`B2-PROJECTION` control-plane/GDD owners and the resolved AI valuation register.
Use the reconciled Slice 3A plan and write its requirement/evidence matrix before
production code.

Exit evidence:

- lethal/non-lethal, counter/no-counter, staff/wait fallback, and stable-tie tests;
- no live-state or RNG mutation during scoring;
- unchanged compatibility-preset byte/decision fixtures;
- focused AI/projection suites, RNG guard, and full suite.

### 2. `B3-CAMPAIGN-RULES`

If the scorer blocks on an owner decision, implement data-driven rule profiles
over the existing `CampaignRules`, save envelope, and registry foundation.

Preserve the shipped default profile exactly. Cover profile validation, override
precedence, mandated/read-only rules, between-map and mid-map round trips, old-save
defaults, campaign-package identity, and New Game selection. Do not fold difficulty
UI or death-mode content into this foundation; those remain
`B4-DIFFICULTY-DEATHMODE` consumers.

### 3. `B3-PHB`

Build the open prep-hub activity/panel registry after re-reading the resolved prep
hub decisions. The framework should validate activity descriptors, resolve panel
factories through a registry, and carry results only through existing
Action/Effect and campaign-state seams. Land one inert/example panel fixture;
convoy, shop, training, arena, and recruitment remain separate tracks.

### 4. Remaining dependency-valid queue

After those three, select one bounded unit at a time in the control-plane order:

1. `B4-ENCOUNTER-MODEL` split completion.
2. `B3-MOVEMENT-VULN-REGISTRY`.
3. `B3-RESOURCE-POOLS`.
4. `UI-INSPECTION` / `VAL-V021-12` headless-safe increments.
5. Suspend/save hardening and `VAL-FIXTURE-GAPS`.
6. `B3-STAT-REGISTRY` only with a complete migration plan.
7. TCV/REQ/text/dialogue dependency reconciliation and foundation work.
8. Compatible content/package authoring.

Do not skip a recorded dependency merely because its target has partial code.
Update stale row text when evidence proves a dependency is already satisfied.

## Shared delivery rules

For every selected track:

1. Re-read its control-plane row, exact GDD owner, decision/register source, and
   latest relevant session note.
2. Derive a requirement/evidence matrix before claiming a multi-part track.
3. Keep author-facing extension points as open registries or predicates.
4. If behavior changes, update the owning GDD and roadmap status in the same
   commit; if the save shape changes, update the F1 manifest and migration tests.
5. Add focused deterministic tests before or with production code.
6. Commit one logical green increment; then check for returned playtest evidence.
7. Run documentation checks, RNG guard, pinned style/lint, relevant focused suites,
   and the full suite before a track-level handoff.

## Safe fallback queue

If all three preferred tracks expose unresolved decisions, continue with work
that does not change player-facing semantics:

- malformed/legacy save and package fixtures;
- transactional write-failure injection;
- ledger/suspend byte and determinism comparisons;
- mutable-runtime serializer ownership audit;
- AI performance and stable-tie fixtures;
- ObjectDB test-fixture cleanup;
- UI inspection harness fidelity and theme-resolution checks;
- short-campaign/content planning against already implemented mechanics.

## Explicitly parked

Do not start release/merge/upload work, replace a playtest build, remove debug
aids, or begin remote play, public builder, hex topology, advanced AI search,
Laguz, the full Awakening supplement, or dependency-skipping convoy/shop/object
features during this waiting stream.

## Next-session starting point

1. Confirm the worktree is clean and neither live return has arrived.
2. Walk through the scorer pre-implementation decision document when the owner is
   available; record settled options and leave unresolved choices explicit.
3. Open the `B5-AI-MIN-SCORER` contract and resolved AI valuation decisions.
4. Inventory the existing Projection Service terms and `EnemyAI` planning seam.
5. Write or update the bounded scorer plan/evidence matrix.
6. Implement the smallest compatibility-preserving scorer slice with focused
   tests, then run the normal gates and commit it.
