extends Node

const DOORWAY_SCRIPT = preload("res://scripts/doorway.gd")
const LAYER_DECOR := 1
const NORTHERN_WALL_PATH := "res://assets/landmarks/northern_great_wall_v1.png"
const LEGACY_GREAT_WALL_PATH := "res://assets/mockups/landmark_great_wall.png"
const NORTHERN_WALL_HEIGHT := 448.0
const NORTHERN_WALL_FRONT_Y := 403.0
const NORTHERN_GATE_OVERHANG := 48.0
const NORTHERN_GATE_HALF_WIDTH := 64.0

var entities_layer: Node2D
var ground_map: TileMap


func setup(world_entities_layer: Node2D, world_ground_map: TileMap) -> void:
	entities_layer = world_entities_layer
	ground_map = world_ground_map


func create_great_wall(world_bounds: Rect2, entrance_tile: Vector2i) -> void:
	if not ResourceLoader.exists(NORTHERN_WALL_PATH):
		_create_legacy_great_wall(entrance_tile + Vector2i(0, -4))
		return
	var texture := load(NORTHERN_WALL_PATH) as Texture2D
	if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0:
		_create_legacy_great_wall(entrance_tile + Vector2i(0, -4))
		return

	var root := Node2D.new()
	root.name = "GreatWallEntrance"
	# Anchor the wall's front line to the north boundary. The wall mass remains
	# outside the playable map; only the central gate projects into the avenue.
	root.position = Vector2(
		world_bounds.position.x,
		world_bounds.position.y - NORTHERN_WALL_FRONT_Y
	)
	root.z_index = 2
	root.add_to_group("northern_perimeter_landmark")
	root.set_meta("asset_path", NORTHERN_WALL_PATH)
	root.set_meta("world_bounds", world_bounds)
	entities_layer.add_child(root)

	var sprite := Sprite2D.new()
	sprite.name = "NorthernGreatWall"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = false
	sprite.scale = Vector2(
		world_bounds.size.x / float(texture.get_width()),
		NORTHERN_WALL_HEIGHT / float(texture.get_height())
	)
	root.add_child(sprite)

	# The district plate's boulevard is visually centered at world x = 0, while
	# tile-body positions carry a 16 px cell-center offset. Use the world axis so
	# the authored arch and its trigger share the exact visible road center.
	var gate_world := Vector2(
		world_bounds.position.x + world_bounds.size.x * 0.5,
		world_bounds.position.y + NORTHERN_GATE_OVERHANG
	)
	var gate_local := gate_world - root.position
	root.set_meta("gate_world_position", root.position + gate_local)
	_add_northern_wall_collision(root, gate_local.x, world_bounds.size.x)
	_add_landmark_entry_trigger(
		root,
		"GreatWallCentralGate",
		gate_local,
		Vector2(96.0, 56.0),
		"red_command",
		"EntryMarker",
		"Harmonious Gate"
	)


func _create_legacy_great_wall(tile: Vector2i) -> void:
	_clear_decor_patch(tile, 4, 3)
	if not ResourceLoader.exists(LEGACY_GREAT_WALL_PATH):
		return

	var root := Node2D.new()
	root.name = "GreatWallEntrance"
	root.position = _tile_to_body_position(tile)
	root.z_index = 2
	entities_layer.add_child(root)

	var texture := load(LEGACY_GREAT_WALL_PATH) as Texture2D
	var sprite := Sprite2D.new()
	sprite.name = "GreatWallLandmark"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = Vector2(0, -texture.get_height() * 0.5)
	sprite.scale = Vector2(0.38, 0.38)
	root.add_child(sprite)

	_add_landmark_entry_trigger(root, "GreatWallDoorLeft", Vector2(-82, -40), Vector2(92, 86), "red_command", "EntryMarker", "Wall Gate")
	_add_landmark_entry_trigger(root, "GreatWallDoorCenter", Vector2(2, -156), Vector2(72, 62), "red_command", "EntryMarker", "Wall Gate")
	_add_landmark_entry_trigger(root, "GreatWallDoorRight", Vector2(76, -106), Vector2(92, 96), "red_command", "EntryMarker", "Wall Gate")


func _add_northern_wall_collision(parent: Node2D, gate_x: float, wall_width: float) -> void:
	var collision := StaticBody2D.new()
	collision.name = "NorthernWallCollision"
	parent.add_child(collision)

	var left_width := maxf(gate_x - NORTHERN_GATE_HALF_WIDTH, 0.0)
	var right_start := minf(gate_x + NORTHERN_GATE_HALF_WIDTH, wall_width)
	var right_width := maxf(wall_width - right_start, 0.0)
	_add_collision_rect(collision, "WestWall", Vector2(left_width * 0.5, NORTHERN_WALL_FRONT_Y), Vector2(left_width, 48.0))
	_add_collision_rect(collision, "EastWall", Vector2(right_start + right_width * 0.5, NORTHERN_WALL_FRONT_Y), Vector2(right_width, 48.0))


func _add_collision_rect(parent: StaticBody2D, shape_name: String, position: Vector2, size: Vector2) -> void:
	var shape_node := CollisionShape2D.new()
	shape_node.name = shape_name
	shape_node.position = position
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape_node.shape = rectangle
	parent.add_child(shape_node)


func create_nuclear_plant(tile: Vector2i) -> void:
	_clear_decor_patch(tile, 4, 3)

	var tex_path = "res://assets/mockups/landmark_nuclear_plant.png"
	if not ResourceLoader.exists(tex_path):
		return

	var root := Node2D.new()
	root.name = "NuclearPlantEntrance"
	root.position = _tile_to_body_position(tile)
	root.z_index = 2
	entities_layer.add_child(root)

	var tex = load(tex_path)
	var plant = Sprite2D.new()
	plant.name = "NuclearPlantLandmark"
	plant.texture = tex
	plant.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plant.offset = Vector2(0, -tex.get_height() * 0.5)
	plant.scale = Vector2(0.38, 0.38)
	root.add_child(plant)

	_add_landmark_entry_trigger(root, "NeuralCoreDoorLeft", Vector2(-76, -18), Vector2(92, 88), "neural_core", "EntryMarker", "Containment Door")
	_add_landmark_entry_trigger(root, "NeuralCoreDoorCenter", Vector2(6, -28), Vector2(94, 102), "neural_core", "EntryMarker", "Containment Door")
	_add_landmark_entry_trigger(root, "NeuralCoreDoorRight", Vector2(92, 12), Vector2(84, 82), "neural_core", "EntryMarker", "Containment Door")


func create_hidden_bunker(tile: Vector2i, world_offset: Vector2) -> void:
	_clear_decor_patch(tile, 3, 2)

	var root := Node2D.new()
	root.name = "HiddenBunkerEntrance"
	root.position = _tile_to_body_position(tile) + world_offset
	root.z_index = 2
	entities_layer.add_child(root)

	var shadow := Polygon2D.new()
	shadow.color = Color(0.0, 0.0, 0.0, 0.16)
	shadow.polygon = PackedVector2Array([
		Vector2(-116, 54),
		Vector2(116, 54),
		Vector2(86, 90),
		Vector2(-86, 90)
	])
	root.add_child(shadow)

	var mountain = Sprite2D.new()
	mountain.texture = load("res://assets/mockups/landmark_bunker.png")
	mountain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mountain.scale = Vector2(0.42, 0.42)
	mountain.offset = Vector2(0, -10)
	root.add_child(mountain)

	var door := Area2D.new()
	door.name = "HiddenBunkerDoor"
	door.position = Vector2(0, 42)
	door.collision_layer = 0
	door.collision_mask = 1
	door.monitoring = true
	door.monitorable = true
	door.set_script(DOORWAY_SCRIPT)
	door.set("destination", "mountain_bunker")
	door.set("spawn_marker", "EntryMarker")
	door.set("prompt_name", "Bunker Hatch")
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(84, 44)
	col.shape = shape
	door.add_child(col)
	root.add_child(door)


func create_pyongyang(tile: Vector2i) -> void:
	_clear_decor_patch(tile, 4, 3)

	var tex_path = "res://assets/mockups/landmark_pyongyang.png"
	if not ResourceLoader.exists(tex_path):
		return

	var root := Node2D.new()
	root.name = "PyongyangEntrance"
	root.position = _tile_to_body_position(tile)
	root.z_index = 2
	entities_layer.add_child(root)

	var tex = load(tex_path)
	var sprite = Sprite2D.new()
	sprite.name = "PyongyangLandmark"
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex_h = tex.get_height()
	sprite.offset = Vector2(0, -tex_h * 0.45)
	sprite.scale = Vector2(0.2, 0.2)
	root.add_child(sprite)

	_add_landmark_entry_trigger(root, "PyongyangCannonDoorLeft", Vector2(-52, -56), Vector2(74, 94), "pyongyang_command", "EntryMarker", "Cannon Hatch")
	_add_landmark_entry_trigger(root, "PyongyangCannonDoorCenter", Vector2(2, -96), Vector2(82, 108), "pyongyang_command", "EntryMarker", "Cannon Hatch")
	_add_landmark_entry_trigger(root, "PyongyangCannonDoorRight", Vector2(50, -136), Vector2(74, 86), "pyongyang_command", "EntryMarker", "Cannon Hatch")


func _add_landmark_entry_trigger(parent: Node2D, trigger_name: String, local_pos: Vector2, size: Vector2, destination: String, spawn_marker: String, prompt_name: String) -> void:
	var door := Area2D.new()
	door.name = trigger_name
	door.position = local_pos
	door.collision_layer = 0
	door.collision_mask = 1
	door.monitoring = true
	door.monitorable = true
	door.set_script(DOORWAY_SCRIPT)
	door.set("destination", destination)
	door.set("spawn_marker", spawn_marker)
	door.set("prompt_name", prompt_name)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	door.add_child(col)
	parent.add_child(door)


func _clear_decor_patch(center_tile: Vector2i, x_radius: int, y_radius: int) -> void:
	for x in range(center_tile.x - x_radius, center_tile.x + x_radius + 1):
		for y in range(center_tile.y - y_radius, center_tile.y + y_radius + 2):
			ground_map.erase_cell(LAYER_DECOR, Vector2i(x, y))


func _tile_to_body_position(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * 32 + 16, tile_pos.y * 32 + 16)
