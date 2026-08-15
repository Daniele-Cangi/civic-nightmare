extends Control

signal telemetry_changed(citizen_hp: float, bezos_hp: float, legal_shield: float, seconds_left: int)
signal resolved(result: Dictionary)

const VIEW_SIZE := Vector2(1280, 720)
const POSE_CELL := Vector2(627, 627)
const ROUND_SECONDS := 32.0
const ATTACK_WARNING_SECONDS := 1.35
const ATTACK_RECOVERY_SECONDS := 0.42
const CONTEST_COOLDOWN_SECONDS := 0.18
const ATTACK_SEQUENCE := ["prime_delivery", "terms_sweep", "one_click_charge"]

var active: bool = false
var elapsed: float = 0.0
var citizen_hp: float = 100.0
var bezos_hp: float = 72.0
var legal_shield: float = 48.0
var attack_wait: float = 2.8
var prompt_limit: float = 2.8
var guided_contest_step: int = 0
var guided_round: int = 0
var active_attack: String = ""
var active_attack_elapsed: float = 0.0
var active_attack_resolved: bool = false
var objection_filed: bool = false
var next_attack_index: int = 0
var contest_cooldown: float = 0.0
var pose_until: float = -1.0
var contest_latched: bool = false
var objection_latched: bool = false
var contest_count: int = 0
var objection_count: int = 0
var intercepted_attacks: int = 0
var suffered_charges: int = 0
var battle_result: Dictionary = {}

var arena_texture: TextureRect
var ambient_tint: ColorRect
var bezos_sprite: Sprite2D
var citizen_sprite: Sprite2D
var legal_shield_ring: Polygon2D
var attack_fx: Control
var tutorial_panel: PanelContainer
var tutorial_title: Label
var tutorial_sequence: Label
var tutorial_progress: ProgressBar
var warning_panel: PanelContainer
var warning_title: Label
var warning_subtitle: Label
var warning_progress: ProgressBar
var contest_button: Button
var objection_button: Button


func setup() -> void:
	position = Vector2.ZERO
	size = VIEW_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_stage()
	visible = false


func start() -> void:
	active = true
	visible = true
	elapsed = 0.0
	citizen_hp = 100.0
	bezos_hp = 72.0
	legal_shield = 48.0
	attack_wait = 3.2
	prompt_limit = 3.2
	guided_contest_step = 0
	guided_round = 0
	active_attack = ""
	active_attack_elapsed = 0.0
	active_attack_resolved = false
	objection_filed = false
	next_attack_index = 0
	contest_cooldown = 0.0
	pose_until = -1.0
	contest_count = 0
	objection_count = 0
	intercepted_attacks = 0
	suffered_charges = 0
	battle_result.clear()
	contest_latched = Input.is_action_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_Z)
	objection_latched = Input.is_physical_key_pressed(KEY_X) or Input.is_physical_key_pressed(KEY_SHIFT)
	_set_pose(bezos_sprite, Vector2i(0, 0))
	_set_pose(citizen_sprite, Vector2i(0, 0))
	bezos_sprite.modulate = Color.WHITE
	citizen_sprite.modulate = Color.WHITE
	legal_shield_ring.visible = true
	_start_guided_round(true)
	_clear_attack_fx()
	_update_controls()
	_emit_telemetry()


func stop() -> void:
	active = false
	visible = false
	_clear_attack_fx()


func process_frame(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	contest_cooldown = maxf(contest_cooldown - delta, 0.0)
	_read_actions()
	if not active:
		return
	_update_ambient_motion(delta)
	_update_fighter_motion()
	_update_attack(delta)
	_update_controls()
	_emit_telemetry()

	if citizen_hp <= 0.0:
		_finish_battle("administrative_defeat")
	elif bezos_hp <= 0.0:
		_finish_battle("citizen_victory")
	elif elapsed >= ROUND_SECONDS:
		_finish_battle("processing_timeout")


func perform_contest() -> bool:
	if not active:
		return false
	if active_attack != "":
		_fail_input()
		return false
	if contest_cooldown > 0.0:
		return false
	contest_cooldown = CONTEST_COOLDOWN_SECONDS
	contest_count += 1
	pose_until = elapsed + 0.26
	_set_pose(citizen_sprite, Vector2i(1, 0))
	var damage := 8.0
	if legal_shield > 0.0:
		legal_shield = maxf(legal_shield - damage, 0.0)
		_flash(legal_shield_ring, Color(1.6, 0.45, 0.18), 0.16)
	else:
		bezos_hp = maxf(bezos_hp - damage, 0.0)
		_set_pose(bezos_sprite, Vector2i(0, 1))
		_flash(bezos_sprite, Color(1.7, 0.35, 0.22), 0.16)
	if bezos_hp > 0.0:
		_advance_guided_contest()
	return true


func perform_objection() -> bool:
	if not active:
		return false
	if objection_filed:
		return false
	if active_attack == "" or active_attack_resolved:
		_fail_input()
		return false
	objection_count += 1
	objection_filed = true
	active_attack_resolved = true
	intercepted_attacks += 1
	active_attack_elapsed = ATTACK_WARNING_SECONDS
	pose_until = elapsed + 0.36
	_set_pose(citizen_sprite, Vector2i(0, 1))
	warning_title.text = "✓"
	warning_subtitle.text = ""
	warning_progress.value = 1.0
	_clear_attack_fx()
	_flash(citizen_sprite, Color(0.45, 1.2, 1.45), 0.14)
	return true


func get_result() -> Dictionary:
	return battle_result.duplicate(true)


func _build_stage() -> void:
	arena_texture = TextureRect.new()
	arena_texture.name = "FulfillmentCathedral"
	arena_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena_texture.texture = load("res://assets/mockups/bezos_fulfillment_cathedral.png")
	arena_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena_texture.stretch_mode = TextureRect.STRETCH_SCALE
	arena_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arena_texture)

	ambient_tint = ColorRect.new()
	ambient_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	ambient_tint.color = Color(0.02, 0.04, 0.09, 0.08)
	ambient_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ambient_tint)

	legal_shield_ring = Polygon2D.new()
	legal_shield_ring.polygon = _ellipse_points(Vector2.ZERO, Vector2(112, 166), 32)
	legal_shield_ring.position = Vector2(324, 412)
	legal_shield_ring.color = Color(1.0, 0.72, 0.12, 0.12)
	legal_shield_ring.z_index = 2
	add_child(legal_shield_ring)

	bezos_sprite = _create_fighter("res://assets/mockups/bezos_battle_poses.png", Vector2(322, 382), Vector2(0.77, 0.77), false)
	bezos_sprite.name = "BezosFighter"
	citizen_sprite = _create_fighter("res://assets/mockups/citizen_battle_poses.png", Vector2(942, 392), Vector2(0.77, 0.77), true)
	citizen_sprite.name = "CitizenFighter"

	attack_fx = Control.new()
	attack_fx.name = "AttackFX"
	attack_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	attack_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attack_fx.z_index = 5
	add_child(attack_fx)

	tutorial_panel = PanelContainer.new()
	tutorial_panel.position = Vector2(460, 94)
	tutorial_panel.size = Vector2(360, 118)
	tutorial_panel.z_index = 8
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tutorial_style := StyleBoxFlat.new()
	tutorial_style.bg_color = Color(0.025, 0.035, 0.05, 0.95)
	tutorial_style.border_color = Color(0.95, 0.7, 0.16, 0.95)
	tutorial_style.set_border_width_all(2)
	tutorial_style.set_corner_radius_all(3)
	tutorial_style.set_content_margin_all(8)
	tutorial_panel.add_theme_stylebox_override("panel", tutorial_style)
	add_child(tutorial_panel)
	var tutorial_stack := VBoxContainer.new()
	tutorial_stack.add_theme_constant_override("separation", 4)
	tutorial_panel.add_child(tutorial_stack)
	tutorial_title = Label.new()
	tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_title.add_theme_font_size_override("font_size", 34)
	tutorial_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	tutorial_stack.add_child(tutorial_title)
	tutorial_sequence = Label.new()
	tutorial_sequence.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_sequence.add_theme_font_size_override("font_size", 16)
	tutorial_sequence.add_theme_color_override("font_color", Color(0.9, 0.94, 0.96))
	tutorial_stack.add_child(tutorial_sequence)
	tutorial_progress = _create_prompt_progress(Color(0.95, 0.7, 0.16))
	tutorial_stack.add_child(tutorial_progress)

	warning_panel = PanelContainer.new()
	warning_panel.position = Vector2(460, 94)
	warning_panel.size = Vector2(360, 118)
	warning_panel.z_index = 8
	warning_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var warning_style := StyleBoxFlat.new()
	warning_style.bg_color = Color(0.025, 0.035, 0.05, 0.94)
	warning_style.border_color = Color(1.0, 0.34, 0.12, 0.95)
	warning_style.set_border_width_all(2)
	warning_style.set_corner_radius_all(3)
	warning_style.set_content_margin_all(8)
	warning_panel.add_theme_stylebox_override("panel", warning_style)
	add_child(warning_panel)
	var warning_stack := VBoxContainer.new()
	warning_stack.add_theme_constant_override("separation", 4)
	warning_panel.add_child(warning_stack)
	warning_title = Label.new()
	warning_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_title.add_theme_font_size_override("font_size", 34)
	warning_title.add_theme_color_override("font_color", Color(0.32, 0.88, 1.0))
	warning_stack.add_child(warning_title)
	warning_subtitle = Label.new()
	warning_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_subtitle.add_theme_font_size_override("font_size", 16)
	warning_subtitle.add_theme_color_override("font_color", Color(0.82, 0.87, 0.9))
	warning_stack.add_child(warning_subtitle)
	warning_progress = _create_prompt_progress(Color(1.0, 0.34, 0.12))
	warning_stack.add_child(warning_progress)
	warning_panel.visible = false

	contest_button = _create_action_button("CONTEST\nSPACE / Z", Vector2(668, 654), Color(0.95, 0.7, 0.16))
	contest_button.pressed.connect(perform_contest)
	objection_button = _create_action_button("OBJECT\nX / SHIFT", Vector2(944, 654), Color(0.2, 0.75, 0.9))
	objection_button.pressed.connect(perform_objection)


func _create_fighter(path: String, fighter_position: Vector2, fighter_scale: Vector2, flip_h: bool) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _pose_texture(path, Vector2i(0, 0))
	sprite.position = fighter_position
	sprite.scale = fighter_scale
	sprite.flip_h = flip_h
	sprite.z_index = 3
	add_child(sprite)
	return sprite


func _pose_texture(path: String, cell: Vector2i) -> AtlasTexture:
	var pose := AtlasTexture.new()
	pose.atlas = load(path)
	pose.region = Rect2(Vector2(cell.x, cell.y) * POSE_CELL, POSE_CELL)
	return pose


func _set_pose(sprite: Sprite2D, cell: Vector2i) -> void:
	if not sprite:
		return
	var path := "res://assets/mockups/bezos_battle_poses.png" if sprite == bezos_sprite else "res://assets/mockups/citizen_battle_poses.png"
	sprite.texture = _pose_texture(path, cell)


func _create_action_button(text: String, button_position: Vector2, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.position = button_position
	button.size = Vector2(260, 58)
	button.z_index = 10
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.035, 0.05, 0.94)
	normal.border_color = accent.darkened(0.18)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(3)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = accent.darkened(0.72)
	hover.border_color = accent
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.025, 0.03, 0.04, 0.82)
	disabled.border_color = Color(0.25, 0.28, 0.31, 0.75)
	button.add_theme_stylebox_override("disabled", disabled)
	add_child(button)
	return button


func _create_prompt_progress(accent: Color) -> ProgressBar:
	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(0, 10)
	progress.min_value = 0.0
	progress.max_value = 1.0
	progress.value = 0.0
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.1, 0.13, 0.96)
	background.set_corner_radius_all(2)
	progress.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = accent
	fill.set_corner_radius_all(2)
	progress.add_theme_stylebox_override("fill", fill)
	return progress


func _read_actions() -> void:
	var contest_down := Input.is_action_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_Z)
	if contest_down and not contest_latched:
		perform_contest()
	contest_latched = contest_down
	var objection_down := Input.is_physical_key_pressed(KEY_X) or Input.is_physical_key_pressed(KEY_SHIFT)
	if objection_down and not objection_latched:
		perform_objection()
	objection_latched = objection_down


func _update_attack(delta: float) -> void:
	if active_attack == "":
		attack_wait -= delta
		tutorial_progress.value = clampf(1.0 - attack_wait / maxf(prompt_limit, 0.01), 0.0, 1.0)
		if attack_wait <= 0.0:
			_fail_input()
		return

	active_attack_elapsed += delta
	_update_attack_visual()
	if active_attack_elapsed >= ATTACK_WARNING_SECONDS and not active_attack_resolved:
		_resolve_attack()
	if active_attack_elapsed >= ATTACK_WARNING_SECONDS + ATTACK_RECOVERY_SECONDS:
		_clear_attack_fx()
		if elapsed >= pose_until:
			_set_pose(bezos_sprite, Vector2i(0, 0))
			_set_pose(citizen_sprite, Vector2i(0, 0))
		_start_guided_round(false)


func _start_guided_round(first_round: bool) -> void:
	active_attack = ""
	active_attack_elapsed = 0.0
	active_attack_resolved = false
	objection_filed = false
	guided_contest_step = 0
	guided_round += 1
	prompt_limit = 3.2 if first_round else maxf(1.55, 2.25 - float(guided_round - 1) * 0.08)
	attack_wait = prompt_limit
	tutorial_panel.visible = true
	warning_panel.visible = false
	tutorial_progress.value = 0.0
	_update_guided_prompt()


func _advance_guided_contest() -> void:
	guided_contest_step += 1
	if guided_contest_step >= 2:
		var attack_id := str(ATTACK_SEQUENCE[next_attack_index % ATTACK_SEQUENCE.size()])
		next_attack_index += 1
		_begin_attack(attack_id)
		return
	prompt_limit = maxf(1.45, 2.1 - float(guided_round - 1) * 0.07)
	attack_wait = prompt_limit
	tutorial_progress.value = 0.0
	_update_guided_prompt()


func _update_guided_prompt() -> void:
	tutorial_title.text = "CONTEST"
	tutorial_sequence.text = "[ SPACE / Z ]"


func _begin_attack(attack_id: String) -> void:
	active_attack = attack_id
	active_attack_elapsed = 0.0
	active_attack_resolved = false
	objection_filed = false
	tutorial_panel.visible = false
	warning_title.text = "OBJECT"
	warning_subtitle.text = "[ X / SHIFT ]"
	warning_progress.value = 0.0
	warning_panel.visible = true
	_set_pose(bezos_sprite, Vector2i(1, 0))
	pose_until = elapsed + ATTACK_WARNING_SECONDS + ATTACK_RECOVERY_SECONDS
	_create_attack_visual(attack_id)


func _resolve_attack() -> void:
	active_attack_resolved = true
	if active_attack == "one_click_charge":
		suffered_charges += 1
	_fail_input()


func _create_attack_visual(attack_id: String) -> void:
	_clear_attack_fx()
	match attack_id:
		"prime_delivery":
			var parcel := PanelContainer.new()
			parcel.name = "IncomingParcel"
			parcel.position = Vector2(430, 260)
			parcel.size = Vector2(72, 54)
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.55, 0.31, 0.12)
			style.border_color = Color(1.0, 0.72, 0.18)
			style.set_border_width_all(3)
			parcel.add_theme_stylebox_override("panel", style)
			attack_fx.add_child(parcel)
		"terms_sweep":
			var ribbon := ColorRect.new()
			ribbon.name = "TermsRibbon"
			ribbon.position = Vector2(380, 468)
			ribbon.size = Vector2(8, 70)
			ribbon.color = Color(0.94, 0.91, 0.78, 0.96)
			attack_fx.add_child(ribbon)
		"one_click_charge":
			var popup := PanelContainer.new()
			popup.name = "ChargePopup"
			popup.position = Vector2(715, 268)
			popup.size = Vector2(250, 116)
			var popup_style := StyleBoxFlat.new()
			popup_style.bg_color = Color(0.93, 0.93, 0.9)
			popup_style.border_color = Color(0.92, 0.45, 0.08)
			popup_style.set_border_width_all(3)
			popup.add_theme_stylebox_override("panel", popup_style)
			for line_index in range(3):
				var line := ColorRect.new()
				line.position = Vector2(22, 20 + line_index * 18)
				line.size = Vector2(160 - line_index * 26, 7)
				line.color = Color(0.18, 0.2, 0.23, 0.72)
				popup.add_child(line)
			var purchase_button := ColorRect.new()
			purchase_button.position = Vector2(58, 82)
			purchase_button.size = Vector2(134, 18)
			purchase_button.color = Color(0.95, 0.43, 0.07)
			popup.add_child(purchase_button)
			attack_fx.add_child(popup)


func _update_attack_visual() -> void:
	var progress := clampf(active_attack_elapsed / ATTACK_WARNING_SECONDS, 0.0, 1.0)
	warning_progress.value = progress
	if not objection_filed and not active_attack_resolved and progress >= 0.68:
		warning_title.text = "OBJECT!"
	elif objection_filed:
		warning_title.text = "✓"
	match active_attack:
		"prime_delivery":
			var parcel := attack_fx.get_node_or_null("IncomingParcel") as Control
			if parcel:
				parcel.position = Vector2(lerpf(430.0, 930.0, progress), lerpf(260.0, 455.0, progress) + sin(progress * PI) * -90.0)
				parcel.rotation = progress * 4.0
		"terms_sweep":
			var ribbon := attack_fx.get_node_or_null("TermsRibbon") as ColorRect
			if ribbon:
				ribbon.size.x = lerpf(8.0, 620.0, progress)
		"one_click_charge":
			var popup := attack_fx.get_node_or_null("ChargePopup") as Control
			if popup:
				var pulse := 1.0 + sin(progress * PI * 5.0) * 0.035
				popup.scale = Vector2(pulse, pulse)


func _clear_attack_fx() -> void:
	if not attack_fx:
		return
	for child in attack_fx.get_children():
		child.queue_free()


func _update_ambient_motion(delta: float) -> void:
	legal_shield_ring.rotation += delta * 0.22
	legal_shield_ring.modulate.a = 0.68 + sin(elapsed * 4.4) * 0.18
	ambient_tint.color.a = 0.07 + sin(elapsed * 1.7) * 0.018


func _update_fighter_motion() -> void:
	var bezos_base := Vector2(322, 382)
	var citizen_base := Vector2(942, 392)
	bezos_sprite.position = bezos_base + Vector2(0, sin(elapsed * 2.2) * 2.0)
	citizen_sprite.position = citizen_base + Vector2(sin(elapsed * 4.1) * 1.4, absf(sin(elapsed * 3.3)) * 2.4)
	if elapsed >= pose_until and active_attack == "":
		_set_pose(bezos_sprite, Vector2i(0, 0))
		_set_pose(citizen_sprite, Vector2i(0, 0))


func _update_controls() -> void:
	if not contest_button or not objection_button:
		return
	if not active:
		contest_button.disabled = true
		objection_button.disabled = true
		return
	var pulse := 0.88 + (sin(elapsed * 8.0) + 1.0) * 0.06
	if active_attack == "":
		contest_button.disabled = contest_cooldown > 0.0
		objection_button.disabled = false
		contest_button.text = "CONTEST\nSPACE / Z"
		objection_button.text = "OBJECT\nX / SHIFT"
		contest_button.modulate = Color(1.0, 0.9 + pulse * 0.08, 0.72, pulse if contest_cooldown <= 0.0 else 0.72)
		objection_button.modulate = Color(0.42, 0.46, 0.5, 0.54)
	elif objection_filed or active_attack_resolved:
		contest_button.disabled = true
		objection_button.disabled = true
		contest_button.text = "CONTEST\nSPACE / Z"
		objection_button.text = "✓"
		contest_button.modulate = Color(0.62, 0.66, 0.7, 0.66)
		objection_button.modulate = Color(0.65, 1.0, 1.0, 0.9)
	else:
		contest_button.disabled = false
		objection_button.disabled = false
		contest_button.text = "CONTEST\nSPACE / Z"
		objection_button.text = "OBJECT\nX / SHIFT"
		contest_button.modulate = Color(0.42, 0.46, 0.5, 0.54)
		objection_button.modulate = Color(0.72, 0.94, 1.0, pulse)


func _emit_telemetry() -> void:
	telemetry_changed.emit(
		citizen_hp,
		bezos_hp,
		legal_shield,
		maxi(int(ceil(ROUND_SECONDS - elapsed)), 0)
	)


func _finish_battle(outcome: String) -> void:
	if not active:
		return
	active = false
	contest_button.disabled = true
	objection_button.disabled = true
	tutorial_panel.visible = false
	warning_panel.visible = false
	_clear_attack_fx()
	if outcome == "citizen_victory":
		_set_pose(bezos_sprite, Vector2i(1, 1))
		_set_pose(citizen_sprite, Vector2i(0, 0))
	else:
		_set_pose(citizen_sprite, Vector2i(1, 1))
		_set_pose(bezos_sprite, Vector2i(0, 0))
	battle_result = {
		"outcome": outcome,
		"contest_count": contest_count,
		"objection_count": objection_count,
		"intercepted_attacks": intercepted_attacks,
		"suffered_charges": suffered_charges,
		"elapsed_seconds": snappedf(elapsed, 0.1),
		"profile_was_known": false,
	}
	resolved.emit(battle_result.duplicate(true))


func _fail_input() -> void:
	if not active:
		return
	citizen_hp = 0.0
	_finish_battle("administrative_defeat")


func _flash(canvas_item: CanvasItem, flash_color: Color, duration: float) -> void:
	if not canvas_item:
		return
	canvas_item.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(canvas_item, "modulate", Color.WHITE, duration)


func _ellipse_points(center: Vector2, radius: Vector2, segments: int = 28) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points
