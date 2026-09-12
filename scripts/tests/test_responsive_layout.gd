extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_responsive_layout.gd
#
# Covers the size-class seam ([GDD-07-UI-UX], "Size class"): the boundary
# rule, the hysteresis that stops a window parked on a boundary oscillating, and the
# state-preservation contract — that no signal is published for a resize that does not
# change the class, which is what stops a screen rebuilding and losing the player's
# selection, scroll position or open More Info target.
#
# The live behaviour is driven through apply_logical_size() rather than a real window on
# purpose. Headless pins the logical viewport at the project base 1280x720
# (SettingsManager._apply_content_scale falls back to CONTENT_SCALE_ASPECT_KEEP because a
# 64x64 headless window would make all layout maths meaningless), so a headless test
# CANNOT vary the viewport. Driving the seam directly is the only way these rules get
# covered at all.

const ResponsiveLayoutS = preload("res://scripts/autoloads/ResponsiveLayout.gd")


# Records every publish so a test can assert both the values and the COUNT. The count is
# the part that matters: a spurious republish is invisible in the final class.
class ClassRecorder:
	extends RefCounted
	var events: Array = []

	func on_size_class_changed(new_class: String, previous_class: String) -> void:
		events.append([previous_class, new_class])

	func classes() -> Array:
		var out: Array = []
		for e in events:
			out.append(e[1])
		return out


func _init() -> void:
	print("=== ResponsiveLayout Test ===")
	var passed := 0
	var failed := 0

	# ---- class_for_width: the raw boundaries, inclusive-lower / exclusive-upper ----
	var boundary_cases := [
		[0.0, ResponsiveLayoutS.CLASS_COMPACT],
		[359.0, ResponsiveLayoutS.CLASS_COMPACT],
		[360.0, ResponsiveLayoutS.CLASS_COMPACT],  # the ratified design floor
		[599.0, ResponsiveLayoutS.CLASS_COMPACT],
		[599.999, ResponsiveLayoutS.CLASS_COMPACT],
		[600.0, ResponsiveLayoutS.CLASS_MEDIUM],  # boundary belongs to the UPPER class
		[800.0, ResponsiveLayoutS.CLASS_MEDIUM],
		[1023.0, ResponsiveLayoutS.CLASS_MEDIUM],
		[1024.0, ResponsiveLayoutS.CLASS_EXPANDED],
		[1280.0, ResponsiveLayoutS.CLASS_EXPANDED],
		[2048.0, ResponsiveLayoutS.CLASS_EXPANDED],
	]
	for boundary_case in boundary_cases:
		var width: float = boundary_case[0]
		var want: String = boundary_case[1]
		var got := ResponsiveLayoutS.class_for_width(width)
		if got == want:
			print("OK  class_for_width(%s) = %s" % [width, want])
			passed += 1
		else:
			print("FAIL class_for_width(%s) = %s, want %s" % [width, got, want])
			failed += 1

	# ---- The scenarios from the design doc's own table ----
	# Every row is `backing / content_scale_factor` -> logical width -> class. If the
	# breakpoints are ever retuned, these are the cases the owner actually signed off.
	var scenarios := [
		["phone portrait", 1179.0, 3.0, ResponsiveLayoutS.CLASS_COMPACT],
		["phone landscape", 2556.0, 3.0, ResponsiveLayoutS.CLASS_MEDIUM],
		["small Linux handheld", 1280.0, 2.0, ResponsiveLayoutS.CLASS_MEDIUM],
		["phone cast to a TV", 1920.0, 1.5, ResponsiveLayoutS.CLASS_EXPANDED],
		["desktop", 2560.0, 2.0, ResponsiveLayoutS.CLASS_EXPANDED],
		["desktop, more on screen", 2560.0, 1.25, ResponsiveLayoutS.CLASS_EXPANDED],
	]
	for scenario in scenarios:
		var label: String = scenario[0]
		var backing: float = scenario[1]
		var factor: float = scenario[2]
		var want_class: String = scenario[3]
		var logical_width := backing / factor
		var got_class := ResponsiveLayoutS.class_for_width(logical_width)
		if got_class == want_class:
			print(
				(
					"OK  %s: %s / %s = %s logical -> %s"
					% [label, backing, factor, logical_width, want_class]
				)
			)
			passed += 1
		else:
			print(
				"FAIL %s: %s logical -> %s, want %s" % [label, logical_width, got_class, want_class]
			)
			failed += 1

	# ---- resolve_class: hysteresis holds the current class inside the margin ----
	var h := ResponsiveLayoutS.CLASS_HYSTERESIS
	var hysteresis_cases := [
		# [width, current class, expected, why]
		[
			600.0,
			ResponsiveLayoutS.CLASS_COMPACT,
			ResponsiveLayoutS.CLASS_COMPACT,
			"parked exactly on the boundary from below: hold"
		],
		[
			600.0 + h - 1.0,
			ResponsiveLayoutS.CLASS_COMPACT,
			ResponsiveLayoutS.CLASS_COMPACT,
			"inside the margin: hold"
		],
		[
			600.0 + h,
			ResponsiveLayoutS.CLASS_COMPACT,
			ResponsiveLayoutS.CLASS_MEDIUM,
			"clears the margin: promote"
		],
		[
			599.0,
			ResponsiveLayoutS.CLASS_MEDIUM,
			ResponsiveLayoutS.CLASS_MEDIUM,
			"just below the boundary from above: hold"
		],
		[
			600.0 - h,
			ResponsiveLayoutS.CLASS_MEDIUM,
			ResponsiveLayoutS.CLASS_MEDIUM,
			"exactly on the lower margin edge: hold (band is inclusive-lower)"
		],
		[
			600.0 - h - 1.0,
			ResponsiveLayoutS.CLASS_MEDIUM,
			ResponsiveLayoutS.CLASS_COMPACT,
			"clears the lower margin: demote"
		],
		[
			1024.0,
			ResponsiveLayoutS.CLASS_MEDIUM,
			ResponsiveLayoutS.CLASS_MEDIUM,
			"parked on the upper boundary: hold"
		],
		[
			1024.0 + h,
			ResponsiveLayoutS.CLASS_MEDIUM,
			ResponsiveLayoutS.CLASS_EXPANDED,
			"clears the upper margin: promote"
		],
		[
			1023.0,
			ResponsiveLayoutS.CLASS_EXPANDED,
			ResponsiveLayoutS.CLASS_EXPANDED,
			"just below from above: hold"
		],
		[
			1024.0 - h - 1.0,
			ResponsiveLayoutS.CLASS_EXPANDED,
			ResponsiveLayoutS.CLASS_MEDIUM,
			"clears the margin: demote"
		],
		# A maximise skips a class. The widened-band rule must not stop one class short.
		[
			1600.0,
			ResponsiveLayoutS.CLASS_COMPACT,
			ResponsiveLayoutS.CLASS_EXPANDED,
			"400 -> 1600 maximise lands on Expanded, not Medium"
		],
		[
			300.0,
			ResponsiveLayoutS.CLASS_EXPANDED,
			ResponsiveLayoutS.CLASS_COMPACT,
			"restore-down to a phone width lands on Compact"
		],
		# An unknown seed must not wedge the class.
		[800.0, "", ResponsiveLayoutS.CLASS_MEDIUM, "unknown current class falls back to raw"],
	]
	for hysteresis_case in hysteresis_cases:
		var w: float = hysteresis_case[0]
		var current: String = hysteresis_case[1]
		var expected: String = hysteresis_case[2]
		var why: String = hysteresis_case[3]
		var resolved := ResponsiveLayoutS.resolve_class(w, current)
		if resolved == expected:
			print("OK  resolve_class(%s, '%s') = %s — %s" % [w, current, expected, why])
			passed += 1
		else:
			print(
				(
					"FAIL resolve_class(%s, '%s') = %s, want %s — %s"
					% [w, current, resolved, expected, why]
				)
			)
			failed += 1

	# A window jittering by a pixel across the boundary must never change class. This is
	# the defect hysteresis exists to prevent, so it gets its own end-to-end assertion
	# rather than resting on the single-step cases above.
	var jitter_class := ResponsiveLayoutS.CLASS_COMPACT
	for i in 40:
		var jitter_width := 600.0 + (1.0 if i % 2 == 0 else -1.0)
		jitter_class = ResponsiveLayoutS.resolve_class(jitter_width, jitter_class)
	if jitter_class == ResponsiveLayoutS.CLASS_COMPACT:
		print("OK  40 one-pixel jitters across the 600 boundary never change class")
		passed += 1
	else:
		print("FAIL boundary jitter escaped hysteresis: ended at %s" % jitter_class)
		failed += 1

	# ---- Live publishing: the signal fires once per real change, never otherwise ----
	var layout: Node = ResponsiveLayoutS.new()
	# .new() without add_child so _ready() does not run: the node would otherwise reach
	# for /root/SettingsManager and the real viewport, which headless pins at 1280x720.
	var recorder := ClassRecorder.new()
	layout.size_class_changed.connect(recorder.on_size_class_changed)

	layout.size_class = ResponsiveLayoutS.CLASS_EXPANDED
	layout.apply_logical_size(Vector2(1280.0, 720.0))
	if recorder.events.is_empty():
		print("OK  a resize that does not change the class publishes nothing")
		passed += 1
	else:
		print("FAIL same-class resize published %d event(s)" % recorder.events.size())
		failed += 1

	# Several same-class resizes in a row — a horizontal drag inside Expanded.
	for width in [1300.0, 1400.0, 1500.0, 2000.0]:
		layout.apply_logical_size(Vector2(width, 720.0))
	if recorder.events.is_empty():
		print("OK  four same-class resizes still publish nothing")
		passed += 1
	else:
		print("FAIL same-class drag published %d event(s)" % recorder.events.size())
		failed += 1

	if layout.logical_size == Vector2(2000.0, 720.0):
		print("OK  logical_size tracks every resize even when the class does not change")
		passed += 1
	else:
		print("FAIL logical_size = %s, want (2000, 720)" % layout.logical_size)
		failed += 1

	layout.apply_logical_size(Vector2(500.0, 900.0))
	if recorder.classes() == [ResponsiveLayoutS.CLASS_COMPACT]:
		print("OK  crossing two boundaries publishes exactly one change, to Compact")
		passed += 1
	else:
		print("FAIL expected one publish to compact, got %s" % [recorder.classes()])
		failed += 1
	if recorder.events.size() == 1 and recorder.events[0][0] == ResponsiveLayoutS.CLASS_EXPANDED:
		print("OK  the publish carries the previous class, so a consumer can diff")
		passed += 1
	else:
		print("FAIL previous class not reported: %s" % [recorder.events])
		failed += 1

	# A drag back and forth across a boundary INSIDE the margin: still nothing.
	recorder.events.clear()
	for width in [599.0, 601.0, 599.0, 610.0, 595.0]:
		layout.apply_logical_size(Vector2(width, 900.0))
	if recorder.events.is_empty():
		print("OK  a drag oscillating around the boundary publishes nothing")
		passed += 1
	else:
		print("FAIL boundary oscillation published %d event(s)" % recorder.events.size())
		failed += 1

	# ---- State preservation: a consumer's state survives a class change ----
	# The seam cannot preserve a screen's state for it, but it CAN guarantee the two
	# things that make preservation possible: the class is already updated when the
	# signal arrives, and it is published exactly once. A consumer that saves and
	# restores around one signal therefore sees a consistent world.
	var preserved := {"selection": 3, "scroll": 120.0, "more_info": "stat:spd", "rebuilds": 0}
	var stateful := StatefulConsumer.new(preserved)
	layout.size_class_changed.connect(stateful.on_size_class_changed)
	layout.size_class = ResponsiveLayoutS.CLASS_COMPACT
	stateful.layout = layout
	layout.apply_logical_size(Vector2(1280.0, 720.0))
	if (
		preserved["selection"] == 3
		and is_equal_approx(preserved["scroll"], 120.0)
		and preserved["more_info"] == "stat:spd"
	):
		print("OK  selection, scroll and the open More Info target survive a class change")
		passed += 1
	else:
		print("FAIL state lost across a class change: %s" % [preserved])
		failed += 1
	if preserved["rebuilds"] == 1:
		print("OK  the consumer rebuilt exactly once for one class change")
		passed += 1
	else:
		print("FAIL consumer rebuilt %d time(s), want 1" % preserved["rebuilds"])
		failed += 1
	if stateful.class_at_signal == ResponsiveLayoutS.CLASS_EXPANDED:
		print("OK  size_class is already the NEW class when the signal arrives")
		passed += 1
	else:
		print("FAIL size_class was '%s' inside the handler" % stateful.class_at_signal)
		failed += 1

	# ---- Density tokens ----
	var touch := ResponsiveLayoutS.tokens_for_mode(ResponsiveLayoutS.MENU_MODE_TOUCH)
	var pad := ResponsiveLayoutS.tokens_for_mode(ResponsiveLayoutS.MENU_MODE_CONTROLLER)
	# Every column, not just the two originals: a column that defines seven of the eight
	# shared tokens is a layout that silently falls back at the eighth. Driven off the
	# published SHARED_TOKENS so adding a column cannot half-land and cannot be covered by
	# a list in this file that nobody updates.
	var all_complete := true
	for mode in ResponsiveLayoutS.MENU_MODES:
		var column: Dictionary = ResponsiveLayoutS.tokens_for_mode(mode)
		for name in ResponsiveLayoutS.SHARED_TOKENS:
			if not column.has(name):
				all_complete = false
				print("FAIL token '%s' missing from the '%s' column" % [name, mode])
	if all_complete:
		print("OK  all four columns define every shared density token")
		passed += 1
	else:
		failed += 1

	# tokens_for_mode() must not quietly hand back touch for a name it does not know: a
	# mode that falls back looks exactly like a mode that works.
	var distinct_columns := true
	for mode in ResponsiveLayoutS.MENU_MODES:
		if mode != ResponsiveLayoutS.MENU_MODE_TOUCH:
			if ResponsiveLayoutS.tokens_for_mode(mode) == touch:
				distinct_columns = false
				print("FAIL the '%s' column is identical to touch — it is not wired" % mode)
	if distinct_columns:
		print("OK  every column is a real column, not a fallback to touch")
		passed += 1
	else:
		failed += 1

	# The whole point of two token sets: the controller column is DENSER. If a future edit
	# makes them equal, Menu Mode has quietly become a no-op.
	var denser := true
	for name in ["row_height", "row_gap", "detail_row", "gutter", "header", "footer"]:
		if float(pad[name]) >= float(touch[name]):
			denser = false
			print("FAIL controller token '%s' is not denser than touch" % name)
	if denser:
		print("OK  every controller token is denser than its touch counterpart")
		passed += 1
	else:
		failed += 1

	if is_equal_approx(float(touch["min_target"]), 44.0):
		print("OK  touch keeps the 44px minimum target (Apple HIG)")
		passed += 1
	else:
		print("FAIL touch min_target = %s, want 44" % touch["min_target"])
		failed += 1
	if is_equal_approx(float(pad["min_target"]), 0.0):
		print("OK  controller has no minimum target — the row marker is the focus ring")
		passed += 1
	else:
		print("FAIL controller min_target = %s, want 0" % pad["min_target"])
		failed += 1

	# ---- The dense column ([UUI-11]) ----
	var dense := ResponsiveLayoutS.tokens_for_mode(ResponsiveLayoutS.MENU_MODE_DENSE)
	var dense_want := {
		"row_height": 44.0,
		"row_gap": 4.0,
		"body_font": 16.0,
		"detail_row": 44.0,
		"min_target": 44.0,
		"gutter": 8.0,
		"header": 72.0,
		"footer": 64.0,
	}
	var dense_ok := true
	for name in dense_want:
		if not is_equal_approx(float(dense[name]), float(dense_want[name])):
			dense_ok = false
			print("FAIL dense '%s' = %s, want %s" % [name, dense[name], dense_want[name]])
	if dense_ok:
		print("OK  the dense column carries the ratified [UUI-11] values")
		passed += 1
	else:
		failed += 1

	# The ARITHMETIC the column exists for, not just its values: seven keys at 44px with the
	# authored touch tokens is 388px and overflows the 360 floor, which is why a third column
	# was added rather than a local override. Asserting the reason means a well-meaning retune
	# of row_gap or gutter cannot quietly reintroduce the overflow the ruling removed.
	var keys := 7
	var dense_row := (
		keys * float(dense["row_height"])
		+ (keys - 1) * float(dense["row_gap"])
		+ 2.0 * float(dense["gutter"])
	)
	var touch_row := (
		keys * float(touch["min_target"])
		+ (keys - 1) * float(touch["row_gap"])
		+ 2.0 * float(touch["gutter"])
	)
	if dense_row <= 360.0 and touch_row > 360.0:
		print(
			(
				"OK  seven keys fit the 360 floor in dense (%s) and do not in touch (%s)"
				% [dense_row, touch_row]
			)
		)
		passed += 1
	else:
		print("FAIL key-row arithmetic: dense %s, touch %s, floor 360" % [dense_row, touch_row])
		failed += 1

	if is_equal_approx(float(dense["min_target"]), 44.0):
		print("OK  dense keeps the 44pt minimum target — only the whitespace shrank")
		passed += 1
	else:
		print("FAIL dense min_target = %s, want 44" % dense["min_target"])
		failed += 1

	# ---- The editor column ([CEUI-S1]/[CEUI-S50], album Sheet 8) ----
	var editor := ResponsiveLayoutS.tokens_for_mode(ResponsiveLayoutS.MENU_MODE_EDITOR)
	var editor_want := {
		"row_height": 26.0,
		"row_gap": 2.0,
		"body_font": 14.0,
		"detail_row": 22.0,
		"min_target": 24.0,
		"gutter": 8.0,
		"header": 44.0,
		"footer": 22.0,
	}
	var editor_ok := true
	for name in editor_want:
		if not is_equal_approx(float(editor[name]), float(editor_want[name])):
			editor_ok = false
			print("FAIL editor '%s' = %s, want %s" % [name, editor[name], editor_want[name]])
	if editor_ok:
		print("OK  the editor column carries the adopted Sheet 8 values")
		passed += 1
	else:
		failed += 1

	# EW-9 ruled this number explicitly against the obvious objection: raising it to touch's
	# 44 would halve what the densest surfaces in the project can show.
	if is_equal_approx(float(editor["min_target"]), 24.0) and float(editor["min_target"]) < 44.0:
		print("OK  editor min_target stays 24 (EW-9), deliberately below the touch minimum")
		passed += 1
	else:
		print("FAIL editor min_target = %s, want 24" % editor["min_target"])
		failed += 1

	# The six editor-only tokens exist in the editor column and NOWHERE else — they describe
	# furniture the game does not have, so a game column defining one would be a copy-paste.
	var editor_only_ok := true
	for name in ResponsiveLayoutS.EDITOR_ONLY_TOKENS:
		if not editor.has(name):
			editor_only_ok = false
			print("FAIL editor-only token '%s' missing from the editor column" % name)
		for mode in ResponsiveLayoutS.MENU_MODES:
			if mode != ResponsiveLayoutS.MENU_MODE_EDITOR:
				if ResponsiveLayoutS.tokens_for_mode(mode).has(name):
					editor_only_ok = false
					print("FAIL editor-only token '%s' leaked into '%s'" % [name, mode])
	if editor_only_ok:
		print("OK  the six editor-only tokens exist only in the editor column")
		passed += 1
	else:
		failed += 1

	# The two resize bounds bracket their preferred value. A preferred width outside its own
	# bounds is unsatisfiable and would only show up as a pane that will not sit where it was
	# asked to.
	var bounds_ok := true
	for base in ["tree_width", "inspector_width"]:
		var preferred := float(editor[base])
		var low := float(editor[base + "_min"])
		var high := float(editor[base + "_max"])
		if not (low <= preferred and preferred <= high and low < high):
			bounds_ok = false
			print("FAIL %s bounds: %s not within [%s, %s]" % [base, preferred, low, high])
	if bounds_ok:
		print("OK  the editor resize bounds bracket their preferred widths")
		passed += 1
	else:
		failed += 1

	# Owner decision 2026-08-06: defaults are large buttons with the controller on screen.
	if layout.menu_mode == ResponsiveLayoutS.MENU_MODE_TOUCH:
		print("OK  Menu Mode defaults to touch (large buttons)")
		passed += 1
	else:
		print("FAIL Menu Mode defaults to '%s'" % layout.menu_mode)
		failed += 1

	var density_events := {"count": 0}
	layout.density_changed.connect(func() -> void: density_events["count"] += 1)
	layout.set_menu_mode(ResponsiveLayoutS.MENU_MODE_CONTROLLER)
	if is_equal_approx(layout.token("row_height"), 28.0):
		print("OK  token() follows the active Menu Mode")
		passed += 1
	else:
		print(
			(
				"FAIL token('row_height') = %s after switching to controller"
				% layout.token("row_height")
			)
		)
		failed += 1
	layout.set_menu_mode(ResponsiveLayoutS.MENU_MODE_CONTROLLER)
	layout.set_menu_mode("nonsense")
	if density_events["count"] == 1:
		print("OK  density_changed fires once; a same-value and an invalid write are no-ops")
		passed += 1
	else:
		print("FAIL density_changed fired %d time(s), want 1" % density_events["count"])
		failed += 1
	if layout.menu_mode == ResponsiveLayoutS.MENU_MODE_CONTROLLER:
		print("OK  an invalid Menu Mode leaves the previous value intact")
		passed += 1
	else:
		print("FAIL invalid write changed Menu Mode to '%s'" % layout.menu_mode)
		failed += 1

	if is_equal_approx(layout.token("does_not_exist", 7.0), 7.0):
		print("OK  an unknown token returns its fallback, not 0")
		passed += 1
	else:
		print("FAIL unknown token did not return the fallback")
		failed += 1

	if layout.info_density == ResponsiveLayoutS.DENSITY_STANDARD:
		print("OK  information density defaults to standard")
		passed += 1
	else:
		print("FAIL information density defaults to '%s'" % layout.info_density)
		failed += 1
	layout.set_info_density(ResponsiveLayoutS.DENSITY_MINIMAL)
	layout.set_info_density("dense-ish")
	if layout.info_density == ResponsiveLayoutS.DENSITY_MINIMAL:
		print("OK  information density is settable and rejects an unknown value")
		passed += 1
	else:
		print("FAIL information density = '%s'" % layout.info_density)
		failed += 1

	# ---- Class ordering ----
	layout.size_class = ResponsiveLayoutS.CLASS_MEDIUM
	if (
		layout.at_least(ResponsiveLayoutS.CLASS_COMPACT)
		and layout.at_least(ResponsiveLayoutS.CLASS_MEDIUM)
		and not layout.at_least(ResponsiveLayoutS.CLASS_EXPANDED)
	):
		print("OK  at_least() orders the classes compact < medium < expanded")
		passed += 1
	else:
		print("FAIL at_least() ordering wrong at medium")
		failed += 1
	layout.size_class = ResponsiveLayoutS.CLASS_COMPACT
	if layout.is_compact() and not layout.at_least(ResponsiveLayoutS.CLASS_MEDIUM):
		print("OK  is_compact() agrees with at_least()")
		passed += 1
	else:
		print("FAIL is_compact() disagrees with at_least()")
		failed += 1

	layout.free()

	# ---- Context scoping ([CEUI-S3] call 1) ----
	# The editor hosts a playable session, so the chrome sits at editor density while the
	# game view derives its class from its SubViewport. One global size_class cannot say
	# that. These use a REAL tree and a REAL SubViewport rather than apply_logical_size(),
	# because the thing under test is precisely which viewport a context measures — driving
	# the class by hand would assert the seam against itself and pass no matter what.
	#
	# The node is named explicitly: an unnamed add_child() takes the script's name, which
	# is one letter from the autoload's, and a node that shadows /root/ResponsiveLayout
	# hollows out every later assertion in a way that still prints OK.
	var root_layout: Node = ResponsiveLayoutS.new()
	root_layout.name = "ResponsiveLayoutUnderTest"
	root.add_child(root_layout)
	await process_frame

	var sub := SubViewport.new()
	sub.size = Vector2i(420, 800)  # Compact by width; the window headless is 1280 Expanded
	root.add_child(sub)
	var embedded := Control.new()
	sub.add_child(embedded)
	var in_window := Control.new()
	root.add_child(in_window)
	await process_frame

	var game_ctx: Node = root_layout.create_context(sub, "game")
	await process_frame

	if game_ctx != root_layout and game_ctx.is_sub_context() and not root_layout.is_sub_context():
		print("OK  a sub-context is a distinct context bound to its own viewport")
		passed += 1
	else:
		print("FAIL create_context did not produce a distinct bound context")
		failed += 1

	if (
		game_ctx.size_class == ResponsiveLayoutS.CLASS_COMPACT
		and root_layout.size_class == ResponsiveLayoutS.CLASS_EXPANDED
	):
		print("OK  the embedded context is Compact while the window context stays Expanded")
		passed += 1
	else:
		print(
			(
				"FAIL classes did not diverge: embedded '%s', window '%s'"
				% [game_ctx.size_class, root_layout.size_class]
			)
		)
		failed += 1

	if game_ctx.measured_viewport() == sub and root_layout.measured_viewport() != sub:
		print("OK  each context measures its own viewport")
		passed += 1
	else:
		print("FAIL a context measured the wrong viewport")
		failed += 1

	# Resolution by viewport is the whole point: the same scene must resolve to the game
	# context when embedded and to the root context in the window, with no flag threaded
	# through it.
	if root_layout.context_for(embedded) == game_ctx:
		print("OK  a node inside the sub-viewport resolves to the embedded context")
		passed += 1
	else:
		print("FAIL a node inside the sub-viewport did not resolve to its context")
		failed += 1
	if root_layout.context_for(in_window) == root_layout:
		print("OK  a node in the window resolves to the root context")
		passed += 1
	else:
		print("FAIL a node in the window did not resolve to the root context")
		failed += 1
	if root_layout.context_for(null) == root_layout:
		print("OK  context_for() never returns null, so no consumer needs a fallback")
		passed += 1
	else:
		print("FAIL context_for(null) did not fall back to the root context")
		failed += 1

	# A second call returns the SAME context rather than a second one racing it.
	if root_layout.create_context(sub, "game") == game_ctx:
		print("OK  create_context is idempotent for one viewport")
		passed += 1
	else:
		print("FAIL create_context made a second context for the same viewport")
		failed += 1

	# Density is seeded then independent: previewing a touch layout inside the editor must
	# not flip the chrome around it.
	var seeded_mode: String = game_ctx.menu_mode
	game_ctx.set_menu_mode(ResponsiveLayoutS.MENU_MODE_CONTROLLER)
	if (
		seeded_mode == root_layout.menu_mode
		and root_layout.menu_mode == ResponsiveLayoutS.MENU_MODE_TOUCH
	):
		print("OK  a sub-context is seeded from the root context's Menu Mode")
		passed += 1
	else:
		print("FAIL sub-context Menu Mode was not seeded from the root")
		failed += 1
	if (
		game_ctx.menu_mode == ResponsiveLayoutS.MENU_MODE_CONTROLLER
		and root_layout.menu_mode == ResponsiveLayoutS.MENU_MODE_TOUCH
		and not is_equal_approx(game_ctx.token("row_height"), root_layout.token("row_height"))
	):
		print("OK  Menu Mode and its tokens are per context, not per application")
		passed += 1
	else:
		print("FAIL Menu Mode leaked between contexts")
		failed += 1

	# A publish in one context must not reach the other: a screen in the window rebuilding
	# because the editor resized its preview pane is the defect this scoping prevents.
	var window_recorder := ClassRecorder.new()
	root_layout.size_class_changed.connect(window_recorder.on_size_class_changed)
	var embedded_recorder := ClassRecorder.new()
	game_ctx.size_class_changed.connect(embedded_recorder.on_size_class_changed)
	game_ctx.apply_logical_size(Vector2(1600.0, 900.0))
	if (
		embedded_recorder.classes() == [ResponsiveLayoutS.CLASS_EXPANDED]
		and window_recorder.events.is_empty()
	):
		print("OK  a class change in one context publishes to that context only")
		passed += 1
	else:
		print(
			(
				"FAIL publish crossed contexts: embedded %s, window %s"
				% [embedded_recorder.classes(), window_recorder.classes()]
			)
		)
		failed += 1

	# Release, and the registry forgets it — the same node then resolves to the root again.
	root_layout.release_context(sub)
	if root_layout.context_for(embedded) == root_layout:
		print("OK  a released viewport resolves back to the root context")
		passed += 1
	else:
		print("FAIL release_context left a stale registry entry")
		failed += 1
	root_layout.release_context(sub)  # twice must be safe
	print("OK  release_context is safe to call twice")
	passed += 1

	# Auto-release: freeing the viewport without releasing must not leave a context bound
	# to a dead viewport. Nobody remembers to clean up when tearing an editor down.
	var sub2 := SubViewport.new()
	sub2.size = Vector2i(500, 700)
	root.add_child(sub2)
	var orphan := Control.new()
	sub2.add_child(orphan)
	await process_frame
	var ctx2: Node = root_layout.create_context(sub2, "second")
	await process_frame
	if root_layout.context_for(orphan) == ctx2:
		print("OK  a second concurrent context registers alongside the first")
		passed += 1
	else:
		print("FAIL a second context did not register")
		failed += 1
	sub2.queue_free()
	await process_frame
	await process_frame
	if root_layout.context_for(in_window) == root_layout:
		print("OK  freeing a bound viewport auto-releases its context")
		passed += 1
	else:
		print("FAIL a freed viewport left its context registered")
		failed += 1

	in_window.queue_free()
	sub.queue_free()
	root_layout.queue_free()
	await process_frame

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


# Stands in for a converted screen: saves its state, rebuilds, restores. What is being
# tested is the seam's half of that contract, not this class's.
class StatefulConsumer:
	extends RefCounted
	var state: Dictionary
	var layout: Node = null
	var class_at_signal: String = ""

	func _init(shared_state: Dictionary) -> void:
		state = shared_state

	func on_size_class_changed(_new_class: String, _previous_class: String) -> void:
		if layout != null:
			class_at_signal = layout.size_class
		var selection: int = state["selection"]
		var scroll: float = state["scroll"]
		var more_info: String = state["more_info"]
		# The rebuild a real screen would do: tear the panes down and put them back.
		state["selection"] = -1
		state["scroll"] = 0.0
		state["more_info"] = ""
		state["selection"] = selection
		state["scroll"] = scroll
		state["more_info"] = more_info
		state["rebuilds"] = int(state["rebuilds"]) + 1
