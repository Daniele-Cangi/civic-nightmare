extends Control

signal telemetry_changed(citizen_hp: float, bezos_hp: float, legal_shield: float, seconds_left: int)
signal resolved(result: Dictionary)

const VIEW_SIZE := Vector2(1280, 720)
const POSE_CELL := Vector2(627, 627)
const ROUND_SECONDS := 82.0
const CITIZEN_ROUND_HP := 100.0
const BEZOS_ROUND_HP := 96.0
const LEGAL_SHIELD_ROUND_HP := 56.0
const WINS_TO_CLAIM := 2
const ROUND_BREAK_SECONDS := 1.65
const MUSIC_PATH := "res://assets/audio/civic_nightmare_bezos_goofy_arcade_steel_strike.ogg"
const MUSIC_LOOP_OFFSET := 14.0
const ATTACK_WARNING_SECONDS := 1.35
const ATTACK_RECOVERY_SECONDS := 0.42
const CONTEST_COOLDOWN_SECONDS := 0.18
const OBJECTION_HOLD_SECONDS := 0.56
const MISTAKE_DAMAGE := 20.0
const ATTACK_SEQUENCE := ["prime_delivery", "terms_sweep", "one_click_charge"]

var active: bool = false
var elapsed: float = 0.0
var round_elapsed: float = 0.0
var citizen_hp: float = CITIZEN_ROUND_HP
var bezos_hp: float = BEZOS_ROUND_HP
var legal_shield: float = LEGAL_SHIELD_ROUND_HP
var round_number: int = 1
var citizen_round_wins: int = 0
var bezos_round_wins: int = 0
var round_transition_active: bool = false
var round_transition_elapsed: float = 0.0
var round_results: Array[String] = []
var attack_wait: float = 2.8
var prompt_limit: float = 2.8
var guided_contest_step: int = 0
var guided_round: int = 0
var active_attack: String = ""
var active_attack_elapsed: float = 0.0
var active_attack_resolved: bool = false
var objection_filed: bool = false
var objection_hold_progress: float = 0.0
var next_attack_index: int = 0
var contest_cooldown: float = 0.0
var pose_until: float = -1.0
var contest_latched: bool = false
var objection_latched: bool = false
var touch_contest_down: bool = false
var touch_objection_down: bool = false
var contest_count: int = 0
var objection_count: int = 0
var intercepted_attacks: int = 0
var suffered_charges: int = 0
var mistake_count: int = 0
var damage_shake_until: float = -1.0
var battle_result: Dictionary = {}

var arena_texture: TextureRect
var ambient_tint: ColorRect
var bezos_sprite: Sprite2D
var citizen_sprite: Sprite2D
var legal_shield_ring: Polygon2D
var attack_fx: Control
var damage_flash: ColorRect
var tutorial_panel: PanelContainer
var tutorial_title: Label
var warning_panel: PanelContainer
var warning_title: Label
var warning_subtitle: Label
var warning_progress: ProgressBar
var round_score_label: Label
var round_banner: Label
var music_player: AudioStreamPlayer
var shield_hit_audio: AudioStreamPlayer
var body_hit_audio: AudioStreamPlayer
var round_audio: AudioStreamPlayer


func setup() -> void:
	position = Vector2.ZERO
	size = VIEW_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_stage()
	_create_audio()
	visible = false


func start() -> void:
	active = true
	visible = true
	elapsed = 0.0
	round_elapsed = 0.0
	round_number = 1
	citizen_round_wins = 0
	bezos_round_wins = 0
	round_transition_active = false
	round_transition_elapsed = 0.0
	round_results.clear()
	next_attack_index = 0
	contest_count = 0
	objection_count = 0
	intercepted_attacks = 0
	suffered_charges = 0
	mistake_count = 0
	damage_shake_until = -1.0
	battle_result.clear()
	touch_contest_down = false
	touch_objection_down = false
	contest_latched = Input.is_physical_key_pressed(KEY_Z)
	objection_latched = Input.is_physical_key_pressed(KEY_X)
	_set_pose(bezos_sprite, Vector2i(0, 0))
	_set_pose(citizen_sprite, Vector2i(0, 0))
	bezos_sprite.modulate = Color.WHITE
	citizen_sprite.modulate = Color.WHITE
	damage_flash.color.a = 0.0
	round_banner.visible = false
	_reset_round_state(true)
	_start_music()
	_emit_telemetry()


func stop() -> void:
	active = false
	touch_contest_down = false
	touch_objection_down = false
	visible = false
	_clear_attack_fx()
	_stop_audio()


func process_frame(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	if round_transition_active:
		_update_ambient_motion(delta)
		_update_fighter_motion()
		_update_round_transition(delta)
		_emit_telemetry()
		return
	round_elapsed += delta
	contest_cooldown = maxf(contest_cooldown - delta, 0.0)
	_read_actions(delta)
	if not active:
		return
	_update_ambient_motion(delta)
	_update_fighter_motion()
	_update_attack(delta)
	if not active:
		return
	_emit_telemetry()

	if citizen_hp <= 0.0:
		_resolve_round("administrative_defeat")
	elif bezos_hp <= 0.0:
		_resolve_round("citizen_victory")


func perform_contest() -> bool:
	if not active:
		return false
	if active_attack != "":
		_penalize_current_prompt()
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
		shield_hit_audio.play()
		_flash(legal_shield_ring, Color(1.6, 0.45, 0.18), 0.16)
		_punch_scale(legal_shield_ring, Vector2.ONE * (0.72 + 0.28 * legal_shield / LEGAL_SHIELD_ROUND_HP))
		if legal_shield <= 0.0:
			var shield_tween := create_tween()
			shield_tween.tween_interval(0.16)
			shield_tween.tween_callback(func(): legal_shield_ring.visible = false)
	else:
		bezos_hp = maxf(bezos_hp - damage, 0.0)
		body_hit_audio.play()
		_set_pose(bezos_sprite, Vector2i(0, 1))
		_flash(bezos_sprite, Color(1.7, 0.35, 0.22), 0.16)
		_punch_scale(bezos_sprite, Vector2(0.77, 0.77))
	_punch_scale(citizen_sprite, Vector2(0.77, 0.77))
	if bezos_hp > 0.0:
		_advance_guided_contest()
	return true


func perform_objection() -> bool:
	if not active:
		return false
	if objection_filed:
		return false
	if active_attack == "" or active_attack_resolved:
		_penalize_current_prompt()
		return false
	objection_count += 1
	objection_filed = true
	active_attack_resolved = true
	intercepted_attacks += 1
	active_attack_elapsed = ATTACK_WARNING_SECONDS
	pose_until = elapsed + 0.36
	_set_pose(citizen_sprite, Vector2i(0, 1))
	warning_progress.value = 1.0
	warning_panel.visible = false
	_clear_attack_fx()
	_flash(citizen_sprite, Color(0.45, 1.2, 1.45), 0.14)
	_flash(bezos_sprite, Color(0.32, 0.92, 1.2), 0.12)
	_punch_scale(citizen_sprite, Vector2(0.77, 0.77))
	return true


func advance_objection_hold(delta: float) -> bool:
	if not active or active_attack == "" or objection_filed or active_attack_resolved:
		return false
	objection_hold_progress = minf(objection_hold_progress + maxf(delta, 0.0), OBJECTION_HOLD_SECONDS)
	warning_progress.value = objection_hold_progress / OBJECTION_HOLD_SECONDS
	if objection_hold_progress >= OBJECTION_HOLD_SECONDS:
		return perform_objection()
	return false


func get_result() -> Dictionary:
	return battle_result.duplicate(true)


func get_touch_profile() -> String:
	if not active or round_transition_active:
		return ""
	return "bezos_objection" if active_attack != "" else "bezos_contest"


func set_touch_control(control_id: String, pressed: bool) -> void:
	match control_id:
		"contest":
			touch_contest_down = pressed
		"objection":
			touch_objection_down = pressed


func get_round_maxima() -> Dictionary:
	return {
		"citizen_hp": CITIZEN_ROUND_HP,
		"bezos_hp": BEZOS_ROUND_HP,
		"legal_shield": LEGAL_SHIELD_ROUND_HP,
	}


func get_music_asset_path() -> String:
	return MUSIC_PATH


func start_music_preview() -> void:
	_start_music()


func _reset_round_state(first_match_round: bool) -> void:
	round_elapsed = 0.0
	citizen_hp = CITIZEN_ROUND_HP
	bezos_hp = BEZOS_ROUND_HP
	legal_shield = LEGAL_SHIELD_ROUND_HP
	attack_wait = 3.2 if first_match_round else 2.65
	prompt_limit = attack_wait
	guided_contest_step = 0
	guided_round = 0
	active_attack = ""
	active_attack_elapsed = 0.0
	active_attack_resolved = false
	objection_filed = false
	objection_hold_progress = 0.0
	contest_cooldown = 0.0
	pose_until = -1.0
	contest_latched = Input.is_physical_key_pressed(KEY_Z)
	objection_latched = Input.is_physical_key_pressed(KEY_X)
	legal_shield_ring.visible = true
	legal_shield_ring.scale = Vector2.ONE
	legal_shield_ring.modulate = Color.WHITE
	bezos_sprite.modulate = Color.WHITE
	citizen_sprite.modulate = Color.WHITE
	_set_pose(bezos_sprite, Vector2i(0, 0))
	_set_pose(citizen_sprite, Vector2i(0, 0))
	_clear_attack_fx()
	_start_guided_round(first_match_round)
	_update_round_score()


func _resolve_round(outcome: String) -> void:
	if not active or round_transition_active:
		return
	tutorial_panel.visible = false
	warning_panel.visible = false
	_clear_attack_fx()
	round_results.append(outcome)
	if outcome == "citizen_victory":
		citizen_round_wins += 1
		_set_pose(bezos_sprite, Vector2i(1, 1))
		_set_pose(citizen_sprite, Vector2i(0, 0))
		round_banner.text = "ROUND %d\nCITIZEN" % round_number
	else:
		bezos_round_wins += 1
		_set_pose(citizen_sprite, Vector2i(1, 1))
		_set_pose(bezos_sprite, Vector2i(0, 0))
		round_banner.text = "ROUND %d\nFULFILLED BY BEZOS" % round_number
	_update_round_score()
	round_audio.play()
	if citizen_round_wins >= WINS_TO_CLAIM or bezos_round_wins >= WINS_TO_CLAIM:
		_finish_battle(outcome)
		return
	round_transition_active = true
	round_transition_elapsed = 0.0
	round_banner.visible = true


func _update_round_transition(delta: float) -> void:
	round_transition_elapsed += delta
	if round_transition_elapsed >= ROUND_BREAK_SECONDS * 0.54:
		round_banner.text = "ROUND %d" % (round_number + 1)
	if round_transition_elapsed < ROUND_BREAK_SECONDS:
		return
	round_transition_active = false
	round_transition_elapsed = 0.0
	round_number += 1
	round_banner.visible = false
	_reset_round_state(false)


func _update_round_score() -> void:
	if not round_score_label:
		return
	round_score_label.text = "BEZOS  %s     ROUND %d     %s  CITIZEN" % [
		_round_marks(bezos_round_wins),
		round_number,
		_round_marks(citizen_round_wins),
	]


func _round_marks(wins: int) -> String:
	var marks := ""
	for index in range(WINS_TO_CLAIM):
		marks += "●" if index < wins else "○"
	return marks


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

	damage_flash = ColorRect.new()
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(0.82, 0.04, 0.02, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash.z_index = 6
	add_child(damage_flash)

	tutorial_panel = PanelContainer.new()
	tutorial_panel.position = Vector2(530, 92)
	tutorial_panel.size = Vector2(220, 94)
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
	tutorial_title.add_theme_font_size_override("font_size", 54)
	tutorial_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	tutorial_stack.add_child(tutorial_title)

	warning_panel = PanelContainer.new()
	warning_panel.position = Vector2(530, 92)
	warning_panel.size = Vector2(220, 132)
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
	warning_title.add_theme_font_size_override("font_size", 54)
	warning_title.add_theme_color_override("font_color", Color(0.32, 0.88, 1.0))
	warning_stack.add_child(warning_title)
	warning_subtitle = Label.new()
	warning_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_subtitle.add_theme_font_size_override("font_size", 16)
	warning_subtitle.add_theme_color_override("font_color", Color(0.82, 0.87, 0.9))
	warning_stack.add_child(warning_subtitle)
	warning_progress = _create_prompt_progress(Color(0.2, 0.78, 1.0))
	warning_stack.add_child(warning_progress)
	warning_panel.visible = false

	round_score_label = Label.new()
	round_score_label.name = "RoundScore"
	round_score_label.position = Vector2(390, 26)
	round_score_label.size = Vector2(500, 42)
	round_score_label.z_index = 9
	round_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_score_label.add_theme_font_size_override("font_size", 22)
	round_score_label.add_theme_color_override("font_color", Color(1.0, 0.83, 0.3))
	round_score_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.03, 0.95))
	round_score_label.add_theme_constant_override("shadow_offset_x", 2)
	round_score_label.add_theme_constant_override("shadow_offset_y", 2)
	round_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(round_score_label)

	round_banner = Label.new()
	round_banner.name = "RoundBanner"
	round_banner.position = Vector2(270, 248)
	round_banner.size = Vector2(740, 150)
	round_banner.z_index = 12
	round_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	round_banner.add_theme_font_size_override("font_size", 44)
	round_banner.add_theme_color_override("font_color", Color(1.0, 0.78, 0.16))
	round_banner.add_theme_color_override("font_outline_color", Color(0.03, 0.025, 0.02, 0.98))
	round_banner.add_theme_constant_override("outline_size", 9)
	round_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	round_banner.visible = false
	add_child(round_banner)


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


func _read_actions(delta: float) -> void:
	var contest_down := Input.is_physical_key_pressed(KEY_Z) or touch_contest_down
	if contest_down and not contest_latched:
		perform_contest()
	contest_latched = contest_down
	var objection_down := Input.is_physical_key_pressed(KEY_X) or touch_objection_down
	if active_attack == "":
		if objection_down and not objection_latched:
			perform_objection()
	elif not objection_filed and not active_attack_resolved:
		if objection_down:
			advance_objection_hold(delta)
		else:
			objection_hold_progress = maxf(objection_hold_progress - delta * 1.8, 0.0)
		warning_progress.value = objection_hold_progress / OBJECTION_HOLD_SECONDS
	objection_latched = objection_down


func _update_attack(delta: float) -> void:
	if active_attack == "":
		attack_wait -= delta
		var prompt_progress := clampf(1.0 - attack_wait / maxf(prompt_limit, 0.01), 0.0, 1.0)
		tutorial_title.modulate.a = 0.72 + absf(sin(elapsed * (5.0 + prompt_progress * 7.0))) * 0.28
		if attack_wait <= 0.0:
			_penalize_current_prompt()
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
	objection_hold_progress = 0.0
	guided_contest_step = 0
	guided_round += 1
	prompt_limit = 3.2 if first_round else maxf(1.55, 2.25 - float(guided_round - 1) * 0.08)
	attack_wait = prompt_limit
	tutorial_panel.visible = true
	warning_panel.visible = false
	tutorial_title.modulate = Color.WHITE
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
	tutorial_title.modulate = Color.WHITE
	_update_guided_prompt()


func _update_guided_prompt() -> void:
	tutorial_title.text = "Z"


func _begin_attack(attack_id: String) -> void:
	active_attack = attack_id
	active_attack_elapsed = 0.0
	active_attack_resolved = false
	objection_filed = false
	objection_hold_progress = 0.0
	tutorial_panel.visible = false
	warning_title.text = "X"
	warning_subtitle.text = "HOLD"
	warning_title.modulate = Color.WHITE
	warning_progress.value = 0.0
	warning_panel.visible = true
	_set_pose(bezos_sprite, Vector2i(1, 0))
	pose_until = elapsed + ATTACK_WARNING_SECONDS + ATTACK_RECOVERY_SECONDS
	_create_attack_visual(attack_id)


func _resolve_attack() -> void:
	_penalize_current_prompt()


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
	if not objection_filed and not active_attack_resolved:
		warning_title.modulate.a = 0.64 + absf(sin(progress * PI * 6.0)) * 0.36
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
	var damage_shake := sin(elapsed * 92.0) * 9.0 if elapsed < damage_shake_until else 0.0
	citizen_sprite.position = citizen_base + Vector2(sin(elapsed * 4.1) * 1.4 + damage_shake, absf(sin(elapsed * 3.3)) * 2.4)
	if elapsed >= pose_until and active_attack == "" and not round_transition_active:
		_set_pose(bezos_sprite, Vector2i(0, 0))
		_set_pose(citizen_sprite, Vector2i(0, 0))


func _emit_telemetry() -> void:
	telemetry_changed.emit(
		citizen_hp,
		bezos_hp,
		legal_shield,
		maxi(int(ceil(ROUND_SECONDS - round_elapsed)), 0)
	)


func _finish_battle(outcome: String) -> void:
	if not active:
		return
	active = false
	round_transition_active = false
	tutorial_panel.visible = false
	warning_panel.visible = false
	round_banner.visible = false
	_clear_attack_fx()
	if music_player:
		music_player.stop()
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
		"mistake_count": mistake_count,
		"citizen_round_wins": citizen_round_wins,
		"bezos_round_wins": bezos_round_wins,
		"rounds_played": round_results.size(),
		"round_results": round_results.duplicate(),
		"elapsed_seconds": snappedf(elapsed, 0.1),
		"profile_was_known": false,
	}
	resolved.emit(battle_result.duplicate(true))


func _penalize_current_prompt() -> void:
	if not active:
		return
	mistake_count += 1
	citizen_hp = maxf(citizen_hp - MISTAKE_DAMAGE, 0.0)
	damage_shake_until = elapsed + 0.34
	pose_until = elapsed + 0.34
	_set_pose(citizen_sprite, Vector2i(1, 1))
	_flash(citizen_sprite, Color(1.65, 0.24, 0.12), 0.2)
	damage_flash.color = Color(0.82, 0.04, 0.02, 0.34)
	var damage_tween := create_tween()
	damage_tween.tween_property(damage_flash, "color:a", 0.0, 0.28)
	if citizen_hp <= 0.0:
		_resolve_round("administrative_defeat")
		return
	if active_attack == "":
		_advance_guided_contest()
		return
	if active_attack == "one_click_charge":
		suffered_charges += 1
	active_attack_resolved = true
	objection_hold_progress = 0.0
	active_attack_elapsed = ATTACK_WARNING_SECONDS
	warning_progress.value = 0.0
	warning_panel.visible = false
	_clear_attack_fx()


func _create_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "GoofyArcadeSteelStrikeMusic"
	music_player.volume_db = -9.0
	if ResourceLoader.exists(MUSIC_PATH):
		var delivered_stream := load(MUSIC_PATH) as AudioStreamOggVorbis
		if delivered_stream:
			delivered_stream.loop = true
			delivered_stream.loop_offset = MUSIC_LOOP_OFFSET
			music_player.stream = delivered_stream
	add_child(music_player)
	shield_hit_audio = _make_audio_player("LegalShieldImpact", _make_impact_sound(132.0, 0.13, 0.6), -2.5, 5)
	body_hit_audio = _make_audio_player("BezosBodyImpact", _make_impact_sound(74.0, 0.19, 0.24), -0.5, 5)
	round_audio = _make_audio_player("RoundDecision", _make_impact_sound(246.0, 0.28, 0.08), -2.0, 2)


func _make_audio_player(player_name: String, stream: AudioStream, volume: float, polyphony: int) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.stream = stream
	player.volume_db = volume
	player.max_polyphony = polyphony
	add_child(player)
	return player


func _start_music() -> void:
	if music_player and music_player.stream and not music_player.playing:
		music_player.play(0.0)


func _stop_audio() -> void:
	for player in [music_player, shield_hit_audio, body_hit_audio, round_audio]:
		if player:
			player.stop()


func _make_impact_sound(frequency: float, duration: float, noise_amount: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := maxi(1, int(duration * sample_rate))
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for index in range(sample_count):
		var time := float(index) / float(sample_rate)
		var progress := float(index) / float(sample_count)
		var envelope := pow(1.0 - progress, 2.8)
		var body := sin(TAU * frequency * time) + sin(TAU * frequency * 1.91 * time) * 0.38
		var metal := sin(TAU * frequency * 5.7 * time) * 0.24
		var noise := sin(float((index * 7919 + 31) % 997) * 0.071) * noise_amount
		var wave := (body + metal + noise) * envelope
		bytes[index] = clampi(int(128.0 + wave * 70.0), 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream


func _flash(canvas_item: CanvasItem, flash_color: Color, duration: float) -> void:
	if not canvas_item:
		return
	canvas_item.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(canvas_item, "modulate", Color.WHITE, duration)


func _punch_scale(node: Node2D, base_scale: Vector2) -> void:
	if not node:
		return
	node.scale = base_scale * 1.12
	var tween := create_tween()
	tween.tween_property(node, "scale", base_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _ellipse_points(center: Vector2, radius: Vector2, segments: int = 28) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points
