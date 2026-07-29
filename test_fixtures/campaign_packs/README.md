# Campaign-pack test fixtures

`two-map-skirmish-1.0.zip` is a player-facing import fixture for the v0.5.0
playtest build. Import it from **New Game > Manage Campaigns > Import**.

Expected content:

- campaign **Two-Map Skirmish**, package version 1.0;
- two linked chapters: **The Crossroads** and **River Pass**;
- two blue roster units, Alden and Mira;
- three basic red raiders on each map.
- accepts a completed **The Proving Grounds** 1.0.0 status record;
- carries that record's ending party gold into the new run;
- grants Mira the pack-defined **Proving Grounds Medal**.
- demonstrates `full_history` rewind pricing: any retained activation costs one charge.

Known v0.5.0 limitation: the Tier-2 runtime adapter does not deserialize authored
objective conditions. The maps and units load, but defeating all red units may
not resolve the chapter or advance from the first map to the second in the
exported v0.5.0 executable.
