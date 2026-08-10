extends Node

const ROOM_SCENE = preload("res://scenes/interiors/oval_office.tscn")
const DOORWAY_SCRIPT = preload("res://scripts/doorway.gd")

var host: Node
var entities_layer: Node2D
var player: CharacterBody2D

var interiors_layer: Node2D
var room_registry: Dictionary = {}
var world_spawn_points: Dictionary = {}

var interior_overlay: ColorRect
var transition_overlay: ColorRect
var room_title_card: PanelContainer
var room_title_label: Label
var room_title_subtitle: Label


func setup(owner: Node, world_entities: Node2D, player_node: CharacterBody2D) -> void:
	host = owner
	entities_layer = world_entities
	player = player_node


func create_transition_ui(ui_layer: CanvasLayer) -> void:
	if transition_overlay:
		return

	interior_overlay = ColorRect.new()
	interior_overlay.name = "InteriorOverlay"
	interior_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interior_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	interior_overlay.color = Color(0.03, 0.04, 0.06, 0.42)
	interior_overlay.modulate.a = 0.0
	interior_overlay.visible = false
	ui_layer.add_child(interior_overlay)
	ui_layer.move_child(interior_overlay, 1)

	room_title_card = PanelContainer.new()
	room_title_card.name = "RoomTitle"
	room_title_card.visible = false
	room_title_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_title_card.anchor_left = 0.5
	room_title_card.anchor_top = 0.0
	room_title_card.anchor_right = 0.5
	room_title_card.anchor_bottom = 0.0
	room_title_card.offset_left = -170.0
	room_title_card.offset_top = 26.0
	room_title_card.offset_right = 170.0
	room_title_card.offset_bottom = 92.0

	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.03, 0.03, 0.05, 0.9)
	title_style.border_width_left = 2
	title_style.border_width_right = 2
	title_style.border_width_bottom = 2
	title_style.border_color = Color(0.76, 0.63, 0.38, 0.95)
	title_style.corner_radius_top_left = 6
	title_style.corner_radius_top_right = 6
	title_style.corner_radius_bottom_left = 6
	title_style.corner_radius_bottom_right = 6
	title_style.content_margin_top = 8
	title_style.content_margin_bottom = 8
	room_title_card.add_theme_stylebox_override("panel", title_style)

	var title_box = VBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.add_theme_constant_override("separation", 1)
	room_title_card.add_child(title_box)

	room_title_label = Label.new()
	room_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_title_label.add_theme_font_size_override("font_size", 22)
	room_title_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.74))
	title_box.add_child(room_title_label)

	room_title_subtitle = Label.new()
	room_title_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_title_subtitle.add_theme_font_size_override("font_size", 12)
	room_title_subtitle.add_theme_color_override("font_color", Color(0.72, 0.75, 0.82))
	title_box.add_child(room_title_subtitle)
	ui_layer.add_child(room_title_card)

	transition_overlay = ColorRect.new()
	transition_overlay.name = "TransitionOverlay"
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_overlay.color = Color.BLACK
	transition_overlay.modulate.a = 0.0
	transition_overlay.visible = false
	ui_layer.add_child(transition_overlay)


func setup_interiors(building_specs: Array, special_specs: Array, display_name_resolver: Callable) -> void:
	if interiors_layer:
		return

	interiors_layer = Node2D.new()
	interiors_layer.name = "Interiors"
	host.add_child(interiors_layer)

	for index in range(building_specs.size()):
		var spec: Dictionary = building_specs[index]
		_register_room(
			str(spec["key"]),
			str(spec["npc"]),
			str(display_name_resolver.call(str(spec["npc"]))),
			index
		)
		var entrance: Vector2i = spec["entrance"]
		world_spawn_points["%s_exterior" % spec["key"]] = _tile_to_actor_position(entrance + Vector2i(0, 2))
		create_world_doorway("%sDoor" % _pascal_case(str(spec["key"])), entrance, str(spec["key"]), "EntryMarker")

	for offset in range(special_specs.size()):
		var spec: Dictionary = special_specs[offset]
		_register_room(
			str(spec["key"]),
			str(spec["character_id"]),
			str(spec["character_name"]),
			building_specs.size() + offset,
			str(spec["node_name"])
		)
		world_spawn_points[str(spec["spawn_marker"])] = spec["world_position"]


func _register_room(room_key: String, character_id: String, character_name: String, index: int, node_name: String = "") -> void:
	var room = ROOM_SCENE.instantiate()
	room.name = node_name if node_name != "" else "%sInterior" % _pascal_case(room_key)
	room.position = Vector2(0, 3200 + index * 960)
	room.set("room_key", room_key)
	room.set("character_id", character_id)
	room.set("character_name", character_name)
	interiors_layer.add_child(room)
	room_registry[room_key] = room
	if room.has_method("set_room_active"):
		room.set_room_active(false)


func create_world_doorway(door_name: String, tile_pos: Vector2i, destination: String, spawn_marker: String) -> void:
	var door := Area2D.new()
	door.name = door_name
	door.collision_layer = 0
	door.collision_mask = 1
	door.monitoring = true
	door.monitorable = true
	door.position = _tile_to_body_position(tile_pos)
	door.set_script(DOORWAY_SCRIPT)
	door.set("destination", destination)
	door.set("spawn_marker", spawn_marker)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(76, 42)
	col.shape = shape
	door.add_child(col)
	entities_layer.add_child(door)


func enter_room(room_id: String, current_room_id: String, spawn_marker: String) -> bool:
	var room = room_registry.get(room_id)
	if room == null:
		return false
	if current_room_id != "" and room_registry.has(current_room_id):
		var current_room = room_registry[current_room_id]
		if current_room and current_room != room and current_room.has_method("set_room_active"):
			current_room.set_room_active(false)

	if room.has_method("set_room_active"):
		room.set_room_active(true)
	if room.has_method("get_entity_container"):
		var room_entities = room.get_entity_container()
		if room_entities and player.get_parent() != room_entities:
			player.reparent(room_entities, true)
	if room.has_method("get_spawn_position"):
		player.velocity = Vector2.ZERO
		player.global_position = room.get_spawn_position(spawn_marker)
	return true


func exit_room(current_room_id: String, spawn_marker: String) -> void:
	var room = room_registry.get(current_room_id)
	if player.get_parent() != entities_layer:
		player.reparent(entities_layer, true)

	player.velocity = Vector2.ZERO
	if current_room_id != "" and room_registry.has(current_room_id):
		if room and room.has_method("set_room_active"):
			room.set_room_active(false)

	if world_spawn_points.has(spawn_marker):
		player.global_position = world_spawn_points[spawn_marker]


func fade_transition(target_alpha: float, duration: float) -> void:
	transition_overlay.visible = true
	var tw = create_tween()
	tw.tween_property(transition_overlay, "modulate:a", target_alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if is_zero_approx(target_alpha):
		transition_overlay.visible = false


func set_room_presentation(indoor: bool, world_canvas_modulate: CanvasModulate, screen_fx_material: ShaderMaterial, hud_panel: PanelContainer) -> void:
	if player.has_method("set_traversal_context"):
		player.set_traversal_context(indoor)

	if world_canvas_modulate:
		world_canvas_modulate.color = Color(0.88, 0.9, 0.94) if indoor else Color(0.95, 0.96, 0.98)

	if interior_overlay:
		interior_overlay.visible = true
		var overlay_alpha := 0.52 if indoor else 0.0
		var overlay_tw = create_tween()
		overlay_tw.tween_property(interior_overlay, "modulate:a", overlay_alpha, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if not indoor:
			overlay_tw.finished.connect(func() -> void:
				if interior_overlay:
					interior_overlay.visible = false
			)

	if screen_fx_material:
		if indoor:
			screen_fx_material.set_shader_parameter("effect_strength", 0.12)
			screen_fx_material.set_shader_parameter("color_levels", 9.0)
			screen_fx_material.set_shader_parameter("scanline_strength", 0.05)
			screen_fx_material.set_shader_parameter("vignette_strength", 0.18)
			screen_fx_material.set_shader_parameter("overlay_strength", 0.24)
			screen_fx_material.set_shader_parameter("tint_color", Color(0.9, 0.91, 0.95, 1.0))
		else:
			screen_fx_material.set_shader_parameter("effect_strength", 0.08)
			screen_fx_material.set_shader_parameter("color_levels", 10.0)
			screen_fx_material.set_shader_parameter("scanline_strength", 0.04)
			screen_fx_material.set_shader_parameter("vignette_strength", 0.1)
			screen_fx_material.set_shader_parameter("overlay_strength", 0.2)
			screen_fx_material.set_shader_parameter("tint_color", Color(0.96, 0.97, 0.98, 1.0))

	if hud_panel:
		hud_panel.modulate = Color(0.9, 0.93, 0.98, 0.92) if indoor else Color(1, 1, 1, 1)


func show_room_title(title: String, subtitle: String = "") -> void:
	if not room_title_card:
		return
	room_title_label.text = title
	room_title_subtitle.text = subtitle
	room_title_card.visible = true
	room_title_card.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(room_title_card, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.55)
	tw.tween_property(room_title_card, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		if room_title_card:
			room_title_card.visible = false
	)


func _tile_to_actor_position(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * 32 + 16, tile_pos.y * 32)


func _tile_to_body_position(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * 32 + 16, tile_pos.y * 32 + 16)


func _pascal_case(value: String) -> String:
	var cleaned := value.strip_edges()
	if cleaned.is_empty():
		return "Room"
	var parts := cleaned.split("_", false)
	var result := ""
	for part in parts:
		if part.is_empty():
			continue
		result += part.substr(0, 1).to_upper() + part.substr(1).to_lower()
	return result if not result.is_empty() else "Room"
