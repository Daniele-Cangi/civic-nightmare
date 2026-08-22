extends Node

signal state_changed

var host: Node
var dossier_manager: Node
var can_open_callback: Callable
var opened: bool = false

var hold_layer: CanvasLayer
var root_control: Control
var header_label: Label
var subheader_label: Label
var menu_container: VBoxContainer
var detail_title: Label
var detail_text: RichTextLabel
var selected_section_id: String = "case_status"


func setup(owner_node: Node, dossier: Node, can_open: Callable) -> void:
	host = owner_node
	dossier_manager = dossier
	can_open_callback = can_open
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if opened:
		close()
	elif can_open_callback.is_valid() and bool(can_open_callback.call()):
		open()
	else:
		return
	get_viewport().set_input_as_handled()


func open() -> void:
	if opened or not hold_layer:
		return
	opened = true
	hold_layer.visible = true
	_refresh()
	state_changed.emit()
	get_tree().paused = true


func close() -> void:
	if not opened:
		return
	opened = false
	if hold_layer:
		hold_layer.visible = false
	get_tree().paused = false
	state_changed.emit()


func _create_ui() -> void:
	hold_layer = CanvasLayer.new()
	hold_layer.name = "AdministrativeHoldLayer"
	hold_layer.layer = 116
	hold_layer.visible = false
	hold_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hold_layer)

	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	hold_layer.add_child(root_control)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.025, 0.04, 0.94)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(dim)

	var scanlines := ColorRect.new()
	scanlines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scanlines.color = Color(0.12, 0.42, 0.48, 0.035)
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(scanlines)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-500, -300)
	panel.size = Vector2(1000, 600)
	panel.add_theme_stylebox_override("panel", _panel_style())
	root_control.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	panel.add_child(outer)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 26)
	header_margin.add_theme_constant_override("margin_right", 26)
	header_margin.add_theme_constant_override("margin_top", 22)
	outer.add_child(header_margin)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 4)
	header_margin.add_child(header_box)

	header_label = Label.new()
	header_label.text = "CASE TEMPORARILY SUSPENDED FOR REVIEW"
	header_label.add_theme_font_size_override("font_size", 26)
	header_label.add_theme_color_override("font_color", Color(0.78, 0.97, 0.93))
	header_box.add_child(header_label)

	subheader_label = Label.new()
	subheader_label.text = "ADMINISTRATIVE HOLD // PROCESSING CLOCK STOPPED"
	subheader_label.add_theme_font_size_override("font_size", 13)
	subheader_label.add_theme_color_override("font_color", Color(0.35, 0.72, 0.71))
	header_box.add_child(subheader_label)

	var divider := HSeparator.new()
	divider.add_theme_constant_override("separation", 1)
	outer.add_child(divider)

	var body_margin := MarginContainer.new()
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 24)
	body_margin.add_theme_constant_override("margin_right", 24)
	body_margin.add_theme_constant_override("margin_bottom", 22)
	outer.add_child(body_margin)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 24)
	body_margin.add_child(body)

	menu_container = VBoxContainer.new()
	menu_container.custom_minimum_size = Vector2(270, 0)
	menu_container.add_theme_constant_override("separation", 8)
	body.add_child(menu_container)

	var vertical_divider := VSeparator.new()
	body.add_child(vertical_divider)

	var detail_box := VBoxContainer.new()
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.add_theme_constant_override("separation", 12)
	body.add_child(detail_box)

	detail_title = Label.new()
	detail_title.add_theme_font_size_override("font_size", 20)
	detail_title.add_theme_color_override("font_color", Color(0.97, 0.74, 0.31))
	detail_box.add_child(detail_title)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_box.add_child(detail_scroll)

	detail_text = RichTextLabel.new()
	detail_text.bbcode_enabled = false
	detail_text.fit_content = true
	detail_text.scroll_active = false
	detail_text.custom_minimum_size = Vector2(620, 0)
	detail_text.add_theme_font_size_override("normal_font_size", 17)
	detail_text.add_theme_color_override("default_color", Color(0.76, 0.84, 0.84))
	detail_text.add_theme_constant_override("line_separation", 6)
	detail_scroll.add_child(detail_text)

	var hint := Label.new()
	hint.text = "ESC — RESUME PROCESSING"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.34, 0.55, 0.56))
	detail_box.add_child(hint)


func _refresh() -> void:
	if not dossier_manager:
		return
	header_label.text = "CASE TEMPORARILY SUSPENDED FOR REVIEW"
	subheader_label.text = (
		"ADMINISTRATIVE HOLD // SUBJECT PRESENT"
		if bool(dossier_manager.get("profile_discovered"))
		else "ADMINISTRATIVE HOLD // PROCESSING CLOCK STOPPED"
	)
	for child in menu_container.get_children():
		menu_container.remove_child(child)
		child.queue_free()

	var resume_button := _make_button("Resume processing")
	resume_button.pressed.connect(close)
	menu_container.add_child(resume_button)

	var sections: Array = dossier_manager.call("get_hold_sections")
	var selected_still_available := false
	var first_section_id := "case_status"
	for section in sections:
		if not section is Dictionary:
			continue
		var section_id := str(section.get("id", "case_status"))
		if section_id == selected_section_id:
			selected_still_available = true
		var section_button := _make_button(str(section.get("label", section_id)))
		section_button.pressed.connect(_select_section.bind(section_id))
		menu_container.add_child(section_button)
	if not selected_still_available:
		selected_section_id = first_section_id
	_show_selected_content()
	resume_button.grab_focus()


func _select_section(section_id: String) -> void:
	selected_section_id = section_id
	if section_id == "citizen_dossier":
		if bool(dossier_manager.call("record_profile_access", section_id)):
			state_changed.emit()
			_refresh()
			return
	_show_selected_content()


func _show_selected_content() -> void:
	var summary: Dictionary = dossier_manager.call("get_pause_summary", selected_section_id)
	detail_title.text = str(summary.get("title", "CASE STATUS"))
	var paragraphs: Array = summary.get("lines", [])
	var rendered := ""
	for paragraph in paragraphs:
		if rendered != "":
			rendered += "\n\n────────────\n\n"
		rendered += str(paragraph)
	detail_text.text = rendered


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.72, 0.9, 0.88))
	button.add_theme_color_override("font_hover_color", Color(0.98, 0.8, 0.34))
	button.add_theme_color_override("font_focus_color", Color(0.98, 0.8, 0.34))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.03, 0.08, 0.1, 0.9), Color(0.16, 0.35, 0.37)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.06, 0.14, 0.15, 0.95), Color(0.65, 0.48, 0.17)))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.06, 0.14, 0.15, 0.95), Color(0.65, 0.48, 0.17)))
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.07, 0.985)
	style.border_color = Color(0.2, 0.58, 0.58, 0.9)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = 14
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style
