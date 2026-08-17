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
var lights: Array[PanelContainer] = []
var station_nodes: Dictionary = {}
var station_status_lights: Dictionary = {}
var dossier_root: Node2D
var dossier_body: Polygon2D
var dossier_stamp: Label
var dossier_seal: PanelContainer
var target_ring: Line2D
var target_halo: Polygon2D
var mobile_stamp_node: PanelContainer
var mobile_stamp_light: PanelContainer
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
	_update_target_visual()
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
	dossier_stamp.text = "%02d / 27" % approvals
	for i in range(lights.size()):
		if i < approvals:
			_set_indicator_color(lights[i], Color("#56f092"), Color(0.22, 0.95, 0.55, 0.36))
		elif phase_index == 2 and i == 26:
			_set_indicator_color(lights[i], Color("#f04455"), Color(0.95, 0.14, 0.22, 0.38))
		else:
			_set_indicator_color(lights[i], Color("#14252c"), Color(0, 0, 0, 0.0))
	if dossier_seal:
		_set_indicator_color(dossier_seal, Color("#3a76ba") if approvals < 27 else Color("#56f092"), Color(0.2, 0.75, 1.0, 0.24))


func _refresh_target() -> void:
	var station_id := _expected_station()
	target_ring.position = _station_position(station_id)
	target_halo.position = target_ring.position
	for id in station_nodes:
		var node: PanelContainer = station_nodes[id]
		node.modulate = Color.WHITE if id == station_id else Color(0.62, 0.69, 0.72, 0.86)
		var status_light: PanelContainer = station_status_lights[id]
		_set_indicator_color(
			status_light,
			Color("#ffdd68") if id == station_id else Color("#16272d"),
			Color(1.0, 0.75, 0.16, 0.36) if id == station_id else Color(0, 0, 0, 0)
		)
	requirement_label.text = _requirement_text()


func _update_mobile_stamp() -> void:
	if not mobile_stamp_node:
		return
	var x := 536.0 + sin(mobile_stamp_time * 1.9) * 240.0
	mobile_stamp_node.position = Vector2(x, 403)
	if active and state == State.ACTIVE and _expected_station() == "mobile_stamp":
		target_ring.position = _station_position("mobile_stamp")
		target_halo.position = target_ring.position
		_set_indicator_color(mobile_stamp_light, Color("#ffdd68"), Color(1.0, 0.75, 0.16, 0.38))
	else:
		_set_indicator_color(mobile_stamp_light, Color("#342d19"), Color(0, 0, 0, 0))


func _update_target_visual() -> void:
	if not target_ring or not target_halo:
		return
	var pulse := 0.5 + sin(mobile_stamp_time * 4.2) * 0.5
	target_ring.rotation = sin(mobile_stamp_time * 1.35) * 0.045
	target_ring.modulate.a = lerpf(0.72, 1.0, pulse)
	target_halo.modulate.a = lerpf(0.2, 0.38, pulse)


func _update_dossier_position() -> void:
	if dossier_root:
		dossier_root.position = dossier_position


func _refresh_emergency_fill() -> void:
	if emergency_fill:
		emergency_fill.size.x = 152.0 * clampf(derogation_hold / DEROGATION_HOLD, 0.0, 1.0)


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
	wash.color = Color(0.015, 0.035, 0.05, 0.11)
	frame.add_child(wash)

	for i in range(27):
		var angle := -PI * 0.94 + (PI * 1.88 * float(i) / 26.0)
		var housing := _make_round_indicator(Vector2(22, 22), Color("#14252c"), Color("#9f8d5c"), 4)
		housing.name = "ApprovalHousing%02d" % (i + 1)
		housing.position = Vector2(640, 356) + Vector2(cos(angle) * 500.0, sin(angle) * 244.0) - Vector2(11, 11)
		frame.add_child(housing)
		var housing_content := Control.new()
		housing_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		housing.add_child(housing_content)
		var core := _make_round_indicator(Vector2(12, 12), Color("#14252c"), Color("#071015"), 2)
		core.name = "ApprovalCore%02d" % (i + 1)
		core.position = Vector2(5, 5)
		housing_content.add_child(core)
		lights.append(core)

	var top_bar := _make_panel(Vector2(14, 10), Vector2(1252, 94), Color("#bba760"), Color(0.012, 0.033, 0.046, 0.97), 4)
	top_bar.name = "CouncilStatusConsole"
	frame.add_child(top_bar)
	var top_content := Control.new()
	top_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(top_content)
	var header_glass := ColorRect.new()
	header_glass.position = Vector2(10, 9)
	header_glass.size = Vector2(1232, 72)
	header_glass.color = Color(0.035, 0.095, 0.13, 0.72)
	header_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_content.add_child(header_glass)
	for i in range(12):
		var star := _make_round_indicator(Vector2(5, 5), Color("#e6c85b"), Color("#58481d"), 1)
		var star_angle := TAU * float(i) / 12.0
		star.position = Vector2(56, 45) + Vector2(cos(star_angle), sin(star_angle)) * 22.0 - Vector2(2.5, 2.5)
		top_content.add_child(star)
	title_label = _make_label(Vector2(90, 17), Vector2(1072, 31), 24, Color("#8bddff"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_content.add_child(title_label)
	approvals_label = _make_label(Vector2(90, 49), Vector2(1072, 30), 22, Color("#f7e38a"))
	approvals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_content.add_child(approvals_label)

	var requirement_panel := _make_panel(Vector2(222, 112), Vector2(836, 62), Color("#617c88"), Color(0.018, 0.052, 0.067, 0.94), 3)
	requirement_panel.name = "ProcedureDirective"
	frame.add_child(requirement_panel)
	requirement_label = _make_label(Vector2(12, 5), Vector2(812, 52), 18, Color.WHITE)
	requirement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	requirement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	requirement_panel.add_child(requirement_label)
	var prompt_panel := _make_panel(Vector2(360, 649), Vector2(560, 43), Color("#9b874c"), Color(0.018, 0.045, 0.056, 0.96), 3)
	prompt_panel.name = "InputConsole"
	frame.add_child(prompt_panel)
	prompt_label = _make_label(Vector2(8, 4), Vector2(544, 35), 20, Color("#fff2a7"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_panel.add_child(prompt_label)

	_create_station("scanner", Vector2(562, 203), Vector2(156, 86), Color("#5ac9ed"), "SCAN // OPTICAL")
	_create_station("stamp", Vector2(276, 323), Vector2(156, 86), Color("#4f81e8"), "STAMP // BLUE")
	_create_station("translation", Vector2(852, 323), Vector2(156, 86), Color("#ca72de"), "A <> B // 24 LANG")
	_create_station("submit", Vector2(562, 462), Vector2(156, 86), Color("#65d18d"), "SEND // COUNCIL")

	mobile_stamp_node = _make_panel(Vector2(536, 403), Vector2(150, 66), Color("#ffd45c"), Color("#29230f"), 5)
	mobile_stamp_node.name = "MobilePopulationStamp"
	mobile_stamp_node.visible = true
	frame.add_child(mobile_stamp_node)
	var mobile_content := Control.new()
	mobile_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_stamp_node.add_child(mobile_content)
	var mobile_stripe := ColorRect.new()
	mobile_stripe.position = Vector2(0, 0)
	mobile_stripe.size = Vector2(150, 11)
	mobile_stripe.color = Color("#ffd45c")
	mobile_content.add_child(mobile_stripe)
	var mobile_label := _make_label(Vector2(8, 17), Vector2(134, 36), 15, Color("#fff2b0"))
	mobile_label.text = "65% STAMP"
	mobile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mobile_content.add_child(mobile_label)
	mobile_stamp_light = _make_round_indicator(Vector2(12, 12), Color("#342d19"), Color("#9e8333"), 2)
	mobile_stamp_light.position = Vector2(128, 27)
	mobile_content.add_child(mobile_stamp_light)

	emergency_panel = _make_panel(Vector2(913, 506), Vector2(186, 94), Color("#ca4139"), Color("#311414"), 5)
	emergency_panel.name = "EmergencyDerogationConsole"
	frame.add_child(emergency_panel)
	var emergency_content := Control.new()
	emergency_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emergency_panel.add_child(emergency_content)
	var emergency_glass := _make_panel(Vector2(9, 8), Vector2(168, 47), Color("#ff7569"), Color(0.22, 0.025, 0.03, 0.96), 3)
	emergency_content.add_child(emergency_glass)
	var emergency_label := _make_label(Vector2(5, 6), Vector2(158, 34), 13, Color.WHITE)
	emergency_label.text = "EMERGENCY DEROGATION"
	emergency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emergency_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emergency_glass.add_child(emergency_label)
	var fill_back := ColorRect.new()
	fill_back.position = Vector2(17, 67)
	fill_back.size = Vector2(152, 13)
	fill_back.color = Color(0.1, 0.08, 0.08, 0.9)
	emergency_content.add_child(fill_back)
	emergency_fill = ColorRect.new()
	emergency_fill.position = Vector2(17, 67)
	emergency_fill.size = Vector2(0, 12)
	emergency_fill.color = Color("#ffdf58")
	emergency_content.add_child(emergency_fill)
	emergency_panel.visible = false

	target_halo = Polygon2D.new()
	target_halo.name = "ProcedureTargetHalo"
	target_halo.polygon = _circle_points(61.0, 32)
	target_halo.color = Color(0.2, 0.82, 1.0, 0.18)
	frame.add_child(target_halo)
	target_ring = Line2D.new()
	target_ring.name = "ProcedureTargetBrackets"
	target_ring.width = 5.0
	target_ring.default_color = Color("#ffdf68")
	target_ring.closed = true
	for point in [Vector2(-58, -34), Vector2(-58, -52), Vector2(-40, -52), Vector2(40, -52), Vector2(58, -52), Vector2(58, -34), Vector2(58, 34), Vector2(58, 52), Vector2(40, 52), Vector2(-40, 52), Vector2(-58, 52), Vector2(-58, 34)]:
		target_ring.add_point(point)
	frame.add_child(target_ring)

	dossier_root = Node2D.new()
	dossier_root.name = "CitizenDossier"
	frame.add_child(dossier_root)
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-41, -23), Vector2(34, -23), Vector2(43, -14), Vector2(43, 35), Vector2(-43, 35)])
	shadow.color = Color(0, 0, 0, 0.45)
	dossier_root.add_child(shadow)
	var tab := Polygon2D.new()
	tab.polygon = PackedVector2Array([Vector2(-38, -31), Vector2(-7, -31), Vector2(1, -23), Vector2(-38, -23)])
	tab.color = Color("#c3a958")
	dossier_root.add_child(tab)
	dossier_body = Polygon2D.new()
	dossier_body.polygon = PackedVector2Array([Vector2(-40, -25), Vector2(28, -25), Vector2(40, -13), Vector2(40, 31), Vector2(-40, 31)])
	dossier_body.color = Color("#ead7a0")
	dossier_root.add_child(dossier_body)
	var fold := Polygon2D.new()
	fold.polygon = PackedVector2Array([Vector2(28, -25), Vector2(40, -13), Vector2(28, -13)])
	fold.color = Color("#bcae85")
	dossier_root.add_child(fold)
	var blue_band := ColorRect.new()
	blue_band.position = Vector2(-40, -12)
	blue_band.size = Vector2(80, 8)
	blue_band.color = Color("#24548a")
	dossier_root.add_child(blue_band)
	var red_band := ColorRect.new()
	red_band.position = Vector2(-40, -4)
	red_band.size = Vector2(80, 3)
	red_band.color = Color("#a63b38")
	dossier_root.add_child(red_band)
	var case_label := _make_label(Vector2(-34, 2), Vector2(42, 18), 10, Color("#493c25"))
	case_label.text = "PASSPORT"
	dossier_root.add_child(case_label)
	dossier_stamp = _make_label(Vector2(-22, 13), Vector2(48, 17), 11, Color("#153c7d"))
	dossier_stamp.text = "00 / 27"
	dossier_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dossier_root.add_child(dossier_stamp)
	dossier_seal = _make_round_indicator(Vector2(15, 15), Color("#3a76ba"), Color("#183e69"), 2)
	dossier_seal.position = Vector2(21, 7)
	dossier_root.add_child(dossier_seal)
	var staple := ColorRect.new()
	staple.position = Vector2(-32, -21)
	staple.size = Vector2(13, 2)
	staple.color = Color("#766b55")
	dossier_root.add_child(staple)

	printer_sheet = ColorRect.new()
	printer_sheet.name = "RegulationPrintout"
	printer_sheet.position = Vector2(612, 272)
	printer_sheet.size = Vector2(56, 0)
	printer_sheet.color = Color("#ede7ca")
	printer_sheet.clip_contents = true
	frame.add_child(printer_sheet)
	var printer_margin := ColorRect.new()
	printer_margin.position = Vector2(7, 0)
	printer_margin.size = Vector2(3, 315)
	printer_margin.color = Color("#b94b50")
	printer_sheet.add_child(printer_margin)
	for i in range(18):
		var printed_line := ColorRect.new()
		printed_line.position = Vector2(15, 13 + i * 16)
		printed_line.size = Vector2(33 if i % 4 != 3 else 24, 2)
		printed_line.color = Color(0.18, 0.25, 0.27, 0.36)
		printer_sheet.add_child(printed_line)
	printer_label = _make_label(Vector2(515, 600), Vector2(250, 35), 19, Color("#fff2a7"))
	printer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(printer_label)
	printer_sheet.visible = false
	printer_label.visible = false


func _create_station(id: String, position_value: Vector2, size_value: Vector2, color: Color, technical_label: String) -> void:
	var panel := _make_panel(position_value, size_value, color, Color("#10232c"), 5)
	panel.name = "%sConsole" % id.capitalize().replace(" ", "")
	frame.add_child(panel)
	station_nodes[id] = panel
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)
	var face := ColorRect.new()
	face.position = Vector2(8, 9)
	face.size = Vector2(size_value.x - 16, size_value.y - 18)
	face.color = Color(0.035, 0.11, 0.14, 0.94)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(face)
	var accent := ColorRect.new()
	accent.position = Vector2(8, 9)
	accent.size = Vector2(size_value.x - 16, 8)
	accent.color = color
	content.add_child(accent)
	var label := _make_label(Vector2(14, 22), Vector2(size_value.x - 28, 28), 16, Color.WHITE)
	label.text = str(STATION_NAMES[id])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(label)
	var technical := _make_label(Vector2(14, 52), Vector2(size_value.x - 28, 18), 9, Color("#8db3bd"))
	technical.text = technical_label
	technical.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(technical)
	var status := _make_round_indicator(Vector2(12, 12), Color("#16272d"), Color("#54636a"), 2)
	status.position = Vector2(size_value.x - 25, 26)
	content.add_child(status)
	station_status_lights[id] = status


func _make_panel(position_value: Vector2, size_value: Vector2, border: Color, background: Color = Color(0.025, 0.06, 0.075, 0.96), border_width: int = 3) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.size = size_value
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_round_indicator(size_value: Vector2, fill: Color, border: Color, border_width: int) -> PanelContainer:
	var indicator := PanelContainer.new()
	indicator.size = size_value
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	var radius := int(minf(size_value.x, size_value.y) * 0.5)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	indicator.add_theme_stylebox_override("panel", style)
	return indicator


func _set_indicator_color(indicator: PanelContainer, fill: Color, glow: Color) -> void:
	if not indicator:
		return
	var current := indicator.get_theme_stylebox("panel") as StyleBoxFlat
	if not current:
		return
	var style := current.duplicate() as StyleBoxFlat
	style.bg_color = fill
	style.shadow_color = glow
	style.shadow_size = 9 if glow.a > 0.0 else 0
	indicator.add_theme_stylebox_override("panel", style)


func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


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
