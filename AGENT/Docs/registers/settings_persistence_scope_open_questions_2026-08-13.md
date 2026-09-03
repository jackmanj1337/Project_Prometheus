---
Role: dated
Type: register
Status: RESOLVED — SPS-1..5 ruled 2026-08-26
Last verified: 2026-08-26
Register: SPS-1..5
Resolved-in: this register — owner walk 2026-08-26
Tracker: SETTINGS-PERSISTENCE-SCOPE-REVIEW-2026-08-13
---

# Settings Persistence Scope — Owner Questions

This register decides who owns each setting, how a fresh scope is seeded, and whether an
authored default or a stored choice wins. It does not assume automatic cross-device transport:
manual settings export/import is the v1 portability mechanism.

## Rulings

### [SPS-1] Which persistence scopes exist? — **RESOLVED 2026-08-26**

There is **no player-profile persistence layer**. Settings use these scopes:

- **Device-local:** audio, menu presentation, accessibility, locale, display geometry, hardware
  availability, and shared touch-overlay geometry. They remain on that device unless explicitly
  carried by a manual export/import operation.
- **Campaign-local:** gameplay pacing and notifications. They persist across runs of that
  campaign and do not leak to sibling campaigns in the same pack. Notification categories keep
  `[SKF]`'s authored-default seed; after first run, the stored campaign choice wins.
- **Seat-local within a campaign:** each local seat owns its control scheme as well as
  `[CFB-15]`'s combat detail and speed. Control scheme includes the seat's selected input mode,
  text-entry mode, active binding set, and key/button overrides. This is not a player profile: the
  values belong to a campaign's local seat records and do not follow a person into another
  campaign. Device capabilities still gate which choices can actually activate, and shared
  touch-overlay geometry remains device-local because every seat uses the same screen.
- **Pack-local is not a default scope.** No current family is assigned to it merely because
  campaigns share a pack.
- **Memory-only:** sensitive transient text such as editor filters remains outside persistence,
  preserving `[CEUI-S48]`/`[NMTE-20]`'s never-to-disk boundary.

This supersedes `[CAU-4]`'s phrase "global player settings" as a storage scope. Its confirmation
floors and tag vocabulary remain unchanged; `[SPS-2]` below replaces its optional campaign/run
override with an explicitly campaign-local, per-seat choice.

## Remaining owner questions

### [SPS-2] Where do confirmation presets live? — **RESOLVED 2026-08-26**

- **A — Campaign-local.** Consistent with gameplay pacing and lets different campaigns retain
  different risk tolerances. A fresh campaign seeds the engine default; stored campaign choice
  then wins. Against: the same player must repeat a safety preference in every campaign.
- **B — Device-local, with CAU-4's campaign/run override retained.** Preserves the spirit of the
  prior global preference without recreating a player profile. Against: confirmation behaviour can
  differ between devices.
- **C — Device-local only.** Simplest model, but removes the already-ratified campaign/run override.
- **Recommendation: B.** Confirmation tolerance is closer to an accessibility/input preference
  than authored campaign pacing, while the existing override still lets a campaign strengthen its
  own safety posture. An authored mandatory confirmation remains a floor no setting can lower.

**Owner ruling:** confirmation presets are **seat-local within the campaign**. Different local
players may choose different confirmation assistance, just as they may choose different controls
and combat pacing. A fresh seat seeds from the engine default; its stored choice wins thereafter
for that campaign. An authored mandatory confirmation remains a floor no seat may lower. This
rejects all three provisional options above and supersedes `[CAU-4]`'s global-player storage scope;
the existing open tag vocabulary is unchanged.

### [SPS-3] What does manual settings export carry? — **RESOLVED 2026-08-26**

The absence of a player profile makes this boundary explicit: decide whether export carries all
device-local preferences, a portable subset excluding hardware-shaped display/control values, or
only user-selected accessibility and language values. Campaign-local values belong with campaign
save data and are not duplicated into the settings export.

**Owner ruling:** a manual settings export carries only the portable device preferences: audio,
menu presentation, accessibility, and locale. It excludes resolution and display geometry,
hardware availability, shared touch-overlay geometry, and every campaign/seat-local value.

Campaign settings travel through campaign artifacts instead:

- The **pack** carries authored defaults only, including notification-category defaults. Player
  choices are never written into or exported as part of an installed/source pack.
- The **run/save** carries the campaign-local and per-seat values active for that run, so importing
  or restoring it reproduces its behavior and controls.
- A local **campaign preference record**, keyed by durable campaign identity, retains the latest
  campaign/seat choices across runs of the same campaign. Starting a new run seeds from that record
  when present; otherwise it seeds from the pack's authored defaults plus engine defaults.

Precedence is therefore: an authored mandatory floor cannot be weakened; otherwise a stored
run/seat value wins for an existing run, then the campaign preference record for a new run, then
the pack-authored default, then the engine default. A sibling campaign never inherits the record.

### [SPS-4] Where do campaign-editor settings live? — **RESOLVED 2026-08-26**

Editor scale, font size, density, reduced motion, and Advanced Mode are device-local. The editor's
author name/profile is also device-local, but it is personal data and is excluded from ordinary
settings export. Exporting a pack may copy the author value into authored manifest metadata only
through `[CEUI-S10]`'s explicit, overridable export surface; it is never a trust signal. Filter text
and filter recents are memory-only and never reach any file, preserving
`[CEUI-S48]`/`[NMTE-20]`.

### [SPS-5] What is the concrete ownership matrix? — **RESOLVED 2026-08-26**

The following matrix applies the preceding rulings to shipped and already-ruled settings. A future
setting must name one of these scopes when it is introduced rather than silently joining
`settings.cfg`.

| Family / current field | Scope | Seed and transfer |
|---|---|---|
| Master, music, SFX volume | Device-local, portable | Engine default; included in settings export |
| Menu scale and information density | Device-local, portable | Engine/device-derived default; included in settings export |
| Locale | Device-local, portable | Device/engine locale fallback; included in settings export |
| Reduced motion and general accessibility values, including dwell multiplier | Device-local, portable | Engine default; included in settings export. This supersedes `[CFB-15]`'s per-local-player storage wording for dwell speed, not its bounded-dwell behavior |
| Window mode, resolution, viewport/content scale | Device-local, hardware-shaped | Engine/device-derived default; excluded from settings export |
| Camera edge buffer, map zoom, terrain grid dim, HUD layout | Device-local, hardware/layout-shaped | Engine/authored default; excluded from settings export |
| Shared touch-overlay geometry | Device-local, hardware/layout-shaped | Device/orientation default; excluded from settings export |
| Combat animations, movement speed, phase banner, level-up presentation, auto-end-turn | Campaign-local | Campaign record, then pack default if authored, then engine default; bundled into run/save |
| Notification categories | Campaign-local | Campaign record, then pack-authored default, then engine default; bundled into run/save |
| Seat combat-detail and combat-feedback speed | Campaign-local seat | Run/seat value, then campaign seat record, then engine default; bundled into run/save |
| Input mode, text-entry mode, touch-control scheme, mouse cursor mode | Campaign-local seat | Run/seat value, then campaign seat record, then device-capability-aware engine default; bundled into run/save |
| Active binding set and key/button overrides | Campaign-local seat | Run/seat value, then campaign seat record, then authored InputMap; bundled into run/save |
| Confirmation preset and per-tag choices | Campaign-local seat | Run/seat value, then campaign seat record, then engine default; authored mandatory floor always wins |
| Editor scale, font size, density, reduced motion, Advanced Mode | Device-local, editor-only | Engine/device default; excluded from ordinary settings export |
| Editor author name/profile | Device-local personal data | Empty/default local value; excluded from ordinary settings export; copied to a manifest only by explicit export UI |
| Editor filter text and recents | Memory-only | Empty on editor restart; never serialized |

There is no current pack-local player setting and no player-profile layer. Pack data participates
only by supplying authored defaults and mandatory floors.

**Register closed.** Ownership, fresh-scope seeding, override precedence, save/pack bundling, and
manual settings transfer are ruled for every shipped setting and every planned setting handed into
this review by `SKF`, `CFB`, `CAU`, `L10N`, `CEUI`, and `NMTE`.
