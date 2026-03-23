extends Node2D

@onready var ground_map: TileMap = $GroundMap
@onready var player: CharacterBody2D = $Entities/Player
@onready var ui_layer: CanvasLayer = $UI

var character_data_cache: Dictionary = {}
var is_dialogue_open: bool = false

# --- Dialogue UI (created in code) ---
var dialogue_anchor: Control
var dialogue_panel: PanelContainer
var dialogue_style: StyleBoxFlat
var portrait_rect: TextureRect
var name_label: Label
var text_label: RichTextLabel
var continue_label: Label
var typewriter_timer: Timer
var typewriter_text: String = ""
var typewriter_index: int = 0
var continue_blink: float = 0.0
var dialogue_rest_top: float = -195.0
var current_character_id: String = ""

# --- HUD ---
var hud_panel: PanelContainer
var meter_bars: Dictionary = {}
var meter_values: Dictionary = {
	"TIME": 100, "ACCESS": 100, "TRUST": 100, "RENT": 0, "STRESS": 0
}

# --- Tile sources ---
# Source 0 = procedural world_tiles.png (buildings, furniture, fallback)
# Source 1 = nature_32.png   (trees, bushes, flowers, rocks)
# Source 2 = field_32.png    (grass)
# Source 3 = water_32.png    (water)
# Source 4 = floor_32.png    (paths and floors)
const SRC_PROC := 0
const SRC_NATURE := 1
const SRC_FIELD := 2
const SRC_WATER := 3
const SRC_FLOOR := 4
const SRC_INTERIOR_FLOOR := 5

const LAYER_GROUND := 0
const LAYER_DECOR := 1
const LAYER_STRUCT := 2

const WORLD_MIN_X := -60
const WORLD_MAX_X := 60
const WORLD_MIN_Y := -50
const WORLD_MAX_Y := 50
const BUILDING_CLEARANCE := 10
const PATH_HALF_WIDTH := 1

var _pack_sources: Dictionary = {
	SRC_NATURE: "res://assets/tiles/nature_32.png",
	SRC_FIELD: "res://assets/tiles/field_32.png",
	SRC_WATER: "res://assets/tiles/water_32.png",
	SRC_FLOOR: "res://assets/tiles/floor_32.png",
	SRC_INTERIOR_FLOOR: "res://assets/tiles/interior_floor_32.png",
}
var _pack_ready: bool = false
var _path_cells: Dictionary = {}
var _solid_positions: Dictionary = {}

# --- Procedural atlas tiles (source 0 — fallback & buildings) ---
const TILE_GRASS = Vector2i(0, 0)
const TILE_WOOD = Vector2i(1, 0)
const TILE_PATH = Vector2i(2, 0)
const TILE_WATER = Vector2i(3, 0)

const TILE_BRICK = Vector2i(0, 1)
const TILE_METAL_FLOOR = Vector2i(1, 1)
const TILE_METAL_WALL = Vector2i(2, 1)
const TILE_VAULT_WALL = Vector2i(3, 1)

const TILE_KREMLIN_WALL = Vector2i(0, 2)
const TILE_MARBLE_FLOOR = Vector2i(1, 2)
const TILE_MARBLE_WALL = Vector2i(2, 2)

const TILE_TREE_TOP = Vector2i(0, 3)
const TILE_TREE_TRUNK = Vector2i(1, 3)
const TILE_BUSH = Vector2i(2, 3)
const TILE_DESK_WOOD = Vector2i(3, 3)

const TILE_DESK_METAL = Vector2i(0, 4)
const TILE_SERVER = Vector2i(1, 4)
const TILE_BOOKSHELF = Vector2i(2, 4)
const TILE_GOLD = Vector2i(3, 4)
const TILE_FLAG = Vector2i(4, 4)
const TILE_FILE_CABINET_WIDE = Vector2i(0, 4)
const TILE_FILE_CABINET = Vector2i(5, 4)
const TILE_PLANT = Vector2i(6, 4)
const TILE_CLOCK = Vector2i(7, 4)
const TILE_WINDOW = Vector2i(6, 2)
const TILE_COLUMN = Vector2i(6, 6)
const TILE_GLOBE = Vector2i(7, 6)

# --- Pack tile coordinates (when _pack_ready) ---
const NT_BUSH := Vector2i(8, 5)
const FD_GRASS := Vector2i(1, 4)
const FD_GRASS2 := Vector2i(3, 4)
const WT_WATER := Vector2i(3, 2)
const FL_STONE := Vector2i(2, 9)
const FL_WOOD := Vector2i(2, 4)
const IF_OFFICE := Vector2i(4, 4)
const IF_PALACE := Vector2i(14, 4)
const IF_VAULT := Vector2i(15, 13)

var tree_variants: Array = [
	{
		"size": Vector2i(2, 2),
		"tiles": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"solid_offset": Vector2i(0, 1)
	},
	{
		"size": Vector2i(2, 2),
		"tiles": [Vector2i(2, 18), Vector2i(3, 18), Vector2i(2, 19), Vector2i(3, 19)],
		"solid_offset": Vector2i(0, 1)
	},
	{
		"size": Vector2i(2, 2),
		"tiles": [Vector2i(0, 18), Vector2i(1, 18), Vector2i(0, 19), Vector2i(1, 19)],
		"solid_offset": Vector2i(0, 1)
	},
	{
		"size": Vector2i(2, 2),
		"tiles": [Vector2i(9, 18), Vector2i(10, 18), Vector2i(9, 19), Vector2i(10, 19)],
		"solid_offset": Vector2i(0, 1)
	}
]
var flower_tiles: Array = [
	Vector2i(0, 10), Vector2i(1, 10), Vector2i(2, 10), Vector2i(5, 10), Vector2i(6, 10)
]
var tuft_tiles: Array = [
	Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10), Vector2i(10, 10), Vector2i(11, 10),
	Vector2i(0, 11), Vector2i(1, 11), Vector2i(4, 11), Vector2i(5, 11)
]
var rock_tiles: Array = [
	Vector2i(2, 12), Vector2i(3, 12), Vector2i(4, 12), Vector2i(5, 12),
	Vector2i(2, 13), Vector2i(3, 13), Vector2i(4, 13)
]

var building_specs: Array = [
	{
		"key": "oval_office",
		"npc": "donald_trump",
		"center": Vector2i(20, -20),
		"npc_spawn": Vector2i(20, -18),
		"entrance": Vector2i(20, -15),
		"light_color": Color(1.0, 0.85, 0.6)
	},
	{
		"key": "spaceship",
		"npc": "elon_musk",
		"center": Vector2i(-20, -20),
		"npc_spawn": Vector2i(-20, -18),
		"entrance": Vector2i(-20, -15),
		"light_color": Color(0.6, 0.8, 1.0)
	},
	{
		"key": "eu_palace",
		"npc": "ursula_von_der_leyen",
		"center": Vector2i(20, 0),
		"npc_spawn": Vector2i(20, 2),
		"entrance": Vector2i(20, 6),
		"light_color": Color(0.7, 0.75, 1.0)
	},
	{
		"key": "kremlin",
		"npc": "vladimir_putin",
		"center": Vector2i(-20, 0),
		"npc_spawn": Vector2i(-20, 2),
		"entrance": Vector2i(-20, 5),
		"light_color": Color(0.9, 0.7, 0.5)
	},
	{
		"key": "vault",
		"npc": "christine_lagarde",
		"center": Vector2i(20, 20),
		"npc_spawn": Vector2i(20, 22),
		"entrance": Vector2i(20, 26),
		"light_color": Color(1.0, 0.9, 0.6)
	},
	{
		"key": "elysee",
		"npc": "emmanuel_macron",
		"center": Vector2i(-20, 20),
		"npc_spawn": Vector2i(-20, 22),
		"entrance": Vector2i(-20, 26),
		"light_color": Color(0.75, 0.8, 1.0)
	}
]

# --- Character visual config ---
var character_colors: Dictionary = {
	"donald_trump": Color(0.82, 0.22, 0.18),
	"elon_musk": Color(0.28, 0.48, 0.72),
	"ursula_von_der_leyen": Color(0.18, 0.28, 0.58),
	"christine_lagarde": Color(0.22, 0.22, 0.38),
	"vladimir_putin": Color(0.52, 0.18, 0.18),
	"emmanuel_macron": Color(0.18, 0.22, 0.58)
}
var portrait_paths: Dictionary = {
	"donald_trump": "res://assets/mockups/trump_caricature.png",
	"elon_musk": "res://assets/mockups/musk_caricature.png",
	"ursula_von_der_leyen": "res://assets/mockups/vdleyen_caricature.png",
	"christine_lagarde": "res://assets/mockups/lagarde_caricature.png",
	"vladimir_putin": "res://assets/mockups/putin_caricature.png",
	"emmanuel_macron": "res://assets/mockups/macron_caricature.png"
}
var npc_sprite_paths: Dictionary = {
	"donald_trump": "res://assets/mockups/trump_true_pixel.png",
	"elon_musk": "res://assets/mockups/musk_pure_sprite.png",
	"ursula_von_der_leyen": "res://assets/mockups/vdl_pure_sprite.png",
	"christine_lagarde": "res://assets/mockups/lagarde_pure_sprite.png",
	"vladimir_putin": "res://assets/mockups/putin_pure_sprite.png",
	"emmanuel_macron": "res://assets/mockups/macron_pure_sprite.png"
}
var npc_facing_defaults: Dictionary = {
	"donald_trump": false,
	"elon_musk": false,
	"ursula_von_der_leyen": false,
	"christine_lagarde": false,
	"vladimir_putin": true,
	"emmanuel_macron": false
}

# --- Meter visual config ---
var meter_config: Dictionary = {
	"TIME":   {"color": Color(0.3, 0.72, 0.72), "initial": 100},
	"ACCESS": {"color": Color(0.3, 0.72, 0.3),  "initial": 100},
	"TRUST":  {"color": Color(0.72, 0.65, 0.3), "initial": 100},
	"RENT":   {"color": Color(0.72, 0.45, 0.3), "initial": 0},
	"STRESS": {"color": Color(0.72, 0.3, 0.3),  "initial": 0},
}


# ============================================================
#  SETUP
# ============================================================

func _ready() -> void:
	# Remove old dialogue box from scene (if present)
	var old_box = get_node_or_null("UI/DialogueBox")
	if old_box:
		old_box.queue_free()

	_setup_tileset_sources()
	_generate_world_layout()
	_load_character_data()
	_assign_npc_textures()
	_setup_world_lighting()
	_create_screen_fx()
	_create_hud()
	_create_dialogue_ui()

func _setup_tileset_sources() -> void:
	var tileset := ground_map.tile_set
	while ground_map.get_layers_count() <= LAYER_STRUCT:
		ground_map.add_layer(-1)
	ground_map.set_layer_z_index(LAYER_DECOR, 1)
	ground_map.set_layer_z_index(LAYER_STRUCT, 2)

	# Register each pack tileset as an additional TileSetAtlasSource
	for src_id in _pack_sources:
		if tileset.has_source(src_id):
			continue
		var path: String = _pack_sources[src_id]
		if not ResourceLoader.exists(path):
			push_warning("Pack tileset not imported yet: %s — using procedural fallback" % path)
			continue
		var tex = load(path) as Texture2D
		if not tex:
			continue
		var source = TileSetAtlasSource.new()
		source.texture = tex
		source.texture_region_size = Vector2i(32, 32)
		# Register every tile position in the atlas
		var cols = int(tex.get_width() / 32)
		var rows = int(tex.get_height() / 32)
		for ty in range(rows):
			for tx in range(cols):
				source.create_tile(Vector2i(tx, ty))
		tileset.add_source(source, src_id)

	_pack_ready = (
		tileset.has_source(SRC_NATURE)
		and tileset.has_source(SRC_FIELD)
		and tileset.has_source(SRC_WATER)
		and tileset.has_source(SRC_FLOOR)
	)

func _process(delta: float) -> void:
	if is_dialogue_open:
		# Blink continue indicator
		if continue_label.visible:
			continue_blink += delta * 3.0
			continue_label.modulate.a = 0.4 + sin(continue_blink) * 0.4

		if Input.is_action_just_pressed("ui_accept"):
			if typewriter_index < typewriter_text.length():
				# Skip to full text
				typewriter_timer.stop()
				text_label.text = typewriter_text
				typewriter_index = typewriter_text.length()
				continue_label.visible = true
			else:
				_close_dialogue()


# ============================================================
#  WORLD GENERATION
# ============================================================

func _is_in_building_zone(x: int, y: int) -> bool:
	for spec in building_specs:
		var center: Vector2i = spec["center"]
		if abs(x - center.x) <= BUILDING_CLEARANCE and abs(y - center.y) <= BUILDING_CLEARANCE:
			return true
	return false

func _is_on_path(x: int, y: int) -> bool:
	return _path_cells.has(Vector2i(x, y))

func _rebuild_path_cache() -> void:
	_path_cells.clear()

	var min_y := 9999
	var max_y := -9999
	for spec in building_specs:
		var entrance: Vector2i = spec["entrance"]
		min_y = min(min_y, entrance.y)
		max_y = max(max_y, entrance.y)
		_mark_path_line(Vector2i(0, entrance.y), entrance, PATH_HALF_WIDTH)
		_mark_path_rect(entrance - Vector2i(1, 1), entrance + Vector2i(1, 1))

	_mark_path_line(Vector2i(0, min_y), Vector2i(0, max_y), PATH_HALF_WIDTH)

func _mark_path_line(a: Vector2i, b: Vector2i, half_width: int = 1) -> void:
	if a.x == b.x:
		for y in range(min(a.y, b.y), max(a.y, b.y) + 1):
			for dx in range(-half_width, half_width + 1):
				_path_cells[Vector2i(a.x + dx, y)] = true
	elif a.y == b.y:
		for x in range(min(a.x, b.x), max(a.x, b.x) + 1):
			for dy in range(-half_width, half_width + 1):
				_path_cells[Vector2i(x, a.y + dy)] = true

func _mark_path_rect(top_left: Vector2i, bottom_right: Vector2i) -> void:
	for x in range(top_left.x, bottom_right.x + 1):
		for y in range(top_left.y, bottom_right.y + 1):
			_path_cells[Vector2i(x, y)] = true

func _tile_roll(x: int, y: int) -> int:
	return posmod(x * 92821 + y * 68917 + 7919, 1000)

func _grass_tile_for(pos: Vector2i) -> Vector2i:
	if not _pack_ready:
		return TILE_GRASS
	return FD_GRASS2 if _tile_roll(pos.x, pos.y) < 180 else FD_GRASS

func _path_tile_for(pos: Vector2i) -> Vector2i:
	if not _pack_ready:
		return TILE_PATH
	return FL_STONE

func _can_use_world_cell(pos: Vector2i) -> bool:
	return (
		pos.x >= WORLD_MIN_X
		and pos.x < WORLD_MAX_X
		and pos.y >= WORLD_MIN_Y
		and pos.y < WORLD_MAX_Y
		and not _is_in_building_zone(pos.x, pos.y)
		and not _is_on_path(pos.x, pos.y)
	)

func _can_place_decoration(top_left: Vector2i, size: Vector2i) -> bool:
	for dx in range(size.x):
		for dy in range(size.y):
			var pos := top_left + Vector2i(dx, dy)
			if not _can_use_world_cell(pos):
				return false
			if ground_map.get_cell_source_id(LAYER_DECOR, pos) != -1:
				return false
			if ground_map.get_cell_source_id(LAYER_STRUCT, pos) != -1:
				return false
	return true

func _stamp_multitile(layer: int, top_left: Vector2i, source_id: int, size: Vector2i, tiles: Array) -> void:
	var index := 0
	for dy in range(size.y):
		for dx in range(size.x):
			ground_map.set_cell(layer, top_left + Vector2i(dx, dy), source_id, tiles[index])
			index += 1

func _generate_world_layout() -> void:
	_rebuild_path_cache()

	var grass_source := SRC_FIELD if _pack_ready else SRC_PROC
	var water_source := SRC_WATER if _pack_ready else SRC_PROC
	var path_source := SRC_FLOOR if _pack_ready else SRC_PROC

	for x in range(WORLD_MIN_X, WORLD_MAX_X):
		for y in range(WORLD_MIN_Y, WORLD_MAX_Y):
			var pos := Vector2i(x, y)
			ground_map.set_cell(LAYER_GROUND, pos, grass_source, _grass_tile_for(pos))

	for cell in _path_cells.keys():
		var path_pos: Vector2i = cell
		ground_map.set_cell(LAYER_GROUND, path_pos, path_source, _path_tile_for(path_pos))

	for spec in building_specs:
		_build_structure(spec)
		_decorate_compound(spec)
		var spawn: Vector2i = spec["npc_spawn"] if spec.has("npc_spawn") else spec["center"]
		_snap_npc_to_house(spec["npc"], spawn.x, spawn.y)

	for x in range(WORLD_MIN_X + 2, WORLD_MAX_X - 2):
		for y in range(WORLD_MIN_Y + 2, WORLD_MAX_Y - 2):
			if _is_in_building_zone(x, y) or _is_on_path(x, y):
				continue

			var roll := _tile_roll(x, y)
			var pos := Vector2i(x, y)
			if roll < 2:
				_paint_lake(pos, water_source, WT_WATER if _pack_ready else TILE_WATER)
			elif roll < 10:
				_place_tree(pos)
			elif roll < 26:
				_place_bush(pos)
			elif roll < 34:
				_place_flower(pos)
			elif roll < 40:
				_place_rock(pos)

func _paint_lake(center: Vector2i, src: int = SRC_PROC, coords: Vector2i = TILE_WATER) -> void:
	for x in range(center.x - 2, center.x + 3):
		for y in range(center.y - 1, center.y + 3):
			if abs(x - center.x) + abs(y - center.y) > 3:
				continue
			var pos := Vector2i(x, y)
			if not _can_use_world_cell(pos):
				return
			if ground_map.get_cell_source_id(LAYER_DECOR, pos) != -1:
				return

	for x in range(center.x - 2, center.x + 3):
		for y in range(center.y - 1, center.y + 3):
			if abs(x - center.x) + abs(y - center.y) <= 3:
				ground_map.set_cell(LAYER_GROUND, Vector2i(x, y), src, coords)
				_create_solid_wall(x, y)

func _place_tree(pos: Vector2i) -> void:
	if _pack_ready:
		var variant: Dictionary = tree_variants[_tile_roll(pos.x + 13, pos.y - 7) % tree_variants.size()]
		var size: Vector2i = variant["size"]
		if not _can_place_decoration(pos, size):
			return
		_stamp_multitile(LAYER_DECOR, pos, SRC_NATURE, size, variant["tiles"])
		var solid_offset: Vector2i = variant["solid_offset"]
		_create_solid_wall(pos.x + solid_offset.x, pos.y + solid_offset.y)
	else:
		if not _can_place_decoration(pos, Vector2i(1, 2)):
			return
		ground_map.set_cell(LAYER_DECOR, pos, SRC_PROC, TILE_TREE_TOP)
		ground_map.set_cell(LAYER_DECOR, pos + Vector2i(0, 1), SRC_PROC, TILE_TREE_TRUNK)
		_create_solid_wall(pos.x, pos.y + 1)

func _place_bush(pos: Vector2i) -> void:
	if not _can_place_decoration(pos, Vector2i(1, 1)):
		return
	if _pack_ready:
		var choices := [NT_BUSH] + tuft_tiles
		var atlas: Vector2i = choices[_tile_roll(pos.x - 9, pos.y + 5) % choices.size()]
		ground_map.set_cell(LAYER_DECOR, pos, SRC_NATURE, atlas)
	else:
		ground_map.set_cell(LAYER_DECOR, pos, SRC_PROC, TILE_BUSH)

func _place_flower(pos: Vector2i) -> void:
	if not _pack_ready or not _can_place_decoration(pos, Vector2i(1, 1)):
		return
	var atlas: Vector2i = flower_tiles[_tile_roll(pos.x + 3, pos.y + 17) % flower_tiles.size()]
	ground_map.set_cell(LAYER_DECOR, pos, SRC_NATURE, atlas)

func _place_rock(pos: Vector2i) -> void:
	if not _pack_ready or not _can_place_decoration(pos, Vector2i(1, 1)):
		return
	var atlas: Vector2i = rock_tiles[_tile_roll(pos.x - 15, pos.y - 19) % rock_tiles.size()]
	ground_map.set_cell(LAYER_DECOR, pos, SRC_NATURE, atlas)
	_create_solid_wall(pos.x, pos.y)

func _snap_npc_to_house(cid: String, tx: int, ty: int) -> void:
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.character_id == cid:
			npc.position = Vector2(tx * 32 + 16, ty * 32)
			break

func _create_solid_wall(x: int, y: int) -> void:
	var cell := Vector2i(x, y)
	if _solid_positions.has(cell):
		return
	_solid_positions[cell] = true

	var wall = StaticBody2D.new()
	wall.position = Vector2(x * 32 + 16, y * 32 + 16)
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(32, 32)
	col.shape = rect
	wall.add_child(col)
	$GroundMap.add_child(wall)


# ============================================================
#  BUILDING BUILDERS
# ============================================================

func _build_structure(spec: Dictionary) -> void:
	var center: Vector2i = spec["center"]
	match spec["key"]:
		"oval_office":
			_build_oval_office(center)
		"spaceship":
			_build_spaceship(center)
		"eu_palace":
			_build_eu_palace(center)
		"kremlin":
			_build_kremlin(center)
		"vault":
			_build_vault(center)
		"elysee":
			_build_elysee(center)

func _set_floor_tile(pos: Vector2i, style: String) -> void:
	var has_interior_floor := ground_map.tile_set.has_source(SRC_INTERIOR_FLOOR)
	match style:
		"wood":
			if has_interior_floor:
				ground_map.set_cell(LAYER_GROUND, pos, SRC_INTERIOR_FLOOR, IF_OFFICE)
			elif _pack_ready:
				ground_map.set_cell(LAYER_GROUND, pos, SRC_FLOOR, FL_WOOD)
			else:
				ground_map.set_cell(LAYER_GROUND, pos, SRC_PROC, TILE_WOOD)
		"palace":
			if has_interior_floor:
				ground_map.set_cell(LAYER_GROUND, pos, SRC_INTERIOR_FLOOR, IF_PALACE)
			elif _pack_ready:
				ground_map.set_cell(LAYER_GROUND, pos, SRC_FLOOR, FL_WOOD)
			else:
				ground_map.set_cell(LAYER_GROUND, pos, SRC_PROC, TILE_MARBLE_FLOOR)
		"vault":
			if has_interior_floor:
				ground_map.set_cell(LAYER_GROUND, pos, SRC_INTERIOR_FLOOR, IF_VAULT)
			elif _pack_ready:
				ground_map.set_cell(LAYER_GROUND, pos, SRC_FLOOR, FL_WOOD)
			else:
				ground_map.set_cell(LAYER_GROUND, pos, SRC_PROC, TILE_METAL_FLOOR)
		"stone":
			if _pack_ready:
				ground_map.set_cell(LAYER_GROUND, pos, SRC_FLOOR, FL_STONE)
			else:
				ground_map.set_cell(LAYER_GROUND, pos, SRC_PROC, TILE_MARBLE_FLOOR)
		"metal":
			ground_map.set_cell(LAYER_GROUND, pos, SRC_PROC, TILE_METAL_FLOOR)
		_:
			ground_map.set_cell(LAYER_GROUND, pos, SRC_PROC, TILE_WOOD)

func _set_structure_tile(pos: Vector2i, coords: Vector2i, solid: bool = false, source_id: int = SRC_PROC) -> void:
	ground_map.set_cell(LAYER_STRUCT, pos, source_id, coords)
	if solid:
		_create_solid_wall(pos.x, pos.y)

func _set_decor_tile(pos: Vector2i, coords: Vector2i, solid: bool = false) -> void:
	if not _pack_ready:
		return
	if pos.x < WORLD_MIN_X or pos.x >= WORLD_MAX_X or pos.y < WORLD_MIN_Y or pos.y >= WORLD_MAX_Y:
		return
	if _is_on_path(pos.x, pos.y):
		return
	if ground_map.get_cell_source_id(LAYER_STRUCT, pos) != -1:
		return
	if ground_map.get_cell_source_id(LAYER_DECOR, pos) != -1:
		return
	ground_map.set_cell(LAYER_DECOR, pos, SRC_NATURE, coords)
	if solid:
		_create_solid_wall(pos.x, pos.y)

func _decorate_flower_bed(start: Vector2i, width: int) -> void:
	for i in range(width):
		var pos := start + Vector2i(i, 0)
		var atlas: Vector2i = flower_tiles[i % flower_tiles.size()]
		_set_decor_tile(pos, atlas)
		if i % 2 == 0:
			_set_decor_tile(pos + Vector2i(0, -1), NT_BUSH)

func _decorate_rock_bed(start: Vector2i, width: int) -> void:
	for i in range(width):
		var pos := start + Vector2i(i, 0)
		var atlas: Vector2i = rock_tiles[i % rock_tiles.size()]
		_set_decor_tile(pos, atlas, true)
		if i % 2 == 0:
			var tuft: Vector2i = tuft_tiles[i % tuft_tiles.size()]
			_set_decor_tile(pos + Vector2i(0, -1), tuft)

func _decorate_compound(spec: Dictionary) -> void:
	if not _pack_ready:
		return

	var center: Vector2i = spec["center"]
	var entrance: Vector2i = spec["entrance"]
	match spec["key"]:
		"oval_office", "eu_palace", "elysee":
			_decorate_flower_bed(entrance + Vector2i(-6, 1), 3)
			_decorate_flower_bed(entrance + Vector2i(4, 1), 3)
			_set_decor_tile(center + Vector2i(-6, -4), NT_BUSH)
			_set_decor_tile(center + Vector2i(6, -4), NT_BUSH)
		"spaceship", "kremlin", "vault":
			_decorate_rock_bed(entrance + Vector2i(-6, 1), 3)
			_decorate_rock_bed(entrance + Vector2i(4, 1), 3)
			_set_decor_tile(center + Vector2i(-6, -4), tuft_tiles[0])
			_set_decor_tile(center + Vector2i(6, -4), tuft_tiles[1])

func _build_rect_building(center: Vector2i, half_size: Vector2i, floor_style: String, wall_tile: Vector2i, door_half_width: int = 2, cut_corners: bool = false) -> void:
	for x in range(center.x - half_size.x, center.x + half_size.x + 1):
		for y in range(center.y - half_size.y, center.y + half_size.y + 1):
			var dx: int = abs(x - center.x)
			var dy: int = abs(y - center.y)
			if cut_corners and dx == half_size.x and dy == half_size.y:
				continue

			var pos := Vector2i(x, y)
			_set_floor_tile(pos, floor_style)

			var is_border: bool = dx == half_size.x or dy == half_size.y
			var is_door: bool = y == center.y + half_size.y and dx <= door_half_width
			if is_border and not is_door:
				_set_structure_tile(pos, wall_tile, true)

func _build_oval_office(center: Vector2i) -> void:
	for x in range(center.x - 5, center.x + 6):
		for y in range(center.y - 4, center.y + 5):
			var xr = pow(float(x - center.x) / 5.0, 2)
			var yr = pow(float(y - center.y) / 4.0, 2)
			if xr + yr <= 1.0:
				var pos := Vector2i(x, y)
				_set_floor_tile(pos, "wood")
				if xr + yr > 0.7 and not (y == center.y + 4 and abs(x - center.x) <= 2):
					_set_structure_tile(pos, TILE_BRICK, true)
	_set_structure_tile(Vector2i(center.x - 2, center.y - 3), TILE_WINDOW)
	_set_structure_tile(Vector2i(center.x, center.y - 3), TILE_WINDOW)
	_set_structure_tile(Vector2i(center.x + 2, center.y - 3), TILE_WINDOW)
	_set_structure_tile(Vector2i(center.x - 4, center.y - 2), TILE_COLUMN, true)
	_set_structure_tile(Vector2i(center.x + 4, center.y - 2), TILE_COLUMN, true)
	_set_structure_tile(Vector2i(center.x - 4, center.y + 2), TILE_GLOBE)
	_set_structure_tile(Vector2i(center.x + 4, center.y + 2), TILE_GOLD, true)
	_set_structure_tile(Vector2i(center.x - 1, center.y - 2), TILE_DESK_WOOD, true)
	_set_structure_tile(Vector2i(center.x, center.y - 2), TILE_DESK_WOOD, true)
	_set_structure_tile(Vector2i(center.x + 1, center.y - 2), TILE_DESK_WOOD, true)

func _build_spaceship(center: Vector2i) -> void:
	_build_rect_building(center, Vector2i(5, 4), "metal", TILE_METAL_WALL)
	_set_structure_tile(Vector2i(center.x - 3, center.y - 2), TILE_SERVER, true)
	_set_structure_tile(Vector2i(center.x + 3, center.y - 2), TILE_SERVER, true)
	_set_structure_tile(Vector2i(center.x - 4, center.y + 1), TILE_SERVER, true)
	_set_structure_tile(Vector2i(center.x + 4, center.y + 1), TILE_SERVER, true)
	_set_structure_tile(Vector2i(center.x + 2, center.y - 2), TILE_GLOBE)
	_set_structure_tile(Vector2i(center.x, center.y - 2), TILE_DESK_METAL, true)

func _build_eu_palace(center: Vector2i) -> void:
	_build_rect_building(center, Vector2i(5, 5), "palace", TILE_MARBLE_WALL, 2, true)
	_set_structure_tile(Vector2i(center.x - 1, center.y - 4), TILE_BOOKSHELF, true)
	_set_structure_tile(Vector2i(center.x, center.y - 4), TILE_BOOKSHELF, true)
	_set_structure_tile(Vector2i(center.x + 1, center.y - 4), TILE_BOOKSHELF, true)
	_set_structure_tile(Vector2i(center.x - 4, center.y - 3), TILE_FILE_CABINET, true)
	_set_structure_tile(Vector2i(center.x + 4, center.y - 3), TILE_FILE_CABINET, true)
	_set_structure_tile(Vector2i(center.x + 2, center.y - 2), TILE_CLOCK)
	_set_structure_tile(Vector2i(center.x - 4, center.y + 2), TILE_PLANT)
	_set_structure_tile(Vector2i(center.x, center.y - 2), TILE_DESK_WOOD, true)
	_set_structure_tile(Vector2i(center.x + 4, center.y + 2), TILE_PLANT)

func _build_elysee(center: Vector2i) -> void:
	_build_rect_building(center, Vector2i(5, 5), "palace", TILE_MARBLE_WALL, 2, true)
	_set_structure_tile(Vector2i(center.x - 4, center.y - 3), TILE_COLUMN, true)
	_set_structure_tile(Vector2i(center.x + 4, center.y - 3), TILE_COLUMN, true)
	_set_structure_tile(Vector2i(center.x, center.y - 4), TILE_BOOKSHELF, true)
	_set_structure_tile(Vector2i(center.x - 2, center.y - 2), TILE_CLOCK)
	_set_structure_tile(Vector2i(center.x - 4, center.y + 2), TILE_PLANT)
	_set_structure_tile(Vector2i(center.x, center.y - 2), TILE_DESK_WOOD, true)
	_set_structure_tile(Vector2i(center.x + 4, center.y + 2), TILE_PLANT)

func _build_kremlin(center: Vector2i) -> void:
	_build_rect_building(center, Vector2i(5, 4), "wood", TILE_KREMLIN_WALL)
	_set_structure_tile(Vector2i(center.x, center.y - 3), TILE_FLAG)
	_set_structure_tile(Vector2i(center.x - 4, center.y - 2), TILE_FILE_CABINET_WIDE, true)
	_set_structure_tile(Vector2i(center.x + 4, center.y - 2), TILE_FILE_CABINET, true)
	_set_structure_tile(Vector2i(center.x - 1, center.y - 2), TILE_DESK_WOOD, true)
	_set_structure_tile(Vector2i(center.x, center.y - 2), TILE_DESK_WOOD, true)
	_set_structure_tile(Vector2i(center.x + 1, center.y - 2), TILE_DESK_WOOD, true)

func _build_vault(center: Vector2i) -> void:
	_build_rect_building(center, Vector2i(5, 5), "vault", TILE_VAULT_WALL)
	_set_structure_tile(Vector2i(center.x, center.y - 3), TILE_FILE_CABINET_WIDE, true)
	_set_structure_tile(Vector2i(center.x - 3, center.y - 3), TILE_GOLD, true)
	_set_structure_tile(Vector2i(center.x - 2, center.y - 3), TILE_GOLD, true)
	_set_structure_tile(Vector2i(center.x + 2, center.y - 3), TILE_GOLD, true)
	_set_structure_tile(Vector2i(center.x + 3, center.y - 3), TILE_GOLD, true)
	_set_structure_tile(Vector2i(center.x - 4, center.y + 1), TILE_FILE_CABINET, true)
	_set_structure_tile(Vector2i(center.x + 4, center.y + 1), TILE_FILE_CABINET, true)
	_set_structure_tile(Vector2i(center.x - 3, center.y - 1), TILE_DESK_METAL, true)
	_set_structure_tile(Vector2i(center.x + 3, center.y - 1), TILE_DESK_METAL, true)


# ============================================================
#  WORLD LIGHTING
# ============================================================

func _setup_world_lighting() -> void:
	# Very subtle cold tint — avoid washing out the pixel art
	var canvas_mod = CanvasModulate.new()
	canvas_mod.color = Color(0.95, 0.96, 0.98)
	add_child(canvas_mod)

	# Warm lights at each building entrance
	for spec in building_specs:
		_add_point_light(spec["entrance"], spec["light_color"])

func _add_point_light(tile_pos: Vector2i, color: Color) -> void:
	var light = PointLight2D.new()
	light.position = Vector2(tile_pos.x * 32 + 16, tile_pos.y * 32 + 16)
	light.color = color
	light.energy = 0.7
	light.texture_scale = 3.5

	# Programmatic radial gradient texture
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

	$Entities.add_child(light)


# ============================================================
#  DATA & TEXTURES
# ============================================================

func _load_character_data() -> void:
	var path := "res://data/characters.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			if data is Array:
				for entry in data:
					character_data_cache[entry["id"]] = entry

func _assign_npc_textures() -> void:
	for npc in get_tree().get_nodes_in_group("npc"):
		var cid: String = npc.character_id
		npc.faces_right_by_default = bool(npc_facing_defaults.get(cid, false))
		if not npc_sprite_paths.has(cid):
			continue
		var sprite := npc.get_node_or_null("Sprite2D") as Sprite2D
		var sprite_path: String = npc_sprite_paths[cid]
		if sprite and ResourceLoader.exists(sprite_path):
			sprite.texture = load(sprite_path)


# ============================================================
#  SCREEN FX (CRT Shader)
# ============================================================

func _create_screen_fx() -> void:
	var fx_rect = ColorRect.new()
	fx_rect.name = "ScreenFX"
	fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	var shader_res = load("res://shaders/screen_pixel_fx.gdshader")
	if shader_res:
		var mat = ShaderMaterial.new()
		mat.shader = shader_res
		mat.set_shader_parameter("effect_strength", 0.08)
		mat.set_shader_parameter("pixel_size", 1.0)
		mat.set_shader_parameter("color_levels", 10.0)
		mat.set_shader_parameter("scanline_strength", 0.04)
		mat.set_shader_parameter("vignette_strength", 0.1)
		mat.set_shader_parameter("overlay_strength", 0.2)
		mat.set_shader_parameter("tint_color", Color(0.96, 0.97, 0.98, 1.0))
		fx_rect.material = mat

	ui_layer.add_child(fx_rect)
	ui_layer.move_child(fx_rect, 0)


# ============================================================
#  HUD
# ============================================================

func _create_hud() -> void:
	hud_panel = PanelContainer.new()
	hud_panel.name = "HUD"
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_panel.offset_left = 15.0
	hud_panel.offset_right = -15.0
	hud_panel.offset_top = 10.0
	hud_panel.offset_bottom = 52.0

	var hud_style = StyleBoxFlat.new()
	hud_style.bg_color = Color(0.04, 0.04, 0.08, 0.7)
	hud_style.corner_radius_top_left = 6
	hud_style.corner_radius_top_right = 6
	hud_style.corner_radius_bottom_left = 6
	hud_style.corner_radius_bottom_right = 6
	hud_style.border_width_bottom = 1
	hud_style.border_color = Color(0.2, 0.2, 0.3, 0.5)
	hud_style.content_margin_left = 12
	hud_style.content_margin_right = 12
	hud_style.content_margin_top = 6
	hud_style.content_margin_bottom = 6
	hud_panel.add_theme_stylebox_override("panel", hud_style)

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 18)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_panel.add_child(hbox)

	for key in meter_config:
		var cfg = meter_config[key]
		var vbox = VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_theme_constant_override("separation", 2)

		var lbl = Label.new()
		lbl.text = key
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", cfg["color"].lightened(0.3))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)

		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(90, 10)
		bar.max_value = 100
		bar.value = cfg["initial"]
		bar.show_percentage = false

		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(0.08, 0.08, 0.12, 0.9)
		bg.corner_radius_top_left = 3
		bg.corner_radius_top_right = 3
		bg.corner_radius_bottom_left = 3
		bg.corner_radius_bottom_right = 3
		bar.add_theme_stylebox_override("background", bg)

		var fill = StyleBoxFlat.new()
		fill.bg_color = cfg["color"]
		fill.corner_radius_top_left = 3
		fill.corner_radius_top_right = 3
		fill.corner_radius_bottom_left = 3
		fill.corner_radius_bottom_right = 3
		bar.add_theme_stylebox_override("fill", fill)

		vbox.add_child(bar)
		hbox.add_child(vbox)
		meter_bars[key] = bar

	ui_layer.add_child(hud_panel)

func update_meter(meter_name: String, value: int) -> void:
	meter_values[meter_name] = clampi(value, 0, 100)
	if meter_bars.has(meter_name):
		var bar: ProgressBar = meter_bars[meter_name]
		var tw = create_tween()
		tw.tween_property(bar, "value", float(meter_values[meter_name]), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# ============================================================
#  DIALOGUE UI
# ============================================================

func _create_dialogue_ui() -> void:
	# Typewriter timer
	typewriter_timer = Timer.new()
	typewriter_timer.one_shot = false
	typewriter_timer.wait_time = 0.03
	typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(typewriter_timer)

	# Anchor control (holds panel + continue indicator)
	dialogue_anchor = Control.new()
	dialogue_anchor.name = "DialogueAnchor"
	dialogue_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_anchor.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_anchor.offset_left = -330.0
	dialogue_anchor.offset_right = 330.0
	dialogue_anchor.offset_top = dialogue_rest_top
	dialogue_anchor.offset_bottom = -15.0
	dialogue_anchor.visible = false

	# Panel with stylized background
	dialogue_panel = PanelContainer.new()
	dialogue_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	dialogue_style = StyleBoxFlat.new()
	dialogue_style.bg_color = Color(0.05, 0.05, 0.09, 0.94)
	dialogue_style.border_width_top = 2
	dialogue_style.border_width_bottom = 2
	dialogue_style.border_width_left = 2
	dialogue_style.border_width_right = 2
	dialogue_style.border_color = Color(0.3, 0.3, 0.4)
	dialogue_style.corner_radius_top_left = 8
	dialogue_style.corner_radius_top_right = 8
	dialogue_style.corner_radius_bottom_left = 8
	dialogue_style.corner_radius_bottom_right = 8
	dialogue_style.shadow_color = Color(0, 0, 0, 0.35)
	dialogue_style.shadow_size = 6
	dialogue_style.shadow_offset = Vector2(2, 4)
	dialogue_style.content_margin_left = 14
	dialogue_style.content_margin_right = 14
	dialogue_style.content_margin_top = 10
	dialogue_style.content_margin_bottom = 10
	dialogue_panel.add_theme_stylebox_override("panel", dialogue_style)

	# Horizontal layout: portrait | text
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)

	# Portrait
	var portrait_panel = PanelContainer.new()
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.04, 0.07)
	ps.border_width_top = 1
	ps.border_width_bottom = 1
	ps.border_width_left = 1
	ps.border_width_right = 1
	ps.border_color = Color(0.2, 0.2, 0.3)
	ps.corner_radius_top_left = 4
	ps.corner_radius_top_right = 4
	ps.corner_radius_bottom_left = 4
	ps.corner_radius_bottom_right = 4
	portrait_panel.add_theme_stylebox_override("panel", ps)
	portrait_panel.custom_minimum_size = Vector2(110, 110)

	portrait_rect = TextureRect.new()
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_panel.add_child(portrait_rect)
	hbox.add_child(portrait_panel)

	# Text column
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.4))
	vbox.add_child(name_label)

	# Thin separator line
	var sep = HSeparator.new()
	var sep_style = StyleBoxFlat.new()
	sep_style.bg_color = Color(0.25, 0.25, 0.35, 0.5)
	sep_style.content_margin_top = 0
	sep_style.content_margin_bottom = 0
	sep.add_theme_stylebox_override("separator", sep_style)
	sep.add_theme_constant_override("separation", 4)
	vbox.add_child(sep)

	text_label = RichTextLabel.new()
	text_label.add_theme_font_size_override("normal_font_size", 16)
	text_label.add_theme_color_override("default_color", Color(0.88, 0.88, 0.92))
	text_label.bbcode_enabled = false
	text_label.fit_content = true
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(text_label)

	hbox.add_child(vbox)
	dialogue_panel.add_child(hbox)
	dialogue_anchor.add_child(dialogue_panel)

	# Continue indicator (blinking triangle)
	continue_label = Label.new()
	continue_label.text = "▼"
	continue_label.add_theme_font_size_override("font_size", 14)
	continue_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	continue_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	continue_label.offset_left = -30.0
	continue_label.offset_top = -24.0
	continue_label.visible = false
	dialogue_anchor.add_child(continue_label)

	ui_layer.add_child(dialogue_anchor)


# ============================================================
#  DIALOGUE SYSTEM
# ============================================================

func open_dialogue(character_id: String) -> void:
	if is_dialogue_open:
		return
	if not character_data_cache.has(character_id):
		return

	var c_data = character_data_cache[character_id]
	current_character_id = character_id
	player.set_physics_process(false)
	is_dialogue_open = true

	# Set character-specific border color
	var border_color = character_colors.get(character_id, Color(0.3, 0.3, 0.4))
	dialogue_style.border_color = border_color

	# Set portrait
	if portrait_paths.has(character_id) and ResourceLoader.exists(portrait_paths[character_id]):
		portrait_rect.texture = load(portrait_paths[character_id])
	else:
		portrait_rect.texture = null

	# Set name
	name_label.text = str(c_data.get("name", "Unknown"))

	# Get dialogue text
	var encounters = c_data.get("encounters", {})
	var voice_line := "..."
	if encounters.has("1"):
		voice_line = str(encounters["1"].get("voice_line", "..."))

	# Start typewriter
	continue_label.visible = false
	continue_blink = 0.0
	_start_typewriter(voice_line)

	# Animate panel in
	_animate_dialogue_in()

func _start_typewriter(text: String) -> void:
	typewriter_text = text
	typewriter_index = 0
	text_label.text = ""
	typewriter_timer.start()

func _on_typewriter_tick() -> void:
	if typewriter_index < typewriter_text.length():
		text_label.text += typewriter_text[typewriter_index]
		typewriter_index += 1
	else:
		typewriter_timer.stop()
		continue_label.visible = true

func _animate_dialogue_in() -> void:
	dialogue_anchor.visible = true
	dialogue_anchor.modulate.a = 0.0
	dialogue_anchor.offset_top = dialogue_rest_top + 40.0

	var tw = create_tween().set_parallel(true)
	tw.tween_property(dialogue_anchor, "modulate:a", 1.0, 0.3)
	tw.tween_property(dialogue_anchor, "offset_top", dialogue_rest_top, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _close_dialogue() -> void:
	typewriter_timer.stop()
	continue_label.visible = false

	var start_top = dialogue_anchor.offset_top
	var tw = create_tween().set_parallel(true)
	tw.tween_property(dialogue_anchor, "modulate:a", 0.0, 0.2)
	tw.tween_property(dialogue_anchor, "offset_top", start_top + 30.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		dialogue_anchor.visible = false
		dialogue_anchor.offset_top = dialogue_rest_top
		is_dialogue_open = false
		player.set_physics_process(true)
	)
