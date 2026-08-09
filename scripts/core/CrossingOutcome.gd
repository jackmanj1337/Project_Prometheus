class_name CrossingOutcome extends RefCounted
# Result of resolving one continuous position change against the crossing
# resolver ([PCM-1]/[PCM-3]). Produced BEFORE any animation runs: `path` is the
# movement that actually happens, and the tween is a presentation of it.
#
# Position-change model decisions 2026-08-01, [PCM-3]: resolution is over the
# path as data, so an Instant-speed move, an AI move and an animated player move
# all consume the same outcome.

# The effective path, origin tile first. Equal to the requested path when nothing
# halted; truncated at (and including) the halting tile otherwise.
var path: Array[Vector2i] = []

# True when a trigger with `interrupt: halt` fired and cut the move short.
var halted: bool = false

# The tile the move stopped on. Only meaningful when `halted`.
var halt_tile: Vector2i = Vector2i.ZERO

# [PCM-6]: at least one fired trigger declared that its halt ends the unit's
# activation. Independent of `halted` in principle, but a trigger only ends the
# activation of a unit it fired on.
var ends_activation: bool = false

# Ids of the triggers that fired, in resolution order. Deterministic: consumers
# resolve in registration order, tiles in path order.
var fired: Array[String] = []

# [PCM-7] clause 1: the free pre-confirm undo is no longer available for this
# move. Set by ANY fired trigger, not only ones carrying an effect — a halt with
# no effect still reveals the trap that caused it, which is exactly the
# zero-cost scouting the clause exists to stop. Rewind (clause 2) is unaffected
# and is not represented here.
var movement_permanent: bool = false

# Malformed trigger declarations found while resolving. Non-empty means content
# is wrong, not that movement failed; the resolver still produces a usable
# outcome by falling back to the safe defaults ([PCM-5]: halt).
var errors: Array[String] = []


# The tile the unit ends on ([-1] of the effective path).
func destination() -> Vector2i:
	if path.is_empty():
		return Vector2i.ZERO
	return path[-1]


# Convenience for callers that only need "did anything happen mid-path".
func any_fired() -> bool:
	return not fired.is_empty()


# The pass-through outcome for a move nothing observed: the requested path,
# unchanged. Used when no consumer is registered and by callers running without
# the service (bare test trees).
static func pass_through(requested: Array[Vector2i]) -> CrossingOutcome:
	var outcome := CrossingOutcome.new()
	outcome.path = requested.duplicate()
	return outcome
