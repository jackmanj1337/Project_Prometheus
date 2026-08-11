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
	bridge.queue_free()
	label.queue_free()
	quit(0)
