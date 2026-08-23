extends Node

# Contextual touch controls for the browser build. Standard controls feed the
# same Godot actions used by keyboard/gamepad input; exceptional encounters
# receive semantic controls through set_touch_control().

const TOUCH_LAYER := 140
const LANDSCAPE_MIN_RATIO := 1.25

const PROFILE_LAYOUTS := {
	"menu": [
		{"id": "up", "label": "▲", "action": "ui_up", "rect": Rect2(0.035, 0.61, 0.09, 0.14)},
		{"id": "down", "label": "▼", "action": "ui_down", "rect": Rect2(0.035, 0.79, 0.09, 0.14)},
		{"id": "select", "label": "SELECT", "action": "ui_accept", "rect": Rect2(0.82, 0.73, 0.145, 0.20)},
		{"id": "back", "label": "HOLD", "action": "ui_cancel", "rect": Rect2(0.89, 0.045, 0.075, 0.105)},
	],
	"confirm": [
		{"id": "confirm", "label": "CONTINUE", "action": "ui_accept", "rect": Rect2(0.80, 0.73, 0.165, 0.20)},
	],
	"skip": [
		{"id": "skip", "label": "SKIP", "action": "ui_accept", "rect": Rect2(0.82, 0.76, 0.145, 0.17)},
	],
	"choice": [
		{"id": "up", "label": "▲", "action": "ui_up", "rect": Rect2(0.035, 0.61, 0.09, 0.14)},
		{"id": "down", "label": "▼", "action": "ui_down", "rect": Rect2(0.035, 0.79, 0.09, 0.14)},
		{"id": "select", "label": "SELECT", "action": "ui_accept", "rect": Rect2(0.82, 0.73, 0.145, 0.20)},
	],
	"drive": [
		{"id": "left", "label": "◀", "action": "ui_left", "rect": Rect2(0.035, 0.72, 0.13, 0.21)},
		{"id": "right", "label": "▶", "action": "ui_right", "rect": Rect2(0.18, 0.72, 0.13, 0.21)},
	],
	"overworld": [
		{"id": "left", "label": "◀", "action": "ui_left", "rect": Rect2(0.025, 0.76, 0.085, 0.17)},
		{"id": "right", "label": "▶", "action": "ui_right", "rect": Rect2(0.19, 0.76, 0.085, 0.17)},
		{"id": "up", "label": "▲", "action": "ui_up", "rect": Rect2(0.108, 0.60, 0.085, 0.17)},
		{"id": "down", "label": "▼", "action": "ui_down", "rect": Rect2(0.108, 0.79, 0.085, 0.17)},
		{"id": "act", "label": "ACT", "action": "ui_accept", "rect": Rect2(0.83, 0.73, 0.135, 0.20)},
		{"id": "hold", "label": "HOLD", "action": "ui_cancel", "rect": Rect2(0.89, 0.045, 0.075, 0.105)},
	],
	"move_action": [
		{"id": "left", "label": "◀", "action": "ui_left", "rect": Rect2(0.025, 0.76, 0.085, 0.17)},
		{"id": "right", "label": "▶", "action": "ui_right", "rect": Rect2(0.19, 0.76, 0.085, 0.17)},
		{"id": "up", "label": "▲", "action": "ui_up", "rect": Rect2(0.108, 0.60, 0.085, 0.17)},
		{"id": "down", "label": "▼", "action": "ui_down", "rect": Rect2(0.108, 0.79, 0.085, 0.17)},
		{"id": "act", "label": "ACT", "action": "ui_accept", "rect": Rect2(0.83, 0.73, 0.135, 0.20)},
	],
	"bunker": [
		{"id": "left", "label": "◀", "action": "ui_left", "rect": Rect2(0.025, 0.76, 0.085, 0.17)},
		{"id": "right", "label": "▶", "action": "ui_right", "rect": Rect2(0.19, 0.76, 0.085, 0.17)},
		{"id": "up", "label": "▲", "action": "ui_up", "rect": Rect2(0.108, 0.60, 0.085, 0.17)},
		{"id": "down", "label": "▼", "action": "ui_down", "rect": Rect2(0.108, 0.79, 0.085, 0.17)},
		{"id": "dash", "label": "DASH", "action": "ui_accept", "rect": Rect2(0.83, 0.73, 0.135, 0.20)},
	],
	"consensus": [
		{"id": "left", "label": "◀", "action": "ui_left", "rect": Rect2(0.025, 0.76, 0.085, 0.17)},
		{"id": "right", "label": "▶", "action": "ui_right", "rect": Rect2(0.19, 0.76, 0.085, 0.17)},
		{"id": "up", "label": "▲", "action": "ui_up", "rect": Rect2(0.108, 0.60, 0.085, 0.17)},
		{"id": "down", "label": "▼", "action": "ui_down", "rect": Rect2(0.108, 0.79, 0.085, 0.17)},
		{"id": "process", "label": "PROCESS\nHOLD", "action": "ui_accept", "rect": Rect2(0.82, 0.70, 0.15, 0.23)},
	],
	"greatest_play": [
		{"id": "hit", "label": "HIT", "custom": "hit", "rect": Rect2(0.63, 0.77, 0.15, 0.16)},
		{"id": "stand", "label": "STAND", "custom": "stand", "rect": Rect2(0.81, 0.77, 0.15, 0.16)},
	],
	"greatest_claim": [
		{"id": "accept", "label": "ACCEPT", "custom": "accept", "rect": Rect2(0.63, 0.77, 0.15, 0.16)},
		{"id": "challenge", "label": "CHALLENGE", "custom": "challenge", "rect": Rect2(0.81, 0.77, 0.15, 0.16)},
	],
	"pinball": [
		{"id": "left_flipper", "label": "L", "action": "ui_left", "rect": Rect2(0.035, 0.72, 0.18, 0.22)},
		{"id": "right_flipper", "label": "R", "action": "ui_right", "rect": Rect2(0.785, 0.72, 0.18, 0.22)},
	],
	"bezos_contest": [
		{"id": "contest", "label": "Z", "custom": "contest", "rect": Rect2(0.82, 0.70, 0.15, 0.23)},
	],
	"bezos_objection": [
		{"id": "objection", "label": "X\nHOLD", "custom": "objection", "rect": Rect2(0.82, 0.70, 0.15, 0.23)},
	],
	"putin": [
		{"id": "strafe_left", "label": "◀", "custom": "strafe_left", "rect": Rect2(0.025, 0.76, 0.085, 0.17)},
		{"id": "strafe_right", "label": "▶", "custom": "strafe_right", "rect": Rect2(0.19, 0.76, 0.085, 0.17)},
		{"id": "forward", "label": "▲", "custom": "forward", "rect": Rect2(0.108, 0.60, 0.085, 0.17)},
		{"id": "backward", "label": "▼", "custom": "backward", "rect": Rect2(0.108, 0.79, 0.085, 0.17)},
		{"id": "turn_left", "label": "TURN ◀", "custom": "turn_left", "rect": Rect2(0.58, 0.78, 0.105, 0.15)},
		{"id": "turn_right", "label": "TURN ▶", "custom": "turn_right", "rect": Rect2(0.695, 0.78, 0.105, 0.15)},
		{"id": "fire", "label": "FIRE", "custom": "fire", "rect": Rect2(0.83, 0.70, 0.135, 0.18)},
		{"id": "reload", "label": "RELOAD", "custom": "reload", "rect": Rect2(0.85, 0.50, 0.115, 0.135)},
	],
}

var host: Node
var context_provider: Callable
var layer: CanvasLayer
var root_control: Control
var controls_root: Control
var rotate_overlay: PanelContainer
var enabled := false
var active_profile := ""
var active_target: Node
var controls: Dictionary = {}
var pointer_controls: Dictionary = {}
var control_pointers: Dictionary = {}
var action_press_counts: Dictionary = {}


func setup(owner: Node, force_enabled := false, provider := Callable()) -> void:
	host = owner
	context_provider = provider
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_overlay()
	set_enabled(force_enabled or DisplayServer.is_touchscreen_available())


func set_enabled(value: bool) -> void:
	_release_all()
	enabled = value
	set_process_input(enabled)
	if layer:
		layer.visible = enabled
	_update_orientation()


func is_enabled() -> bool:
	return enabled


func _process(_delta: float) -> void:
	if enabled and context_provider.is_valid():
		var context = context_provider.call()
		if context is Dictionary:
			process_frame(context)


func process_frame(context: Dictionary) -> void:
	if not enabled:
		return
	_update_orientation()
	var profile := str(context.get("profile", ""))
	var target := context.get("target") as Node
	if profile != active_profile or target != active_target:
		_apply_context(profile, target)


func apply_context_for_test(profile: String, target: Node = null) -> void:
	_apply_context(profile, target)


func get_active_control_ids() -> Array[String]:
	var ids: Array[String] = []
	for control_id in controls:
		ids.append(str(control_id))
	return ids


func press_control(control_id: String, pointer_id := -1) -> bool:
	if not enabled or not controls.has(control_id):
		return false
	if pointer_id >= 0 and pointer_controls.has(pointer_id):
		_release_pointer(pointer_id)
	var pointers: Dictionary = control_pointers.get(control_id, {})
	if pointers.has(pointer_id):
		return true
	pointers[pointer_id] = true
	control_pointers[control_id] = pointers
	if pointer_id >= 0:
		pointer_controls[pointer_id] = control_id
	if pointers.size() == 1:
		_set_control_state(control_id, true)
	return true


func release_control(control_id: String, pointer_id := -1) -> void:
	if not control_pointers.has(control_id):
		return
	var pointers: Dictionary = control_pointers[control_id]
	pointers.erase(pointer_id)
	if pointer_id >= 0:
		pointer_controls.erase(pointer_id)
	if pointers.is_empty():
		control_pointers.erase(control_id)
		_set_control_state(control_id, false)
	else:
		control_pointers[control_id] = pointers


func _input(event: InputEvent) -> void:
	if not enabled or not controls_root.visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var handled := false
		if touch.pressed:
			handled = _press_pointer_at(touch.index, touch.position)
		else:
			handled = _release_pointer(touch.index)
		if handled:
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var hovered := _control_at(drag.position)
		var previous := str(pointer_controls.get(drag.index, ""))
		if hovered != previous:
			_release_pointer(drag.index)
			if hovered != "":
				press_control(hovered, drag.index)
		if hovered != "" or previous != "":
			get_viewport().set_input_as_handled()


func _apply_context(profile: String, target: Node) -> void:
	_release_all()
	active_profile = profile
	active_target = target
	for child in controls_root.get_children():
		child.queue_free()
	controls.clear()
	var definitions: Array = PROFILE_LAYOUTS.get(profile, [])
	for definition_variant in definitions:
		if definition_variant is Dictionary:
			_create_control(definition_variant as Dictionary)
	controls_root.visible = enabled and not definitions.is_empty() and not rotate_overlay.visible


func _create_control(definition: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.name = "Touch_%s" % str(definition.get("id", "control"))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var normalized_rect: Rect2 = definition.get("rect", Rect2())
	panel.anchor_left = normalized_rect.position.x
	panel.anchor_top = normalized_rect.position.y
	panel.anchor_right = normalized_rect.end.x
	panel.anchor_bottom = normalized_rect.end.y
	panel.offset_left = 4.0
	panel.offset_top = 4.0
	panel.offset_right = -4.0
	panel.offset_bottom = -4.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.055, 0.64)
	style.border_color = Color(0.32, 0.86, 0.94, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = str(definition.get("label", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	controls_root.add_child(panel)
	controls[str(definition.get("id", ""))] = {"node": panel, "definition": definition}


func _press_pointer_at(pointer_id: int, position: Vector2) -> bool:
	var control_id := _control_at(position)
	if control_id != "":
		return press_control(control_id, pointer_id)
	return false


func _release_pointer(pointer_id: int) -> bool:
	if not pointer_controls.has(pointer_id):
		return false
	var control_id := str(pointer_controls[pointer_id])
	release_control(control_id, pointer_id)
	return true


func _control_at(position: Vector2) -> String:
	for control_id in controls:
		var entry: Dictionary = controls[control_id]
		var panel := entry.get("node") as Control
		if panel and panel.visible and panel.get_global_rect().has_point(position):
			return str(control_id)
	return ""


func _set_control_state(control_id: String, pressed: bool) -> void:
	if not controls.has(control_id):
		return
	var entry: Dictionary = controls[control_id]
	var definition: Dictionary = entry.get("definition", {})
	var panel := entry.get("node") as Control
	if panel:
		panel.modulate = Color(1.25, 1.08, 0.62) if pressed else Color.WHITE
	var action := str(definition.get("action", ""))
	if action != "":
		_set_action_state(action, pressed)
	var custom := str(definition.get("custom", ""))
	if custom != "" and active_target and active_target.has_method("set_touch_control"):
		active_target.set_touch_control(custom, pressed)


func _set_action_state(action: String, pressed: bool) -> void:
	var count := int(action_press_counts.get(action, 0))
	if pressed:
		count += 1
		action_press_counts[action] = count
		if count == 1:
			_emit_action_event(action, true)
		return
	count = maxi(0, count - 1)
	if count == 0:
		action_press_counts.erase(action)
		_emit_action_event(action, false)
	else:
		action_press_counts[action] = count


func _emit_action_event(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _release_all() -> void:
	for action in action_press_counts.keys():
		_emit_action_event(str(action), false)
	for control_id in control_pointers.keys():
		if not controls.has(control_id):
			continue
		var definition: Dictionary = (controls[control_id] as Dictionary).get("definition", {})
		var custom := str(definition.get("custom", ""))
		if custom != "" and active_target and active_target.has_method("set_touch_control"):
			active_target.set_touch_control(custom, false)
	action_press_counts.clear()
	pointer_controls.clear()
	control_pointers.clear()


func _update_orientation() -> void:
	if not layer or not root_control:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.y > 0.0 and viewport_size.x / viewport_size.y < LANDSCAPE_MIN_RATIO
	rotate_overlay.visible = enabled and portrait
	controls_root.visible = enabled and not portrait and controls.size() > 0


func _create_overlay() -> void:
	if layer:
		return
	layer = CanvasLayer.new()
	layer.name = "TouchControlLayer"
	layer.layer = TOUCH_LAYER
	add_child(layer)
	root_control = Control.new()
	root_control.name = "TouchControls"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root_control)
	controls_root = Control.new()
	controls_root.name = "ContextControls"
	controls_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(controls_root)
	rotate_overlay = PanelContainer.new()
	rotate_overlay.name = "LandscapeRequired"
	rotate_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rotate_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.02, 0.03, 0.96)
	style.border_color = Color(0.87, 0.68, 0.22)
	style.set_border_width_all(4)
	rotate_overlay.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "ROTATE DEVICE\n\nCASE PROCESSING REQUIRES LANDSCAPE ORIENTATION"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.62))
	rotate_overlay.add_child(label)
	root_control.add_child(rotate_overlay)
	layer.visible = false
