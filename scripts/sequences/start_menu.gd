extends Node

signal continue_requested
signal new_game_requested

var active: bool = true
var has_save: bool = false
var confirmation_active: bool = false
var menu_layer: CanvasLayer
var continue_button: Button
var new_game_button: Button
var status_label: Label
var warning_label: Label


func setup(owner: Node, save_summary: Dictionary) -> void:
	has_save = not save_summary.is_empty()
	active = true
	_create_menu(owner, save_summary)
	set_process_unhandled_input(true)
	if has_save:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()


func close() -> void:
	active = false
	set_process_unhandled_input(false)
	if menu_layer:
		menu_layer.queue_free()
		menu_layer = null


func _unhandled_input(event: InputEvent) -> void:
	if not active or not confirmation_active:
		return
	if event.is_action_pressed("ui_cancel"):
		confirmation_active = false
		new_game_button.text = "NEW GAME"
		warning_label.text = "The protocol does not provide shortcuts."
		new_game_button.grab_focus()
		get_viewport().set_input_as_handled()


func _create_menu(owner: Node, save_summary: Dictionary) -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.name = "StartMenuLayer"
	menu_layer.layer = 120
	owner.add_child(menu_layer)

	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.025, 0.035, 0.055, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(background)

	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wash_material := ShaderMaterial.new()
	var wash_shader := Shader.new()
	wash_shader.code = """
shader_type canvas_item;
void fragment() {
	float line = step(0.55, fract(FRAGCOORD.y / 3.0));
	float vignette = clamp(length(SCREEN_UV - vec2(0.5)) * 1.25, 0.0, 0.7);
	COLOR = vec4(0.04, 0.12, 0.16, 0.12 + line * 0.035 + vignette * 0.45);
}
"""
	wash_material.shader = wash_shader
	wash.material = wash_material
	menu_layer.add_child(wash)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	menu_layer.add_child(center)

	var dossier := PanelContainer.new()
	dossier.custom_minimum_size = Vector2(560, 430)
	var dossier_style := StyleBoxFlat.new()
	dossier_style.bg_color = Color(0.07, 0.075, 0.08, 0.98)
	dossier_style.border_color = Color(0.72, 0.58, 0.26, 0.92)
	dossier_style.set_border_width_all(3)
	dossier_style.set_corner_radius_all(2)
	dossier_style.content_margin_left = 46.0
	dossier_style.content_margin_top = 34.0
	dossier_style.content_margin_right = 46.0
	dossier_style.content_margin_bottom = 34.0
	dossier.add_theme_stylebox_override("panel", dossier_style)
	center.add_child(dossier)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	dossier.add_child(stack)

	var agency := Label.new()
	agency.text = "MINISTRY OF THINGS LEFT UNRESOLVED"
	agency.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	agency.add_theme_font_size_override("font_size", 13)
	agency.add_theme_color_override("font_color", Color(0.68, 0.7, 0.7))
	stack.add_child(agency)

	var title := Label.new()
	title.text = "CIVIC NIGHTMARE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.96, 0.86, 0.48))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	stack.add_child(title)

	var divider := HSeparator.new()
	stack.add_child(divider)

	status_label = Label.new()
	status_label.text = _summary_text(save_summary)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.78, 0.8, 0.79))
	stack.add_child(status_label)

	continue_button = _make_button("CONTINUE")
	continue_button.disabled = not has_save
	continue_button.tooltip_text = "No valid dossier" if not has_save else "Resume from the latest safe checkpoint"
	continue_button.pressed.connect(func() -> void:
		if active and has_save:
			continue_requested.emit()
	)
	stack.add_child(continue_button)

	new_game_button = _make_button("NEW GAME")
	new_game_button.pressed.connect(_on_new_game_pressed)
	stack.add_child(new_game_button)

	warning_label = Label.new()
	warning_label.text = "The protocol does not provide shortcuts."
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.add_theme_font_size_override("font_size", 12)
	warning_label.add_theme_color_override("font_color", Color(0.62, 0.63, 0.64))
	stack.add_child(warning_label)

	var controls := Label.new()
	controls.text = "ARROWS / ENTER  ·  MOUSE"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 11)
	controls.add_theme_color_override("font_color", Color(0.38, 0.42, 0.44))
	stack.add_child(controls)


func _make_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 52)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.86))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.48))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.9, 0.48))
	return button


func _on_new_game_pressed() -> void:
	if not active:
		return
	if has_save and not confirmation_active:
		confirmation_active = true
		new_game_button.text = "CONFIRM NEW GAME"
		warning_label.text = "The existing dossier will be destroyed. ESC cancels."
		return
	new_game_requested.emit()


func _summary_text(save_summary: Dictionary) -> String:
	if save_summary.is_empty():
		return "NO DOSSIER ON FILE"
	if bool(save_summary.get("final_mission_done", false)):
		return "DOSSIER COMPLETE  ·  POST-PROTOCOL ACCESS"
	var signatures := int(save_summary.get("signatures", 0))
	var total := int(save_summary.get("total_signatures", 6))
	return "DOSSIER RECOVERED  ·  SIGNATURES %d/%d" % [signatures, total]
