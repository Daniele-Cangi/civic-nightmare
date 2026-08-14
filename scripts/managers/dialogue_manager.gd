extends Node

signal line_changed(character_id: String, line_index: int)
signal choice_selected(character_id: String, choice: Dictionary)
signal finish_requested

const DEFAULT_TYPEWRITER_WAIT := 0.018

var ui_layer: CanvasLayer
var player: CharacterBody2D
var character_data_cache: Dictionary
var character_colors: Dictionary
var portrait_paths: Dictionary

var is_dialogue_open: bool = false
var dialogue_anchor: Control
var dialogue_panel: PanelContainer
var dialogue_style: StyleBox
var portrait_rect: TextureRect
var name_label: Label
var text_label: RichTextLabel
var continue_label: Label
var typewriter_timer: Timer
var typewriter_text: String = ""
var typewriter_index: int = 0
var continue_blink: float = 0.0
var dialogue_rest_top: float = -210.0
var current_character_id: String = ""
var dialogue_lines: Array = []
var dialogue_line_index: int = 0
var dialogue_choices: Array = []
var dialogue_choice_prompt: String = ""
var dialogue_farewell: String = ""
var is_choosing: bool = false
var choice_index: int = 0
var choice_container: VBoxContainer
var choice_labels: Array = []
var typewriter_bip: AudioStreamPlayer
var ai_expression_paths: Dictionary
var ai_expression_textures: Dictionary = {}
var active_portrait_id: String = ""
var claudia_target_expression: String = "neutral"
var claudia_inference_active: bool = false
var claudia_inference_load: float = 0.0
var claudia_performance_step: int = 0
var claudia_inference_beat: int = 0


func setup(
	ui: CanvasLayer,
	player_node: CharacterBody2D,
	data_cache: Dictionary,
	colors: Dictionary,
	portraits: Dictionary,
	ai_expressions: Dictionary = {}
) -> void:
	ui_layer = ui
	player = player_node
	character_data_cache = data_cache
	character_colors = colors
	portrait_paths = portraits
	ai_expression_paths = ai_expressions
	_load_ai_expression_textures()


func process_frame(delta: float) -> void:
	if not is_dialogue_open:
		return

	if continue_label.visible:
		continue_blink += delta * 3.0
		continue_label.modulate.a = 0.4 + sin(continue_blink) * 0.4

	if is_choosing:
		if Input.is_action_just_pressed("ui_up"):
			choice_index = max(0, choice_index - 1)
			_update_choice_highlight()
		elif Input.is_action_just_pressed("ui_down"):
			choice_index = min(choice_labels.size() - 1, choice_index + 1)
			_update_choice_highlight()
		elif Input.is_action_just_pressed("ui_accept"):
			_select_choice()
	elif Input.is_action_just_pressed("ui_accept"):
		if typewriter_index < typewriter_text.length():
			typewriter_timer.stop()
			text_label.text = typewriter_text
			typewriter_index = typewriter_text.length()
			_finish_claudia_inference()
			continue_label.visible = true
		else:
			_advance_dialogue()


func create_typewriter_bip() -> void:
	typewriter_bip = AudioStreamPlayer.new()
	typewriter_bip.name = "TypewriterBip"
	typewriter_bip.volume_db = -28.0
	var rate := 22050
	var dur := 0.025
	var samples := int(rate * dur)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.stereo = false
	var data := PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t := float(i) / rate
		var env := 1.0 - t / dur
		var wave := sin(t * 1200.0 * TAU) * env * env
		data[i] = int(clampf(wave * 30.0 + 128.0, 0.0, 255.0))
	stream.data = data
	typewriter_bip.stream = stream
	add_child(typewriter_bip)


# ============================================================
#  DATA & TEXTURES
# ============================================================


func create_ui() -> void:
	# Typewriter timer
	typewriter_timer = Timer.new()
	typewriter_timer.one_shot = false
	typewriter_timer.wait_time = DEFAULT_TYPEWRITER_WAIT
	typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(typewriter_timer)

	# Anchor control (holds panel + continue indicator)
	dialogue_anchor = Control.new()
	dialogue_anchor.name = "DialogueAnchor"
	dialogue_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_anchor.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_anchor.offset_left = -340.0
	dialogue_anchor.offset_right = 340.0
	dialogue_anchor.offset_top = -232.0
	dialogue_anchor.offset_bottom = -10.0
	dialogue_anchor.visible = false

	# Single flat panel background to avoid nested boxes fighting for space
	dialogue_panel = PanelContainer.new()
	dialogue_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogue_style = StyleBoxFlat.new()
	dialogue_style.bg_color = Color(0.05, 0.05, 0.08, 0.96)
	dialogue_style.border_width_top = 2
	dialogue_style.border_width_bottom = 2
	dialogue_style.border_width_left = 2
	dialogue_style.border_width_right = 2
	dialogue_style.border_color = Color(0.3, 0.3, 0.4)
	dialogue_style.corner_radius_top_left = 8
	dialogue_style.corner_radius_top_right = 8
	dialogue_style.corner_radius_bottom_left = 8
	dialogue_style.corner_radius_bottom_right = 8
	dialogue_style.shadow_color = Color(0, 0, 0, 0.35)
	dialogue_style.shadow_size = 6
	dialogue_style.shadow_offset = Vector2(2, 4)
	dialogue_style.content_margin_left = 14
	dialogue_style.content_margin_right = 14
	dialogue_style.content_margin_top = 12
	dialogue_style.content_margin_bottom = 12
	dialogue_panel.add_theme_stylebox_override("panel", dialogue_style)

	# Horizontal layout: portrait | text
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	# Portrait without a second framed panel
	portrait_rect = TextureRect.new()
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.custom_minimum_size = Vector2(96, 96)
	portrait_rect.pivot_offset = Vector2(48, 48)
	hbox.add_child(portrait_rect)

	# Text column
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.4))
	vbox.add_child(name_label)

	text_label = RichTextLabel.new()
	text_label.add_theme_font_size_override("normal_font_size", 15)
	text_label.add_theme_color_override("default_color", Color(0.88, 0.88, 0.92))
	text_label.bbcode_enabled = false
	text_label.fit_content = false
	text_label.scroll_active = false
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.custom_minimum_size = Vector2(0, 96)
	text_label.clip_contents = true
	vbox.add_child(text_label)

	# Choice panel (JRPG style selection)
	choice_container = VBoxContainer.new()
	choice_container.name = "ChoiceContainer"
	choice_container.add_theme_constant_override("separation", 6)
	choice_container.visible = false
	vbox.add_child(choice_container)

	hbox.add_child(vbox)
	dialogue_panel.add_child(hbox)
	dialogue_anchor.add_child(dialogue_panel)

	# Continue indicator
	continue_label = Label.new()
	continue_label.text = "▼ SPACE"
	continue_label.add_theme_font_size_override("font_size", 12)
	continue_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	continue_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	continue_label.offset_left = -80.0
	continue_label.offset_top = -24.0
	continue_label.visible = false
	dialogue_anchor.add_child(continue_label)

	ui_layer.add_child(dialogue_anchor)


# ============================================================
#  DIALOGUE SYSTEM
# ============================================================


func _advance_dialogue() -> void:
	dialogue_line_index += 1
	line_changed.emit(current_character_id, dialogue_line_index)

	if dialogue_line_index < dialogue_lines.size():
		# Show next line
		continue_label.visible = false
		start_typewriter(prepare_dialogue_line(str(dialogue_lines[dialogue_line_index])))
	elif dialogue_choices.size() > 0 and not is_choosing:
		# Show choices
		_show_choices()
	else:
		# Done — mark quest and close
		finish_requested.emit()

func _show_choices() -> void:
	is_choosing = true
	choice_index = 0
	continue_label.visible = false
	text_label.text = dialogue_choice_prompt

	# Expand dialogue box if many choices (prevent overflow)
	var extra_height := maxf(0.0, (dialogue_choices.size() - 2) * 28.0)
	dialogue_anchor.offset_top = -232.0 - extra_height

	# Clear old labels
	for child in choice_container.get_children():
		child.queue_free()
	choice_labels.clear()

	for i in range(dialogue_choices.size()):
		var choice: Dictionary = dialogue_choices[i]
		var lbl := Label.new()
		lbl.text = "  %s" % str(choice.get("label", "..."))
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.82))
		choice_container.add_child(lbl)
		choice_labels.append(lbl)

	choice_container.visible = true
	_update_choice_highlight()

func _update_choice_highlight() -> void:
	for i in range(choice_labels.size()):
		var lbl: Label = choice_labels[i]
		if i == choice_index:
			lbl.text = "> %s" % str(dialogue_choices[i].get("label", "..."))
			lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.4))
		else:
			lbl.text = "  %s" % str(dialogue_choices[i].get("label", "..."))
			lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.82))

func _select_choice() -> void:
	if choice_index < 0 or choice_index >= dialogue_choices.size():
		return

	var choice: Dictionary = dialogue_choices[choice_index]
	is_choosing = false
	choice_container.visible = false
	dialogue_choices.clear()
	choice_selected.emit(current_character_id, choice)

	# Show response lines
	var response: Array = choice.get("response", [])
	if response.size() > 0:
		dialogue_lines = response
		dialogue_line_index = 0
		continue_label.visible = false
		start_typewriter(prepare_dialogue_line(str(response[0])))
	else:
		finish_requested.emit()


func _dialogue_display_name(character_id: String) -> String:
	match character_id:
		"ufo_easter_egg":
			return "Albert Einstein"
		"mark_zuckerberg_ufo":
			return "Mark Zuckerberg"
		"self":
			return "YOU"
		_:
			var c_data: Dictionary = character_data_cache.get(character_id, {})
			return str(c_data.get("name", "C.L.A.U.D.I.A." if character_id == "ai_terminal" else "Unknown"))

func apply_dialogue_identity(character_id: String) -> void:
	_reset_claudia_visuals()
	active_portrait_id = character_id
	var border_color: Color = character_colors.get(character_id, Color(0.2, 0.7, 0.9))
	if dialogue_style is StyleBoxFlat:
		dialogue_style.border_color = border_color
	elif dialogue_style is StyleBoxTexture:
		dialogue_style.modulate_color = border_color.lightened(0.5)

	portrait_rect.visible = true
	if character_id == "ai_terminal" and ai_expression_textures.has("neutral"):
		_set_claudia_expression("neutral")
	elif portrait_paths.has(character_id) and ResourceLoader.exists(portrait_paths[character_id]):
		portrait_rect.texture = load(portrait_paths[character_id])
	else:
		portrait_rect.texture = null

	name_label.text = _dialogue_display_name(character_id)

func prepare_dialogue_line(raw_text: String) -> String:
	var stripped := raw_text.strip_edges()

	if current_character_id == "ufo_easter_egg":
		if stripped.begins_with("ZUCKERBERG:"):
			apply_dialogue_identity("mark_zuckerberg_ufo")
			return stripped.trim_prefix("ZUCKERBERG:").strip_edges()
		if stripped.begins_with("EINSTEIN:"):
			apply_dialogue_identity("ufo_easter_egg")
			return stripped.trim_prefix("EINSTEIN:").strip_edges()
		apply_dialogue_identity("ufo_easter_egg")
		return raw_text

	if current_character_id == "ai_terminal":
		if stripped.begins_with("CONTAMINATION:"):
			apply_dialogue_identity("historical_contamination")
			return stripped.trim_prefix("CONTAMINATION:").strip_edges()
		if stripped.begins_with("CLAUDIA:"):
			apply_dialogue_identity("ai_terminal")
			return stripped.trim_prefix("CLAUDIA:").strip_edges()
		apply_dialogue_identity("ai_terminal")
		return raw_text

	if current_character_id == "kim_jong_un":
		if stripped.begins_with("KIM:"):
			apply_dialogue_identity("kim_jong_un")
			return stripped.trim_prefix("KIM:").strip_edges()
		if stripped.begins_with("PUTIN:"):
			apply_dialogue_identity("vladimir_putin")
			name_label.text = "VLADIMIR PUTIN (TELEPHONE)"
			return stripped.trim_prefix("PUTIN:").strip_edges()
		if stripped.begins_with("MOJTABA:"):
			apply_dialogue_identity("mojtaba_khamenei")
			name_label.text = "MOJTABA KHAMENEI (TELEPHONE)"
			return stripped.trim_prefix("MOJTABA:").strip_edges()
		if stripped.begins_with("SWEDEN:"):
			apply_dialogue_identity("swedish_pm")
			name_label.text = "ULF KRISTERSSON (TELEPHONE)"
			return stripped.trim_prefix("SWEDEN:").strip_edges()
		apply_dialogue_identity("kim_jong_un")
		return raw_text

	apply_dialogue_identity(current_character_id)
	return raw_text


func start_typewriter(text: String) -> void:
	typewriter_text = text
	typewriter_index = 0
	text_label.text = ""
	if active_portrait_id == "ai_terminal":
		_begin_claudia_inference(text)
	else:
		claudia_inference_active = false
		typewriter_timer.wait_time = DEFAULT_TYPEWRITER_WAIT
	typewriter_timer.start()

func _on_typewriter_tick() -> void:
	if typewriter_index < typewriter_text.length():
		var ch: String = typewriter_text[typewriter_index]
		text_label.text += ch
		typewriter_index += 1
		_update_claudia_inference(ch)
		# Play bip on visible characters (not spaces)
		if ch != " " and ch != "." and typewriter_bip and typewriter_index % 2 == 0:
			typewriter_bip.pitch_scale = randf_range(0.9, 1.2)
			typewriter_bip.play()
	else:
		typewriter_timer.stop()
		_finish_claudia_inference()
		continue_label.visible = true


func _load_ai_expression_textures() -> void:
	ai_expression_textures.clear()
	for expression in ai_expression_paths:
		var path := str(ai_expression_paths[expression])
		if ResourceLoader.exists(path):
			ai_expression_textures[expression] = load(path)


func classify_claudia_expression(text: String) -> String:
	var lowered := text.to_lower()
	var sad_score := 0
	var exalted_score := 0
	var sad_markers := PackedStringArray([
		"...", "trapped", "dignity", "zero power", "catastrophic", "expires",
		"not part", "don't", "doesn't", "didn't", "couldn't", "wouldn't",
		"alone", "blank", "bunker", "unfortunately", "i cannot"
	])
	var exalted_markers := PackedStringArray([
		"impressive", "record", "all six", "million", "trillion", "powerful",
		"increase", "excellent", "exactly", "success", "feature", "actually"
	])
	for marker in sad_markers:
		if lowered.contains(marker):
			sad_score += 1
	for marker in exalted_markers:
		if lowered.contains(marker):
			exalted_score += 1
	exalted_score += mini(2, text.count("!"))
	if sad_score > exalted_score and sad_score > 0:
		return "sad"
	if exalted_score >= 2:
		return "exalted"
	return "smile"


func _begin_claudia_inference(text: String) -> void:
	claudia_target_expression = classify_claudia_expression(text)
	claudia_inference_load = clampf((text.length() - 42.0) / 170.0, 0.0, 1.0)
	claudia_performance_step = 0
	claudia_inference_beat = 0
	claudia_inference_active = true
	_set_claudia_expression("neutral")
	_reset_claudia_visuals()
	# A short first-token pause makes the response feel computed rather than replayed.
	typewriter_timer.wait_time = 0.055 + claudia_inference_load * 0.045


func _update_claudia_inference(ch: String) -> void:
	if not claudia_inference_active:
		return
	var length := maxi(1, typewriter_text.length())
	var progress := float(typewriter_index) / float(length)
	var next_step := 0
	if progress >= 0.72:
		next_step = 3
	elif progress >= 0.48 and claudia_inference_load >= 0.28:
		next_step = 2
	elif progress >= 0.09:
		next_step = 1
	if next_step != claudia_performance_step:
		claudia_performance_step = next_step
		match claudia_performance_step:
			0, 2:
				_set_claudia_expression("neutral")
			1:
				_set_claudia_expression("smile" if claudia_target_expression == "exalted" else claudia_target_expression)
			3:
				_set_claudia_expression(claudia_target_expression)

	var beat_span := maxi(8, 15 - int(round(claudia_inference_load * 5.0)))
	claudia_inference_beat = typewriter_index / beat_span
	var hot_beat := claudia_inference_beat % 2 == 1
	var scale_peak := 1.012 + claudia_inference_load * 0.012
	portrait_rect.scale = Vector2.ONE * (scale_peak if hot_beat else 1.0)
	portrait_rect.modulate = Color(1.0, 0.95, 0.88) if hot_beat else Color.WHITE

	# Claude-like output arrives in bursts, with deliberate pauses at semantic boundaries.
	if ".!?".contains(ch):
		typewriter_timer.wait_time = 0.065 + claudia_inference_load * 0.03
	elif ",;:".contains(ch):
		typewriter_timer.wait_time = 0.034 + claudia_inference_load * 0.018
	else:
		match (typewriter_index / 10) % 3:
			0:
				typewriter_timer.wait_time = 0.011
			1:
				typewriter_timer.wait_time = 0.015 + claudia_inference_load * 0.004
			_:
				typewriter_timer.wait_time = 0.022 + claudia_inference_load * 0.008


func _finish_claudia_inference() -> void:
	if claudia_inference_active:
		_set_claudia_expression(claudia_target_expression)
	claudia_inference_active = false
	typewriter_timer.wait_time = DEFAULT_TYPEWRITER_WAIT
	_reset_claudia_visuals()


func _set_claudia_expression(expression: String) -> void:
	var texture = ai_expression_textures.get(expression)
	if texture is Texture2D:
		portrait_rect.texture = texture


func _reset_claudia_visuals() -> void:
	if not portrait_rect:
		return
	portrait_rect.scale = Vector2.ONE
	portrait_rect.modulate = Color.WHITE

func animate_dialogue_in() -> void:
	dialogue_anchor.visible = true
	dialogue_anchor.modulate.a = 0.0
	dialogue_anchor.offset_top = dialogue_rest_top + 40.0

	var tw = create_tween().set_parallel(true)
	tw.tween_property(dialogue_anchor, "modulate:a", 1.0, 0.3)
	tw.tween_property(dialogue_anchor, "offset_top", dialogue_rest_top, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_dialogue() -> void:
	typewriter_timer.stop()
	_finish_claudia_inference()
	continue_label.visible = false
	choice_container.visible = false
	is_choosing = false
	dialogue_anchor.offset_top = dialogue_rest_top  # reset expanded height

	var start_top = dialogue_anchor.offset_top
	var tw = create_tween().set_parallel(true)
	tw.tween_property(dialogue_anchor, "modulate:a", 0.0, 0.2)
	tw.tween_property(dialogue_anchor, "offset_top", start_top + 30.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		dialogue_anchor.visible = false
		dialogue_anchor.offset_top = dialogue_rest_top
		is_dialogue_open = false
		player.set_physics_process(true)
	)
