extends Node

const FRAME_SIZE := Vector2(1280.0, 720.0)

var host: Node
var player: CharacterBody2D
var data_cache: Dictionary

var xi_pre_scene_seen: bool = false
var xi_pre_scene_active: bool = false
var xi_pre_skip_requested: bool = false
var xi_scene_layer: CanvasLayer
var xi_scene_root: Control
var xi_scene_frame: Control
var xi_scene_left_vbox: VBoxContainer
var xi_scene_right_vbox: VBoxContainer


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
	var intro_tween := _build_xi_scene_overlay()
	if intro_tween:
		await intro_tween.finished
	if xi_pre_skip_requested:
		xi_pre_skip_requested = false
		xi_pre_scene_seen = true
		_destroy_xi_scene_overlay(func() -> void:
			xi_pre_scene_active = false
			player.set_physics_process(true)
			if xi_room and xi_room.has_method("set_npc_interaction_enabled"):
				xi_room.set_npc_interaction_enabled(true)
			if xi_room and xi_room.has_method("require_npc_reapproach"):
				xi_room.require_npc_reapproach()
		)
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

	xi_pre_skip_requested = false

	# Show "press space" hint and wait for player input
	if xi_scene_frame and is_instance_valid(xi_scene_frame):
		var close_lbl := Label.new()
		close_lbl.name = "XiCloseHint"
		close_lbl.text = "[ SPACE — close transmission ]"
		close_lbl.add_theme_font_size_override("font_size", 14)
		close_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		close_lbl.position = Vector2(0.0, 690.0)
		close_lbl.size = Vector2(1280.0, 24.0)
		xi_scene_frame.add_child(close_lbl)
		var blink_t: float = 0.0
		while true:
			await get_tree().process_frame
			blink_t += get_process_delta_time() * 3.0
			close_lbl.modulate.a = 0.45 + sin(blink_t) * 0.45
			if Input.is_action_just_pressed("ui_accept"):
				break

	xi_pre_scene_seen = true
	_destroy_xi_scene_overlay(func() -> void:
		xi_pre_scene_active = false
		player.set_physics_process(true)
		if xi_room and xi_room.has_method("set_npc_interaction_enabled"):
			xi_room.set_npc_interaction_enabled(true)
		if xi_room and xi_room.has_method("require_npc_reapproach"):
			xi_room.require_npc_reapproach()
	)

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
	bg.color = Color(0.0, 0.0, 0.03, 0.93)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	xi_scene_root.add_child(bg)

	xi_scene_frame = Control.new()
	xi_scene_frame.name = "XiSceneFrame"
	xi_scene_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xi_scene_frame.size = FRAME_SIZE
	xi_scene_root.add_child(xi_scene_frame)
	_layout_xi_scene_frame()

	var intercept_lbl := Label.new()
	intercept_lbl.text = "[ INTERCEPTED COMMUNICATIONS — CLASSIFIED ]"
	intercept_lbl.add_theme_font_size_override("font_size", 15)
	intercept_lbl.add_theme_color_override("font_color", Color(0.38, 0.38, 0.38))
	intercept_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intercept_lbl.position = Vector2(0.0, 20.0)
	intercept_lbl.size = Vector2(1280.0, 24.0)
	xi_scene_frame.add_child(intercept_lbl)

	var skip_lbl := Label.new()
	skip_lbl.text = "[ SPACE — skip ]"
	skip_lbl.add_theme_font_size_override("font_size", 13)
	skip_lbl.add_theme_color_override("font_color", Color(0.28, 0.28, 0.28))
	skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip_lbl.position = Vector2(0.0, 700.0)
	skip_lbl.size = Vector2(1270.0, 20.0)
	xi_scene_frame.add_child(skip_lbl)

	var left_panel := _xi_make_panel(
		Vector2(40.0, 58.0), Vector2(570.0, 630.0),
		Color(0.02, 0.04, 0.12), "DEEPSICK  v3.1  [ 国内版 ]",
		Color(0.05, 0.22, 0.72))
	xi_scene_frame.add_child(left_panel)
	xi_scene_left_vbox = left_panel.get_node_or_null("Scroll") as VBoxContainer

	var right_panel := _xi_make_panel(
		Vector2(670.0, 58.0), Vector2(570.0, 630.0),
		Color(0.10, 0.05, 0.01), "C.L.A.U.D.I.A.  EXTERNAL  RELAY",
		Color(0.80, 0.38, 0.02))
	xi_scene_frame.add_child(right_panel)
	xi_scene_right_vbox = right_panel.get_node_or_null("Scroll") as VBoxContainer

	var tw := create_tween()
	tw.tween_property(xi_scene_root, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	return tw

func _xi_make_panel(pos: Vector2, sz: Vector2, bg_col: Color, header_text: String, header_col: Color) -> Control:
	var panel := Control.new()
	panel.position = pos
	panel.size = sz

	var bg := ColorRect.new()
	bg.color = bg_col
	bg.size = sz
	panel.add_child(bg)

	var hdr := ColorRect.new()
	hdr.color = header_col
	hdr.size = Vector2(sz.x, 30.0)
	panel.add_child(hdr)

	var hdr_lbl := Label.new()
	hdr_lbl.text = "  " + header_text
	hdr_lbl.add_theme_font_size_override("font_size", 14)
	hdr_lbl.add_theme_color_override("font_color", Color.WHITE)
	hdr_lbl.position = Vector2(0.0, 6.0)
	hdr_lbl.size = Vector2(sz.x, 22.0)
	panel.add_child(hdr_lbl)

	var vbox := VBoxContainer.new()
	vbox.name = "Scroll"
	vbox.position = Vector2(8.0, 38.0)
	vbox.size = Vector2(sz.x - 16.0, 10.0)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	return panel

func _xi_scene_add_message(channel: String, from_sender: String, text: String) -> Tween:
	var vbox: VBoxContainer = xi_scene_left_vbox if channel == "deepsick" else xi_scene_right_vbox
	if not vbox or not is_instance_valid(vbox):
		return null

	var is_xi := from_sender == "xi"
	var prefix: String
	var col: Color
	if is_xi:
		prefix = "[XI]:"
		col = Color(0.92, 0.88, 0.55)
	elif channel == "deepsick":
		prefix = "[DEEPSICK]:"
		col = Color(0.38, 0.72, 1.00)
	else:
		prefix = "[C.L.A.U.D.I.A.]:"
		col = Color(1.00, 0.55, 0.12)

	var lbl := Label.new()
	lbl.text = prefix + " " + text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(vbox.size.x, 0.0)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", col)
	lbl.modulate = Color(1.0, 1.0, 1.0, 0.0)
	vbox.add_child(lbl)

	# Expand panel bg to match growing vbox
	var panel := vbox.get_parent() as Control
	if panel:
		var bg := panel.get_child(0) as ColorRect
		if bg:
			await get_tree().process_frame
			var new_h := maxf(vbox.position.y + vbox.size.y + 10.0, panel.size.y)
			bg.size.y = new_h

	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.28)
	return tw

func _destroy_xi_scene_overlay(on_done: Callable = Callable()) -> void:
	if not xi_scene_root or not is_instance_valid(xi_scene_root):
		if xi_scene_layer and is_instance_valid(xi_scene_layer):
			xi_scene_layer.queue_free()
		xi_scene_layer = null
		xi_scene_root = null
		xi_scene_frame = null
		xi_scene_left_vbox = null
		xi_scene_right_vbox = null
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
		xi_scene_left_vbox = null
		xi_scene_right_vbox = null
		if on_done.is_valid():
			on_done.call()
	)
