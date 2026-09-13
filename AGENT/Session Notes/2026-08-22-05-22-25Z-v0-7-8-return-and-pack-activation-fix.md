# Session Notes — 2026-08-22-05-22-25Z-v0-7-8-return-and-pack-activation-fix (v0.7.8 return and pack activation fix)

## What was done

The v0.7.8 Windows round returned and was rejected: useful Narrator, keyboard,
reason-text, and resize evidence landed, but the supplied Proving Grounds pack
could not start because its self-contained registry omitted the newly-required
`campaign_vars` family. Sections 3, 5, and 6 were therefore blocked.

The failure reproduced against the exact shipped ZIP. The existing pack validator
still reported `adapter valid: true`, activation success, and 8/8 playable maps
because it never exercised the RegistryManager transaction used by New Game.
Tier-2 registry documents also could not represent typed campaign variables: the
schema vocabulary omitted the family and the runtime adapter always built the base
RegistryEntry type.

The release fix admits and validates typed campaign-variable registry documents,
adapts them to CampaignVarDef, and makes ExportedRegistryGate validate the installed
archive's complete registry candidate. The original v0.7.8 ZIP now fails that gate
with the exact returned error. A repaired public pack exports, installs, activates,
and remains 8/8 playable. The corresponding pack change is commit `c63cb6e` on
`Project_Prometheus_Campaign_Pack_0` branch
`agent/from-proving-grounds-public-pack/v079-campaign-vars-registry`.

## Factual Git state

- Branch: `agent/playtest-release-v0.7.9-fixes`
- HEAD: `2db24fa9e4ba2bc22e65622c22083d3b560b432d`
- Task merge base: `904e93873f90a7def0345c20a3945f42e5c0c1e8`

## Commits

- `2db24fa9` Reject campaign packs that cannot activate registries

## Checks

- `full`: `bash run_tests.sh` at `2db24fa9e4ba`

## Decisions and context

- v0.7.8 is rejected and remains untagged.
- A replacement native-host round is required for the blocked checklist sections.
- Pack release validation must test runtime registry activation, not merely archive
  installation and Tier-2 data adaptation.
- Narrator's returned behavior answers ANN-5: disabled controls expose their labels
  and disabled state, but not the unmet-reason sentence.

## Next session

Merge the pack content commit into its public-pack base, then use both changes to cut
the replacement candidate. Carry forward the controller items (not run), the blocked
overworld/terrain/smoke items, and the missing complete Godot log directory. Record
the narrow-window Campaign Library border collision and the absent Menu Density
label as returned observations rather than silently accepting them.
