> **Historical** measurement evidence captured on 2026-07-15; rerun the helper
> before changing import budgets.

# Campaign Save Import-Budget Measurement — 2026-07-15

Command: `godot --headless --path . -s scripts/tests/test_save_import_budgets.gd`

Environment: Godot 4.6.3, Linux container, headless debug run.

| Representative save | Compact JSON bytes | Parse time (µs) | Observed static-memory delta (bytes) |
| --- | ---: | ---: | ---: |
| Between-map (24-unit roster, 120 convoy entries) | 40,374 | 1,254 | 647,694 |
| Normal mid-map (30 units, six retained board entries) | 584,453 | 19,032 | 9,437,667 |
| Large roster/convoy (300 units, 3,000 convoy entries) | 653,118 | 12,433 | 10,569,558 |
| Largest shipped rewind retention (60 units, one retry boundary) | 333,288 | 5,576 | 5,377,444 |

The stable gate is serialized byte size: every fixture must remain below half the
configured warning threshold. Parse time and process-memory delta are recorded but
are deliberately non-blocking because allocator state and host load make them noisy.
The largest measured fixture is 653,118 bytes, leaving 16,124,098 bytes of headroom
below the configured desktop warning and 66,455,746 bytes below the hard maximum.

Shipped campaign data uses the default `undo_activations = 0` and `undo_rounds = 0`,
so its retained ledger is the single Retry boundary. The six-entry normal-mid-map
fixture is an additional forward-pressure sample; it is not a claim that this
larger retention policy ships today.
