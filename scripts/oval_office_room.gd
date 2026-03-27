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

const TILE_WOOD := Vector2i(1, 0)
const TILE_METAL_FLOOR := Vector2i(1, 1)
const TILE_METAL_WALL := Vector2i(2, 1)
const TILE_VAULT_WALL := Vector2i(3, 1)
const TILE_KREMLIN_WALL := Vector2i(0, 2)
const TILE_MARBLE_WALL := Vector2i(2, 2)
const TILE_WINDOW := Vector2i(6, 2)
const TILE_DOOR := Vector2i(7, 2)
const TILE_DESK_WOOD := Vector2i(3, 3)
const TILE_DESK_METAL := Vector2i(0, 4)
const TILE_SERVER := Vector2i(1, 4)
const TILE_BOOKSHELF := Vector2i(2, 4)
const TILE_GOLD := Vector2i(3, 4)
const TILE_FILE_CABINET_WIDE := Vector2i(0, 4)
const TILE_FILE_CABINET := Vector2i(5, 4)
const TILE_PLANT := Vector2i(6, 4)
const TILE_CLOCK := Vector2i(7, 4)
const TILE_COLUMN := Vector2i(6, 6)
const TILE_GLOBE := Vector2i(7, 6)

const IF_OFFICE := Vector2i(4, 4)
const IF_PALACE := Vector2i(14, 4)
const IF_VAULT := Vector2i(15, 13)

const ROOM_LEFT := -9
const ROOM_RIGHT := 9
const ROOM_TOP := -8
const ROOM_BOTTOM := 8
const ITEM_SCALE := Vector2(2.0, 2.0)

@export var room_key := "oval_office"
@export var character_id := "donald_trump"
@export var character_name := "Donald Trump"

@onready var room_map: TileMap = $RoomMap
@onready var entities: Node2D = $Entities
@onready var interactables: Node2D = $Interactables
@onready var markers: Node2D = $Markers

var theme: Dictionary = {}
var decor_root: Node2D
var foreground_root: Node2D
var collision_root: Node2D

func _ready() -> void:
	theme = _theme_for_key(room_key)
	_setup_tileset_sources()
	_build_room()
	_spawn_character()
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
	return global_position + Vector2(theme.get("spawn_position", Vector2(0, 168)))

func get_entity_container() -> Node2D:
	return entities

func get_room_title() -> String:
	return str(theme.get("title", room_key.to_upper()))

func get_room_subtitle() -> String:
	return str(theme.get("subtitle", ""))

func _theme_for_key(key: String) -> Dictionary:
	match key:
		"spaceship":
			return {
				"title": "STARLINK COMMAND",
				"subtitle": "Orbital operations wing",
				"floor_source": SRC_PROC,
				"floor_tile": TILE_METAL_FLOOR,
				"accent_source": SRC_PROC,
				"accent_tile": TILE_METAL_FLOOR,
				"wall_tile": TILE_METAL_WALL,
				"window_positions": [-5, -1, 3],
				"curtains": false,
				"panel_color": Color(0.08, 0.12, 0.18, 0.36),
				"trim_color": Color(0.2, 0.44, 0.72, 0.28),
				"accent_color": Color(0.18, 0.42, 0.7, 0.18),
				"rug_outer": Color(0.12, 0.2, 0.28, 0.92),
				"rug_inner": Color(0.04, 0.09, 0.18, 0.96),
				"rug_glow": Color(0.26, 0.52, 0.88, 0.18),
				"spawn_position": Vector2(0, 168),
				"npc_position": Vector2(0, 24),
				"desk_position": Vector2(0, -86),
				"lights": [
					{"pos": Vector2(-132, -182), "color": Color(0.48, 0.76, 1.0), "scale": 3.1, "energy": 0.34},
					{"pos": Vector2(132, -182), "color": Color(0.48, 0.76, 1.0), "scale": 3.1, "energy": 0.34},
					{"pos": Vector2(0, -30), "color": Color(0.5, 0.8, 1.0), "scale": 2.4, "energy": 0.4},
					{"pos": Vector2(0, 110), "color": Color(0.18, 0.32, 0.46), "scale": 2.0, "energy": 0.14}
				]
			}
		"eu_palace":
			return {
				"title": "THE BERLAYMONT",
				"subtitle": "Administrative chamber",
				"floor_source": SRC_INTERIOR_FLOOR,
				"floor_tile": IF_PALACE,
				"accent_source": SRC_INTERIOR_FLOOR,
				"accent_tile": IF_OFFICE,
				"wall_tile": TILE_MARBLE_WALL,
				"window_positions": [-4, 0, 4],
				"curtains": true,
				"curtain_color": Color(0.08, 0.22, 0.56, 0.92),
				"panel_color": Color(0.18, 0.2, 0.28, 0.14),
				"trim_color": Color(0.76, 0.68, 0.38, 0.26),
				"accent_color": Color(0.14, 0.22, 0.44, 0.18),
				"rug_outer": Color(0.8, 0.72, 0.42, 0.86),
				"rug_inner": Color(0.1, 0.2, 0.52, 0.92),
				"rug_glow": Color(0.82, 0.76, 0.44, 0.18),
				"spawn_position": Vector2(0, 168),
				"npc_position": Vector2(0, 30),
				"desk_position": Vector2(0, -76),
				"lights": [
					{"pos": Vector2(-128, -182), "color": Color(0.82, 0.88, 1.0), "scale": 3.0, "energy": 0.28},
					{"pos": Vector2(128, -182), "color": Color(0.82, 0.88, 1.0), "scale": 3.0, "energy": 0.28},
					{"pos": Vector2(0, -12), "color": Color(1.0, 0.84, 0.56), "scale": 2.5, "energy": 0.48},
					{"pos": Vector2(0, 112), "color": Color(0.52, 0.46, 0.34), "scale": 2.0, "energy": 0.14}
				]
			}
		"kremlin":
			return {
				"title": "KREMLIN STUDY",
				"subtitle": "State intelligence office",
				"floor_source": SRC_PROC,
				"floor_tile": TILE_WOOD,
				"accent_source": SRC_PROC,
				"accent_tile": TILE_WOOD,
				"wall_tile": TILE_KREMLIN_WALL,
				"window_positions": [-4, 4],
				"curtains": true,
				"curtain_color": Color(0.44, 0.08, 0.08, 0.94),
				"panel_color": Color(0.18, 0.06, 0.06, 0.22),
				"trim_color": Color(0.48, 0.18, 0.14, 0.22),
				"accent_color": Color(0.3, 0.06, 0.06, 0.14),
				"rug_outer": Color(0.58, 0.16, 0.12, 0.88),
				"rug_inner": Color(0.22, 0.05, 0.05, 0.94),
				"rug_glow": Color(0.72, 0.22, 0.16, 0.16),
				"spawn_position": Vector2(0, 168),
				"npc_position": Vector2(0, 26),
				"desk_position": Vector2(0, -82),
				"lights": [
					{"pos": Vector2(-118, -184), "color": Color(0.92, 0.72, 0.56), "scale": 2.8, "energy": 0.24},
					{"pos": Vector2(118, -184), "color": Color(0.92, 0.72, 0.56), "scale": 2.8, "energy": 0.24},
					{"pos": Vector2(0, -18), "color": Color(0.94, 0.68, 0.42), "scale": 2.4, "energy": 0.42},
					{"pos": Vector2(0, 110), "color": Color(0.38, 0.18, 0.16), "scale": 2.0, "energy": 0.14}
				]
			}
		"vault":
			return {
				"title": "ECB VAULT",
				"subtitle": "Monetary control floor",
				"floor_source": SRC_INTERIOR_FLOOR,
				"floor_tile": IF_VAULT,
				"accent_source": SRC_PROC,
				"accent_tile": TILE_METAL_FLOOR,
				"wall_tile": TILE_VAULT_WALL,
				"window_positions": [],
				"curtains": false,
				"panel_color": Color(0.18, 0.16, 0.1, 0.2),
				"trim_color": Color(0.62, 0.56, 0.28, 0.22),
				"accent_color": Color(0.32, 0.28, 0.08, 0.16),
				"rug_outer": Color(0.56, 0.48, 0.18, 0.7),
				"rug_inner": Color(0.12, 0.14, 0.18, 0.94),
				"rug_glow": Color(0.82, 0.74, 0.26, 0.12),
				"spawn_position": Vector2(0, 168),
				"npc_position": Vector2(0, 20),
				"desk_position": Vector2(0, -82),
				"lights": [
					{"pos": Vector2(-112, -176), "color": Color(0.9, 0.78, 0.36), "scale": 2.8, "energy": 0.24},
					{"pos": Vector2(112, -176), "color": Color(0.9, 0.78, 0.36), "scale": 2.8, "energy": 0.24},
					{"pos": Vector2(0, -28), "color": Color(1.0, 0.82, 0.42), "scale": 2.3, "energy": 0.44},
					{"pos": Vector2(0, 112), "color": Color(0.34, 0.3, 0.16), "scale": 1.9, "energy": 0.12}
				]
			}
		"elysee":
			return {
				"title": "ELYSEE SALON",
				"subtitle": "Presidential reception",
				"floor_source": SRC_INTERIOR_FLOOR,
				"floor_tile": IF_PALACE,
				"accent_source": SRC_INTERIOR_FLOOR,
				"accent_tile": IF_OFFICE,
				"wall_tile": TILE_MARBLE_WALL,
				"window_positions": [-4, 0, 4],
				"curtains": true,
				"curtain_color": Color(0.1, 0.16, 0.44, 0.92),
				"panel_color": Color(0.16, 0.18, 0.22, 0.14),
				"trim_color": Color(0.78, 0.7, 0.42, 0.24),
				"accent_color": Color(0.22, 0.24, 0.42, 0.16),
				"rug_outer": Color(0.78, 0.72, 0.46, 0.86),
				"rug_inner": Color(0.12, 0.18, 0.48, 0.92),
				"rug_glow": Color(0.84, 0.76, 0.48, 0.16),
				"spawn_position": Vector2(0, 168),
				"npc_position": Vector2(0, 30),
				"desk_position": Vector2(0, -76),
				"lights": [
					{"pos": Vector2(-128, -182), "color": Color(0.82, 0.88, 1.0), "scale": 3.0, "energy": 0.28},
					{"pos": Vector2(128, -182), "color": Color(0.82, 0.88, 1.0), "scale": 3.0, "energy": 0.28},
					{"pos": Vector2(0, -16), "color": Color(1.0, 0.82, 0.56), "scale": 2.5, "energy": 0.48},
					{"pos": Vector2(0, 112), "color": Color(0.52, 0.46, 0.34), "scale": 2.0, "energy": 0.14}
				]
			}
		_:
			return {
				"title": "THE OVAL OFFICE",
				"subtitle": "Executive residence",
				"floor_source": SRC_INTERIOR_FLOOR,
				"floor_tile": IF_OFFICE,
				"accent_source": SRC_INTERIOR_FLOOR,
				"accent_tile": IF_PALACE,
				"wall_tile": TILE_MARBLE_WALL,
				"window_positions": [-4, 0, 4],
				"curtains": true,
				"curtain_color": Color(0.5, 0.12, 0.08, 0.92),
				"panel_color": Color(0.14, 0.1, 0.08, 0.18),
				"trim_color": Color(0.24, 0.18, 0.12, 0.22),
				"accent_color": Color(0.2, 0.14, 0.08, 0.12),
				"rug_outer": Color(0.76, 0.64, 0.34, 0.88),
				"rug_inner": Color(0.1, 0.17, 0.31, 0.92),
				"rug_glow": Color(0.76, 0.64, 0.34, 0.2),
				"spawn_position": Vector2(0, 168),
				"npc_position": Vector2(0, 28),
				"desk_position": Vector2(0, -78),
				"lights": [
					{"pos": Vector2(-128, -182), "color": Color(0.72, 0.84, 1.0), "scale": 3.0, "energy": 0.28},
					{"pos": Vector2(128, -182), "color": Color(0.72, 0.84, 1.0), "scale": 3.0, "energy": 0.28},
					{"pos": Vector2(0, -18), "color": Color(1.0, 0.78, 0.52), "scale": 2.5, "energy": 0.58},
					{"pos": Vector2(0, 104), "color": Color(0.52, 0.46, 0.36), "scale": 1.9, "energy": 0.18}
				]
			}

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
	for node in entities.get_children():
		if node.name != "Player":
			node.queue_free()
	for node in interactables.get_children():
		node.queue_free()
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

	collision_root = Node2D.new()
	collision_root.name = "CollisionRoot"
	add_child(collision_root)
	move_child(collision_root, 2)

	foreground_root = Node2D.new()
	foreground_root.name = "ForegroundRoot"
	add_child(foreground_root)
	move_child(foreground_root, get_child_count() - 1)

	_fill_floor()
	_build_walls()
	_build_wall_panels()
	_build_top_trim()
	_build_rug()
	_build_room_props()
	_build_boundaries()
	_build_foreground()

func _fill_floor() -> void:
	for x in range(ROOM_LEFT, ROOM_RIGHT + 1):
		for y in range(ROOM_TOP, ROOM_BOTTOM + 1):
			room_map.set_cell(LAYER_GROUND, Vector2i(x, y), int(theme["floor_source"]), theme["floor_tile"])

	match room_key:
		"spaceship":
			for y in range(-6, 6):
				room_map.set_cell(LAYER_ACCENT, Vector2i(-6, y), int(theme["accent_source"]), theme["accent_tile"])
				room_map.set_cell(LAYER_ACCENT, Vector2i(6, y), int(theme["accent_source"]), theme["accent_tile"])
		"vault":
			for y in range(-2, 4):
				room_map.set_cell(LAYER_ACCENT, Vector2i(-6, y), int(theme["accent_source"]), theme["accent_tile"])
				room_map.set_cell(LAYER_ACCENT, Vector2i(6, y), int(theme["accent_source"]), theme["accent_tile"])
		_:
			for x in range(-5, 6):
				for y in range(ROOM_TOP + 1, ROOM_TOP + 4):
					room_map.set_cell(LAYER_ACCENT, Vector2i(x, y), int(theme["accent_source"]), theme["accent_tile"])

func _build_walls() -> void:
	var wall_tile: Vector2i = theme["wall_tile"]
	var window_positions: Array = theme.get("window_positions", [])
	for x in range(ROOM_LEFT, ROOM_RIGHT + 1):
		var top_pos := Vector2i(x, ROOM_TOP)
		var top_tile := TILE_WINDOW if window_positions.has(x) else wall_tile
		room_map.set_cell(LAYER_STRUCT, top_pos, SRC_PROC, top_tile)

	for y in range(ROOM_TOP + 1, ROOM_BOTTOM):
		room_map.set_cell(LAYER_STRUCT, Vector2i(ROOM_LEFT, y), SRC_PROC, wall_tile)
		room_map.set_cell(LAYER_STRUCT, Vector2i(ROOM_RIGHT, y), SRC_PROC, wall_tile)

	for x in range(ROOM_LEFT, ROOM_RIGHT + 1):
		if abs(x) <= 1:
			continue
		room_map.set_cell(LAYER_STRUCT, Vector2i(x, ROOM_BOTTOM), SRC_PROC, wall_tile)
	room_map.set_cell(LAYER_STRUCT, Vector2i(0, ROOM_BOTTOM), SRC_PROC, TILE_DOOR)

	match room_key:
		"spaceship":
			room_map.set_cell(LAYER_STRUCT, Vector2i(-7, ROOM_TOP + 1), SRC_PROC, TILE_SERVER)
			room_map.set_cell(LAYER_STRUCT, Vector2i(7, ROOM_TOP + 1), SRC_PROC, TILE_SERVER)
		"vault":
			room_map.set_cell(LAYER_STRUCT, Vector2i(-6, ROOM_TOP + 1), SRC_PROC, TILE_GOLD)
			room_map.set_cell(LAYER_STRUCT, Vector2i(6, ROOM_TOP + 1), SRC_PROC, TILE_GOLD)
			room_map.set_cell(LAYER_STRUCT, Vector2i(0, ROOM_TOP + 1), SRC_PROC, TILE_CLOCK)
		_:
			room_map.set_cell(LAYER_STRUCT, Vector2i(-7, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
			room_map.set_cell(LAYER_STRUCT, Vector2i(-6, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
			room_map.set_cell(LAYER_STRUCT, Vector2i(6, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
			room_map.set_cell(LAYER_STRUCT, Vector2i(7, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
			room_map.set_cell(LAYER_STRUCT, Vector2i(0, ROOM_TOP + 2), SRC_PROC, TILE_CLOCK)

func _build_wall_panels() -> void:
	var panel_color: Color = theme["panel_color"]
	_add_rect_polygon(decor_root, Rect2(Vector2(-224, -166), Vector2(96, 74)), panel_color)
	_add_rect_polygon(decor_root, Rect2(Vector2(128, -166), Vector2(96, 74)), panel_color)
	_add_rect_polygon(decor_root, Rect2(Vector2(-224, 42), Vector2(96, 88)), panel_color.darkened(0.15))
	_add_rect_polygon(decor_root, Rect2(Vector2(128, 42), Vector2(96, 88)), panel_color.darkened(0.15))

func _build_top_trim() -> void:
	if bool(theme.get("curtains", false)):
		var curtain_color: Color = theme["curtain_color"]
		for window_x in [-128.0, 0.0, 128.0]:
			if not theme["window_positions"].has(int(window_x / 32.0)):
				continue
			_add_rect_polygon(decor_root, Rect2(Vector2(window_x - 42, -234), Vector2(18, 110)), curtain_color)
			_add_rect_polygon(decor_root, Rect2(Vector2(window_x + 24, -234), Vector2(18, 110)), curtain_color)
			_add_rect_polygon(decor_root, Rect2(Vector2(window_x - 44, -130), Vector2(88, 6)), theme["trim_color"].lightened(0.8))
	else:
		var accent: Color = theme["accent_color"]
		for x in [-160.0, 0.0, 160.0]:
			_add_rect_polygon(decor_root, Rect2(Vector2(x - 34, -226), Vector2(68, 14)), accent.lightened(0.4))
			_add_rect_polygon(decor_root, Rect2(Vector2(x - 14, -212), Vector2(28, 78)), accent)

func _build_rug() -> void:
	match room_key:
		"spaceship":
			_add_rect_polygon(decor_root, Rect2(Vector2(-112, -8), Vector2(224, 116)), theme["rug_outer"])
			_add_rect_polygon(decor_root, Rect2(Vector2(-90, 10), Vector2(180, 80)), theme["rug_inner"])
			_add_rect_polygon(decor_root, Rect2(Vector2(-22, -2), Vector2(44, 104)), theme["rug_glow"])
		"vault":
			_add_rect_polygon(decor_root, Rect2(Vector2(-96, -2), Vector2(192, 104)), theme["rug_outer"])
			_add_rect_polygon(decor_root, Rect2(Vector2(-76, 14), Vector2(152, 72)), theme["rug_inner"])
			_add_rect_polygon(decor_root, Rect2(Vector2(-10, -2), Vector2(20, 104)), theme["rug_glow"])
		"kremlin":
			_add_ellipse_polygon(decor_root, Vector2(0, 46), Vector2(184, 120), theme["rug_outer"], 32)
			_add_ellipse_polygon(decor_root, Vector2(0, 46), Vector2(162, 96), theme["rug_inner"], 32)
			_add_ellipse_polygon(decor_root, Vector2(0, 46), Vector2(80, 40), theme["rug_glow"], 24)
		_:
			_add_ellipse_polygon(decor_root, Vector2(0, 48), Vector2(192, 124), theme["rug_outer"], 32)
			_add_ellipse_polygon(decor_root, Vector2(0, 48), Vector2(172, 106), theme["rug_inner"], 32)
			_add_ellipse_polygon(decor_root, Vector2(0, 48), Vector2(88, 52), theme["rug_glow"], 24)

func _build_room_props() -> void:
	match room_key:
		"spaceship":
			_build_spaceship_props()
		"eu_palace":
			_build_eu_props()
		"kremlin":
			_build_kremlin_props()
		"vault":
			_build_vault_props()
		"elysee":
			_build_elysee_props()
		_:
			_build_oval_props()

func _build_oval_props() -> void:
	var desk = _create_desk("Desk", theme["desk_position"], false)
	_add_loose_sprite(desk, PROP_BOOK, Vector2(-20, -34))
	_add_loose_sprite(desk, PROP_HOURGLASS, Vector2(8, -34))
	_add_loose_sprite(desk, PROP_GOLD_CUP, Vector2(34, -34), Vector2(2.2, 2.2))
	var left_console = _create_console("NorthLeftConsole", Vector2(-146, -102), 2, TILE_DESK_WOOD)
	var right_console = _create_console("NorthRightConsole", Vector2(146, -102), 2, TILE_DESK_WOOD)
	_add_loose_sprite(left_console, PROP_BOOK, Vector2(-8, -36))
	_add_loose_sprite(right_console, PROP_GOLD_CUP, Vector2(2, -38), Vector2(2.2, 2.2))
	_create_archive_unit("LeftBookcase", Vector2(-214, -22), TILE_BOOKSHELF)
	_create_archive_unit("RightCabinet", Vector2(214, -22), TILE_FILE_CABINET)
	_create_flag_stand("UnitedStatesFlag", Vector2(-208, -136), "us", true)
	_create_flag_stand("PresidentialBanner", Vector2(208, -136), "banner", false)
	_create_potted_plant("LeftPlant", Vector2(-206, 120))
	_create_potted_plant("RightPlant", Vector2(206, 120))
	var south_left = _create_console("SouthLeftConsole", Vector2(-154, 148), 2, TILE_DESK_WOOD)
	var south_right = _create_console("SouthRightConsole", Vector2(154, 148), 2, TILE_DESK_WOOD)
	_add_loose_sprite(south_left, PROP_BAG, Vector2(-10, -36))
	_add_loose_sprite(south_left, PROP_BOOK, Vector2(10, -34))
	_add_loose_sprite(south_right, PROP_HOURGLASS, Vector2(-10, -34))
	_add_loose_sprite(south_right, PROP_BOOK, Vector2(10, -34))

func _build_spaceship_props() -> void:
	var desk = _create_desk("CommandDesk", theme["desk_position"], true)
	_add_loose_sprite(desk, PROP_BAG, Vector2(-18, -34), Vector2(1.6, 1.6))
	_add_loose_sprite(desk, PROP_BOOK, Vector2(10, -32), Vector2(1.5, 1.5))
	_create_server_bank("NorthWestServer", Vector2(-208, -94), 2)
	_create_server_bank("NorthEastServer", Vector2(208, -94), 2)
	_create_server_bank("MidWestServer", Vector2(-208, 4), 2)
	_create_server_bank("MidEastServer", Vector2(208, 4), 2)
	var left_console = _create_console("LeftCommandConsole", Vector2(-126, -18), 2, TILE_DESK_METAL)
	var right_console = _create_console("RightCommandConsole", Vector2(126, -18), 2, TILE_DESK_METAL)
	_add_loose_sprite(left_console, PROP_BOOK, Vector2(-10, -34), Vector2(1.5, 1.5))
	_add_loose_sprite(right_console, PROP_HOURGLASS, Vector2(8, -34), Vector2(1.7, 1.7))
	var south_left = _create_console("SouthLeftRack", Vector2(-150, 150), 2, TILE_METAL_FLOOR)
	var south_right = _create_console("SouthRightRack", Vector2(150, 150), 2, TILE_METAL_FLOOR)
	_add_loose_sprite(south_left, PROP_CRATE, Vector2(-14, -30), Vector2(1.5, 1.5))
	_add_loose_sprite(south_right, PROP_BAG, Vector2(2, -30), Vector2(1.5, 1.5))

func _build_eu_props() -> void:
	var desk = _create_desk("CommissionDesk", theme["desk_position"], false)
	_add_loose_sprite(desk, PROP_BOOK, Vector2(-18, -34))
	_add_loose_sprite(desk, PROP_BOOK, Vector2(10, -32), Vector2(1.8, 1.8))
	var north_table = _create_console("NorthBriefingTable", Vector2(0, -104), 3, TILE_DESK_WOOD)
	_add_loose_sprite(north_table, PROP_BOOK, Vector2(-18, -34))
	_add_loose_sprite(north_table, PROP_HOURGLASS, Vector2(10, -34), Vector2(1.7, 1.7))
	_create_archive_unit("LeftShelf", Vector2(-214, -18), TILE_BOOKSHELF)
	_create_archive_unit("RightShelf", Vector2(214, -18), TILE_BOOKSHELF)
	_create_archive_unit("LeftCabinet", Vector2(-214, 50), TILE_FILE_CABINET)
	_create_archive_unit("RightCabinet", Vector2(214, 50), TILE_FILE_CABINET)
	_create_flag_stand("EUFlagWest", Vector2(-208, -136), "eu", true)
	_create_flag_stand("EUFlagEast", Vector2(208, -136), "eu", false)
	_create_potted_plant("LeftPlant", Vector2(-206, 126))
	_create_potted_plant("RightPlant", Vector2(206, 126))

func _build_kremlin_props() -> void:
	var desk = _create_desk("SecurityDesk", theme["desk_position"], false)
	_add_loose_sprite(desk, PROP_BAG, Vector2(-18, -34), Vector2(1.5, 1.5))
	_add_loose_sprite(desk, PROP_HOURGLASS, Vector2(10, -34), Vector2(1.7, 1.7))
	_create_archive_unit("LeftWideCabinet", Vector2(-214, -28), TILE_FILE_CABINET_WIDE)
	_create_archive_unit("RightCabinet", Vector2(214, -22), TILE_FILE_CABINET)
	_create_flag_stand("RussianFlag", Vector2(-208, -136), "russia", true)
	_create_flag_stand("CrestBanner", Vector2(208, -136), "kremlin", false)
	var south_left = _create_console("SouthLeftTable", Vector2(-148, 150), 2, TILE_DESK_WOOD)
	var south_right = _create_console("SouthRightTable", Vector2(148, 150), 2, TILE_DESK_WOOD)
	_add_loose_sprite(south_left, PROP_BOOK, Vector2(-8, -34))
	_add_loose_sprite(south_right, PROP_BAG, Vector2(8, -34), Vector2(1.5, 1.5))
	_create_potted_plant("LeftPlant", Vector2(-206, 126))
	_create_potted_plant("RightPlant", Vector2(206, 126))

func _build_vault_props() -> void:
	var desk = _create_desk("VaultControlDesk", theme["desk_position"], true)
	_add_loose_sprite(desk, PROP_BOOK, Vector2(-18, -34), Vector2(1.6, 1.6))
	_add_loose_sprite(desk, PROP_GOLD_CUP, Vector2(18, -36), Vector2(2.0, 2.0))
	_create_gold_stack("NorthGoldLeft", Vector2(-176, -106), 3)
	_create_gold_stack("NorthGoldRight", Vector2(176, -106), 3)
	_create_archive_unit("LeftWideCabinet", Vector2(-214, -24), TILE_FILE_CABINET_WIDE)
	_create_archive_unit("RightWideCabinet", Vector2(214, -24), TILE_FILE_CABINET_WIDE)
	_create_archive_unit("LeftCabinet", Vector2(-214, 56), TILE_FILE_CABINET)
	_create_archive_unit("RightCabinet", Vector2(214, 56), TILE_FILE_CABINET)
	_create_console("SouthLeftConsole", Vector2(-150, 150), 2, TILE_METAL_FLOOR)
	_create_console("SouthRightConsole", Vector2(150, 150), 2, TILE_METAL_FLOOR)
	_create_flag_stand("ECBFlagWest", Vector2(-212, -128), "ecb", true)
	_create_flag_stand("ECBFlagEast", Vector2(212, -128), "ecb", false)

func _build_elysee_props() -> void:
	var desk = _create_desk("ElyseeDesk", theme["desk_position"], false)
	_add_loose_sprite(desk, PROP_BOOK, Vector2(-20, -34))
	_add_loose_sprite(desk, PROP_GOLD_CUP, Vector2(28, -36), Vector2(2.0, 2.0))
	_create_archive_unit("LeftShelf", Vector2(-214, -20), TILE_BOOKSHELF)
	_create_archive_unit("RightShelf", Vector2(214, -20), TILE_BOOKSHELF)
	_create_flag_stand("FranceFlag", Vector2(-208, -136), "france", true)
	_create_flag_stand("ElyseeBanner", Vector2(208, -136), "banner", false)
	_create_potted_plant("LeftPlant", Vector2(-206, 124))
	_create_potted_plant("RightPlant", Vector2(206, 124))
	var south_left = _create_console("SouthLeftConsole", Vector2(-150, 150), 2, TILE_DESK_WOOD)
	var south_right = _create_console("SouthRightConsole", Vector2(150, 150), 2, TILE_DESK_WOOD)
	_add_loose_sprite(south_left, PROP_BOOK, Vector2(-8, -34))
	_add_loose_sprite(south_right, PROP_HOURGLASS, Vector2(8, -34), Vector2(1.7, 1.7))

func _build_boundaries() -> void:
	_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2((ROOM_RIGHT - ROOM_LEFT + 1) * 32, 64)))
	_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2(32, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)))
	_create_barrier(Rect2(Vector2(ROOM_RIGHT * 32, ROOM_TOP * 32), Vector2(32, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)))
	_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_BOTTOM * 32), Vector2(240, 32)))
	_create_barrier(Rect2(Vector2(112, ROOM_BOTTOM * 32), Vector2(208, 32)))

func _build_foreground() -> void:
	_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2((ROOM_RIGHT - ROOM_LEFT + 1) * 32, 28)), Color(0, 0, 0, 0.16))
	_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_LEFT * 32, ROOM_BOTTOM * 32 - 14), Vector2((ROOM_RIGHT - ROOM_LEFT + 1) * 32, 46)), Color(0, 0, 0, 0.1))
	_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2(34, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)), Color(0.02, 0.01, 0.01, 0.16))
	_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_RIGHT * 32 - 2, ROOM_TOP * 32), Vector2(34, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)), Color(0.02, 0.01, 0.01, 0.16))

func _create_desk(name: String, origin: Vector2, metal: bool) -> StaticBody2D:
	var tile := TILE_DESK_METAL if metal else TILE_DESK_WOOD
	_create_shadow(origin + Vector2(0, 8), Vector2(126, 16), Color(0, 0, 0, 0.14))
	return _create_world_unit(
		name,
		origin,
		[
			{"coords": tile, "offset": Vector2(-48, -32)},
			{"coords": tile, "offset": Vector2(-16, -32)},
			{"coords": tile, "offset": Vector2(16, -32)}
		],
		Vector2(94, 18),
		Vector2(0, -9)
	)

func _create_console(name: String, origin: Vector2, width_tiles: int, tile_coords: Vector2i) -> StaticBody2D:
	_create_shadow(origin + Vector2(0, 8), Vector2(84, 14), Color(0, 0, 0, 0.1))
	var tiles: Array = []
	for i in range(width_tiles):
		tiles.append({"coords": tile_coords, "offset": Vector2(-width_tiles * 16 + i * 32, -32)})
	return _create_world_unit(name, origin, tiles, Vector2(62, 12), Vector2(0, -6))

func _create_archive_unit(name: String, origin: Vector2, tile_coords: Vector2i) -> StaticBody2D:
	_create_shadow(origin + Vector2(0, 6), Vector2(28, 18), Color(0, 0, 0, 0.1))
	return _create_world_unit(name, origin, [{"coords": tile_coords, "offset": Vector2(-16, -32)}], Vector2(24, 18), Vector2(0, -8))

func _create_server_bank(name: String, origin: Vector2, count: int) -> void:
	for i in range(count):
		_create_world_unit("%s_%d" % [name, i], origin + Vector2(0, i * 42), [{"coords": TILE_SERVER, "offset": Vector2(-16, -32)}], Vector2(24, 18), Vector2(0, -8))

func _create_gold_stack(name: String, origin: Vector2, count: int) -> void:
	for i in range(count):
		_create_world_unit("%s_%d" % [name, i], origin + Vector2(i * 30 - (count - 1) * 15, 0), [{"coords": TILE_GOLD, "offset": Vector2(-16, -32)}], Vector2(18, 12), Vector2(0, -6))

func _create_potted_plant(name: String, origin: Vector2) -> StaticBody2D:
	return _create_world_unit(name, origin, [{"coords": TILE_PLANT, "offset": Vector2(-16, -32)}], Vector2(20, 18), Vector2(0, -8))

func _create_holo_pedestal(name: String, origin: Vector2) -> void:
	var stand = _create_display_pedestal(name, origin, PROP_BOOK, Vector2(0.0, 0.0))
	var sprite = _add_loose_sprite(stand, WORLD_TILES, Vector2(0, -38), Vector2(1.25, 1.25))
	sprite.region_enabled = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_rect = Rect2(Vector2(TILE_GLOBE * 32), Vector2(32, 32))

func _create_lounge_chair(name: String, origin: Vector2, faces_left: bool, seat_color: Color, back_color: Color) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.name = name
	body.position = origin
	_add_shadow_to_node(body, Rect2(Vector2(-28, 6), Vector2(56, 14)), Color(0, 0, 0, 0.1))
	var seat = Polygon2D.new()
	seat.color = seat_color
	seat.polygon = PackedVector2Array([Vector2(-22, -10), Vector2(22, -10), Vector2(26, 10), Vector2(-26, 10)])
	body.add_child(seat)
	var back = Polygon2D.new()
	back.color = back_color
	var dir := -1.0 if faces_left else 1.0
	back.polygon = PackedVector2Array([Vector2(-24 * dir, -28), Vector2(18 * dir, -24), Vector2(22 * dir, -8), Vector2(-20 * dir, -10)])
	body.add_child(back)
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(42, 18)
	col.shape = shape
	col.position = Vector2(0, -2)
	body.add_child(col)
	entities.add_child(body)
	return body

func _create_coffee_table(name: String, origin: Vector2, add_bag: bool) -> StaticBody2D:
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
	return body

func _create_display_pedestal(name: String, origin: Vector2, top_texture: Texture2D, top_scale: Vector2) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.name = name
	body.position = origin
	_add_shadow_to_node(body, Rect2(Vector2(-18, 4), Vector2(36, 12)), Color(0, 0, 0, 0.08))
	var base = Polygon2D.new()
	base.color = Color(0.73, 0.72, 0.7, 0.96)
	base.polygon = PackedVector2Array([Vector2(-16, -28), Vector2(16, -28), Vector2(20, 8), Vector2(-20, 8)])
	body.add_child(base)
	var trim = Polygon2D.new()
	trim.color = Color(0.86, 0.82, 0.68, 0.95)
	trim.polygon = PackedVector2Array([Vector2(-18, -30), Vector2(18, -30), Vector2(16, -24), Vector2(-16, -24)])
	body.add_child(trim)
	if top_scale.x > 0.0 and top_scale.y > 0.0:
		_add_loose_sprite(body, top_texture, Vector2(0, -42), top_scale)
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 14)
	col.shape = shape
	col.position = Vector2(0, 0)
	body.add_child(col)
	entities.add_child(body)
	return body

func _create_flag_stand(name: String, origin: Vector2, flag_style: String, drape_left: bool) -> void:
	var stand = Node2D.new()
	stand.name = name
	stand.position = origin
	var pole = Polygon2D.new()
	pole.color = Color(0.72, 0.6, 0.32, 0.95)
	pole.polygon = PackedVector2Array([Vector2(-2, -6), Vector2(2, -6), Vector2(2, -86), Vector2(-2, -86)])
	stand.add_child(pole)
	var finial = Polygon2D.new()
	finial.color = Color(0.86, 0.78, 0.42, 0.98)
	finial.polygon = _make_ellipse(Vector2(0, -90), Vector2(10, 10), 12)
	stand.add_child(finial)
	var base = Polygon2D.new()
	base.color = Color(0.54, 0.43, 0.2, 0.95)
	base.polygon = PackedVector2Array([Vector2(-14, 8), Vector2(14, 8), Vector2(18, 16), Vector2(-18, 16)])
	stand.add_child(base)
	var dir := -1.0 if drape_left else 1.0
	var main_flag = Polygon2D.new()
	main_flag.color = Color.WHITE
	main_flag.polygon = PackedVector2Array([Vector2(0, -82), Vector2(44 * dir, -78), Vector2(38 * dir, -54), Vector2(10 * dir, -46), Vector2(0, -50)])
	stand.add_child(main_flag)
	match flag_style:
		"us":
			for i in range(7):
				var stripe = Polygon2D.new()
				stripe.color = Color(0.76, 0.12, 0.18, 0.95) if i % 2 == 0 else Color(0.96, 0.96, 0.94, 0.95)
				var top_y := -82.0 + i * 5.0
				stripe.polygon = PackedVector2Array([Vector2(0, top_y), Vector2(42 * dir, top_y + 3), Vector2(38 * dir, top_y + 8), Vector2(0, top_y + 6)])
				stand.add_child(stripe)
			var canton = Polygon2D.new()
			canton.color = Color(0.08, 0.18, 0.46, 0.98)
			canton.polygon = PackedVector2Array([Vector2(0, -82), Vector2(18 * dir, -80), Vector2(18 * dir, -62), Vector2(0, -64)])
			stand.add_child(canton)
		"eu":
			main_flag.color = Color(0.08, 0.22, 0.56, 0.98)
			for i in range(8):
				var star = Polygon2D.new()
				var angle := TAU * float(i) / 8.0
				var star_center := Vector2(18 * dir + cos(angle) * 9.0 * dir, -64 + sin(angle) * 9.0)
				star.color = Color(0.88, 0.8, 0.34, 0.95)
				star.polygon = _make_ellipse(star_center, Vector2(3, 3), 6)
				stand.add_child(star)
		"france":
			main_flag.color = Color(0.95, 0.95, 0.94, 0.98)
			var blue = Polygon2D.new()
			blue.color = Color(0.08, 0.18, 0.46, 0.98)
			blue.polygon = PackedVector2Array([Vector2(0, -82), Vector2(14 * dir, -80), Vector2(12 * dir, -52), Vector2(0, -54)])
			stand.add_child(blue)
			var red = Polygon2D.new()
			red.color = Color(0.78, 0.12, 0.16, 0.98)
			red.polygon = PackedVector2Array([Vector2(28 * dir, -80), Vector2(44 * dir, -78), Vector2(38 * dir, -54), Vector2(24 * dir, -56)])
			stand.add_child(red)
		"russia":
			var white = Polygon2D.new()
			white.color = Color(0.96, 0.96, 0.94, 0.98)
			white.polygon = PackedVector2Array([Vector2(0, -82), Vector2(44 * dir, -78), Vector2(42 * dir, -70), Vector2(0, -74)])
			stand.add_child(white)
			var blue2 = Polygon2D.new()
			blue2.color = Color(0.12, 0.28, 0.62, 0.98)
			blue2.polygon = PackedVector2Array([Vector2(0, -74), Vector2(42 * dir, -70), Vector2(40 * dir, -62), Vector2(0, -66)])
			stand.add_child(blue2)
			var red2 = Polygon2D.new()
			red2.color = Color(0.76, 0.12, 0.16, 0.98)
			red2.polygon = PackedVector2Array([Vector2(0, -66), Vector2(40 * dir, -62), Vector2(38 * dir, -54), Vector2(0, -58)])
			stand.add_child(red2)
		"ecb":
			main_flag.color = Color(0.08, 0.22, 0.44, 0.98)
			var euro_ring = Polygon2D.new()
			euro_ring.color = Color(0.86, 0.74, 0.32, 0.95)
			euro_ring.polygon = _make_ellipse(Vector2(18 * dir, -64), Vector2(16, 16), 16)
			stand.add_child(euro_ring)
			var euro_inner = Polygon2D.new()
			euro_inner.color = Color(0.08, 0.22, 0.44, 1.0)
			euro_inner.polygon = _make_ellipse(Vector2(18 * dir, -64), Vector2(8, 8), 12)
			stand.add_child(euro_inner)
		"kremlin":
			main_flag.color = Color(0.42, 0.08, 0.08, 0.98)
			var seal = Polygon2D.new()
			seal.color = Color(0.84, 0.72, 0.34, 0.92)
			seal.polygon = _make_ellipse(Vector2(18 * dir, -64), Vector2(16, 16), 14)
			stand.add_child(seal)
		_:
			main_flag.color = Color(0.12, 0.2, 0.52, 0.98)
			var trim = Polygon2D.new()
			trim.color = Color(0.86, 0.74, 0.38, 0.95)
			trim.polygon = PackedVector2Array([Vector2(0, -82), Vector2(44 * dir, -78), Vector2(42 * dir, -74), Vector2(0, -78)])
			stand.add_child(trim)
			var seal2 = Polygon2D.new()
			seal2.color = Color(0.86, 0.74, 0.38, 0.92)
			seal2.polygon = _make_ellipse(Vector2(18 * dir, -64), Vector2(16, 16), 16)
			stand.add_child(seal2)
	_add_shadow_to_node(stand, Rect2(Vector2(-16, 12), Vector2(32, 8)), Color(0, 0, 0, 0.08))
	decor_root.add_child(stand)

func _create_world_unit(name: String, origin: Vector2, tiles: Array, collision_size: Vector2, collision_offset: Vector2) -> StaticBody2D:
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
	return body

func _add_loose_sprite(parent: Node, texture: Texture2D, offset: Vector2, scale: Vector2 = ITEM_SCALE) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = scale
	sprite.position = offset
	parent.add_child(sprite)
	return sprite

func _spawn_character() -> void:
	var npc = NPC_SCENE.instantiate()
	npc.name = "%sInterior" % character_name.replace(" ", "")
	npc.character_id = character_id
	npc.character_name = character_name
	npc.position = theme.get("npc_position", Vector2(0, 40))
	npc.z_index = 3
	entities.add_child(npc)

func _create_exit_door() -> void:
	var door := Area2D.new()
	door.name = "ExitDoor"
	door.collision_layer = 0
	door.collision_mask = 1
	door.monitoring = true
	door.monitorable = true
	door.position = Vector2(0, 228)
	door.set_script(DOORWAY_SCRIPT)
	door.set("destination", "world")
	door.set("spawn_marker", "%s_exterior" % room_key)
	door.set("prompt_name", "Exit")
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(120, 36)
	col.shape = shape
	door.add_child(col)
	interactables.add_child(door)

func _create_lighting() -> void:
	for light_spec in theme.get("lights", []):
		_add_point_light(light_spec["pos"], light_spec["color"], float(light_spec["scale"]), float(light_spec["energy"]))

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
	entry.position = theme.get("spawn_position", Vector2(0, 168))

func _create_barrier(rect: Rect2) -> void:
	var body = StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	body.add_child(col)
	collision_root.add_child(body)

func _create_shadow(pos: Vector2, size: Vector2, color: Color) -> void:
	_add_rect_polygon(decor_root, Rect2(pos - size * 0.5, size), color)

func _add_shadow_to_node(parent: Node, rect: Rect2, color: Color) -> void:
	var shadow = Polygon2D.new()
	shadow.color = color
	shadow.polygon = PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.position + rect.size, rect.position + Vector2(0, rect.size.y)])
	parent.add_child(shadow)

func _add_rect_polygon(parent: Node2D, rect: Rect2, color: Color) -> void:
	var poly = Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.position + rect.size, rect.position + Vector2(0, rect.size.y)])
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
