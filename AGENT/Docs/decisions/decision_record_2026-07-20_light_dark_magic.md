---
Type: decision
Status: Applied
Last verified: 2026-07-20
Decision IDs: RULE-009, OPEN-10
---

# Decision Record — Light/Dark Magic Design Pass (2026-07-20)

## Context

`OPEN-10` ("Cleric Light E") had sat **Open / Not scheduled** since June, blocked
on the `RULE-009` Light/Dark design pass, which was itself **Planned** with no
date. The decision index describes OPEN-10 as a narrow question about one class's
weapon access.

A data check on 2026-07-20 found the question is not narrow.

## The finding

**The `light` and `dark` weapon tracks are declared by classes, but no tomes
exist.** `data/weapons/` contains twelve resources: fire, thunder, wind (all on
the `elemental_magic` track), a heal staff, and physical arms. There is no light
tome and no dark tome anywhere in the project.

| Class | Declared tracks | Tomes that exist |
|---|---|---|
| Cleric | `staff` 100 / `light` 0, cap 400 | none for `light` |
| **Bishop** | **`light` 100** / `staff` 0 | **none** |
| **Dark Knight** | `sword` 100 / **`dark`** 0 | **none** |

Two consequences the index does not record:

1. **Bishop is a reachable promotion whose primary offensive track has no
   weapons.** `cleric.promotes_to` includes `bishop`, so a player can promote into
   a class that cannot attack with the track it is built around. Dark Knight has
   the same hole on `dark`.
2. **The magic triangle is not wired.** Every weapon carries
   `triangle_family = ""`, so the relationship `RULE-013` defines and `SET-003`
   commits to does not exist in data for magic.

`DataManager`'s validation cross-checks *ids* — class refs, promotes, reclass, map
registry — but does not check that a declared `wexp_track` has any weapon on it.
That is why this passed boot validation and the full suite while being broken in
play.

So OPEN-10 was never really "does Cleric get Light E". It was "does Light/Dark
exist at all".

## Decisions

| ID | Decision | Applied in |
|---|---|---|
| RULE-009 | **Author Light and Dark tome families.** Create the missing tomes so Bishop and Dark Knight become playable in the roles the promotion graph already offers. Rejected: collapsing both into `elemental_magic` (would make Bishop a reskinned Sage and flatten magic to one track), and deferring again (leaves a reachable promotion that soft-locks a unit's offence). | `LD-TOMES-2026-07-20` |
| RULE-009 (triangle) | **Wire the three-way magic triangle** across Light, Dark, and the existing `elemental_magic` track, via `triangle_family`. Closes a relationship `SET-003` already ratified and `RULE-013` already defines the magnitude rule for. | `LD-MAGIC-TRIANGLE-2026-07-20` |
| OPEN-10 | **Cleric is staff-only; Light arrives on promotion to Bishop.** Remove `light` from Cleric's base class rather than leaving a trainable track with nothing to train on. Keeps Cleric a clean support identity and makes promotion a real unlock. This also honours GDD_03's standing instruction not to author a one-off tome for the base class. | This record; `LD-TOMES-2026-07-20` |

## Consequences

### Do not name the third track "Anima"

The classic name for the fire/thunder/wind family is **FE-coined vocabulary**, and
`REN-1` (decided the same day, `decision_record_2026-07-20_ren_public_identity.md`)
commits to replacing exactly that class of term. The project already uses
**`elemental_magic`**, which is an owned, descriptive name. Keep it. "Light" and
"Dark" are generic and carry no such problem.

This is worth stating because the triangle is conventionally described with the
FE term, and it would be easy to introduce it while implementing.

### The triangle's direction is still to be designed

This record commits to *having* a magic triangle, not to a particular cycle. Which
family beats which is a balance decision for the implementing slice, and it should
be chosen on this project's own terms rather than inherited — the promotion graph,
class roles, and tome availability here are not the same as any other game's.

### Validation gap worth closing

Nothing currently catches "a class declares a `wexp_track` with no weapons on it".
That gap is what let Bishop ship unusable. A check belongs with this work;
otherwise the same class of defect recurs the next time a track is declared ahead
of its weapons. Tracked as `LD-TRACK-COVERAGE-CHECK-2026-07-20`.

### Ordering

`RULE-009` was specified as preceding bulk corpus class migration (`AWR-2`,
`SET-009`, `RULE-007`). That ordering is unchanged: the tome families and the
triangle should exist before classes are authored en masse against them.

## Follow-ups

| Task | What |
|---|---|
| `LD-TOMES-2026-07-20` | Author the Light and Dark tome families; remove `light` from Cleric's base class. Makes Bishop and Dark Knight playable. |
| `LD-MAGIC-TRIANGLE-2026-07-20` | Set `triangle_family` across the three magic families and choose the cycle direction. |
| `LD-TRACK-COVERAGE-CHECK-2026-07-20` | Validation that every declared `wexp_track` has at least one weapon. |
