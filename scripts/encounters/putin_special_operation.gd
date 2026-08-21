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
const PLAYER_HIT_RADIUS := 0.62
const CORRIDOR_HALF_WIDTH := 5.55
const START_POSITION := Vector3(0.0, 1.55, 2.0)
const GATE_Z := [18.0, 38.0, 60.0]
const COVER_POINTS := [
	Vector3(-3.9, 0.55, 12.0),
	Vector3(3.8, 0.55, 28.0),
	Vector3(-3.7, 0.55, 47.0),
	Vector3(3.7, 0.55, 53.0),
]
const COVER_HALF_SIZE := Vector2(0.625, 0.4)
const MAX_ACTIVE_THREATS := 1
const PROJECTILE_LIFETIME := 4.8

const MATRYOSHKA_PATH := "res://assets/encounters/putin_operation/matryoshka_security_unit_v1.png"
const COPIER_PATH := "res://assets/encounters/putin_operation/mobilization_copier_v1.png"
const CAMERA_PATH := "res://assets/encounters/putin_operation/state_television_camera_v1.png"
const STRATEGIC_BEAR_PATH := "res://assets/encounters/putin_operation/strategic_bear_washer_boss_v1.png"
const WEAPON_PATH := "res://assets/encounters/putin_operation/diplomatic_note_launcher_centered_v2.png"
const MUSIC_PATH := "res://assets/audio/civic_nightmare_putin_special_operation.ogg"
const STRATEGIC_BEAR_MAX_HEALTH := 6
const STRATEGIC_BEAR_RELOAD_DURATION := 2.25
const STRATEGIC_BEAR_ALARM_RELOAD_DURATION := 1.70
const STRATEGIC_BEAR_ALARM_HIT_THRESHOLD := 3
const STRATEGIC_BEAR_ALARM_STRAFE_DISTANCE := 2.15
const STRATEGIC_BEAR_DEPARTURE_DURATION := 1.75
const STRATEGIC_BEAR_POSITION := Vector3(0.0, 0.0, 64.0)
const STRATEGIC_BEAR_TARGET_POSITION := Vector3(0.0, 2.12, 63.78)
const WEAPON_CUTOUT_SHADER := """
shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float neutral_range = max(color.r, max(color.g, color.b)) - min(color.r, min(color.g, color.b));
	if (min(color.r, min(color.g, color.b)) > 0.90 && neutral_range < 0.035) {
		color.a = 0.0;
	}
	COLOR = color;
}
"""

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
var seal_caption_label: Label

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
var enemy_projectiles: Array[Dictionary] = []
var enemy_sequence := 0
var projectile_sequence := 0
var wave_spawned := [false, false, false]
var gate_open := [false, false, false]
var gate_nodes: Array[Node3D] = []
var final_display: Node3D
var final_display_label: Label3D
var seal_nodes: Array[MeshInstance3D] = []
var seal_target_nodes: Array[Node3D] = []
var seal_ready_material: StandardMaterial3D
var seal_damaged_material: StandardMaterial3D
var seal_health := [2, 2, 2]
var seal_hit_flash := [0.0, 0.0, 0.0]
var final_seals_active := false
var final_seals_resolved := false
var strategic_bear_target: Node3D
var strategic_bear_id := ""
var strategic_bear_active := false
var strategic_bear_defeated := false
var strategic_bear_departure_active := false
var strategic_bear_departure_timer := 0.0
var strategic_bear_departure_stage := 0
var strategic_bear_hits := 0
var strategic_bear_alarm_phase := false
var domestic_reserve_label: Label3D
var strategic_bear_alarm_lights: Array[OmniLight3D] = []
var strategic_bear_alarm_strips: Array[MeshInstance3D] = []
var recovered_appliance_roots: Array[Node3D] = []
var result: Dictionary = {}

var shot_audio: AudioStreamPlayer
var reload_audio: AudioStreamPlayer
var hit_audio: AudioStreamPlayer
var damage_audio: AudioStreamPlayer
var gate_audio: AudioStreamPlayer
var success_audio: AudioStreamPlayer
var music_player: AudioStreamPlayer


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
	if strategic_bear_target:
		strategic_bear_target.visible = false
	if music_player:
		music_player.stop()
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
	for seal_index in range(seal_hit_flash.size()):
		seal_hit_flash[seal_index] = maxf(0.0, float(seal_hit_flash[seal_index]) - delta)
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


func get_music_asset_path() -> String:
	return MUSIC_PATH


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


func get_strategic_bear_state() -> Dictionary:
	var health := 0
	var vulnerable := false
	for enemy in enemies:
		if str(enemy.get("id", "")) != strategic_bear_id:
			continue
		health = int(enemy.get("hp", 0))
		vulnerable = bool(enemy.get("vulnerable", false))
		break
	return {
		"id": strategic_bear_id,
		"active": strategic_bear_active,
		"defeated": strategic_bear_defeated,
		"departing": strategic_bear_departure_active,
		"alarm_phase": strategic_bear_alarm_phase,
		"health": health,
		"vulnerable": vulnerable,
	}


func register_enemy_hit(enemy_id: String) -> bool:
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		if str(enemy.get("id", "")) != enemy_id or not bool(enemy.get("alive", false)):
			continue
		if str(enemy.get("type", "")) == "strategic_bear":
			return _register_strategic_bear_hit(index, enemy)
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


func _register_strategic_bear_hit(index: int, enemy: Dictionary) -> bool:
	var sprite := enemy.get("node") as Sprite3D
	if not bool(enemy.get("vulnerable", false)):
		enemy["hit_flash"] = 0.10
		enemies[index] = enemy
		if sprite:
			sprite.modulate = Color("#c7d2cb")
		hit_audio.pitch_scale = 0.68
		hit_audio.play()
		_show_status("DAMAGE NOT RECOGNIZED OUTSIDE THE WASH CYCLE", 0.62)
		return false
	var allowed_reload_hits := 1 if strategic_bear_alarm_phase else 2
	if int(enemy.get("reload_hits", 0)) >= allowed_reload_hits:
		_show_status("ONE LOAD — ONE AUTHORIZED STAMP", 0.62)
		return false
	shots_hit += 1
	strategic_bear_hits += 1
	enemy["reload_hits"] = int(enemy.get("reload_hits", 0)) + 1
	enemy["hp"] = int(enemy.get("hp", STRATEGIC_BEAR_MAX_HEALTH)) - 1
	enemy["hit_flash"] = 0.18
	if strategic_bear_hits == STRATEGIC_BEAR_ALARM_HIT_THRESHOLD:
		strategic_bear_alarm_phase = true
		enemy["vulnerable"] = false
		enemy["reload_timer"] = 0.0
		enemy["attack_state"] = "idle"
		enemy["attack_timer"] = 0.72
		if strategic_bear_target:
			strategic_bear_target.visible = false
		_activate_strategic_bear_alarm()
	enemies[index] = enemy
	if sprite:
		sprite.modulate = Color("#ff9b7e")
	hit_audio.pitch_scale = 1.18
	hit_audio.play()
	if int(enemy.get("hp", 0)) <= 0:
		_defeat_strategic_bear(index)
	elif strategic_bear_alarm_phase and strategic_bear_hits == STRATEGIC_BEAR_ALARM_HIT_THRESHOLD:
		_show_status("SANCTIONS-PROOF WASH CYCLE", 1.45)
	else:
		_show_status("LOAD BECOMING ADMINISTRATIVELY UNBALANCED", 0.58)
	return true


func register_seal_hit(seal_index: int) -> bool:
	if not final_seals_active or seal_index < 0 or seal_index >= seal_health.size():
		return false
	if seal_health[seal_index] <= 0:
		return false
	shots_hit += 1
	seal_health[seal_index] -= 1
	seal_hit_flash[seal_index] = 0.22
	var seal := seal_nodes[seal_index] if seal_index < seal_nodes.size() else null
	if seal:
		seal.material_override = seal_damaged_material if seal_health[seal_index] > 0 else seal_ready_material
		seal.scale = Vector3.ONE * (1.34 if seal_health[seal_index] > 0 else 0.01)
	if seal_index < seal_target_nodes.size() and seal_health[seal_index] <= 0:
		seal_target_nodes[seal_index].visible = false
	hit_audio.pitch_scale = 1.08 + float(seal_index) * 0.12
	hit_audio.play()
	if _remaining_seals() == 0:
		_summon_strategic_bear()
	elif final_display_label:
		var remaining := _remaining_seals()
		final_display_label.text = "STAMP %d FLASHING SEAL%s" % [remaining, "" if remaining == 1 else "S"]
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
	world_environment.background_color = Color("#090d0c")
	world_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_environment.ambient_light_color = Color("#718078")
	world_environment.ambient_light_energy = 0.78
	world_environment.fog_enabled = true
	world_environment.fog_light_color = Color("#101716")
	world_environment.fog_density = 0.016
	environment_node = WorldEnvironment.new()
	environment_node.environment = world_environment
	world_root.add_child(environment_node)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-46, -24, 0)
	key_light.light_color = Color("#e5d2ae")
	key_light.light_energy = 1.05
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
	_build_strategic_bear_chamber()
	_build_gates()
	_build_final_display()
	_build_strategic_bear_target()


func _build_corridor() -> void:
	var floor_material := _make_material(Color("#2d3431"), Color.TRANSPARENT)
	var route_material := _make_material(Color("#3a423d"), Color.TRANSPARENT)
	var ceiling_material := _make_material(Color("#181d1c"), Color.TRANSPARENT)
	var wall_material := _make_material(Color("#414943"), Color.TRANSPARENT)
	var recess_material := _make_material(Color("#202827"), Color.TRANSPARENT)
	var seam_material := _make_material(Color("#171d1c"), Color.TRANSPARENT)
	var lane_material := _make_material(Color("#594923"), Color("#9c7d31"))
	var red_light_material := _make_material(Color("#4e1115"), Color("#c9272f"))
	var cyan_light_material := _make_material(Color("#243a3b"), Color("#78b6ba"))
	var banner_material := _make_material(Color("#59161a"), Color("#781b20"))
	var medal_material := _make_material(Color("#73571f"), Color("#c89b3c"))
	var cover_material := _make_material(Color("#4a514b"), Color.TRANSPARENT)
	var cover_trim_material := _make_material(Color("#697169"), Color.TRANSPARENT)

	_add_box("ConcreteFloor", Vector3(12.0, 0.18, 66.0), Vector3(0, -0.10, 32.0), floor_material)
	_add_box("CentralAdministrativeRoute", Vector3(5.9, 0.035, 64.0), Vector3(0, 0.005, 32.0), route_material)
	_add_box("LeftRouteEdge", Vector3(0.065, 0.045, 64.0), Vector3(-3.0, 0.03, 32.0), lane_material)
	_add_box("RightRouteEdge", Vector3(0.065, 0.045, 64.0), Vector3(3.0, 0.03, 32.0), lane_material)
	# The service ceiling ends before the final defense; the bear receives a
	# deliberately oversized requisition hall instead of being cropped by it.
	_add_box("LowCeiling", Vector3(12.0, 0.18, 58.0), Vector3(0, 3.25, 28.5), ceiling_material)
	_add_box("CeilingInset", Vector3(6.8, 0.055, 56.5), Vector3(0, 3.13, 28.25), recess_material)
	_add_box("LeftWall", Vector3(0.45, 3.35, 66.0), Vector3(-5.9, 1.58, 32.0), wall_material)
	_add_box("RightWall", Vector3(0.45, 3.35, 66.0), Vector3(5.9, 1.58, 32.0), wall_material)
	_add_box("RearWall", Vector3(12.0, 3.35, 0.45), Vector3(0, 1.58, 0.0), wall_material)
	_add_box("LeftWallBase", Vector3(0.08, 0.72, 64.0), Vector3(-5.63, 0.38, 32.0), recess_material)
	_add_box("RightWallBase", Vector3(0.08, 0.72, 64.0), Vector3(5.63, 0.38, 32.0), recess_material)
	_add_box("LeftPipe", Vector3(0.14, 0.14, 64.0), Vector3(-5.43, 2.66, 32.0), recess_material)
	_add_box("RightPipe", Vector3(0.14, 0.14, 64.0), Vector3(5.43, 2.66, 32.0), recess_material)

	for seam_index in range(1, 17):
		var seam_z := float(seam_index * 4)
		_add_box("FloorSeam%d" % seam_index, Vector3(11.0, 0.025, 0.045), Vector3(0, 0.01, seam_z), seam_material)
		if seam_index % 2 == 0:
			_add_box("GuidanceMark%d" % seam_index, Vector3(0.10, 0.04, 1.55), Vector3(0, 0.04, seam_z), lane_material)
			for side in [-1.0, 1.0]:
				_add_box("WallRib%d_%d" % [seam_index, int(side)], Vector3(0.26, 3.0, 0.34), Vector3(side * 5.51, 1.55, seam_z), recess_material)

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
		corridor_light.light_energy = 0.58
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

	# Ceremonial cover is useful, visually legible, and no longer floats as a bare box.
	for cover_index in range(COVER_POINTS.size()):
		var cover_root := Node3D.new()
		cover_root.name = "CeremonialCover%d" % (cover_index + 1)
		cover_root.position = COVER_POINTS[cover_index]
		world_root.add_child(cover_root)
		_add_box_to(cover_root, "ConcreteBlock", Vector3(1.25, 1.1, 0.8), Vector3.ZERO, cover_material)
		_add_box_to(cover_root, "TopCap", Vector3(1.34, 0.075, 0.87), Vector3(0, 0.55, 0), cover_trim_material)
		_add_box_to(cover_root, "InspectionStripe", Vector3(0.72, 0.11, 0.035), Vector3(0, 0.11, -0.42), red_light_material)


func _build_strategic_bear_chamber() -> void:
	var wall_material := _make_material(Color("#303834"), Color.TRANSPARENT)
	var wall_recess_material := _make_material(Color("#171d1c"), Color.TRANSPARENT)
	var ceiling_material := _make_material(Color("#151a19"), Color.TRANSPARENT)
	var floor_material := _make_material(Color("#242b28"), Color.TRANSPARENT)
	var red_material := _make_material(Color("#591419"), Color("#a51d24"))
	var brass_material := _make_material(Color("#6d5727"), Color("#c79a3e"))
	var washer_material := _make_material(Color("#a7a18d"), Color.TRANSPARENT)
	var washer_drum_material := _make_material(Color("#172326"), Color("#387781"))

	_add_box("StrategicReserveFloor", Vector3(11.2, 0.055, 7.4), Vector3(0, 0.025, 61.25), floor_material)
	_add_box("StrategicReserveRoute", Vector3(4.8, 0.035, 7.2), Vector3(0, 0.06, 61.25), red_material)
	_add_box("StrategicReserveCeiling", Vector3(12.0, 0.22, 7.8), Vector3(0, 7.05, 61.25), ceiling_material)
	_add_box("StrategicReserveLeftUpperWall", Vector3(0.45, 3.9, 7.8), Vector3(-5.9, 5.05, 61.25), wall_material)
	_add_box("StrategicReserveRightUpperWall", Vector3(0.45, 3.9, 7.8), Vector3(5.9, 5.05, 61.25), wall_material)
	_add_box("StrategicReserveRearWall", Vector3(12.0, 7.15, 0.32), Vector3(0, 3.5, 65.15), wall_material)
	_add_box("StrategicReserveRearRecess", Vector3(7.8, 3.9, 0.08), Vector3(0, 4.15, 64.96), wall_recess_material)

	for truss_index in range(3):
		var truss_z := 58.2 + float(truss_index) * 3.1
		_add_box("ReserveTruss%d" % truss_index, Vector3(11.4, 0.18, 0.22), Vector3(0, 6.52, truss_z), brass_material)
		_add_box("ReserveLeftColumn%d" % truss_index, Vector3(0.20, 3.3, 0.28), Vector3(-5.28, 4.88, truss_z), brass_material)
		_add_box("ReserveRightColumn%d" % truss_index, Vector3(0.20, 3.3, 0.28), Vector3(5.28, 4.88, truss_z), brass_material)

	# Confiscated domestic appliances form the ceremonial side gallery. Their
	# cold drums contrast with the warm parade lighting around the boss.
	for washer_index in range(4):
		var side := -1.0 if washer_index % 2 == 0 else 1.0
		var washer_z := 59.0 + float(washer_index / 2) * 3.7
		var washer_root := Node3D.new()
		washer_root.name = "RecoveredAppliance%d" % (washer_index + 1)
		washer_root.position = Vector3(side * 5.12, 1.22, washer_z)
		world_root.add_child(washer_root)
		recovered_appliance_roots.append(washer_root)
		_add_box_to(washer_root, "Cabinet", Vector3(0.70, 1.38, 1.15), Vector3.ZERO, washer_material)
		var drum_mesh := CylinderMesh.new()
		drum_mesh.top_radius = 0.36
		drum_mesh.bottom_radius = 0.36
		drum_mesh.height = 0.16
		drum_mesh.radial_segments = 18
		var drum := MeshInstance3D.new()
		drum.name = "InspectionDrum"
		drum.mesh = drum_mesh
		drum.material_override = washer_drum_material
		drum.rotation.z = PI * 0.5
		drum.position = Vector3(-side * 0.42, -0.08, 0)
		washer_root.add_child(drum)

	domestic_reserve_label = Label3D.new()
	domestic_reserve_label.name = "DomesticReserveLabel"
	domestic_reserve_label.text = "DOMESTIC STRATEGIC RESERVE"
	domestic_reserve_label.font_size = 58
	domestic_reserve_label.pixel_size = 0.010
	domestic_reserve_label.modulate = Color("#e4d3aa")
	domestic_reserve_label.outline_modulate = Color("#250507")
	domestic_reserve_label.outline_size = 10
	domestic_reserve_label.position = Vector3(0, 5.72, 64.72)
	domestic_reserve_label.rotation.y = PI
	world_root.add_child(domestic_reserve_label)

	for light_index in range(2):
		var chamber_light := OmniLight3D.new()
		chamber_light.name = "StrategicReserveLight%d" % (light_index + 1)
		chamber_light.position = Vector3(-2.8 + light_index * 5.6, 5.45, 61.2)
		chamber_light.light_color = Color("#e5b27f") if light_index == 0 else Color("#76b9bf")
		chamber_light.light_energy = 1.05
		chamber_light.omni_range = 8.0
		chamber_light.shadow_enabled = false
		world_root.add_child(chamber_light)

	var alarm_material := _make_material(Color("#6e0e13"), Color("#ff1f27"))
	for alarm_index in range(4):
		var side := -1.0 if alarm_index % 2 == 0 else 1.0
		var alarm_z := 59.2 + float(alarm_index / 2) * 3.8
		var alarm_strip := _add_box(
			"ReserveAlarmStrip%d" % (alarm_index + 1),
			Vector3(0.16, 1.25, 0.22),
			Vector3(side * 5.16, 4.18, alarm_z),
			alarm_material
		)
		alarm_strip.visible = false
		strategic_bear_alarm_strips.append(alarm_strip)

		var alarm_light := OmniLight3D.new()
		alarm_light.name = "ReserveAlarmLight%d" % (alarm_index + 1)
		alarm_light.position = Vector3(side * 4.55, 4.45, alarm_z)
		alarm_light.light_color = Color("#ff3138")
		alarm_light.light_energy = 0.0
		alarm_light.omni_range = 5.8
		alarm_light.shadow_enabled = false
		alarm_light.visible = false
		world_root.add_child(alarm_light)
		strategic_bear_alarm_lights.append(alarm_light)


func _activate_strategic_bear_alarm() -> void:
	if domestic_reserve_label:
		domestic_reserve_label.text = "DOMESTIC PRODUCTION SUCCESSFUL"
		domestic_reserve_label.modulate = Color("#ffb2a5")
	for strip in strategic_bear_alarm_strips:
		strip.visible = true
	for alarm_light in strategic_bear_alarm_lights:
		alarm_light.visible = true
	gate_audio.pitch_scale = 0.54
	gate_audio.play()


func _update_strategic_bear_alarm_presentation() -> void:
	if not strategic_bear_alarm_phase:
		return
	var pulse := 0.35 + 0.65 * absf(sin(elapsed * 6.4))
	for alarm_index in range(strategic_bear_alarm_lights.size()):
		var alarm_light := strategic_bear_alarm_lights[alarm_index]
		alarm_light.light_energy = 0.45 + pulse * 1.15
		alarm_light.visible = pulse > 0.48 or alarm_index % 2 == int(elapsed * 4.0) % 2
	for appliance_index in range(recovered_appliance_roots.size()):
		var appliance := recovered_appliance_roots[appliance_index]
		appliance.position.y = 1.22 + sin(elapsed * 22.0 + float(appliance_index)) * 0.035
		appliance.rotation.z = sin(elapsed * 18.0 + float(appliance_index) * 1.7) * 0.025
	if domestic_reserve_label:
		domestic_reserve_label.position.x = sin(elapsed * 12.0) * 0.045


func _reset_strategic_bear_alarm_presentation() -> void:
	if domestic_reserve_label:
		domestic_reserve_label.text = "DOMESTIC STRATEGIC RESERVE"
		domestic_reserve_label.modulate = Color("#e4d3aa")
		domestic_reserve_label.position.x = 0.0
	for strip in strategic_bear_alarm_strips:
		strip.visible = false
	for alarm_light in strategic_bear_alarm_lights:
		alarm_light.visible = false
		alarm_light.light_energy = 0.0
	for appliance in recovered_appliance_roots:
		appliance.position.y = 1.22
		appliance.rotation = Vector3.ZERO


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
	var board_material := _make_material(Color("#43483d"), Color.TRANSPARENT)
	var board_shadow_material := _make_material(Color("#252b26"), Color.TRANSPARENT)
	var trim_material := _make_material(Color("#70241f"), Color.TRANSPARENT)
	var edge_material := _make_material(Color("#77735d"), Color.TRANSPARENT)
	var target_material := _make_material(Color("#6d1115"), Color("#ff3a3f"))
	seal_ready_material = _make_material(Color("#8d1718"), Color("#ff3038"))
	seal_damaged_material = _make_material(Color("#9a5a12"), Color("#ffc43d"))
	_add_box_to(final_display, "DefenseShadow", Vector3(8.2, 2.65, 0.12), Vector3(0, 1.32, 0.02), board_shadow_material)
	_add_box_to(final_display, "TankCardboardBody", Vector3(7.6, 1.62, 0.18), Vector3(0, 1.0, -0.28), board_material)
	_add_box_to(final_display, "TankCardboardTurret", Vector3(3.5, 0.9, 0.20), Vector3(0, 2.18, -0.3), board_material)
	_add_box_to(final_display, "PaintedCannon", Vector3(0.34, 0.34, 3.0), Vector3(0, 2.22, -1.65), trim_material)
	_add_box_to(final_display, "CardboardTopEdge", Vector3(7.75, 0.08, 0.08), Vector3(0, 1.83, -0.42), edge_material)
	_add_box_to(final_display, "AuthorizationPanel", Vector3(6.3, 1.15, 0.09), Vector3(0, 1.45, -0.46), board_shadow_material)
	for wheel_index in range(5):
		_add_box_to(final_display, "PaintedWheel%d" % wheel_index, Vector3(0.95, 0.58, 0.12), Vector3(-2.4 + wheel_index * 1.2, 0.38, -0.42), trim_material)

	for seal_index in range(3):
		var seal_mesh := SphereMesh.new()
		seal_mesh.radius = 0.39
		seal_mesh.height = 0.78
		seal_mesh.radial_segments = 18
		seal_mesh.rings = 8
		var seal := MeshInstance3D.new()
		seal.name = "AuthorizationSeal%d" % (seal_index + 1)
		seal.mesh = seal_mesh
		seal.material_override = seal_ready_material
		seal.position = Vector3(-2.2 + seal_index * 2.2, 1.43 + (0.34 if seal_index == 1 else 0.0), -0.65)
		final_display.add_child(seal)
		seal_nodes.append(seal)

		var target_root := Node3D.new()
		target_root.name = "SealTarget%d" % (seal_index + 1)
		target_root.position = seal.position + Vector3(0, 0, -0.05)
		target_root.visible = false
		final_display.add_child(target_root)
		_add_box_to(target_root, "TopBracket", Vector3(0.52, 0.075, 0.055), Vector3(0, 0.58, 0), target_material)
		_add_box_to(target_root, "BottomBracket", Vector3(0.52, 0.075, 0.055), Vector3(0, -0.58, 0), target_material)
		_add_box_to(target_root, "LeftBracket", Vector3(0.075, 0.52, 0.055), Vector3(-0.58, 0, 0), target_material)
		_add_box_to(target_root, "RightBracket", Vector3(0.075, 0.52, 0.055), Vector3(0.58, 0, 0), target_material)
		seal_target_nodes.append(target_root)

	final_display_label = Label3D.new()
	final_display_label.name = "DisplayLabel"
	final_display_label.text = "POTEMKIN DEFENSE"
	final_display_label.font_size = 52
	final_display_label.pixel_size = 0.009
	final_display_label.modulate = Color("#e8d9b5")
	final_display_label.outline_modulate = Color.BLACK
	final_display_label.outline_size = 8
	final_display_label.position = Vector3(0, 2.92, -0.5)
	final_display_label.rotation.y = PI
	final_display.add_child(final_display_label)

	var final_light := OmniLight3D.new()
	final_light.name = "PotemkinInspectionLight"
	final_light.position = Vector3(0, 2.45, -2.2)
	final_light.light_color = Color("#d54a43")
	final_light.light_energy = 0.72
	final_light.omni_range = 7.5
	final_light.shadow_enabled = false
	final_display.add_child(final_light)


func _build_strategic_bear_target() -> void:
	strategic_bear_target = Node3D.new()
	strategic_bear_target.name = "StrategicBearDrumTarget"
	strategic_bear_target.position = STRATEGIC_BEAR_TARGET_POSITION
	strategic_bear_target.visible = false
	world_root.add_child(strategic_bear_target)
	var target_material := _make_material(Color("#5f1114"), Color("#ff3138"))
	_add_box_to(strategic_bear_target, "TopBracket", Vector3(0.84, 0.09, 0.07), Vector3(0, 0.82, 0), target_material)
	_add_box_to(strategic_bear_target, "BottomBracket", Vector3(0.84, 0.09, 0.07), Vector3(0, -0.82, 0), target_material)
	_add_box_to(strategic_bear_target, "LeftBracket", Vector3(0.09, 0.84, 0.07), Vector3(-0.82, 0, 0), target_material)
	_add_box_to(strategic_bear_target, "RightBracket", Vector3(0.09, 0.84, 0.07), Vector3(0.82, 0, 0), target_material)


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

	seal_caption_label = Label.new()
	seal_caption_label.position = Vector2(724, 17)
	seal_caption_label.size = Vector2(64, 42)
	seal_caption_label.text = "SEALS"
	seal_caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seal_caption_label.add_theme_font_size_override("font_size", 16)
	seal_caption_label.add_theme_color_override("font_color", Color("#b9ad94"))
	seal_caption_label.z_index = 31
	frame.add_child(seal_caption_label)

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
	muzzle_flash.position = Vector2(608, 350)
	muzzle_flash.size = Vector2(64, 96)
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
	var cutout_shader := Shader.new()
	cutout_shader.code = WEAPON_CUTOUT_SHADER
	var cutout_material := ShaderMaterial.new()
	cutout_material.shader = cutout_shader
	weapon_rect.material = cutout_material
	weapon_rect.z_index = 37
	frame.add_child(weapon_rect)


func _create_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "SpecialOperationMusic"
	music_player.volume_db = -4.0
	if ResourceLoader.exists(MUSIC_PATH):
		music_player.stream = load(MUSIC_PATH)
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	shot_audio = AudioStreamPlayer.new()
	shot_audio.stream = _make_tone(92.0, 0.13, 0.42)
	shot_audio.volume_db = -1.0
	add_child(shot_audio)
	reload_audio = AudioStreamPlayer.new()
	reload_audio.stream = _make_tone(146.0, 0.24, 0.26)
	reload_audio.volume_db = -2.5
	add_child(reload_audio)
	hit_audio = AudioStreamPlayer.new()
	hit_audio.stream = _make_tone(310.0, 0.11, 0.22)
	hit_audio.volume_db = -2.0
	add_child(hit_audio)
	damage_audio = AudioStreamPlayer.new()
	damage_audio.stream = _make_tone(58.0, 0.22, 0.58)
	damage_audio.volume_db = -1.0
	add_child(damage_audio)
	gate_audio = AudioStreamPlayer.new()
	gate_audio.stream = _make_tone(178.0, 0.38, 0.18)
	gate_audio.volume_db = -2.5
	add_child(gate_audio)
	success_audio = AudioStreamPlayer.new()
	success_audio.stream = _make_tone(660.0, 0.48, 0.02)
	success_audio.volume_db = -2.0
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
	seal_hit_flash = [0.0, 0.0, 0.0]
	final_seals_resolved = false
	strategic_bear_id = ""
	strategic_bear_active = false
	strategic_bear_defeated = false
	strategic_bear_departure_active = false
	strategic_bear_departure_timer = 0.0
	strategic_bear_departure_stage = 0
	strategic_bear_hits = 0
	strategic_bear_alarm_phase = false
	_reset_strategic_bear_alarm_presentation()
	if hit_audio:
		hit_audio.pitch_scale = 1.0
	if gate_audio:
		gate_audio.pitch_scale = 1.0
	if music_player and music_player.stream:
		music_player.play()
	final_seals_active = false
	_clear_enemies()
	if strategic_bear_target:
		strategic_bear_target.visible = false
		strategic_bear_target.position = STRATEGIC_BEAR_TARGET_POSITION
		strategic_bear_target.scale = Vector3.ONE
		strategic_bear_target.rotation = Vector3.ZERO
	if seal_caption_label:
		seal_caption_label.text = "SEALS"
	for gate_index in range(gate_nodes.size()):
		gate_nodes[gate_index].visible = true
	if final_display:
		final_display.visible = true
	for seal in seal_nodes:
		seal.visible = true
		seal.scale = Vector3.ONE
		seal.material_override = seal_ready_material
	for target in seal_target_nodes:
		target.visible = false
		target.scale = Vector3.ONE
		target.rotation = Vector3.ZERO
	if final_display_label:
		final_display_label.text = "POTEMKIN DEFENSE"
		final_display_label.modulate = Color("#e8d9b5")
	_spawn_wave(0)
	status_label.text = "W/S ADVANCE  //  A/D STRAFE  //  ARROWS AIM  //  SPACE STAMP"
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
	_update_enemy_projectiles(delta)
	_update_strategic_bear_alarm_presentation()
	_update_strategic_bear_departure(delta)
	_update_gate_progress()
	_update_camera()
	if gate_open[2] and player_position.z >= 61.2:
		_begin_cleared()


func _process_player_input(delta: float) -> void:
	var turn_input := 0.0
	if Input.is_action_pressed("ui_left"):
		turn_input += 1.0
	if Input.is_action_pressed("ui_right"):
		turn_input -= 1.0
	player_yaw += turn_input * TURN_SPEED * delta

	var forward_input := 0.0
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(Key.KEY_W):
		forward_input += 1.0
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(Key.KEY_S):
		forward_input -= 1.0
	var strafe_input := 0.0
	if Input.is_physical_key_pressed(Key.KEY_D) or Input.is_physical_key_pressed(Key.KEY_E):
		strafe_input += 1.0
	if Input.is_physical_key_pressed(Key.KEY_A) or Input.is_physical_key_pressed(Key.KEY_Q):
		strafe_input -= 1.0
	var forward := _forward_vector()
	var right := _right_vector()
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
	var previous := player_position
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
	if _position_hits_cover(candidate, PLAYER_RADIUS):
		var slide_x := Vector3(candidate.x, candidate.y, previous.z)
		var slide_z := Vector3(previous.x, candidate.y, candidate.z)
		if not _position_hits_cover(slide_x, PLAYER_RADIUS):
			candidate = slide_x
		elif not _position_hits_cover(slide_z, PLAYER_RADIUS):
			candidate = slide_z
		else:
			candidate = previous
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
		if register_enemy_hit(str(enemies[best_index].get("id", ""))):
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
	var attack_interval := 2.9
	var attack_windup := 0.8
	var projectile_speed := 4.7
	var projectile_radius := 0.38
	var target_radius := 0.92
	var sprite_height := 2.55
	match enemy_type:
		"matryoshka":
			texture_path = MATRYOSHKA_PATH
			hp = 3
			speed = 0.58
			attack_range = 6.1
			attack_interval = 3.2
			attack_windup = 0.95
			projectile_speed = 4.2
			projectile_radius = 0.44
			target_radius = 1.02
			sprite_height = 2.95
		"matryoshka_small":
			texture_path = MATRYOSHKA_PATH
			hp = 1
			speed = 1.12
			attack_range = 4.8
			attack_interval = 3.0
			attack_windup = 0.75
			projectile_speed = 4.5
			projectile_radius = 0.32
			target_radius = 0.62
			sprite_height = 1.72
		"state_camera":
			texture_path = CAMERA_PATH
			hp = 2
			speed = 0.24
			attack_range = 12.5
			attack_interval = 3.5
			attack_windup = 1.1
			projectile_speed = 3.6
			projectile_radius = 0.58
			target_radius = 0.88
			sprite_height = 2.72
		"strategic_bear":
			texture_path = STRATEGIC_BEAR_PATH
			hp = STRATEGIC_BEAR_MAX_HEALTH
			speed = 0.0
			attack_range = 18.0
			attack_interval = 1.15
			attack_windup = 1.0
			projectile_speed = 4.0
			projectile_radius = 0.62
			target_radius = 1.35
			sprite_height = 4.7

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
		"attack_windup": attack_windup,
		"projectile_speed": projectile_speed,
		"projectile_radius": projectile_radius,
		"attack_timer": 1.4 + float(enemy_sequence % 4) * 0.2,
		"attack_state": "idle",
		"telegraph_timer": 0.0,
		"locked_target": START_POSITION,
		"secondary_locked_target": START_POSITION,
		"telegraph_node": null,
		"telegraph_node_secondary": null,
		"double_attack": false,
		"target_radius": target_radius,
		"wave": wave_index,
		"blocks_gate": blocks_gate,
		"alive": true,
		"hit_flash": 0.0,
		"vulnerable": false,
		"reload_timer": 0.0,
		"reload_hits": 0,
		"cycle_index": 0,
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
		var enemy_type := str(enemy.get("type", ""))
		var attack_state := str(enemy.get("attack_state", "idle"))
		if enemy_type == "strategic_bear" and strategic_bear_alarm_phase and attack_state in ["idle", "reload"]:
			var alarm_position := enemy.get("position", STRATEGIC_BEAR_POSITION) as Vector3
			alarm_position.x = sin(elapsed * 1.45) * STRATEGIC_BEAR_ALARM_STRAFE_DISTANCE
			enemy["position"] = alarm_position
		if enemy_type == "strategic_bear" and attack_state == "reload":
			enemy["reload_timer"] = maxf(0.0, float(enemy.get("reload_timer", 0.0)) - delta)
			enemy["hit_flash"] = maxf(0.0, float(enemy.get("hit_flash", 0.0)) - delta)
			var reload_pulse := 0.92 + 0.08 * absf(sin(elapsed * 14.0))
			sprite.scale = Vector3.ONE * reload_pulse
			var reload_position := enemy.get("position", STRATEGIC_BEAR_POSITION) as Vector3
			sprite.position.x = reload_position.x + sin(elapsed * 5.0) * 0.08
			if float(enemy.get("hit_flash", 0.0)) <= 0.0:
				sprite.modulate = Color.WHITE
			if strategic_bear_target:
				strategic_bear_target.position.x = sprite.position.x
				strategic_bear_target.scale = Vector3.ONE * (0.92 + 0.12 * absf(sin(elapsed * 12.0)))
			if float(enemy.get("reload_timer", 0.0)) <= 0.0:
				enemy["attack_state"] = "idle"
				enemy["attack_timer"] = 0.82
				enemy["vulnerable"] = false
				sprite.scale = Vector3.ONE
				if strategic_bear_target:
					strategic_bear_target.visible = false
			enemies[index] = enemy
			continue
		if str(enemy.get("attack_state", "idle")) == "telegraph":
			enemy["telegraph_timer"] = maxf(0.0, float(enemy.get("telegraph_timer", 0.0)) - delta)
			var telegraph := enemy.get("telegraph_node") as MeshInstance3D
			if telegraph and is_instance_valid(telegraph):
				var pulse := 0.78 + 0.22 * absf(sin(elapsed * 16.0))
				telegraph.scale.x = pulse
				var secondary_telegraph := enemy.get("telegraph_node_secondary") as MeshInstance3D
				if secondary_telegraph and is_instance_valid(secondary_telegraph):
					secondary_telegraph.scale.x = pulse
			sprite.modulate = Color("#ffb0a1") if int(elapsed * 12.0) % 2 == 0 else Color.WHITE
			enemies[index] = enemy
			if float(enemy.get("telegraph_timer", 0.0)) <= 0.0:
				_release_enemy_projectile(index)
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
		enemies[index] = enemy
		if (
			distance <= float(enemy.get("attack_range", 7.0))
			and float(enemy.get("attack_timer", 0.0)) <= 0.0
			and _active_threat_count() < MAX_ACTIVE_THREATS
		):
			_begin_enemy_telegraph(index)


func _begin_enemy_telegraph(index: int) -> bool:
	if index < 0 or index >= enemies.size() or state != State.ACTIVE:
		return false
	if _active_threat_count() >= MAX_ACTIVE_THREATS:
		return false
	var enemy: Dictionary = enemies[index]
	if not bool(enemy.get("alive", false)) or str(enemy.get("attack_state", "idle")) != "idle":
		return false
	enemy["double_attack"] = false
	if str(enemy.get("type", "")) == "strategic_bear":
		var cycle := int(enemy.get("cycle_index", 0)) % 3
		enemy["cycle_index"] = cycle + 1
		match cycle:
			0:
				enemy["attack_windup"] = 0.95
				enemy["projectile_speed"] = 4.0
				enemy["projectile_radius"] = 0.58
				_show_status("SPIN CYCLE — MOVE", 0.9)
			1:
				enemy["attack_windup"] = 1.12
				enemy["projectile_speed"] = 3.65
				enemy["projectile_radius"] = 0.76
				_show_status("RINSE CYCLE — MOVE", 1.05)
			_:
				enemy["attack_windup"] = 1.28
				enemy["projectile_speed"] = 4.45
				enemy["projectile_radius"] = 0.52
				_show_status("HEAVY LOAD — MOVE", 1.18)
		if strategic_bear_alarm_phase:
			enemy["attack_windup"] = maxf(0.78, float(enemy.get("attack_windup", 1.0)) * 0.84)
			enemy["projectile_speed"] = float(enemy.get("projectile_speed", 4.0)) + 0.35
			enemy["double_attack"] = cycle != 1
			_show_status(
				"ALARM — DOUBLE SPIN — MOVE" if bool(enemy["double_attack"]) else "ALARM — FAST CYCLE — MOVE",
				float(enemy["attack_windup"])
			)
	var locked_target := Vector3(player_position.x, 1.1, player_position.z)
	var position := enemy.get("position", Vector3.ZERO) as Vector3
	var telegraph := _create_warning_lane(position, locked_target, str(enemy.get("type", "")))
	var secondary_target := locked_target
	var secondary_telegraph: MeshInstance3D
	if bool(enemy.get("double_attack", false)):
		var offset_direction := -1.0 if player_position.x >= 0.0 else 1.0
		secondary_target.x = clampf(
			locked_target.x + offset_direction * 2.15,
			-CORRIDOR_HALF_WIDTH + PLAYER_RADIUS,
			CORRIDOR_HALF_WIDTH - PLAYER_RADIUS
		)
		secondary_telegraph = _create_warning_lane(position, secondary_target, "strategic_bear")
	enemy["attack_state"] = "telegraph"
	enemy["telegraph_timer"] = float(enemy.get("attack_windup", 0.9))
	enemy["locked_target"] = locked_target
	enemy["secondary_locked_target"] = secondary_target
	enemy["telegraph_node"] = telegraph
	enemy["telegraph_node_secondary"] = secondary_telegraph
	enemies[index] = enemy
	return true


func _create_warning_lane(start: Vector3, target: Vector3, enemy_type: String) -> MeshInstance3D:
	var delta := Vector3(target.x - start.x, 0.0, target.z - start.z)
	var full_distance := maxf(delta.length(), 0.1)
	var direction := delta / full_distance
	var visible_target := target - direction * minf(1.85, full_distance * 0.45)
	var visible_delta := Vector3(visible_target.x - start.x, 0.0, visible_target.z - start.z)
	var distance := maxf(visible_delta.length(), 0.1)
	var width := 0.16
	var color := Color("#f04c35")
	if enemy_type == "state_camera":
		width = 0.55
		color = Color("#29c8df")
	elif enemy_type == "mobilization_copier":
		width = 0.22
		color = Color("#d7ad37")
	elif enemy_type == "strategic_bear":
		width = 0.92
		color = Color("#55d7e8")
	var material := _make_material(color.darkened(0.45), color)
	var lane := _add_box("IncomingAdministrativeLane", Vector3(width, 0.045, distance), Vector3.ZERO, material)
	lane.position = Vector3((start.x + visible_target.x) * 0.5, 0.075, (start.z + visible_target.z) * 0.5)
	lane.rotation.y = atan2(visible_delta.x, visible_delta.z)
	return lane


func _release_enemy_projectile(index: int) -> bool:
	if index < 0 or index >= enemies.size():
		return false
	var enemy: Dictionary = enemies[index]
	if not bool(enemy.get("alive", false)) or str(enemy.get("attack_state", "idle")) != "telegraph":
		return false
	var telegraph := enemy.get("telegraph_node") as MeshInstance3D
	if telegraph and is_instance_valid(telegraph):
		telegraph.queue_free()
	var secondary_telegraph := enemy.get("telegraph_node_secondary") as MeshInstance3D
	if secondary_telegraph and is_instance_valid(secondary_telegraph):
		secondary_telegraph.queue_free()
	enemy["telegraph_node"] = null
	enemy["telegraph_node_secondary"] = null
	var enemy_type := str(enemy.get("type", ""))
	if enemy_type == "strategic_bear":
		enemy["attack_state"] = "reload"
		enemy["reload_timer"] = STRATEGIC_BEAR_ALARM_RELOAD_DURATION if strategic_bear_alarm_phase else STRATEGIC_BEAR_RELOAD_DURATION
		enemy["reload_hits"] = 0
		enemy["vulnerable"] = true
		if strategic_bear_target:
			strategic_bear_target.visible = true
		_show_status(
			"ALARM RELOAD — ONE STAMP" if strategic_bear_alarm_phase else "RELOAD — STAMP THE OPEN DRUM",
			1.35 if strategic_bear_alarm_phase else 1.8
		)
	else:
		enemy["attack_state"] = "idle"
		enemy["attack_timer"] = float(enemy.get("attack_interval", 3.0))
	var start_source := enemy.get("position", Vector3.ZERO) as Vector3
	var start := Vector3(start_source.x, 1.12, start_source.z)
	var speed := float(enemy.get("projectile_speed", 4.2))
	var radius := float(enemy.get("projectile_radius", 0.4))
	_append_enemy_projectile(enemy_type, start, enemy.get("locked_target", player_position) as Vector3, speed, radius)
	if bool(enemy.get("double_attack", false)):
		_append_enemy_projectile(
			enemy_type,
			start,
			enemy.get("secondary_locked_target", player_position) as Vector3,
			speed,
			radius * 0.88,
			0.42
		)
	var sprite := enemy.get("node") as Sprite3D
	if sprite:
		sprite.modulate = Color.WHITE
	enemies[index] = enemy
	return true


func _append_enemy_projectile(
	enemy_type: String,
	start: Vector3,
	target: Vector3,
	speed: float,
	radius: float,
	delay: float = 0.0
) -> void:
	var flat_direction := Vector3(target.x - start.x, 0.0, target.z - start.z)
	if flat_direction.length_squared() <= 0.001:
		flat_direction = Vector3(0.0, 0.0, -1.0)
	flat_direction = flat_direction.normalized()
	var visual := _create_enemy_projectile_visual(enemy_type)
	visual.position = start
	visual.visible = delay <= 0.0
	projectile_sequence += 1
	enemy_projectiles.append({
		"id": "incoming_form_%02d" % projectile_sequence,
		"type": enemy_type,
		"node": visual,
		"position": start,
		"velocity": flat_direction * speed,
		"radius": radius,
		"delay": delay,
		"lifetime": PROJECTILE_LIFETIME,
	})


func _create_enemy_projectile_visual(enemy_type: String) -> Node3D:
	var visual := Node3D.new()
	visual.name = "IncomingAdministrativeMaterial"
	world_root.add_child(visual)
	match enemy_type:
		"strategic_bear":
			var drum_shell := _make_material(Color("#d8d0bd"), Color("#438b96"))
			var drum_warning := _make_material(Color("#8c171c"), Color("#ff3538"))
			var drum_mesh := CylinderMesh.new()
			drum_mesh.top_radius = 0.44
			drum_mesh.bottom_radius = 0.44
			drum_mesh.height = 0.24
			drum_mesh.radial_segments = 18
			var drum := MeshInstance3D.new()
			drum.name = "WeaponizedSpinCycle"
			drum.mesh = drum_mesh
			drum.material_override = drum_shell
			drum.rotation.x = PI * 0.5
			visual.add_child(drum)
			_add_box_to(visual, "UnbalancedLoad", Vector3(0.72, 0.10, 0.12), Vector3(0, 0.0, -0.18), drum_warning)
		"mobilization_copier":
			var paper := _make_material(Color("#ded4b4"), Color("#766e52"))
			var urgent := _make_material(Color("#9d2020"), Color("#ff3434"))
			_add_box_to(visual, "CompulsoryForm", Vector3(0.68, 0.10, 0.46), Vector3.ZERO, paper)
			_add_box_to(visual, "UrgentMargin", Vector3(0.70, 0.05, 0.10), Vector3(0.0, 0.08, 0.12), urgent)
		"state_camera":
			var scan := _make_material(Color("#176d7c"), Color("#35e2f6"))
			var lens := _make_material(Color("#22282b"), Color("#d5fbff"))
			_add_box_to(visual, "MandatoryBroadcast", Vector3(1.18, 0.18, 0.22), Vector3.ZERO, scan)
			_add_box_to(visual, "ApprovedLens", Vector3(0.26, 0.23, 0.25), Vector3(0.0, 0.0, -0.02), lens)
		_:
			var seal_mesh := SphereMesh.new()
			seal_mesh.radius = 0.27 if enemy_type == "matryoshka" else 0.21
			seal_mesh.height = seal_mesh.radius * 2.0
			var seal := MeshInstance3D.new()
			seal.name = "PreApprovedSeal"
			seal.mesh = seal_mesh
			seal.material_override = _make_material(Color("#8d1718"), Color("#ff3038"))
			visual.add_child(seal)
	return visual


func _update_enemy_projectiles(delta: float) -> void:
	if not combat_enabled:
		return
	for index in range(enemy_projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = enemy_projectiles[index]
		var visual := projectile.get("node") as Node3D
		var launch_delay := maxf(0.0, float(projectile.get("delay", 0.0)) - delta)
		projectile["delay"] = launch_delay
		if launch_delay > 0.0:
			if visual and is_instance_valid(visual):
				visual.visible = false
			enemy_projectiles[index] = projectile
			continue
		if visual and is_instance_valid(visual):
			visual.visible = true
		var previous := projectile.get("position", Vector3.ZERO) as Vector3
		var velocity := projectile.get("velocity", Vector3.ZERO) as Vector3
		var next_position := previous + velocity * delta
		projectile["position"] = next_position
		projectile["lifetime"] = float(projectile.get("lifetime", 0.0)) - delta
		if visual and is_instance_valid(visual):
			visual.position = next_position
			if str(projectile.get("type", "")) != "state_camera":
				visual.rotation.z += delta * 3.4
		var radius := float(projectile.get("radius", 0.4))
		if _segment_hits_cover(previous, next_position, radius):
			_remove_enemy_projectile(index)
			continue
		if _segment_distance_xz(previous, next_position, player_position) <= PLAYER_HIT_RADIUS + radius:
			_enemy_attack(str(projectile.get("type", "")))
			_remove_enemy_projectile(index)
			continue
		if float(projectile.get("lifetime", 0.0)) <= 0.0:
			_remove_enemy_projectile(index)
			continue
		enemy_projectiles[index] = projectile


func _active_threat_count() -> int:
	var count := enemy_projectiles.size()
	for enemy in enemies:
		if bool(enemy.get("alive", false)) and str(enemy.get("attack_state", "idle")) == "telegraph":
			count += 1
	return count


func _position_hits_cover(position: Vector3, clearance: float = 0.0) -> bool:
	for cover in COVER_POINTS:
		if (
			absf(position.x - cover.x) <= COVER_HALF_SIZE.x + clearance
			and absf(position.z - cover.z) <= COVER_HALF_SIZE.y + clearance
		):
			return true
	return false


func _segment_hits_cover(start: Vector3, finish: Vector3, radius: float) -> bool:
	for cover in COVER_POINTS:
		var half_size := COVER_HALF_SIZE + Vector2(radius, radius)
		if _segment_intersects_rect_xz(start, finish, cover, half_size):
			return true
	return false


func _segment_intersects_rect_xz(start: Vector3, finish: Vector3, center: Vector3, half_size: Vector2) -> bool:
	var delta := finish - start
	var t_min := 0.0
	var t_max := 1.0
	var min_x := center.x - half_size.x
	var max_x := center.x + half_size.x
	if absf(delta.x) < 0.0001:
		if start.x < min_x or start.x > max_x:
			return false
	else:
		var tx1 := (min_x - start.x) / delta.x
		var tx2 := (max_x - start.x) / delta.x
		if tx1 > tx2:
			var swap_x := tx1
			tx1 = tx2
			tx2 = swap_x
		t_min = maxf(t_min, tx1)
		t_max = minf(t_max, tx2)
		if t_min > t_max:
			return false
	var min_z := center.z - half_size.y
	var max_z := center.z + half_size.y
	if absf(delta.z) < 0.0001:
		return start.z >= min_z and start.z <= max_z
	var tz1 := (min_z - start.z) / delta.z
	var tz2 := (max_z - start.z) / delta.z
	if tz1 > tz2:
		var swap_z := tz1
		tz1 = tz2
		tz2 = swap_z
	t_min = maxf(t_min, tz1)
	t_max = minf(t_max, tz2)
	return t_min <= t_max


func _segment_distance_xz(start: Vector3, finish: Vector3, point: Vector3) -> float:
	var segment := Vector2(finish.x - start.x, finish.z - start.z)
	var to_point := Vector2(point.x - start.x, point.z - start.z)
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return to_point.length()
	var amount := clampf(to_point.dot(segment) / length_squared, 0.0, 1.0)
	return (to_point - segment * amount).length()


func _remove_enemy_projectile(index: int) -> void:
	if index < 0 or index >= enemy_projectiles.size():
		return
	var visual := enemy_projectiles[index].get("node") as Node3D
	if visual and is_instance_valid(visual):
		visual.queue_free()
	enemy_projectiles.remove_at(index)


func _enemy_attack(enemy_type: String) -> void:
	if invulnerability_remaining > 0.0 or state != State.ACTIVE:
		return
	case_integrity -= 1
	damage_taken += 1
	invulnerability_remaining = 1.05
	damage_flash.color = Color(0.85, 0.04, 0.02, 0.62)
	if enemy_type == "state_camera":
		damage_flash.color = Color(0.04, 0.67, 0.76, 0.46)
	elif enemy_type == "mobilization_copier":
		damage_flash.color = Color(0.92, 0.86, 0.68, 0.52)
	elif enemy_type == "strategic_bear":
		damage_flash.color = Color(0.18, 0.70, 0.78, 0.52)
	damage_audio.play()
	if case_integrity <= 0:
		_begin_returned()


func _destroy_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index]
	if not bool(enemy.get("alive", false)):
		return
	var telegraph := enemy.get("telegraph_node") as MeshInstance3D
	if telegraph and is_instance_valid(telegraph):
		telegraph.queue_free()
	var secondary_telegraph := enemy.get("telegraph_node_secondary") as MeshInstance3D
	if secondary_telegraph and is_instance_valid(secondary_telegraph):
		secondary_telegraph.queue_free()
	enemy["telegraph_node_secondary"] = null
	enemy["telegraph_node"] = null
	enemy["attack_state"] = "idle"
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


func _summon_strategic_bear() -> void:
	if final_seals_resolved or strategic_bear_active or strategic_bear_defeated:
		return
	final_seals_active = false
	final_seals_resolved = true
	if final_display:
		final_display.visible = false
	if gate_nodes.size() > 2:
		# The slab disappears visually to reveal the arena, while its traversal
		# boundary remains closed until the appliance exits.
		gate_nodes[2].visible = false
	for target in seal_target_nodes:
		target.visible = false
	_clear_enemy_projectiles()
	for enemy_index in range(enemies.size()):
		var remaining_enemy: Dictionary = enemies[enemy_index]
		if str(remaining_enemy.get("type", "")) != "state_camera" or not bool(remaining_enemy.get("alive", false)):
			continue
		remaining_enemy["alive"] = false
		var remaining_camera := remaining_enemy.get("node") as Sprite3D
		if remaining_camera:
			remaining_camera.visible = false
		enemies[enemy_index] = remaining_enemy
	strategic_bear_active = true
	strategic_bear_id = _spawn_enemy("strategic_bear", STRATEGIC_BEAR_POSITION, 2, true)
	if seal_caption_label:
		seal_caption_label.text = "LOAD"
	_show_status("FINAL DEFENSE — STRATEGIC BEAR", 1.55)
	gate_audio.pitch_scale = 0.72
	gate_audio.play()


func _defeat_strategic_bear(index: int) -> void:
	if index < 0 or index >= enemies.size() or strategic_bear_defeated:
		return
	var enemy: Dictionary = enemies[index]
	enemy["hp"] = 0
	enemy["alive"] = false
	enemy["vulnerable"] = false
	enemy["attack_state"] = "departing"
	var telegraph := enemy.get("telegraph_node") as MeshInstance3D
	if telegraph and is_instance_valid(telegraph):
		telegraph.queue_free()
	var secondary_telegraph := enemy.get("telegraph_node_secondary") as MeshInstance3D
	if secondary_telegraph and is_instance_valid(secondary_telegraph):
		secondary_telegraph.queue_free()
	enemy["telegraph_node_secondary"] = null
	enemy["telegraph_node"] = null
	enemies[index] = enemy
	strategic_bear_active = false
	strategic_bear_defeated = true
	strategic_bear_departure_active = true
	strategic_bear_departure_timer = 0.0
	strategic_bear_departure_stage = 0
	if strategic_bear_target:
		strategic_bear_target.visible = false
	_clear_enemy_projectiles()
	_show_status("FINAL SPIN", 0.75)
	gate_audio.pitch_scale = 1.28
	gate_audio.play()


func _update_strategic_bear_departure(delta: float) -> void:
	if not strategic_bear_departure_active:
		return
	strategic_bear_departure_timer += delta
	var progress := clampf(strategic_bear_departure_timer / STRATEGIC_BEAR_DEPARTURE_DURATION, 0.0, 1.0)
	var sprite: Sprite3D
	for enemy in enemies:
		if str(enemy.get("id", "")) == strategic_bear_id:
			sprite = enemy.get("node") as Sprite3D
			break
	if sprite:
		var vibration := sin(strategic_bear_departure_timer * 34.0) * (0.06 + progress * 0.10)
		sprite.position.x = progress * progress * 8.5 + vibration
		sprite.rotation.z = vibration * 0.5 + progress * 0.22
		sprite.scale = Vector3.ONE * (1.0 + absf(vibration) * 0.25)
	if strategic_bear_departure_stage == 0 and strategic_bear_departure_timer >= 0.52:
		strategic_bear_departure_stage = 1
		_show_status("LOAD UNBALANCED", 1.0)
	if strategic_bear_departure_timer < STRATEGIC_BEAR_DEPARTURE_DURATION:
		return
	strategic_bear_departure_active = false
	strategic_bear_departure_stage = 2
	if sprite:
		sprite.visible = false
	_open_final_defense()


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
		elif not final_seals_active and not final_seals_resolved:
			_activate_final_seals()


func _activate_final_seals() -> void:
	if final_seals_resolved:
		return
	final_seals_active = true
	if seal_caption_label:
		seal_caption_label.text = "SEALS"
	for target in seal_target_nodes:
		target.visible = true
	if final_display_label:
		final_display_label.text = "STAMP 3 FLASHING SEALS"
		final_display_label.modulate = Color("#ffdf9b")
	_show_status("STAMP THE THREE FLASHING AUTHORIZATION SEALS", 2.25)
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
	_show_status("APPLIANCE RELOCATION COMPLETE", 1.5)
	gate_audio.play()


func _begin_returned() -> void:
	state = State.RETURNED
	state_timer = 0.0
	_clear_enemy_projectiles()
	_clear_enemy_telegraphs()
	status_label.text = "OPERATION RESTARTED ACCORDING TO PLAN"
	fire_label.text = ""


func _begin_cleared() -> void:
	state = State.CLEARED
	state_timer = 0.0
	_clear_enemy_projectiles()
	_clear_enemy_telegraphs()
	if music_player:
		music_player.stop()
	status_label.text = "SPECIAL OPERATION COMPLETED"
	fire_label.text = "EVERYTHING PROCEEDED ACCORDING TO PLAN"
	success_audio.play()


func _finish_success() -> void:
	if music_player:
		music_player.stop()
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
		"strategic_bear_defeated": strategic_bear_defeated,
		"strategic_bear_hits": strategic_bear_hits,
		"strategic_bear_alarm_phase": strategic_bear_alarm_phase,
		"elapsed_seconds": snappedf(elapsed, 0.1),
	}
	active = false
	state = State.INACTIVE
	layer.visible = false
	completed.emit(result.duplicate(true))


func _on_music_finished() -> void:
	if active and state != State.CLEARED and music_player and music_player.stream:
		music_player.play()


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
	_update_seal_presentation()
	var incoming_warning := false
	for enemy in enemies:
		if bool(enemy.get("alive", false)) and str(enemy.get("attack_state", "idle")) == "telegraph":
			incoming_warning = true
			break
	var aiming_at_seal := _is_aiming_at_live_seal()
	var aiming_at_bear_drum := _is_aiming_at_vulnerable_bear()
	for line in crosshair_lines:
		if crosshair_hit_timer > 0.0:
			line.color = Color("#ffdc63")
		elif aiming_at_seal or aiming_at_bear_drum:
			line.color = Color("#ff4338") if int(elapsed * 14.0) % 2 == 0 else Color("#ffe08a")
		elif incoming_warning:
			line.color = Color("#ff3b32") if int(elapsed * 12.0) % 2 == 0 else Color("#f1e6c9")
		else:
			line.color = Color("#f1e6c9")
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


func _update_seal_presentation() -> void:
	for seal_index in range(seal_nodes.size()):
		var seal := seal_nodes[seal_index]
		var target := seal_target_nodes[seal_index] if seal_index < seal_target_nodes.size() else null
		if not final_seals_active:
			if target:
				target.visible = false
			continue
		if seal_health[seal_index] <= 0:
			seal.scale = Vector3.ONE * 0.01
			if target:
				target.visible = false
			continue
		var wave := 0.5 + 0.5 * sin(elapsed * 7.5 + float(seal_index) * 1.8)
		var hit_boost := 0.28 if float(seal_hit_flash[seal_index]) > 0.0 else 0.0
		seal.scale = Vector3.ONE * (0.96 + wave * 0.16 + hit_boost)
		if target:
			target.visible = true
			target.scale = Vector3.ONE * (0.92 + wave * 0.18 + hit_boost * 0.4)
			target.rotation.z = sin(elapsed * 2.6 + float(seal_index)) * 0.055
	if final_seals_active and final_display_label:
		var label_wave := 0.72 + 0.28 * absf(sin(elapsed * 5.0))
		final_display_label.modulate = Color(1.0, 0.45 + label_wave * 0.45, 0.28, 1.0)


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
		if strategic_bear_active or strategic_bear_departure_active or strategic_bear_defeated:
			var bear_health := _strategic_bear_health()
			var active_loads := ceili(float(bear_health) / 2.0)
			seal_marks[index].color = Color("#d52a31") if index < active_loads else Color("#29372d")
		elif not final_seals_active:
			seal_marks[index].color = Color("#32282a")
		elif seal_health[index] > 1:
			var mark_wave := 0.68 + 0.32 * absf(sin(elapsed * 7.5 + float(index) * 1.8))
			seal_marks[index].color = Color(0.84 * mark_wave, 0.10, 0.12, 1.0)
		elif seal_health[index] == 1:
			seal_marks[index].color = Color("#e7a928")
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


func _is_aiming_at_live_seal() -> bool:
	if not final_seals_active:
		return false
	var forward := _forward_vector()
	for seal_index in range(seal_nodes.size()):
		if seal_health[seal_index] <= 0:
			continue
		var offset := seal_nodes[seal_index].global_position - player_position
		var flat_offset := Vector3(offset.x, 0.0, offset.z)
		var distance := flat_offset.length()
		if distance <= 0.01 or distance > 18.0:
			continue
		var angle := acos(clampf(forward.dot(flat_offset / distance), -1.0, 1.0))
		if angle <= 0.085:
			return true
	return false


func _is_aiming_at_vulnerable_bear() -> bool:
	if not strategic_bear_active:
		return false
	var forward := _forward_vector()
	for enemy in enemies:
		if str(enemy.get("id", "")) != strategic_bear_id or not bool(enemy.get("vulnerable", false)):
			continue
		var offset := (enemy.get("position", Vector3.ZERO) as Vector3) - player_position
		var flat_offset := Vector3(offset.x, 0.0, offset.z)
		var distance := flat_offset.length()
		if distance <= 0.01 or distance > 21.0:
			return false
		return acos(clampf(forward.dot(flat_offset / distance), -1.0, 1.0)) <= 0.11
	return false


func _strategic_bear_health() -> int:
	for enemy in enemies:
		if str(enemy.get("id", "")) == strategic_bear_id:
			return maxi(0, int(enemy.get("hp", 0)))
	return 0


func _forward_vector() -> Vector3:
	return Vector3(sin(player_yaw), 0.0, cos(player_yaw)).normalized()


func _right_vector() -> Vector3:
	var forward := _forward_vector()
	return Vector3(-forward.z, 0.0, forward.x).normalized()


func _clear_enemies() -> void:
	for enemy in enemies:
		var telegraph := enemy.get("telegraph_node") as MeshInstance3D
		if telegraph and is_instance_valid(telegraph):
			telegraph.queue_free()
		var secondary_telegraph := enemy.get("telegraph_node_secondary") as MeshInstance3D
		if secondary_telegraph and is_instance_valid(secondary_telegraph):
			secondary_telegraph.queue_free()
		var sprite := enemy.get("node") as Sprite3D
		if sprite and is_instance_valid(sprite):
			sprite.queue_free()
	enemies.clear()
	enemy_sequence = 0
	_clear_enemy_projectiles()


func _clear_enemy_telegraphs() -> void:
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		var telegraph := enemy.get("telegraph_node") as MeshInstance3D
		if telegraph and is_instance_valid(telegraph):
			telegraph.queue_free()
		var secondary_telegraph := enemy.get("telegraph_node_secondary") as MeshInstance3D
		if secondary_telegraph and is_instance_valid(secondary_telegraph):
			secondary_telegraph.queue_free()
		enemy["telegraph_node_secondary"] = null
		enemy["telegraph_node"] = null
		enemy["attack_state"] = "idle"
		enemies[index] = enemy


func _clear_enemy_projectiles() -> void:
	for projectile in enemy_projectiles:
		var visual := projectile.get("node") as Node3D
		if visual and is_instance_valid(visual):
			visual.queue_free()
	enemy_projectiles.clear()
	projectile_sequence = 0


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
