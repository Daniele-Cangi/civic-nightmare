extends Node2D

const OVAL_OFFICE_ROOM_SCENE = preload("res://scenes/interiors/oval_office.tscn")
const DOORWAY_SCRIPT = preload("res://scripts/doorway.gd")

@onready var ground_map: TileMap = $GroundMap
@onready var player: CharacterBody2D = $Entities/Player
@onready var entities_layer: Node2D = $Entities
@onready var ui_layer: CanvasLayer = $UI

var character_data_cache: Dictionary = {}
var is_dialogue_open: bool = false
var interiors_layer: Node2D
var room_registry: Dictionary = {}
var world_spawn_points: Dictionary = {}
var active_room_id: String = ""
var door_cooldown_until_ms: int = 0
var is_room_transition: bool = false
var world_canvas_modulate: CanvasModulate
var screen_fx_material: ShaderMaterial
var interior_overlay: ColorRect
var transition_overlay: ColorRect
var room_title_card: PanelContainer
var room_title_label: Label
var room_title_subtitle: Label

# --- Dialogue UI (created in code) ---
var dialogue_anchor: Control
var dialogue_panel: PanelContainer
var dialogue_style: StyleBox
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
var dialogue_lines: Array = []
var dialogue_line_index: int = 0
var dialogue_choices: Array = []
var dialogue_choice_prompt: String = ""
var dialogue_farewell: String = ""
var is_choosing: bool = false
var choice_index: int = 0
var choice_container: VBoxContainer
var choice_labels: Array = []
var typewriter_bip: AudioStreamPlayer

# --- Quest state ---
var quest_order: Array = [
	"donald_trump", "elon_musk", "ursula_von_der_leyen",
	"vladimir_putin", "christine_lagarde", "emmanuel_macron"
]
var quest_completed: Dictionary = {}
var quest_index: int = -1
var quest_finished: bool = false
var ai_terminal_data: Dictionary = {}

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
const SRC_HOUSE := 6

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
	SRC_HOUSE: "res://assets/tiles/house_32.png",
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
const TILE_DOOR = Vector2i(7, 2)
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

# --- Water autotile (first set in water_32.png, sandy shore) ---
const WT_CENTER := Vector2i(3, 1)
const WT_EDGE_T := Vector2i(3, 0)
const WT_EDGE_B := Vector2i(3, 2)
const WT_EDGE_L := Vector2i(2, 1)
const WT_EDGE_R := Vector2i(4, 1)
const WT_CORNER_TL := Vector2i(2, 0)
const WT_CORNER_TR := Vector2i(4, 0)
const WT_CORNER_BL := Vector2i(2, 2)
const WT_CORNER_BR := Vector2i(4, 2)

# --- Floor/path autotile (first set in floor_32.png, sandy path) ---
const FL_EDGE_T := Vector2i(3, 0)
const FL_EDGE_B := Vector2i(3, 2)
const FL_EDGE_L := Vector2i(2, 1)
const FL_EDGE_R := Vector2i(4, 1)
const FL_CENTER := Vector2i(3, 1)
const FL_CORNER_TL := Vector2i(2, 0)
const FL_CORNER_TR := Vector2i(4, 0)
const FL_CORNER_BL := Vector2i(2, 2)
const FL_CORNER_BR := Vector2i(4, 2)

# House templates removed — all buildings now use unique procedural shapes

var tree_variants: Array = [
	# Row 0-1: Confirmed round canopy trees (green, snow, pink)
	{"size": Vector2i(2, 2), "tiles": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], "solid_offset": Vector2i(0, 1)},
	{"size": Vector2i(2, 2), "tiles": [Vector2i(4, 0), Vector2i(5, 0), Vector2i(4, 1), Vector2i(5, 1)], "solid_offset": Vector2i(0, 1)},
	{"size": Vector2i(2, 2), "tiles": [Vector2i(6, 0), Vector2i(7, 0), Vector2i(6, 1), Vector2i(7, 1)], "solid_offset": Vector2i(0, 1)},
	{"size": Vector2i(2, 2), "tiles": [Vector2i(8, 0), Vector2i(9, 0), Vector2i(8, 1), Vector2i(9, 1)], "solid_offset": Vector2i(0, 1)},
	{"size": Vector2i(2, 2), "tiles": [Vector2i(10, 0), Vector2i(11, 0), Vector2i(10, 1), Vector2i(11, 1)], "solid_offset": Vector2i(0, 1)},
	{"size": Vector2i(2, 2), "tiles": [Vector2i(12, 0), Vector2i(13, 0), Vector2i(12, 1), Vector2i(13, 1)], "solid_offset": Vector2i(0, 1)},
]
var flower_tiles: Array = [
	Vector2i(2, 11), Vector2i(3, 11), Vector2i(12, 11), Vector2i(13, 11), Vector2i(13, 12)
]
var tuft_tiles: Array = [
	Vector2i(12, 9), Vector2i(6, 10), Vector2i(12, 10), Vector2i(8, 13), Vector2i(9, 13),
	Vector2i(13, 12)
]
var rock_tiles: Array = [
	Vector2i(4, 12), Vector2i(6, 12), Vector2i(7, 12), Vector2i(9, 12),
	Vector2i(11, 12), Vector2i(12, 12)
]

var building_specs: Array = [
	{
		"key": "oval_office",
		"npc": "donald_trump",
		"center": Vector2i(20, -20),
		"npc_spawn": Vector2i(20, -13),
		"entrance": Vector2i(20, -15),
		"light_color": Color(1.0, 0.85, 0.6)
	},
	{
		"key": "spaceship",
		"npc": "elon_musk",
		"center": Vector2i(-20, -20),
		"npc_spawn": Vector2i(-20, -12),
		"entrance": Vector2i(-20, -14),
		"light_color": Color(0.6, 0.8, 1.0)
	},
	{
		"key": "eu_palace",
		"npc": "ursula_von_der_leyen",
		"center": Vector2i(20, 0),
		"npc_spawn": Vector2i(20, 8),
		"entrance": Vector2i(20, 6),
		"light_color": Color(0.7, 0.75, 1.0)
	},
	{
		"key": "kremlin",
		"npc": "vladimir_putin",
		"center": Vector2i(-20, 0),
		"npc_spawn": Vector2i(-20, 8),
		"entrance": Vector2i(-20, 6),
		"light_color": Color(0.9, 0.7, 0.5)
	},
	{
		"key": "vault",
		"npc": "christine_lagarde",
		"center": Vector2i(20, 20),
		"npc_spawn": Vector2i(20, 28),
		"entrance": Vector2i(20, 26),
		"light_color": Color(1.0, 0.9, 0.6)
	},
	{
		"key": "elysee",
		"npc": "emmanuel_macron",
		"center": Vector2i(-20, 20),
		"npc_spawn": Vector2i(-20, 27),
		"entrance": Vector2i(-20, 25),
		"light_color": Color(0.75, 0.8, 1.0)
	}
]

# --- Character visual config ---
var character_colors: Dictionary = {
	"ai_terminal": Color(0.2, 0.7, 0.9),
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
var landmark_sprite_paths: Dictionary = {
	"donald_trump": "res://assets/mockups/landmark_trump.png",
	"elon_musk": "res://assets/mockups/landmark_musk.png",
	"ursula_von_der_leyen": "res://assets/mockups/landmark_vdl.png",
	"christine_lagarde": "res://assets/mockups/landmark_lagarde.png",
	"vladimir_putin": "res://assets/mockups/landmark_putin.png",
	"emmanuel_macron": "res://assets/mockups/landmark_macron.png"
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
	_setup_world_lighting()
	_create_screen_fx()
	_create_hud()
	_create_dialogue_ui()
	_create_transition_fx()
	_setup_interiors()
	_remove_world_npcs()
	_assign_npc_textures()
	_create_ai_terminal()
	_create_typewriter_bip()
	_setup_ambient_audio()
	_create_atmosphere_particles()

func _remove_world_npcs() -> void:
	for child in entities_layer.get_children():
		if child == player:
			continue
		if child.is_in_group("npc"):
			entities_layer.remove_child(child)
			child.queue_free()

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

func _setup_interiors() -> void:
	if interiors_layer:
		return

	interiors_layer = Node2D.new()
	interiors_layer.name = "Interiors"
	add_child(interiors_layer)

	for index in range(building_specs.size()):
		var spec: Dictionary = building_specs[index]
		var room = OVAL_OFFICE_ROOM_SCENE.instantiate()
		room.name = "%sInterior" % _pascal_case(str(spec["key"]))
		room.position = Vector2(0, 3200 + index * 960)
		room.set("room_key", spec["key"])
		room.set("character_id", spec["npc"])
		room.set("character_name", _character_display_name(str(spec["npc"])))
		interiors_layer.add_child(room)
		room_registry[spec["key"]] = room
		if room.has_method("set_room_active"):
			room.set_room_active(false)

		var entrance: Vector2i = spec["entrance"]
		world_spawn_points["%s_exterior" % spec["key"]] = _tile_to_actor_position(entrance + Vector2i(0, 2))
		_create_world_doorway("%sDoor" % _pascal_case(str(spec["key"])), entrance, spec["key"], "EntryMarker")

func _create_world_doorway(name: String, tile_pos: Vector2i, destination: String, spawn_marker: String) -> void:
	var door := Area2D.new()
	door.name = name
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

func use_door(destination: String, spawn_marker: String) -> void:
	if is_dialogue_open or is_room_transition:
		return
	var now := Time.get_ticks_msec()
	if now < door_cooldown_until_ms:
		return
	door_cooldown_until_ms = now + 900
	is_room_transition = true
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	var door_sfx = get_node_or_null("DoorSFX")
	if door_sfx:
		door_sfx.play()
	await _fade_transition(1.0, 0.22)
	if destination == "world":
		_exit_room(spawn_marker)
	else:
		_enter_room(destination, spawn_marker)
	_set_room_presentation(active_room_id != "")
	if destination != "world":
		var room = room_registry.get(destination)
		var title := _pascal_case(destination).to_upper()
		var subtitle := ""
		if room:
			if room.has_method("get_room_title"):
				title = str(room.get_room_title())
			if room.has_method("get_room_subtitle"):
				subtitle = str(room.get_room_subtitle())
		_show_room_title(title, subtitle)
	await _fade_transition(0.0, 0.28)
	if not is_dialogue_open:
		player.set_physics_process(true)
	is_room_transition = false

func _enter_room(room_id: String, spawn_marker: String) -> void:
	var room = room_registry.get(room_id)
	if room == null:
		return
	if active_room_id != "" and room_registry.has(active_room_id):
		var current_room = room_registry[active_room_id]
		if current_room and current_room != room and current_room.has_method("set_room_active"):
			current_room.set_room_active(false)

	active_room_id = room_id
	if room.has_method("set_room_active"):
		room.set_room_active(true)
	if room.has_method("get_entity_container"):
		var room_entities = room.get_entity_container()
		if room_entities and player.get_parent() != room_entities:
			player.reparent(room_entities, true)
	if room.has_method("get_spawn_position"):
		player.velocity = Vector2.ZERO
		player.global_position = room.get_spawn_position(spawn_marker)

func _exit_room(spawn_marker: String) -> void:
	var room = room_registry.get(active_room_id)
	if player.get_parent() != entities_layer:
		player.reparent(entities_layer, true)

	player.velocity = Vector2.ZERO
	if active_room_id != "" and room_registry.has(active_room_id):
		if room and room.has_method("set_room_active"):
			room.set_room_active(false)
	active_room_id = ""

	if world_spawn_points.has(spawn_marker):
		player.global_position = world_spawn_points[spawn_marker]

func _fade_transition(target_alpha: float, duration: float) -> void:
	transition_overlay.visible = true
	var tw = create_tween()
	tw.tween_property(transition_overlay, "modulate:a", target_alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if is_zero_approx(target_alpha):
		transition_overlay.visible = false

func _set_room_presentation(indoor: bool) -> void:
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

func _show_room_title(title: String, subtitle: String = "") -> void:
	if not room_title_card:
		return
	room_title_label.text = title
	room_title_subtitle.text = subtitle
	room_title_card.visible = true
	room_title_card.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(room_title_card, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.95)
	tw.tween_property(room_title_card, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
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

func _character_display_name(character_id: String) -> String:
	if character_data_cache.has(character_id):
		var entry = character_data_cache[character_id]
		if entry is Dictionary and entry.has("name"):
			return str(entry["name"])
	var words := character_id.split("_", false)
	var display_words: Array[String] = []
	for i in range(words.size()):
		var word: String = words[i]
		display_words.append(word.substr(0, 1).to_upper() + word.substr(1).to_lower())
	var result := ""
	for i in range(display_words.size()):
		if i > 0:
			result += " "
		result += display_words[i]
	return result

func _process(delta: float) -> void:
	_process_ai_terminal(delta)
	if is_dialogue_open:
		# Blink continue indicator
		if continue_label.visible:
			continue_blink += delta * 3.0
			continue_label.modulate.a = 0.4 + sin(continue_blink) * 0.4

		if is_choosing:
			# Navigate choices with up/down
			if Input.is_action_just_pressed("ui_up"):
				choice_index = max(0, choice_index - 1)
				_update_choice_highlight()
			elif Input.is_action_just_pressed("ui_down"):
				choice_index = min(choice_labels.size() - 1, choice_index + 1)
				_update_choice_highlight()
			elif Input.is_action_just_pressed("ui_accept"):
				_select_choice()
		elif Input.is_action_just_pressed("ui_accept"):
			if typewriter_index < typewriter_text.length():
				# Skip to full text
				typewriter_timer.stop()
				text_label.text = typewriter_text
				typewriter_index = typewriter_text.length()
				continue_label.visible = true
			else:
				_advance_dialogue()


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

func _path_tile_for_neighbors(n: bool, s: bool, w: bool, e: bool) -> Vector2i:
	if n and s and w and e: return FL_CENTER
	if not n and s and w and e: return FL_EDGE_T
	if n and not s and w and e: return FL_EDGE_B
	if n and s and not w and e: return FL_EDGE_L
	if n and s and w and not e: return FL_EDGE_R
	if not n and s and not w and e: return FL_CORNER_TL
	if not n and s and w and not e: return FL_CORNER_TR
	if n and not s and not w and e: return FL_CORNER_BL
	if n and not s and w and not e: return FL_CORNER_BR
	return FL_CENTER

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
		if _pack_ready:
			var pn := _path_cells.has(path_pos + Vector2i(0, -1))
			var ps := _path_cells.has(path_pos + Vector2i(0, 1))
			var pw := _path_cells.has(path_pos + Vector2i(-1, 0))
			var pe := _path_cells.has(path_pos + Vector2i(1, 0))
			ground_map.set_cell(LAYER_GROUND, path_pos, path_source, _path_tile_for_neighbors(pn, ps, pw, pe))
		else:
			ground_map.set_cell(LAYER_GROUND, path_pos, path_source, TILE_PATH)

	for spec in building_specs:
		_build_structure(spec)
		_decorate_compound(spec)
		_place_landmark(spec)

	for x in range(WORLD_MIN_X + 4, WORLD_MAX_X - 4):
		for y in range(WORLD_MIN_Y + 4, WORLD_MAX_Y - 4):
			if _is_in_building_zone(x, y) or _is_on_path(x, y):
				continue

			var roll := _tile_roll(x, y)
			var pos := Vector2i(x, y)
			if roll < 2:
				_paint_lake(pos, water_source, WT_WATER if _pack_ready else TILE_WATER)
			elif roll < 18:
				_place_tree(pos)
			elif roll < 38:
				_place_bush(pos)
			elif roll < 52:
				_place_flower(pos)
			elif roll < 62:
				_place_rock(pos)

func _paint_lake(center: Vector2i, src: int = SRC_PROC, coords: Vector2i = TILE_WATER) -> void:
	var lake_cells: Array[Vector2i] = []
	for x in range(center.x - 2, center.x + 3):
		for y in range(center.y - 1, center.y + 3):
			if abs(x - center.x) + abs(y - center.y) > 3:
				continue
			var pos := Vector2i(x, y)
			if not _can_use_world_cell(pos):
				return
			if ground_map.get_cell_source_id(LAYER_DECOR, pos) != -1:
				return
			lake_cells.append(pos)

	var lake_set: Dictionary = {}
	for pos in lake_cells:
		lake_set[pos] = true

	for pos in lake_cells:
		if _pack_ready:
			var wn := lake_set.has(pos + Vector2i(0, -1))
			var ws := lake_set.has(pos + Vector2i(0, 1))
			var ww := lake_set.has(pos + Vector2i(-1, 0))
			var we := lake_set.has(pos + Vector2i(1, 0))
			var tile := _water_tile_for_neighbors(wn, ws, ww, we)
			ground_map.set_cell(LAYER_GROUND, pos, SRC_WATER, tile)
		else:
			ground_map.set_cell(LAYER_GROUND, pos, src, coords)
		_create_solid_wall(pos.x, pos.y)

func _water_tile_for_neighbors(n: bool, s: bool, w: bool, e: bool) -> Vector2i:
	if n and s and w and e: return WT_CENTER
	if not n and s and w and e: return WT_EDGE_T
	if n and not s and w and e: return WT_EDGE_B
	if n and s and not w and e: return WT_EDGE_L
	if n and s and w and not e: return WT_EDGE_R
	if not n and s and not w and e: return WT_CORNER_TL
	if not n and s and w and not e: return WT_CORNER_TR
	if n and not s and not w and e: return WT_CORNER_BL
	if n and not s and w and not e: return WT_CORNER_BR
	return WT_CENTER

func _place_tree(pos: Vector2i) -> void:
	if _pack_ready:
		# Use a different hash from the main roll to avoid repetition
		var variant_idx := posmod(pos.x * 48271 + pos.y * 91831 + 37139, tree_variants.size())
		var variant: Dictionary = tree_variants[variant_idx]
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

func _place_landmark(spec: Dictionary) -> void:
	var cid = spec["npc"]
	if not landmark_sprite_paths.has(cid):
		return
		
	var path = landmark_sprite_paths[cid]
	if not ResourceLoader.exists(path):
		return
		
	var sprite = Sprite2D.new()
	sprite.texture = load(path)
	
	# Center on the building
	var pos = _tile_to_body_position(spec["center"])
	sprite.position = pos
	
	# Landmarks sit ON THE ROOF. 
	# We adjust the offset based on the specific house height to avoid floating.
	var offset_y := -155.0
	match cid:
		"elon_musk": offset_y = -95.0
		"donald_trump", "emmanuel_macron": offset_y = -135.0
		_: offset_y = -155.0
	
	sprite.offset = Vector2(0, offset_y)
	sprite.z_index = 5 
	
	entities_layer.add_child(sprite)
	
	# We don't need extra collision anymore as the landmark is ABOVE the house walls
	# which already have collision.

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

	# Flower beds flanking the entrance
	_decorate_flower_bed(entrance + Vector2i(-4, 1), 2)
	_decorate_flower_bed(entrance + Vector2i(3, 1), 2)

	# Corner bushes (wider offset for procedural buildings)
	var bush_offset: int = 7
	_set_decor_tile(center + Vector2i(-bush_offset, -3), NT_BUSH)
	_set_decor_tile(center + Vector2i(bush_offset, -3), NT_BUSH)
	_set_decor_tile(center + Vector2i(-bush_offset, 2), NT_BUSH)
	_set_decor_tile(center + Vector2i(bush_offset, 2), NT_BUSH)

	# Grass tufts beside the building
	for i in range(-bush_offset + 1, bush_offset):
		if abs(i) > 2 and _tile_roll(center.x + i, center.y - 4) % 3 == 0:
			_set_decor_tile(center + Vector2i(i, -4), tuft_tiles[abs(i) % tuft_tiles.size()])

	# Additional decorations by style
	match spec["key"]:
		"oval_office", "eu_palace", "elysee":
			# Elegant: extra flower line along sides
			for dy in range(-2, 3):
				if _tile_roll(center.x - bush_offset - 1, center.y + dy) % 4 == 0:
					_set_decor_tile(center + Vector2i(-bush_offset - 1, dy), flower_tiles[abs(dy) % flower_tiles.size()])
				if _tile_roll(center.x + bush_offset + 1, center.y + dy) % 4 == 0:
					_set_decor_tile(center + Vector2i(bush_offset + 1, dy), flower_tiles[abs(dy) % flower_tiles.size()])
		"spaceship", "kremlin", "vault":
			# Rugged: rock borders
			_decorate_rock_bed(entrance + Vector2i(-5, 2), 2)
			_decorate_rock_bed(entrance + Vector2i(4, 2), 2)


# --- Unique shaped buildings — each politician has a distinctive silhouette ---

func _fill_building_tile(pos: Vector2i, on_edge: bool, wall_tile: Vector2i, roof_tile: Vector2i) -> void:
	if on_edge:
		_set_structure_tile(pos, wall_tile, true)
	else:
		_set_structure_tile(pos, roof_tile, true)

# TRUMP — Ellipse (Oval Office)
func _build_oval_office(center: Vector2i) -> void:
	var a := 5
	var b := 4
	for x in range(center.x - a, center.x + a + 1):
		for y in range(center.y - b, center.y + b + 1):
			var xr := pow(float(x - center.x) / float(a), 2)
			var yr := pow(float(y - center.y) / float(b), 2)
			if xr + yr <= 1.0:
				var on_edge: bool = xr + yr > 0.62
				_fill_building_tile(Vector2i(x, y), on_edge, TILE_BRICK, TILE_WOOD)
	_set_structure_tile(Vector2i(center.x, center.y + b), TILE_DOOR, true)
	for wx in [-2, 0, 2]:
		_set_structure_tile(Vector2i(center.x + wx, center.y - b + 1), TILE_WINDOW, true)

# MUSK — Diamond / rocket shape (Spaceship)
func _build_spaceship(center: Vector2i) -> void:
	var r := 5
	for x in range(center.x - r, center.x + r + 1):
		for y in range(center.y - r, center.y + r + 1):
			var manhattan: int = abs(x - center.x) + abs(y - center.y)
			if manhattan <= r:
				var on_edge: bool = manhattan >= r - 1
				_fill_building_tile(Vector2i(x, y), on_edge, TILE_METAL_WALL, TILE_METAL_FLOOR)
	_set_structure_tile(Vector2i(center.x, center.y + r), TILE_DOOR, true)
	for wx in [-1, 0, 1]:
		_set_structure_tile(Vector2i(center.x + wx, center.y - r + 2), TILE_WINDOW, true)

# VON DER LEYEN — Grand rectangle with cut corners + columns (EU Palace)
func _build_eu_palace(center: Vector2i) -> void:
	var hx := 5
	var hy := 5
	for x in range(center.x - hx, center.x + hx + 1):
		for y in range(center.y - hy, center.y + hy + 1):
			var dx: int = abs(x - center.x)
			var dy: int = abs(y - center.y)
			# Cut all 4 corners
			if dx >= hx - 1 and dy >= hy - 1:
				continue
			var on_border: bool = dx == hx or dy == hy
			_fill_building_tile(Vector2i(x, y), on_border, TILE_MARBLE_WALL, TILE_MARBLE_FLOOR)
	_set_structure_tile(Vector2i(center.x, center.y + hy), TILE_DOOR, true)
	# Front columns
	_set_structure_tile(Vector2i(center.x - 3, center.y + hy), TILE_COLUMN, true)
	_set_structure_tile(Vector2i(center.x + 3, center.y + hy), TILE_COLUMN, true)
	# Windows across the top
	for wx in [-3, -1, 1, 3]:
		_set_structure_tile(Vector2i(center.x + wx, center.y - hy), TILE_WINDOW, true)

# PUTIN — Cross / plus shape (Kremlin)
func _build_kremlin(center: Vector2i) -> void:
	var arm_len := 5
	var arm_w := 2
	for x in range(center.x - arm_len, center.x + arm_len + 1):
		for y in range(center.y - arm_len, center.y + arm_len + 1):
			var dx: int = abs(x - center.x)
			var dy: int = abs(y - center.y)
			var in_v: bool = dx <= arm_w
			var in_h: bool = dy <= arm_w
			if in_v or in_h:
				var on_edge := false
				if in_v and not in_h:
					on_edge = dy == arm_len or dx == arm_w
				elif in_h and not in_v:
					on_edge = dx == arm_len or dy == arm_w
				else:
					on_edge = (dx == arm_w and dy > arm_w) or (dy == arm_w and dx > arm_w)
				_fill_building_tile(Vector2i(x, y), on_edge, TILE_KREMLIN_WALL, TILE_WOOD)
	_set_structure_tile(Vector2i(center.x, center.y + arm_len), TILE_DOOR, true)
	# Flag at top
	_set_structure_tile(Vector2i(center.x, center.y - arm_len), TILE_FLAG, true)

# LAGARDE — Octagonal vault shape
func _build_vault(center: Vector2i) -> void:
	var r := 5
	var cut := 3
	for x in range(center.x - r, center.x + r + 1):
		for y in range(center.y - r, center.y + r + 1):
			var dx: int = abs(x - center.x)
			var dy: int = abs(y - center.y)
			# Octagon: rectangle minus corners where dx+dy > r+cut
			if dx + dy > r + cut:
				continue
			var on_edge: bool = dx == r or dy == r or dx + dy >= r + cut - 1
			_fill_building_tile(Vector2i(x, y), on_edge, TILE_VAULT_WALL, TILE_METAL_FLOOR)
	_set_structure_tile(Vector2i(center.x, center.y + r), TILE_DOOR, true)
	# Gold accents
	_set_structure_tile(Vector2i(center.x - 2, center.y - r + 1), TILE_GOLD, true)
	_set_structure_tile(Vector2i(center.x + 2, center.y - r + 1), TILE_GOLD, true)

# MACRON — T-shape palace with wings (Élysée)
func _build_elysee(center: Vector2i) -> void:
	# Top wing (wide)
	for x in range(center.x - 5, center.x + 6):
		for y in range(center.y - 4, center.y - 1):
			var dx: int = abs(x - center.x)
			var on_edge: bool = dx == 5 or y == center.y - 4 or y == center.y - 1
			_fill_building_tile(Vector2i(x, y), on_edge, TILE_MARBLE_WALL, TILE_MARBLE_FLOOR)
	# Main body (narrower)
	for x in range(center.x - 3, center.x + 4):
		for y in range(center.y - 1, center.y + 5):
			var dx: int = abs(x - center.x)
			var on_edge: bool = dx == 3 or y == center.y + 4
			_fill_building_tile(Vector2i(x, y), on_edge, TILE_MARBLE_WALL, TILE_MARBLE_FLOOR)
	_set_structure_tile(Vector2i(center.x, center.y + 4), TILE_DOOR, true)
	# Columns on wing ends
	_set_structure_tile(Vector2i(center.x - 5, center.y - 1), TILE_COLUMN, true)
	_set_structure_tile(Vector2i(center.x + 5, center.y - 1), TILE_COLUMN, true)
	# Windows on top wing
	for wx in [-3, -1, 1, 3]:
		_set_structure_tile(Vector2i(center.x + wx, center.y - 4), TILE_WINDOW, true)


# ============================================================
#  WORLD LIGHTING
# ============================================================

func _setup_world_lighting() -> void:
	# Very subtle cold tint — avoid washing out the pixel art
	world_canvas_modulate = CanvasModulate.new()
	world_canvas_modulate.color = Color(0.95, 0.96, 0.98)
	add_child(world_canvas_modulate)

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

func _setup_ambient_audio() -> void:
	# Door entry sound effect only (soft thud, no ambient noise)
	var door_sfx = AudioStreamPlayer.new()
	door_sfx.name = "DoorSFX"
	door_sfx.volume_db = -16.0
	var door_rate := 22050
	var door_dur := 0.1
	var door_samples := int(door_rate * door_dur)
	var door_stream := AudioStreamWAV.new()
	door_stream.format = AudioStreamWAV.FORMAT_8_BITS
	door_stream.mix_rate = door_rate
	door_stream.stereo = false
	var door_data := PackedByteArray()
	door_data.resize(door_samples)
	for i in range(door_samples):
		var t := float(i) / door_rate
		var env := (1.0 - t / door_dur)
		var thud := sin(t * 180.0 * TAU) * env * env
		door_data[i] = int(clampf(thud * 45.0 + 128.0, 0.0, 255.0))
	door_stream.data = door_data
	door_sfx.stream = door_stream
	add_child(door_sfx)

func _create_atmosphere_particles() -> void:
	var player_node = get_node_or_null("Player")
	if not player_node:
		return

	# Floating leaves / pollen
	var leaves = CPUParticles2D.new()
	leaves.name = "LeafParticles"
	leaves.emitting = true
	leaves.amount = 12
	leaves.lifetime = 6.0
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = Vector2(400, 300)
	leaves.direction = Vector2(1.0, 0.5)
	leaves.spread = 30.0
	leaves.initial_velocity_min = 6.0
	leaves.initial_velocity_max = 14.0
	leaves.gravity = Vector2(2.0, 8.0)
	leaves.angular_velocity_min = -40.0
	leaves.angular_velocity_max = 40.0
	leaves.scale_amount_min = 1.5
	leaves.scale_amount_max = 3.0
	var leaf_grad = Gradient.new()
	leaf_grad.colors = PackedColorArray([
		Color(0.45, 0.55, 0.25, 0.0),
		Color(0.5, 0.6, 0.3, 0.35),
		Color(0.55, 0.5, 0.25, 0.3),
		Color(0.6, 0.45, 0.2, 0.0)
	])
	leaf_grad.offsets = PackedFloat32Array([0.0, 0.15, 0.7, 1.0])
	leaves.color_ramp = leaf_grad
	leaves.z_index = 5
	player_node.add_child(leaves)

	# Fireflies (subtle glowing dots)
	var fireflies = CPUParticles2D.new()
	fireflies.name = "Fireflies"
	fireflies.emitting = true
	fireflies.amount = 8
	fireflies.lifetime = 4.0
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = Vector2(350, 250)
	fireflies.direction = Vector2(0, -1)
	fireflies.spread = 180.0
	fireflies.initial_velocity_min = 2.0
	fireflies.initial_velocity_max = 8.0
	fireflies.gravity = Vector2(0, -3)
	fireflies.scale_amount_min = 1.0
	fireflies.scale_amount_max = 2.0
	var ff_grad = Gradient.new()
	ff_grad.colors = PackedColorArray([
		Color(1.0, 0.95, 0.5, 0.0),
		Color(1.0, 0.9, 0.4, 0.5),
		Color(1.0, 0.85, 0.3, 0.4),
		Color(1.0, 0.9, 0.5, 0.0)
	])
	ff_grad.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	fireflies.color_ramp = ff_grad
	fireflies.z_index = 6
	player_node.add_child(fireflies)


# ============================================================
#  WORLD NPC MANAGEMENT & AI TERMINAL
# ============================================================


func _create_ai_terminal() -> void:
	var terminal := StaticBody2D.new()
	terminal.name = "AITerminal"
	terminal.position = Vector2(16, 16)
	terminal.add_to_group("ai_terminal")
	terminal.set_script(load("res://scripts/ai_terminal.gd"))

	# Glowing terminal visual — pulsing cyan pillar
	var base_poly := Polygon2D.new()
	base_poly.color = Color(0.08, 0.12, 0.18, 0.95)
	base_poly.polygon = PackedVector2Array([
		Vector2(-18, -6), Vector2(18, -6), Vector2(22, 10), Vector2(-22, 10)
	])
	terminal.add_child(base_poly)

	var screen_poly := Polygon2D.new()
	screen_poly.color = Color(0.15, 0.7, 0.9, 0.92)
	screen_poly.polygon = PackedVector2Array([
		Vector2(-14, -38), Vector2(14, -38), Vector2(16, -8), Vector2(-16, -8)
	])
	terminal.add_child(screen_poly)

	var screen_inner := Polygon2D.new()
	screen_inner.color = Color(0.05, 0.15, 0.22, 0.95)
	screen_inner.polygon = PackedVector2Array([
		Vector2(-10, -34), Vector2(10, -34), Vector2(12, -12), Vector2(-12, -12)
	])
	terminal.add_child(screen_inner)

	# Indicator label
	var label := Label.new()
	label.text = "AI"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-10, -30)
	label.z_index = 10
	terminal.add_child(label)

	# "!" indicator when nearby (same as NPCs)
	var indicator := Label.new()
	indicator.name = "Indicator"
	indicator.text = "!"
	indicator.add_theme_font_size_override("font_size", 22)
	indicator.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicator.position = Vector2(-8, -60)
	indicator.visible = false
	indicator.z_index = 10
	terminal.add_child(indicator)

	# Collision for interaction ray
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 20)
	col.shape = shape
	col.position = Vector2(0, 2)
	terminal.add_child(col)

	# Glow light
	var glow := PointLight2D.new()
	glow.position = Vector2(0, -20)
	glow.color = Color(0.2, 0.75, 0.95)
	glow.energy = 0.5
	glow.texture_scale = 2.0
	var glow_tex := GradientTexture2D.new()
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(1.0, 0.5)
	glow_tex.width = 128
	glow_tex.height = 128
	var glow_grad := Gradient.new()
	glow_grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	glow_grad.offsets = PackedFloat32Array([0.0, 1.0])
	glow_tex.gradient = glow_grad
	glow.texture = glow_tex
	terminal.add_child(glow)

	terminal.z_index = 2
	entities_layer.add_child(terminal)

	# Add path tiles around the terminal
	_mark_path_rect(Vector2i(-2, -2), Vector2i(2, 2))
	var path_source: int = SRC_FLOOR if _pack_ready else SRC_PROC
	for x in range(-2, 3):
		for y in range(-2, 3):
			var pos := Vector2i(x, y)
			if _pack_ready:
				var pn := _path_cells.has(pos + Vector2i(0, -1))
				var ps := _path_cells.has(pos + Vector2i(0, 1))
				var pw := _path_cells.has(pos + Vector2i(-1, 0))
				var pe := _path_cells.has(pos + Vector2i(1, 0))
				ground_map.set_cell(LAYER_GROUND, pos, path_source, _path_tile_for_neighbors(pn, ps, pw, pe))
			else:
				ground_map.set_cell(LAYER_GROUND, pos, path_source, TILE_PATH)

func _process_ai_terminal(_delta: float) -> void:
	var terminal := get_node_or_null("Entities/AITerminal")
	if not terminal or not player:
		return
	var indicator := terminal.get_node_or_null("Indicator") as Label
	if not indicator:
		return
	var dist: float = terminal.global_position.distance_to(player.global_position)
	indicator.visible = dist < 80.0
	if indicator.visible:
		var t := Time.get_ticks_msec() / 300.0
		indicator.position.y = -60 + sin(t) * 3.0
		indicator.modulate.a = 0.6 + sin(t * 2.0) * 0.4

func _create_typewriter_bip() -> void:
	typewriter_bip = AudioStreamPlayer.new()
	typewriter_bip.name = "TypewriterBip"
	typewriter_bip.volume_db = -28.0
	var rate := 22050
	var dur := 0.025
	var samples := int(rate * dur)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.stereo = false
	var data := PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t := float(i) / rate
		var env := 1.0 - t / dur
		var wave := sin(t * 1200.0 * TAU) * env * env
		data[i] = int(clampf(wave * 30.0 + 128.0, 0.0, 255.0))
	stream.data = data
	typewriter_bip.stream = stream
	add_child(typewriter_bip)


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
					if entry.get("is_terminal", false):
						ai_terminal_data = entry
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
		screen_fx_material = mat

	ui_layer.add_child(fx_rect)
	ui_layer.move_child(fx_rect, 0)

func _create_transition_fx() -> void:
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

	var panel_tex_path := "res://assets/packs/civic_nightmare/ui/ninja/theme_wood/nine_path_panel.png"
	if ResourceLoader.exists(panel_tex_path):
		dialogue_style = StyleBoxTexture.new()
		dialogue_style.texture = load(panel_tex_path)
		dialogue_style.texture_margin_left = 4
		dialogue_style.texture_margin_right = 4
		dialogue_style.texture_margin_top = 4
		dialogue_style.texture_margin_bottom = 4
		dialogue_style.content_margin_left = 16
		dialogue_style.content_margin_right = 16
		dialogue_style.content_margin_top = 12
		dialogue_style.content_margin_bottom = 12
	else:
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
	var faceset_tex_path := "res://assets/packs/civic_nightmare/ui/ninja/dialog/FacesetBox.png"
	if ResourceLoader.exists(faceset_tex_path):
		var ps = StyleBoxTexture.new()
		ps.texture = load(faceset_tex_path)
		ps.texture_margin_left = 3
		ps.texture_margin_right = 3
		ps.texture_margin_top = 3
		ps.texture_margin_bottom = 3
		ps.content_margin_left = 4
		ps.content_margin_right = 4
		ps.content_margin_top = 4
		ps.content_margin_bottom = 4
		portrait_panel.add_theme_stylebox_override("panel", ps)
	else:
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

	# Choice panel (JRPG style selection)
	choice_container = VBoxContainer.new()
	choice_container.name = "ChoiceContainer"
	choice_container.add_theme_constant_override("separation", 4)
	choice_container.visible = false
	vbox.add_child(choice_container)

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

	current_character_id = character_id
	player.set_physics_process(false)
	is_dialogue_open = true
	is_choosing = false
	dialogue_lines.clear()
	dialogue_choices.clear()
	dialogue_line_index = 0
	dialogue_farewell = ""
	choice_container.visible = false

	# Determine dialogue content based on character type
	if character_id == "ai_terminal":
		_setup_ai_dialogue()
	else:
		_setup_politician_dialogue(character_id)

	# Set border color
	var border_color: Color = character_colors.get(character_id, Color(0.2, 0.7, 0.9))
	if dialogue_style is StyleBoxFlat:
		dialogue_style.border_color = border_color
	elif dialogue_style is StyleBoxTexture:
		dialogue_style.modulate_color = border_color.lightened(0.5)

	# Set portrait
	if portrait_paths.has(character_id) and ResourceLoader.exists(portrait_paths[character_id]):
		portrait_rect.texture = load(portrait_paths[character_id])
	else:
		portrait_rect.texture = null

	# Set name
	var c_data: Dictionary = character_data_cache.get(character_id, {})
	name_label.text = str(c_data.get("name", "C.L.A.U.D.I.A." if character_id == "ai_terminal" else "Unknown"))

	# Start first line
	continue_label.visible = false
	continue_blink = 0.0
	if dialogue_lines.size() > 0:
		_start_typewriter(str(dialogue_lines[0]))
	else:
		_start_typewriter("...")

	_animate_dialogue_in()

func _setup_ai_dialogue() -> void:
	if ai_terminal_data.is_empty():
		dialogue_lines = ["System offline. Try again later."]
		return

	var phases: Dictionary = ai_terminal_data.get("phases", {})
	var phase_key := ""

	if quest_finished:
		# Already completed — brief message
		dialogue_lines = ["You already have all signatures. Now go enjoy your passport. Or don't. I'm an AI, not your life coach."]
		return

	if quest_index < 0:
		phase_key = "intro"
		quest_index = 0
	elif quest_index < quest_order.size():
		var last_done: String = quest_order[quest_index - 1] if quest_index > 0 else ""
		if last_done != "" and quest_completed.has(last_done):
			phase_key = "after_%s" % last_done
		else:
			# Player hasn't visited the current target yet
			var target_name: String = quest_order[quest_index]
			var display := _character_display_name(target_name)
			dialogue_lines = ["You haven't talked to %s yet. Go on, I'll wait. It's not like I have feelings." % display]
			return

	if quest_index >= quest_order.size() and not quest_finished:
		phase_key = "after_%s" % quest_order[quest_order.size() - 1]
		quest_finished = true

	if phases.has(phase_key):
		var phase: Dictionary = phases[phase_key]
		dialogue_lines = phase.get("lines", ["..."])
	else:
		dialogue_lines = ["..."]

func _setup_politician_dialogue(character_id: String) -> void:
	var c_data: Dictionary = character_data_cache.get(character_id, {})
	var qd: Dictionary = c_data.get("quest_dialogue", {})

	if quest_completed.has(character_id):
		dialogue_lines = ["You already have my signature. What more do you want?"]
		return

	# Check if this is the correct target
	if quest_index >= 0 and quest_index < quest_order.size():
		if quest_order[quest_index] != character_id:
			var correct_name: String = _character_display_name(quest_order[quest_index])
			dialogue_lines = ["I wasn't expecting visitors. Try %s first." % correct_name]
			return

	if qd.is_empty():
		dialogue_lines = ["..."]
		return

	dialogue_lines = qd.get("lines", ["..."])
	dialogue_choices = qd.get("choices", [])
	dialogue_choice_prompt = str(qd.get("choice_prompt", ""))

func _advance_dialogue() -> void:
	dialogue_line_index += 1

	if dialogue_line_index < dialogue_lines.size():
		# Show next line
		continue_label.visible = false
		_start_typewriter(str(dialogue_lines[dialogue_line_index]))
	elif dialogue_choices.size() > 0 and not is_choosing:
		# Show choices
		_show_choices()
	else:
		# Done — mark quest and close
		_finish_dialogue()

func _show_choices() -> void:
	is_choosing = true
	choice_index = 0
	continue_label.visible = false
	text_label.text = dialogue_choice_prompt

	# Clear old labels
	for child in choice_container.get_children():
		child.queue_free()
	choice_labels.clear()

	for i in range(dialogue_choices.size()):
		var choice: Dictionary = dialogue_choices[i]
		var lbl := Label.new()
		lbl.text = "  %s" % str(choice.get("label", "..."))
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.82))
		choice_container.add_child(lbl)
		choice_labels.append(lbl)

	choice_container.visible = true
	_update_choice_highlight()

func _update_choice_highlight() -> void:
	for i in range(choice_labels.size()):
		var lbl: Label = choice_labels[i]
		if i == choice_index:
			lbl.text = "> %s" % str(dialogue_choices[i].get("label", "..."))
			lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.4))
		else:
			lbl.text = "  %s" % str(dialogue_choices[i].get("label", "..."))
			lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.82))

func _select_choice() -> void:
	if choice_index < 0 or choice_index >= dialogue_choices.size():
		return

	var choice: Dictionary = dialogue_choices[choice_index]
	is_choosing = false
	choice_container.visible = false
	dialogue_choices.clear()

	# Apply effects
	var effects: Dictionary = choice.get("effects", {})
	for key in effects:
		var meter_key: String = key.to_upper()
		if meter_values.has(meter_key):
			update_meter(meter_key, meter_values[meter_key] + int(effects[key]))

	# Show response lines
	var response: Array = choice.get("response", [])
	if response.size() > 0:
		dialogue_lines = response
		dialogue_line_index = 0
		continue_label.visible = false
		_start_typewriter(str(response[0]))
	else:
		_finish_dialogue()

func _finish_dialogue() -> void:
	# Mark quest completion for politicians
	if current_character_id != "ai_terminal" and not quest_completed.has(current_character_id):
		if quest_index >= 0 and quest_index < quest_order.size() and quest_order[quest_index] == current_character_id:
			quest_completed[current_character_id] = true
			quest_index += 1

	_close_dialogue()

func _start_typewriter(text: String) -> void:
	typewriter_text = text
	typewriter_index = 0
	text_label.text = ""
	typewriter_timer.start()

func _on_typewriter_tick() -> void:
	if typewriter_index < typewriter_text.length():
		var ch: String = typewriter_text[typewriter_index]
		text_label.text += ch
		typewriter_index += 1
		# Play bip on visible characters (not spaces)
		if ch != " " and ch != "." and typewriter_bip and typewriter_index % 2 == 0:
			typewriter_bip.pitch_scale = randf_range(0.9, 1.2)
			typewriter_bip.play()
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
	choice_container.visible = false
	is_choosing = false

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
