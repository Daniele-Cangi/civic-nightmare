extends Node

const DOORWAY_SCRIPT = preload("res://scripts/doorway.gd")
const LAYER_DECOR := 1
const NORTHERN_WALL_PATH := "res://assets/landmarks/northern_great_wall_v1.png"
const LEGACY_GREAT_WALL_PATH := "res://assets/mockups/landmark_great_wall.png"
const INFERENCE_REACTOR_PATH := "res://assets/landmarks/inference_reactor_demo_v1.png"
const LEGACY_NUCLEAR_PLANT_PATH := "res://assets/mockups/landmark_nuclear_plant.png"
const PYONGYANG_ARTILLERY_PATH := "res://assets/landmarks/pyongyang_broadcast_artillery_v1.png"
const LEGACY_PYONGYANG_PATH := "res://assets/mockups/landmark_pyongyang.png"
const SOUTHERN_ANNEX_GATE_PATH := "res://assets/landmarks/southern_annex_gate_v1.png"
const WESTERN_AID_GATE_PATH := "res://assets/landmarks/western_aid_gate_v1.png"
const WESTERN_AID_BARRIER_PATH := "res://assets/landmarks/western_aid_gate_barrier_v1.png"
const LEGACY_BUNKER_PATH := "res://assets/mockups/landmark_bunker.png"
const NORTHERN_WALL_HEIGHT := 448.0
const NORTHERN_WALL_FRONT_Y := 403.0
const NORTHERN_GATE_OVERHANG := 48.0
const NORTHERN_GATE_HALF_WIDTH := 64.0
const WESTERN_AID_GATE_SIZE := Vector2(576.0, 720.0)
const WESTERN_AID_GATE_SCALE := 0.62
const WESTERN_AID_GATE_SPRITE_OFFSET := Vector2(80.0, -27.0)
const WESTERN_AID_GATE_PASSAGE_OFFSET := Vector2(200.0, 0.0)

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
	if not ResourceLoader.exists(INFERENCE_REACTOR_PATH):
		_create_legacy_nuclear_plant(tile)
		return
	var texture := load(INFERENCE_REACTOR_PATH) as Texture2D
	if texture == null or texture.get_size() != Vector2(480.0, 320.0):
		_create_legacy_nuclear_plant(tile)
		return

	var root := Node2D.new()
	root.name = "NuclearPlantEntrance"
	root.position = _tile_to_body_position(tile)
	root.z_index = 2
	root.add_to_group("optional_world_landmark")
	root.set_meta("asset_path", INFERENCE_REACTOR_PATH)
	entities_layer.add_child(root)

	var plant := Sprite2D.new()
	plant.name = "NuclearPlantLandmark"
	plant.texture = texture
	plant.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	plant.position = Vector2(0.0, -160.0)
	root.add_child(plant)

	var collision := StaticBody2D.new()
	collision.name = "InferenceReactorCollision"
	root.add_child(collision)
	# The upper mass prevents walking through the machinery. Two lower wings
	# follow the facade while leaving the pristine keynote doorway accessible.
	_add_collision_rect(collision, "UpperInfrastructure", Vector2(0.0, -174.0), Vector2(444.0, 158.0))
	_add_collision_rect(collision, "WestServiceWing", Vector2(-151.0, -55.0), Vector2(178.0, 80.0))
	_add_collision_rect(collision, "EastCoolingWing", Vector2(151.0, -55.0), Vector2(178.0, 80.0))

	_add_landmark_entry_trigger(root, "NeuralCoreDoor", Vector2(0.0, -42.0), Vector2(92.0, 54.0), "neural_core", "EntryMarker", "Demonstration Entrance")


func create_southern_annex_gate(tile: Vector2i) -> void:
	if not ResourceLoader.exists(SOUTHERN_ANNEX_GATE_PATH):
		return
	var texture := load(SOUTHERN_ANNEX_GATE_PATH) as Texture2D
	if texture == null or texture.get_size() != Vector2(576.0, 288.0):
		return

	var root := Node2D.new()
	root.name = "SouthernAnnexGate"
	# The district plate is centered on x=0. Anchor the gate to that axis and
	# let its lower edge meet the authored southern boundary.
	root.position = Vector2(0.0, float(tile.y * 32))
	root.z_index = 2
	root.set_meta("asset_path", SOUTHERN_ANNEX_GATE_PATH)
	entities_layer.add_child(root)

	var sprite := Sprite2D.new()
	sprite.name = "SouthernAnnexGateLandmark"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = Vector2(0.0, -144.0)
	root.add_child(sprite)

	var collision := StaticBody2D.new()
	collision.name = "SouthernAnnexGateCollision"
	root.add_child(collision)
	_add_collision_rect(collision, "WestCheckpoint", Vector2(-202.0, -72.0), Vector2(172.0, 136.0))
	_add_collision_rect(collision, "EastCheckpoint", Vector2(202.0, -72.0), Vector2(172.0, 136.0))

	_add_landmark_entry_trigger(
		root,
		"SouthernAnnexPassage",
		Vector2(0.0, -55.0),
		Vector2(132.0, 72.0),
		"southern_annex",
		"NorthEntry",
		"Southern Administrative Annex"
	)


func _create_legacy_nuclear_plant(tile: Vector2i) -> void:
	if not ResourceLoader.exists(LEGACY_NUCLEAR_PLANT_PATH):
		return

	var root := Node2D.new()
	root.name = "NuclearPlantEntrance"
	root.position = _tile_to_body_position(tile)
	root.z_index = 2
	entities_layer.add_child(root)

	var texture := load(LEGACY_NUCLEAR_PLANT_PATH) as Texture2D
	var plant := Sprite2D.new()
	plant.name = "NuclearPlantLandmark"
	plant.texture = texture
	plant.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plant.offset = Vector2(0, -texture.get_height() * 0.5)
	plant.scale = Vector2(0.38, 0.38)
	root.add_child(plant)

	_add_landmark_entry_trigger(root, "NeuralCoreDoorLeft", Vector2(-76, -18), Vector2(92, 88), "neural_core", "EntryMarker", "Containment Door")
	_add_landmark_entry_trigger(root, "NeuralCoreDoorCenter", Vector2(6, -28), Vector2(94, 102), "neural_core", "EntryMarker", "Containment Door")
	_add_landmark_entry_trigger(root, "NeuralCoreDoorRight", Vector2(92, 12), Vector2(84, 82), "neural_core", "EntryMarker", "Containment Door")


func create_hidden_bunker(world_bounds: Rect2, approach_tile: Vector2i) -> void:
	_clear_decor_patch(approach_tile, 10, 5)
	if not ResourceLoader.exists(WESTERN_AID_GATE_PATH):
		_create_legacy_hidden_bunker(approach_tile)
		return
	var texture := load(WESTERN_AID_GATE_PATH) as Texture2D
	if texture == null or texture.get_size() != WESTERN_AID_GATE_SIZE:
		_create_legacy_hidden_bunker(approach_tile)
		return

	var root := Node2D.new()
	root.name = "HiddenBunkerEntrance"
	# The authored opening begins 160 px into the cutout. Offsetting the scaled
	# sprite by 80 px makes that opening meet the western boundary exactly, while the
	# checkpoint's fortification and donor set project into the playable map.
	root.position = Vector2(world_bounds.position.x, _tile_to_body_position(approach_tile).y)
	root.z_index = 2
	root.add_to_group("classified_world_landmark")
	root.set_meta("asset_path", WESTERN_AID_GATE_PATH)
	root.set_meta("passage_world_position", root.position + WESTERN_AID_GATE_PASSAGE_OFFSET)
	entities_layer.add_child(root)

	var sprite := Sprite2D.new()
	sprite.name = "WesternAidGateLandmark"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = WESTERN_AID_GATE_SPRITE_OFFSET
	sprite.scale = Vector2.ONE * WESTERN_AID_GATE_SCALE
	root.add_child(sprite)

	var collision := StaticBody2D.new()
	collision.name = "WesternAidGateCollision"
	root.add_child(collision)
	# The gate is a vertical border structure around a horizontal road. Its two
	# collision masses deliberately leave the authored drive-through unobstructed.
	_add_collision_rect(collision, "WartimeFortification", Vector2(130.0, -135.0), Vector2(260.0, 180.0))
	_add_collision_rect(collision, "DonorMediaCheckpoint", Vector2(125.0, 140.0), Vector2(250.0, 150.0))

	_add_aid_gate_state(root)
	_add_landmark_entry_trigger(
		root,
		"HiddenBunkerDoor",
		WESTERN_AID_GATE_PASSAGE_OFFSET,
		Vector2(104.0, 76.0),
		"mountain_bunker",
		"EntryMarker",
		"Aid Clearance"
	)
	set_hidden_bunker_gate_cleared(false)


func set_hidden_bunker_gate_cleared(is_cleared: bool) -> void:
	if entities_layer == null:
		return
	var root := entities_layer.get_node_or_null("HiddenBunkerEntrance") as Node2D
	if root == null or not root.is_in_group("classified_world_landmark"):
		return
	root.set_meta("clearance_granted", is_cleared)
	var shutter := root.get_node_or_null("AidGateShutter") as Node2D
	if shutter:
		shutter.visible = not is_cleared
	var shutter_shape := root.get_node_or_null("AidGateShutterCollision/CollisionShape2D") as CollisionShape2D
	if shutter_shape:
		shutter_shape.disabled = is_cleared
	var cleared_beacon := root.get_node_or_null("AidGateClearedBeacon") as Polygon2D
	if cleared_beacon:
		cleared_beacon.visible = is_cleared


func _add_aid_gate_state(root: Node2D) -> void:
	var shutter := Node2D.new()
	shutter.name = "AidGateShutter"
	shutter.position = Vector2(110.0, 0.0)
	shutter.z_index = 3
	root.add_child(shutter)

	if ResourceLoader.exists(WESTERN_AID_BARRIER_PATH):
		var barrier_texture := load(WESTERN_AID_BARRIER_PATH) as Texture2D
		if barrier_texture and barrier_texture.get_size() == Vector2(32.0, 128.0):
			var barrier := Sprite2D.new()
			barrier.name = "AidGateBarrierProp"
			barrier.texture = barrier_texture
			barrier.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			shutter.add_child(barrier)
	if shutter.get_child_count() == 0:
		var fallback_barrier := Polygon2D.new()
		fallback_barrier.name = "FallbackArmoredBarrier"
		fallback_barrier.color = Color("8f302d")
		fallback_barrier.polygon = PackedVector2Array([
			Vector2(-9.0, -42.0),
			Vector2(9.0, -38.0),
			Vector2(9.0, 38.0),
			Vector2(-9.0, 42.0)
		])
		shutter.add_child(fallback_barrier)

	var shutter_collision := StaticBody2D.new()
	shutter_collision.name = "AidGateShutterCollision"
	shutter_collision.position = shutter.position
	root.add_child(shutter_collision)
	_add_collision_rect(shutter_collision, "CollisionShape2D", Vector2.ZERO, Vector2(18.0, 84.0))

	var cleared_beacon := Polygon2D.new()
	cleared_beacon.name = "AidGateClearedBeacon"
	cleared_beacon.position = Vector2(110.0, -47.0)
	cleared_beacon.color = Color("71e7d5")
	cleared_beacon.polygon = _regular_polygon(4.0, 8)
	cleared_beacon.z_index = 4
	cleared_beacon.visible = false
	root.add_child(cleared_beacon)


func _regular_polygon(radius: float, sides: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(sides):
		var angle := TAU * float(point_index) / float(sides)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _create_legacy_hidden_bunker(tile: Vector2i) -> void:
	if not ResourceLoader.exists(LEGACY_BUNKER_PATH):
		return
	var root := Node2D.new()
	root.name = "HiddenBunkerEntrance"
	root.position = _tile_to_body_position(tile) + Vector2(12.0, 0.0)
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

	var mountain := Sprite2D.new()
	mountain.name = "LegacyBunkerLandmark"
	mountain.texture = load(LEGACY_BUNKER_PATH)
	mountain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mountain.scale = Vector2(0.42, 0.42)
	mountain.offset = Vector2(0, -10)
	root.add_child(mountain)

	_add_landmark_entry_trigger(root, "HiddenBunkerDoor", Vector2(0, 42), Vector2(84, 44), "mountain_bunker", "EntryMarker", "Bunker Hatch")


func create_pyongyang(tile: Vector2i) -> void:
	_clear_decor_patch(tile, 4, 3)
	if not ResourceLoader.exists(PYONGYANG_ARTILLERY_PATH):
		_create_legacy_pyongyang(tile)
		return
	var texture := load(PYONGYANG_ARTILLERY_PATH) as Texture2D
	if texture == null or texture.get_size() != Vector2(448.0, 352.0):
		_create_legacy_pyongyang(tile)
		return

	var root := Node2D.new()
	root.name = "PyongyangEntrance"
	root.position = _tile_to_body_position(tile)
	root.z_index = 2
	root.add_to_group("optional_world_landmark")
	root.set_meta("asset_path", PYONGYANG_ARTILLERY_PATH)
	entities_layer.add_child(root)

	var sprite := Sprite2D.new()
	sprite.name = "PyongyangLandmark"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = Vector2(0.0, -176.0)
	root.add_child(sprite)

	var collision := StaticBody2D.new()
	collision.name = "BroadcastArtilleryCollision"
	root.add_child(collision)
	# The gun carriage is solid above the access hatch. Cameras and parade
	# scenery form two lower wings with a deliberate centre passage.
	_add_collision_rect(collision, "ArtilleryCarriage", Vector2(0.0, -174.0), Vector2(330.0, 168.0))
	_add_collision_rect(collision, "WestBroadcastWing", Vector2(-151.0, -51.0), Vector2(142.0, 74.0))
	_add_collision_rect(collision, "EastBroadcastWing", Vector2(151.0, -51.0), Vector2(142.0, 74.0))

	_add_landmark_entry_trigger(root, "PyongyangCannonDoor", Vector2(0.0, -35.0), Vector2(86.0, 48.0), "pyongyang_command", "EntryMarker", "Broadcast Artillery Hatch")


func _create_legacy_pyongyang(tile: Vector2i) -> void:
	if not ResourceLoader.exists(LEGACY_PYONGYANG_PATH):
		return

	var root := Node2D.new()
	root.name = "PyongyangEntrance"
	root.position = _tile_to_body_position(tile)
	root.z_index = 2
	entities_layer.add_child(root)

	var texture := load(LEGACY_PYONGYANG_PATH) as Texture2D
	var sprite := Sprite2D.new()
	sprite.name = "PyongyangLandmark"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = Vector2(0, -texture.get_height() * 0.45)
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
