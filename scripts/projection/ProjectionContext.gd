class_name ProjectionContext extends RefCounted
## Inputs shared by every side-effect-free forecast adapter.

var kind: String = ""
var audience: String = "player"
var actor: Node = null
var subject: Variant = null
var targets: Array = []
var source: Variant = null
var action_spec: Variant = null
var state_view: Dictionary = {}
var knowledge_policy: String = "exact"
var rng_mode: String = "odds_only"
var pipeline_flags: Dictionary = {}
var reason: String = ""
var parent_id: String = ""
var budget: int = 1


static func combat(attacker: Node, defender: Node,
		audience_id: String = "player") -> RefCounted:
	var ctx: RefCounted = load("res://scripts/projection/ProjectionContext.gd").new()
	ctx.kind = "combat"
	ctx.audience = audience_id
	ctx.actor = attacker
	ctx.subject = attacker
	ctx.targets = [defender]
	ctx.source = attacker.get_equipped_weapon() if attacker != null \
		and attacker.has_method("get_equipped_weapon") else null
	ctx.reason = "combat_forecast"
	return ctx
