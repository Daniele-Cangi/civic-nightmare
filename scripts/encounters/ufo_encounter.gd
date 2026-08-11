extends Node

signal triggered

var player: CharacterBody2D
var entities_layer: Node2D
var ufo_root: Node2D
var ufo_beam: Polygon2D
var ufo_clouds: Sprite2D
var ufo_quantum_nodes: Array[Sprite2D] = []
var ufo_base_position := Vector2.ZERO
var ufo_hover_time := 0.0


func setup(world_player: CharacterBody2D, world_entities_layer: Node2D, spawn_position: Vector2) -> void:
	player = world_player
	entities_layer = world_entities_layer
	ufo_base_position = spawn_position
	_create_world_node()


func process_frame(delta: float) -> void:
	if not ufo_root:
		return

	ufo_hover_time += delta * 1.8
	var sway = sin(ufo_hover_time * 0.5) * 24.0
	var hover = sin(ufo_hover_time) * 6.0
	ufo_root.position = ufo_base_position + Vector2(sway, hover)

	if ufo_beam:
		ufo_beam.modulate.a = 0.14 + (sin(ufo_hover_time * 2.4) * 0.08 + 0.08)

	for sym in ufo_quantum_nodes:
		if randf() < delta * 4.0:
			var angle = randf() * TAU
			var dist = randf_range(40, 90)
			sym.position = Vector2(cos(angle) * dist, sin(angle) * dist - 40.0)
			sym.modulate.a = 0.8
			sym.scale = Vector2(randf_range(0.3, 0.5), randf_range(0.3, 0.5))
			var rx = (randi() % 8) * 80
			var ry = (randi() % 8) * 80
			sym.region_rect = Rect2(rx, ry, 80, 80)
		else:
			sym.modulate.a = max(0.0, sym.modulate.a - delta * 4.0)

	if ufo_clouds:
		ufo_clouds.position.x = -sway * 0.5


func prepare_lab(room: Node, npc_sprite_paths: Dictionary) -> void:
	if not room:
		return

	var einstein = room.get_node_or_null("Entities/AlbertEinsteinPlaceholder")
	var zuck = room.get_node_or_null("Entities/MarkZuckerbergPlaceholder")

	for data in [[einstein, "ufo_easter_egg", true], [zuck, "mark_zuckerberg_ufo", false]]:
		var node = data[0] as StaticBody2D
		var sprite_id = data[1]
		var is_einstein = data[2]
		if node:
			node.process_mode = Node.PROCESS_MODE_INHERIT
			node.scale = Vector2(0.88, 0.88)
			if is_einstein:
				node.set("patrol_range", 10.0)
				node.set("patrol_speed", 18.0)
			var sprite = node.get_node_or_null("Sprite2D") as Sprite2D
			if sprite:
				sprite.texture = load(npc_sprite_paths.get(sprite_id, ""))
				sprite.visible = true
				if node.has_method("_ready"):
					node.set("base_scale", sprite.scale)
			var placeholder_visual = node.get_node_or_null("PlaceholderVisual")
			if placeholder_visual:
				placeholder_visual.visible = false


func _create_world_node() -> void:
	ufo_root = Node2D.new()
	ufo_root.name = "UfoEasterEgg"
	ufo_root.position = ufo_base_position
	ufo_root.z_index = 4
	entities_layer.add_child(ufo_root)

	var shadow = Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.18)
	shadow.polygon = _ellipse_points(Vector2(0, 28), Vector2(54, 14), 18)
	ufo_root.add_child(shadow)

	ufo_clouds = Sprite2D.new()
	ufo_clouds.texture = load("res://assets/mockups/ufo_clouds.png")
	ufo_clouds.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ufo_clouds.scale = Vector2(0.4, 0.4)
	ufo_clouds.position = Vector2(0, -120)
	ufo_clouds.modulate.a = 0.8
	ufo_root.add_child(ufo_clouds)

	ufo_beam = Polygon2D.new()
	ufo_beam.color = Color(0.72, 1.0, 0.82, 0.18)
	ufo_beam.polygon = PackedVector2Array([
		Vector2(-24, 10),
		Vector2(24, 10),
		Vector2(68, 106),
		Vector2(-68, 106)
	])
	ufo_root.add_child(ufo_beam)

	var ufo_sprite = Sprite2D.new()
	ufo_sprite.texture = load("res://assets/mockups/ufo_advanced.png")
	ufo_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ufo_sprite.scale = Vector2(0.22, 0.22)
	ufo_root.add_child(ufo_sprite)

	var sym_tex = load("res://assets/mockups/quantum_symbols.png")
	for i in range(8):
		var sym = Sprite2D.new()
		sym.texture = sym_tex
		sym.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sym.region_enabled = true
		var rx = (randi() % 10) * 64
		var ry = (randi() % 10) * 64
		sym.region_rect = Rect2(rx, ry, 64, 64)
		sym.scale = Vector2(0.4, 0.4)
		sym.modulate = Color(0.5, 1.0, 0.6, 0.0)
		ufo_root.add_child(sym)
		ufo_quantum_nodes.append(sym)

	var trigger = Area2D.new()
	trigger.name = "UfoTrigger"
	trigger.collision_layer = 0
	trigger.collision_mask = 1
	trigger.monitoring = true
	trigger.monitorable = true
	var trigger_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(148, 112)
	trigger_shape.shape = shape
	trigger_shape.position = Vector2(0, 44)
	trigger.add_child(trigger_shape)
	trigger.body_entered.connect(_on_trigger_body_entered)
	ufo_root.add_child(trigger)


func _on_trigger_body_entered(body: Node) -> void:
	if body == player:
		triggered.emit()


func _ellipse_points(center: Vector2, radius: Vector2, segments: int = 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points
