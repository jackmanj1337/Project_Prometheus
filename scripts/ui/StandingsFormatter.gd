class_name StandingsFormatter extends RefCounted
# Shared result copy for victory and defeat surfaces. Keeping this pure makes it
# reusable by later PvP result screens without coupling them to either overlay.


static func format(winner_group: String, standings: Array) -> String:
	if standings.is_empty():
		return ""
	var lines: Array[String] = []
	if winner_group == "":
		lines.append("Draw — all groups eliminated")
	for entry in standings:
		var rank: int = entry.get("rank", 0)
		var group: String = entry.get("group", "")
		var eliminated_round: int = entry.get("eliminated_round", -1)
		var label: String = "%d. %s" % [rank, group.capitalize()]
		if eliminated_round >= 0:
			label += " — eliminated turn %d" % eliminated_round
		if bool(entry.get("is_blue_group", false)):
			label += " (you)"
		lines.append(label)
	return "\n".join(lines)
