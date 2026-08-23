extends Node

signal completed(result: Dictionary)

const BACKGROUND_PATH := "res://assets/interiors/ufo_unreconciled_chamber_v1.png"
const VIEW_SIZE := Vector2(1280, 720)
const ARENA_RECT := Rect2(250, 145, 780, 455)
const ARENA_CENTER := Vector2(640, 402)
const CITIZEN_SPEED := 270.0
const PAD_RADIUS := 54.0
const HISTORY_SAMPLE_INTERVAL := 0.05
const ECHO_PLAYBACK_SPEED := 1.18
const DEFAULT_INTRO_DURATION := 1.35
const DEFAULT_TRANSITION_DURATION := 1.25
const DEFAULT_COLLAPSE_DURATION := 1.15
const DEFAULT_OUTRO_DURATION := 1.8

const PHASE_ONE_PADS := [
	Vector2(430, 402),
	Vector2(850, 402),
]

const PHASE_TWO_PADS := [
	Vector2(350, 450),
	Vector2(640, 240),
	Vector2(930, 450),
]

enum State {
	INACTIVE,
	INTRO,
	PHASE_ONE,
	BETWEEN_PHASES,
	PHASE_TWO,
	CERTIFY,
	COLLAPSE,
	CLEARED,
}

var host: Node
var layer: CanvasLayer
var root_control: Control
var frame: Control
var arena_root: Node2D
var pad_layer: Node2D
var echo_layer: Node2D
var scanner_layer: Node2D
var citizen_node: Node2D
var passport_node: Node2D
var title_label: Label
var phase_label: Label
var subject_label: Label
var status_label: Label
var prompt_label: Label
var scanner_label: Label
var clock_labels: Array[Label] = []
var result_panel: PanelContainer
var result_title: Label
var result_subtitle: Label
var pad_nodes: Array[Dictionary] = []
var scanner_lines: Array[Line2D] = []
var glitch_strips: Array[ColorRect] = []

var hum_audio: AudioStreamPlayer
var record_audio: AudioStreamPlayer
var error_audio: AudioStreamPlayer
var phase_audio: AudioStreamPlayer
var collapse_audio: AudioStreamPlayer

var active := false
var state: State = State.INACTIVE
var state_timer := 0.0
var total_elapsed := 0.0
var phase_index := 0
var citizen_position := ARENA_CENTER
var recent_path: Array[Vector2] = []
var history_sample_timer := 0.0
var echoes: Array[Dictionary] = []
var reserved_pads: Array[int] = []
var current_pad_positions: Array[Vector2] = []
var scanner_time := 0.0
var scanner_cooldown := 0.0
var scanner_resets := 0
var recording_attempts := 0
var state_changes := 0
var intro_duration := DEFAULT_INTRO_DURATION
var transition_duration := DEFAULT_TRANSITION_DURATION
var collapse_duration := DEFAULT_COLLAPSE_DURATION
var outro_duration := DEFAULT_OUTRO_DURATION
var scanner_enabled := true
var manual_input_enabled := true
var result: Dictionary = {}


func setup(owner: Node) -> void:
	host = owner
	_create_overlay()
	_create_audio()


func start(options: Dictionary = {}) -> void:
	if not layer:
		_create_overlay()
	if not hum_audio:
		_create_audio()
	intro_duration = maxf(0.0, float(options.get("intro_duration", DEFAULT_INTRO_DURATION)))
	transition_duration = maxf(0.0, float(options.get("transition_duration", DEFAULT_TRANSITION_DURATION)))
	collapse_duration = maxf(0.0, float(options.get("collapse_duration", DEFAULT_COLLAPSE_DURATION)))
	outro_duration = maxf(0.0, float(options.get("outro_duration", DEFAULT_OUTRO_DURATION)))
	scanner_enabled = bool(options.get("scanner_enabled", true))
	manual_input_enabled = bool(options.get("manual_input_enabled", true))
	total_elapsed = 0.0
	phase_index = 0
	scanner_time = 0.0
	scanner_cooldown = 0.0
	scanner_resets = 0
	recording_attempts = 0
	state_changes = 0
	result.clear()
	_clear_echoes()
	_clear_pads()
	citizen_position = ARENA_CENTER
	citizen_node.scale = Vector2.ONE
	citizen_node.rotation = 0.0
	citizen_node.modulate = Color.WHITE
	recent_path = [ARENA_CENTER]
	history_sample_timer = 0.0
	active = true
	layer.visible = true
	result_panel.visible = false
	passport_node.visible = true
	passport_node.position = ARENA_CENTER
	passport_node.scale = Vector2.ONE
	passport_node.modulate = Color(1, 1, 1, 0.74)
	phase_label.text = "IDENTITY CALIBRATION"
	subject_label.text = "REGISTERED CITIZENS  1    DETECTED  1"
	status_label.text = "PROVE THAT ONE PERSON CAN OCCUPY TWO RECORDS"
	status_label.modulate.a = 1.0
	prompt_label.text = "ARROWS  MOVE        SPACE  RECORD"
	scanner_label.visible = false
	_update_clock_labels()
	_sync_citizen_node()
	_layout_frame()
	_set_state(State.INTRO)
	if hum_audio and hum_audio.stream:
		hum_audio.play()


func stop() -> void:
	active = false
	state = State.INACTIVE
	for player in [hum_audio, record_audio, error_audio, phase_audio, collapse_audio]:
		if player:
			player.stop()
	if layer:
		layer.visible = false


func process_frame(delta: float) -> void:
	if not active:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		status_label.text = "ACTIVE OBSERVATION CANNOT BE SUSPENDED"
		status_label.modulate.a = 1.0
		if error_audio:
			error_audio.pitch_scale = 0.72
			error_audio.play()
	state_timer += delta
	total_elapsed += delta
	_update_ambient(delta)
	match state:
		State.INTRO:
			if state_timer >= intro_duration:
				_begin_phase(0)
		State.PHASE_ONE, State.PHASE_TWO:
			_process_active_phase(delta)
			if Input.is_action_just_pressed("ui_accept"):
				commit_recording()
		State.BETWEEN_PHASES:
			if state_timer >= transition_duration:
				_begin_phase(1)
		State.CERTIFY:
			if Input.is_action_just_pressed("ui_accept"):
				certify_identity()
		State.COLLAPSE:
			if state_timer >= collapse_duration:
				_show_clearance()
		State.CLEARED:
			if state_timer >= outro_duration:
				_finish_success()


func commit_recording() -> bool:
	if not active or state not in [State.PHASE_ONE, State.PHASE_TWO]:
		return false
	recording_attempts += 1
	var pad_index := _pad_at_position(citizen_position)
	var required_echoes := current_pad_positions.size() - 1
	if pad_index < 0 or reserved_pads.has(pad_index) or echoes.size() >= required_echoes:
		_reject_recording()
		return false
	if recent_path.is_empty() or not recent_path.back().is_equal_approx(citizen_position):
		recent_path.append(citizen_position)
	_create_echo(recent_path.duplicate(), pad_index)
	reserved_pads.append(pad_index)
	if record_audio:
		record_audio.pitch_scale = 1.0 + float(echoes.size() - 1) * 0.16
		record_audio.play()
	status_label.text = "TIMELINE %d RECORDED" % echoes.size()
	status_label.modulate.a = 1.0
	citizen_position = ARENA_CENTER
	recent_path = [ARENA_CENTER]
	history_sample_timer = 0.0
	_sync_citizen_node()
	_refresh_subject_label()
	return true


func certify_identity() -> bool:
	if not active or state != State.CERTIFY:
		return false
	if collapse_audio:
		collapse_audio.play()
	result_panel.visible = false
	prompt_label.text = ""
	status_label.text = "COLLAPSING ADMINISTRATIVE OBSERVATIONS"
	status_label.modulate.a = 1.0
	scanner_label.visible = false
	passport_node.visible = true
	passport_node.modulate = Color(0.72, 1.0, 0.92, 1.0)
	_begin_collapse_visual()
	_set_state(State.COLLAPSE)
	return true


func simulate_scan_hit() -> bool:
	if not active or state != State.PHASE_TWO:
		return false
	_handle_scan_hit()
	return true


func get_result() -> Dictionary:
	return result.duplicate(true)


func get_pad_positions() -> Array[Vector2]:
	return current_pad_positions.duplicate()


func get_state_name() -> String:
	return State.keys()[state]


func _process_active_phase(delta: float) -> void:
	if manual_input_enabled:
		_update_citizen_movement(delta)
	_sample_current_path(delta)
	_update_echoes(delta)
	_update_scanners(delta)
	_update_pad_visuals()
	_check_phase_completion()


func _update_citizen_movement(delta: float) -> void:
	var movement := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if movement.length_squared() > 1.0:
		movement = movement.normalized()
	citizen_position += movement * CITIZEN_SPEED * delta
	citizen_position.x = clampf(citizen_position.x, ARENA_RECT.position.x, ARENA_RECT.end.x)
	citizen_position.y = clampf(citizen_position.y, ARENA_RECT.position.y, ARENA_RECT.end.y)
	_sync_citizen_node()


func _sample_current_path(delta: float) -> void:
	history_sample_timer += delta
	while history_sample_timer >= HISTORY_SAMPLE_INTERVAL:
		history_sample_timer -= HISTORY_SAMPLE_INTERVAL
		if recent_path.is_empty() or recent_path.back().distance_to(citizen_position) > 0.5:
			recent_path.append(citizen_position)


func _create_echo(path: Array[Vector2], pad_index: int) -> void:
	var echo_color := Color(0.35, 0.95, 1.0, 0.72) if echoes.is_empty() else Color(0.92, 0.48, 1.0, 0.72)
	var echo_node := _make_subject(echo_color, "T-%d" % (echoes.size() + 1), true)
	echo_node.position = path[0] if not path.is_empty() else ARENA_CENTER
	echo_layer.add_child(echo_node)
	var trail := Line2D.new()
	trail.width = 3.0
	trail.default_color = Color(echo_color.r, echo_color.g, echo_color.b, 0.24)
	trail.points = PackedVector2Array(path)
	trail.antialiased = true
	echo_layer.add_child(trail)
	echoes.append({
		"node": echo_node,
		"trail": trail,
		"path": path,
		"elapsed": 0.0,
		"finished": false,
		"pad_index": pad_index,
	})


func _update_echoes(delta: float) -> void:
	for echo in echoes:
		var node := echo.get("node") as Node2D
		var path: Array = echo.get("path", [])
		if not node or path.is_empty() or bool(echo.get("finished", false)):
			continue
		echo["elapsed"] = float(echo.get("elapsed", 0.0)) + delta
		var sample_index := mini(
			path.size() - 1,
			int(float(echo["elapsed"]) * ECHO_PLAYBACK_SPEED / HISTORY_SAMPLE_INTERVAL)
		)
		node.position = path[sample_index]
		if sample_index >= path.size() - 1:
			echo["finished"] = true
			var pad_index := int(echo.get("pad_index", -1))
			if pad_index >= 0 and pad_index < current_pad_positions.size():
				node.position = current_pad_positions[pad_index]
			var tween := create_tween()
			tween.tween_property(node, "scale", Vector2.ONE * 1.18, 0.12)
			tween.tween_property(node, "scale", Vector2.ONE, 0.18)


func _clear_echoes() -> void:
	for echo in echoes:
		for key in ["node", "trail"]:
			var node := echo.get(key) as Node
			if node and is_instance_valid(node):
				node.queue_free()
	echoes.clear()
	reserved_pads.clear()


func _remove_last_echo() -> void:
	if echoes.is_empty():
		return
	var echo: Dictionary = echoes.pop_back()
	for key in ["node", "trail"]:
		var node := echo.get(key) as Node
		if node and is_instance_valid(node):
			node.queue_free()
	var pad_index := int(echo.get("pad_index", -1))
	reserved_pads.erase(pad_index)


func _begin_phase(next_phase: int) -> void:
	phase_index = next_phase
	_clear_echoes()
	_clear_pads()
	citizen_position = ARENA_CENTER
	recent_path = [ARENA_CENTER]
	history_sample_timer = 0.0
	_sync_citizen_node()
	passport_node.visible = false
	result_panel.visible = false
	if phase_index == 0:
		current_pad_positions.assign(PHASE_ONE_PADS)
		phase_label.text = "PHASE I   IDENTITY CALIBRATION"
		status_label.text = "RECORD ONE PLATFORM. OCCUPY THE OTHER."
		_set_state(State.PHASE_ONE)
	else:
		current_pad_positions.assign(PHASE_TWO_PADS)
		phase_label.text = "PHASE II   SIMULTANEOUS RESIDENCY"
		status_label.text = "THREE LOCATIONS. ONE REGISTERED CITIZEN."
		_set_state(State.PHASE_TWO)
	status_label.modulate.a = 1.0
	prompt_label.text = "ARROWS  MOVE        SPACE  RECORD"
	_create_pads()
	_refresh_subject_label()
	_update_scanners(0.0)
	if phase_audio:
		phase_audio.pitch_scale = 0.92 if phase_index == 0 else 1.18
		phase_audio.play()


func _check_phase_completion() -> void:
	if echoes.size() != current_pad_positions.size() - 1:
		return
	for echo in echoes:
		if not bool(echo.get("finished", false)):
			return
	var citizen_pad := _pad_at_position(citizen_position)
	if citizen_pad < 0 or reserved_pads.has(citizen_pad):
		return
	for pad_index in range(current_pad_positions.size()):
		if not _is_pad_occupied(pad_index):
			return
	_update_pad_visuals()
	if state == State.PHASE_ONE:
		phase_label.text = "CALIBRATION ACCEPTED"
		subject_label.text = "ONE SUBJECT DETECTED:  2"
		status_label.text = "IDENTITY COUNT HAS BEEN CORRECTED UPWARD"
		prompt_label.text = ""
		if phase_audio:
			phase_audio.pitch_scale = 1.34
			phase_audio.play()
		_set_state(State.BETWEEN_PHASES)
	else:
		phase_label.text = "PHASE III   COLLAPSE THE RECORD"
		subject_label.text = "CONCURRENT SUBJECTS  3    REGISTERED CITIZENS  1"
		status_label.text = "ALL OBSERVATIONS VALID. MUTUAL CONSISTENCY NOT REQUIRED."
		prompt_label.text = "SPACE  CERTIFY SINGLE IDENTITY"
		scanner_label.visible = false
		for line in scanner_lines:
			line.visible = false
		_set_state(State.CERTIFY)


func _pad_at_position(position_value: Vector2) -> int:
	for pad_index in range(current_pad_positions.size()):
		if position_value.distance_to(current_pad_positions[pad_index]) <= PAD_RADIUS:
			return pad_index
	return -1


func _is_pad_occupied(pad_index: int) -> bool:
	if pad_index < 0 or pad_index >= current_pad_positions.size():
		return false
	var pad_position := current_pad_positions[pad_index]
	if citizen_position.distance_to(pad_position) <= PAD_RADIUS:
		return true
	for echo in echoes:
		if not bool(echo.get("finished", false)):
			continue
		var node := echo.get("node") as Node2D
		if node and node.position.distance_to(pad_position) <= PAD_RADIUS:
			return true
	return false


func _reject_recording() -> void:
	status_label.text = "NO VALID PLATFORM AT CURRENT COORDINATES"
	status_label.modulate.a = 1.0
	if error_audio:
		error_audio.pitch_scale = 0.82
		error_audio.play()
	var tween := create_tween()
	tween.tween_property(citizen_node, "position:x", citizen_position.x - 8.0, 0.05)
	tween.tween_property(citizen_node, "position:x", citizen_position.x + 8.0, 0.08)
	tween.tween_property(citizen_node, "position:x", citizen_position.x, 0.05)


func _update_scanners(delta: float) -> void:
	var scanner_active := state == State.PHASE_TWO
	for line in scanner_lines:
		line.visible = scanner_active
	if not scanner_active:
		scanner_label.visible = false
		return
	scanner_time += delta
	scanner_cooldown = maxf(0.0, scanner_cooldown - delta)
	var vertical_x := 640.0 + sin(scanner_time * 0.72) * 315.0
	var horizontal_y := 385.0 + cos(scanner_time * 0.58) * 165.0
	scanner_lines[0].points = PackedVector2Array([Vector2(vertical_x, 150), Vector2(vertical_x, 590)])
	scanner_lines[1].points = PackedVector2Array([Vector2(260, horizontal_y), Vector2(1020, horizontal_y)])
	var sweep_phase := fmod(scanner_time, 4.2)
	var dangerous := sweep_phase >= 3.32
	var scan_color := Color(1.0, 0.26, 0.34, 0.82) if dangerous else Color(0.38, 0.9, 1.0, 0.20)
	for line in scanner_lines:
		line.default_color = scan_color
		line.width = 8.0 if dangerous else 3.0
	scanner_label.visible = dangerous
	scanner_label.text = "OBSERVATION SWEEP"
	if not scanner_enabled or not dangerous or scanner_cooldown > 0.0:
		return
	if _pad_at_position(citizen_position) >= 0:
		return
	if absf(citizen_position.x - vertical_x) <= 13.0 or absf(citizen_position.y - horizontal_y) <= 13.0:
		_handle_scan_hit()


func _handle_scan_hit() -> void:
	scanner_resets += 1
	scanner_cooldown = 1.1
	_remove_last_echo()
	citizen_position = ARENA_CENTER
	recent_path = [ARENA_CENTER]
	history_sample_timer = 0.0
	_sync_citizen_node()
	_refresh_subject_label()
	_update_clock_labels()
	status_label.text = "OBSERVATION INVALID    TIMESTAMP REISSUED"
	status_label.modulate.a = 1.0
	if error_audio:
		error_audio.pitch_scale = 0.58
		error_audio.play()
	var flash := ColorRect.new()
	flash.size = VIEW_SIZE
	flash.color = Color(1.0, 0.08, 0.18, 0.22)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.26)
	tween.tween_callback(flash.queue_free)


func _begin_collapse_visual() -> void:
	var subjects: Array[Node2D] = [citizen_node]
	for echo in echoes:
		var node := echo.get("node") as Node2D
		if node:
			subjects.append(node)
	for subject in subjects:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(subject, "position", ARENA_CENTER, collapse_duration * 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(subject, "rotation", subject.rotation + TAU, collapse_duration * 0.72)
		tween.tween_property(subject, "scale", Vector2.ONE * 0.12, collapse_duration * 0.72)
	for pad in pad_nodes:
		var root := pad.get("root") as Node2D
		if root:
			var pad_tween := create_tween()
			pad_tween.tween_property(root, "modulate:a", 0.0, collapse_duration * 0.62)
	var passport_tween := create_tween().set_parallel(true)
	passport_tween.tween_property(passport_node, "scale", Vector2.ONE * 1.34, collapse_duration * 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	passport_tween.tween_property(passport_node, "rotation", 0.08, collapse_duration * 0.72)


func _show_clearance() -> void:
	result = {
		"outcome": "identity_verified",
		"route": "concurrent_observation",
		"concurrent_subject_count": 3,
		"registered_citizen_count": 1,
		"echoes_created": 2,
		"scanner_resets": scanner_resets,
		"recording_attempts": recording_attempts,
		"elapsed": total_elapsed,
		"reconciliation": "postponed",
	}
	result_panel.visible = true
	result_title.text = "IDENTITY VERIFIED"
	result_subtitle.text = "NUMBER OF IDENTITIES: UNRESOLVED"
	phase_label.text = "ADMINISTRATIVE WAVEFUNCTION COLLAPSED"
	subject_label.text = "REGISTERED CITIZENS  1    DEPARTING SUBJECTS  1"
	status_label.text = "RECONCILIATION POSTPONED"
	passport_node.modulate = Color(0.75, 1.0, 0.88, 1.0)
	if phase_audio:
		phase_audio.pitch_scale = 1.52
		phase_audio.play()
	_set_state(State.CLEARED)


func _finish_success() -> void:
	var final_result := result.duplicate(true)
	stop()
	completed.emit(final_result)


func _set_state(next_state: State) -> void:
	state = next_state
	state_timer = 0.0
	state_changes += 1


func _refresh_subject_label() -> void:
	var detected := 1 + echoes.size()
	subject_label.text = "REGISTERED CITIZENS  1    DETECTED  %d" % detected


func _update_clock_labels() -> void:
	if clock_labels.size() < 3:
		return
	clock_labels[0].text = "LOCAL   14:04:%02d" % ((12 + scanner_resets * 7) % 60)
	clock_labels[1].text = "CRAFT   14:03:??"
	clock_labels[2].text = "SYSTEM  17:44:%02d" % ((scanner_resets * 13) % 60)


func _sync_citizen_node() -> void:
	if citizen_node:
		citizen_node.position = citizen_position


func _update_pad_visuals() -> void:
	for pad_index in range(pad_nodes.size()):
		var data: Dictionary = pad_nodes[pad_index]
		var root := data.get("root") as Node2D
		var outer := data.get("outer") as Polygon2D
		var core := data.get("core") as Polygon2D
		var occupied := _is_pad_occupied(pad_index)
		var reserved := reserved_pads.has(pad_index)
		if outer:
			outer.color = Color(0.28, 1.0, 0.72, 0.86) if occupied else (Color(0.68, 0.36, 1.0, 0.72) if reserved else Color(0.26, 0.78, 1.0, 0.62))
		if core:
			core.color = Color(0.12, 0.64, 0.48, 0.42) if occupied else Color(0.04, 0.11, 0.18, 0.78)
		if root:
			var pulse := 1.0 + sin(total_elapsed * 4.4 + float(pad_index)) * (0.035 if occupied else 0.018)
			root.scale = Vector2.ONE * pulse


func _update_ambient(delta: float) -> void:
	for strip_index in range(glitch_strips.size()):
		var strip := glitch_strips[strip_index]
		strip.position.x += delta * (18.0 + float(strip_index) * 7.0)
		if strip.position.x > VIEW_SIZE.x:
			strip.position.x = -strip.size.x
		strip.modulate.a = 0.14 + sin(total_elapsed * (2.1 + strip_index * 0.17)) * 0.08
	if status_label and state in [State.PHASE_ONE, State.PHASE_TWO]:
		status_label.modulate.a = 0.78 + sin(total_elapsed * 2.6) * 0.18


func _create_overlay() -> void:
	if layer:
		return
	layer = CanvasLayer.new()
	layer.name = "ObservationProblemLayer"
	layer.layer = 114
	layer.visible = false
	add_child(layer)
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root_control)
	var blackout := ColorRect.new()
	blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color("#020309")
	blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(blackout)
	frame = Control.new()
	frame.size = VIEW_SIZE
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(frame)
	root_control.resized.connect(_layout_frame)

	var background := TextureRect.new()
	background.size = VIEW_SIZE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.modulate = Color(0.72, 0.88, 1.0, 0.62)
	background.texture = load(BACKGROUND_PATH) if ResourceLoader.exists(BACKGROUND_PATH) else null
	frame.add_child(background)
	var wash := ColorRect.new()
	wash.size = VIEW_SIZE
	wash.color = Color(0.015, 0.025, 0.08, 0.66)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(wash)

	for strip_index in range(9):
		var strip := ColorRect.new()
		strip.position = Vector2(float(strip_index * 163 - 80), 0)
		strip.size = Vector2(2 + strip_index % 3, VIEW_SIZE.y)
		strip.color = Color(0.38, 0.96, 1.0, 0.25 if strip_index % 2 else 0.14)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(strip)
		glitch_strips.append(strip)

	arena_root = Node2D.new()
	arena_root.name = "QuantumObservationArena"
	frame.add_child(arena_root)
	for ring_index in range(3):
		var ring := Line2D.new()
		ring.closed = true
		ring.width = 2.0 if ring_index < 2 else 4.0
		ring.default_color = Color(0.25, 0.88, 1.0, 0.22 - float(ring_index) * 0.045)
		ring.points = _ellipse_points(ARENA_CENTER, Vector2(388 - ring_index * 34, 228 - ring_index * 25), 64)
		ring.antialiased = true
		arena_root.add_child(ring)

	var axis_h := Line2D.new()
	axis_h.width = 2.0
	axis_h.default_color = Color(0.56, 0.42, 1.0, 0.20)
	axis_h.points = PackedVector2Array([Vector2(270, ARENA_CENTER.y), Vector2(1010, ARENA_CENTER.y)])
	arena_root.add_child(axis_h)
	var axis_v := Line2D.new()
	axis_v.width = 2.0
	axis_v.default_color = Color(0.56, 0.42, 1.0, 0.20)
	axis_v.points = PackedVector2Array([Vector2(ARENA_CENTER.x, 165), Vector2(ARENA_CENTER.x, 575)])
	arena_root.add_child(axis_v)

	scanner_layer = Node2D.new()
	scanner_layer.name = "ObservationSweepLayer"
	arena_root.add_child(scanner_layer)
	for scanner_index in range(2):
		var scanner := Line2D.new()
		scanner.width = 3.0
		scanner.default_color = Color(0.38, 0.9, 1.0, 0.2)
		scanner.antialiased = true
		scanner.visible = false
		scanner_layer.add_child(scanner)
		scanner_lines.append(scanner)

	echo_layer = Node2D.new()
	echo_layer.name = "TimelineEchoes"
	arena_root.add_child(echo_layer)
	pad_layer = Node2D.new()
	pad_layer.name = "IdentityPlatforms"
	arena_root.add_child(pad_layer)
	citizen_node = _make_subject(Color.WHITE, "CITIZEN", false)
	citizen_node.position = ARENA_CENTER
	arena_root.add_child(citizen_node)
	passport_node = _create_passport()
	passport_node.position = ARENA_CENTER
	arena_root.add_child(passport_node)

	_create_hud()
	_create_result_panel()
	_layout_frame()


func _create_hud() -> void:
	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(20, 16)
	top_panel.size = Vector2(1240, 112)
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.26, 0.86, 1.0, 0.68), Color(0.01, 0.025, 0.08, 0.92), 2))
	frame.add_child(top_panel)
	var top_content := Control.new()
	top_panel.add_child(top_content)
	title_label = _make_label(Vector2(24, 10), Vector2(540, 42), 27, Color("#d5fbff"))
	title_label.text = "THE OBSERVATION PROBLEM"
	top_content.add_child(title_label)
	phase_label = _make_label(Vector2(26, 51), Vector2(590, 34), 15, Color("#a88cff"))
	top_content.add_child(phase_label)
	subject_label = _make_label(Vector2(698, 12), Vector2(500, 34), 15, Color("#82f6c5"))
	subject_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_content.add_child(subject_label)
	var clock_names := ["LOCAL", "CRAFT", "SYSTEM"]
	for clock_index in range(3):
		var clock := _make_label(Vector2(626 + clock_index * 192, 54), Vector2(186, 28), 13, Color("#a9d8e7"))
		clock.text = "%s  --:--:--" % clock_names[clock_index]
		clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		top_content.add_child(clock)
		clock_labels.append(clock)

	status_label = _make_label(Vector2(190, 600), Vector2(900, 34), 16, Color("#c8f7ff"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	frame.add_child(status_label)
	prompt_label = _make_label(Vector2(250, 648), Vector2(780, 42), 19, Color("#f2d76f"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	frame.add_child(prompt_label)
	scanner_label = _make_label(Vector2(465, 154), Vector2(350, 34), 16, Color("#ff5268"))
	scanner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scanner_label.add_theme_color_override("font_outline_color", Color(0.18, 0, 0.02, 0.95))
	scanner_label.add_theme_constant_override("outline_size", 5)
	scanner_label.visible = false
	frame.add_child(scanner_label)


func _create_pads() -> void:
	for pad_index in range(current_pad_positions.size()):
		var root := Node2D.new()
		root.position = current_pad_positions[pad_index]
		pad_layer.add_child(root)
		var outer := Polygon2D.new()
		outer.polygon = _circle_points(PAD_RADIUS, 40)
		outer.color = Color(0.26, 0.78, 1.0, 0.62)
		root.add_child(outer)
		var middle := Polygon2D.new()
		middle.polygon = _circle_points(PAD_RADIUS - 7.0, 40)
		middle.color = Color(0.02, 0.07, 0.13, 0.96)
		root.add_child(middle)
		var core := Polygon2D.new()
		core.polygon = _circle_points(PAD_RADIUS - 17.0, 40)
		core.color = Color(0.04, 0.11, 0.18, 0.78)
		root.add_child(core)
		var cross_h := Line2D.new()
		cross_h.width = 2.0
		cross_h.default_color = Color(0.65, 0.94, 1.0, 0.54)
		cross_h.points = PackedVector2Array([Vector2(-28, 0), Vector2(28, 0)])
		root.add_child(cross_h)
		var cross_v := Line2D.new()
		cross_v.width = 2.0
		cross_v.default_color = Color(0.65, 0.94, 1.0, 0.54)
		cross_v.points = PackedVector2Array([Vector2(0, -28), Vector2(0, 28)])
		root.add_child(cross_v)
		var label := _make_label(Vector2(-34, 57), Vector2(68, 28), 14, Color("#bceeff"))
		label.text = "NODE %s" % char(65 + pad_index)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(label)
		pad_nodes.append({"root": root, "outer": outer, "core": core, "label": label})


func _clear_pads() -> void:
	for pad in pad_nodes:
		var root := pad.get("root") as Node
		if root and is_instance_valid(root):
			root.queue_free()
	pad_nodes.clear()
	current_pad_positions.clear()


func _make_subject(color: Color, caption: String, is_echo: bool) -> Node2D:
	var subject := Node2D.new()
	subject.modulate = color
	var shadow := Polygon2D.new()
	shadow.position = Vector2(0, 22)
	shadow.scale = Vector2(1.4, 0.42)
	shadow.polygon = _circle_points(17.0, 24)
	shadow.color = Color(0, 0, 0, 0.46)
	subject.add_child(shadow)
	var legs := Polygon2D.new()
	legs.polygon = PackedVector2Array([Vector2(-12, 9), Vector2(-2, 9), Vector2(-3, 25), Vector2(-13, 25), Vector2(2, 9), Vector2(12, 9), Vector2(13, 25), Vector2(3, 25)])
	legs.color = Color("#182538")
	subject.add_child(legs)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-18, -22), Vector2(18, -22), Vector2(16, 12), Vector2(-16, 12)])
	body.color = Color("#335ea8") if not is_echo else Color("#a7eaff")
	subject.add_child(body)
	var shirt := Polygon2D.new()
	shirt.polygon = PackedVector2Array([Vector2(-5, -22), Vector2(5, -22), Vector2(4, 4), Vector2(-4, 4)])
	shirt.color = Color("#e7e9df")
	subject.add_child(shirt)
	var tie := Polygon2D.new()
	tie.polygon = PackedVector2Array([Vector2(-3, -18), Vector2(3, -18), Vector2(5, 3), Vector2(0, 8), Vector2(-5, 3)])
	tie.color = Color("#ee4d61")
	subject.add_child(tie)
	var head := Polygon2D.new()
	head.position = Vector2(0, -34)
	head.polygon = PackedVector2Array([Vector2(-13, -13), Vector2(13, -13), Vector2(13, 13), Vector2(-13, 13)])
	head.color = Color("#e9cfaa")
	subject.add_child(head)
	var hair := Polygon2D.new()
	hair.position = Vector2(0, -34)
	hair.polygon = PackedVector2Array([Vector2(-13, -13), Vector2(13, -13), Vector2(13, -7), Vector2(-13, -7)])
	hair.color = Color("#25262c")
	subject.add_child(hair)
	var label := _make_label(Vector2(-50, 31), Vector2(100, 24), 12, Color("#d8f8ff"))
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subject.add_child(label)
	return subject


func _create_passport() -> Node2D:
	var root := Node2D.new()
	root.name = "QuantumPassport"
	var panel := PanelContainer.new()
	panel.position = Vector2(-74, -48)
	panel.size = Vector2(148, 96)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#e2c765"), Color(0.08, 0.14, 0.25, 0.98), 4))
	root.add_child(panel)
	var content := Control.new()
	panel.add_child(content)
	var emblem := _make_label(Vector2(10, 8), Vector2(128, 34), 23, Color("#e2c765"))
	emblem.text = "CIVIC"
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(emblem)
	var passport_label := _make_label(Vector2(10, 47), Vector2(128, 26), 13, Color("#bdeaf0"))
	passport_label.text = "PASSPORT / SUBJECT ?"
	passport_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(passport_label)
	return root


func _create_result_panel() -> void:
	result_panel = PanelContainer.new()
	result_panel.position = Vector2(330, 228)
	result_panel.size = Vector2(620, 260)
	result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_panel.add_theme_stylebox_override("panel", _panel_style(Color("#b591ff"), Color(0.015, 0.025, 0.09, 0.97), 5))
	frame.add_child(result_panel)
	var content := Control.new()
	result_panel.add_child(content)
	result_title = _make_label(Vector2(28, 31), Vector2(564, 68), 31, Color("#d9fdff"))
	result_title.text = "IDENTITY RECONCILED"
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(result_title)
	result_subtitle = _make_label(Vector2(44, 110), Vector2(532, 106), 17, Color("#91f1d3"))
	result_subtitle.text = "THREE OBSERVATIONS ACCEPTED\nONE CITIZEN REGISTERED\nRECONCILIATION POSTPONED"
	result_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(result_subtitle)
	result_panel.visible = false


func _create_audio() -> void:
	if hum_audio:
		return
	hum_audio = AudioStreamPlayer.new()
	hum_audio.stream = _make_hum()
	hum_audio.volume_db = -21.0
	add_child(hum_audio)
	record_audio = AudioStreamPlayer.new()
	record_audio.stream = _make_tone(525.0, 0.16, 0.03)
	record_audio.volume_db = -9.0
	add_child(record_audio)
	error_audio = AudioStreamPlayer.new()
	error_audio.stream = _make_tone(112.0, 0.22, 0.31)
	error_audio.volume_db = -7.0
	add_child(error_audio)
	phase_audio = AudioStreamPlayer.new()
	phase_audio.stream = _make_tone(735.0, 0.34, 0.02)
	phase_audio.volume_db = -9.0
	add_child(phase_audio)
	collapse_audio = AudioStreamPlayer.new()
	collapse_audio.stream = _make_tone(58.0, 0.72, 0.18)
	collapse_audio.volume_db = -5.0
	add_child(collapse_audio)


func _make_hum() -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(1.2 * sample_rate)
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for i in range(sample_count):
		var time := float(i) / float(sample_rate)
		var wave := sin(TAU * 43.0 * time) * 0.38 + sin(TAU * 86.0 * time) * 0.13
		wave += sin(TAU * 217.0 * time) * (0.035 + sin(TAU * 0.83 * time) * 0.018)
		bytes[i] = clampi(int(128.0 + wave * 96.0), 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = bytes
	return stream


func _make_tone(frequency: float, duration: float, noise_amount: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := maxi(1, int(duration * sample_rate))
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for i in range(sample_count):
		var time := float(i) / float(sample_rate)
		var envelope := pow(1.0 - float(i) / float(sample_count), 1.55)
		var wave := sin(TAU * frequency * time) * (1.0 - noise_amount)
		wave += sin(TAU * frequency * 1.51 * time) * 0.22
		var noise := sin(float(i * 7919 % 997) * 0.013) * noise_amount
		bytes[i] = clampi(int(128.0 + (wave + noise) * envelope * 88.0), 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream


func _make_label(position_value: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position_value
	label.size = size_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _panel_style(border_color: Color, background_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	return style


func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _ellipse_points(center: Vector2, radii: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var angle := TAU * float(i % segments) / float(segments)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


func _layout_frame() -> void:
	if root_control and frame:
		frame.position = (root_control.size - VIEW_SIZE) * 0.5
