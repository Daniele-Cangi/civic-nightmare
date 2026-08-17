extends Node

signal completed(result: Dictionary)
signal cancelled

const BACKGROUND_PATH := "res://assets/encounters/price_stability_pinball_stage_v1.png"
const VIEW_SIZE := Vector2(1280, 720)
const TARGET_INFLATION := 2.0
const STARTING_INFLATION := 4.8
const STABILITY_BAND := 0.12
const STABILITY_HOLD := 2.0
const BALL_RADIUS := 13.0
const PLAY_LEFT := 270.0
const PLAY_RIGHT := 1010.0
const PLAY_TOP := 132.0
const DRAIN_Y := 704.0
const FLIPPER_LENGTH := 146.0
const SYSTEMIC_SERVE_POSITION := Vector2(640, 555)
const SYSTEMIC_SERVE_SPEED := Vector2(18, -260)
const SOUTH_LEFT_GUIDE_START := Vector2(282, 470)
const SOUTH_LEFT_GUIDE_END := Vector2(460, 618)
const SOUTH_RIGHT_GUIDE_START := Vector2(998, 470)
const SOUTH_RIGHT_GUIDE_END := Vector2(820, 618)
const SOUTH_GUIDE_COLLISION_RADIUS := BALL_RADIUS + 13.0
const MAX_PHYSICS_FRAME_DELTA := 0.2
const PHYSICS_STEP := 1.0 / 120.0
const DEFAULT_INTRO_DURATION := 1.0
const DEFAULT_BEAT_DURATION := 1.25
const DEFAULT_OUTRO_DURATION := 1.6
const DEFAULT_ADJUSTMENT_TIMEOUT := 48.0

enum State { INACTIVE, INTRO, ACTIVE, STABLE, AFTERMATH, CLEARED }

const BUMPER_DATA := {
	"rates_left": {
		"position": Vector2(427, 276),
		"radius": 45.0,
		"label": "RATES\n-0.45",
		"delta": -0.45,
		"color": Color("#55cfee"),
	},
	"rates_right": {
		"position": Vector2(853, 276),
		"radius": 45.0,
		"label": "RATES\n-0.45",
		"delta": -0.45,
		"color": Color("#55cfee"),
	},
	"energy": {
		"position": Vector2(552, 205),
		"radius": 39.0,
		"label": "ENERGY\n+0.25",
		"delta": 0.25,
		"color": Color("#e8a23e"),
	},
	"rent": {
		"position": Vector2(728, 205),
		"radius": 39.0,
		"label": "RENT\n+0.22",
		"delta": 0.22,
		"color": Color("#e8754f"),
	},
	"wages": {
		"position": Vector2(545, 395),
		"radius": 42.0,
		"label": "WAGES\n+0.14",
		"delta": 0.14,
		"color": Color("#d96c77"),
	},
	"bank_rescue": {
		"position": Vector2(735, 395),
		"radius": 42.0,
		"label": "BANK\n+0.12",
		"delta": 0.12,
		"color": Color("#d7b650"),
	},
}

var host: Node
var layer: CanvasLayer
var root_control: Control
var frame: Control
var play_root: Node2D
var title_label: Label
var inflation_label: Label
var target_label: Label
var policy_message_label: Label
var prompt_label: Label
var result_panel: PanelContainer
var result_title: Label
var result_subtitle: Label
var gauge_marker: PanelContainer
var bumper_nodes: Dictionary = {}
var left_flipper: Node2D
var right_flipper: Node2D
var balls: Array[Dictionary] = []

var active := false
var state: State = State.INACTIVE
var state_timer := 0.0
var elapsed := 0.0
var intro_duration := DEFAULT_INTRO_DURATION
var beat_duration := DEFAULT_BEAT_DURATION
var outro_duration := DEFAULT_OUTRO_DURATION
var adjustment_timeout := DEFAULT_ADJUSTMENT_TIMEOUT
var physics_enabled := true
var timers_enabled := true
var inflation := STARTING_INFLATION
var stable_time := 0.0
var hit_count := 0
var rate_hits := 0
var household_hits := 0
var bailouts := 0
var acceptable_losses := 0
var multiball_spawned := false
var rate_shock_active := false
var statistical_adjustment := false
var left_flipper_angle := 0.22
var right_flipper_angle := -0.22
var spawn_direction := 1.0
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
	adjustment_timeout = maxf(1.0, float(options.get("adjustment_timeout", DEFAULT_ADJUSTMENT_TIMEOUT)))
	physics_enabled = bool(options.get("physics_enabled", true))
	timers_enabled = bool(options.get("timers_enabled", true))
	inflation = STARTING_INFLATION
	stable_time = 0.0
	elapsed = 0.0
	hit_count = 0
	rate_hits = 0
	household_hits = 0
	bailouts = 0
	acceptable_losses = 0
	multiball_spawned = false
	rate_shock_active = false
	statistical_adjustment = false
	spawn_direction = 1.0
	result.clear()
	_clear_balls()
	_spawn_ball(Vector2(640, 515), Vector2(165, -430))
	active = true
	layer.visible = true
	result_panel.visible = false
	policy_message_label.text = ""
	prompt_label.text = "←  LEFT FLIPPER                         RIGHT FLIPPER  →"
	_layout_frame()
	_refresh_inflation()
	_set_state(State.INTRO)


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
	_update_flippers(delta)
	match state:
		State.INTRO:
			if state_timer >= intro_duration:
				_set_state(State.ACTIVE)
		State.ACTIVE:
			_process_active(delta)
		State.STABLE:
			if state_timer >= beat_duration:
				_show_aftermath()
		State.AFTERMATH:
			if state_timer >= beat_duration:
				_show_clearance()
		State.CLEARED:
			if state_timer >= outro_duration:
				_finish_success()


func get_result() -> Dictionary:
	return result.duplicate(true)


func register_bumper_hit(bumper_id: String) -> bool:
	if not active or state != State.ACTIVE or not BUMPER_DATA.has(bumper_id):
		return false
	var data: Dictionary = BUMPER_DATA[bumper_id]
	var delta_value := float(data.get("delta", 0.0))
	inflation = clampf(inflation + delta_value, 0.0, 9.9)
	hit_count += 1
	if delta_value < 0.0:
		rate_hits += 1
	else:
		household_hits += 1
	_flash_bumper(bumper_id)
	_refresh_inflation()
	if hit_count == 5 and not multiball_spawned:
		_trigger_liquidity_injection()
	elif hit_count == 10 and not rate_shock_active:
		_trigger_rate_shock()
	return true


func force_statistical_adjustment() -> bool:
	if not active or state != State.ACTIVE:
		return false
	statistical_adjustment = true
	inflation = TARGET_INFLATION
	stable_time = STABILITY_HOLD
	_refresh_inflation()
	_show_policy_message("METHODOLOGY UPDATED")
	_complete_stability()
	return true


func simulate_ball_loss() -> bool:
	if not active or state != State.ACTIVE:
		return false
	for ball in balls:
		var node: Node2D = ball.get("node")
		if node and is_instance_valid(node):
			node.queue_free()
	balls.clear()
	_restore_systemic_ball()
	return true


func _process_active(delta: float) -> void:
	elapsed += delta
	if physics_enabled:
		_update_balls(delta)
	_update_stability(delta)
	if timers_enabled and elapsed >= adjustment_timeout and state == State.ACTIVE:
		force_statistical_adjustment()


func _update_stability(delta: float) -> void:
	if absf(inflation - TARGET_INFLATION) <= STABILITY_BAND:
		stable_time += delta
	else:
		stable_time = 0.0
	if stable_time >= STABILITY_HOLD and state == State.ACTIVE:
		_complete_stability()


func _complete_stability() -> void:
	inflation = TARGET_INFLATION
	_refresh_inflation()
	_freeze_balls()
	result_panel.visible = true
	result_title.text = "PRICE STABILITY ACHIEVED"
	result_subtitle.text = "PUBLISHED INDICATOR: 2.0%"
	policy_message_label.text = ""
	prompt_label.text = ""
	_set_state(State.STABLE)


func _show_aftermath() -> void:
	result_title.text = "PURCHASING POWER NOT INCLUDED"
	result_subtitle.text = "HOUSEHOLD EFFECTS OUTSIDE MEASUREMENT PERIMETER"
	_set_state(State.AFTERMATH)


func _show_clearance() -> void:
	result = {
		"outcome": "access_granted",
		"route": "statistical_adjustment" if statistical_adjustment else "market_stabilized",
		"final_inflation": inflation,
		"bumper_hits": hit_count,
		"rate_hits": rate_hits,
		"household_hits": household_hits,
		"bailouts": bailouts,
		"acceptable_losses": acceptable_losses,
		"multiball_used": multiball_spawned,
		"rate_shock": rate_shock_active,
		"elapsed": elapsed,
	}
	result_title.text = "ACCESS GRANTED"
	result_subtitle.text = "STABILITY CERTIFIED"
	_set_state(State.CLEARED)


func _finish_success() -> void:
	var final_result := result.duplicate(true)
	stop()
	completed.emit(final_result)


func _trigger_liquidity_injection() -> void:
	multiball_spawned = true
	_show_policy_message("LIQUIDITY INJECTION")
	_spawn_ball(Vector2(640, 475), Vector2(-205, -445))


func _trigger_rate_shock() -> void:
	rate_shock_active = true
	_show_policy_message("RATE HIKE")
	for ball in balls:
		ball["velocity"] = (ball.get("velocity", Vector2.ZERO) as Vector2) * 1.18


func _show_policy_message(message: String) -> void:
	policy_message_label.text = message
	policy_message_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.85)
	tween.tween_property(policy_message_label, "modulate:a", 0.0, 0.35)


func _spawn_ball(position_value: Vector2, velocity_value: Vector2) -> void:
	var node := _create_euro_ball()
	node.position = position_value
	play_root.add_child(node)
	balls.append({
		"node": node,
		"position": position_value,
		"velocity": velocity_value,
		"bumper_cooldown": 0.0,
		"last_bumper": "",
	})


func _clear_balls() -> void:
	for ball in balls:
		var node: Node2D = ball.get("node")
		if node and is_instance_valid(node):
			node.queue_free()
	balls.clear()


func _freeze_balls() -> void:
	for ball in balls:
		ball["velocity"] = Vector2.ZERO


func _update_balls(delta: float) -> void:
	var simulation_delta := minf(maxf(delta, 0.0), MAX_PHYSICS_FRAME_DELTA)
	var step_count := maxi(1, ceili(simulation_delta / PHYSICS_STEP))
	var step_delta := simulation_delta / float(step_count)
	for step_index in range(step_count):
		_update_balls_step(step_delta)


func _update_balls_step(delta: float) -> void:
	for i in range(balls.size() - 1, -1, -1):
		var ball: Dictionary = balls[i]
		_integrate_ball(ball, delta)
		if float((ball.get("position", Vector2.ZERO) as Vector2).y) > DRAIN_Y:
			var node: Node2D = ball.get("node")
			if node and is_instance_valid(node):
				node.queue_free()
			balls.remove_at(i)
			acceptable_losses += 1
	if balls.is_empty() and state == State.ACTIVE:
		_restore_systemic_ball()


func _restore_systemic_ball() -> void:
	bailouts += 1
	inflation = clampf(inflation + 0.32, 0.0, 9.9)
	_refresh_inflation()
	_show_policy_message("SYSTEMIC BALL RESTORED")
	spawn_direction *= -1.0
	_spawn_ball(
		SYSTEMIC_SERVE_POSITION,
		Vector2(SYSTEMIC_SERVE_SPEED.x * spawn_direction, SYSTEMIC_SERVE_SPEED.y)
	)


func _integrate_ball(ball: Dictionary, delta: float) -> void:
	var position: Vector2 = ball.get("position", Vector2.ZERO)
	var velocity: Vector2 = ball.get("velocity", Vector2.ZERO)
	var gravity := 485.0 if rate_shock_active else 375.0
	velocity.y += gravity * delta
	if velocity.length() > 720.0:
		velocity = velocity.normalized() * 720.0
	position += velocity * delta
	if position.x < PLAY_LEFT + BALL_RADIUS:
		position.x = PLAY_LEFT + BALL_RADIUS
		velocity.x = absf(velocity.x) * 0.94
	elif position.x > PLAY_RIGHT - BALL_RADIUS:
		position.x = PLAY_RIGHT - BALL_RADIUS
		velocity.x = -absf(velocity.x) * 0.94
	if position.y < PLAY_TOP + BALL_RADIUS:
		position.y = PLAY_TOP + BALL_RADIUS
		velocity.y = absf(velocity.y) * 0.94
	ball["position"] = position
	ball["velocity"] = velocity
	ball["bumper_cooldown"] = maxf(0.0, float(ball.get("bumper_cooldown", 0.0)) - delta)
	_collide_ball_with_bumpers(ball)
	_collide_ball_with_south_guides(ball)
	_collide_ball_with_flippers(ball)
	var node: Node2D = ball.get("node")
	if node and is_instance_valid(node):
		node.position = ball.get("position", position)
		node.rotation += delta * 4.8


func _collide_ball_with_bumpers(ball: Dictionary) -> void:
	var position: Vector2 = ball.get("position", Vector2.ZERO)
	var velocity: Vector2 = ball.get("velocity", Vector2.ZERO)
	for bumper_id in BUMPER_DATA:
		var data: Dictionary = BUMPER_DATA[bumper_id]
		var bumper_position: Vector2 = data.get("position", Vector2.ZERO)
		var collision_radius := float(data.get("radius", 36.0)) + BALL_RADIUS
		var offset := position - bumper_position
		if offset.length_squared() >= collision_radius * collision_radius:
			continue
		var normal := offset.normalized() if offset.length_squared() > 0.01 else Vector2.UP
		position = bumper_position + normal * collision_radius
		velocity = velocity.bounce(normal)
		if velocity.length() < 410.0:
			velocity = normal * 410.0
		velocity += Vector2(normal.x * 35.0, -25.0)
		if float(ball.get("bumper_cooldown", 0.0)) <= 0.0 or str(ball.get("last_bumper", "")) != str(bumper_id):
			register_bumper_hit(str(bumper_id))
			ball["bumper_cooldown"] = 0.24
			ball["last_bumper"] = str(bumper_id)
		break
	ball["position"] = position
	ball["velocity"] = velocity


func _collide_ball_with_flippers(ball: Dictionary) -> void:
	var left_tip := left_flipper.position + Vector2(FLIPPER_LENGTH, 0).rotated(left_flipper.rotation)
	var right_tip := right_flipper.position + Vector2(-FLIPPER_LENGTH, 0).rotated(right_flipper.rotation)
	_collide_ball_with_segment(ball, left_flipper.position, left_tip, Input.is_action_pressed("ui_left"))
	_collide_ball_with_segment(ball, right_flipper.position, right_tip, Input.is_action_pressed("ui_right"))


func _collide_ball_with_south_guides(ball: Dictionary) -> void:
	_collide_ball_with_guide(
		ball,
		SOUTH_LEFT_GUIDE_START,
		SOUTH_LEFT_GUIDE_END,
		Vector2(0.64, -0.77)
	)
	_collide_ball_with_guide(
		ball,
		SOUTH_RIGHT_GUIDE_START,
		SOUTH_RIGHT_GUIDE_END,
		Vector2(-0.64, -0.77)
	)


func _collide_ball_with_guide(ball: Dictionary, start: Vector2, end: Vector2, inward_normal: Vector2) -> void:
	var position: Vector2 = ball.get("position", Vector2.ZERO)
	var segment := end - start
	var segment_length_squared := segment.length_squared()
	if segment_length_squared <= 0.01:
		return
	var amount := clampf((position - start).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest := start + segment * amount
	if position.distance_squared_to(closest) >= SOUTH_GUIDE_COLLISION_RADIUS * SOUTH_GUIDE_COLLISION_RADIUS:
		return
	var normal := inward_normal.normalized()
	position = closest + normal * SOUTH_GUIDE_COLLISION_RADIUS
	var velocity: Vector2 = ball.get("velocity", Vector2.ZERO)
	if velocity.dot(normal) < 0.0:
		velocity = velocity.bounce(normal) * 0.92
		velocity.y = minf(velocity.y, -240.0)
		velocity.x += normal.x * 90.0
	ball["position"] = position
	ball["velocity"] = velocity


func _collide_ball_with_segment(ball: Dictionary, start: Vector2, end: Vector2, engaged: bool) -> void:
	var position: Vector2 = ball.get("position", Vector2.ZERO)
	var segment := end - start
	var segment_length_squared := segment.length_squared()
	if segment_length_squared <= 0.01:
		return
	var amount := clampf((position - start).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest := start + segment * amount
	var offset := position - closest
	var collision_radius := BALL_RADIUS + 15.0
	if offset.length_squared() >= collision_radius * collision_radius:
		return
	var normal := offset.normalized() if offset.length_squared() > 0.01 else Vector2.UP
	position = closest + normal * collision_radius
	var velocity: Vector2 = ball.get("velocity", Vector2.ZERO)
	velocity = velocity.bounce(normal) * 0.92
	velocity.y = minf(velocity.y, -510.0 if engaged else -330.0)
	velocity.x += (amount - 0.5) * (180.0 if engaged else 80.0)
	ball["position"] = position
	ball["velocity"] = velocity


func _update_flippers(delta: float) -> void:
	var left_target := -0.48 if Input.is_action_pressed("ui_left") else 0.22
	var right_target := 0.48 if Input.is_action_pressed("ui_right") else -0.22
	var weight := clampf(delta * 15.0, 0.0, 1.0)
	left_flipper_angle = lerp_angle(left_flipper_angle, left_target, weight)
	right_flipper_angle = lerp_angle(right_flipper_angle, right_target, weight)
	if left_flipper:
		left_flipper.rotation = left_flipper_angle
	if right_flipper:
		right_flipper.rotation = right_flipper_angle


func _refresh_inflation() -> void:
	inflation_label.text = "INFLATION  %.2f%%" % inflation
	var distance := absf(inflation - TARGET_INFLATION)
	var color := Color("#55efa0") if distance <= STABILITY_BAND else (Color("#ff7666") if inflation >= 4.0 else Color("#ffe16b"))
	inflation_label.add_theme_color_override("font_color", color)
	if gauge_marker:
		gauge_marker.position.x = 447.0 + clampf(inflation / 8.0, 0.0, 1.0) * 386.0


func _flash_bumper(bumper_id: String) -> void:
	var bumper: Node2D = bumper_nodes.get(bumper_id)
	if not bumper:
		return
	bumper.scale = Vector2.ONE * 1.12
	var tween := create_tween()
	tween.tween_property(bumper, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_state(next_state: State) -> void:
	state = next_state
	state_timer = 0.0


func _create_overlay() -> void:
	layer = CanvasLayer.new()
	layer.name = "PriceStabilityPinballLayer"
	layer.layer = 113
	layer.visible = false
	add_child(layer)
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root_control)
	var blackout := ColorRect.new()
	blackout.set_anchors_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color("#020304")
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
	wash.color = Color(0.01, 0.02, 0.035, 0.13)
	frame.add_child(wash)
	_create_header()
	play_root = Node2D.new()
	play_root.name = "PinballMechanism"
	frame.add_child(play_root)
	for bumper_id in BUMPER_DATA:
		_create_bumper(str(bumper_id), BUMPER_DATA[bumper_id])
	left_flipper = _create_flipper(Vector2(468, 612), 1.0, Color("#62b9da"))
	right_flipper = _create_flipper(Vector2(812, 612), -1.0, Color("#62b9da"))
	left_flipper.rotation = left_flipper_angle
	right_flipper.rotation = right_flipper_angle
	play_root.add_child(left_flipper)
	play_root.add_child(right_flipper)
	policy_message_label = _make_label(Vector2(390, 116), Vector2(500, 40), 20, Color("#ffe17a"))
	policy_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(policy_message_label)
	prompt_label = _make_label(Vector2(300, 674), Vector2(680, 32), 16, Color("#f6e5a5"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(prompt_label)
	_create_result_panel()


func _create_header() -> void:
	var header := PanelContainer.new()
	header.position = Vector2(14, 10)
	header.size = Vector2(1252, 101)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override("panel", _panel_style(Color("#c5a84c"), Color(0.015, 0.03, 0.05, 0.97), 4))
	frame.add_child(header)
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(content)
	title_label = _make_label(Vector2(24, 15), Vector2(310, 35), 24, Color("#e9c85b"))
	title_label.text = "THE 2% MIRACLE"
	content.add_child(title_label)
	inflation_label = _make_label(Vector2(360, 11), Vector2(530, 43), 30, Color("#ff7666"))
	inflation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(inflation_label)
	target_label = _make_label(Vector2(938, 17), Vector2(270, 32), 20, Color("#8edcf2"))
	target_label.text = "TARGET  2.00%"
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(target_label)
	var gauge_back := ColorRect.new()
	gauge_back.position = Vector2(430, 68)
	gauge_back.size = Vector2(420, 9)
	gauge_back.color = Color("#17252c")
	content.add_child(gauge_back)
	var target_zone := ColorRect.new()
	target_zone.position = Vector2(530, 68)
	target_zone.size = Vector2(18, 9)
	target_zone.color = Color("#55efa0")
	content.add_child(target_zone)
	gauge_marker = PanelContainer.new()
	gauge_marker.position = Vector2(679, 61)
	gauge_marker.size = Vector2(13, 23)
	gauge_marker.add_theme_stylebox_override("panel", _panel_style(Color("#fff0a0"), Color("#e45d50"), 2))
	content.add_child(gauge_marker)


func _create_bumper(bumper_id: String, data: Dictionary) -> void:
	var root := Node2D.new()
	root.name = "%sBumper" % bumper_id.to_pascal_case()
	root.position = data.get("position", Vector2.ZERO)
	root.z_index = 10
	play_root.add_child(root)
	bumper_nodes[bumper_id] = root
	var radius := float(data.get("radius", 38.0))
	var shadow := Polygon2D.new()
	shadow.polygon = _circle_points(radius + 7.0, 32)
	shadow.position = Vector2(5, 7)
	shadow.color = Color(0, 0, 0, 0.58)
	root.add_child(shadow)
	var rim := Polygon2D.new()
	rim.polygon = _circle_points(radius + 6.0, 32)
	rim.color = Color("#c9a84c")
	root.add_child(rim)
	var body := Polygon2D.new()
	body.polygon = _circle_points(radius, 32)
	body.color = data.get("color", Color.WHITE)
	root.add_child(body)
	var glass := Polygon2D.new()
	glass.polygon = _circle_points(radius - 8.0, 32)
	glass.color = Color(0.025, 0.06, 0.08, 0.86)
	root.add_child(glass)
	var label := _make_label(Vector2(-radius, -24), Vector2(radius * 2.0, 48), 13, Color.WHITE)
	label.text = str(data.get("label", "POLICY"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(label)


func _create_flipper(position_value: Vector2, direction: float, color: Color) -> Node2D:
	var root := Node2D.new()
	root.position = position_value
	root.z_index = 15
	var shadow := Line2D.new()
	shadow.width = 34.0
	shadow.default_color = Color(0, 0, 0, 0.55)
	shadow.position = Vector2(5, 7)
	shadow.add_point(Vector2.ZERO)
	shadow.add_point(Vector2(FLIPPER_LENGTH * direction, 0))
	root.add_child(shadow)
	var rim := Line2D.new()
	rim.width = 31.0
	rim.default_color = Color("#c4a34a")
	rim.add_point(Vector2.ZERO)
	rim.add_point(Vector2(FLIPPER_LENGTH * direction, 0))
	root.add_child(rim)
	var body := Line2D.new()
	body.width = 23.0
	body.default_color = color
	body.add_point(Vector2.ZERO)
	body.add_point(Vector2(FLIPPER_LENGTH * direction, 0))
	root.add_child(body)
	for local_position in [Vector2.ZERO, Vector2(FLIPPER_LENGTH * direction, 0)]:
		var cap := Polygon2D.new()
		cap.polygon = _circle_points(15.5, 24)
		cap.position = local_position
		cap.color = Color("#d5b458")
		root.add_child(cap)
	return root


func _create_euro_ball() -> Node2D:
	var root := Node2D.new()
	root.name = "SystemicEuroBall"
	root.z_index = 20
	var shadow := Polygon2D.new()
	shadow.polygon = _circle_points(BALL_RADIUS + 2.0, 24)
	shadow.position = Vector2(4, 5)
	shadow.color = Color(0, 0, 0, 0.6)
	root.add_child(shadow)
	var rim := Polygon2D.new()
	rim.polygon = _circle_points(BALL_RADIUS + 2.0, 24)
	rim.color = Color("#f1cf67")
	root.add_child(rim)
	var core := Polygon2D.new()
	core.polygon = _circle_points(BALL_RADIUS - 2.0, 24)
	core.color = Color("#e8b945")
	root.add_child(core)
	var euro := _make_label(Vector2(-13, -15), Vector2(26, 30), 19, Color("#50370c"))
	euro.text = "€"
	euro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	euro.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(euro)
	return root


func _create_result_panel() -> void:
	result_panel = PanelContainer.new()
	result_panel.position = Vector2(326, 274)
	result_panel.size = Vector2(628, 176)
	result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_panel.add_theme_stylebox_override("panel", _panel_style(Color("#d9bd5b"), Color(0.018, 0.035, 0.052, 0.98), 5))
	frame.add_child(result_panel)
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_panel.add_child(content)
	result_title = _make_label(Vector2(18, 31), Vector2(592, 52), 27, Color("#f4d76b"))
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(result_title)
	result_subtitle = _make_label(Vector2(22, 103), Vector2(584, 43), 16, Color("#b8d9e2"))
	result_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(result_subtitle)
	result_panel.visible = false


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
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	return style


func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _layout_frame() -> void:
	if not root_control or not frame:
		return
	var viewport_size := root_control.size
	var scale_factor := minf(viewport_size.x / VIEW_SIZE.x, viewport_size.y / VIEW_SIZE.y)
	frame.scale = Vector2.ONE * scale_factor
	frame.position = (viewport_size - VIEW_SIZE * scale_factor) * 0.5
