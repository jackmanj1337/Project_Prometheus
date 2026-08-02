class_name TextEntryRequest
extends RefCounted

enum Purpose { NAME, FILE_PATH }
enum DismissalPolicy { KEEP_EDITED, RESTORE_INITIAL }

var purpose: Purpose = Purpose.NAME
var initial_text := ""
var max_characters := 64
var max_utf8_bytes := 255
var allowed_characters := ""
var multiline := false
var private_value := false
var allow_empty := false
var target: LineEdit
var host_viewport: Viewport
var dismissal_policy: DismissalPolicy = DismissalPolicy.KEEP_EDITED


# One place that knows what each purpose accepts, so callers do not each carry a
# literal charset. Three FileDialog screens share this; without it the same
# printable-ASCII loop gets copied into every one of them.
static func for_purpose(next_purpose: Purpose) -> TextEntryRequest:
	var request := TextEntryRequest.new()
	request.purpose = next_purpose
	request.allowed_characters = printable_ascii()
	match next_purpose:
		Purpose.FILE_PATH:
			request.max_characters = 255
			request.max_utf8_bytes = 255
		_:
			request.max_characters = 64
			request.max_utf8_bytes = 255
	return request


static func printable_ascii() -> String:
	var result := ""
	for code in range(32, 127):
		result += char(code)
	return result


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
