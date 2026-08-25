extends Node

signal receipt_submitted(response_id: String)
signal postgame_requested

const VIEW_SIZE := Vector2(1280.0, 720.0)
const BACKGROUND := preload("res://assets/sequences/final_determinations_office_v1.png")
const CLAUDIA_TEXTURES := {
	"neutral": preload("res://assets/mockups/ai_terminal_portrait_v2.png"),
	"smile": preload("res://assets/mockups/ai_terminal_portrait_smile_v2.png"),
	"sad": preload("res://assets/mockups/ai_terminal_portrait_sad_v2.png"),
	"exalted": preload("res://assets/mockups/ai_terminal_portrait_exalted_v2.png"),
}

enum EndingState {
	IDLE,
	VERIFYING,
	PASSPORT,
	DOSSIER,
	CHOICE,
	AWAITING_RECORD,
	RESPONSE,
	EPILOGUE,
}

var host: Node
var ending_active := false
var ending_layer: CanvasLayer
var root_control: Control
var frame: Control
var background: TextureRect
var fade: ColorRect
var case_label: Label
var status_label: Label
var verification_lights: Array[PanelContainer] = []
var passport_panel: PanelContainer
var passport_stamp: Label
var paper_panel: PanelContainer
var classification_label: Label
var evidence_text: RichTextLabel
var notification_label: Label
var choice_panel: HBoxContainer
var response_label: Label
var claudia_portrait: TextureRect
var claudia_panel: PanelContainer
var claudia_label: Label
var epilogue_panel: PanelContainer
var epilogue_label: Label
var leave_button: Button
var verify_audio: AudioStreamPlayer
var stamp_audio: AudioStreamPlayer
var printer_audio: AudioStreamPlayer

var assessment: Dictionary = {}
var ending_state := EndingState.IDLE
var ending_timer := 0.0
var verification_index := -1
var claudia_index := -1
var claudia_lines: Array = []
var response_confirmed := false
var postgame_free_roam_started := false


func setup(owner: Node) -> void:
	host = owner
	_create_overlay()


func configure_assessment(value: Dictionary) -> void:
	assessment = value.duplicate(true)


func start(_final_mission_complete: bool = false) -> void:
	if ending_active:
		return
	ending_active = true
	ending_timer = 0.0
	verification_index = -1
	claudia_index = -1
	response_confirmed = false
	postgame_free_roam_started = false
	_reset_presentation()
	ending_layer.visible = true
	_layout_frame()
	if _final_mission_complete and str(assessment.get("response_id", "")) != "":
		_resume_completed_determination()
	else:
		ending_state = EndingState.VERIFYING
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, 1.25).set_trans(Tween.TRANS_SINE)


func _resume_completed_determination() -> void:
	for light in verification_lights:
		_set_verification_light(light, true)
	passport_panel.visible = true
	passport_panel.position.x = 50.0
	passport_panel.modulate.a = 1.0
	_build_assessment_text()
	paper_panel.visible = true
	paper_panel.position.y = 42.0
	paper_panel.modulate.a = 1.0
	evidence_text.visible_characters = -1
	response_label.text = str(assessment.get("response_note", "Response retained."))
	response_label.visible = true
	claudia_lines = Array(assessment.get("claudia_lines", [])).duplicate()
	response_confirmed = true
	ending_state = EndingState.RESPONSE
	status_label.text = "FINAL RESPONSE RESTORED / ORIGINAL ASSESSMENT UNALTERED"
	_show_next_claudia_line()


func confirm_receipt(updated_assessment: Dictionary) -> void:
	if ending_state != EndingState.AWAITING_RECORD:
		return
	assessment = updated_assessment.duplicate(true)
	response_confirmed = true
	response_label.text = str(assessment.get("response_note", "Response retained."))
	response_label.visible = true
	response_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(response_label, "modulate:a", 1.0, 0.3)
	printer_audio.play()
	status_label.text = "RESPONSE RETAINED / ORIGINAL ASSESSMENT UNALTERED"
	claudia_lines = Array(assessment.get("claudia_lines", [])).duplicate()
	ending_state = EndingState.RESPONSE
	ending_timer = 0.0
	_show_next_claudia_line()


func process_frame(delta: float) -> void:
	if not ending_active:
		return
	ending_timer += delta

	if ending_state == EndingState.DOSSIER and Input.is_action_just_pressed("ui_accept"):
		evidence_text.visible_characters = -1
		ending_timer = maxf(ending_timer, 4.8)

	match ending_state:
		EndingState.VERIFYING:
			_process_verification()
		EndingState.PASSPORT:
			if ending_timer >= 1.85:
				_reveal_dossier()
		EndingState.DOSSIER:
			_process_dossier(delta)
		EndingState.RESPONSE:
			_process_claudia_response()
		EndingState.EPILOGUE:
			if Input.is_action_just_pressed("ui_accept"):
				_leave_office()


func _process_verification() -> void:
	var requested_index := mini(int(ending_timer / 0.42), verification_lights.size() - 1)
	while requested_index > verification_index:
		verification_index += 1
		var light := verification_lights[verification_index]
		_set_verification_light(light, true)
		light.scale = Vector2(1.35, 1.35)
		create_tween().tween_property(light, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
		verify_audio.pitch_scale = 0.88 + float(verification_index) * 0.045
		verify_audio.play()
		status_label.text = "SIGNATURE VERIFICATION %d / 6" % (verification_index + 1)
	if ending_timer >= 3.0:
		_reveal_passport()


func _reveal_passport() -> void:
	ending_state = EndingState.PASSPORT
	ending_timer = 0.0
	status_label.text = "PRIMARY PROCEDURE COMPLETE"
	passport_panel.visible = true
	passport_panel.modulate.a = 0.0
	passport_panel.position.x = -380.0
	stamp_audio.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(passport_panel, "position:x", 50.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(passport_panel, "modulate:a", 1.0, 0.24)
	tween.tween_property(passport_stamp, "rotation_degrees", -4.0, 0.15).from(8.0)


func _reveal_dossier() -> void:
	ending_state = EndingState.DOSSIER
	ending_timer = 0.0
	status_label.text = "SECONDARY PROCEDURE CONTINUES"
	_build_assessment_text()
	paper_panel.visible = true
	paper_panel.position.y = 760.0
	paper_panel.modulate.a = 0.0
	evidence_text.visible_characters = 0
	printer_audio.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(paper_panel, "position:y", 42.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(paper_panel, "modulate:a", 1.0, 0.35)


func _process_dossier(delta: float) -> void:
	if evidence_text.visible_characters >= 0:
		evidence_text.visible_characters = mini(
			evidence_text.get_total_character_count(),
			evidence_text.visible_characters + maxi(1, int(delta * 92.0))
		)
	var dossier_revealed := evidence_text.visible_characters < 0 or evidence_text.visible_characters >= evidence_text.get_total_character_count()
	if ending_timer >= 5.4 and dossier_revealed:
		_show_receipt_choices()


func _show_receipt_choices() -> void:
	ending_state = EndingState.CHOICE
	ending_timer = 0.0
	status_label.text = "CITIZEN RECEIPT REQUIRED / PASSPORT STATUS UNAFFECTED"
	choice_panel.visible = true
	choice_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(choice_panel, "modulate:a", 1.0, 0.3)
	var first_button := choice_panel.get_child(0) as Button
	if first_button:
		first_button.grab_focus()


func _on_receipt_pressed(response_id: String) -> void:
	if ending_state != EndingState.CHOICE:
		return
	ending_state = EndingState.AWAITING_RECORD
	choice_panel.visible = false
	status_label.text = "RESPONSE ROUTING..."
	stamp_audio.pitch_scale = 0.78 if response_id == "refuse" else 1.0
	stamp_audio.play()
	receipt_submitted.emit(response_id)


func _process_claudia_response() -> void:
	if not response_confirmed:
		return
	var target_index := mini(int(ending_timer / 3.15), claudia_lines.size() - 1)
	if target_index > claudia_index:
		_show_next_claudia_line()
	if not claudia_lines.is_empty() and ending_timer >= float(claudia_lines.size()) * 3.15 + 1.25:
		_show_epilogue()


func _show_next_claudia_line() -> void:
	claudia_index += 1
	if claudia_index < 0 or claudia_index >= claudia_lines.size():
		return
	claudia_panel.visible = true
	claudia_portrait.visible = true
	claudia_portrait.texture = CLAUDIA_TEXTURES.get(str(assessment.get("claudia_expression", "neutral")), CLAUDIA_TEXTURES["neutral"])
	claudia_label.modulate.a = 0.0
	claudia_label.text = "C.L.A.U.D.I.A. / FINAL OBSERVATION\n\n%s" % str(claudia_lines[claudia_index])
	var tween := create_tween()
	tween.tween_property(claudia_label, "modulate:a", 1.0, 0.32)


func _show_epilogue() -> void:
	ending_state = EndingState.EPILOGUE
	ending_timer = 0.0
	claudia_panel.visible = false
	choice_panel.visible = false
	status_label.text = "PROCESSING COMPLETE"
	epilogue_panel.visible = true
	epilogue_panel.modulate.a = 0.0
	epilogue_label.text = (
		"THE WORLD DID NOT CHANGE.\n"
		+ "The wars are still running. The billionaires are still rich.\n"
		+ "The warehouse worker still does not have a chair.\n\n"
		+ "The document is filed in a folder that one machine decided to create\n"
		+ "because one person decided to try.\n\n"
		+ "YOUR PASSPORT HAS BEEN APPROVED."
	)
	leave_button.visible = true
	leave_button.grab_focus()
	var tween := create_tween()
	tween.tween_property(epilogue_panel, "modulate:a", 1.0, 0.8)


func _leave_office() -> void:
	if ending_state != EndingState.EPILOGUE or postgame_free_roam_started:
		return
	postgame_free_roam_started = true
	leave_button.disabled = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.85)
	tween.tween_callback(func() -> void:
		ending_active = false
		ending_layer.visible = false
		postgame_requested.emit()
	)


func _build_assessment_text() -> void:
	classification_label.text = "CITIZEN CLASSIFICATION\n%s" % str(assessment.get("classification", "INTERPRETATION PENDING"))
	var classification_detail := str(assessment.get("classification_detail", ""))
	if classification_detail != "":
		classification_label.text += "\n%s" % classification_detail
	classification_label.add_theme_color_override(
		"font_color",
		Color("#9f2424") if bool(assessment.get("classification_failed", false)) else Color("#17272c")
	)
	var blocks: Array[String] = []
	for item_value in assessment.get("evidence", []):
		if not item_value is Dictionary:
			continue
		var item: Dictionary = item_value
		blocks.append("%s / %s\n%s\nSYSTEM NOTE: %s" % [
			str(item.get("kind", "EVIDENCE")),
			str(item.get("title", "RETAINED")),
			str(item.get("body", "")),
			str(item.get("note", "Explanation pending.")),
		])
	evidence_text.text = "\n\n".join(blocks)
	notification_label.text = str(assessment.get("notification", "CITIZEN NOTIFICATION DEFERRED."))


func _reset_presentation() -> void:
	fade.color = Color(0.0, 0.0, 0.0, 1.0)
	case_label.text = "OFFICE OF FINAL DETERMINATIONS"
	status_label.text = "CASE TEMPORARILY SUSPENDED FOR FINAL PROCESSING"
	for light in verification_lights:
		_set_verification_light(light, false)
		light.scale = Vector2.ONE
	passport_panel.visible = false
	paper_panel.visible = false
	choice_panel.visible = false
	response_label.visible = false
	claudia_portrait.visible = false
	claudia_panel.visible = false
	epilogue_panel.visible = false
	leave_button.visible = false
	leave_button.disabled = false


func _create_overlay() -> void:
	ending_layer = CanvasLayer.new()
	ending_layer.name = "FinalDeterminationsLayer"
	ending_layer.layer = 100
	ending_layer.visible = false
	ending_layer.process_mode = Node.PROCESS_MODE_ALWAYS

	root_control = Control.new()
	root_control.name = "FinalDeterminationsRoot"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	ending_layer.add_child(root_control)

	var letterbox := ColorRect.new()
	letterbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	letterbox.color = Color("#050505")
	letterbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(letterbox)

	frame = Control.new()
	frame.name = "Frame"
	frame.size = VIEW_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(frame)
	root_control.resized.connect(_layout_frame)

	background = TextureRect.new()
	background.name = "OfficeBackground"
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(background)

	var atmospheric_tint := ColorRect.new()
	atmospheric_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	atmospheric_tint.color = Color(0.015, 0.035, 0.045, 0.18)
	atmospheric_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(atmospheric_tint)

	_create_header()
	_create_verification_lights()
	_create_passport_panel()
	_create_paper_panel()
	_create_claudia_panel()
	_create_epilogue_panel()
	_create_audio()
	_create_scanlines()

	fade = ColorRect.new()
	fade.name = "Fade"
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.0, 0.0, 0.0, 1.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(fade)

	host.add_child(ending_layer)


func _create_header() -> void:
	var header := PanelContainer.new()
	header.position = Vector2(38.0, 28.0)
	header.size = Vector2(620.0, 76.0)
	header.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.05, 0.92), Color("#d2b56b"), 2, 8))
	frame.add_child(header)
	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 2)
	header.add_child(header_box)
	case_label = _label("", 24, Color("#f2dd99"), HORIZONTAL_ALIGNMENT_CENTER)
	header_box.add_child(case_label)
	status_label = _label("", 13, Color("#8de9df"), HORIZONTAL_ALIGNMENT_CENTER)
	header_box.add_child(status_label)


func _create_verification_lights() -> void:
	var light_row := HBoxContainer.new()
	light_row.position = Vector2(414.0, 305.0)
	light_row.size = Vector2(452.0, 24.0)
	light_row.alignment = BoxContainer.ALIGNMENT_CENTER
	light_row.add_theme_constant_override("separation", 34)
	frame.add_child(light_row)
	for index in range(6):
		var light := PanelContainer.new()
		light.name = "SignatureLight%d" % (index + 1)
		light.custom_minimum_size = Vector2(30.0, 12.0)
		light.pivot_offset = Vector2(15.0, 6.0)
		light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_verification_light(light, false)
		light_row.add_child(light)
		verification_lights.append(light)


func _create_passport_panel() -> void:
	passport_panel = PanelContainer.new()
	passport_panel.name = "PassportApproval"
	passport_panel.position = Vector2(50.0, 470.0)
	passport_panel.size = Vector2(348.0, 166.0)
	passport_panel.add_theme_stylebox_override("panel", _panel_style(Color("#173a43"), Color("#e7c45c"), 4, 12))
	frame.add_child(passport_panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	passport_panel.add_child(box)
	box.add_child(_label("PASSPORT RENEWAL", 16, Color("#a8d8d5"), HORIZONTAL_ALIGNMENT_CENTER))
	passport_stamp = _label("APPROVED", 42, Color("#f4d466"), HORIZONTAL_ALIGNMENT_CENTER)
	passport_stamp.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	passport_stamp.add_theme_constant_override("shadow_offset_x", 3)
	passport_stamp.add_theme_constant_override("shadow_offset_y", 3)
	box.add_child(passport_stamp)
	box.add_child(_label("VALID FOR TRAVEL / INVALID AS AN EXPLANATION", 11, Color("#e7eee9"), HORIZONTAL_ALIGNMENT_CENTER))


func _create_paper_panel() -> void:
	paper_panel = PanelContainer.new()
	paper_panel.name = "CitizenDossierPaper"
	paper_panel.position = Vector2(704.0, 42.0)
	paper_panel.size = Vector2(528.0, 618.0)
	paper_panel.add_theme_stylebox_override("panel", _panel_style(Color("#e8e1cc"), Color("#7d6842"), 3, 4))
	frame.add_child(paper_panel)
	var paper_box := VBoxContainer.new()
	paper_box.add_theme_constant_override("separation", 6)
	paper_panel.add_child(paper_box)
	var file_header := _label("INTERNAL DOCUMENT / CITIZEN COPY", 12, Color("#665738"), HORIZONTAL_ALIGNMENT_CENTER)
	paper_box.add_child(file_header)
	classification_label = _label("", 21, Color("#17272c"), HORIZONTAL_ALIGNMENT_CENTER)
	classification_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	classification_label.custom_minimum_size.y = 86.0
	classification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	paper_box.add_child(classification_label)
	var rule := HSeparator.new()
	rule.add_theme_color_override("separator", Color("#8f7c55"))
	paper_box.add_child(rule)
	evidence_text = RichTextLabel.new()
	evidence_text.name = "FinalEvidence"
	evidence_text.bbcode_enabled = false
	evidence_text.fit_content = false
	evidence_text.scroll_active = false
	evidence_text.custom_minimum_size = Vector2(488.0, 370.0)
	evidence_text.add_theme_font_size_override("normal_font_size", 12)
	evidence_text.add_theme_color_override("default_color", Color("#25241f"))
	evidence_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper_box.add_child(evidence_text)
	notification_label = _label("", 11, Color("#5d382d"), HORIZONTAL_ALIGNMENT_CENTER)
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notification_label.custom_minimum_size.y = 36.0
	paper_box.add_child(notification_label)
	response_label = _label("", 12, Color("#7f1d1d"), HORIZONTAL_ALIGNMENT_CENTER)
	response_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	response_label.custom_minimum_size.y = 44.0
	paper_box.add_child(response_label)

	choice_panel = HBoxContainer.new()
	choice_panel.name = "ReceiptChoices"
	choice_panel.position = Vector2(64.0, 648.0)
	choice_panel.size = Vector2(1152.0, 56.0)
	choice_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_panel.add_theme_constant_override("separation", 18)
	frame.add_child(choice_panel)
	for option in [
		["ACKNOWLEDGE RECEIPT", "acknowledge"],
		["REQUEST CORRECTION", "correct"],
		["REFUSE TO SIGN", "refuse"],
	]:
		var button := Button.new()
		button.text = str(option[0])
		button.custom_minimum_size = Vector2(300.0, 48.0)
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", Color("#f3e4b4"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_stylebox_override("normal", _panel_style(Color("#17272c"), Color("#a58a4f"), 2, 5))
		button.add_theme_stylebox_override("hover", _panel_style(Color("#23454a"), Color("#f0ce6a"), 3, 5))
		button.add_theme_stylebox_override("focus", _panel_style(Color("#23454a"), Color("#8de9df"), 3, 5))
		button.pressed.connect(_on_receipt_pressed.bind(str(option[1])))
		choice_panel.add_child(button)


func _create_claudia_panel() -> void:
	claudia_portrait = TextureRect.new()
	claudia_portrait.name = "ClaudiaFinalPortrait"
	claudia_portrait.position = Vector2(548.0, 112.0)
	claudia_portrait.size = Vector2(184.0, 112.0)
	claudia_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	claudia_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	claudia_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	claudia_portrait.modulate = Color(0.72, 1.0, 0.96, 0.92)
	claudia_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(claudia_portrait)

	claudia_panel = PanelContainer.new()
	claudia_panel.name = "ClaudiaMonitorText"
	claudia_panel.position = Vector2(50.0, 122.0)
	claudia_panel.size = Vector2(580.0, 174.0)
	claudia_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.06, 0.065, 0.94), Color("#5bd3d7"), 2, 16))
	frame.add_child(claudia_panel)
	claudia_label = _label("", 16, Color("#9ff4ed"), HORIZONTAL_ALIGNMENT_CENTER)
	claudia_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	claudia_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	claudia_panel.add_child(claudia_label)


func _create_epilogue_panel() -> void:
	epilogue_panel = PanelContainer.new()
	epilogue_panel.name = "Epilogue"
	epilogue_panel.position = Vector2(150.0, 180.0)
	epilogue_panel.size = Vector2(980.0, 388.0)
	epilogue_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.025, 0.028, 0.96), Color("#d7bd70"), 3, 12))
	frame.add_child(epilogue_panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	epilogue_panel.add_child(box)
	box.add_child(_label("CIVIC NIGHTMARE", 38, Color("#e8cb75"), HORIZONTAL_ALIGNMENT_CENTER))
	epilogue_label = _label("", 18, Color("#e9e5d8"), HORIZONTAL_ALIGNMENT_CENTER)
	epilogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	epilogue_label.custom_minimum_size = Vector2(900.0, 210.0)
	epilogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(epilogue_label)
	leave_button = Button.new()
	leave_button.text = "LEAVE WITH PASSPORT"
	leave_button.custom_minimum_size = Vector2(310.0, 48.0)
	leave_button.add_theme_font_size_override("font_size", 16)
	leave_button.add_theme_stylebox_override("normal", _panel_style(Color("#18353a"), Color("#d7bd70"), 2, 5))
	leave_button.add_theme_stylebox_override("hover", _panel_style(Color("#28545a"), Color("#f1dc91"), 3, 5))
	leave_button.add_theme_stylebox_override("focus", _panel_style(Color("#28545a"), Color("#8de9df"), 3, 5))
	leave_button.pressed.connect(_leave_office)
	box.add_child(leave_button)


func _create_audio() -> void:
	verify_audio = AudioStreamPlayer.new()
	verify_audio.name = "VerifyAudio"
	verify_audio.stream = _make_tone(480.0, 0.09, 0.03)
	verify_audio.volume_db = -10.0
	ending_layer.add_child(verify_audio)
	stamp_audio = AudioStreamPlayer.new()
	stamp_audio.name = "StampAudio"
	stamp_audio.stream = _make_tone(108.0, 0.28, 0.34)
	stamp_audio.volume_db = -5.0
	ending_layer.add_child(stamp_audio)
	printer_audio = AudioStreamPlayer.new()
	printer_audio.name = "PrinterAudio"
	printer_audio.stream = _make_tone(226.0, 0.62, 0.24)
	printer_audio.volume_db = -8.0
	ending_layer.add_child(printer_audio)


func _create_scanlines() -> void:
	var scanlines := ColorRect.new()
	scanlines.name = "Scanlines"
	scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	float line = step(1.5, mod(FRAGCOORD.y, 3.0));
	COLOR = vec4(0.0, 0.02, 0.025, line * 0.11);
}
"""
	material.shader = shader
	scanlines.material = material
	frame.add_child(scanlines)


func _layout_frame() -> void:
	if not root_control or not frame:
		return
	var viewport_size := root_control.size
	var scale_factor := minf(viewport_size.x / VIEW_SIZE.x, viewport_size.y / VIEW_SIZE.y)
	frame.scale = Vector2.ONE * scale_factor
	frame.position = (viewport_size - VIEW_SIZE * scale_factor) * 0.5


func _label(text: String, size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _set_verification_light(light: PanelContainer, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#85f2c2") if active else Color("#4b211f")
	style.border_color = Color("#d9fff0") if active else Color("#8d4940")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	if active:
		style.shadow_color = Color(0.25, 1.0, 0.75, 0.48)
		style.shadow_size = 5
	light.add_theme_stylebox_override("panel", style)


func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _make_tone(frequency: float, duration: float, noise_amount: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := maxi(1, int(duration * sample_rate))
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for index in range(sample_count):
		var time := float(index) / float(sample_rate)
		var envelope := pow(1.0 - float(index) / float(sample_count), 1.45)
		var primary := sin(TAU * frequency * time)
		var harmonic := sin(TAU * frequency * 2.01 * time) * 0.2
		var noise := sin(float(index * 7919 % 997) * 0.013) * noise_amount
		var wave := (primary + harmonic) * (1.0 - noise_amount) + noise
		bytes[index] = clampi(int(128.0 + wave * envelope * 86.0), 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream
