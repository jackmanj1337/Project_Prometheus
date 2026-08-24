extends SceneTree

const BridgeScript = preload("res://scripts/autoloads/WebTestBridge.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var bridge := BridgeScript.new()
	root.add_child(bridge)
	var label := Label.new()
	label.text = "A deliberately long bridge label"
	label.size = Vector2(20, 10)
	root.add_child(label)
	await process_frame

	var snapshot: Dictionary = bridge._control_snapshot(label)
	var truncation: Dictionary = snapshot.get("truncation", {})
	if snapshot.get("text", "") != label.text:
		print("FAIL bridge control snapshot omitted label text")
		quit(1)
		return
	if (
		not truncation.has("fits")
		or not truncation.has("measuredTextWidth")
		or not truncation.has("overrunBehavior")
		or not truncation.has("availableWidth")
	):
		print("FAIL bridge control snapshot omitted truncation evidence")
		quit(1)
		return
	print("OK  bridge publishes text and measured truncation evidence")
	var inherited_theme := Theme.new()
	inherited_theme.take_over_path("res://tests/inherited_theme.tres")
	var theme_owner := Control.new()
	theme_owner.theme = inherited_theme
	root.remove_child(label)
	theme_owner.add_child(label)
	root.add_child(theme_owner)
	var provenance: Dictionary = bridge._theme_provenance(label)
	if (
		provenance.get("source") != "control"
		or provenance.get("resource") != inherited_theme.resource_path
	):
		print("FAIL bridge omitted inherited theme provenance: %s" % [provenance])
		quit(1)
		return
	print("OK  bridge publishes the inherited theme resource and owner")
	var import_button := Button.new()
	import_button.name = "BtnImport"
	if bridge._semantic_control_id(import_button) != "campaign.import":
		print("FAIL bridge omitted stable campaign import id")
		quit(1)
		return
	var value := LineEdit.new()
	value.name = "Value"
	if bridge._semantic_control_id(value) != "text-entry.value":
		print("FAIL bridge omitted stable text-entry value id")
		quit(1)
		return
	var codes := bridge._diagnostic_codes_from_text(
		"Import failed: vocabulary_value_unknown at classes[0]."
	)
	if codes != ["vocabulary_value_unknown"]:
		print("FAIL bridge did not retain stable import diagnostic code: %s" % [codes])
		quit(1)
		return
	print("OK  bridge publishes stable semantic ids and import diagnostic codes")
	bridge.queue_free()
	theme_owner.queue_free()
	import_button.queue_free()
	value.queue_free()
	quit(0)
