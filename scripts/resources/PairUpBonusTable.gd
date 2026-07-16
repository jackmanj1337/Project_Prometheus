extends Resource
# Data-driven Pair Up bonus table.
#
# A support unit contributes two layers of bonus to its paired lead (Q5):
#   1. A flat StatBlock authored per support class (`class_bonuses`).
#   2. A scaling term derived from the support unit's live stats
#      (`floor(support_stat / scaling_divisor)`).
#
# Both layers are summed by PairUpBonusResolver. Stats not listed in
# `scaling_stats` contribute zero scaling; stats with no entry in
# `class_bonuses` for the support's class contribute zero flat bonus.
#
# class_name is intentionally omitted so this script does not need a global
# class-cache entry (the .tres loads by ExtResource path; production code
# preloads by path).

# class_id -> { stat_name: int } flat bonus block per support class. Missing
# classes return zeros from the resolver. Missing stats default to zero.
@export var class_bonuses: Dictionary = {}

# Divisor applied to each scaling stat. `floor(support_stat / scaling_divisor)`
# is added on top of the flat block. Must be >= 1 — values <= 0 disable scaling.
@export var scaling_divisor: int = 4

# Stats whose live values contribute the scaling term. Limited to combat-
# relevant stats by default so HP / movement do not bleed into Pair Up math.
@export var scaling_stats: PackedStringArray = PackedStringArray(
	[
		"strength",
		"magic",
		"defense",
		"resistance",
		"skill",
		"speed",
		"luck",
	]
)


# Returns the flat bonus dict for a class, or an empty dict if unknown.
# Caller must not mutate the result; treat it as read-only.
func get_class_bonus(class_id: String) -> Dictionary:
	return class_bonuses.get(class_id, {})
