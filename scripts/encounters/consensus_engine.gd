extends Node

signal completed(result: Dictionary)
signal cancelled

const BACKGROUND_PATH := "res://assets/encounters/consensus_engine_stage_v1.png"
const VIEW_SIZE := Vector2(1280, 720)
const MOVE_SPEED := 330.0
const INTERACTION_RADIUS := 82.0
const DEROGATION_HOLD := 1.05
const DEFAULT_INTRO_DURATION := 1.7
const DEFAULT_BEAT_DURATION := 1.0
const DEFAULT_OUTRO_DURATION := 2.2

enum State { INACTIVE, INTRO, ACTIVE, PHASE_RESULT, PRINTING, CLEARED }

const PHASE_SEQUENCES := [
	["scanner", "stamp", "submit"],
	["stamp", "translation", "mobile_stamp", "submit"],
	["submit", "scanner", "translation", "scanner", "translation", "submit"],
]
const PHASE_BASE_APPROVALS := [0, 8, 26]
const PHASE_APPROVAL_STEPS := [
	[3, 6, 8],
	[14, 20, 25, 26],
	[26, 26, 26, 26, 26, 27],
]
const PHASE_TITLES := [
	"PHASE I  ·  SIMPLE MAJORITY",
	"PHASE II  ·  QUALIFIED MAJORITY",
	"PHASE III  ·  UNANIMITY",
]
const STATION_POSITIONS := {
	"scanner": Vector2(640, 246),
	"stamp": Vector2(354, 366),
	"translation": Vector2(930, 366),
	"submit": Vector2(640, 505),
	"emergency": Vector2(1006, 553),
}
const STATION_NAMES := {
	"scanner": "SCANNER",
	"stamp": "BLUE STAMP",
	"translation": "TRANSLATION",
	"mobile_stamp": "65% STAMP",
	"submit": "SUBMIT",
	"emergency": "HOLD SPACE",
}

var host: Node
var layer: CanvasLayer
var root_control: Control
var frame: Control
var title_label: Label
var approvals_label: Label
var requirement_label: Label
var prompt_label: Label
var lights: Array[ColorRect] = []
var station_nodes: Dictionary = {}
var dossier_root: Node2D
var dossier_body: Polygon2D
var dossier_stamp: Label
var target_ring: Line2D
var mobile_stamp_node: PanelContainer
var emergency_fill: ColorRect
var emergency_panel: PanelContainer
var printer_sheet: ColorRect
var printer_label: Label

var active := false
var state: State = State.INACTIVE
var state_timer := 0.0
var intro_duration := DEFAULT_INTRO_DURATION
var beat_duration := DEFAULT_BEAT_DURATION
var outro_duration := DEFAULT_OUTRO_DURATION
var timers_enabled := true
var phase_index := 0
var step_index := 0
var approvals := 0
var dossier_position := Vector2(640, 604)
var phase_time_remaining := 30.0
var mobile_stamp_time := 0.0
var derogation_hold := 0.0
var derogation_unlocked := false
var derogation_used := false
var expiry_resets := 0
var misroutes := 0
var station_actions := 0
var attempts := 1
var completion_route := ""
var result: Dictionary = {}


func setup(owner: Node) -> void:
	host = owner
	_create_overlay()


func start(options: Dictionary = {}) -> void:
	if not layer:
		_create_overlay()
	intro_duration = maxf(0.0, float(options.get("intro_duration", DEFAULT_INTRO_DURATION)))
	beat_duration = maxf(0.0, float(options.get("beat_duration", DEFAULT_BEAT_DURATION)))
	outro_duration = maxf(0.0, float(options.get("outro_duration", DEFAULT_OUTRO_DURATION)))
	timers_enabled = bool(options.get("timers_enabled", true))
	phase_index = 0
	step_index = 0
	approvals = 0
	dossier_position = Vector2(640, 604)
	derogation_hold = 0.0
	derogation_unlocked = false
	derogation_used = false
	expiry_resets = 0
	misroutes = 0
	station_actions = 0
	attempts = 1
	completion_route = ""
	result.clear()
	active = true
	layer.visible = true
	_layout_frame()
	_set_state(State.INTRO)
	_refresh_phase()


func stop() -> void:
	active = false
	state = State.INACTIVE
	if layer:
		layer.visible = false


func process_frame(delta: float) -> void:
	if not active:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		stop()
		cancelled.emit()
		return
	state_timer += delta
	mobile_stamp_time += delta
	_update_mobile_stamp()
	match state:
		State.INTRO:
			if state_timer >= intro_duration:
				_set_state(State.ACTIVE)
		State.ACTIVE:
			_process_active(delta)
		State.PHASE_RESULT:
			if state_timer >= beat_duration:
				_advance_phase()
		State.PRINTING:
			_process_printing(delta)
		State.CLEARED:
			if state_timer >= outro_duration:
				_finish_success()


func get_result() -> Dictionary:
	return result.duplicate(true)


func interact_at_station(station_id: String) -> bool:
	if not active or state != State.ACTIVE:
		return false
	var expected := _expected_station()
	if station_id != expected:
		misroutes += 1
		prompt_label.text = "WRONG DEPARTMENT"
		return false
	station_actions += 1
	step_index += 1
	approvals = int(PHASE_APPROVAL_STEPS[phase_index][step_index - 1])
	_refresh_approvals()
	if phase_index == 2 and step_index >= 3:
		derogation_unlocked = true
		emergency_panel.visible = true
	if step_index >= (PHASE_SEQUENCES[phase_index] as Array).size():
		if phase_index < 2:
			_show_phase_result()
		else:
			completion_route = "full_procedure"
			_begin_printing()
	else:
		_refresh_target()
	return true


func activate_derogation() -> bool:
	if not active or state != State.ACTIVE or phase_index != 2 or not derogation_unlocked:
		return false
	derogation_used = true
	completion_route = "emergency_derogation"
	approvals = 27
	_refresh_approvals()
	_begin_printing()
	return true


func _process_active(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	dossier_position += direction * MOVE_SPEED * delta
	dossier_position.x = clampf(dossier_position.x, 112.0, 1168.0)
	dossier_position.y = clampf(dossier_position.y, 142.0, 632.0)
	_update_dossier_position()
	if timers_enabled and phase_index < 2:
		phase_time_remaining -= delta
		if phase_time_remaining <= 0.0:
			_reset_expired_phase()
			return
	var nearby := _nearby_station()
	if nearby == "emergency" and derogation_unlocked:
		if Input.is_action_pressed("ui_accept"):
			advance_derogation_hold(delta)
		else:
			derogation_hold = 0.0
			_refresh_emergency_fill()
	elif Input.is_action_just_pressed("ui_accept") and nearby != "":
		interact_at_station(nearby)
	else:
		derogation_hold = 0.0
		_refresh_emergency_fill()
	_update_prompt(nearby)


func advance_derogation_hold(delta: float) -> bool:
	if not derogation_unlocked or state != State.ACTIVE:
		return false
	derogation_hold += delta
	_refresh_emergency_fill()
	if derogation_hold < DEROGATION_HOLD:
		return false
	return activate_derogation()


func _expected_station() -> String:
	var sequence: Array = PHASE_SEQUENCES[phase_index]
	return str(sequence[mini(step_index, sequence.size() - 1)])


func _nearby_station() -> String:
	if derogation_unlocked and dossier_position.distance_to(STATION_POSITIONS["emergency"]) <= INTERACTION_RADIUS:
		return "emergency"
	var expected := _expected_station()
	var target_position := _station_position(expected)
	if dossier_position.distance_to(target_position) <= INTERACTION_RADIUS:
		return expected
	for station_id in STATION_POSITIONS:
		if station_id == "emergency":
			continue
		if dossier_position.distance_to(STATION_POSITIONS[station_id]) <= INTERACTION_RADIUS:
			return str(station_id)
	return ""


func _station_position(station_id: String) -> Vector2:
	if station_id == "mobile_stamp":
		return mobile_stamp_node.position + mobile_stamp_node.size * 0.5
	return STATION_POSITIONS.get(station_id, Vector2.ZERO)


func _update_prompt(nearby: String) -> void:
	if nearby == "emergency" and derogation_unlocked:
		prompt_label.text = "SPACE  ·  HOLD"
	elif nearby != "":
		prompt_label.text = "SPACE  ·  %s" % str(STATION_NAMES.get(nearby, "PROCESS"))
	else:
		prompt_label.text = "ARROWS  ·  MOVE DOSSIER"


func _show_phase_result() -> void:
	if phase_index == 0:
		requirement_label.text = "SIMPLE MAJORITY ACHIEVED\nINSUFFICIENT FOR THIS PROCEDURE"
	else:
		requirement_label.text = "64% REPRESENTED\n65% REQUIRED"
	prompt_label.text = ""
	_set_state(State.PHASE_RESULT)


func _advance_phase() -> void:
	phase_index += 1
	step_index = 0
	approvals = int(PHASE_BASE_APPROVALS[phase_index])
	dossier_position = Vector2(640, 604)
	phase_time_remaining = 35.0 if phase_index == 1 else 999.0
	_refresh_phase()
	_set_state(State.ACTIVE)


func _reset_expired_phase() -> void:
	expiry_resets += 1
	attempts += 1
	step_index = 0
	approvals = int(PHASE_BASE_APPROVALS[phase_index])
	phase_time_remaining = 30.0 if phase_index == 0 else 35.0
	dossier_position = Vector2(640, 604)
	requirement_label.text = "APPROVALS EXPIRED  ·  RESUBMIT"
	_refresh_phase()


func _begin_printing() -> void:
	requirement_label.text = "PROCEDURE SUCCESSFULLY COMPLETED\nIN ACCORDANCE WITH PROCEDURE"
	prompt_label.text = ""
	printer_sheet.visible = true
	printer_sheet.size.y = 0.0
	printer_label.visible = false
	_set_state(State.PRINTING)


func _process_printing(delta: float) -> void:
	printer_sheet.size.y = minf(315.0, printer_sheet.size.y + delta * 178.0)
	if printer_sheet.size.y >= 270.0:
		printer_label.visible = true
		printer_label.text = "PAGE 1 OF 847"
	if printer_sheet.size.y >= 315.0 and state_timer >= 2.15:
		result = {
			"outcome": "access_granted",
			"route": completion_route,
			"derogation_used": derogation_used,
			"expiry_resets": expiry_resets,
			"misroutes": misroutes,
			"station_actions": station_actions,
			"attempts": attempts,
		}
		title_label.text = "UNANIMOUS APPROVAL"
		requirement_label.text = "ACCESS AUTHORIZED"
		_set_state(State.CLEARED)


func _finish_success() -> void:
	var final_result := result.duplicate(true)
	stop()
	completed.emit(final_result)


func _set_state(next_state: State) -> void:
	state = next_state
	state_timer = 0.0


func _refresh_phase() -> void:
	title_label.text = str(PHASE_TITLES[phase_index])
	requirement_label.text = _requirement_text()
	_refresh_approvals()
	_refresh_target()
	_update_dossier_position()
	mobile_stamp_node.visible = phase_index == 1
	emergency_panel.visible = phase_index == 2 and derogation_unlocked
	printer_sheet.visible = false
	printer_label.visible = false


func _requirement_text() -> String:
	if phase_index == 0:
		return "SCAN  →  BLUE STAMP  →  SUBMIT"
	if phase_index == 1:
		return "55% MEMBER STATES  +  65% POPULATION"
	if step_index == 0:
		return "26 / 27  ·  MISSING ANNEX B"
	if step_index <= 2:
		return "ANNEX B MUST BE TRANSLATED"
	return "TRANSLATION REQUIRES ANNEX C"


func _refresh_approvals() -> void:
	approvals_label.text = "%02d / 27  APPROVALS" % approvals
	for i in range(lights.size()):
		if i < approvals:
			lights[i].color = Color("#56f092")
		elif phase_index == 2 and i == 26:
			lights[i].color = Color("#f04455")
		else:
			lights[i].color = Color(0.13, 0.19, 0.21, 0.92)


func _refresh_target() -> void:
	var station_id := _expected_station()
	target_ring.position = _station_position(station_id)
	for id in station_nodes:
		var node: PanelContainer = station_nodes[id]
		node.modulate = Color.WHITE if id == station_id else Color(0.64, 0.7, 0.74, 0.82)
	requirement_label.text = _requirement_text()


func _update_mobile_stamp() -> void:
	if not mobile_stamp_node:
		return
	var x := 536.0 + sin(mobile_stamp_time * 1.9) * 240.0
	mobile_stamp_node.position = Vector2(x, 403)
	if active and state == State.ACTIVE and _expected_station() == "mobile_stamp":
		target_ring.position = _station_position("mobile_stamp")


func _update_dossier_position() -> void:
	if dossier_root:
		dossier_root.position = dossier_position


func _refresh_emergency_fill() -> void:
	if emergency_fill:
		emergency_fill.size.x = 132.0 * clampf(derogation_hold / DEROGATION_HOLD, 0.0, 1.0)


func _create_overlay() -> void:
	layer = CanvasLayer.new()
	layer.name = "ConsensusEngineLayer"
	layer.layer = 113
	layer.visible = false
	add_child(layer)
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root_control)
	var blackout := ColorRect.new()
	blackout.set_anchors_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color("#020608")
	root_control.add_child(blackout)
	frame = Control.new()
	frame.size = VIEW_SIZE
	frame.clip_contents = true
	root_control.add_child(frame)
	root_control.resized.connect(_layout_frame)
	var background := TextureRect.new()
	background.size = VIEW_SIZE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture = load(BACKGROUND_PATH) if ResourceLoader.exists(BACKGROUND_PATH) else null
	frame.add_child(background)
	var wash := ColorRect.new()
	wash.size = VIEW_SIZE
	wash.color = Color(0.015, 0.035, 0.05, 0.16)
	frame.add_child(wash)

	for i in range(27):
		var angle := -PI * 0.94 + (PI * 1.88 * float(i) / 26.0)
		var light := ColorRect.new()
		light.position = Vector2(640, 356) + Vector2(cos(angle) * 500.0, sin(angle) * 244.0) - Vector2(8, 8)
		light.size = Vector2(16, 16)
		light.color = Color(0.13, 0.19, 0.21, 0.92)
		frame.add_child(light)
		lights.append(light)

	var top_bar := ColorRect.new()
	top_bar.size = Vector2(1280, 108)
	top_bar.color = Color(0.018, 0.04, 0.055, 0.94)
	frame.add_child(top_bar)
	title_label = _make_label(Vector2(26, 12), Vector2(1228, 35), 25, Color("#7ad9ff"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(title_label)
	approvals_label = _make_label(Vector2(30, 48), Vector2(1220, 30), 20, Color("#f5e794"))
	approvals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(approvals_label)
	requirement_label = _make_label(Vector2(230, 112), Vector2(820, 62), 18, Color.WHITE)
	requirement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	requirement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	frame.add_child(requirement_label)
	prompt_label = _make_label(Vector2(330, 650), Vector2(620, 40), 21, Color("#fff2a7"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(prompt_label)

	_create_station("scanner", Vector2(575, 210), Vector2(130, 72), Color("#5ac9ed"))
	_create_station("stamp", Vector2(289, 330), Vector2(130, 72), Color("#4f81e8"))
	_create_station("translation", Vector2(865, 330), Vector2(130, 72), Color("#ca72de"))
	_create_station("submit", Vector2(575, 469), Vector2(130, 72), Color("#65d18d"))

	mobile_stamp_node = _make_panel(Vector2(536, 403), Vector2(150, 66), Color("#ffd45c"))
	mobile_stamp_node.visible = true
	frame.add_child(mobile_stamp_node)
	var mobile_label := _make_label(Vector2(8, 14), Vector2(134, 36), 15, Color("#1b1a12"))
	mobile_label.text = "65% STAMP"
	mobile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mobile_stamp_node.add_child(mobile_label)

	emergency_panel = _make_panel(Vector2(923, 514), Vector2(166, 77), Color("#f04c3f"))
	frame.add_child(emergency_panel)
	var emergency_content := Control.new()
	emergency_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emergency_panel.add_child(emergency_content)
	var emergency_label := _make_label(Vector2(8, 8), Vector2(150, 26), 14, Color.WHITE)
	emergency_label.text = "EMERGENCY DEROGATION"
	emergency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emergency_content.add_child(emergency_label)
	var fill_back := ColorRect.new()
	fill_back.position = Vector2(17, 47)
	fill_back.size = Vector2(132, 12)
	fill_back.color = Color(0.1, 0.08, 0.08, 0.9)
	emergency_content.add_child(fill_back)
	emergency_fill = ColorRect.new()
	emergency_fill.position = Vector2(17, 47)
	emergency_fill.size = Vector2(0, 12)
	emergency_fill.color = Color("#ffdf58")
	emergency_content.add_child(emergency_fill)
	emergency_panel.visible = false

	target_ring = Line2D.new()
	target_ring.width = 4.0
	target_ring.default_color = Color("#ffec7a")
	target_ring.closed = true
	for i in range(25):
		var angle := TAU * float(i) / 24.0
		target_ring.add_point(Vector2(cos(angle), sin(angle)) * 53.0)
	frame.add_child(target_ring)

	dossier_root = Node2D.new()
	frame.add_child(dossier_root)
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-29, 24), Vector2(32, 24), Vector2(39, 31), Vector2(-35, 31)])
	shadow.color = Color(0, 0, 0, 0.45)
	dossier_root.add_child(shadow)
	dossier_body = Polygon2D.new()
	dossier_body.polygon = PackedVector2Array([Vector2(-32, -24), Vector2(22, -24), Vector2(34, -12), Vector2(34, 25), Vector2(-32, 25)])
	dossier_body.color = Color("#ead9a4")
	dossier_root.add_child(dossier_body)
	var fold := Polygon2D.new()
	fold.polygon = PackedVector2Array([Vector2(22, -24), Vector2(34, -12), Vector2(22, -12)])
	fold.color = Color("#bcae85")
	dossier_root.add_child(fold)
	dossier_stamp = _make_label(Vector2(-27, -9), Vector2(54, 23), 13, Color("#153c7d"))
	dossier_stamp.text = "CASE"
	dossier_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dossier_root.add_child(dossier_stamp)

	printer_sheet = ColorRect.new()
	printer_sheet.position = Vector2(612, 272)
	printer_sheet.size = Vector2(56, 0)
	printer_sheet.color = Color("#ede7ca")
	frame.add_child(printer_sheet)
	printer_label = _make_label(Vector2(515, 600), Vector2(250, 35), 19, Color("#fff2a7"))
	printer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(printer_label)
	printer_sheet.visible = false
	printer_label.visible = false


func _create_station(id: String, position_value: Vector2, size_value: Vector2, color: Color) -> void:
	var panel := _make_panel(position_value, size_value, color)
	frame.add_child(panel)
	station_nodes[id] = panel
	var label := _make_label(Vector2(5, 16), Vector2(size_value.x - 10, 40), 15, Color.WHITE)
	label.text = str(STATION_NAMES[id])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)


func _make_panel(position_value: Vector2, size_value: Vector2, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.size = size_value
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.06, 0.075, 0.9)
	style.border_color = border
	style.set_border_width_all(3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_label(position_value: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position_value
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _layout_frame() -> void:
	if not root_control or not frame:
		return
	var viewport_size := root_control.size
	var scale_factor := minf(viewport_size.x / VIEW_SIZE.x, viewport_size.y / VIEW_SIZE.y)
	frame.scale = Vector2.ONE * scale_factor
	frame.position = (viewport_size - VIEW_SIZE * scale_factor) * 0.5
