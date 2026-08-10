extends Node

const DOORWAY_SCRIPT = preload("res://scripts/doorway.gd")
const LAYER_DECOR := 1

var entities_layer: Node2D
var ground_map: TileMap


func setup(world_entities_layer: Node2D, world_ground_map: TileMap) -> void:
	entities_layer = world_entities_layer
	ground_map = world_ground_map


func create_great_wall(tile: Vector2i) -> void:
	_clear_decor_patch(tile, 4, 3)

	var tex_path = "res://assets/mockups/landmark_great_wall.png"
	if not ResourceLoader.exists(tex_path):
		return

	var root := Node2D.new()
	root.name = "GreatWallEntrance"
	root.position = _tile_to_body_position(tile)
	root.z_index = 2
	entities_layer.add_child(root)

	var tex = load(tex_path)
	var sprite = Sprite2D.new()
	sprite.name = "GreatWallLandmark"
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex_h = tex.get_height()
	sprite.offset = Vector2(0, -tex_h * 0.5)
	sprite.scale = Vector2(0.38, 0.38)
	root.add_child(sprite)

	_add_landmark_entry_trigger(root, "GreatWallDoorLeft", Vector2(-82, -40), Vector2(92, 86), "red_command", "EntryMarker", "Wall Gate")
	_add_landmark_entry_trigger(root, "GreatWallDoorCenter", Vector2(2, -156), Vector2(72, 62), "red_command", "EntryMarker", "Wall Gate")
	_add_landmark_entry_trigger(root, "GreatWallDoorRight", Vector2(76, -106), Vector2(92, 96), "red_command", "EntryMarker", "Wall Gate")


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
