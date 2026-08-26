---
Role: dated
Type: register
Status: OPEN — SPS-1 ruled 2026-08-26; remaining settings awaiting owner walk
Last verified: 2026-08-26
Register: SPS-1..
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

### [SPS-3] What does manual settings export carry? — **OPEN**

The absence of a player profile makes this boundary explicit: decide whether export carries all
device-local preferences, a portable subset excluding hardware-shaped display/control values, or
only user-selected accessibility and language values. Campaign-local values belong with campaign
save data and are not duplicated into the settings export.
