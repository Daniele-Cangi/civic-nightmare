extends Node

signal completed(result: Dictionary)
signal cancelled

const VIEW_SIZE := Vector2(1280, 720)
const RENDER_SIZE := Vector2i(640, 360)
const DEFAULT_INTRO_DURATION := 3.2
const DEFAULT_OUTRO_DURATION := 2.4
const MAX_CASE_INTEGRITY := 6
const MOVE_SPEED := 5.4
const STRAFE_SPEED := 4.25
const TURN_SPEED := 2.15
const SHOT_COOLDOWN := 0.24
const NOTE_MAGAZINE_SIZE := 6
const RELOAD_DURATION := 1.15
const PLAYER_RADIUS := 0.42
const CORRIDOR_HALF_WIDTH := 5.55
const START_POSITION := Vector3(0.0, 1.55, 2.0)
const GATE_Z := [18.0, 38.0, 60.0]

const MATRYOSHKA_PATH := "res://assets/encounters/putin_operation/matryoshka_security_unit_v1.png"
const COPIER_PATH := "res://assets/encounters/putin_operation/mobilization_copier_v1.png"
const CAMERA_PATH := "res://assets/encounters/putin_operation/state_television_camera_v1.png"
const WEAPON_PATH := "res://assets/encounters/putin_operation/diplomatic_note_launcher_v1.png"

enum State { INACTIVE, INTRO, ACTIVE, RETURNED, CLEARED }

var host: Node
var layer: CanvasLayer
var root_control: Control
var frame: Control
var world_view: TextureRect
var render_viewport: SubViewport
var world_root: Node3D
var camera_3d: Camera3D
var environment_node: WorldEnvironment

var weapon_rect: TextureRect
var muzzle_flash: ColorRect
var damage_flash: ColorRect
var crosshair_lines: Array[ColorRect] = []
var title_label: Label
var title_echo_red: Label
var title_echo_cyan: Label
var status_label: Label
var status_plate: ColorRect
var timer_label: Label
var fire_label: Label
var fire_plate: ColorRect
var note_marks: Array[ColorRect] = []
var reload_sheet: ColorRect
var integrity_marks: Array[ColorRect] = []
var seal_marks: Array[ColorRect] = []

var active := false
var state: State = State.INACTIVE
var state_timer := 0.0
var elapsed := 0.0
var intro_duration := DEFAULT_INTRO_DURATION
var outro_duration := DEFAULT_OUTRO_DURATION
var combat_enabled := true
var player_position := START_POSITION
var player_yaw := 0.0
var case_integrity := MAX_CASE_INTEGRITY
var invulnerability_remaining := 0.0
var shot_cooldown_remaining := 0.0
var notes_loaded := NOTE_MAGAZINE_SIZE
var reload_remaining := 0.0
var weapon_kick := 0.0
var crosshair_hit_timer := 0.0
var status_timer := 0.0
var attempt_count := 0
var shots_fired := 0
var shots_hit := 0
var damage_taken := 0
var cameras_destroyed := 0
var matryoshka_splits := 0
var enemies: Array[Dictionary] = []
var enemy_sequence := 0
var wave_spawned := [false, false, false]
var gate_open := [false, false, false]
var gate_nodes: Array[Node3D] = []
var final_display: Node3D
var seal_nodes: Array[MeshInstance3D] = []
var seal_health := [2, 2, 2]
var final_seals_active := false
var result: Dictionary = {}

var shot_audio: AudioStreamPlayer
var reload_audio: AudioStreamPlayer
var hit_audio: AudioStreamPlayer
var damage_audio: AudioStreamPlayer
var gate_audio: AudioStreamPlayer
var success_audio: AudioStreamPlayer


func setup(owner: Node) -> void:
	host = owner
	_create_overlay()


func start(options: Dictionary = {}) -> void:
	if not layer:
		_create_overlay()
	intro_duration = maxf(0.0, float(options.get("intro_duration", DEFAULT_INTRO_DURATION)))
	outro_duration = maxf(0.0, float(options.get("outro_duration", DEFAULT_OUTRO_DURATION)))
	combat_enabled = bool(options.get("combat_enabled", true))
	attempt_count = 0
	shots_fired = 0
	shots_hit = 0
	damage_taken = 0
	cameras_destroyed = 0
	matryoshka_splits = 0
	result.clear()
	active = true
	layer.visible = true
	_layout_frame()
	_reset_attempt(true)


func stop() -> void:
	active = false
	state = State.INACTIVE
	_clear_enemies()
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
	shot_cooldown_remaining = maxf(0.0, shot_cooldown_remaining - delta)
	_update_reload(delta)
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)
	weapon_kick = move_toward(weapon_kick, 0.0, delta * 5.5)
	crosshair_hit_timer = maxf(0.0, crosshair_hit_timer - delta)
	status_timer = maxf(0.0, status_timer - delta)
	_update_overlay_motion()

	match state:
		State.INTRO:
			if state_timer >= intro_duration:
				_begin_active_run()
		State.ACTIVE:
			_process_active_run(delta)
		State.RETURNED:
			if state_timer >= 1.35:
				_reset_attempt(false)
		State.CLEARED:
			if state_timer >= outro_duration:
				_finish_success()

	_update_hud()


func get_result() -> Dictionary:
	return result.duplicate(true)


func get_enemy_counts() -> Dictionary:
	var alive_count := 0
	var required_count := 0
	var camera_count := 0
	for enemy in enemies:
		if not bool(enemy.get("alive", false)):
			continue
		alive_count += 1
		if bool(enemy.get("blocks_gate", false)):
			required_count += 1
		if str(enemy.get("type", "")) == "state_camera":
			camera_count += 1
	return {
		"alive": alive_count,
		"required": required_count,
		"cameras": camera_count,
	}


func register_enemy_hit(enemy_id: String) -> bool:
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		if str(enemy.get("id", "")) != enemy_id or not bool(enemy.get("alive", false)):
			continue
		shots_hit += 1
		enemy["hp"] = int(enemy.get("hp", 1)) - 1
		enemy["hit_flash"] = 0.14
		enemies[index] = enemy
		var sprite := enemy.get("node") as Sprite3D
		if sprite:
			sprite.modulate = Color(1.0, 0.35, 0.28, 1.0)
		if int(enemy.get("hp", 0)) <= 0:
			_destroy_enemy(index)
		else:
			hit_audio.play()
		return true
	return false


func register_seal_hit(seal_index: int) -> bool:
	if not final_seals_active or seal_index < 0 or seal_index >= seal_health.size():
		return false
	if seal_health[seal_index] <= 0:
		return false
	shots_hit += 1
	seal_health[seal_index] -= 1
	var seal := seal_nodes[seal_index] if seal_index < seal_nodes.size() else null
	if seal:
		seal.scale = Vector3.ONE * (1.28 if seal_health[seal_index] > 0 else 0.01)
	if seal_health[seal_index] <= 0:
		hit_audio.play()
	if _remaining_seals() == 0:
		_open_final_defense()
	return true


func _create_overlay() -> void:
	layer = CanvasLayer.new()
	layer.name = "PutinSpecialOperationLayer"
	layer.layer = 114
	layer.visible = false
	add_child(layer)

	root_control = Control.new()
	root_control.name = "PutinSpecialOperationRoot"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root_control)

	var blackout := ColorRect.new()
	blackout.set_anchors_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color("#020305")
	root_control.add_child(blackout)

	frame = Control.new()
	frame.name = "OperationFrame"
	frame.size = VIEW_SIZE
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(frame)
	root_control.resized.connect(_layout_frame)

	render_viewport = SubViewport.new()
	render_viewport.name = "OperationViewport"
	render_viewport.size = RENDER_SIZE
	render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	render_viewport.own_world_3d = true
	render_viewport.msaa_3d = Viewport.MSAA_DISABLED
	root_control.add_child(render_viewport)

	world_view = TextureRect.new()
	world_view.name = "LowResolutionWorld"
	world_view.position = Vector2.ZERO
	world_view.size = VIEW_SIZE
	world_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_view.stretch_mode = TextureRect.STRETCH_SCALE
	world_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_view.texture = render_viewport.get_texture()
	world_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(world_view)

	_create_world()
	_create_hud()
	_create_audio()
	_layout_frame()


func _create_world() -> void:
	world_root = Node3D.new()
	world_root.name = "ContinuityDefenseComplex"
	render_viewport.add_child(world_root)

	var world_environment := Environment.new()
	world_environment.background_mode = Environment.BG_COLOR
	world_environment.background_color = Color("#141918")
	world_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_environment.ambient_light_color = Color("#7e8a82")
	world_environment.ambient_light_energy = 0.92
	world_environment.fog_enabled = true
	world_environment.fog_light_color = Color("#242a29")
	world_environment.fog_density = 0.010
	environment_node = WorldEnvironment.new()
	environment_node.environment = world_environment
	world_root.add_child(environment_node)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-46, -24, 0)
	key_light.light_color = Color("#e7d4ad")
	key_light.light_energy = 1.15
	key_light.shadow_enabled = true
	world_root.add_child(key_light)

	camera_3d = Camera3D.new()
	camera_3d.name = "CitizenCamera"
	camera_3d.fov = 73.0
	camera_3d.near = 0.08
	camera_3d.far = 90.0
	camera_3d.current = true
	world_root.add_child(camera_3d)

	_build_corridor()
	_build_gates()
	_build_final_display()


func _build_corridor() -> void:
	var floor_material := _make_material(Color("#454b4a"), Color.TRANSPARENT)
	var ceiling_material := _make_material(Color("#252a2a"), Color.TRANSPARENT)
	var wall_material := _make_material(Color("#5d6257"), Color.TRANSPARENT)
	var recess_material := _make_material(Color("#303638"), Color.TRANSPARENT)
	var seam_material := _make_material(Color("#252b2b"), Color.TRANSPARENT)
	var lane_material := _make_material(Color("#735c2b"), Color("#c3983c"))
	var red_light_material := _make_material(Color("#62161a"), Color("#db2630"))
	var cyan_light_material := _make_material(Color("#18383b"), Color("#3dc7ce"))
	var banner_material := _make_material(Color("#691a1e"), Color("#8b1e24"))
	var medal_material := _make_material(Color("#8d6a24"), Color("#e1ae45"))

	_add_box("ConcreteFloor", Vector3(12.0, 0.18, 66.0), Vector3(0, -0.10, 32.0), floor_material)
	_add_box("LowCeiling", Vector3(12.0, 0.18, 66.0), Vector3(0, 3.25, 32.0), ceiling_material)
	_add_box("LeftWall", Vector3(0.45, 3.35, 66.0), Vector3(-5.9, 1.58, 32.0), wall_material)
	_add_box("RightWall", Vector3(0.45, 3.35, 66.0), Vector3(5.9, 1.58, 32.0), wall_material)
	_add_box("RearWall", Vector3(12.0, 3.35, 0.45), Vector3(0, 1.58, 0.0), wall_material)
	_add_box("LeftPipe", Vector3(0.14, 0.14, 64.0), Vector3(-5.43, 2.66, 32.0), recess_material)
	_add_box("RightPipe", Vector3(0.14, 0.14, 64.0), Vector3(5.43, 2.66, 32.0), recess_material)

	for seam_index in range(1, 22):
		var seam_z := float(seam_index * 3)
		_add_box("FloorSeam%d" % seam_index, Vector3(11.0, 0.025, 0.045), Vector3(0, 0.01, seam_z), seam_material)
		if seam_index % 2 == 0:
			_add_box("GuidanceMark%d" % seam_index, Vector3(0.10, 0.035, 1.15), Vector3(0, 0.035, seam_z), lane_material)
		for side in [-1.0, 1.0]:
			_add_box("WallRib%d_%d" % [seam_index, int(side)], Vector3(0.30, 3.08, 0.42), Vector3(side * 5.52, 1.55, seam_z), recess_material)

	for marker_index in range(1, 8):
		var marker_z := float(marker_index * 8)
		for side in [-1.0, 1.0]:
			_add_box(
				"Recess_%d_%d" % [marker_index, int(side)],
				Vector3(0.18, 2.15, 2.8),
				Vector3(side * 5.62, 1.45, marker_z),
				recess_material
			)
			_add_box(
				"WarningLamp_%d_%d" % [marker_index, int(side)],
				Vector3(0.12, 0.28, 0.28),
				Vector3(side * 5.48, 2.35, marker_z - 0.72),
				red_light_material if marker_index % 2 == 0 else cyan_light_material
			)
		var overhead_material := red_light_material if marker_index % 3 == 0 else cyan_light_material
		_add_box(
			"CeilingStrip_%d" % marker_index,
			Vector3(4.8, 0.12, 0.28),
			Vector3(0, 3.12, marker_z),
			overhead_material
		)
		var corridor_light := OmniLight3D.new()
		corridor_light.name = "InspectionLight%d" % marker_index
		corridor_light.position = Vector3(0, 2.8, marker_z)
		corridor_light.light_color = Color("#d7e5d8") if marker_index % 3 else Color("#e0a9a0")
		corridor_light.light_energy = 0.72
		corridor_light.omni_range = 7.4
		corridor_light.shadow_enabled = false
		world_root.add_child(corridor_light)

	# Ceremonial banners insist this utility corridor is a triumphal route.
	for banner_index in range(6):
		var side := -1.0 if banner_index % 2 == 0 else 1.0
		var banner_z := 6.5 + float(banner_index) * 9.6
		_add_box(
			"ContinuityBanner%d" % banner_index,
			Vector3(0.055, 1.72, 2.15),
			Vector3(side * 5.34, 1.62, banner_z),
			banner_material
		)
		for rank_bar in range(3):
			_add_box(
				"BannerRank%d_%d" % [banner_index, rank_bar],
				Vector3(0.07, 0.12, 0.92 - rank_bar * 0.16),
				Vector3(side * 5.28, 1.94 - rank_bar * 0.30, banner_z),
				medal_material
			)

	# Ceremonial cover that looks expensive but does not meaningfully protect anything.
	var cover_material := _make_material(Color("#596056"), Color.TRANSPARENT)
	for cover in [
		Vector3(-3.9, 0.55, 12.0), Vector3(3.8, 0.55, 28.0),
		Vector3(-3.7, 0.55, 47.0), Vector3(3.7, 0.55, 53.0),
	]:
		_add_box("CeremonialCover", Vector3(1.25, 1.1, 0.8), cover, cover_material)


func _build_gates() -> void:
	var gate_material := _make_material(Color("#31382f"), Color.TRANSPARENT)
	var stripe_material := _make_material(Color("#7c5a16"), Color("#d9a62a"))
	for gate_index in range(GATE_Z.size()):
		var gate_root := Node3D.new()
		gate_root.name = "ContinuityGate%d" % (gate_index + 1)
		gate_root.position = Vector3(0, 0, GATE_Z[gate_index])
		world_root.add_child(gate_root)
		_add_box_to(gate_root, "GateSlab", Vector3(11.3, 2.95, 0.32), Vector3(0, 1.48, 0), gate_material)
		for stripe_index in range(5):
			_add_box_to(
				gate_root,
				"Stripe%d" % stripe_index,
				Vector3(1.2, 0.16, 0.05),
				Vector3(-3.0 + stripe_index * 1.5, 1.52, -0.19),
				stripe_material
			)
		gate_nodes.append(gate_root)


func _build_final_display() -> void:
	final_display = Node3D.new()
	final_display.name = "PotemkinDefense"
	final_display.position = Vector3(0, 0, 59.55)
	world_root.add_child(final_display)
	var board_material := _make_material(Color("#3f4739"), Color.TRANSPARENT)
	var trim_material := _make_material(Color("#6d241f"), Color.TRANSPARENT)
	var red_seal_material := _make_material(Color("#8d1718"), Color("#ff3038"))
	_add_box_to(final_display, "TankCardboardBody", Vector3(7.6, 1.62, 0.18), Vector3(0, 1.0, -0.28), board_material)
	_add_box_to(final_display, "TankCardboardTurret", Vector3(3.5, 0.9, 0.20), Vector3(0, 2.18, -0.3), board_material)
	_add_box_to(final_display, "PaintedCannon", Vector3(0.34, 0.34, 3.0), Vector3(0, 2.22, -1.65), trim_material)
	for wheel_index in range(5):
		_add_box_to(final_display, "PaintedWheel%d" % wheel_index, Vector3(0.95, 0.58, 0.12), Vector3(-2.4 + wheel_index * 1.2, 0.38, -0.42), trim_material)

	for seal_index in range(3):
		var seal_mesh := SphereMesh.new()
		seal_mesh.radius = 0.31
		seal_mesh.height = 0.62
		seal_mesh.radial_segments = 18
		seal_mesh.rings = 8
		var seal := MeshInstance3D.new()
		seal.name = "AuthorizationSeal%d" % (seal_index + 1)
		seal.mesh = seal_mesh
		seal.material_override = red_seal_material
		seal.position = Vector3(-2.15 + seal_index * 2.15, 1.55 + (0.42 if seal_index == 1 else 0.0), -0.65)
		final_display.add_child(seal)
		seal_nodes.append(seal)

	var label := Label3D.new()
	label.name = "DisplayLabel"
	label.text = "POTEMKIN DEFENSE"
	label.font_size = 52
	label.pixel_size = 0.009
	label.modulate = Color("#e8d9b5")
	label.outline_modulate = Color.BLACK
	label.outline_size = 8
	label.position = Vector3(0, 2.92, -0.5)
	final_display.add_child(label)


func _create_hud() -> void:
	damage_flash = ColorRect.new()
	damage_flash.position = Vector2.ZERO
	damage_flash.size = VIEW_SIZE
	damage_flash.color = Color(0.8, 0.03, 0.02, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash.z_index = 20
	frame.add_child(damage_flash)

	var top_bar := ColorRect.new()
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(1280, 82)
	top_bar.color = Color(0.008, 0.012, 0.014, 0.90)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.z_index = 30
	frame.add_child(top_bar)

	var propaganda_rule := ColorRect.new()
	propaganda_rule.position = Vector2(0, 70)
	propaganda_rule.size = Vector2(1280, 12)
	propaganda_rule.color = Color("#a71920")
	propaganda_rule.z_index = 31
	frame.add_child(propaganda_rule)

	var title_plate := ColorRect.new()
	title_plate.position = Vector2(20, 12)
	title_plate.size = Vector2(505, 52)
	title_plate.rotation = deg_to_rad(-1.0)
	title_plate.color = Color("#64161b")
	title_plate.z_index = 31
	frame.add_child(title_plate)

	title_echo_red = Label.new()
	title_echo_red.position = Vector2(32, 12)
	title_echo_red.size = Vector2(490, 54)
	title_echo_red.text = "THREE-MINUTE SPECIAL OPERATION"
	title_echo_red.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_echo_red.add_theme_font_size_override("font_size", 25)
	title_echo_red.add_theme_color_override("font_color", Color("#e3242b"))
	title_echo_red.rotation = deg_to_rad(-1.0)
	title_echo_red.z_index = 32
	frame.add_child(title_echo_red)

	title_echo_cyan = Label.new()
	title_echo_cyan.position = Vector2(26, 8)
	title_echo_cyan.size = Vector2(490, 54)
	title_echo_cyan.text = "THREE-MINUTE SPECIAL OPERATION"
	title_echo_cyan.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_echo_cyan.add_theme_font_size_override("font_size", 25)
	title_echo_cyan.add_theme_color_override("font_color", Color("#2b9c9d"))
	title_echo_cyan.rotation = deg_to_rad(-1.0)
	title_echo_cyan.z_index = 32
	frame.add_child(title_echo_cyan)

	title_label = Label.new()
	title_label.position = Vector2(29, 9)
	title_label.size = Vector2(490, 58)
	title_label.text = "THREE-MINUTE SPECIAL OPERATION"
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 25)
	title_label.add_theme_color_override("font_color", Color("#fff1c9"))
	title_label.add_theme_color_override("font_outline_color", Color("#180406"))
	title_label.add_theme_constant_override("outline_size", 4)
	title_label.rotation = deg_to_rad(-1.0)
	title_label.z_index = 33
	frame.add_child(title_label)

	var timer_frame := ColorRect.new()
	timer_frame.position = Vector2(550, 10)
	timer_frame.size = Vector2(180, 58)
	timer_frame.color = Color("#8f181e")
	timer_frame.z_index = 31
	frame.add_child(timer_frame)
	var timer_well := ColorRect.new()
	timer_well.position = Vector2(5, 5)
	timer_well.size = Vector2(170, 48)
	timer_well.color = Color("#050707")
	timer_frame.add_child(timer_well)

	timer_label = Label.new()
	timer_label.position = Vector2(558, 8)
	timer_label.size = Vector2(164, 62)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 38)
	timer_label.add_theme_color_override("font_color", Color("#f2eee2"))
	timer_label.add_theme_color_override("font_outline_color", Color("#8f181e"))
	timer_label.add_theme_constant_override("outline_size", 2)
	timer_label.z_index = 33
	frame.add_child(timer_label)

	var case_label := Label.new()
	case_label.position = Vector2(900, 17)
	case_label.size = Vector2(68, 42)
	case_label.text = "CASE"
	case_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	case_label.add_theme_font_size_override("font_size", 16)
	case_label.add_theme_color_override("font_color", Color("#b9ad94"))
	case_label.z_index = 31
	frame.add_child(case_label)

	for integrity_index in range(MAX_CASE_INTEGRITY):
		var sheet := ColorRect.new()
		sheet.position = Vector2(970 + integrity_index * 38, 23 + (integrity_index % 2) * 3)
		sheet.size = Vector2(27, 36)
		sheet.rotation = deg_to_rad(-4.0 + integrity_index * 1.5)
		sheet.color = Color("#e9dfc3")
		sheet.z_index = 31
		frame.add_child(sheet)
		var red_line := ColorRect.new()
		red_line.position = Vector2(5, 17)
		red_line.size = Vector2(17, 4)
		red_line.color = Color("#9c2020")
		sheet.add_child(red_line)
		integrity_marks.append(sheet)

	var seals_label := Label.new()
	seals_label.position = Vector2(724, 17)
	seals_label.size = Vector2(64, 42)
	seals_label.text = "SEALS"
	seals_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seals_label.add_theme_font_size_override("font_size", 16)
	seals_label.add_theme_color_override("font_color", Color("#b9ad94"))
	seals_label.z_index = 31
	frame.add_child(seals_label)

	for seal_index in range(3):
		var mark := ColorRect.new()
		mark.position = Vector2(790 + seal_index * 42, 27)
		mark.size = Vector2(28, 28)
		mark.color = Color("#641c1d")
		mark.z_index = 31
		frame.add_child(mark)
		seal_marks.append(mark)

	status_plate = ColorRect.new()
	status_plate.position = Vector2(220, 96)
	status_plate.size = Vector2(840, 50)
	status_plate.color = Color(0.38, 0.025, 0.035, 0.90)
	status_plate.rotation = deg_to_rad(-0.8)
	status_plate.z_index = 31
	frame.add_child(status_plate)

	status_label = Label.new()
	status_label.position = Vector2(245, 92)
	status_label.size = Vector2(790, 58)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 29)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	status_label.add_theme_color_override("font_outline_color", Color("#7d1118"))
	status_label.add_theme_constant_override("outline_size", 5)
	status_label.add_theme_constant_override("shadow_offset_x", 3)
	status_label.add_theme_constant_override("shadow_offset_y", 3)
	status_label.z_index = 32
	frame.add_child(status_label)

	fire_plate = ColorRect.new()
	fire_plate.position = Vector2(1035, 614)
	fire_plate.size = Vector2(205, 62)
	fire_plate.color = Color("#94171d")
	fire_plate.rotation = deg_to_rad(-2.0)
	fire_plate.z_index = 39
	frame.add_child(fire_plate)
	var fire_well := ColorRect.new()
	fire_well.position = Vector2(6, 6)
	fire_well.size = Vector2(193, 50)
	fire_well.color = Color("#100c0b")
	fire_plate.add_child(fire_well)

	fire_label = Label.new()
	fire_label.position = Vector2(1030, 607)
	fire_label.size = Vector2(220, 76)
	fire_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fire_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fire_label.add_theme_font_size_override("font_size", 29)
	fire_label.add_theme_color_override("font_color", Color("#f5ead0"))
	fire_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	fire_label.add_theme_color_override("font_outline_color", Color("#a71920"))
	fire_label.add_theme_constant_override("outline_size", 5)
	fire_label.add_theme_constant_override("shadow_offset_x", 3)
	fire_label.add_theme_constant_override("shadow_offset_y", 3)
	fire_label.z_index = 40
	frame.add_child(fire_label)

	var notes_caption := Label.new()
	notes_caption.position = Vector2(1015, 501)
	notes_caption.size = Vector2(245, 28)
	notes_caption.text = "DIPLOMATIC NOTES"
	notes_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notes_caption.add_theme_font_size_override("font_size", 15)
	notes_caption.add_theme_color_override("font_color", Color("#f1d59f"))
	notes_caption.add_theme_color_override("font_outline_color", Color.BLACK)
	notes_caption.add_theme_constant_override("outline_size", 3)
	notes_caption.rotation = deg_to_rad(1.2)
	notes_caption.z_index = 40
	frame.add_child(notes_caption)
	for note_index in range(NOTE_MAGAZINE_SIZE):
		var note := ColorRect.new()
		note.position = Vector2(1035 + note_index * 34, 536 + (note_index % 2) * 3)
		note.size = Vector2(25, 34)
		note.rotation = deg_to_rad(-5.0 + note_index * 1.7)
		note.color = Color("#ede0bd")
		note.z_index = 40
		frame.add_child(note)
		var note_line := ColorRect.new()
		note_line.position = Vector2(4, 16)
		note_line.size = Vector2(17, 4)
		note_line.color = Color("#a71920")
		note.add_child(note_line)
		note_marks.append(note)

	reload_sheet = ColorRect.new()
	reload_sheet.position = Vector2(590, 126)
	reload_sheet.size = Vector2(100, 132)
	reload_sheet.rotation = deg_to_rad(4.0)
	reload_sheet.color = Color("#f0e4c5")
	reload_sheet.visible = false
	reload_sheet.z_index = 38
	frame.add_child(reload_sheet)
	for form_line_index in range(5):
		var form_line := ColorRect.new()
		form_line.position = Vector2(13, 20 + form_line_index * 18)
		form_line.size = Vector2(74, 4)
		form_line.color = Color("#7b8580") if form_line_index < 4 else Color("#9e1d23")
		reload_sheet.add_child(form_line)
	var reload_stamp := Label.new()
	reload_stamp.position = Vector2(7, 84)
	reload_stamp.size = Vector2(86, 42)
	reload_stamp.text = "R-6"
	reload_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reload_stamp.add_theme_font_size_override("font_size", 31)
	reload_stamp.add_theme_color_override("font_color", Color("#a71920"))
	reload_stamp.rotation = deg_to_rad(-7.0)
	reload_sheet.add_child(reload_stamp)

	for rect in [
		Rect2(635, 337, 10, 2), Rect2(639, 333, 2, 10),
	]:
		var line := ColorRect.new()
		line.position = rect.position
		line.size = rect.size
		line.color = Color("#f1e6c9")
		line.z_index = 40
		frame.add_child(line)
		crosshair_lines.append(line)

	muzzle_flash = ColorRect.new()
	muzzle_flash.position = Vector2(570, 340)
	muzzle_flash.size = Vector2(140, 155)
	muzzle_flash.color = Color(1.0, 0.76, 0.24, 0.0)
	muzzle_flash.z_index = 36
	frame.add_child(muzzle_flash)

	weapon_rect = TextureRect.new()
	weapon_rect.name = "DiplomaticNoteLauncher"
	weapon_rect.position = Vector2(314, 270)
	weapon_rect.size = Vector2(652, 435)
	weapon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(WEAPON_PATH):
		weapon_rect.texture = load(WEAPON_PATH)
	weapon_rect.z_index = 37
	frame.add_child(weapon_rect)


func _create_audio() -> void:
	shot_audio = AudioStreamPlayer.new()
	shot_audio.stream = _make_tone(92.0, 0.13, 0.42)
	shot_audio.volume_db = -5.0
	add_child(shot_audio)
	reload_audio = AudioStreamPlayer.new()
	reload_audio.stream = _make_tone(146.0, 0.24, 0.26)
	reload_audio.volume_db = -7.0
	add_child(reload_audio)
	hit_audio = AudioStreamPlayer.new()
	hit_audio.stream = _make_tone(310.0, 0.11, 0.22)
	hit_audio.volume_db = -8.0
	add_child(hit_audio)
	damage_audio = AudioStreamPlayer.new()
	damage_audio.stream = _make_tone(58.0, 0.22, 0.58)
	damage_audio.volume_db = -5.0
	add_child(damage_audio)
	gate_audio = AudioStreamPlayer.new()
	gate_audio.stream = _make_tone(178.0, 0.38, 0.18)
	gate_audio.volume_db = -8.0
	add_child(gate_audio)
	success_audio = AudioStreamPlayer.new()
	success_audio.stream = _make_tone(660.0, 0.48, 0.02)
	success_audio.volume_db = -7.0
	add_child(success_audio)


func _reset_attempt(first_attempt: bool) -> void:
	attempt_count += 1
	state = State.INTRO
	state_timer = 0.0
	elapsed = 0.0
	player_position = START_POSITION
	player_yaw = 0.0
	case_integrity = MAX_CASE_INTEGRITY
	invulnerability_remaining = 0.0
	shot_cooldown_remaining = 0.0
	notes_loaded = NOTE_MAGAZINE_SIZE
	reload_remaining = 0.0
	weapon_kick = 0.0
	status_timer = 0.0
	wave_spawned = [false, false, false]
	gate_open = [false, false, false]
	seal_health = [2, 2, 2]
	final_seals_active = false
	_clear_enemies()
	for gate_index in range(gate_nodes.size()):
		gate_nodes[gate_index].visible = true
	if final_display:
		final_display.visible = true
	for seal in seal_nodes:
		seal.visible = true
		seal.scale = Vector3.ONE
	_spawn_wave(0)
	status_label.text = "W/S ADVANCE  //  A/D TURN  //  Q/E EVADE  //  SPACE STAMP"
	fire_label.text = ""
	if not first_attempt:
		intro_duration = minf(intro_duration, 0.85)
	_update_camera()


func _begin_active_run() -> void:
	state = State.ACTIVE
	state_timer = 0.0
	status_label.text = ""
	fire_label.text = "SPACE  STAMP"


func _process_active_run(delta: float) -> void:
	elapsed += delta
	_process_player_input(delta)
	_update_wave_triggers()
	_update_enemies(delta)
	_update_gate_progress()
	_update_camera()
	if gate_open[2] and player_position.z >= 61.2:
		_begin_cleared()


func _process_player_input(delta: float) -> void:
	var turn_input := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(Key.KEY_A):
		turn_input += 1.0
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(Key.KEY_D):
		turn_input -= 1.0
	player_yaw += turn_input * TURN_SPEED * delta

	var forward_input := 0.0
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(Key.KEY_W):
		forward_input += 1.0
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(Key.KEY_S):
		forward_input -= 1.0
	var strafe_input := float(Input.is_physical_key_pressed(Key.KEY_E)) - float(Input.is_physical_key_pressed(Key.KEY_Q))
	var forward := _forward_vector()
	var right := Vector3(-forward.z, 0.0, forward.x)
	var motion := forward * forward_input * MOVE_SPEED + right * strafe_input * STRAFE_SPEED
	if motion.length_squared() > MOVE_SPEED * MOVE_SPEED:
		motion = motion.normalized() * MOVE_SPEED
	_try_move(motion * delta)

	if Input.is_physical_key_pressed(Key.KEY_R) and reload_remaining <= 0.0 and notes_loaded < NOTE_MAGAZINE_SIZE:
		_begin_reload()
	var fire_pressed := Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if fire_pressed and shot_cooldown_remaining <= 0.0 and reload_remaining <= 0.0:
		_fire()


func _try_move(motion: Vector3) -> void:
	var candidate := player_position + motion
	candidate.x = clampf(candidate.x, -CORRIDOR_HALF_WIDTH + PLAYER_RADIUS, CORRIDOR_HALF_WIDTH - PLAYER_RADIUS)
	candidate.z = clampf(candidate.z, 1.0, 62.5)
	for gate_index in range(GATE_Z.size()):
		if gate_open[gate_index]:
			continue
		var gate_z: float = GATE_Z[gate_index]
		if player_position.z < gate_z and candidate.z >= gate_z - 0.62:
			candidate.z = gate_z - 0.64
		elif player_position.z > gate_z and candidate.z <= gate_z + 0.62:
			candidate.z = gate_z + 0.64
	player_position = candidate


func _fire() -> void:
	if reload_remaining > 0.0:
		return
	if notes_loaded <= 0:
		_begin_reload()
		return
	shot_cooldown_remaining = SHOT_COOLDOWN
	notes_loaded -= 1
	shots_fired += 1
	weapon_kick = 1.0
	muzzle_flash.color.a = 0.78
	shot_audio.play()
	if notes_loaded <= 0:
		_begin_reload()

	var forward := _forward_vector()
	var best_kind := ""
	var best_index := -1
	var best_score := INF
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		if not bool(enemy.get("alive", false)):
			continue
		var enemy_position := enemy.get("position", Vector3.ZERO) as Vector3
		var offset := enemy_position - player_position
		var flat_offset := Vector3(offset.x, 0.0, offset.z)
		var distance := flat_offset.length()
		if distance <= 0.01 or distance > 21.0:
			continue
		var direction := flat_offset / distance
		var alignment := clampf(forward.dot(direction), -1.0, 1.0)
		var angular_radius := 0.075 + float(enemy.get("target_radius", 0.8)) / maxf(distance, 1.0)
		var angle := acos(alignment)
		if angle <= angular_radius:
			var score := angle + distance * 0.0015
			if score < best_score:
				best_score = score
				best_kind = "enemy"
				best_index = index

	if final_seals_active:
		for seal_index in range(seal_nodes.size()):
			if seal_health[seal_index] <= 0:
				continue
			var seal_position := seal_nodes[seal_index].global_position
			var seal_offset := seal_position - player_position
			var flat_seal := Vector3(seal_offset.x, 0.0, seal_offset.z)
			var seal_distance := flat_seal.length()
			if seal_distance <= 0.01 or seal_distance > 18.0:
				continue
			var seal_angle := acos(clampf(forward.dot(flat_seal / seal_distance), -1.0, 1.0))
			if seal_angle <= 0.085 and seal_angle < best_score:
				best_score = seal_angle
				best_kind = "seal"
				best_index = seal_index

	if best_kind == "enemy":
		register_enemy_hit(str(enemies[best_index].get("id", "")))
		crosshair_hit_timer = 0.12
	elif best_kind == "seal":
		register_seal_hit(best_index)
		crosshair_hit_timer = 0.12


func _begin_reload() -> void:
	if reload_remaining > 0.0 or notes_loaded >= NOTE_MAGAZINE_SIZE:
		return
	reload_remaining = RELOAD_DURATION
	shot_cooldown_remaining = RELOAD_DURATION
	weapon_kick = 0.0
	reload_audio.pitch_scale = 1.0
	reload_audio.play()
	_show_status("RE-FILING UNDER EMERGENCY DECREE", 0.82)


func _update_reload(delta: float) -> void:
	if reload_remaining <= 0.0:
		return
	reload_remaining = maxf(0.0, reload_remaining - delta)
	if reload_remaining > 0.0:
		return
	notes_loaded = NOTE_MAGAZINE_SIZE
	reload_audio.pitch_scale = 1.42
	reload_audio.play()
	_show_status("SIX NOTES CERTIFIED WITHOUT REVIEW", 0.68)


func _spawn_wave(wave_index: int) -> void:
	if wave_index < 0 or wave_index >= wave_spawned.size() or wave_spawned[wave_index]:
		return
	wave_spawned[wave_index] = true
	match wave_index:
		0:
			_spawn_enemy("mobilization_copier", Vector3(-2.5, 0, 9.5), wave_index, true)
			_spawn_enemy("matryoshka", Vector3(2.4, 0, 13.2), wave_index, true)
			_spawn_enemy("state_camera", Vector3(0.0, 0, 16.2), wave_index, false)
		1:
			_spawn_enemy("mobilization_copier", Vector3(2.8, 0, 26.0), wave_index, true)
			_spawn_enemy("matryoshka", Vector3(-2.7, 0, 31.0), wave_index, true)
			_spawn_enemy("state_camera", Vector3(0.4, 0, 35.5), wave_index, false)
		2:
			_spawn_enemy("mobilization_copier", Vector3(-3.0, 0, 46.0), wave_index, true)
			_spawn_enemy("matryoshka", Vector3(2.5, 0, 50.4), wave_index, true)
			_spawn_enemy("mobilization_copier", Vector3(-0.4, 0, 54.0), wave_index, true)
			_spawn_enemy("state_camera", Vector3(3.4, 0, 56.2), wave_index, false)


func _spawn_enemy(enemy_type: String, position: Vector3, wave_index: int, blocks_gate: bool, scale_factor: float = 1.0) -> String:
	enemy_sequence += 1
	var enemy_id := "%s_%02d" % [enemy_type, enemy_sequence]
	var texture_path := COPIER_PATH
	var hp := 2
	var speed := 0.72
	var attack_range := 7.2
	var attack_interval := 1.65
	var target_radius := 0.92
	var sprite_height := 2.55
	match enemy_type:
		"matryoshka":
			texture_path = MATRYOSHKA_PATH
			hp = 3
			speed = 0.58
			attack_range = 6.1
			attack_interval = 1.9
			target_radius = 1.02
			sprite_height = 2.95
		"matryoshka_small":
			texture_path = MATRYOSHKA_PATH
			hp = 1
			speed = 1.12
			attack_range = 4.8
			attack_interval = 1.45
			target_radius = 0.62
			sprite_height = 1.72
		"state_camera":
			texture_path = CAMERA_PATH
			hp = 2
			speed = 0.24
			attack_range = 12.5
			attack_interval = 2.25
			target_radius = 0.88
			sprite_height = 2.72

	var sprite := Sprite3D.new()
	sprite.name = enemy_id
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.pixel_size = sprite_height / maxf(float(sprite.texture.get_height()), 1.0) if sprite.texture else 0.006
	sprite.position = Vector3(position.x, sprite_height * 0.5, position.z)
	sprite.scale = Vector3.ONE * scale_factor
	world_root.add_child(sprite)

	enemies.append({
		"id": enemy_id,
		"type": enemy_type,
		"node": sprite,
		"position": Vector3(position.x, sprite_height * 0.5, position.z),
		"base_y": sprite_height * 0.5,
		"hp": hp,
		"speed": speed,
		"attack_range": attack_range,
		"attack_interval": attack_interval,
		"attack_timer": 0.65 + float(enemy_sequence % 4) * 0.22,
		"target_radius": target_radius,
		"wave": wave_index,
		"blocks_gate": blocks_gate,
		"alive": true,
		"hit_flash": 0.0,
	})
	return enemy_id


func _update_wave_triggers() -> void:
	if gate_open[0] and player_position.z > 20.0:
		_spawn_wave(1)
	if gate_open[1] and player_position.z > 40.0:
		_spawn_wave(2)


func _update_enemies(delta: float) -> void:
	if not combat_enabled:
		return
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		if not bool(enemy.get("alive", false)):
			continue
		var sprite := enemy.get("node") as Sprite3D
		if not sprite:
			continue
		var position := enemy.get("position", Vector3.ZERO) as Vector3
		var to_player := Vector3(player_position.x - position.x, 0.0, player_position.z - position.z)
		var distance := to_player.length()
		if distance > float(enemy.get("attack_range", 7.0)) * 0.72 and distance > 1.45:
			var next_position := position + to_player.normalized() * float(enemy.get("speed", 0.6)) * delta
			next_position.x = clampf(next_position.x, -CORRIDOR_HALF_WIDTH + 0.8, CORRIDOR_HALF_WIDTH - 0.8)
			# Enemies never cross backward through a continuity gate.
			var wave_index := int(enemy.get("wave", 0))
			var minimum_z: float = 2.2 if wave_index == 0 else float(GATE_Z[wave_index - 1]) + 1.0
			next_position.z = maxf(next_position.z, minimum_z)
			position = next_position
		enemy["position"] = position
		enemy["attack_timer"] = float(enemy.get("attack_timer", 0.0)) - delta
		enemy["hit_flash"] = maxf(0.0, float(enemy.get("hit_flash", 0.0)) - delta)
		var bob := sin(elapsed * 5.2 + float(index)) * 0.055
		sprite.position = Vector3(position.x, float(enemy.get("base_y", 1.3)) + bob, position.z)
		if float(enemy.get("hit_flash", 0.0)) <= 0.0:
			sprite.modulate = Color.WHITE
		if distance <= float(enemy.get("attack_range", 7.0)) and float(enemy.get("attack_timer", 0.0)) <= 0.0:
			enemy["attack_timer"] = float(enemy.get("attack_interval", 1.7))
			_enemy_attack(str(enemy.get("type", "")))
		enemies[index] = enemy


func _enemy_attack(enemy_type: String) -> void:
	if invulnerability_remaining > 0.0 or state != State.ACTIVE:
		return
	case_integrity -= 1
	damage_taken += 1
	invulnerability_remaining = 0.72
	damage_flash.color = Color(0.85, 0.04, 0.02, 0.62)
	if enemy_type == "state_camera":
		damage_flash.color = Color(0.04, 0.67, 0.76, 0.46)
	elif enemy_type == "mobilization_copier":
		damage_flash.color = Color(0.92, 0.86, 0.68, 0.52)
	damage_audio.play()
	if case_integrity <= 0:
		_begin_returned()


func _destroy_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index]
	if not bool(enemy.get("alive", false)):
		return
	enemy["alive"] = false
	enemies[index] = enemy
	var sprite := enemy.get("node") as Sprite3D
	if sprite:
		sprite.visible = false
	hit_audio.play()
	var enemy_type := str(enemy.get("type", ""))
	if enemy_type == "state_camera":
		cameras_destroyed += 1
		_show_status("BROADCAST TEMPORARILY OBJECTIVE", 0.9)
	elif enemy_type == "matryoshka":
		matryoshka_splits += 1
		var position := enemy.get("position", Vector3.ZERO) as Vector3
		var wave_index := int(enemy.get("wave", 0))
		var blocks_gate := bool(enemy.get("blocks_gate", true))
		_spawn_enemy("matryoshka_small", position + Vector3(-0.65, -0.3, 0.15), wave_index, blocks_gate, 0.82)
		_spawn_enemy("matryoshka_small", position + Vector3(0.65, -0.3, -0.15), wave_index, blocks_gate, 0.82)
		_show_status("SECURITY UNIT RESTRUCTURED", 0.9)
	else:
		_show_status("UNIT REPOSITIONED VOLUNTARILY", 0.78)


func _update_gate_progress() -> void:
	for wave_index in range(3):
		if not wave_spawned[wave_index] or gate_open[wave_index]:
			continue
		var blockers := 0
		for enemy in enemies:
			if bool(enemy.get("alive", false)) and int(enemy.get("wave", -1)) == wave_index and bool(enemy.get("blocks_gate", false)):
				blockers += 1
		if blockers > 0:
			continue
		if wave_index < 2:
			_open_gate(wave_index)
		elif not final_seals_active:
			final_seals_active = true
			_show_status("DEFENSE REQUIRES THREE SIGNATURES", 1.35)
			gate_audio.play()


func _open_gate(gate_index: int) -> void:
	if gate_index < 0 or gate_index >= gate_open.size() or gate_open[gate_index]:
		return
	gate_open[gate_index] = true
	if gate_index < gate_nodes.size():
		gate_nodes[gate_index].visible = false
	_show_status("TACTICAL GOODWILL CORRIDOR OPEN", 1.15)
	gate_audio.play()


func _open_final_defense() -> void:
	gate_open[2] = true
	if gate_nodes.size() > 2:
		gate_nodes[2].visible = false
	if final_display:
		final_display.visible = false
	_show_status("DEFENSE WITHDREW AS A GESTURE OF GOODWILL", 1.5)
	gate_audio.play()


func _begin_returned() -> void:
	state = State.RETURNED
	state_timer = 0.0
	status_label.text = "OPERATION RESTARTED ACCORDING TO PLAN"
	fire_label.text = ""


func _begin_cleared() -> void:
	state = State.CLEARED
	state_timer = 0.0
	status_label.text = "SPECIAL OPERATION COMPLETED"
	fire_label.text = "EVERYTHING PROCEEDED ACCORDING TO PLAN"
	success_audio.play()


func _finish_success() -> void:
	var accuracy := float(shots_hit) / float(maxi(shots_fired, 1))
	result = {
		"outcome": "access_granted",
		"route": "broadcast_suppressed" if cameras_destroyed > 0 else "defensive_corridor",
		"attempts": attempt_count,
		"shots_fired": shots_fired,
		"shots_hit": shots_hit,
		"accuracy": snappedf(accuracy, 0.01),
		"damage_taken": damage_taken,
		"cameras_destroyed": cameras_destroyed,
		"matryoshka_splits": matryoshka_splits,
		"elapsed_seconds": snappedf(elapsed, 0.1),
	}
	active = false
	state = State.INACTIVE
	layer.visible = false
	completed.emit(result.duplicate(true))


func _update_camera() -> void:
	if not camera_3d:
		return
	camera_3d.position = player_position
	camera_3d.rotation = Vector3(0.0, player_yaw + PI, 0.0)


func _update_overlay_motion() -> void:
	var reload_progress := 0.0
	if reload_remaining > 0.0:
		reload_progress = 1.0 - reload_remaining / RELOAD_DURATION
	if weapon_rect:
		var walking := state == State.ACTIVE and (
			Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")
			or Input.is_physical_key_pressed(Key.KEY_W) or Input.is_physical_key_pressed(Key.KEY_S)
		)
		var bob := sin(elapsed * 10.0) * 4.0 if walking else 0.0
		var reload_drop := sin(reload_progress * PI) * 58.0 if reload_remaining > 0.0 else 0.0
		weapon_rect.position = Vector2(314, 270 + bob + weapon_kick * 29.0 + reload_drop)
	if reload_sheet:
		reload_sheet.visible = reload_remaining > 0.0
		if reload_sheet.visible:
			var feed_curve := reload_progress * reload_progress * (3.0 - 2.0 * reload_progress)
			reload_sheet.position = Vector2(590 + sin(reload_progress * PI) * 18.0, 126 + feed_curve * 188.0)
			reload_sheet.rotation = deg_to_rad(7.0 - reload_progress * 10.0)
	if muzzle_flash:
		muzzle_flash.color.a = move_toward(muzzle_flash.color.a, 0.0, 0.18)
	if damage_flash:
		damage_flash.color.a = move_toward(damage_flash.color.a, 0.0, 0.035)
	for line in crosshair_lines:
		line.color = Color("#ffdc63") if crosshair_hit_timer > 0.0 else Color("#f1e6c9")
	var title_jitter := sin(elapsed * 17.0) * 1.4
	if title_echo_red:
		title_echo_red.position = Vector2(32 + title_jitter, 12)
	if title_echo_cyan:
		title_echo_cyan.position = Vector2(26 - title_jitter, 8)
	if state == State.INTRO:
		status_label.modulate.a = 0.55 + 0.45 * absf(sin(state_timer * 4.0))
	else:
		status_label.modulate.a = 1.0
	if status_timer <= 0.0 and state == State.ACTIVE:
		status_label.text = ""
	if status_plate:
		status_plate.visible = status_label.text != ""
		status_plate.rotation = deg_to_rad(-0.8 + sin(elapsed * 11.0) * 0.35)
	if status_label:
		status_label.rotation = deg_to_rad(sin(elapsed * 13.0) * 0.28 if status_label.text != "" else 0.0)
	if fire_plate:
		fire_plate.visible = state == State.ACTIVE
		fire_plate.rotation = deg_to_rad(-2.0 + sin(elapsed * 8.0) * (1.3 if reload_remaining > 0.0 else 0.35))
	if fire_label and state == State.ACTIVE:
		fire_label.text = "AUTO-FILING" if reload_remaining > 0.0 else "SPACE  STAMP"
		fire_label.add_theme_color_override("font_color", Color("#ff3941") if reload_remaining > 0.0 else Color("#f5ead0"))


func _update_hud() -> void:
	if not timer_label:
		return
	var minutes := int(elapsed) / 60
	var seconds := int(elapsed) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	for index in range(integrity_marks.size()):
		integrity_marks[index].modulate = Color.WHITE if index < case_integrity else Color(0.18, 0.18, 0.18, 0.34)
	for index in range(note_marks.size()):
		note_marks[index].modulate = Color.WHITE if index < notes_loaded else Color(0.16, 0.12, 0.10, 0.32)
	for index in range(seal_marks.size()):
		if not final_seals_active:
			seal_marks[index].color = Color("#32282a")
		elif seal_health[index] > 0:
			seal_marks[index].color = Color("#d42e32")
		else:
			seal_marks[index].color = Color("#29372d")


func _show_status(text: String, duration: float) -> void:
	status_label.text = text
	status_timer = duration


func _remaining_seals() -> int:
	var remaining := 0
	for health in seal_health:
		if int(health) > 0:
			remaining += 1
	return remaining


func _forward_vector() -> Vector3:
	return Vector3(sin(player_yaw), 0.0, cos(player_yaw)).normalized()


func _clear_enemies() -> void:
	for enemy in enemies:
		var sprite := enemy.get("node") as Sprite3D
		if sprite and is_instance_valid(sprite):
			sprite.queue_free()
	enemies.clear()
	enemy_sequence = 0


func _add_box(name_value: String, size_value: Vector3, position_value: Vector3, material: Material) -> MeshInstance3D:
	return _add_box_to(world_root, name_value, size_value, position_value, material)


func _add_box_to(parent: Node3D, name_value: String, size_value: Vector3, position_value: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	var instance := MeshInstance3D.new()
	instance.name = name_value
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _make_material(albedo: Color, emission: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.88
	if emission.a > 0.0:
		material.emission_enabled = true
		material.emission = Color(emission.r, emission.g, emission.b, 1.0)
		material.emission_energy_multiplier = 1.8
	return material


func _layout_frame() -> void:
	if root_control and frame:
		frame.position = (root_control.size - VIEW_SIZE) * 0.5


func _make_tone(frequency: float, duration: float, noise_amount: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := maxi(1, int(duration * sample_rate))
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for index in range(sample_count):
		var time := float(index) / float(sample_rate)
		var envelope := pow(1.0 - float(index) / float(sample_count), 1.7)
		var wave := sin(TAU * frequency * time) * (1.0 - noise_amount)
		var noise := sin(float(index * 7919 % 997) * 0.013) * noise_amount
		bytes[index] = clampi(int(128.0 + (wave + noise) * envelope * 105.0), 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream
