extends Node

signal triggered
signal dialogue_requested(character_id: String)

var player: CharacterBody2D
var entities_layer: Node2D
var dialogue_anchor: Control
var typewriter_timer: Timer
var typewriter_bip: AudioStreamPlayer
var contamination_root: Node2D

var bezos_drone_root: Node2D
var bezos_drone_base_position: Vector2 = Vector2.ZERO
var bezos_drone_hover_time: float = 0.0
var bezos_escalation_active: bool = false
var bezos_escalation_step: int = 0
var bezos_escalation_timer: float = 0.0
var bezos_escalation_space_latched: bool = false
var bezos_escalation_bip_tween: Tween
var bezos_escalation_bubble: PanelContainer
var bezos_escalation_speaker_label: Label
var bezos_escalation_text_label: Label


func setup(player_node: CharacterBody2D, world_entities: Node2D, spawn_position: Vector2) -> void:
	player = player_node
	entities_layer = world_entities
	bezos_drone_base_position = spawn_position
	_create_drone()


func _create_drone() -> void:
	bezos_drone_root = Node2D.new()
	bezos_drone_root.name = "BezosDroneEncounter"
	bezos_drone_root.position = bezos_drone_base_position
	bezos_drone_root.z_index = 4
	entities_layer.add_child(bezos_drone_root)

	var shadow := Polygon2D.new()
	shadow.name = "DroneShadow"
	shadow.color = Color(0.0, 0.0, 0.0, 0.22)
	shadow.polygon = _ellipse_points(Vector2(0, 72), Vector2(54, 15), 20)
	shadow.z_index = -2
	bezos_drone_root.add_child(shadow)

	# The scanner sits behind the artwork so the drone reads as an inspecting machine,
	# not as a static cutout pasted onto the map.
	var scanner_beam := Polygon2D.new()
	scanner_beam.name = "ScannerBeam"
	scanner_beam.color = Color(0.15, 0.9, 1.0, 0.16)
	scanner_beam.polygon = PackedVector2Array([
		Vector2(-13, -14),
		Vector2(-48, 78),
		Vector2(30, 78)
	])
	scanner_beam.z_index = 0
	bezos_drone_root.add_child(scanner_beam)

	var sprite := Sprite2D.new()
	sprite.name = "DroneSprite"
	sprite.texture = load("res://assets/mockups/bezos_drone_v2.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2(0.125, 0.125)
	sprite.z_index = 2
	bezos_drone_root.add_child(sprite)

	var scanner_eye := Polygon2D.new()
	scanner_eye.name = "ScannerEye"
	scanner_eye.color = Color(0.28, 0.96, 1.0, 0.9)
	scanner_eye.polygon = _ellipse_points(Vector2(-12, -18), Vector2(7, 5), 14)
	scanner_eye.z_index = 3
	bezos_drone_root.add_child(scanner_eye)

	var status_light := Polygon2D.new()
	status_light.name = "StatusLight"
	status_light.color = Color(1.0, 0.18, 0.08, 0.95)
	status_light.polygon = _ellipse_points(Vector2(1, -51), Vector2(3, 2), 10)
	status_light.z_index = 3
	bezos_drone_root.add_child(status_light)

	var motto := Label.new()
	motto.name = "DroneMotto"
	motto.text = "DELIVERY IS DESTINY"
	motto.position = Vector2(-90, 88)
	motto.size = Vector2(180, 16)
	motto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	motto.add_theme_font_size_override("font_size", 8)
	motto.add_theme_color_override("font_color", Color(0.98, 0.82, 0.3, 0.92))
	motto.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	motto.add_theme_constant_override("shadow_offset_x", 1)
	motto.add_theme_constant_override("shadow_offset_y", 1)
	motto.visible = false
	bezos_drone_root.add_child(motto)

	var trigger := Area2D.new()
	trigger.name = "BezosDroneTrigger"
	trigger.collision_layer = 0
	trigger.collision_mask = 1
	trigger.monitoring = true
	trigger.monitorable = true
	var trigger_shape := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(190, 150)
	trigger_shape.shape = shape
	trigger_shape.position = Vector2(0, 28)
	trigger.add_child(trigger_shape)
	trigger.body_entered.connect(_on_bezos_drone_trigger_body_entered)
	bezos_drone_root.add_child(trigger)

func _on_bezos_drone_trigger_body_entered(body: Node) -> void:
	if body == player:
		triggered.emit()

func start(dialogue_anchor_node: Control, typewriter_timer_node: Timer, typewriter_bip_node: AudioStreamPlayer, contamination_node: Node2D) -> void:
	dialogue_anchor = dialogue_anchor_node
	typewriter_timer = typewriter_timer_node
	typewriter_bip = typewriter_bip_node
	contamination_root = contamination_node
	bezos_escalation_active = true
	bezos_escalation_step = 0
	bezos_escalation_timer = 0.0
	bezos_escalation_space_latched = Input.is_physical_key_pressed(KEY_SPACE)
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	if dialogue_anchor:
		dialogue_anchor.visible = false
	if typewriter_timer:
		typewriter_timer.stop()
	if bezos_drone_root:
		var trigger := bezos_drone_root.get_node_or_null("BezosDroneTrigger") as Area2D
		if trigger:
			trigger.monitoring = false
		var motto := bezos_drone_root.get_node_or_null("DroneMotto") as Label
		if motto:
			motto.visible = true
	# Create in-world speech bubble above drone
	_create_bezos_escalation_bubble()
	_set_bezos_escalation_line(
		"AMZN DRONE",
		"Your Prime trial expired 1,247 days ago.\nRenew now?   [ YES ]   [ YES IN YELLOW ]",
		Color(1.0, 0.82, 0.3)
	)

func _is_bezos_escalation_advance_pressed() -> bool:
	var space_down := Input.is_physical_key_pressed(KEY_SPACE)
	var space_pressed := space_down and not bezos_escalation_space_latched
	bezos_escalation_space_latched = space_down
	return Input.is_action_just_pressed("ui_accept") or space_pressed

func _create_bezos_escalation_bubble() -> void:
	if bezos_escalation_bubble:
		bezos_escalation_bubble.queue_free()
	bezos_escalation_bubble = PanelContainer.new()
	bezos_escalation_bubble.position = Vector2(-150, -178)
	bezos_escalation_bubble.size = Vector2(300, 88)
	bezos_escalation_bubble.z_index = 10
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.08, 0.92)
	style.border_color = Color(0.98, 0.82, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	bezos_escalation_bubble.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	bezos_escalation_bubble.add_child(vbox)
	bezos_escalation_speaker_label = Label.new()
	bezos_escalation_speaker_label.add_theme_font_size_override("font_size", 10)
	bezos_escalation_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	vbox.add_child(bezos_escalation_speaker_label)
	bezos_escalation_text_label = Label.new()
	bezos_escalation_text_label.add_theme_font_size_override("font_size", 9)
	bezos_escalation_text_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.96))
	bezos_escalation_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(bezos_escalation_text_label)
	bezos_drone_root.add_child(bezos_escalation_bubble)
	bezos_escalation_bubble.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(bezos_escalation_bubble, "modulate:a", 1.0, 0.25)

func _set_bezos_escalation_line(speaker: String, text: String, color: Color) -> void:
	if not bezos_escalation_speaker_label or not bezos_escalation_text_label:
		return
	bezos_escalation_speaker_label.text = speaker
	bezos_escalation_speaker_label.add_theme_color_override("font_color", color)
	bezos_escalation_text_label.text = text
	_play_bezos_escalation_bips(text, speaker)
	# Flash effect on new line
	if bezos_escalation_bubble:
		bezos_escalation_bubble.modulate = Color(1.4, 1.4, 1.4, 1.0)
		var tw := create_tween()
		tw.tween_property(bezos_escalation_bubble, "modulate", Color.WHITE, 0.2)

func _play_bezos_escalation_bips(text: String, speaker: String) -> void:
	if not typewriter_bip:
		return
	if bezos_escalation_bip_tween and bezos_escalation_bip_tween.is_valid():
		bezos_escalation_bip_tween.kill()

	var stripped_len := text.replace(" ", "").replace("\n", "").length()
	var burst_count := clampi(int(ceil(stripped_len / 18.0)), 2, 6)
	var pitch_min := 0.96
	var pitch_max := 1.12
	match speaker:
		"AMZN DRONE":
			pitch_min = 1.12
			pitch_max = 1.24
		"BEZOS":
			pitch_min = 0.86
			pitch_max = 0.98
		"CITIZEN":
			pitch_min = 0.98
			pitch_max = 1.1

	bezos_escalation_bip_tween = create_tween()
	for i in range(burst_count):
		bezos_escalation_bip_tween.tween_callback(func():
			if not typewriter_bip:
				return
			typewriter_bip.pitch_scale = randf_range(pitch_min, pitch_max)
			typewriter_bip.play()
		)
		if i < burst_count - 1:
			bezos_escalation_bip_tween.tween_interval(0.045)


func process_frame(delta: float) -> void:
	if not bezos_drone_root:
		return

	bezos_drone_hover_time += delta * 2.1
	bezos_drone_root.position = bezos_drone_base_position + Vector2(0.0, sin(bezos_drone_hover_time) * 3.0)
	var scanner_beam := bezos_drone_root.get_node_or_null("ScannerBeam") as Polygon2D
	if scanner_beam:
		scanner_beam.rotation = sin(bezos_drone_hover_time * 1.7) * 0.11
		scanner_beam.modulate.a = 0.65 + sin(bezos_drone_hover_time * 2.4) * 0.25
	var scanner_eye := bezos_drone_root.get_node_or_null("ScannerEye") as Polygon2D
	if scanner_eye:
		var eye_pulse := 1.0 + sin(bezos_drone_hover_time * 4.8) * 0.1
		scanner_eye.scale = Vector2.ONE * eye_pulse
		scanner_eye.modulate.a = 0.78 + sin(bezos_drone_hover_time * 4.8) * 0.2
	var status_light := bezos_drone_root.get_node_or_null("StatusLight") as Polygon2D
	if status_light:
		status_light.visible = fmod(bezos_drone_hover_time, 1.0) < 0.72

	# --- In-world escalation dialogue ---
	if not bezos_escalation_active:
		return
	bezos_escalation_timer += delta
	# Drone shakes more as conversation heats up
	if bezos_escalation_step >= 4:
		var shake := sin(bezos_escalation_timer * 22.0) * 2.0
		bezos_drone_root.position.x = bezos_drone_base_position.x + shake
	elif bezos_escalation_step >= 2:
		var shake := sin(bezos_escalation_timer * 14.0) * 0.8
		bezos_drone_root.position.x = bezos_drone_base_position.x + shake

	var advance_pressed := _is_bezos_escalation_advance_pressed()

	# --- Contamination Spectral Breathing & Shader ---
	if contamination_root and contamination_root.visible:
		var spr := contamination_root.get_node_or_null("Sprite") as Sprite2D
		if spr:
			var base_scale := float(spr.get_meta("base_scale", 0.22))
			var breath := 1.0 + sin(Time.get_ticks_msec() * 0.003) * 0.03
			spr.scale = Vector2(base_scale, base_scale * breath)
			if spr.material is ShaderMaterial:
				spr.material.set_shader_parameter("time", Time.get_ticks_msec() * 0.001)

	match bezos_escalation_step:
		0:
			if advance_pressed:
				bezos_escalation_step = 1
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"...Where's the 'no' button?",
					Color(0.4, 0.75, 1.0)
				)
		1:
			if advance_pressed:
				bezos_escalation_step = 2
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"AMZN DRONE",
					"That option was deprecated.\nAlgorithmically, you already said yes.",
					Color(1.0, 0.82, 0.3)
				)
		2:
			if advance_pressed:
				bezos_escalation_step = 3
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"You time workers to the second, move bridges for yachts,\nand launch rockets while a drone invoices pedestrians.\nI only need a passport signature.",
					Color(0.4, 0.75, 1.0)
				)
		3:
			if advance_pressed:
				bezos_escalation_step = 4
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"AMZN DRONE",
					"Complaint summary accepted.\nOwner escalation is mandatory and non-refundable.",
					Color(1.0, 0.82, 0.3)
				)
		4:
			if advance_pressed:
				bezos_escalation_active = false
				if bezos_escalation_bubble:
					bezos_escalation_bubble.visible = false
				bezos_escalation_step = 5
				call_deferred("_request_dialogue")
		5:
			# This step is now handled by the dialogue system's callback
			pass

func _request_dialogue() -> void:
	dialogue_requested.emit("jeff_bezos")


func _ellipse_points(center: Vector2, radius: Vector2, segments: int = 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points


func prepare_cinematic() -> void:
	bezos_escalation_active = false
	if bezos_escalation_bip_tween and bezos_escalation_bip_tween.is_valid():
		bezos_escalation_bip_tween.kill()
	if bezos_escalation_bubble:
		bezos_escalation_bubble.queue_free()
		bezos_escalation_bubble = null


func remove_drone() -> void:
	bezos_escalation_active = false
	bezos_escalation_bubble = null
	if bezos_drone_root:
		bezos_drone_root.queue_free()
		bezos_drone_root = null
