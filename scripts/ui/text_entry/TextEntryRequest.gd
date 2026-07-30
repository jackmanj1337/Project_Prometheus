class_name TextEntryRequest
extends RefCounted

enum Purpose { NAME, FILE_PATH }

var purpose: Purpose = Purpose.NAME
var initial_text := ""
var max_characters := 64
var max_utf8_bytes := 255
var allowed_characters := ""
var multiline := false
var private_value := false
var allow_empty := false


func accepts(character: String) -> bool:
	if character.length() != 1 or character.unicode_at(0) < 32:
		return false
	return allowed_characters.is_empty() or allowed_characters.contains(character)


func validate(candidate: String) -> String:
	if not multiline:
		candidate = candidate.replace("\r", "").replace("\n", "")
	var filtered := ""
	for character in candidate:
		if accepts(character):
			var next := filtered + character
			if next.length() > max_characters or next.to_utf8_buffer().size() > max_utf8_bytes:
				break
			filtered = next
	return filtered


func is_submittable(candidate: String) -> bool:
	return allow_empty or not validate(candidate).is_empty()
