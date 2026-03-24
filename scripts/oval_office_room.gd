extends Node2D

const NPC_SCENE = preload("res://scenes/npc.tscn")
const DOORWAY_SCRIPT = preload("res://scripts/doorway.gd")
const WORLD_TILES = preload("res://assets/tiles/world_tiles.png")
const PROP_BOOK = preload("res://assets/packs/civic_nightmare/items_props/ninja/Object/Book.png")
const PROP_HOURGLASS = preload("res://assets/packs/civic_nightmare/items_props/ninja/Object/Hourglass.png")
const PROP_BAG = preload("res://assets/packs/civic_nightmare/items_props/ninja/Object/Bag.png")
const PROP_CRATE = preload("res://assets/packs/civic_nightmare/items_props/ninja/Object/CrateEmpty.png")
const PROP_GOLD_CUP = preload("res://assets/packs/civic_nightmare/items_props/ninja/Treasure/GoldCup.png")

const SRC_PROC := 0
const SRC_INTERIOR_FLOOR := 1

const LAYER_GROUND := 0
const LAYER_ACCENT := 1
const LAYER_STRUCT := 2

const TILE_MARBLE_WALL := Vector2i(2, 2)
const TILE_WINDOW := Vector2i(6, 2)
const TILE_DOOR := Vector2i(7, 2)
const TILE_DESK_WOOD := Vector2i(3, 3)
const TILE_BOOKSHELF := Vector2i(2, 4)
const TILE_FLAG := Vector2i(4, 4)
const TILE_FILE_CABINET := Vector2i(5, 4)
const TILE_PLANT := Vector2i(6, 4)
const TILE_CLOCK := Vector2i(7, 4)
const TILE_COLUMN := Vector2i(6, 6)
const TILE_GLOBE := Vector2i(7, 6)

const IF_OFFICE := Vector2i(4, 4)
const IF_PALACE := Vector2i(14, 4)

const ROOM_LEFT := -9
const ROOM_RIGHT := 9
const ROOM_TOP := -8
const ROOM_BOTTOM := 8

const ENTRY_POS := Vector2(0, 168)
const EXIT_POS := Vector2(0, 228)
const TRUMP_POS := Vector2(0, 42)
const ITEM_SCALE := Vector2(2.0, 2.0)

@onready var room_map: TileMap = $RoomMap
@onready var entities: Node2D = $Entities
@onready var interactables: Node2D = $Interactables
@onready var markers: Node2D = $Markers

var decor_root: Node2D
var foreground_root: Node2D
var collision_root: Node2D

func _ready() -> void:
	_setup_tileset_sources()
	_build_room()
	_spawn_trump()
	_create_exit_door()
	_create_lighting()
	_set_markers()
	set_room_active(false)

func set_room_active(active: bool) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func get_spawn_position(marker_name: String) -> Vector2:
	var marker := markers.get_node_or_null(marker_name) as Marker2D
	if marker:
		return marker.global_position
	return global_position + ENTRY_POS

func get_entity_container() -> Node2D:
	return entities

func _setup_tileset_sources() -> void:
	if room_map.tile_set == null:
		room_map.tile_set = TileSet.new()
	var tileset := room_map.tile_set

	while room_map.get_layers_count() <= LAYER_STRUCT:
		room_map.add_layer(-1)
	room_map.set_layer_z_index(LAYER_GROUND, 0)
	room_map.set_layer_z_index(LAYER_ACCENT, 1)
	room_map.set_layer_z_index(LAYER_STRUCT, 2)

	_add_tileset_source(tileset, SRC_PROC, "res://assets/tiles/world_tiles.png")
	_add_tileset_source(tileset, SRC_INTERIOR_FLOOR, "res://assets/tiles/interior_floor_32.png")

func _add_tileset_source(tileset: TileSet, source_id: int, path: String) -> void:
	if tileset.has_source(source_id) or not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	if not tex:
		return
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(32, 32)
	var cols := int(tex.get_width() / 32)
	var rows := int(tex.get_height() / 32)
	for ty in range(rows):
		for tx in range(cols):
			source.create_tile(Vector2i(tx, ty))
	tileset.add_source(source, source_id)

func _build_room() -> void:
	room_map.clear()

	if decor_root:
		decor_root.queue_free()
	if foreground_root:
		foreground_root.queue_free()
	if collision_root:
		collision_root.queue_free()

	decor_root = Node2D.new()
	decor_root.name = "DecorRoot"
	add_child(decor_root)
	move_child(decor_root, 1)

	foreground_root = Node2D.new()
	foreground_root.name = "ForegroundRoot"
	add_child(foreground_root)
	move_child(foreground_root, get_child_count() - 1)

	collision_root = Node2D.new()
	collision_root.name = "CollisionRoot"
	add_child(collision_root)
	move_child(collision_root, 2)

	for x in range(ROOM_LEFT, ROOM_RIGHT + 1):
		for y in range(ROOM_TOP, ROOM_BOTTOM + 1):
			room_map.set_cell(LAYER_GROUND, Vector2i(x, y), SRC_INTERIOR_FLOOR, IF_OFFICE)

	for x in range(-5, 6):
		for y in range(ROOM_TOP + 1, ROOM_TOP + 4):
			room_map.set_cell(LAYER_ACCENT, Vector2i(x, y), SRC_INTERIOR_FLOOR, IF_PALACE)

	for x in range(-3, 4):
		for y in range(-1, 3):
			room_map.set_cell(LAYER_ACCENT, Vector2i(x, y), SRC_INTERIOR_FLOOR, IF_PALACE)

	for x in range(ROOM_LEFT, ROOM_RIGHT + 1):
		var top_pos := Vector2i(x, ROOM_TOP)
		var top_tile := TILE_WINDOW if x in [-4, 0, 4] else TILE_MARBLE_WALL
		room_map.set_cell(LAYER_STRUCT, top_pos, SRC_PROC, top_tile)

	for y in range(ROOM_TOP + 1, ROOM_BOTTOM):
		room_map.set_cell(LAYER_STRUCT, Vector2i(ROOM_LEFT, y), SRC_PROC, TILE_MARBLE_WALL)
		room_map.set_cell(LAYER_STRUCT, Vector2i(ROOM_RIGHT, y), SRC_PROC, TILE_MARBLE_WALL)

	for x in range(ROOM_LEFT, ROOM_RIGHT + 1):
		if abs(x) <= 1:
			continue
		room_map.set_cell(LAYER_STRUCT, Vector2i(x, ROOM_BOTTOM), SRC_PROC, TILE_MARBLE_WALL)
	room_map.set_cell(LAYER_STRUCT, Vector2i(0, ROOM_BOTTOM), SRC_PROC, TILE_DOOR)

	room_map.set_cell(LAYER_STRUCT, Vector2i(-7, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
	room_map.set_cell(LAYER_STRUCT, Vector2i(-6, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
	room_map.set_cell(LAYER_STRUCT, Vector2i(6, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
	room_map.set_cell(LAYER_STRUCT, Vector2i(7, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
	room_map.set_cell(LAYER_STRUCT, Vector2i(0, ROOM_TOP + 2), SRC_PROC, TILE_CLOCK)

	_build_wall_panels()
	_build_curtains()
	_build_rug()
	_build_props()
	_build_collisions()
	_build_foreground()

func _build_wall_panels() -> void:
	_add_rect_polygon(decor_root, Rect2(Vector2(-224, -166), Vector2(96, 74)), Color(0.14, 0.1, 0.08, 0.18))
	_add_rect_polygon(decor_root, Rect2(Vector2(128, -166), Vector2(96, 74)), Color(0.14, 0.1, 0.08, 0.18))
	_add_rect_polygon(decor_root, Rect2(Vector2(-224, 42), Vector2(96, 88)), Color(0.14, 0.1, 0.08, 0.14))
	_add_rect_polygon(decor_root, Rect2(Vector2(128, 42), Vector2(96, 88)), Color(0.14, 0.1, 0.08, 0.14))
	_add_rect_polygon(decor_root, Rect2(Vector2(-160, -16), Vector2(320, 8)), Color(0.24, 0.18, 0.12, 0.22))

func _build_curtains() -> void:
	for window_x in [-128.0, 0.0, 128.0]:
		_add_rect_polygon(decor_root, Rect2(Vector2(window_x - 42, -234), Vector2(18, 110)), Color(0.5, 0.12, 0.08, 0.92))
		_add_rect_polygon(decor_root, Rect2(Vector2(window_x + 24, -234), Vector2(18, 110)), Color(0.5, 0.12, 0.08, 0.92))
		_add_rect_polygon(decor_root, Rect2(Vector2(window_x - 44, -130), Vector2(88, 6)), Color(0.76, 0.63, 0.34, 0.85))

func _build_rug() -> void:
	_add_ellipse_polygon(decor_root, Vector2(0, 48), Vector2(192, 124), Color(0.76, 0.64, 0.34, 0.88), 32)
	_add_ellipse_polygon(decor_root, Vector2(0, 48), Vector2(172, 106), Color(0.1, 0.17, 0.31, 0.92), 32)
	_add_ellipse_polygon(decor_root, Vector2(0, 48), Vector2(88, 52), Color(0.76, 0.64, 0.34, 0.2), 32)

func _build_props() -> void:
	_create_shadow(Vector2(0, -72), Vector2(126, 16), Color(0, 0, 0, 0.14))
	_create_prop(
		"Desk",
		Vector2(0, -78),
		[
			{"coords": TILE_DESK_WOOD, "offset": Vector2(-48, -32)},
			{"coords": TILE_DESK_WOOD, "offset": Vector2(-16, -32)},
			{"coords": TILE_DESK_WOOD, "offset": Vector2(16, -32)}
		],
		Vector2(94, 18),
		Vector2(0, -9)
	)
	_add_loose_sprite(entities.get_node("Desk"), PROP_BOOK, Vector2(-20, -34))
	_add_loose_sprite(entities.get_node("Desk"), PROP_HOURGLASS, Vector2(8, -34))
	_add_loose_sprite(entities.get_node("Desk"), PROP_GOLD_CUP, Vector2(34, -34), Vector2(2.2, 2.2))

	_create_console("NorthLeftConsole", Vector2(-146, -102), 2, true)
	_create_console("NorthRightConsole", Vector2(146, -102), 2, false)
	_add_loose_sprite(entities.get_node("NorthLeftConsole"), PROP_BOOK, Vector2(-8, -36))
	_add_loose_sprite(entities.get_node("NorthRightConsole"), PROP_GOLD_CUP, Vector2(2, -38), Vector2(2.2, 2.2))

	_create_shadow(Vector2(-208, -18), Vector2(28, 20), Color(0, 0, 0, 0.1))
	_create_prop(
		"LeftBookcase",
		Vector2(-214, -22),
		[
			{"coords": TILE_BOOKSHELF, "offset": Vector2(-16, -32)}
		],
		Vector2(22, 18),
		Vector2(0, -8)
	)
	_create_shadow(Vector2(208, -18), Vector2(28, 20), Color(0, 0, 0, 0.1))
	_create_prop(
		"RightCabinet",
		Vector2(214, -22),
		[
			{"coords": TILE_FILE_CABINET, "offset": Vector2(-16, -32)}
		],
		Vector2(22, 18),
		Vector2(0, -8)
	)
	_create_prop(
		"LeftFlag",
		Vector2(-168, -110),
		[
			{"coords": TILE_FLAG, "offset": Vector2(-16, -32)}
		],
		Vector2(16, 22),
		Vector2(0, -11)
	)
	_create_prop(
		"RightFlag",
		Vector2(168, -110),
		[
			{"coords": TILE_FLAG, "offset": Vector2(-16, -32)}
		],
		Vector2(16, 22),
		Vector2(0, -11)
	)
	_create_prop(
		"LeftPlant",
		Vector2(-206, 120),
		[
			{"coords": TILE_PLANT, "offset": Vector2(-16, -32)}
		],
		Vector2(20, 18),
		Vector2(0, -8)
	)
	_create_prop(
		"RightPlant",
		Vector2(206, 120),
		[
			{"coords": TILE_PLANT, "offset": Vector2(-16, -32)}
		],
		Vector2(20, 18),
		Vector2(0, -8)
	)
	_create_prop(
		"RightGlobe",
		Vector2(176, 42),
		[
			{"coords": TILE_GLOBE, "offset": Vector2(-16, -32)}
		],
		Vector2(18, 14),
		Vector2(0, -7)
	)
	_create_lounge_chair("WestChair", Vector2(-186, 84), false)
	_create_lounge_chair("EastChair", Vector2(186, 84), true)
	_create_coffee_table("WestTable", Vector2(-124, 98), true)
	_create_coffee_table("EastTable", Vector2(124, 98), false)
	_create_display_pedestal("WestPedestal", Vector2(-136, 16), PROP_GOLD_CUP, Vector2(2.2, 2.2))
	_create_display_pedestal("EastPedestal", Vector2(136, 16), PROP_BOOK, ITEM_SCALE)
	_create_console("SouthLeftConsole", Vector2(-154, 148), 2, true)
	_create_console("SouthRightConsole", Vector2(154, 148), 2, false)
	_add_loose_sprite(entities.get_node("SouthLeftConsole"), PROP_BAG, Vector2(-10, -36))
	_add_loose_sprite(entities.get_node("SouthLeftConsole"), PROP_BOOK, Vector2(10, -34))
	_add_loose_sprite(entities.get_node("SouthRightConsole"), PROP_HOURGLASS, Vector2(-10, -34))
	_add_loose_sprite(entities.get_node("SouthRightConsole"), PROP_BOOK, Vector2(10, -34))

func _build_collisions() -> void:
	_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2((ROOM_RIGHT - ROOM_LEFT + 1) * 32, 64)))
	_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2(32, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)))
	_create_barrier(Rect2(Vector2(ROOM_RIGHT * 32, ROOM_TOP * 32), Vector2(32, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)))
	_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_BOTTOM * 32), Vector2(240, 32)))
	_create_barrier(Rect2(Vector2(112, ROOM_BOTTOM * 32), Vector2(208, 32)))

func _build_foreground() -> void:
	_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2((ROOM_RIGHT - ROOM_LEFT + 1) * 32, 28)), Color(0, 0, 0, 0.18))
	_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_LEFT * 32, ROOM_BOTTOM * 32 - 14), Vector2((ROOM_RIGHT - ROOM_LEFT + 1) * 32, 46)), Color(0, 0, 0, 0.1))
	_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2(34, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)), Color(0.02, 0.01, 0.01, 0.18))
	_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_RIGHT * 32 - 2, ROOM_TOP * 32), Vector2(34, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)), Color(0.02, 0.01, 0.01, 0.18))

func _create_prop(name: String, origin: Vector2, tiles: Array, collision_size: Vector2, collision_offset: Vector2) -> void:
	var body = StaticBody2D.new()
	body.name = name
	body.position = origin

	for tile_data in tiles:
		var sprite = Sprite2D.new()
		sprite.texture = WORLD_TILES
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2(tile_data["coords"] * 32), Vector2(32, 32))
		sprite.position = tile_data["offset"]
		body.add_child(sprite)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = collision_size
	col.shape = shape
	col.position = collision_offset
	body.add_child(col)
	entities.add_child(body)

func _create_console(name: String, origin: Vector2, width_tiles: int, add_books: bool) -> void:
	var body = StaticBody2D.new()
	body.name = name
	body.position = origin
	_add_shadow_to_node(body, Rect2(Vector2(-42, 2), Vector2(84, 16)), Color(0, 0, 0, 0.12))

	for i in range(width_tiles):
		var sprite = Sprite2D.new()
		sprite.texture = WORLD_TILES
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2(TILE_DESK_WOOD * 32), Vector2(32, 32))
		sprite.position = Vector2(-width_tiles * 16 + i * 32, -32)
		body.add_child(sprite)

	if add_books:
		_add_loose_sprite(body, PROP_BOOK, Vector2(-12, -34))
		_add_loose_sprite(body, PROP_BOOK, Vector2(12, -30), Vector2(1.7, 1.7))

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(62, 12)
	col.shape = shape
	col.position = Vector2(0, -6)
	body.add_child(col)
	entities.add_child(body)

func _create_lounge_chair(name: String, origin: Vector2, faces_left: bool) -> void:
	var body = StaticBody2D.new()
	body.name = name
	body.position = origin
	_add_shadow_to_node(body, Rect2(Vector2(-28, 6), Vector2(56, 14)), Color(0, 0, 0, 0.1))

	var seat = Polygon2D.new()
	seat.color = Color(0.24, 0.13, 0.1, 0.96)
	seat.polygon = PackedVector2Array([
		Vector2(-22, -10),
		Vector2(22, -10),
		Vector2(26, 10),
		Vector2(-26, 10)
	])
	body.add_child(seat)

	var back = Polygon2D.new()
	back.color = Color(0.19, 0.08, 0.06, 0.98)
	var dir := -1.0 if faces_left else 1.0
	back.polygon = PackedVector2Array([
		Vector2(-24 * dir, -28),
		Vector2(18 * dir, -24),
		Vector2(22 * dir, -8),
		Vector2(-20 * dir, -10)
	])
	body.add_child(back)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(42, 18)
	col.shape = shape
	col.position = Vector2(0, -2)
	body.add_child(col)
	entities.add_child(body)

func _create_coffee_table(name: String, origin: Vector2, add_bag: bool) -> void:
	var body = StaticBody2D.new()
	body.name = name
	body.position = origin
	_add_shadow_to_node(body, Rect2(Vector2(-20, 2), Vector2(40, 12)), Color(0, 0, 0, 0.08))

	var crate = Sprite2D.new()
	crate.texture = PROP_CRATE
	crate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	crate.centered = false
	crate.scale = ITEM_SCALE
	crate.position = Vector2(-16, -22)
	body.add_child(crate)

	_add_loose_sprite(body, PROP_BOOK, Vector2(-10, -26), Vector2(1.7, 1.7))
	if add_bag:
		_add_loose_sprite(body, PROP_BAG, Vector2(6, -24), Vector2(1.6, 1.6))
	else:
		_add_loose_sprite(body, PROP_HOURGLASS, Vector2(8, -24), Vector2(1.8, 1.8))

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(28, 10)
	col.shape = shape
	col.position = Vector2(0, -2)
	body.add_child(col)
	entities.add_child(body)

func _create_display_pedestal(name: String, origin: Vector2, top_texture: Texture2D, top_scale: Vector2) -> void:
	var body = StaticBody2D.new()
	body.name = name
	body.position = origin
	_add_shadow_to_node(body, Rect2(Vector2(-18, 4), Vector2(36, 12)), Color(0, 0, 0, 0.08))

	var base = Polygon2D.new()
	base.color = Color(0.73, 0.72, 0.7, 0.96)
	base.polygon = PackedVector2Array([
		Vector2(-16, -28),
		Vector2(16, -28),
		Vector2(20, 8),
		Vector2(-20, 8)
	])
	body.add_child(base)

	var trim = Polygon2D.new()
	trim.color = Color(0.86, 0.82, 0.68, 0.95)
	trim.polygon = PackedVector2Array([
		Vector2(-18, -30),
		Vector2(18, -30),
		Vector2(16, -24),
		Vector2(-16, -24)
	])
	body.add_child(trim)

	_add_loose_sprite(body, top_texture, Vector2(0, -42), top_scale)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 14)
	col.shape = shape
	col.position = Vector2(0, 0)
	body.add_child(col)
	entities.add_child(body)

func _add_loose_sprite(parent: Node, texture: Texture2D, offset: Vector2, scale: Vector2 = ITEM_SCALE) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = scale
	sprite.position = offset
	parent.add_child(sprite)

func _create_shadow(pos: Vector2, size: Vector2, color: Color) -> void:
	_add_rect_polygon(decor_root, Rect2(pos - size * 0.5, size), color)

func _add_shadow_to_node(parent: Node, rect: Rect2, color: Color) -> void:
	var shadow = Polygon2D.new()
	shadow.color = color
	shadow.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y)
	])
	parent.add_child(shadow)

func _spawn_trump() -> void:
	var trump = NPC_SCENE.instantiate()
	trump.name = "TrumpInterior"
	trump.character_id = "donald_trump"
	trump.character_name = "Donald Trump"
	trump.position = TRUMP_POS
	entities.add_child(trump)

func _create_exit_door() -> void:
	var door := Area2D.new()
	door.name = "ExitDoor"
	door.collision_layer = 0
	door.collision_mask = 1
	door.monitoring = true
	door.monitorable = true
	door.position = EXIT_POS
	door.set_script(DOORWAY_SCRIPT)
	door.set("destination", "world")
	door.set("spawn_marker", "oval_office_exterior")
	door.set("prompt_name", "Exit Oval Office")

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(120, 36)
	col.shape = shape
	door.add_child(col)
	interactables.add_child(door)

func _create_lighting() -> void:
	_add_point_light(Vector2(-128, -182), Color(0.72, 0.84, 1.0), 3.0, 0.28)
	_add_point_light(Vector2(128, -182), Color(0.72, 0.84, 1.0), 3.0, 0.28)
	_add_point_light(Vector2(0, -18), Color(1.0, 0.78, 0.52), 2.5, 0.58)
	_add_point_light(Vector2(0, 104), Color(0.52, 0.46, 0.36), 1.9, 0.18)

func _add_point_light(local_pos: Vector2, color: Color, scale_factor: float, energy: float) -> void:
	var light = PointLight2D.new()
	light.position = local_pos
	light.color = color
	light.energy = energy
	light.texture_scale = scale_factor

	var tex = GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	tex.gradient = grad
	light.texture = tex

	add_child(light)

func _set_markers() -> void:
	var entry := markers.get_node("EntryMarker") as Marker2D
	entry.position = ENTRY_POS

func _create_barrier(rect: Rect2) -> void:
	var body = StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	body.add_child(col)
	collision_root.add_child(body)

func _add_rect_polygon(parent: Node2D, rect: Rect2, color: Color) -> void:
	var poly = Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y)
	])
	parent.add_child(poly)

func _add_ellipse_polygon(parent: Node2D, center: Vector2, size: Vector2, color: Color, segments: int) -> void:
	var poly = Polygon2D.new()
	poly.color = color
	poly.polygon = _make_ellipse(center, size, segments)
	parent.add_child(poly)

func _make_ellipse(center: Vector2, size: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var radius := size * 0.5
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points
