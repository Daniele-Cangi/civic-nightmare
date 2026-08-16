extends Node

signal completed(result: Dictionary)
signal cancelled

const BACKGROUND_PATH := "res://assets/encounters/bunker_aid_corridor_v1.png"
const CITIZEN_POSES_PATH := "res://assets/mockups/citizen_battle_poses.png"
const VIEW_SIZE := Vector2(1280, 720)
const ARENA := Rect2(104, 230, 1072, 372)
const POSE_CELL := 627
const MAX_HEALTH := 4
const DEFAULT_DURATION := 55.0
const DEFAULT_INTRO_DURATION := 2.4
const DEFAULT_OUTRO_DURATION := 1.7
const MOVE_SPEED := 300.0
const DASH_SPEED_MULTIPLIER := 2.65
const DASH_DURATION := 0.18
const DASH_COOLDOWN := 1.05
const BOMB_WARNING_DURATION := 0.78
const BOMB_FALL_DURATION := 0.34
const BOMB_BLAST_DURATION := 0.34
const BOMB_HIT_RADIUS := 54.0

enum State { INACTIVE, INTRO, ACTIVE, RETURNED, CLEARED }

var host: Node
var layer: CanvasLayer
var root_control: Control
var frame: Control
var background: TextureRect
var phase_tint: ColorRect
var hazard_layer: Control
var citizen_shadow: Polygon2D
var citizen_sprite: Sprite2D
var timer_label: Label
var prompt_label: Label
var dash_panel: PanelContainer
var dash_label: Label
var dash_fill: ColorRect
var health_marks: Array[ColorRect] = []
var door_glow: ColorRect

var active: bool = false
var state: State = State.INACTIVE
var state_timer: float = 0.0
var elapsed: float = 0.0
var run_duration: float = DEFAULT_DURATION
var intro_duration: float = DEFAULT_INTRO_DURATION
var outro_duration: float = DEFAULT_OUTRO_DURATION
var hazards_enabled: bool = true
var attempt_count: int = 0
var health: int = MAX_HEALTH
var citizen_position := Vector2(190, 425)
var last_move_direction := Vector2.RIGHT
var dash_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0
var aid_drag_remaining: float = 0.0
var invulnerability_remaining: float = 0.0
var pose_hold_remaining: float = 0.0
var bomb_spawn_timer: float = 0.0
var money_spawn_timer: float = 0.0
var bomb_sequence: int = 0
var money_sequence: int = 0
var bombs: Array[Dictionary] = []
var money_packages: Array[Dictionary] = []
var bomb_hits: int = 0
var funding_contacts: int = 0
var dash_count: int = 0
var result: Dictionary = {}

var impact_audio: AudioStreamPlayer
var paper_audio: AudioStreamPlayer
var success_audio: AudioStreamPlayer


func setup(owner: Node) -> void:
	host = owner
	_create_overlay()


func start(options: Dictionary = {}) -> void:
	if not layer:
		_create_overlay()
	run_duration = maxf(0.05, float(options.get("duration", DEFAULT_DURATION)))
	intro_duration = maxf(0.0, float(options.get("intro_duration", DEFAULT_INTRO_DURATION)))
	outro_duration = maxf(0.0, float(options.get("outro_duration", DEFAULT_OUTRO_DURATION)))
	hazards_enabled = bool(options.get("hazards_enabled", true))
	attempt_count = 0
	bomb_hits = 0
	funding_contacts = 0
	dash_count = 0
	result.clear()
	active = true
	layer.visible = true
	_layout_frame()
	_reset_attempt(true)


func stop() -> void:
	active = false
	state = State.INACTIVE
	_clear_hazards()
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
	_match_state_visuals()
	match state:
		State.INTRO:
			if state_timer >= intro_duration:
				_begin_active_run()
		State.ACTIVE:
			_process_active_run(delta)
		State.RETURNED:
			if state_timer >= 1.15:
				_reset_attempt(false)
		State.CLEARED:
			if state_timer >= outro_duration:
				_finish_success()


func get_result() -> Dictionary:
	return result.duplicate(true)


func get_hazard_counts() -> Dictionary:
	return {"bombs": bombs.size(), "funding": money_packages.size()}


func _create_overlay() -> void:
	layer = CanvasLayer.new()
	layer.name = "BunkerAccessLayer"
	layer.layer = 112
	layer.visible = false
	add_child(layer)

	root_control = Control.new()
	root_control.name = "BunkerAccessRoot"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root_control)

	var blackout := ColorRect.new()
	blackout.set_anchors_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color("#06090d")
	root_control.add_child(blackout)

	frame = Control.new()
	frame.name = "BunkerAccessFrame"
	frame.size = VIEW_SIZE
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(frame)
	root_control.resized.connect(_layout_frame)

	background = TextureRect.new()
	background.name = "AuthoredCorridor"
	background.position = Vector2.ZERO
	background.size = VIEW_SIZE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH)
	else:
		background.modulate = Color("#323a3d")
	frame.add_child(background)

	var floor_readability := ColorRect.new()
	floor_readability.name = "ArenaReadability"
	floor_readability.position = ARENA.position
	floor_readability.size = ARENA.size
	floor_readability.color = Color(0.02, 0.03, 0.035, 0.13)
	floor_readability.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(floor_readability)

	phase_tint = ColorRect.new()
	phase_tint.name = "PhaseTint"
	phase_tint.position = Vector2.ZERO
	phase_tint.size = VIEW_SIZE
	phase_tint.color = Color(0.12, 0.18, 0.22, 0.0)
	phase_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(phase_tint)

	door_glow = ColorRect.new()
	door_glow.name = "ExitAuthorization"
	door_glow.position = Vector2(1134, 272)
	door_glow.size = Vector2(22, 252)
	door_glow.color = Color(0.4, 1.0, 0.58, 0.0)
	door_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(door_glow)

	hazard_layer = Control.new()
	hazard_layer.name = "Hazards"
	hazard_layer.position = Vector2.ZERO
	hazard_layer.size = VIEW_SIZE
	hazard_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(hazard_layer)

	citizen_shadow = Polygon2D.new()
	citizen_shadow.name = "CitizenShadow"
	citizen_shadow.polygon = _ellipse_points(38.0, 11.0, 20)
	citizen_shadow.color = Color(0.0, 0.0, 0.0, 0.45)
	frame.add_child(citizen_shadow)

	citizen_sprite = Sprite2D.new()
	citizen_sprite.name = "Citizen"
	citizen_sprite.texture = _pose_texture(Vector2i(1, 0))
	citizen_sprite.scale = Vector2(0.29, 0.29)
	citizen_sprite.z_index = 8
	frame.add_child(citizen_sprite)

	_create_hud()
	_create_audio()
	_layout_frame()


func _create_hud() -> void:
	var hud_back := ColorRect.new()
	hud_back.position = Vector2(0, 0)
	hud_back.size = Vector2(1280, 88)
	hud_back.color = Color(0.01, 0.015, 0.02, 0.83)
	hud_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_back.z_index = 30
	frame.add_child(hud_back)

	for i in range(MAX_HEALTH):
		var paper := ColorRect.new()
		paper.name = "CaseSheet%d" % (i + 1)
		paper.position = Vector2(42 + i * 31, 27 + (i % 2) * 3)
		paper.size = Vector2(22, 31)
		paper.color = Color("#e9e1c9")
		paper.rotation = deg_to_rad(-5.0 + i * 3.0)
		paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paper.z_index = 31
		frame.add_child(paper)
		var stamp := ColorRect.new()
		stamp.position = Vector2(4, 9)
		stamp.size = Vector2(14, 4)
		stamp.color = Color("#b53030")
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paper.add_child(stamp)
		health_marks.append(paper)

	timer_label = Label.new()
	timer_label.name = "Timer"
	timer_label.position = Vector2(552, 13)
	timer_label.size = Vector2(176, 60)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 43)
	timer_label.add_theme_color_override("font_color", Color("#f7f0d8"))
	timer_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	timer_label.add_theme_constant_override("shadow_offset_x", 3)
	timer_label.add_theme_constant_override("shadow_offset_y", 3)
	timer_label.z_index = 31
	frame.add_child(timer_label)

	dash_panel = PanelContainer.new()
	dash_panel.name = "DashCommand"
	dash_panel.position = Vector2(1092, 20)
	dash_panel.size = Vector2(142, 48)
	dash_panel.z_index = 31
	var dash_style := StyleBoxFlat.new()
	dash_style.bg_color = Color("#1d2730")
	dash_style.border_color = Color("#d8c48b")
	dash_style.set_border_width_all(2)
	dash_style.set_corner_radius_all(5)
	dash_panel.add_theme_stylebox_override("panel", dash_style)
	frame.add_child(dash_panel)

	dash_fill = ColorRect.new()
	dash_fill.position = Vector2(4, 40)
	dash_fill.size = Vector2(134, 4)
	dash_fill.color = Color("#70d9d1")
	dash_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dash_panel.add_child(dash_fill)

	dash_label = Label.new()
	dash_label.text = "SPACE"
	dash_label.position = Vector2(0, 1)
	dash_label.size = Vector2(142, 38)
	dash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dash_label.add_theme_font_size_override("font_size", 20)
	dash_label.add_theme_color_override("font_color", Color("#f7f0d8"))
	dash_panel.add_child(dash_label)

	prompt_label = Label.new()
	prompt_label.name = "StatePrompt"
	prompt_label.position = Vector2(286, 612)
	prompt_label.size = Vector2(708, 76)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 34)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt_label.add_theme_constant_override("shadow_offset_x", 3)
	prompt_label.add_theme_constant_override("shadow_offset_y", 3)
	prompt_label.z_index = 31
	frame.add_child(prompt_label)


func _create_audio() -> void:
	impact_audio = AudioStreamPlayer.new()
	impact_audio.stream = _make_tone(74.0, 0.18, 0.48)
	impact_audio.volume_db = -6.0
	add_child(impact_audio)
	paper_audio = AudioStreamPlayer.new()
	paper_audio.stream = _make_tone(460.0, 0.09, 0.08)
	paper_audio.volume_db = -10.0
	add_child(paper_audio)
	success_audio = AudioStreamPlayer.new()
	success_audio.stream = _make_tone(690.0, 0.32, 0.02)
	success_audio.volume_db = -8.0
	add_child(success_audio)


func _reset_attempt(first_attempt: bool) -> void:
	attempt_count += 1
	health = MAX_HEALTH
	elapsed = 0.0
	citizen_position = Vector2(176, 430)
	last_move_direction = Vector2.RIGHT
	dash_remaining = 0.0
	dash_cooldown_remaining = 0.0
	aid_drag_remaining = 0.0
	invulnerability_remaining = 0.0
	pose_hold_remaining = 0.0
	bomb_spawn_timer = 0.38
	money_spawn_timer = 0.28
	bomb_sequence = 0
	money_sequence = 0
	_clear_hazards()
	_set_pose(Vector2i(1, 0))
	state = State.INTRO
	state_timer = 0.0
	if not first_attempt:
		intro_duration = minf(intro_duration, 0.75)
	_update_hud()
	_update_citizen_visual()


func _begin_active_run() -> void:
	state = State.ACTIVE
	state_timer = 0.0
	prompt_label.text = ""


func _process_active_run(delta: float) -> void:
	elapsed = minf(run_duration, elapsed + delta)
	dash_remaining = maxf(0.0, dash_remaining - delta)
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	aid_drag_remaining = maxf(0.0, aid_drag_remaining - delta)
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)
	pose_hold_remaining = maxf(0.0, pose_hold_remaining - delta)
	_process_movement(delta)
	if hazards_enabled:
		_process_spawns(delta)
		_update_bombs(delta)
		if state != State.ACTIVE:
			_update_citizen_visual()
			_update_hud()
			return
		_update_money(delta)
	_update_citizen_visual()
	_update_hud()
	if elapsed >= run_duration:
		_begin_success()


func _process_movement(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if is_zero_approx(direction.x):
		direction.x = float(Input.is_physical_key_pressed(Key.KEY_D)) - float(Input.is_physical_key_pressed(Key.KEY_A))
	if is_zero_approx(direction.y):
		direction.y = float(Input.is_physical_key_pressed(Key.KEY_S)) - float(Input.is_physical_key_pressed(Key.KEY_W))
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	if direction.length_squared() > 0.01:
		last_move_direction = direction.normalized()
	if Input.is_action_just_pressed("ui_accept") and dash_cooldown_remaining <= 0.0:
		dash_remaining = DASH_DURATION
		dash_cooldown_remaining = DASH_COOLDOWN
		dash_count += 1
	var speed := MOVE_SPEED
	if aid_drag_remaining > 0.0:
		speed *= 0.56
	if dash_remaining > 0.0:
		speed *= DASH_SPEED_MULTIPLIER
		if direction.length_squared() <= 0.01:
			direction = last_move_direction
	citizen_position += direction * speed * delta
	citizen_position.x = clampf(citizen_position.x, ARENA.position.x + 30.0, ARENA.end.x - 30.0)
	citizen_position.y = clampf(citizen_position.y, ARENA.position.y + 42.0, ARENA.end.y - 42.0)
	if pose_hold_remaining <= 0.0:
		_set_pose(Vector2i(1, 0) if direction.length_squared() > 0.01 else Vector2i(0, 0))
	citizen_sprite.flip_h = last_move_direction.x < -0.05


func _process_spawns(delta: float) -> void:
	bomb_spawn_timer -= delta
	var progress := elapsed / run_duration
	var bomb_interval := 1.55
	var money_interval := 99.0
	if progress >= 0.36 and progress < 0.73:
		bomb_interval = 1.85
		money_interval = 0.62
	elif progress >= 0.73:
		bomb_interval = 1.08
		money_interval = 0.44
	if bomb_spawn_timer <= 0.0:
		_spawn_bomb(progress)
		bomb_spawn_timer += bomb_interval
	if progress >= 0.34:
		money_spawn_timer -= delta
		if money_spawn_timer <= 0.0:
			_spawn_money(progress)
			money_spawn_timer += money_interval


func _spawn_bomb(progress: float) -> void:
	var lanes := [286.0, 365.0, 447.0, 532.0]
	var target := Vector2(270.0 + float((bomb_sequence * 173) % 820), lanes[bomb_sequence % lanes.size()])
	if bomb_sequence % 3 == 2:
		target = citizen_position + last_move_direction * (44.0 if progress > 0.7 else 18.0)
		target.x = clampf(target.x, ARENA.position.x + 42.0, ARENA.end.x - 42.0)
		target.y = clampf(target.y, ARENA.position.y + 42.0, ARENA.end.y - 42.0)
	bomb_sequence += 1
	var node := Node2D.new()
	node.name = "Bomb%02d" % bomb_sequence
	node.position = target
	node.z_index = 3
	hazard_layer.add_child(node)
	var outer := Line2D.new()
	outer.name = "WarningRing"
	outer.points = PackedVector2Array(_circle_points(BOMB_HIT_RADIUS, 28, true))
	outer.width = 4.0
	outer.default_color = Color(1.0, 0.22, 0.12, 0.94)
	node.add_child(outer)
	_create_bureaucratic_target(node)
	bombs.append({"node": node, "target": target, "age": 0.0, "phase": 0})


func _create_bureaucratic_target(parent: Node2D) -> void:
	var docket := Node2D.new()
	docket.name = "ImpactDocket"
	docket.z_index = 1
	parent.add_child(docket)

	var paper_shadow := Polygon2D.new()
	paper_shadow.position = Vector2(3, 4)
	paper_shadow.polygon = PackedVector2Array([
		Vector2(-21, -27), Vector2(14, -27), Vector2(24, -17),
		Vector2(24, 27), Vector2(-21, 27),
	])
	paper_shadow.color = Color(0.0, 0.0, 0.0, 0.38)
	docket.add_child(paper_shadow)

	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([
		Vector2(-22, -28), Vector2(13, -28), Vector2(23, -18),
		Vector2(23, 28), Vector2(-22, 28),
	])
	paper.color = Color(0.94, 0.88, 0.70, 0.94)
	docket.add_child(paper)

	var folded_corner := Polygon2D.new()
	folded_corner.polygon = PackedVector2Array([
		Vector2(13, -28), Vector2(13, -18), Vector2(23, -18),
	])
	folded_corner.color = Color(0.70, 0.64, 0.48, 0.96)
	docket.add_child(folded_corner)

	for row in range(3):
		var checkbox := Line2D.new()
		var box_y := -15.0 + row * 11.0
		checkbox.points = PackedVector2Array([
			Vector2(-15, box_y - 3), Vector2(-9, box_y - 3),
			Vector2(-9, box_y + 3), Vector2(-15, box_y + 3),
			Vector2(-15, box_y - 3),
		])
		checkbox.width = 1.5
		checkbox.default_color = Color(0.18, 0.20, 0.19, 0.82)
		docket.add_child(checkbox)
		var form_line := Line2D.new()
		form_line.points = PackedVector2Array([Vector2(-5, box_y), Vector2(15, box_y)])
		form_line.width = 1.5
		form_line.default_color = Color(0.28, 0.29, 0.25, 0.72)
		docket.add_child(form_line)

	var seal := Line2D.new()
	seal.points = PackedVector2Array(_circle_points(9.0, 18, true))
	seal.position = Vector2(7, 17)
	seal.width = 2.5
	seal.default_color = Color(0.72, 0.06, 0.06, 0.92)
	docket.add_child(seal)
	var approval_mark := Line2D.new()
	approval_mark.points = PackedVector2Array([
		Vector2(1, 17), Vector2(5, 21), Vector2(13, 12),
	])
	approval_mark.width = 2.5
	approval_mark.default_color = Color(0.72, 0.06, 0.06, 0.92)
	docket.add_child(approval_mark)

	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var inward_marker := Polygon2D.new()
		inward_marker.position = Vector2(cos(angle), sin(angle)) * 45.0
		inward_marker.rotation = angle + PI
		inward_marker.polygon = PackedVector2Array([
			Vector2(-6, -3), Vector2(6, 0), Vector2(-6, 3),
		])
		inward_marker.color = Color(0.95, 0.12, 0.08, 0.88)
		docket.add_child(inward_marker)


func _spawn_money(progress: float) -> void:
	var lanes := [305.0, 390.0, 478.0, 552.0]
	var from_left := money_sequence % 2 == 0
	var y: float = lanes[(money_sequence * 3) % lanes.size()]
	var node := _make_money_bundle()
	node.name = "Transfer%02d" % (money_sequence + 1)
	node.position = Vector2(ARENA.position.x - 64.0 if from_left else ARENA.end.x + 64.0, y)
	node.z_index = 5
	hazard_layer.add_child(node)
	var base_speed := 252.0 + (58.0 if progress > 0.73 else 0.0)
	money_packages.append({"node": node, "velocity": Vector2(base_speed if from_left else -base_speed, 0.0)})
	money_sequence += 1


func _update_bombs(delta: float) -> void:
	for index in range(bombs.size() - 1, -1, -1):
		var item: Dictionary = bombs[index]
		var node := item.get("node") as Node2D
		if not is_instance_valid(node):
			bombs.remove_at(index)
			continue
		item["age"] = float(item.get("age", 0.0)) + delta
		var phase := int(item.get("phase", 0))
		var age := float(item["age"])
		if phase == 0:
			var warning := node.get_node_or_null("WarningRing") as Line2D
			var docket := node.get_node_or_null("ImpactDocket") as Node2D
			if warning:
				warning.modulate.a = 0.35 + 0.65 * absf(sin(age * 14.0))
				warning.scale = Vector2.ONE * (0.86 + 0.12 * sin(age * 9.0))
			if docket:
				docket.rotation = sin(age * 8.0) * 0.045
				docket.modulate.a = 0.68 + 0.32 * absf(sin(age * 10.0))
			if age >= BOMB_WARNING_DURATION:
				item["phase"] = 1
				item["age"] = 0.0
				_add_falling_bomb(node)
		elif phase == 1:
			var bomb_visual := node.get_node_or_null("FallingBomb") as Node2D
			var fall_progress := clampf(age / BOMB_FALL_DURATION, 0.0, 1.0)
			if bomb_visual:
				bomb_visual.position.y = lerpf(-270.0, 0.0, ease(fall_progress, -2.0))
				bomb_visual.scale = Vector2.ONE * lerpf(0.65, 1.1, fall_progress)
			if age >= BOMB_FALL_DURATION:
				item["phase"] = 2
				item["age"] = 0.0
				_bomb_impact(node, item.get("target", node.position))
				if state != State.ACTIVE:
					return
		elif phase == 2:
			var blast_progress := clampf(age / BOMB_BLAST_DURATION, 0.0, 1.0)
			var blast := node.get_node_or_null("Blast") as Node2D
			if blast:
				blast.scale = Vector2.ONE * lerpf(0.55, 1.55, blast_progress)
				blast.modulate.a = 1.0 - blast_progress
			if age >= BOMB_BLAST_DURATION:
				node.queue_free()
				bombs.remove_at(index)
				continue


func _update_money(delta: float) -> void:
	for index in range(money_packages.size() - 1, -1, -1):
		var item: Dictionary = money_packages[index]
		var node := item.get("node") as Node2D
		if not is_instance_valid(node):
			money_packages.remove_at(index)
			continue
		node.position += (item.get("velocity", Vector2.ZERO) as Vector2) * delta
		node.rotation = sin(elapsed * 7.0 + float(index)) * 0.08
		if node.position.x < ARENA.position.x - 100.0 or node.position.x > ARENA.end.x + 100.0:
			node.queue_free()
			money_packages.remove_at(index)
			continue
		if citizen_position.distance_to(node.position) < 49.0 and invulnerability_remaining <= 0.0:
			funding_contacts += 1
			aid_drag_remaining = 1.45
			pose_hold_remaining = 0.24
			_set_pose(Vector2i(0, 1))
			paper_audio.play()
			node.queue_free()
			money_packages.remove_at(index)


func _add_falling_bomb(parent: Node2D) -> void:
	var warning := parent.get_node_or_null("WarningRing")
	if warning:
		warning.modulate.a = 0.55
	var bomb := Node2D.new()
	bomb.name = "FallingBomb"
	bomb.position = Vector2(0, -270)
	parent.add_child(bomb)
	var shell := Polygon2D.new()
	shell.polygon = PackedVector2Array([Vector2(-10, -24), Vector2(10, -24), Vector2(14, 13), Vector2(0, 24), Vector2(-14, 13)])
	shell.color = Color("#222b2d")
	bomb.add_child(shell)
	var band := Polygon2D.new()
	band.polygon = PackedVector2Array([Vector2(-13, -2), Vector2(13, -2), Vector2(13, 6), Vector2(-13, 6)])
	band.color = Color("#e5b334")
	bomb.add_child(band)
	for side in [-1.0, 1.0]:
		var fin := Polygon2D.new()
		fin.polygon = PackedVector2Array([Vector2(side * 7, -18), Vector2(side * 22, -28), Vector2(side * 15, -6)])
		fin.color = Color("#485356")
		bomb.add_child(fin)


func _bomb_impact(parent: Node2D, target: Vector2) -> void:
	var falling := parent.get_node_or_null("FallingBomb")
	if falling:
		falling.queue_free()
	for child in parent.get_children():
		if child is Line2D:
			child.visible = false
	var docket := parent.get_node_or_null("ImpactDocket") as Node2D
	if docket:
		docket.visible = false
	var blast := Node2D.new()
	blast.name = "Blast"
	blast.z_index = 9
	parent.add_child(blast)
	var star := Polygon2D.new()
	star.polygon = _star_points(38.0, 80.0, 12)
	star.color = Color("#ffbd35")
	blast.add_child(star)
	var core := Polygon2D.new()
	core.polygon = _star_points(22.0, 48.0, 10)
	core.color = Color("#fff3c2")
	blast.add_child(core)
	impact_audio.play()
	if citizen_position.distance_to(target) <= BOMB_HIT_RADIUS and invulnerability_remaining <= 0.0:
		bomb_hits += 1
		health -= 1
		invulnerability_remaining = 0.72
		pose_hold_remaining = 0.42
		_set_pose(Vector2i(0, 1))
		var knock := (citizen_position - target).normalized()
		if knock.length_squared() < 0.1:
			knock = -last_move_direction
		citizen_position += knock * 48.0
		citizen_position.x = clampf(citizen_position.x, ARENA.position.x + 30.0, ARENA.end.x - 30.0)
		citizen_position.y = clampf(citizen_position.y, ARENA.position.y + 42.0, ARENA.end.y - 42.0)
		_update_hud()
		if health <= 0:
			_begin_returned()


func _begin_returned() -> void:
	state = State.RETURNED
	state_timer = 0.0
	prompt_label.text = "PROCESS RETURNED"
	_set_pose(Vector2i(1, 1))
	_clear_hazards()


func _begin_success() -> void:
	state = State.CLEARED
	state_timer = 0.0
	prompt_label.text = "ACCESS ELIGIBILITY SURVIVED"
	door_glow.color.a = 0.72
	_set_pose(Vector2i(1, 0))
	_clear_hazards()
	success_audio.play()


func _finish_success() -> void:
	result = {
		"outcome": "access_granted",
		"attempts": attempt_count,
		"bomb_hits": bomb_hits,
		"funding_contacts": funding_contacts,
		"dash_count": dash_count,
		"elapsed_seconds": snappedf(run_duration, 0.1)
	}
	active = false
	state = State.INACTIVE
	layer.visible = false
	completed.emit(result.duplicate(true))


func _match_state_visuals() -> void:
	if state == State.INTRO:
		prompt_label.text = "↑  ←  ↓  →       SPACE"
		prompt_label.modulate.a = 0.58 + 0.42 * absf(sin(state_timer * 4.2))
	elif state == State.ACTIVE:
		prompt_label.modulate.a = 1.0
	elif state == State.RETURNED:
		prompt_label.modulate.a = 0.55 + 0.45 * absf(sin(state_timer * 8.0))
	elif state == State.CLEARED:
		prompt_label.modulate.a = 1.0
		door_glow.color.a = 0.45 + 0.35 * absf(sin(state_timer * 7.0))


func _update_citizen_visual() -> void:
	var bob := sin(elapsed * 11.0) * 2.0 if state == State.ACTIVE else 0.0
	citizen_sprite.position = citizen_position + Vector2(0, -38 + bob)
	citizen_shadow.position = citizen_position + Vector2(0, 66)
	var blink := invulnerability_remaining > 0.0 and int(invulnerability_remaining * 18.0) % 2 == 0
	citizen_sprite.modulate.a = 0.48 if blink else 1.0
	citizen_sprite.modulate = Color(0.72, 1.0, 0.72, citizen_sprite.modulate.a) if aid_drag_remaining > 0.0 else Color(1, 1, 1, citizen_sprite.modulate.a)


func _update_hud() -> void:
	var remaining := maxf(0.0, run_duration - elapsed)
	timer_label.text = "%02d" % ceili(remaining)
	for i in range(health_marks.size()):
		health_marks[i].modulate = Color.WHITE if i < health else Color(0.22, 0.22, 0.22, 0.38)
	var dash_ratio := 1.0 - clampf(dash_cooldown_remaining / DASH_COOLDOWN, 0.0, 1.0)
	dash_fill.size.x = 134.0 * dash_ratio
	dash_panel.modulate = Color.WHITE if dash_cooldown_remaining <= 0.0 else Color(0.55, 0.58, 0.61, 0.85)
	var progress := elapsed / run_duration
	if progress < 0.36:
		phase_tint.color = Color(0.2, 0.07, 0.03, 0.10)
	elif progress < 0.73:
		phase_tint.color = Color(0.08, 0.22, 0.11, 0.10)
	else:
		phase_tint.color = Color(0.28, 0.10, 0.02, 0.15)


func _clear_hazards() -> void:
	bombs.clear()
	money_packages.clear()
	if hazard_layer:
		for child in hazard_layer.get_children():
			child.queue_free()


func _make_money_bundle() -> Node2D:
	var bundle := Node2D.new()
	var shadow := Polygon2D.new()
	shadow.position = Vector2(4, 5)
	shadow.polygon = PackedVector2Array([Vector2(-31, -18), Vector2(31, -18), Vector2(31, 18), Vector2(-31, 18)])
	shadow.color = Color(0, 0, 0, 0.38)
	bundle.add_child(shadow)
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([Vector2(-32, -19), Vector2(32, -19), Vector2(32, 19), Vector2(-32, 19)])
	paper.color = Color("#9ecb83")
	bundle.add_child(paper)
	var band := Polygon2D.new()
	band.polygon = PackedVector2Array([Vector2(-8, -21), Vector2(8, -21), Vector2(8, 21), Vector2(-8, 21)])
	band.color = Color("#e8d09a")
	bundle.add_child(band)
	var mark := Label.new()
	mark.text = "$"
	mark.position = Vector2(-27, -17)
	mark.size = Vector2(54, 34)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_size_override("font_size", 25)
	mark.add_theme_color_override("font_color", Color("#245936"))
	bundle.add_child(mark)
	return bundle


func _set_pose(cell: Vector2i) -> void:
	if citizen_sprite:
		citizen_sprite.texture = _pose_texture(cell)


func _pose_texture(cell: Vector2i) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	if ResourceLoader.exists(CITIZEN_POSES_PATH):
		atlas_texture.atlas = load(CITIZEN_POSES_PATH)
	atlas_texture.region = Rect2(cell.x * POSE_CELL, cell.y * POSE_CELL, POSE_CELL, POSE_CELL)
	return atlas_texture


func _layout_frame() -> void:
	if root_control and frame:
		frame.position = (root_control.size - VIEW_SIZE) * 0.5


func _circle_points(radius: float, segments: int, close_shape: bool = false) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in range(segments + (1 if close_shape else 0)):
		var angle := TAU * float(i % segments) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _ellipse_points(radius_x: float, radius_y: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _star_points(inner_radius: float, outer_radius: float, points_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(points_count * 2):
		var angle := -PI * 0.5 + PI * float(i) / float(points_count)
		var radius := outer_radius if i % 2 == 0 else inner_radius
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _make_tone(frequency: float, duration: float, noise_amount: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := maxi(1, int(duration * sample_rate))
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for i in range(sample_count):
		var time := float(i) / float(sample_rate)
		var envelope := pow(1.0 - float(i) / float(sample_count), 1.7)
		var wave := sin(TAU * frequency * time) * (1.0 - noise_amount)
		var noise := sin(float(i * 7919 % 997) * 0.013) * noise_amount
		bytes[i] = clampi(int(128.0 + (wave + noise) * envelope * 105.0), 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream
