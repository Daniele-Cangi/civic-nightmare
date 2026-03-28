extends Node2D

const NPC_SCENE = preload("res://scenes/npc.tscn")
const DOORWAY_SCRIPT = preload("res://scripts/doorway.gd")
const RITUAL_STATION_SCRIPT = preload("res://scripts/ritual_station.gd")
const WORLD_TILES = preload("res://assets/tiles/world_tiles.png")
const PROP_BOOK = preload("res://assets/packs/civic_nightmare/items_props/ninja/Object/Book.png")
const PROP_HOURGLASS = preload("res://assets/packs/civic_nightmare/items_props/ninja/Object/Hourglass.png")
const PROP_BAG = preload("res://assets/packs/civic_nightmare/items_props/ninja/Object/Bag.png")
const PROP_MONEY_BAG = preload("res://assets/packs/civic_nightmare/items_props/ninja/Object/MoneyBag.png")
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
var room_npc: StaticBody2D
var ritual_stations: Dictionary = {}
var encounter_state: Dictionary = {}

func _ready() -> void:
	theme = _theme_for_key(room_key)
	_setup_encounter_density()
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
	if active:
		_refresh_encounter_density()
		if room_key == "vault" and not bool(encounter_state.get("dialogue_ready", true)):
			call_deferred("_show_vault_instruction")

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

func _setup_encounter_density() -> void:
	ritual_stations.clear()
	if room_key == "vault":
		encounter_state = {
			"residue_id": "",
			"aftermath_spawned": false
		}
	else:
		encounter_state = {}

func _show_vault_instruction() -> void:
	return

func _refresh_encounter_density() -> void:
	return

func handle_ritual_station_interaction(station_id: String) -> void:
	return

func handle_dialogue_choice(target_character_id: String, choice: Dictionary) -> void:
	if room_key != "vault" or target_character_id != "christine_lagarde" or bool(encounter_state.get("aftermath_spawned", false)):
		return

	var residue_id := str(choice.get("residue_id", "emotional_surcharge_notice")).strip_edges()
	var aftermath_title := str(choice.get("aftermath_title", "SURCHARGE REGISTERED")).strip_edges()
	var aftermath_subtitle := str(choice.get("aftermath_subtitle", "Resistance itself has been priced into the file.")).strip_edges()

	encounter_state["residue_id"] = residue_id
	encounter_state["aftermath_spawned"] = true
	_spawn_vault_aftermath_notice(residue_id)

	var world = get_tree().current_scene
	if world:
		if world.has_method("register_encounter_residue"):
			world.register_encounter_residue(target_character_id, residue_id, aftermath_subtitle)
		if world.has_method("_show_room_title"):
			world._show_room_title(aftermath_title, aftermath_subtitle)

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
		"ufo_lab":
			return {
				"title": "UNIDENTIFIED CRAFT",
				"subtitle": "Observation deck",
				"floor_source": SRC_INTERIOR_FLOOR,
				"floor_tile": IF_OFFICE,
				"accent_source": SRC_INTERIOR_FLOOR,
				"accent_tile": IF_PALACE,
				"wall_tile": TILE_MARBLE_WALL,
				"window_positions": [],
				"curtains": false,
				"panel_color": Color(0.78, 0.92, 0.94, 0.22),
				"trim_color": Color(0.58, 0.9, 0.82, 0.24),
				"accent_color": Color(0.42, 0.92, 0.78, 0.18),
				"rug_outer": Color(0.82, 0.92, 0.9, 0.86),
				"rug_inner": Color(0.7, 0.84, 0.82, 0.92),
				"rug_glow": Color(0.62, 1.0, 0.88, 0.12),
				"spawn_position": Vector2(0, 168),
				"npc_position": Vector2(-104, 22),
				"desk_position": Vector2(0, -72),
				"lights": [
					{"pos": Vector2(-132, -178), "color": Color(0.88, 1.0, 0.96), "scale": 3.0, "energy": 0.26},
					{"pos": Vector2(132, -178), "color": Color(0.88, 1.0, 0.96), "scale": 3.0, "energy": 0.26},
					{"pos": Vector2(0, -22), "color": Color(0.72, 1.0, 0.88), "scale": 2.5, "energy": 0.42},
					{"pos": Vector2(0, 112), "color": Color(0.34, 0.46, 0.44), "scale": 2.0, "energy": 0.1}
				]
			}
		"mountain_bunker":
			return {
				"title": "MOUNTAIN BUNKER",
				"subtitle": "Excluded from protocol",
				"floor_source": SRC_PROC,
				"floor_tile": TILE_METAL_FLOOR,
				"accent_source": SRC_PROC,
				"accent_tile": TILE_METAL_FLOOR,
				"wall_tile": TILE_VAULT_WALL,
				"window_positions": [],
				"curtains": false,
				"panel_color": Color(0.08, 0.09, 0.11, 0.46),
				"trim_color": Color(0.18, 0.2, 0.24, 0.28),
				"accent_color": Color(0.12, 0.14, 0.16, 0.22),
				"rug_outer": Color(0.08, 0.09, 0.1, 0.94),
				"rug_inner": Color(0.05, 0.06, 0.07, 0.98),
				"rug_glow": Color(0.18, 0.22, 0.26, 0.08),
				"spawn_position": Vector2(0, 180),
				"approach_position": Vector2(0, 118),
				"npc_position": Vector2(-70, 26),
				"desk_position": Vector2(0, -68),
				"lights": [
					{"pos": Vector2(0, -186), "color": Color(0.54, 0.58, 0.64), "scale": 2.1, "energy": 0.11},
					{"pos": Vector2(-124, 18), "color": Color(0.2, 0.34, 0.42), "scale": 1.7, "energy": 0.06},
					{"pos": Vector2(0, 98), "color": Color(0.12, 0.14, 0.18), "scale": 1.8, "energy": 0.05}
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
		"ufo_lab":
			return
		"mountain_bunker":
			return
		"kremlin":
			return
		"oval_office":
			return
		"vault":
			return
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
		"ufo_lab":
			room_map.set_cell(LAYER_STRUCT, Vector2i(0, ROOM_TOP + 1), SRC_PROC, TILE_GLOBE)
		"vault":
			room_map.set_cell(LAYER_STRUCT, Vector2i(0, ROOM_TOP + 1), SRC_PROC, TILE_CLOCK)
		_:
			room_map.set_cell(LAYER_STRUCT, Vector2i(-7, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
			room_map.set_cell(LAYER_STRUCT, Vector2i(-6, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
			room_map.set_cell(LAYER_STRUCT, Vector2i(6, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
			room_map.set_cell(LAYER_STRUCT, Vector2i(7, ROOM_TOP + 1), SRC_PROC, TILE_COLUMN)
			room_map.set_cell(LAYER_STRUCT, Vector2i(0, ROOM_TOP + 2), SRC_PROC, TILE_CLOCK)

func _build_wall_panels() -> void:
	if room_key == "ufo_lab":
		var ufo_panel_color: Color = theme["panel_color"]
		_add_rect_polygon(decor_root, Rect2(Vector2(-196, -170), Vector2(392, 96)), ufo_panel_color)
		_add_rect_polygon(decor_root, Rect2(Vector2(-172, -146), Vector2(344, 48)), theme["trim_color"].lightened(0.2))
		return

	if room_key == "mountain_bunker":
		var bunker_panel: Color = theme["panel_color"]
		_add_rect_polygon(decor_root, Rect2(Vector2(-192, -168), Vector2(384, 110)), bunker_panel)
		_add_rect_polygon(decor_root, Rect2(Vector2(-82, -162), Vector2(164, 56)), theme["trim_color"])
		_add_rect_polygon(decor_root, Rect2(Vector2(-220, -162), Vector2(92, 180)), Color(0.02, 0.02, 0.03, 0.42))
		_add_rect_polygon(decor_root, Rect2(Vector2(128, -162), Vector2(92, 180)), Color(0.02, 0.02, 0.03, 0.42))
		_add_rect_polygon(decor_root, Rect2(Vector2(-56, -96), Vector2(16, 174)), Color(0.18, 0.2, 0.22, 0.14))
		_add_rect_polygon(decor_root, Rect2(Vector2(24, -74), Vector2(10, 128)), Color(0.18, 0.2, 0.22, 0.12))
		return

	if room_key == "kremlin":
		var kremlin_panel_color: Color = theme["panel_color"]
		_add_rect_polygon(decor_root, Rect2(Vector2(-184, -164), Vector2(368, 92)), kremlin_panel_color.darkened(0.04))
		return

	if room_key == "oval_office":
		var oval_panel_color: Color = theme["panel_color"]
		_add_rect_polygon(decor_root, Rect2(Vector2(-188, -164), Vector2(376, 92)), oval_panel_color.darkened(0.05))
		return

	if room_key == "vault":
		var panel_color: Color = theme["panel_color"]
		_add_rect_polygon(decor_root, Rect2(Vector2(-184, -162), Vector2(368, 86)), panel_color.darkened(0.08))
		return

	var panel_color: Color = theme["panel_color"]
	_add_rect_polygon(decor_root, Rect2(Vector2(-224, -166), Vector2(96, 74)), panel_color)
	_add_rect_polygon(decor_root, Rect2(Vector2(128, -166), Vector2(96, 74)), panel_color)
	_add_rect_polygon(decor_root, Rect2(Vector2(-224, 42), Vector2(96, 88)), panel_color.darkened(0.15))
	_add_rect_polygon(decor_root, Rect2(Vector2(128, 42), Vector2(96, 88)), panel_color.darkened(0.15))

func _build_top_trim() -> void:
	if room_key == "ufo_lab":
		var ufo_accent: Color = theme["accent_color"]
		_add_rect_polygon(decor_root, Rect2(Vector2(-88, -224), Vector2(176, 10)), ufo_accent.lightened(0.55))
		_add_rect_polygon(decor_root, Rect2(Vector2(-22, -214), Vector2(44, 66)), ufo_accent.lightened(0.15))
		return

	if room_key == "mountain_bunker":
		var bunker_accent: Color = theme["accent_color"]
		_add_rect_polygon(decor_root, Rect2(Vector2(-58, -226), Vector2(116, 8)), bunker_accent.lightened(0.18))
		_add_rect_polygon(decor_root, Rect2(Vector2(-22, -218), Vector2(44, 34)), Color(0.58, 0.62, 0.68, 0.12))
		return

	if room_key == "vault":
		var accent: Color = theme["accent_color"]
		_add_rect_polygon(decor_root, Rect2(Vector2(-58, -222), Vector2(116, 12)), accent.lightened(0.45))
		return

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
		"ufo_lab":
			_add_ellipse_polygon(decor_root, Vector2(0, 44), Vector2(228, 118), theme["rug_outer"], 36)
			_add_ellipse_polygon(decor_root, Vector2(0, 44), Vector2(192, 88), theme["rug_inner"], 32)
			_add_ellipse_polygon(decor_root, Vector2(0, 44), Vector2(72, 34), theme["rug_glow"], 24)
		"mountain_bunker":
			_add_rect_polygon(decor_root, Rect2(Vector2(-92, -4), Vector2(184, 126)), theme["rug_outer"])
			_add_rect_polygon(decor_root, Rect2(Vector2(-62, 12), Vector2(124, 82)), theme["rug_inner"])
			_add_rect_polygon(decor_root, Rect2(Vector2(-8, -4), Vector2(16, 126)), theme["rug_glow"])
			_add_rect_polygon(decor_root, Rect2(Vector2(-42, 90), Vector2(84, 10)), Color(0.0, 0.0, 0.0, 0.18))
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
		"ufo_lab":
			_build_ufo_lab_props()
		"mountain_bunker":
			_build_mountain_bunker_props()
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
	_add_loose_sprite(desk, PROP_BOOK, Vector2(-6, -34))
	_create_floor_prop("MoneyLeft", PROP_MONEY_BAG, Vector2(-112, 72), Vector2(1.2, 1.2))
	_create_floor_prop("MoneyRight", PROP_MONEY_BAG, Vector2(118, 54), Vector2(1.0, 1.0))
	_create_floor_prop("MoneyFront", PROP_MONEY_BAG, Vector2(24, 118), Vector2(1.1, 1.1))

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
	_add_loose_sprite(desk, PROP_BAG, Vector2(-2, -34), Vector2(1.5, 1.5))
	_create_flag_stand("RussianFlag", Vector2(-208, -136), "russia", true)
	_create_flag_stand("CrestBanner", Vector2(208, -136), "kremlin", false)

func _build_vault_props() -> void:
	var desk = _create_desk("VaultControlDesk", theme["desk_position"], true)
	_add_loose_sprite(desk, PROP_BOOK, Vector2(0, -34), Vector2(1.6, 1.6))

func _build_ufo_lab_props() -> void:
	var board := Node2D.new()
	board.name = "DebateBoard"
	board.position = Vector2(0, -92)
	_add_shadow_to_node(board, Rect2(Vector2(-92, 10), Vector2(184, 14)), Color(0, 0, 0, 0.08))

	var frame = Polygon2D.new()
	frame.color = Color(0.72, 0.82, 0.82, 0.96)
	frame.polygon = PackedVector2Array([
		Vector2(-96, -44),
		Vector2(96, -44),
		Vector2(104, 24),
		Vector2(-104, 24)
	])
	board.add_child(frame)

	var panel = Polygon2D.new()
	panel.color = Color(0.08, 0.12, 0.14, 0.96)
	panel.polygon = PackedVector2Array([
		Vector2(-84, -34),
		Vector2(84, -34),
		Vector2(92, 14),
		Vector2(-92, 14)
	])
	board.add_child(panel)

	for rule_y in [-18.0, -2.0, 12.0]:
		var rule = Polygon2D.new()
		rule.color = Color(0.58, 0.96, 0.84, 0.28)
		rule.polygon = PackedVector2Array([
			Vector2(-62, rule_y),
			Vector2(56, rule_y + 4),
			Vector2(56, rule_y + 8),
			Vector2(-62, rule_y + 4)
		])
		board.add_child(rule)

	var formula = Polygon2D.new()
	formula.color = Color(0.9, 1.0, 0.92, 0.82)
	formula.polygon = PackedVector2Array([
		Vector2(-16, -24),
		Vector2(36, -20),
		Vector2(32, -12),
		Vector2(-20, -16)
	])
	board.add_child(formula)

	decor_root.add_child(board)

func _build_mountain_bunker_props() -> void:
	_add_rect_polygon(decor_root, Rect2(Vector2(-156, -54), Vector2(52, 30)), Color(0.16, 0.28, 0.34, 0.44))
	_add_rect_polygon(decor_root, Rect2(Vector2(-150, -48), Vector2(40, 18)), Color(0.28, 0.56, 0.64, 0.12))
	_add_rect_polygon(decor_root, Rect2(Vector2(112, 18), Vector2(44, 80)), Color(0.04, 0.04, 0.05, 0.2))
	_add_rect_polygon(decor_root, Rect2(Vector2(-142, 84), Vector2(64, 10)), Color(0.0, 0.0, 0.0, 0.16))
	_add_rect_polygon(decor_root, Rect2(Vector2(58, 72), Vector2(84, 12)), Color(0.0, 0.0, 0.0, 0.14))

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
	if room_key == "mountain_bunker":
		_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2((ROOM_RIGHT - ROOM_LEFT + 1) * 32, 70)))
		_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2(96, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)))
		_create_barrier(Rect2(Vector2(ROOM_RIGHT * 32 - 62, ROOM_TOP * 32), Vector2(96, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)))
		_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_BOTTOM * 32), Vector2(248, 32)))
		_create_barrier(Rect2(Vector2(104, ROOM_BOTTOM * 32), Vector2(216, 32)))
		return

	_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2((ROOM_RIGHT - ROOM_LEFT + 1) * 32, 64)))
	_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2(32, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)))
	_create_barrier(Rect2(Vector2(ROOM_RIGHT * 32, ROOM_TOP * 32), Vector2(32, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)))
	_create_barrier(Rect2(Vector2(ROOM_LEFT * 32, ROOM_BOTTOM * 32), Vector2(240, 32)))
	_create_barrier(Rect2(Vector2(112, ROOM_BOTTOM * 32), Vector2(208, 32)))

func _build_foreground() -> void:
	if room_key == "mountain_bunker":
		_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2((ROOM_RIGHT - ROOM_LEFT + 1) * 32, 36)), Color(0, 0, 0, 0.26))
		_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_LEFT * 32, ROOM_BOTTOM * 32 - 14), Vector2((ROOM_RIGHT - ROOM_LEFT + 1) * 32, 52)), Color(0, 0, 0, 0.16))
		_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_LEFT * 32, ROOM_TOP * 32), Vector2(96, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)), Color(0.01, 0.01, 0.02, 0.34))
		_add_rect_polygon(foreground_root, Rect2(Vector2(ROOM_RIGHT * 32 - 62, ROOM_TOP * 32), Vector2(96, (ROOM_BOTTOM - ROOM_TOP + 1) * 32)), Color(0.01, 0.01, 0.02, 0.34))
		return

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

func _create_floor_prop(name: String, texture: Texture2D, origin: Vector2, scale: Vector2) -> Node2D:
	var body := Node2D.new()
	body.name = name
	body.position = origin
	_add_shadow_to_node(body, Rect2(Vector2(-18, 8), Vector2(36, 10)), Color(0, 0, 0, 0.08))
	_add_loose_sprite(body, texture, Vector2.ZERO, scale)
	decor_root.add_child(body)
	return body

func _create_placeholder_standee(name: String, origin: Vector2, label_text: String, body_color: Color, accent_color: Color) -> Node2D:
	var standee := Node2D.new()
	standee.name = name
	standee.position = origin
	standee.z_index = 3
	_attach_placeholder_visual(standee, label_text, body_color, accent_color)
	entities.add_child(standee)
	return standee

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
	if room_key == "ufo_lab":
		var ufo_npc = NPC_SCENE.instantiate()
		ufo_npc.name = "AlbertEinsteinPlaceholder"
		ufo_npc.character_id = character_id
		ufo_npc.character_name = character_name
		ufo_npc.position = theme.get("npc_position", Vector2(-104, 22))
		ufo_npc.z_index = 4
		ufo_npc.interaction_distance = 82.0
		ufo_npc.indicator_distance = 132.0
		ufo_npc.set("patrol_range", 0.0)
		ufo_npc.set("patrol_speed", 0.0)
		var ufo_sprite := ufo_npc.get_node_or_null("Sprite2D") as Sprite2D
		if ufo_sprite:
			ufo_sprite.texture = null
			ufo_sprite.offset = Vector2(0, -18)
		entities.add_child(ufo_npc)
		_attach_placeholder_visual(ufo_npc, "EINSTEIN", Color(0.44, 0.42, 0.36, 0.98), Color(0.96, 0.88, 0.52, 0.94))

		var zuck_npc = NPC_SCENE.instantiate()
		zuck_npc.name = "MarkZuckerbergPlaceholder"
		zuck_npc.character_id = "mark_zuckerberg_ufo"
		zuck_npc.character_name = "Mark Zuckerberg"
		zuck_npc.position = Vector2(104, 34)
		zuck_npc.z_index = 4
		zuck_npc.set("patrol_range", 0.0)
		zuck_npc.set("patrol_speed", 0.0)
		zuck_npc.set("interaction_distance", 0.0)
		zuck_npc.set("indicator_distance", 0.0)
		var zuck_sprite := zuck_npc.get_node_or_null("Sprite2D") as Sprite2D
		if zuck_sprite:
			zuck_sprite.texture = null
			zuck_sprite.offset = Vector2(0, -18)
		if zuck_npc.has_method("set_interaction_enabled"):
			zuck_npc.set_interaction_enabled(false)
		zuck_npc.process_mode = Node.PROCESS_MODE_DISABLED
		entities.add_child(zuck_npc)
		_attach_placeholder_visual(zuck_npc, "ZUCK", Color(0.34, 0.44, 0.58, 0.98), Color(0.7, 0.96, 0.84, 0.94))

		room_npc = ufo_npc
		_refresh_encounter_density()
		return

	if room_key == "mountain_bunker":
		var zelensky = NPC_SCENE.instantiate()
		zelensky.name = "ZelenskyPlaceholder"
		zelensky.character_id = "hidden_bunker_scene"
		zelensky.character_name = "Zelensky"
		zelensky.position = Vector2(-60, 22)
		zelensky.z_index = 4
		zelensky.set("patrol_range", 0.0)
		zelensky.set("patrol_speed", 0.0)
		zelensky.set("interaction_distance", 0.0)
		zelensky.set("indicator_distance", 0.0)
		if zelensky.has_method("set_interaction_enabled"):
			zelensky.set_interaction_enabled(false)
		zelensky.process_mode = Node.PROCESS_MODE_DISABLED
		var zelensky_sprite := zelensky.get_node_or_null("Sprite2D") as Sprite2D
		if zelensky_sprite:
			zelensky_sprite.texture = null
			zelensky_sprite.offset = Vector2(0, -18)
		entities.add_child(zelensky)
		_attach_placeholder_visual(zelensky, "ZEL", Color(0.18, 0.22, 0.26, 0.98), Color(0.72, 0.78, 0.82, 0.9))

		var death = NPC_SCENE.instantiate()
		death.name = "DeathPlaceholder"
		death.character_id = "hidden_bunker_scene"
		death.character_name = "Death"
		death.position = Vector2(92, 4)
		death.z_index = 4
		death.set("patrol_range", 0.0)
		death.set("patrol_speed", 0.0)
		death.set("interaction_distance", 0.0)
		death.set("indicator_distance", 0.0)
		if death.has_method("set_interaction_enabled"):
			death.set_interaction_enabled(false)
		death.process_mode = Node.PROCESS_MODE_DISABLED
		var death_sprite := death.get_node_or_null("Sprite2D") as Sprite2D
		if death_sprite:
			death_sprite.texture = null
			death_sprite.offset = Vector2(0, -18)
		entities.add_child(death)
		_attach_death_visual(death)

		room_npc = zelensky
		return

	var npc = NPC_SCENE.instantiate()
	npc.name = "%sInterior" % character_name.replace(" ", "")
	npc.character_id = character_id
	npc.character_name = character_name
	npc.position = theme.get("npc_position", Vector2(0, 40))
	npc.z_index = 3
	entities.add_child(npc)
	room_npc = npc
	_refresh_encounter_density()

func _attach_placeholder_visual(parent: Node, label_text: String, body_color: Color, accent_color: Color) -> void:
	var shell := Node2D.new()
	shell.name = "PlaceholderVisual"

	_add_shadow_to_node(shell, Rect2(Vector2(-18, 8), Vector2(36, 10)), Color(0, 0, 0, 0.08))

	var body = Polygon2D.new()
	body.color = body_color
	body.polygon = PackedVector2Array([
		Vector2(-16, -10),
		Vector2(16, -10),
		Vector2(20, 22),
		Vector2(-20, 22)
	])
	shell.add_child(body)

	var head = Polygon2D.new()
	head.color = accent_color
	head.polygon = _make_ellipse(Vector2(0, -28), Vector2(26, 26), 14)
	shell.add_child(head)

	var shoulder = Polygon2D.new()
	shoulder.color = accent_color.darkened(0.18)
	shoulder.polygon = PackedVector2Array([
		Vector2(-22, -6),
		Vector2(22, -6),
		Vector2(16, 4),
		Vector2(-16, 4)
	])
	shell.add_child(shoulder)

	var plate = Polygon2D.new()
	plate.color = accent_color.lightened(0.2)
	plate.polygon = PackedVector2Array([
		Vector2(-30, -64),
		Vector2(30, -64),
		Vector2(26, -48),
		Vector2(-26, -48)
	])
	shell.add_child(plate)

	var tag = Label.new()
	tag.text = label_text
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", Color(0.08, 0.1, 0.12))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.position = Vector2(-28, -63)
	tag.size = Vector2(56, 16)
	shell.add_child(tag)

	parent.add_child(shell)

func _attach_death_visual(parent: Node) -> void:
	var shell := Node2D.new()
	shell.name = "PlaceholderVisual"

	_add_shadow_to_node(shell, Rect2(Vector2(-24, 10), Vector2(48, 10)), Color(0, 0, 0, 0.12))

	var robe := Polygon2D.new()
	robe.color = Color(0.03, 0.03, 0.04, 0.98)
	robe.polygon = PackedVector2Array([
		Vector2(-22, -6),
		Vector2(22, -6),
		Vector2(28, 34),
		Vector2(-28, 34)
	])
	shell.add_child(robe)

	var hood := Polygon2D.new()
	hood.color = Color(0.0, 0.0, 0.0, 0.98)
	hood.polygon = _make_ellipse(Vector2(0, -28), Vector2(28, 30), 16)
	shell.add_child(hood)

	var face_void := Polygon2D.new()
	face_void.color = Color(0.02, 0.02, 0.03, 0.98)
	face_void.polygon = PackedVector2Array([
		Vector2(-10, -34),
		Vector2(10, -34),
		Vector2(6, -12),
		Vector2(-6, -12)
	])
	shell.add_child(face_void)

	var scythe_pole := Line2D.new()
	scythe_pole.width = 4.0
	scythe_pole.default_color = Color(0.34, 0.32, 0.26, 0.98)
	scythe_pole.points = PackedVector2Array([Vector2(12, -54), Vector2(30, 38)])
	shell.add_child(scythe_pole)

	var scythe_blade := Polygon2D.new()
	scythe_blade.color = Color(0.72, 0.74, 0.78, 0.9)
	scythe_blade.polygon = PackedVector2Array([
		Vector2(2, -60),
		Vector2(28, -70),
		Vector2(40, -48),
		Vector2(16, -42)
	])
	shell.add_child(scythe_blade)

	var hammer_handle := Line2D.new()
	hammer_handle.width = 4.0
	hammer_handle.default_color = Color(0.34, 0.32, 0.26, 0.98)
	hammer_handle.points = PackedVector2Array([Vector2(-24, -10), Vector2(-38, 30)])
	shell.add_child(hammer_handle)

	var hammer_head := Polygon2D.new()
	hammer_head.color = Color(0.42, 0.44, 0.48, 0.9)
	hammer_head.polygon = PackedVector2Array([
		Vector2(-52, -14),
		Vector2(-26, -14),
		Vector2(-26, -2),
		Vector2(-52, -2)
	])
	shell.add_child(hammer_head)

	parent.add_child(shell)

func _create_ritual_station(name: String, origin: Vector2, station_id: String, visual: String, accent: Color) -> void:
	var station = StaticBody2D.new()
	station.name = name
	station.position = origin
	station.set_script(RITUAL_STATION_SCRIPT)
	station.set("station_id", station_id)
	station.set("station_name", name)
	station.set("station_visual", visual)
	station.set("accent_color", accent)
	station.set("room_ref", self)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(34, 42)
	col.shape = shape
	col.position = Vector2(0, -12)
	station.add_child(col)

	entities.add_child(station)
	ritual_stations[station_id] = station

func _spawn_vault_aftermath_notice(residue_id: String) -> void:
	var notice := Node2D.new()
	notice.name = "AftermathNotice"
	notice.position = Vector2(0, 126)
	var shadow = Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.08)
	shadow.polygon = PackedVector2Array([
		Vector2(-20, 8),
		Vector2(20, 8),
		Vector2(26, 18),
		Vector2(-26, 18)
	])
	notice.add_child(shadow)

	var sheet = Polygon2D.new()
	sheet.color = Color(0.94, 0.9, 0.76, 0.96)
	sheet.polygon = PackedVector2Array([
		Vector2(-18, -20),
		Vector2(16, -16),
		Vector2(20, 18),
		Vector2(-14, 14)
	])
	notice.add_child(sheet)

	var stamp = Polygon2D.new()
	stamp.color = Color(0.86, 0.66, 0.24, 0.92) if residue_id == "adjustment_invoice" else Color(0.76, 0.22, 0.18, 0.92)
	stamp.polygon = _make_ellipse(Vector2(8, -2), Vector2(14, 14), 12)
	notice.add_child(stamp)

	var rule_a = Polygon2D.new()
	rule_a.color = Color(0.42, 0.38, 0.3, 0.38)
	rule_a.polygon = PackedVector2Array([
		Vector2(-10, -8),
		Vector2(8, -6),
		Vector2(8, -2),
		Vector2(-10, -4)
	])
	notice.add_child(rule_a)

	var rule_b = Polygon2D.new()
	rule_b.color = Color(0.42, 0.38, 0.3, 0.32)
	rule_b.polygon = PackedVector2Array([
		Vector2(-8, 0),
		Vector2(10, 2),
		Vector2(10, 5),
		Vector2(-8, 3)
	])
	notice.add_child(rule_b)

	decor_root.add_child(notice)

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
	door.set("prompt_name", "Beam Out" if room_key == "ufo_lab" else "Exit")
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
	if room_key == "mountain_bunker":
		var approach := markers.get_node_or_null("ApproachMarker") as Marker2D
		if approach == null:
			approach = Marker2D.new()
			approach.name = "ApproachMarker"
			markers.add_child(approach)
		approach.position = theme.get("approach_position", Vector2(0, 118))

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
