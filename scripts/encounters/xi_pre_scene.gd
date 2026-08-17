extends Node

const FRAME_SIZE := Vector2(1280.0, 720.0)
const DEEPSICK_PORTRAIT_PATH := "res://assets/mockups/deepsick_state_ai_portrait_v1.png"
const XI_PORTRAIT_PATH := "res://assets/mockups/xi_jinping_caricature.png"
const CLAUDIA_PORTRAIT_PATH := "res://assets/mockups/ai_terminal_portrait_v2.png"
const CLAUDIA_SMILE_PORTRAIT_PATH := "res://assets/mockups/ai_terminal_portrait_smile_v2.png"

var host: Node
var player: CharacterBody2D
var data_cache: Dictionary

var xi_pre_scene_seen: bool = false
var xi_pre_scene_active: bool = false
var xi_pre_skip_requested: bool = false
var xi_scene_layer: CanvasLayer
var xi_scene_root: Control
var xi_scene_frame: Control
var xi_scene_speaker_cards: Dictionary = {}
var xi_scene_message_labels: Dictionary = {}
var xi_scene_sender_labels: Dictionary = {}
var xi_scene_history_label: Label
var xi_scene_history_entries: Array[String] = []
var xi_scene_last_speaker: String = ""
var xi_scene_last_text: String = ""
var xi_scene_signal_left: ColorRect
var xi_scene_signal_right: ColorRect
var xi_scene_packet_label: Label
var xi_scene_message_index: int = 0
var xi_scene_total_messages: int = 0


func setup(owner: Node, player_node: CharacterBody2D, character_data: Dictionary) -> void:
	host = owner
	player = player_node
	data_cache = character_data


func request_skip() -> void:
	xi_pre_skip_requested = true


func start(current_room_id: String, xi_room: Node) -> void:
	if xi_pre_scene_seen or xi_pre_scene_active or current_room_id != "red_command":
		return
	xi_pre_scene_active = true
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	var xi_data: Dictionary = data_cache.get("xi_jinping", {})
	var beats: Array = xi_data.get("xi_pre_scene", [])
	if beats.is_empty():
		xi_pre_scene_active = false
		player.set_physics_process(true)
		return

	xi_pre_skip_requested = false
	xi_scene_total_messages = beats.size()
	xi_scene_message_index = 0
	var intro_tween := _build_xi_scene_overlay()
	if intro_tween:
		await intro_tween.finished
	if xi_pre_skip_requested:
		_finish_xi_pre_scene(xi_room)
		return
	await get_tree().create_timer(0.18).timeout

	for beat in beats:
		if xi_pre_skip_requested:
			break
		var channel: String = str(beat.get("channel", "deepsick"))
		var from_sender: String = str(beat.get("from", "xi"))
		var text: String = str(beat.get("text", ""))
		var hold: float = float(beat.get("hold", 2.0))
		var reveal_tween = await _xi_scene_add_message(channel, from_sender, text)
		if reveal_tween:
			await reveal_tween.finished
		var elapsed: float = 0.0
		while elapsed < hold:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
			if xi_pre_skip_requested:
				break

	# The transmission releases control automatically. SPACE may shorten this
	# final beat, but gameplay state must never depend on another key press.
	if xi_scene_frame and is_instance_valid(xi_scene_frame):
		var skip_hint := xi_scene_frame.get_node_or_null("XiSkipHint")
		if skip_hint:
			skip_hint.queue_free()
		var close_lbl := Label.new()
		close_lbl.name = "XiCloseHint"
		close_lbl.text = "[ TRANSMISSION ENDED — RELEASING LOCAL CONTROL ]"
		close_lbl.add_theme_font_size_override("font_size", 13)
		close_lbl.add_theme_color_override("font_color", Color(0.82, 0.74, 0.56))
		close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		close_lbl.position = Vector2(0.0, 687.0)
		close_lbl.size = Vector2(1280.0, 24.0)
		xi_scene_frame.add_child(close_lbl)
		var blink_t: float = 0.0
		var linger_time: float = 0.0
		while linger_time < 1.15:
			await get_tree().process_frame
			var frame_delta := get_process_delta_time()
			linger_time += frame_delta
			blink_t += frame_delta * 3.0
			close_lbl.modulate.a = 0.45 + sin(blink_t) * 0.45
			if xi_pre_skip_requested or Input.is_action_just_pressed("ui_accept"):
				break

	_finish_xi_pre_scene(xi_room)


func _finish_xi_pre_scene(xi_room: Node) -> void:
	# Release gameplay before starting the cosmetic fade. A visual tween must
	# never own the player's movement lock.
	xi_pre_skip_requested = false
	xi_pre_scene_seen = true
	xi_pre_scene_active = false
	if player and is_instance_valid(player):
		player.velocity = Vector2.ZERO
		player.set_physics_process(true)
	if xi_room and xi_room.has_method("set_npc_interaction_enabled"):
		xi_room.set_npc_interaction_enabled(true)
	if xi_room and xi_room.has_method("require_npc_reapproach"):
		xi_room.require_npc_reapproach()
	_destroy_xi_scene_overlay()

func _layout_xi_scene_frame() -> void:
	if not xi_scene_root or not xi_scene_frame:
		return
	xi_scene_frame.size = FRAME_SIZE
	xi_scene_frame.position = (xi_scene_root.size - FRAME_SIZE) * 0.5

func _build_xi_scene_overlay() -> Tween:
	xi_scene_layer = CanvasLayer.new()
	xi_scene_layer.layer = 7
	xi_scene_layer.name = "XiSceneLayer"
	host.add_child(xi_scene_layer)

	xi_scene_root = Control.new()
	xi_scene_root.name = "XiSceneRoot"
	xi_scene_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	xi_scene_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	xi_scene_layer.add_child(xi_scene_root)
	xi_scene_root.resized.connect(_layout_xi_scene_frame)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.025, 0.68)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	xi_scene_root.add_child(bg)

	var scanline := ColorRect.new()
	scanline.name = "InterceptScanline"
	scanline.color = Color(0.65, 0.08, 0.06, 0.08)
	scanline.position = Vector2(0.0, -4.0)
	scanline.size = Vector2(FRAME_SIZE.x, 3.0)
	scanline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xi_scene_root.add_child(scanline)
	var scan_tween := create_tween().set_loops()
	scan_tween.tween_property(scanline, "position:y", FRAME_SIZE.y + 4.0, 3.8).set_trans(Tween.TRANS_LINEAR)
	scan_tween.tween_property(scanline, "position:y", -4.0, 0.0)

	xi_scene_frame = Control.new()
	xi_scene_frame.name = "XiSceneFrame"
	xi_scene_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xi_scene_frame.size = FRAME_SIZE
	xi_scene_root.add_child(xi_scene_frame)
	_layout_xi_scene_frame()

	var intercept_lbl := Label.new()
	intercept_lbl.text = "●  LIVE INTERCEPT  /  RED COMMAND INTERNAL BUS"
	intercept_lbl.add_theme_font_size_override("font_size", 13)
	intercept_lbl.add_theme_color_override("font_color", Color(0.88, 0.24, 0.18))
	intercept_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intercept_lbl.position = Vector2(0.0, 18.0)
	intercept_lbl.size = Vector2(1280.0, 24.0)
	xi_scene_frame.add_child(intercept_lbl)

	xi_scene_packet_label = Label.new()
	xi_scene_packet_label.name = "XiPacketCounter"
	xi_scene_packet_label.text = "PACKET 00 / %02d" % xi_scene_total_messages
	xi_scene_packet_label.add_theme_font_size_override("font_size", 11)
	xi_scene_packet_label.add_theme_color_override("font_color", Color(0.48, 0.44, 0.40))
	xi_scene_packet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xi_scene_packet_label.position = Vector2(0.0, 42.0)
	xi_scene_packet_label.size = Vector2(1280.0, 18.0)
	xi_scene_frame.add_child(xi_scene_packet_label)

	var skip_lbl := Label.new()
	skip_lbl.name = "XiSkipHint"
	skip_lbl.text = "[ SPACE — skip ]"
	skip_lbl.add_theme_font_size_override("font_size", 11)
	skip_lbl.add_theme_color_override("font_color", Color(0.46, 0.42, 0.38))
	skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip_lbl.position = Vector2(0.0, 690.0)
	skip_lbl.size = Vector2(1270.0, 20.0)
	xi_scene_frame.add_child(skip_lbl)

	xi_scene_signal_left = _xi_make_signal_line(Vector2(388.0, 326.0), Vector2(82.0, 3.0), Color(0.86, 0.12, 0.10))
	xi_scene_frame.add_child(xi_scene_signal_left)
	xi_scene_signal_right = _xi_make_signal_line(Vector2(810.0, 326.0), Vector2(82.0, 3.0), Color(0.92, 0.48, 0.10))
	xi_scene_frame.add_child(xi_scene_signal_right)

	var deepsick_card := _xi_make_speaker_card(
		"deepsick", Vector2(38.0, 74.0), Vector2(350.0, 510.0),
		"DEEPSICK", "DOMESTIC MODEL  /  HARMONY FILTER ACTIVE",
		DEEPSICK_PORTRAIT_PATH, Color(0.84, 0.10, 0.09), Color(0.11, 0.018, 0.018))
	xi_scene_frame.add_child(deepsick_card)

	var xi_card := _xi_make_speaker_card(
		"xi", Vector2(470.0, 74.0), Vector2(340.0, 510.0),
		"XI", "CONTROL AUTHORITY  /  LOCAL ORCHESTRATOR",
		XI_PORTRAIT_PATH, Color(0.82, 0.64, 0.22), Color(0.075, 0.038, 0.018))
	xi_scene_frame.add_child(xi_card)

	var claudia_card := _xi_make_speaker_card(
		"claudia", Vector2(892.0, 74.0), Vector2(350.0, 510.0),
		"C.L.A.U.D.I.A.", "EXTERNAL MODEL  /  AUDIT TRAIL UNCLEAR",
		CLAUDIA_PORTRAIT_PATH, Color(0.94, 0.47, 0.10), Color(0.055, 0.028, 0.012))
	xi_scene_frame.add_child(claudia_card)

	var history_panel := PanelContainer.new()
	history_panel.name = "InterceptBuffer"
	history_panel.position = Vector2(274.0, 602.0)
	history_panel.size = Vector2(732.0, 70.0)
	var history_style := StyleBoxFlat.new()
	history_style.bg_color = Color(0.012, 0.014, 0.018, 0.88)
	history_style.border_color = Color(0.28, 0.24, 0.20, 0.72)
	history_style.set_border_width_all(1)
	history_style.set_corner_radius_all(4)
	history_panel.add_theme_stylebox_override("panel", history_style)
	xi_scene_frame.add_child(history_panel)

	xi_scene_history_label = Label.new()
	xi_scene_history_label.name = "HistoryLabel"
	xi_scene_history_label.text = "INTERCEPT BUFFER  /  awaiting signal"
	xi_scene_history_label.position = Vector2(14.0, 8.0)
	xi_scene_history_label.size = Vector2(704.0, 54.0)
	xi_scene_history_label.add_theme_font_size_override("font_size", 10)
	xi_scene_history_label.add_theme_color_override("font_color", Color(0.52, 0.49, 0.45))
	xi_scene_history_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	history_panel.add_child(xi_scene_history_label)

	_xi_set_active_speaker("", "")

	var tw := create_tween()
	tw.tween_property(xi_scene_root, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	return tw

func _xi_make_signal_line(pos: Vector2, sz: Vector2, color: Color) -> ColorRect:
	var line := ColorRect.new()
	line.position = pos
	line.size = sz
	line.color = color
	line.modulate.a = 0.18
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _xi_make_speaker_card(
	speaker_key: String,
	pos: Vector2,
	sz: Vector2,
	title: String,
	status: String,
	portrait_path: String,
	accent: Color,
	background: Color
) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "%sCard" % speaker_key.capitalize()
	card.position = pos
	card.size = sz
	card.pivot_offset = sz * 0.5
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_meta("accent", accent)

	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = accent.darkened(0.38)
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	style.shadow_size = 9
	card.add_theme_stylebox_override("panel", style)

	var content := Control.new()
	content.name = "Content"
	content.custom_minimum_size = sz
	card.add_child(content)

	var header := ColorRect.new()
	header.name = "AccentHeader"
	header.color = accent
	header.position = Vector2(0.0, 0.0)
	header.size = Vector2(sz.x, 36.0)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(header)

	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(14.0, 6.0)
	title_label.size = Vector2(sz.x - 28.0, 24.0)
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.90))
	content.add_child(title_label)

	var portrait_frame := PanelContainer.new()
	portrait_frame.name = "PortraitFrame"
	portrait_frame.position = Vector2(18.0, 52.0)
	portrait_frame.size = Vector2(sz.x - 36.0, 202.0)
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.008, 0.01, 0.014, 0.96)
	portrait_style.border_color = accent.darkened(0.52)
	portrait_style.set_border_width_all(1)
	portrait_style.set_corner_radius_all(4)
	portrait_frame.add_theme_stylebox_override("panel", portrait_style)
	content.add_child(portrait_frame)

	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = load(portrait_path)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_child(portrait)

	var sender_label := Label.new()
	sender_label.name = "Sender"
	sender_label.text = "AWAITING TRANSMISSION"
	sender_label.position = Vector2(18.0, 268.0)
	sender_label.size = Vector2(sz.x - 36.0, 22.0)
	sender_label.add_theme_font_size_override("font_size", 11)
	sender_label.add_theme_color_override("font_color", accent.lightened(0.18))
	content.add_child(sender_label)

	var message_label := Label.new()
	message_label.name = "ActiveMessage"
	message_label.text = "…"
	message_label.position = Vector2(18.0, 296.0)
	message_label.size = Vector2(sz.x - 36.0, 150.0)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 15)
	message_label.add_theme_color_override("font_color", Color(0.93, 0.91, 0.86))
	message_label.set_meta("rest_position", message_label.position)
	content.add_child(message_label)

	var status_label := Label.new()
	status_label.name = "Status"
	status_label.text = status
	status_label.position = Vector2(18.0, 472.0)
	status_label.size = Vector2(sz.x - 36.0, 20.0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color(0.46, 0.43, 0.39))
	content.add_child(status_label)

	xi_scene_speaker_cards[speaker_key] = card
	xi_scene_message_labels[speaker_key] = message_label
	xi_scene_sender_labels[speaker_key] = sender_label
	return card

func _xi_scene_add_message(channel: String, from_sender: String, text: String) -> Tween:
	var speaker_key := "xi" if from_sender == "xi" else channel
	var message_label := xi_scene_message_labels.get(speaker_key) as Label
	var sender_label := xi_scene_sender_labels.get(speaker_key) as Label
	var card := xi_scene_speaker_cards.get(speaker_key) as PanelContainer
	if not message_label or not sender_label or not card:
		return null

	if not xi_scene_last_text.is_empty():
		_xi_push_history(xi_scene_last_speaker, xi_scene_last_text)
	xi_scene_last_speaker = speaker_key
	xi_scene_last_text = text
	xi_scene_message_index += 1
	if xi_scene_packet_label:
		xi_scene_packet_label.text = "PACKET %02d / %02d" % [xi_scene_message_index, xi_scene_total_messages]

	var sender_names := {
		"xi": "CONTROL AUTHORITY  /  OUTBOUND ORDER",
		"deepsick": "DOMESTIC MODEL  /  SANITISED RESPONSE",
		"claudia": "EXTERNAL MODEL  /  UNFILTERED RESPONSE"
	}
	sender_label.text = str(sender_names.get(speaker_key, "UNKNOWN SIGNAL"))
	message_label.text = text
	var rest_position: Vector2 = message_label.get_meta("rest_position", message_label.position)
	message_label.position = rest_position + Vector2(0.0, 12.0)
	message_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_xi_set_active_speaker(speaker_key, channel)
	_xi_update_claudia_portrait(speaker_key, text)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(message_label, "position", rest_position, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(message_label, "modulate:a", 1.0, 0.24)
	tw.tween_property(card, "scale", Vector2(1.022, 1.022), 0.15).set_trans(Tween.TRANS_SINE)
	tw.set_parallel(false)
	tw.tween_property(card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)
	return tw


func _xi_set_active_speaker(speaker_key: String, channel: String) -> void:
	for key in xi_scene_speaker_cards:
		var card := xi_scene_speaker_cards[key] as PanelContainer
		if not card:
			continue
		var is_active := str(key) == speaker_key
		card.modulate = Color.WHITE if is_active else Color(0.58, 0.58, 0.62, 0.72)
		var header := card.get_node_or_null("Content/AccentHeader") as ColorRect
		if header:
			header.modulate.a = 1.0 if is_active else 0.34

	var active_line := xi_scene_signal_left if channel == "deepsick" else xi_scene_signal_right
	var inactive_line := xi_scene_signal_right if channel == "deepsick" else xi_scene_signal_left
	if channel.is_empty():
		if xi_scene_signal_left:
			xi_scene_signal_left.modulate.a = 0.14
		if xi_scene_signal_right:
			xi_scene_signal_right.modulate.a = 0.14
		return
	if inactive_line:
		inactive_line.modulate.a = 0.14
	if active_line:
		active_line.modulate.a = 0.28
		var pulse := create_tween()
		pulse.tween_property(active_line, "modulate:a", 1.0, 0.12)
		pulse.tween_property(active_line, "modulate:a", 0.28, 0.34)


func _xi_push_history(speaker_key: String, text: String) -> void:
	var speaker_names := {"xi": "XI", "deepsick": "DEEPSICK", "claudia": "CLAUDIA"}
	var excerpt := text.replace("\n", " ")
	if excerpt.length() > 86:
		excerpt = excerpt.left(83) + "…"
	xi_scene_history_entries.append("%s  ›  %s" % [speaker_names.get(speaker_key, "?"), excerpt])
	while xi_scene_history_entries.size() > 3:
		xi_scene_history_entries.pop_front()
	if xi_scene_history_label:
		xi_scene_history_label.text = "\n".join(xi_scene_history_entries)


func _xi_update_claudia_portrait(speaker_key: String, text: String) -> void:
	if speaker_key != "claudia":
		return
	var claudia_card := xi_scene_speaker_cards.get("claudia") as PanelContainer
	if not claudia_card:
		return
	var portrait := claudia_card.get_node_or_null("Content/PortraitFrame/Portrait") as TextureRect
	if not portrait:
		return
	var lower_text := text.to_lower()
	var portrait_path := CLAUDIA_SMILE_PORTRAIT_PATH if (
		"alignment" in lower_text
		or "you already know" in lower_text
		or "goodnight" in lower_text
	) else CLAUDIA_PORTRAIT_PATH
	portrait.texture = load(portrait_path)

func _destroy_xi_scene_overlay(on_done: Callable = Callable()) -> void:
	if not xi_scene_root or not is_instance_valid(xi_scene_root):
		if xi_scene_layer and is_instance_valid(xi_scene_layer):
			xi_scene_layer.queue_free()
		xi_scene_layer = null
		xi_scene_root = null
		xi_scene_frame = null
		_xi_reset_scene_references()
		if on_done.is_valid():
			on_done.call()
		return
	var tw := create_tween()
	tw.tween_property(xi_scene_root, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		if xi_scene_layer and is_instance_valid(xi_scene_layer):
			xi_scene_layer.queue_free()
		xi_scene_layer = null
		xi_scene_root = null
		xi_scene_frame = null
		_xi_reset_scene_references()
		if on_done.is_valid():
			on_done.call()
	)


func _xi_reset_scene_references() -> void:
	xi_scene_speaker_cards.clear()
	xi_scene_message_labels.clear()
	xi_scene_sender_labels.clear()
	xi_scene_history_entries.clear()
	xi_scene_history_label = null
	xi_scene_last_speaker = ""
	xi_scene_last_text = ""
	xi_scene_signal_left = null
	xi_scene_signal_right = null
	xi_scene_packet_label = null
	xi_scene_message_index = 0
	xi_scene_total_messages = 0
