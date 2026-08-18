extends Node

signal finished

const VIEW_SIZE := Vector2(1280, 720)
const BACKGROUND_PATH := "res://assets/sequences/opening_drive_sunset_v2.png"
const CAR_PATH := "res://assets/sequences/opening_drive_car_v1.png"
const CEREMONY_PATH := "res://assets/sequences/opening_drive_pothole_ceremony_v1.png"
const MOTORCADE_PATH := "res://assets/sequences/opening_drive_motorcade_v1.png"
const TOLLBOOTH_PATH := "res://assets/sequences/opening_drive_tollbooth_v1.png"
const CHECKPOINT_PATH := "res://assets/sequences/opening_drive_checkpoint_v1.png"
const MUSIC_PATH := "res://assets/audio/civic_nightmare_opening_drive.ogg"
const MUSIC_DURATION := 88.0
const SEQUENCE_DURATION := 89.8
const DRIVE_START := 6.2
const ARRIVAL_START := 78.0
const ROAD_HORIZON_Y := 344.0
const ROAD_BOTTOM_Y := 735.0
const CAR_LANE_HALF_WIDTH := 290.0
const CAR_Y := 580.0

const SIGN_SCHEDULE := [
	{"time": 12.0, "side": -1.0, "text": "DISTRICT\n12 km", "color": Color("#245f8c")},
	{"time": 31.0, "side": -1.0, "text": "FAST LANE\nFORM A", "color": Color("#376f4b")},
	{"time": 48.0, "side": -1.0, "text": "ROAD WORK\nCOMPLETED 1987", "color": Color("#8b6927")},
	{"time": 68.0, "side": -1.0, "text": "WELCOME\nAPPOINTMENT ONLY", "color": Color("#a34938")},
]

const HAZARD_SCHEDULE := [
	{"time": 16.0, "lane": -0.42},
	{"time": 34.0, "lane": -0.08},
	{"time": 48.5, "lane": 0.52},
	{"time": 70.0, "lane": -0.30},
]

const SET_PIECE_SCHEDULE := [
	{"time": 19.0, "id": "ceremony"},
	{"time": 38.0, "id": "motorcade"},
	{"time": 56.0, "id": "tollbooth"},
	{"time": 77.0, "id": "checkpoint"},
]

const PART_LOSS_TIMES := [32.0, 54.0, 71.0]

var host: Node
var player: CharacterBody2D
var active := true
var elapsed := 0.0
var road_scroll := 0.0
var car_x := 640.0
var car_velocity_x := 0.0
var shake_strength := 0.0
var next_sign_index := 0
var next_hazard_index := 0
var next_part_index := 0
var next_set_piece_index := 0
var smoke_timer := 0.0
var engine_dead := false
var event_message_until := 0.0
var receipt_attached := false

var layer: CanvasLayer
var root_control: Control
var frame: Control
var background: TextureRect
var road_root: Node2D
var road_surface: Polygon2D
var institutional_lane: Polygon2D
var scenery_root: Node2D
var set_piece_root: Node2D
var smoke_root: Node2D
var car_root: Node2D
var car_sprite: Sprite2D
var debris_root: Node2D
var speed_label: Label
var status_label: Label
var control_hint: Label
var arrival_panel: PanelContainer
var event_panel: PanelContainer
var event_label: Label
var receipt_trail: Line2D
var music_player: AudioStreamPlayer
var engine_player: AudioStreamPlayer
var clunk_player: AudioStreamPlayer

var road_markers: Array[Polygon2D] = []
var shoulder_segments: Array[Polygon2D] = []
var edge_streaks: Array[Polygon2D] = []
var signs: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var smoke_puffs: Array[Dictionary] = []
var debris: Array[Dictionary] = []
var set_pieces: Array[Dictionary] = []
var spawned_set_piece_ids: Array[String] = []


func setup(owner: Node, player_node: CharacterBody2D) -> void:
	host = owner
	player = player_node
	player.set_physics_process(false)
	_create_sequence()
	_create_audio()
	active = true
	if music_player.stream:
		music_player.play()
	engine_player.play()


func process_frame(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	var frame_delta := minf(delta, 0.1)
	_update_audio()
	_update_car(frame_delta)
	_update_road(frame_delta)
	_update_schedule()
	_update_set_pieces(frame_delta)
	_update_signs(frame_delta)
	_update_hazards(frame_delta)
	_update_receipt()
	_update_smoke(frame_delta)
	_update_debris(frame_delta)
	_update_hud()
	if elapsed >= MUSIC_DURATION and not engine_dead:
		_begin_engine_death()
	if elapsed >= SEQUENCE_DURATION:
		_finish()


func get_music_asset_path() -> String:
	return MUSIC_PATH


func get_sequence_duration() -> float:
	return SEQUENCE_DURATION


func get_set_piece_asset_paths() -> PackedStringArray:
	return PackedStringArray([CEREMONY_PATH, MOTORCADE_PATH, TOLLBOOTH_PATH, CHECKPOINT_PATH])


func _create_sequence() -> void:
	layer = CanvasLayer.new()
	layer.name = "OpeningDriveLayer"
	layer.layer = 104
	host.add_child(layer)

	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root_control)

	var blackout := ColorRect.new()
	blackout.set_anchors_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color("#080813")
	root_control.add_child(blackout)

	frame = Control.new()
	frame.size = VIEW_SIZE
	frame.clip_contents = true
	root_control.add_child(frame)
	root_control.resized.connect(_layout_frame)

	background = TextureRect.new()
	background.position = Vector2(-14, -8)
	background.size = VIEW_SIZE + Vector2(28, 16)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.texture = load(BACKGROUND_PATH) if ResourceLoader.exists(BACKGROUND_PATH) else null
	frame.add_child(background)

	road_root = Node2D.new()
	road_root.name = "AnimatedRoad"
	frame.add_child(road_root)
	_create_road_motion()

	scenery_root = Node2D.new()
	scenery_root.name = "RoadsideProcedure"
	frame.add_child(scenery_root)

	set_piece_root = Node2D.new()
	set_piece_root.name = "CivicRoadSetPieces"
	frame.add_child(set_piece_root)

	smoke_root = Node2D.new()
	smoke_root.name = "ExhaustSmoke"
	frame.add_child(smoke_root)

	car_root = Node2D.new()
	car_root.name = "CitizenVehicle"
	car_root.position = Vector2(car_x, CAR_Y)
	frame.add_child(car_root)
	car_sprite = Sprite2D.new()
	car_sprite.name = "BatteredEconomyCar"
	car_sprite.texture = load(CAR_PATH) if ResourceLoader.exists(CAR_PATH) else null
	car_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	car_sprite.scale = Vector2.ONE * 0.27
	car_sprite.position = Vector2(0, -8)
	car_root.add_child(car_sprite)

	debris_root = Node2D.new()
	debris_root.name = "VehicleIntegrity"
	frame.add_child(debris_root)
	receipt_trail = Line2D.new()
	receipt_trail.name = "AdministrativeReceiptTrail"
	receipt_trail.width = 22.0
	receipt_trail.default_color = Color("#f6efd5")
	receipt_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	receipt_trail.visible = false
	debris_root.add_child(receipt_trail)

	_create_hud()
	_create_scanlines()
	_layout_frame()


func _create_road_motion() -> void:
	road_surface = Polygon2D.new()
	road_surface.name = "CurvingRoadSurface"
	road_surface.color = Color(0.025, 0.025, 0.065, 0.82)
	road_root.add_child(road_surface)
	for shoulder_index in range(18):
		for shoulder_side in [-1.0, 1.0]:
			var shoulder := Polygon2D.new()
			shoulder.color = Color("#fff0c4") if shoulder_index % 2 == 0 else Color("#ef4e64")
			shoulder.set_meta("offset", float(shoulder_index) / 18.0)
			shoulder.set_meta("side", shoulder_side)
			road_root.add_child(shoulder)
			shoulder_segments.append(shoulder)
	for marker_index in range(12):
		for lane_side in [-1.0, 1.0]:
			var marker := Polygon2D.new()
			marker.color = Color(1.0, 0.88, 0.52, 0.88)
			marker.set_meta("offset", float(marker_index) / 12.0)
			marker.set_meta("side", lane_side)
			road_root.add_child(marker)
			road_markers.append(marker)
	for streak_index in range(14):
		for edge_side in [-1.0, 1.0]:
			var streak := Polygon2D.new()
			streak.color = Color(0.45, 0.86, 0.95, 0.42)
			streak.set_meta("offset", float(streak_index) / 14.0)
			streak.set_meta("side", edge_side)
			road_root.add_child(streak)
			edge_streaks.append(streak)
	institutional_lane = Polygon2D.new()
	institutional_lane.name = "TemporaryInstitutionalLane"
	institutional_lane.color = Color(0.96, 0.70, 0.16, 0.0)
	institutional_lane.visible = false
	road_root.add_child(institutional_lane)


func _create_hud() -> void:
	var top_bar := PanelContainer.new()
	top_bar.position = Vector2(18, 16)
	top_bar.size = Vector2(1244, 56)
	top_bar.add_theme_stylebox_override("panel", _panel_style(Color("#efb84f"), Color(0.02, 0.035, 0.08, 0.88), 3))
	frame.add_child(top_bar)
	var title := _make_label(Vector2(20, 9), Vector2(390, 38), 20, Color("#ffd46a"))
	title.text = "CIVIC NIGHTMARE // APPROACH VECTOR"
	top_bar.add_child(title)
	speed_label = _make_label(Vector2(483, 6), Vector2(278, 43), 27, Color("#75e6f2"))
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(speed_label)
	status_label = _make_label(Vector2(790, 10), Vector2(430, 36), 16, Color("#f2e8c1"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_child(status_label)

	control_hint = _make_label(Vector2(500, 670), Vector2(280, 34), 17, Color("#fff1ae"))
	control_hint.text = "←  →  STEER"
	control_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(control_hint)

	event_panel = PanelContainer.new()
	event_panel.name = "RoadEventNotice"
	event_panel.position = Vector2(398, 92)
	event_panel.size = Vector2(484, 76)
	event_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f0c35b"), Color(0.02, 0.035, 0.07, 0.94), 3))
	frame.add_child(event_panel)
	event_label = _make_label(Vector2(12, 8), Vector2(460, 60), 19, Color("#ffe17a"))
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	event_panel.add_child(event_label)
	event_panel.visible = false

	arrival_panel = PanelContainer.new()
	arrival_panel.position = Vector2(376, 272)
	arrival_panel.size = Vector2(528, 122)
	arrival_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f0c35b"), Color(0.02, 0.035, 0.07, 0.95), 4))
	frame.add_child(arrival_panel)
	var arrival_label := _make_label(Vector2(18, 20), Vector2(492, 80), 25, Color("#ffe17a"))
	arrival_label.text = "ADMINISTRATIVE DISTRICT\nARRIVAL REGISTERED"
	arrival_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrival_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrival_panel.add_child(arrival_label)
	arrival_panel.visible = false


func _create_scanlines() -> void:
	var scanlines := ColorRect.new()
	scanlines.size = VIEW_SIZE
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	float line = mod(FRAGCOORD.y, 4.0);
	float scan = step(2.0, line) * 0.055;
	float vignette = smoothstep(0.74, 1.18, length(SCREEN_UV - vec2(0.5)) * 1.45);
	COLOR = vec4(0.0, 0.01, 0.035, scan + vignette * 0.18);
}
"""
	material.shader = shader
	scanlines.material = material
	frame.add_child(scanlines)


func _create_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "OpeningDriveMusic"
	music_player.volume_db = -4.0
	if ResourceLoader.exists(MUSIC_PATH):
		music_player.stream = load(MUSIC_PATH)
	add_child(music_player)

	engine_player = AudioStreamPlayer.new()
	engine_player.name = "EconomyEngine"
	engine_player.stream = _make_engine_stream()
	engine_player.volume_db = -18.0
	add_child(engine_player)

	clunk_player = AudioStreamPlayer.new()
	clunk_player.name = "VehicleClunk"
	clunk_player.stream = _make_clunk_stream()
	clunk_player.volume_db = -9.0
	add_child(clunk_player)


func _update_audio() -> void:
	if not engine_player or engine_dead:
		return
	if elapsed < DRIVE_START:
		var attempt_on := fmod(elapsed, 1.45) < 0.83
		engine_player.volume_db = -11.0 if attempt_on else -45.0
		engine_player.pitch_scale = 0.66 + sin(elapsed * 7.5) * 0.08
	elif elapsed < ARRIVAL_START:
		engine_player.volume_db = -19.0
		engine_player.pitch_scale = 0.94 + sin(elapsed * 5.0) * 0.035
	else:
		engine_player.volume_db = -18.0
		engine_player.pitch_scale = lerpf(0.94, 0.72, clampf((elapsed - ARRIVAL_START) / 10.0, 0.0, 1.0))


func _update_car(delta: float) -> void:
	var drive_active := elapsed >= DRIVE_START and not engine_dead
	var steer := Input.get_axis("ui_left", "ui_right") if drive_active else 0.0
	var target_velocity := steer * 360.0
	car_velocity_x = move_toward(car_velocity_x, target_velocity, delta * (900.0 if absf(steer) > 0.01 else 1200.0))
	var lane_center := _road_center(0.87)
	var lane_min := lane_center - CAR_LANE_HALF_WIDTH
	var lane_max := lane_center + CAR_LANE_HALF_WIDTH
	car_x = clampf(car_x + car_velocity_x * delta, lane_min, lane_max)
	if car_x <= lane_min + 0.5 or car_x >= lane_max - 0.5:
		car_velocity_x *= -0.22
		shake_strength = maxf(shake_strength, 0.32)

	shake_strength = maxf(0.0, shake_strength - delta * 1.8)
	var startup_shake := (1.0 - clampf(elapsed / DRIVE_START, 0.0, 1.0)) * 7.0
	var vibration := 1.5 + clampf((elapsed - 28.0) / 48.0, 0.0, 1.0) * 2.4
	var shake_x := sin(elapsed * 31.0) * (startup_shake + shake_strength * 9.0)
	var shake_y := sin(elapsed * 23.0) * (startup_shake * 0.45 + vibration + shake_strength * 5.0)
	car_root.position = Vector2(car_x + shake_x, CAR_Y + shake_y)
	car_root.rotation = steer * 0.045 + sin(elapsed * 9.0) * 0.009 + shake_strength * sin(elapsed * 37.0) * 0.035
	background.position.x = -14.0 - (car_x - lane_center) * 0.014


func _update_road(delta: float) -> void:
	var drive_amount := clampf((elapsed - DRIVE_START) / 4.0, 0.0, 1.0)
	var arrival_slowdown := 1.0 - clampf((elapsed - MUSIC_DURATION) / 1.2, 0.0, 1.0)
	road_scroll = fposmod(road_scroll + delta * lerpf(0.0, 0.54, drive_amount) * arrival_slowdown, 1.0)
	_update_road_surface()
	for shoulder in shoulder_segments:
		var progress := fposmod(road_scroll + float(shoulder.get_meta("offset")), 1.0)
		shoulder.visible = drive_amount > 0.04 and progress < 0.955
		if not shoulder.visible:
			continue
		var tail := minf(progress + 0.038 + progress * 0.026, 0.985)
		var side := float(shoulder.get_meta("side"))
		var center0 := _road_center(progress)
		var center1 := _road_center(tail)
		var inner0 := center0 + side * _road_half_width(progress)
		var inner1 := center1 + side * _road_half_width(tail)
		var outer0 := center0 + side * (_road_half_width(progress) + 4.0 + progress * 14.0)
		var outer1 := center1 + side * (_road_half_width(tail) + 5.0 + tail * 17.0)
		shoulder.polygon = PackedVector2Array([
			Vector2(inner0, _road_y(progress)), Vector2(outer0, _road_y(progress)),
			Vector2(outer1, _road_y(tail)), Vector2(inner1, _road_y(tail)),
		])
	for marker in road_markers:
		var progress := fposmod(road_scroll + float(marker.get_meta("offset")), 1.0)
		marker.visible = drive_amount > 0.05 and progress < 0.94
		if not marker.visible:
			continue
		var tail := minf(progress + 0.055 + progress * 0.035, 0.985)
		var side := float(marker.get_meta("side"))
		var p0 := Vector2(_road_center(progress) + side * _road_half_width(progress) * 0.33, _road_y(progress))
		var p1 := Vector2(_road_center(tail) + side * _road_half_width(tail) * 0.33, _road_y(tail))
		var width0 := 1.0 + progress * 6.0
		var width1 := 1.0 + tail * 9.0
		marker.polygon = PackedVector2Array([
			p0 + Vector2(-width0, 0), p0 + Vector2(width0, 0),
			p1 + Vector2(width1, 0), p1 + Vector2(-width1, 0),
		])
	for streak in edge_streaks:
		var progress := fposmod(road_scroll * 1.24 + float(streak.get_meta("offset")), 1.0)
		streak.visible = drive_amount > 0.2 and progress < 0.91
		if not streak.visible:
			continue
		var tail := minf(progress + 0.035 + progress * 0.055, 0.97)
		var side := float(streak.get_meta("side"))
		var p0 := Vector2(_road_center(progress) + side * (_road_half_width(progress) + 18.0), _road_y(progress))
		var p1 := Vector2(_road_center(tail) + side * (_road_half_width(tail) + 28.0), _road_y(tail))
		var width := 1.0 + progress * 5.0
		streak.polygon = PackedVector2Array([
			p0 + Vector2(-width, 0), p0 + Vector2(width, 0),
			p1 + Vector2(width * 1.6, 0), p1 + Vector2(-width * 1.6, 0),
		])


func _update_schedule() -> void:
	while next_sign_index < SIGN_SCHEDULE.size() and elapsed >= float(SIGN_SCHEDULE[next_sign_index]["time"]):
		_spawn_sign(SIGN_SCHEDULE[next_sign_index])
		next_sign_index += 1
	while next_hazard_index < HAZARD_SCHEDULE.size() and elapsed >= float(HAZARD_SCHEDULE[next_hazard_index]["time"]):
		_spawn_hazard(float(HAZARD_SCHEDULE[next_hazard_index]["lane"]))
		next_hazard_index += 1
	while next_part_index < PART_LOSS_TIMES.size() and elapsed >= float(PART_LOSS_TIMES[next_part_index]):
		_spawn_debris(car_root.position + Vector2(-95.0 + next_part_index * 72.0, 52.0), next_part_index)
		clunk_player.play()
		shake_strength = maxf(shake_strength, 0.7)
		next_part_index += 1
	while next_set_piece_index < SET_PIECE_SCHEDULE.size() and elapsed >= float(SET_PIECE_SCHEDULE[next_set_piece_index]["time"]):
		_spawn_set_piece(str(SET_PIECE_SCHEDULE[next_set_piece_index]["id"]))
		next_set_piece_index += 1


func _spawn_set_piece(set_piece_id: String) -> void:
	var event := {"id": set_piece_id, "age": 0.0, "phase": 0, "hit": false}
	var node := Node2D.new()
	node.name = set_piece_id.capitalize().replace(" ", "")
	set_piece_root.add_child(node)
	event["node"] = node
	match set_piece_id:
		"ceremony":
			var ceremony := Sprite2D.new()
			ceremony.name = "PotholeInauguration"
			ceremony.texture = load(CEREMONY_PATH) if ResourceLoader.exists(CEREMONY_PATH) else null
			ceremony.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			node.add_child(ceremony)
		"motorcade":
			var motorcade := Sprite2D.new()
			motorcade.name = "InstitutionalMotorcade"
			motorcade.texture = load(MOTORCADE_PATH) if ResourceLoader.exists(MOTORCADE_PATH) else null
			motorcade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			node.add_child(motorcade)
		"tollbooth":
			var tollbooth := Sprite2D.new()
			tollbooth.name = "MobileAdministrativeTollbooth"
			tollbooth.texture = load(TOLLBOOTH_PATH) if ResourceLoader.exists(TOLLBOOTH_PATH) else null
			tollbooth.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			node.add_child(tollbooth)
			_create_tollbooth_indicators(node, event)
		"checkpoint":
			_create_checkpoint(node, event)
	spawned_set_piece_ids.append(set_piece_id)
	set_pieces.append(event)


func _update_set_pieces(delta: float) -> void:
	for index in range(set_pieces.size() - 1, -1, -1):
		var event: Dictionary = set_pieces[index]
		event["age"] = float(event.get("age", 0.0)) + delta
		match str(event.get("id", "")):
			"ceremony":
				_update_ceremony(event)
			"motorcade":
				_update_motorcade(event)
			"tollbooth":
				_update_tollbooth(event)
			"checkpoint":
				_update_checkpoint(event)
		if bool(event.get("finished", false)):
			var node: Node2D = event.get("node")
			if node:
				node.queue_free()
			set_pieces.remove_at(index)


func _update_ceremony(event: Dictionary) -> void:
	var age := float(event.get("age", 0.0))
	var progress := clampf(0.012 + age / 10.8, 0.012, 1.08)
	var node: Node2D = event.get("node")
	node.position = Vector2(_road_center(progress) + _road_half_width(progress) * 0.24, _road_y(progress))
	node.scale = Vector2.ONE * (0.025 + pow(progress, 1.55) * 0.36)
	if age >= 1.3 and int(event.get("phase", 0)) == 0:
		event["phase"] = 1
		_show_event_message("INFRASTRUCTURE\nSUCCESSFULLY COMPLETED", Color("#f0c35b"), 2.8)
	if progress > 0.78 and progress < 0.98 and not bool(event.get("hit", false)) and absf(node.position.x - car_x) < 150.0:
		event["hit"] = true
		shake_strength = 1.1
		clunk_player.play()
		_spawn_debris(car_root.position + Vector2(0, 70), 11)
	if progress >= 1.06:
		event["finished"] = true


func _update_motorcade(event: Dictionary) -> void:
	var age := float(event.get("age", 0.0))
	var travel := clampf(age / 8.5, 0.0, 1.0)
	var progress := lerpf(0.95, 0.08, ease(travel, -1.2))
	var node: Node2D = event.get("node")
	node.position = Vector2(_road_center(progress) + _road_half_width(progress) * 0.42, _road_y(progress))
	var scale_value := lerpf(0.23, 0.045, travel)
	node.scale = Vector2.ONE * scale_value
	_update_institutional_lane(age)
	var phase := int(event.get("phase", 0))
	if age >= 0.45 and phase == 0:
		event["phase"] = 1
		_show_event_message("EQUAL ACCESS\nTEMPORARILY SUSPENDED", Color("#70d6ff"), 2.5)
	elif age >= 6.4 and phase == 1:
		event["phase"] = 2
		_show_event_message("EQUAL ACCESS RESTORED", Color("#8de08d"), 2.3)
		_spawn_debris(Vector2(_road_center(0.56) + _road_half_width(0.56) * 0.42, _road_y(0.56)), 12)
		clunk_player.play()
	if age >= 8.7:
		institutional_lane.visible = false
		event["finished"] = true


func _update_institutional_lane(age: float) -> void:
	var visibility := clampf(age / 0.6, 0.0, 1.0) * (1.0 - clampf((age - 6.1) / 1.5, 0.0, 1.0))
	institutional_lane.visible = visibility > 0.01
	institutional_lane.color.a = visibility * 0.31
	var points := PackedVector2Array()
	for sample_index in range(15):
		var progress := float(sample_index) / 14.0
		var center := _road_center(progress) + _road_half_width(progress) * 0.42
		var width := 3.0 + _road_half_width(progress) * 0.25
		points.append(Vector2(center - width, _road_y(progress)))
	for sample_index in range(14, -1, -1):
		var progress := float(sample_index) / 14.0
		var center := _road_center(progress) + _road_half_width(progress) * 0.42
		var width := 3.0 + _road_half_width(progress) * 0.25
		points.append(Vector2(center + width, _road_y(progress)))
	institutional_lane.polygon = points


func _create_tollbooth_indicators(node: Node2D, event: Dictionary) -> void:
	var indicators: Array[Polygon2D] = []
	var open_marks: Array[Polygon2D] = []
	var closed_marks: Array[Node2D] = []
	for lane_index in range(3):
		var indicator := Polygon2D.new()
		indicator.name = "LaneIndicator%d" % (lane_index + 1)
		indicator.polygon = PackedVector2Array([Vector2(-58, -37), Vector2(58, -37), Vector2(58, 37), Vector2(-58, 37)])
		indicator.position = Vector2(float(lane_index - 1) * 480.0, -135.0)
		node.add_child(indicator)
		indicators.append(indicator)
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([
			Vector2(-9, -25), Vector2(9, -25), Vector2(9, -5), Vector2(28, -5),
			Vector2(0, 27), Vector2(-28, -5), Vector2(-9, -5),
		])
		arrow.color = Color("#ecf7df")
		indicator.add_child(arrow)
		open_marks.append(arrow)
		var cross := Node2D.new()
		for slope in [-1.0, 1.0]:
			var stroke := Line2D.new()
			stroke.width = 10.0
			stroke.default_color = Color("#fff0df")
			stroke.add_point(Vector2(-23, slope * -20.0))
			stroke.add_point(Vector2(23, slope * 20.0))
			cross.add_child(stroke)
		indicator.add_child(cross)
		closed_marks.append(cross)
	event["indicators"] = indicators
	event["open_marks"] = open_marks
	event["closed_marks"] = closed_marks


func _update_tollbooth(event: Dictionary) -> void:
	var age := float(event.get("age", 0.0))
	var progress := clampf(0.018 + age / 12.7, 0.018, 0.96)
	var node: Node2D = event.get("node")
	node.position = Vector2(_road_center(progress), _road_y(progress) - 32.0 * progress)
	node.scale = Vector2.ONE * (0.028 + pow(progress, 1.48) * 0.39)
	var phase := int(event.get("phase", 0))
	if age >= 0.8 and phase == 0:
		event["phase"] = 1
		_show_event_message("PRIORITY PROCESSING\nLANE 1 OPEN", Color("#8de08d"), 2.4)
	elif age >= 5.0 and phase == 1:
		event["phase"] = 2
		_show_event_message("STATUS CORRECTED\nLANE 3 OPEN", Color("#ef6b5b"), 2.7)
		clunk_player.play()
	var open_lane := 0 if age < 5.0 else 2
	var indicators: Array = event.get("indicators", [])
	var open_marks: Array = event.get("open_marks", [])
	var closed_marks: Array = event.get("closed_marks", [])
	for lane_index in range(indicators.size()):
		(indicators[lane_index] as Polygon2D).color = Color(0.20, 0.95, 0.48, 0.92) if lane_index == open_lane else Color(0.95, 0.16, 0.12, 0.88)
		(open_marks[lane_index] as Polygon2D).visible = lane_index == open_lane
		(closed_marks[lane_index] as Node2D).visible = lane_index != open_lane
	if progress > 0.76 and progress < 0.93 and not bool(event.get("hit", false)):
		var lane_center := _road_center(0.87)
		var car_lane := int(clampf(round((car_x - lane_center) / 185.0) + 1.0, 0.0, 2.0))
		if car_lane != open_lane:
			event["hit"] = true
			shake_strength = 0.9
			clunk_player.play()
			_spawn_debris(car_root.position + Vector2(24, 58), 13)
	if progress >= 0.89 and not receipt_attached:
		receipt_attached = true
		receipt_trail.visible = true
		_show_event_message("RECEIPT ISSUED", Color("#f6efd5"), 2.1)
	if progress >= 0.95:
		event["finished"] = true


func _create_checkpoint(node: Node2D, event: Dictionary) -> void:
	var checkpoint := Sprite2D.new()
	checkpoint.name = "DecayedAdministrativeCheckpoint"
	checkpoint.texture = load(CHECKPOINT_PATH) if ResourceLoader.exists(CHECKPOINT_PATH) else null
	checkpoint.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	node.add_child(checkpoint)
	var scan_beam := Polygon2D.new()
	scan_beam.name = "VehicleScanBeam"
	scan_beam.polygon = PackedVector2Array([Vector2(-385, -95), Vector2(385, -95), Vector2(385, -67), Vector2(-385, -67)])
	scan_beam.color = Color(0.25, 0.88, 1.0, 0.35)
	node.add_child(scan_beam)
	var barrier_pivot := Node2D.new()
	barrier_pivot.name = "RustFailedBarrierPivot"
	barrier_pivot.position = Vector2(-400, 54)
	node.add_child(barrier_pivot)
	var barrier := Line2D.new()
	barrier.name = "RustFailedBarrier"
	barrier.width = 34.0
	barrier.default_color = Color("#d75143")
	barrier.add_point(Vector2.ZERO)
	barrier.add_point(Vector2(800, 0))
	barrier_pivot.add_child(barrier)
	for stripe_index in range(7):
		var stripe := Polygon2D.new()
		stripe.polygon = PackedVector2Array([Vector2(-22, -18), Vector2(22, -18), Vector2(12, 18), Vector2(-32, 18)])
		stripe.position = Vector2(75.0 + stripe_index * 108.0, 0)
		stripe.color = Color("#eee7ce")
		barrier_pivot.add_child(stripe)
	event["barrier_pivot"] = barrier_pivot
	event["scan_beam"] = scan_beam


func _update_checkpoint(event: Dictionary) -> void:
	var age := float(event.get("age", 0.0))
	var progress := clampf(0.025 + age / 13.5, 0.025, 0.82)
	var node: Node2D = event.get("node")
	node.position = Vector2(_road_center(progress), _road_y(progress) - 52.0 * progress)
	node.scale = Vector2.ONE * (0.045 + pow(progress, 1.25) * 0.57)
	var scan_beam: Polygon2D = event.get("scan_beam")
	scan_beam.position.y = -90.0 + fposmod(age * 105.0, 170.0)
	scan_beam.modulate.a = 0.55 + sin(age * 11.0) * 0.22
	var phase := int(event.get("phase", 0))
	if age >= 3.6 and phase == 0:
		event["phase"] = 1
		_show_event_message("VEHICLE NOT RECOGNIZED", Color("#ff625a"), 3.2)
	elif age >= 8.0 and phase == 1:
		event["phase"] = 2
		clunk_player.play()
		shake_strength = 1.25
		for spark_index in range(5):
			_spawn_debris(Vector2(_road_center(0.72) - 210.0 + spark_index * 95.0, _road_y(0.72)), 20 + spark_index)
	elif age >= 8.55 and phase == 2:
		event["phase"] = 3
		_show_event_message("ACCESS GRANTED", Color("#8de08d"), 2.8)
	var barrier_pivot: Node2D = event.get("barrier_pivot")
	barrier_pivot.rotation = ease(clampf((age - 8.0) / 1.15, 0.0, 1.0), 1.7) * 1.42
	if age >= 12.2:
		event["finished"] = true


func _show_event_message(message: String, border_color: Color, duration: float) -> void:
	event_label.text = message
	event_panel.add_theme_stylebox_override("panel", _panel_style(border_color, Color(0.02, 0.035, 0.07, 0.94), 3))
	event_panel.visible = true
	event_message_until = elapsed + duration


func _update_receipt() -> void:
	if not receipt_trail or not receipt_attached:
		return
	if elapsed >= 79.0:
		receipt_trail.modulate.a = maxf(0.0, 1.0 - (elapsed - 79.0) / 2.0)
		if receipt_trail.modulate.a <= 0.01:
			receipt_trail.visible = false
		return
	var points := PackedVector2Array()
	var anchor := car_root.position + Vector2(12.0, 64.0)
	for point_index in range(7):
		var distance := float(point_index) * 30.0
		points.append(anchor + Vector2(sin(elapsed * 8.0 + point_index * 1.2) * (5.0 + point_index * 2.0), distance))
	receipt_trail.points = points


func _spawn_sign(data: Dictionary) -> void:
	var sign := Node2D.new()
	var post := Line2D.new()
	post.width = 7.0
	post.default_color = Color("#6b665c")
	post.add_point(Vector2(0, 24))
	post.add_point(Vector2(0, 104))
	sign.add_child(post)
	var panel := PanelContainer.new()
	panel.position = Vector2(-92, -42)
	panel.size = Vector2(184, 78)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#e4d9ab"), data.get("color", Color("#245f8c")), 4))
	sign.add_child(panel)
	var label := _make_label(Vector2(8, 6), Vector2(168, 66), 15, Color.WHITE)
	label.text = str(data.get("text", "PROCEDURE"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	scenery_root.add_child(sign)
	signs.append({"node": sign, "progress": 0.015, "side": float(data.get("side", 1.0))})


func _update_signs(delta: float) -> void:
	for index in range(signs.size() - 1, -1, -1):
		var entry: Dictionary = signs[index]
		var progress := float(entry.get("progress", 0.0)) + delta * (0.105 + float(entry.get("progress", 0.0)) * 0.10)
		entry["progress"] = progress
		var node: Node2D = entry.get("node")
		var side := float(entry.get("side", 1.0))
		node.position = Vector2(_road_center(progress) + side * (_road_half_width(progress) + 75.0 + progress * 90.0), _road_y(progress))
		node.scale = Vector2.ONE * (0.08 + pow(progress, 1.5) * 1.15)
		if progress > 1.04:
			node.queue_free()
			signs.remove_at(index)


func _spawn_hazard(lane: float) -> void:
	var hazard := Node2D.new()
	var rim := Polygon2D.new()
	rim.polygon = _ellipse_points(54.0, 18.0, 24)
	rim.color = Color("#9a7252")
	hazard.add_child(rim)
	var hole := Polygon2D.new()
	hole.polygon = _ellipse_points(45.0, 13.0, 24)
	hole.color = Color("#15131b")
	hazard.add_child(hole)
	scenery_root.add_child(hazard)
	hazards.append({"node": hazard, "progress": 0.01, "lane": lane, "hit": false})


func _update_hazards(delta: float) -> void:
	for index in range(hazards.size() - 1, -1, -1):
		var entry: Dictionary = hazards[index]
		var progress := float(entry.get("progress", 0.0)) + delta * (0.12 + float(entry.get("progress", 0.0)) * 0.12)
		entry["progress"] = progress
		var node: Node2D = entry.get("node")
		var lane := float(entry.get("lane", 0.0))
		node.position = Vector2(_road_center(progress) + lane * _road_half_width(progress) * 0.72, _road_y(progress))
		node.scale = Vector2.ONE * (0.03 + pow(progress, 1.65) * 1.3)
		if progress > 0.80 and progress < 0.98 and not bool(entry.get("hit", false)) and absf(node.position.x - car_x) < 82.0:
			entry["hit"] = true
			shake_strength = 1.0
			clunk_player.play()
			_spawn_debris(car_root.position + Vector2(0, 70), index + 4)
		if progress > 1.04:
			node.queue_free()
			hazards.remove_at(index)


func _update_smoke(delta: float) -> void:
	if elapsed >= DRIVE_START and not engine_dead:
		smoke_timer -= delta
		var interval := lerpf(0.24, 0.085, clampf((elapsed - 18.0) / 55.0, 0.0, 1.0))
		if smoke_timer <= 0.0:
			_spawn_smoke(false)
			smoke_timer = interval
	for index in range(smoke_puffs.size() - 1, -1, -1):
		var entry: Dictionary = smoke_puffs[index]
		var life := float(entry.get("life", 0.0)) + delta
		entry["life"] = life
		var node: Node2D = entry.get("node")
		node.position += (entry.get("velocity", Vector2.ZERO) as Vector2) * delta
		node.scale = Vector2.ONE * (0.65 + life * 1.45)
		node.modulate.a = maxf(0.0, 0.55 - life * 0.42)
		if life > 1.35:
			node.queue_free()
			smoke_puffs.remove_at(index)


func _spawn_smoke(final_burst: bool) -> void:
	var puff := Polygon2D.new()
	puff.polygon = _circle_points(11.0 if not final_burst else 17.0, 18)
	puff.color = Color(0.31, 0.30, 0.33, 0.72)
	puff.position = car_root.position + Vector2(63.0, 64.0)
	smoke_root.add_child(puff)
	var drift := Vector2(28.0 + sin(elapsed * 7.0) * 12.0, -42.0 if final_burst else -27.0)
	smoke_puffs.append({"node": puff, "velocity": drift, "life": 0.0})


func _spawn_debris(origin: Vector2, variant: int) -> void:
	var piece := Polygon2D.new()
	var width := 18.0 + float(variant % 3) * 7.0
	piece.polygon = PackedVector2Array([Vector2(-width, -5), Vector2(width, -4), Vector2(width * 0.8, 5), Vector2(-width * 0.7, 6)])
	piece.color = [Color("#a77a47"), Color("#6d8b91"), Color("#d1b27a")][variant % 3]
	piece.position = origin
	debris_root.add_child(piece)
	debris.append({
		"node": piece,
		"velocity": Vector2(-80.0 + float((variant * 67) % 160), 115.0 + float(variant % 4) * 28.0),
		"spin": -3.5 + float(variant % 5) * 1.4,
		"life": 0.0,
	})


func _update_debris(delta: float) -> void:
	for index in range(debris.size() - 1, -1, -1):
		var entry: Dictionary = debris[index]
		var node: Node2D = entry.get("node")
		var velocity: Vector2 = entry.get("velocity", Vector2.ZERO)
		velocity.y += 260.0 * delta
		entry["velocity"] = velocity
		entry["life"] = float(entry.get("life", 0.0)) + delta
		node.position += velocity * delta
		node.rotation += float(entry.get("spin", 0.0)) * delta
		node.modulate.a = maxf(0.0, 1.0 - maxf(0.0, float(entry["life"]) - 1.2))
		if float(entry["life"]) > 2.2:
			node.queue_free()
			debris.remove_at(index)


func _update_hud() -> void:
	var driving := elapsed >= DRIVE_START and not engine_dead
	var speed := 0 if not driving else int(58.0 + sin(elapsed * 2.7) * 5.0 + clampf((elapsed - DRIVE_START) / 50.0, 0.0, 1.0) * 18.0)
	speed_label.text = "%03d km/h" % speed
	if elapsed < DRIVE_START:
		status_label.text = "IGNITION ATTEMPT %02d" % (1 + int(elapsed / 1.45))
	elif elapsed < 32.0:
		status_label.text = "ENGINE STATUS: NOMINAL*"
	elif elapsed < 54.0:
		status_label.text = "SUSPENSION: OPTIONAL"
	elif elapsed < ARRIVAL_START:
		status_label.text = "VEHICLE INTEGRITY: PENDING"
	elif not engine_dead:
		status_label.text = "ARRIVAL WINDOW CONFIRMED"
	else:
		status_label.text = "ENGINE RESPONSE: NONE"
	control_hint.modulate.a = clampf(1.0 - maxf(0.0, elapsed - 14.0) / 4.0, 0.0, 1.0)
	event_panel.visible = elapsed < event_message_until and not arrival_panel.visible


func _begin_engine_death() -> void:
	engine_dead = true
	car_velocity_x = 0.0
	shake_strength = 1.6
	engine_player.pitch_scale = 0.42
	engine_player.volume_db = -8.0
	clunk_player.play()
	for burst_index in range(8):
		_spawn_smoke(true)
		(smoke_puffs.back().get("node") as Node2D).position += Vector2(float(burst_index - 4) * 8.0, -float(burst_index % 3) * 5.0)
	arrival_panel.visible = true
	var tween := create_tween()
	tween.tween_property(engine_player, "volume_db", -45.0, 0.7)
	tween.tween_callback(engine_player.stop)


func _update_road_surface() -> void:
	var road_points := PackedVector2Array()
	for sample_index in range(19):
		var progress := float(sample_index) / 18.0
		road_points.append(Vector2(_road_center(progress) - _road_half_width(progress), _road_y(progress)))
	for sample_index in range(18, -1, -1):
		var progress := float(sample_index) / 18.0
		road_points.append(Vector2(_road_center(progress) + _road_half_width(progress), _road_y(progress)))
	road_surface.polygon = road_points


func _road_center(progress: float) -> float:
	var drive_amount := clampf((elapsed - DRIVE_START) / 3.5, 0.0, 1.0)
	var arrival_settle := 1.0 - clampf((elapsed - ARRIVAL_START) / (MUSIC_DURATION - ARRIVAL_START), 0.0, 1.0)
	var phase := maxf(0.0, elapsed - DRIVE_START)
	var long_curve := sin(phase * 0.125) * 72.0 + sin(phase * 0.047 + 1.2) * 28.0
	var road_wobble := sin(phase * 0.22 + progress * 2.5) * 10.0
	return 640.0 + (long_curve * pow(progress, 1.55) + road_wobble * progress) * drive_amount * arrival_settle


func _road_y(progress: float) -> float:
	return ROAD_HORIZON_Y + pow(clampf(progress, 0.0, 1.1), 1.72) * (ROAD_BOTTOM_Y - ROAD_HORIZON_Y)


func _road_half_width(progress: float) -> float:
	return 16.0 + pow(clampf(progress, 0.0, 1.1), 1.25) * 535.0


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


func _panel_style(border: Color, fill: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 4)
	return style


func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _ellipse_points(radius_x: float, radius_y: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _make_engine_stream() -> AudioStreamWAV:
	var sample_rate := 11025
	var sample_count := sample_rate
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for index in range(sample_count):
		var time := float(index) / float(sample_rate)
		var piston := sin(TAU * 47.0 * time) * 0.42 + sin(TAU * 94.0 * time) * 0.17
		var rattle := sin(TAU * 211.0 * time + sin(time * 19.0) * 2.0) * 0.09
		var uneven := 0.72 + sin(TAU * 3.5 * time) * 0.18
		var sample := clampf((piston + rattle) * uneven, -1.0, 1.0)
		bytes[index] = int(clampf(128.0 + sample * 78.0, 0.0, 255.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = bytes
	return stream


func _make_clunk_stream() -> AudioStreamWAV:
	var sample_rate := 11025
	var sample_count := int(sample_rate * 0.28)
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for index in range(sample_count):
		var time := float(index) / float(sample_rate)
		var envelope := pow(maxf(0.0, 1.0 - time / 0.28), 2.2)
		var sample := (sin(TAU * 73.0 * time) * 0.65 + sin(TAU * 119.0 * time) * 0.24) * envelope
		bytes[index] = int(clampf(128.0 + sample * 95.0, 0.0, 255.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream


func _layout_frame() -> void:
	if not root_control or not frame:
		return
	var viewport_size := root_control.size
	var scale_factor := minf(viewport_size.x / VIEW_SIZE.x, viewport_size.y / VIEW_SIZE.y)
	frame.scale = Vector2.ONE * scale_factor
	frame.position = (viewport_size - VIEW_SIZE * scale_factor) * 0.5


func _finish() -> void:
	if not active:
		return
	active = false
	if music_player:
		music_player.stop()
	if engine_player:
		engine_player.stop()
	if layer:
		layer.queue_free()
		layer = null
	player.set_physics_process(true)
	finished.emit()
