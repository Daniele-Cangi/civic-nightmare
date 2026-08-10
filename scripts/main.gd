extends Node2D

const NPC_SCENE = preload("res://scenes/npc.tscn")
const DOORWAY_SCRIPT = preload("res://scripts/doorway.gd")
const INTRO_SEQUENCE_SCRIPT = preload("res://scripts/sequences/intro_sequence.gd")
const ROOM_MANAGER_SCRIPT = preload("res://scripts/managers/room_manager.gd")
const KIM_PHONE_ENCOUNTER_SCRIPT = preload("res://scripts/encounters/kim_phone_encounter.gd")
const QUEST_MANAGER_SCRIPT = preload("res://scripts/managers/quest_manager.gd")
const DIALOGUE_MANAGER_SCRIPT = preload("res://scripts/managers/dialogue_manager.gd")
const XI_PRE_SCENE_SCRIPT = preload("res://scripts/encounters/xi_pre_scene.gd")
const BEZOS_ENCOUNTER_SCRIPT = preload("res://scripts/encounters/bezos_encounter.gd")
const ENDING_SEQUENCE_SCRIPT = preload("res://scripts/sequences/ending_sequence.gd")

@onready var ground_map: TileMap = $GroundMap
@onready var player: CharacterBody2D = $Entities/Player
@onready var entities_layer: Node2D = $Entities
@onready var ui_layer: CanvasLayer = $UI

var character_data_cache: Dictionary = {}
var dialogue_manager: Node
var is_dialogue_open: bool:
	get:
		return bool(dialogue_manager.get("is_dialogue_open")) if dialogue_manager else false
	set(value):
		if dialogue_manager:
			dialogue_manager.set("is_dialogue_open", value)
var room_manager: Node
var room_registry: Dictionary = {}
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
var dialogue_anchor: Control:
	get: return dialogue_manager.get("dialogue_anchor") as Control if dialogue_manager else null
var dialogue_style: StyleBox:
	get: return dialogue_manager.get("dialogue_style") as StyleBox if dialogue_manager else null
var portrait_rect: TextureRect:
	get: return dialogue_manager.get("portrait_rect") as TextureRect if dialogue_manager else null
var name_label: Label:
	get: return dialogue_manager.get("name_label") as Label if dialogue_manager else null
var text_label: RichTextLabel:
	get: return dialogue_manager.get("text_label") as RichTextLabel if dialogue_manager else null
var continue_label: Label:
	get: return dialogue_manager.get("continue_label") as Label if dialogue_manager else null
var typewriter_timer: Timer:
	get: return dialogue_manager.get("typewriter_timer") as Timer if dialogue_manager else null
var typewriter_bip: AudioStreamPlayer:
	get: return dialogue_manager.get("typewriter_bip") as AudioStreamPlayer if dialogue_manager else null
var choice_container: VBoxContainer:
	get: return dialogue_manager.get("choice_container") as VBoxContainer if dialogue_manager else null
var typewriter_text: String:
	get: return str(dialogue_manager.get("typewriter_text")) if dialogue_manager else ""
var typewriter_index: int:
	get: return int(dialogue_manager.get("typewriter_index")) if dialogue_manager else 0
	set(value): dialogue_manager.set("typewriter_index", value)
var continue_blink: float:
	get: return float(dialogue_manager.get("continue_blink")) if dialogue_manager else 0.0
	set(value): dialogue_manager.set("continue_blink", value)
var dialogue_rest_top: float:
	get: return float(dialogue_manager.get("dialogue_rest_top")) if dialogue_manager else -210.0
var current_character_id: String:
	get: return str(dialogue_manager.get("current_character_id")) if dialogue_manager else ""
	set(value): dialogue_manager.set("current_character_id", value)
var dialogue_lines: Array:
	get: return dialogue_manager.get("dialogue_lines") as Array
	set(value): dialogue_manager.set("dialogue_lines", value)
var dialogue_line_index: int:
	get: return int(dialogue_manager.get("dialogue_line_index"))
	set(value): dialogue_manager.set("dialogue_line_index", value)
var dialogue_choices: Array:
	get: return dialogue_manager.get("dialogue_choices") as Array
	set(value): dialogue_manager.set("dialogue_choices", value)
var dialogue_choice_prompt: String:
	get: return str(dialogue_manager.get("dialogue_choice_prompt"))
	set(value): dialogue_manager.set("dialogue_choice_prompt", value)
var dialogue_farewell: String:
	get: return str(dialogue_manager.get("dialogue_farewell"))
	set(value): dialogue_manager.set("dialogue_farewell", value)
var is_choosing: bool:
	get: return bool(dialogue_manager.get("is_choosing"))
	set(value): dialogue_manager.set("is_choosing", value)
var choice_index: int:
	get: return int(dialogue_manager.get("choice_index"))
	set(value): dialogue_manager.set("choice_index", value)

# --- Quest state ---
var quest_manager: Node
var quest_index: int:
	get:
		return int(quest_manager.get("quest_index")) if quest_manager else -1
	set(value):
		if quest_manager:
			quest_manager.set("quest_index", value)
var quest_finished: bool:
	get:
		return bool(quest_manager.get("quest_finished")) if quest_manager else false
	set(value):
		if quest_manager:
			quest_manager.set("quest_finished", value)
var ai_terminal_data: Dictionary = {}
var hidden_bunker_data: Dictionary = {}
var ai_override_lines: Array = []
var optional_ai_followup_lines: Array = []
var ufo_ai_followup_pending: bool = false
var ai_dialogue_override_active: bool = false
var seen_hidden_bunker_scene: bool = false
var hidden_bunker_scene_active: bool = false
var hidden_bunker_exit_acknowledged: bool = false
var hidden_bunker_ai_ack_pending: bool = false
var hidden_bunker_ai_ack_active: bool = false
var contamination_active: bool = false
var contamination_seen_sources: Dictionary = {}
var contamination_appearance_count: int = 0
var contamination_terminal_ready: bool = false
var contamination_terminal_dialogue_seen: bool = false
var contamination_terminal_departed: bool = false
var contamination_terminal_afterglow_pending: bool = false
var contamination_root: Node2D

# --- Encounter modules ---
var kim_phone_encounter: Node
var xi_pre_scene_encounter: Node
var xi_pre_scene_seen: bool:
	get:
		return bool(xi_pre_scene_encounter.get("xi_pre_scene_seen")) if xi_pre_scene_encounter else false
var xi_pre_scene_active: bool:
	get:
		return bool(xi_pre_scene_encounter.get("xi_pre_scene_active")) if xi_pre_scene_encounter else false

const CONTAMINATION_MAX_APPEARANCES := 3
const CONTAMINATION_SOURCE_OFFSETS := {
	"oval_office": Vector2(-116, -24),
	"kremlin": Vector2(122, -24),
	"mountain_bunker": Vector2(112, -18)
}
const CONTAMINATION_TERMINAL_OFFSET := Vector2(-140, -8)

# --- Intro sequence ---
var intro_sequence: Node
var intro_active: bool:
	get:
		return intro_sequence == null or bool(intro_sequence.get("active"))

# --- Ending sequence ---
var ending_triggered: bool = false
var ending_sequence: Node
var ending_active: bool:
	get:
		return bool(ending_sequence.get("ending_active")) if ending_sequence else false
	set(value):
		if ending_sequence:
			ending_sequence.set("ending_active", value)
var ending_layer: CanvasLayer:
	get:
		return ending_sequence.get("ending_layer") as CanvasLayer if ending_sequence else null
var ending_scenes: Array:
	get:
		return ending_sequence.get("ending_scenes") as Array if ending_sequence else []
	set(value):
		if ending_sequence:
			ending_sequence.set("ending_scenes", value)
var ending_phase: int:
	get:
		return int(ending_sequence.get("ending_phase")) if ending_sequence else 0
	set(value):
		if ending_sequence:
			ending_sequence.set("ending_phase", value)


# --- Bezos cinematic encounter ---
var bezos_encounter: Node
var bezos_cinematic_active: bool:
	get:
		return bool(bezos_encounter.get("bezos_cinematic_active")) if bezos_encounter else false
var bezos_cinematic_seen: bool:
	get:
		return bool(bezos_encounter.get("bezos_cinematic_seen")) if bezos_encounter else false


# --- Final Mission ---
var final_mission_active: bool = false
var final_mission_done: bool = false
var final_mission_margin_text: String = ""
var final_mission_choice: int = -1
var final_mission_npc: StaticBody2D
var final_mission_awaiting_input: bool = false
var final_mission_text_field: LineEdit
var postgame_free_roam_started: bool = false

# --- MK Sequence ---
var mk_sequence_active: bool = false
var mk_sequence_timer: float = 0.0
var mk_layer: CanvasLayer
var mk_finish_label: Label
var mk_countdown_label: Label
var mk_freeze_text: Label
var mk_claudia_label: Label
var mk_flash: ColorRect
var mk_sprite: TextureRect
var mk_fact_bg: ColorRect
var mk_fact_number: Label
var mk_fact_line1: Label
var mk_fact_line2: Label
var mk_red_bloom: ColorRect
var mk_execute_line: Label
var mk_ghost1: TextureRect
var mk_ghost2: TextureRect
var mk_flash_index: int = 0
enum MKState { ENTER, COUNTDOWN, EXECUTE, FREEZE, CLAUDIA_LINE, FADE_OUT }
var mk_state: int = MKState.ENTER

# --- HUD ---


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

const WORLD_MIN_X := -34
const WORLD_MAX_X := 34
const WORLD_MIN_Y := -32
const WORLD_MAX_Y := 32
const BUILDING_CLEARANCE := 10
const PATH_HALF_WIDTH := 1
const BORDER_WIDTH := 2
const GREAT_WALL_TILE := Vector2i(0, -24)
const GREAT_WALL_APPROACH_TILE := Vector2i(0, -20)
const XI_WORLD_PIXEL_OFFSET := Vector2(54, -42)
const SAM_ALTMAN_TILE := Vector2i(0, 24)
const NUCLEAR_PLANT_TILE := Vector2i(0, 28)
const UFO_TILE := Vector2i(30, -6)
const UFO_FLOAT_OFFSET := Vector2(0, -24)
const BEZOS_DRONE_TILE := Vector2i(24, 10)
const BEZOS_DRONE_FLOAT_OFFSET := Vector2(0, -14)
const HIDDEN_BUNKER_TILE := Vector2i(-29, -27)
const HIDDEN_BUNKER_WORLD_OFFSET := Vector2(12, 0)
const PYONGYANG_TILE := Vector2i(-31, 16)

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
var ufo_root: Node2D
var ufo_beam: Polygon2D
var ufo_sprite: Sprite2D
var ufo_clouds: Sprite2D
var ufo_quantum_nodes: Array[Sprite2D] = []
var ufo_base_position: Vector2 = Vector2.ZERO
var ufo_abduction_active: bool = false
var ufo_hover_time: float = 0.0
var bezos_drone_root: Node2D
var bezos_drone_base_position: Vector2 = Vector2.ZERO
var bezos_drone_hover_time: float = 0.0
var bezos_escalation_active: bool = false
var bezos_escalation_step: int = 0
var bezos_escalation_timer: float = 0.0
var bezos_escalation_space_latched: bool = false
var bezos_escalation_bip_tween: Tween
var bezos_escalation_bubble: PanelContainer
var bezos_escalation_speaker_label: Label
var bezos_escalation_text_label: Label
var hidden_bunker_root: Node2D

# --- Hidden bunker cutscene ---
var bunker_caption_anchor: Control
var bunker_caption_panel: PanelContainer
var bunker_caption_speaker: Label
var bunker_caption_text: RichTextLabel

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
# Field terrain biome tiles
const FD_DIRT := Vector2i(1, 0)
const FD_DIRT2 := Vector2i(3, 0)
const FD_LGREEN := Vector2i(1, 2)
const FD_LGREEN2 := Vector2i(3, 2)
const FD_GRASS := Vector2i(1, 4)
const FD_GRASS2 := Vector2i(3, 4)
const FD_PINK := Vector2i(1, 6)
const FD_PINK2 := Vector2i(3, 6)
const FD_SNOW := Vector2i(1, 8)
const FD_SNOW2 := Vector2i(3, 8)
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

# --- Biome system: each building has a climate zone ---
# Biome IDs
enum Biome { DEFAULT, AMERICAN, MARTIAN, EUROPEAN, SIBERIAN, FINANCIAL, FRENCH }

# Tree variants per biome (from nature_32.png)
var trees_green: Array = [
	{"size": Vector2i(2, 2), "tiles": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], "solid_offset": Vector2i(0, 1)},
	{"size": Vector2i(2, 2), "tiles": [Vector2i(8, 0), Vector2i(9, 0), Vector2i(8, 1), Vector2i(9, 1)], "solid_offset": Vector2i(0, 1)},
	{"size": Vector2i(2, 2), "tiles": [Vector2i(10, 0), Vector2i(11, 0), Vector2i(10, 1), Vector2i(11, 1)], "solid_offset": Vector2i(0, 1)},
	{"size": Vector2i(2, 2), "tiles": [Vector2i(12, 0), Vector2i(13, 0), Vector2i(12, 1), Vector2i(13, 1)], "solid_offset": Vector2i(0, 1)},
]
var trees_snow: Array = [
	{"size": Vector2i(2, 2), "tiles": [Vector2i(4, 0), Vector2i(5, 0), Vector2i(4, 1), Vector2i(5, 1)], "solid_offset": Vector2i(0, 1)},
	{"size": Vector2i(2, 2), "tiles": [Vector2i(4, 4), Vector2i(5, 4), Vector2i(4, 5), Vector2i(5, 5)], "solid_offset": Vector2i(0, 1)},
]
var trees_pink: Array = [
	{"size": Vector2i(2, 2), "tiles": [Vector2i(6, 0), Vector2i(7, 0), Vector2i(6, 1), Vector2i(7, 1)], "solid_offset": Vector2i(0, 1)},
]
var trees_dead: Array = [
	{"size": Vector2i(2, 2), "tiles": [Vector2i(0, 4), Vector2i(1, 4), Vector2i(0, 5), Vector2i(1, 5)], "solid_offset": Vector2i(0, 1)},
]

# Decorations per biome
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
# Small plants, stumps, cacti from nature_32
var stump_tiles: Array = [
	Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)
]
var cactus_tiles: Array = [
	Vector2i(8, 7), Vector2i(9, 7)
]

var biome_map: Dictionary = {}  # Vector2i -> Biome

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
	"emmanuel_macron": Color(0.18, 0.22, 0.58),
	"xi_jinping": Color(0.7, 0.12, 0.12),
	"sam_altman": Color(0.6, 0.62, 0.65),
	"ufo_easter_egg": Color(0.58, 0.96, 0.78),
	"mark_zuckerberg_ufo": Color(0.12, 0.12, 0.12),
	"historical_contamination": Color(0.32, 0.32, 0.34),
	"self": Color(0.75, 0.75, 0.82),
	"mojtaba_khamenei": Color(0.12, 0.45, 0.12), # Iranian Green
	"swedish_pm": Color(0.12, 0.45, 0.82), # Swedish Blue
	"jeff_bezos": Color(1.0, 0.5, 0.0) # Amazon Orange
}
var portrait_paths: Dictionary = {
	"donald_trump": "res://assets/mockups/trump_combat_portrait.png",
	"elon_musk": "res://assets/mockups/musk_combat_portrait.png",
	"ursula_von_der_leyen": "res://assets/mockups/vdl_combat_portrait.png",
	"christine_lagarde": "res://assets/mockups/lagarde_combat_portrait.png",
	"vladimir_putin": "res://assets/mockups/putin_combat_portrait.png",
	"emmanuel_macron": "res://assets/mockups/macron_combat_portrait.png",
	"xi_jinping": "res://assets/mockups/xi_jinping_caricature.png",
	"sam_altman": "res://assets/mockups/sam_altman_caricature.png",
	"ai_terminal": "res://assets/mockups/ai_terminal_caricature.png",
	"ufo_easter_egg": "res://assets/mockups/einstein_caricature.png",
	"mark_zuckerberg_ufo": "res://assets/mockups/zuckerberg_caricature.png",
	"historical_contamination": "res://assets/mockups/contamination_portrait.png",
	"ZELENSKY": "res://assets/mockups/zelensky_portrait.png",
	"DEATH": "res://assets/mockups/death_ironic.png",
	"kim_jong_un": "res://assets/mockups/kim_jong_un_portrait.png",
	"mojtaba_khamenei": "res://assets/mockups/mojtaba_portrait.png",
	"swedish_pm": "res://assets/mockups/swedish_pm_portrait.png",
	"jeff_bezos": "res://assets/mockups/bezos_portrait.png"
}
var combat_portrait_paths: Dictionary = {
	"donald_trump": "res://assets/mockups/trump_combat_portrait.png",
	"elon_musk": "res://assets/mockups/musk_combat_portrait.png",
	"ursula_von_der_leyen": "res://assets/mockups/vdl_combat_portrait.png",
	"christine_lagarde": "res://assets/mockups/lagarde_combat_portrait.png",
	"vladimir_putin": "res://assets/mockups/putin_combat_portrait.png",
	"emmanuel_macron": "res://assets/mockups/macron_combat_portrait.png"
}
var npc_sprite_paths: Dictionary = {
	"donald_trump": "res://assets/mockups/trump_pure_sprite.png",
	"elon_musk": "res://assets/mockups/musk_pure_sprite.png",
	"ursula_von_der_leyen": "res://assets/mockups/vdl_pure_sprite.png",
	"christine_lagarde": "res://assets/mockups/lagarde_pure_sprite.png",
	"vladimir_putin": "res://assets/mockups/putin_pure_sprite.png",
	"emmanuel_macron": "res://assets/mockups/macron_pure_sprite.png",
	"xi_jinping": "res://assets/characters/xi_jinping.png",
	"sam_altman": "res://assets/characters/sam_altman.png",
	"ufo_easter_egg": "res://assets/characters/einstein_sprite.png",
	"mark_zuckerberg_ufo": "res://assets/characters/zuckerberg_sprite.png",
	"zelensky_bunker": "res://assets/mockups/zelensky_move.png",
	"death_bunker": "res://assets/mockups/death_ironic.png",
	"kim_jong_un": "res://assets/mockups/kim_jong_un_sprite.png"
}

const NPC_TARGET_SPRITE_HEIGHT := 128.0
var npc_facing_defaults: Dictionary = {
	"donald_trump": false,
	"elon_musk": false,
	"ursula_von_der_leyen": false,
	"christine_lagarde": false,
	"vladimir_putin": true,
	"emmanuel_macron": false,
	"xi_jinping": false,
	"sam_altman": false,
	"kim_jong_un": false
}
var landmark_sprite_paths: Dictionary = {
	"donald_trump": "res://assets/mockups/landmark_trump.png",
	"elon_musk": "res://assets/mockups/landmark_musk.png",
	"ursula_von_der_leyen": "res://assets/mockups/landmark_vdl.png",
	"christine_lagarde": "res://assets/mockups/landmark_lagarde.png",
	"vladimir_putin": "res://assets/mockups/landmark_putin.png",
	"emmanuel_macron": "res://assets/mockups/landmark_macron_ruined.png",
	"xi_jinping": "res://assets/mockups/landmark_great_wall.png",
	"sam_altman": "res://assets/mockups/landmark_nuclear_plant.png",
	"pyongyang": "res://assets/mockups/landmark_pyongyang.png"
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

func _setup_quest_manager() -> void:
	quest_manager = QUEST_MANAGER_SCRIPT.new()
	quest_manager.name = "QuestManager"
	add_child(quest_manager)

func _ready() -> void:
	_setup_quest_manager()
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
	_create_bunker_caption_ui()
	_create_transition_fx()
	_setup_interiors()
	_remove_world_npcs()
	_create_great_wall_landmark()
	_create_sam_altman_encounter()
	_create_ufo_easter_egg()
	_create_bezos_drone_encounter()
	_create_hidden_bunker_entrance()
	_create_pyongyang_landmark()
	_ensure_contamination_figure()
	_assign_npc_textures()
	_create_ai_terminal()
	_create_typewriter_bip()
	_setup_ambient_audio()
	_create_atmosphere_particles()
	_setup_intro_sequence()
	_create_ending_overlay()
	_create_bezos_cinematic_overlay()
	_create_mk_overlay()

func _remove_world_npcs() -> void:
	for child in entities_layer.get_children():
		if child == player:
			continue
		if child.is_in_group("npc"):
			entities_layer.remove_child(child)
			child.queue_free()

func _create_great_wall_landmark() -> void:
	_clear_decor_patch(GREAT_WALL_TILE, 4, 3)

	var tex_path = "res://assets/mockups/landmark_great_wall.png"
	if not ResourceLoader.exists(tex_path):
		return

	var root := Node2D.new()
	root.name = "GreatWallEntrance"
	root.position = _tile_to_body_position(GREAT_WALL_TILE)
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

func _create_sam_altman_encounter() -> void:
	_clear_decor_patch(NUCLEAR_PLANT_TILE, 4, 3)

	var tex_path = "res://assets/mockups/landmark_nuclear_plant.png"
	if not ResourceLoader.exists(tex_path):
		return

	var root := Node2D.new()
	root.name = "NuclearPlantEntrance"
	root.position = _tile_to_body_position(NUCLEAR_PLANT_TILE)
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

func _create_ufo_easter_egg() -> void:
	_clear_decor_patch(UFO_TILE, 3, 2)

	ufo_root = Node2D.new()
	ufo_root.name = "UfoEasterEgg"
	ufo_base_position = _tile_to_body_position(UFO_TILE) + UFO_FLOAT_OFFSET
	ufo_root.position = ufo_base_position
	ufo_root.z_index = 4
	entities_layer.add_child(ufo_root)

	# 1. Shadow (remain procedural as it fits perfectly)
	var shadow = Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.18)
	shadow.polygon = _ellipse_points(Vector2(0, 28), Vector2(54, 14), 18)
	ufo_root.add_child(shadow)

	# 2. Black Clouds above
	ufo_clouds = Sprite2D.new()
	ufo_clouds.texture = load("res://assets/mockups/ufo_clouds.png")
	ufo_clouds.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ufo_clouds.scale = Vector2(0.4, 0.4)
	ufo_clouds.position = Vector2(0, -120)
	ufo_clouds.modulate.a = 0.8
	ufo_root.add_child(ufo_clouds)

	# 3. Beam (remain procedural translucent)
	ufo_beam = Polygon2D.new()
	ufo_beam.color = Color(0.72, 1.0, 0.82, 0.18)
	ufo_beam.polygon = PackedVector2Array([
		Vector2(-24, 10),
		Vector2(24, 10),
		Vector2(68, 106),
		Vector2(-68, 106)
	])
	ufo_root.add_child(ufo_beam)

	# 4. Advanced UFO Sprite
	ufo_sprite = Sprite2D.new()
	ufo_sprite.texture = load("res://assets/mockups/ufo_advanced.png")
	ufo_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ufo_sprite.scale = Vector2(0.22, 0.22) # Scale down 640px to ~140px
	ufo_root.add_child(ufo_sprite)

	# 5. Quantum Lightning (Symbol Flicker)
	var sym_tex = load("res://assets/mockups/quantum_symbols.png")
	for i in range(8):
		var sym = Sprite2D.new()
		sym.texture = sym_tex
		sym.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sym.region_enabled = true
		# Pick a random 64x64 region from 640x640 sheet (approx)
		var rx = (randi() % 10) * 64
		var ry = (randi() % 10) * 64
		sym.region_rect = Rect2(rx, ry, 64, 64)
		sym.scale = Vector2(0.4, 0.4)
		sym.modulate = Color(0.5, 1.0, 0.6, 0.0) # Start invisible
		ufo_root.add_child(sym)
		ufo_quantum_nodes.append(sym)

	# 6. Interaction Trigger
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
	trigger.body_entered.connect(_on_ufo_trigger_body_entered)
	ufo_root.add_child(trigger)

func _create_bezos_drone_encounter() -> void:
	_clear_decor_patch(BEZOS_DRONE_TILE, 2, 2)

	bezos_drone_root = Node2D.new()
	bezos_drone_root.name = "BezosDroneEncounter"
	bezos_drone_base_position = _tile_to_body_position(BEZOS_DRONE_TILE) + BEZOS_DRONE_FLOAT_OFFSET
	bezos_drone_root.position = bezos_drone_base_position
	bezos_drone_root.z_index = 4
	entities_layer.add_child(bezos_drone_root)

	# 1. Shadow (remain procedural as it fits perfectly)
	var shadow := Polygon2D.new()
	shadow.color = Color(0.0, 0.0, 0.0, 0.18)
	shadow.polygon = _ellipse_points(Vector2(0, 30), Vector2(40, 12), 16)
	bezos_drone_root.add_child(shadow)

	# 2. Advanced Mamazon Drone Sprite
	var sprite = Sprite2D.new()
	sprite.texture = load("res://assets/mockups/bezos_drone.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.85, 0.85)
	sprite.z_index = 1
	bezos_drone_root.add_child(sprite)

	var canopy := Polygon2D.new()
	canopy.color = Color(0.98, 0.82, 0.3, 0.94)
	canopy.polygon = PackedVector2Array([
		Vector2(-14, -6),
		Vector2(14, -6),
		Vector2(20, 4),
		Vector2(0, 12),
		Vector2(-20, 4)
	])
	bezos_drone_root.add_child(canopy)

	var glow := Polygon2D.new()
	glow.name = "GlowLight"
	glow.color = Color(0.98, 0.82, 0.3, 0.82)
	glow.polygon = _ellipse_points(Vector2(0, 10), Vector2(10, 6), 12)
	bezos_drone_root.add_child(glow)

	var logo := Label.new()
	logo.name = "DroneLogo"
	logo.text = "A M Z N  AIR"
	logo.position = Vector2(-52, 44)
	logo.add_theme_font_size_override("font_size", 12)
	logo.add_theme_color_override("font_color", Color(0.98, 0.82, 0.3, 0.92))
	logo.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	logo.add_theme_constant_override("shadow_offset_x", 1)
	logo.add_theme_constant_override("shadow_offset_y", 1)
	bezos_drone_root.add_child(logo)

	var motto := Label.new()
	motto.name = "DroneMotto"
	motto.text = "DELIVERY IS DESTINY"
	motto.position = Vector2(-72, 58)
	motto.add_theme_font_size_override("font_size", 8)
	motto.add_theme_color_override("font_color", Color(0.98, 0.82, 0.3, 0.92))
	motto.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	motto.add_theme_constant_override("shadow_offset_x", 1)
	motto.add_theme_constant_override("shadow_offset_y", 1)
	motto.visible = false
	bezos_drone_root.add_child(motto)

	var trigger := Area2D.new()
	trigger.name = "BezosDroneTrigger"
	trigger.collision_layer = 0
	trigger.collision_mask = 1
	trigger.monitoring = true
	trigger.monitorable = true
	var trigger_shape := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(160, 112)
	trigger_shape.shape = shape
	trigger_shape.position = Vector2(0, 42)
	trigger.add_child(trigger_shape)
	trigger.body_entered.connect(_on_bezos_drone_trigger_body_entered)
	bezos_drone_root.add_child(trigger)

func _on_bezos_drone_trigger_body_entered(body: Node) -> void:
	if body != player:
		return
	if bezos_cinematic_seen or bezos_cinematic_active or bezos_escalation_active or ufo_abduction_active or contamination_active:
		return
	if is_room_transition or intro_active or ending_active or is_dialogue_open or active_room_id != "":
		return
	call_deferred("_start_bezos_escalation")

func _start_bezos_escalation() -> void:
	if bezos_cinematic_seen or bezos_cinematic_active or bezos_escalation_active or contamination_active:
		return
	bezos_escalation_active = true
	bezos_escalation_step = 0
	bezos_escalation_timer = 0.0
	bezos_escalation_space_latched = Input.is_physical_key_pressed(KEY_SPACE)
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	is_dialogue_open = false
	if dialogue_anchor:
		dialogue_anchor.visible = false
	if typewriter_timer:
		typewriter_timer.stop()
	if bezos_drone_root:
		var trigger := bezos_drone_root.get_node_or_null("BezosDroneTrigger") as Area2D
		if trigger:
			trigger.monitoring = false
		var motto := bezos_drone_root.get_node_or_null("DroneMotto") as Label
		if motto:
			motto.visible = true
	# Create in-world speech bubble above drone
	_create_bezos_escalation_bubble()
	_set_bezos_escalation_line(
		"AMZN DRONE",
		"Your Prime trial expired 1,247 days ago.\nRenew now?   [ YES ]   [ YES IN YELLOW ]",
		Color(1.0, 0.82, 0.3)
	)

func _is_bezos_escalation_advance_pressed() -> bool:
	var space_down := Input.is_physical_key_pressed(KEY_SPACE)
	var space_pressed := space_down and not bezos_escalation_space_latched
	bezos_escalation_space_latched = space_down
	return Input.is_action_just_pressed("ui_accept") or space_pressed

func _create_bezos_escalation_bubble() -> void:
	if bezos_escalation_bubble:
		bezos_escalation_bubble.queue_free()
	bezos_escalation_bubble = PanelContainer.new()
	bezos_escalation_bubble.position = Vector2(-150, -105)
	bezos_escalation_bubble.size = Vector2(300, 88)
	bezos_escalation_bubble.z_index = 10
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.08, 0.92)
	style.border_color = Color(0.98, 0.82, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	bezos_escalation_bubble.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	bezos_escalation_bubble.add_child(vbox)
	bezos_escalation_speaker_label = Label.new()
	bezos_escalation_speaker_label.add_theme_font_size_override("font_size", 10)
	bezos_escalation_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	vbox.add_child(bezos_escalation_speaker_label)
	bezos_escalation_text_label = Label.new()
	bezos_escalation_text_label.add_theme_font_size_override("font_size", 9)
	bezos_escalation_text_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.96))
	bezos_escalation_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(bezos_escalation_text_label)
	bezos_drone_root.add_child(bezos_escalation_bubble)
	bezos_escalation_bubble.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(bezos_escalation_bubble, "modulate:a", 1.0, 0.25)

func _set_bezos_escalation_line(speaker: String, text: String, color: Color) -> void:
	if not bezos_escalation_speaker_label or not bezos_escalation_text_label:
		return
	bezos_escalation_speaker_label.text = speaker
	bezos_escalation_speaker_label.add_theme_color_override("font_color", color)
	bezos_escalation_text_label.text = text
	_play_bezos_escalation_bips(text, speaker)
	# Flash effect on new line
	if bezos_escalation_bubble:
		bezos_escalation_bubble.modulate = Color(1.4, 1.4, 1.4, 1.0)
		var tw := create_tween()
		tw.tween_property(bezos_escalation_bubble, "modulate", Color.WHITE, 0.2)

func _play_bezos_escalation_bips(text: String, speaker: String) -> void:
	if not typewriter_bip:
		return
	if bezos_escalation_bip_tween and bezos_escalation_bip_tween.is_valid():
		bezos_escalation_bip_tween.kill()

	var stripped_len := text.replace(" ", "").replace("\n", "").length()
	var burst_count := clampi(int(ceil(stripped_len / 18.0)), 2, 6)
	var pitch_min := 0.96
	var pitch_max := 1.12
	match speaker:
		"AMZN DRONE":
			pitch_min = 1.12
			pitch_max = 1.24
		"BEZOS":
			pitch_min = 0.86
			pitch_max = 0.98
		"CITIZEN":
			pitch_min = 0.98
			pitch_max = 1.1

	bezos_escalation_bip_tween = create_tween()
	for i in range(burst_count):
		bezos_escalation_bip_tween.tween_callback(func():
			if not typewriter_bip:
				return
			typewriter_bip.pitch_scale = randf_range(pitch_min, pitch_max)
			typewriter_bip.play()
		)
		if i < burst_count - 1:
			bezos_escalation_bip_tween.tween_interval(0.045)

func _start_bezos_cinematic() -> void:
	bezos_escalation_active = false
	if bezos_escalation_bip_tween and bezos_escalation_bip_tween.is_valid():
		bezos_escalation_bip_tween.kill()
	if bezos_escalation_bubble:
		bezos_escalation_bubble.queue_free()
		bezos_escalation_bubble = null

	await _fade_transition(1.0, 0.15)
	if transition_overlay:
		transition_overlay.visible = false
		transition_overlay.modulate.a = 0.0
	bezos_encounter.start()


func _create_hidden_bunker_entrance() -> void:
	_clear_decor_patch(HIDDEN_BUNKER_TILE, 3, 2)

	hidden_bunker_root = Node2D.new()
	hidden_bunker_root.name = "HiddenBunkerEntrance"
	hidden_bunker_root.position = _tile_to_body_position(HIDDEN_BUNKER_TILE) + HIDDEN_BUNKER_WORLD_OFFSET
	hidden_bunker_root.z_index = 2
	entities_layer.add_child(hidden_bunker_root)

	var shadow := Polygon2D.new()
	shadow.color = Color(0.0, 0.0, 0.0, 0.16)
	shadow.polygon = PackedVector2Array([
		Vector2(-116, 54),
		Vector2(116, 54),
		Vector2(86, 90),
		Vector2(-86, 90)
	])
	hidden_bunker_root.add_child(shadow)

	var mountain = Sprite2D.new()
	mountain.texture = load("res://assets/mockups/landmark_bunker.png")
	mountain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mountain.scale = Vector2(0.42, 0.42)
	mountain.offset = Vector2(0, -10)
	hidden_bunker_root.add_child(mountain)

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
	hidden_bunker_root.add_child(door)

func _create_pyongyang_landmark() -> void:
	_clear_decor_patch(PYONGYANG_TILE, 4, 3)

	var tex_path = "res://assets/mockups/landmark_pyongyang.png"
	if not ResourceLoader.exists(tex_path):
		return

	var root := Node2D.new()
	root.name = "PyongyangEntrance"
	root.position = _tile_to_body_position(PYONGYANG_TILE)
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

func _on_ufo_trigger_body_entered(body: Node) -> void:
	if body != player:
		return
	if ufo_abduction_active or is_room_transition or intro_active or ending_active or is_dialogue_open or active_room_id != "":
		return
	call_deferred("_start_ufo_abduction")

func _start_ufo_abduction() -> void:
	if ufo_abduction_active or is_room_transition or intro_active or ending_active or is_dialogue_open or active_room_id != "":
		return
	ufo_abduction_active = true
	is_room_transition = true
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	if screen_fx_material:
		screen_fx_material.set_shader_parameter("effect_strength", 0.16)
		screen_fx_material.set_shader_parameter("color_levels", 8.0)
		screen_fx_material.set_shader_parameter("scanline_strength", 0.07)
		screen_fx_material.set_shader_parameter("vignette_strength", 0.24)
		screen_fx_material.set_shader_parameter("overlay_strength", 0.34)
		screen_fx_material.set_shader_parameter("tint_color", Color(0.8, 1.0, 0.88, 1.0))

	_show_room_title("UNIDENTIFIED CRAFT", "Please remain vaguely calm.")
	await _fade_transition(1.0, 0.08)
	_enter_room("ufo_lab", "EntryMarker")
	_set_room_presentation(true)
	_show_room_title("OBSERVATION DECK", "Two geniuses. One functioning calculator.")
	await _fade_transition(0.0, 0.14)
	if not is_dialogue_open:
		player.set_physics_process(true)
	ufo_abduction_active = false
	is_room_transition = false

func _clear_decor_near_xi(npc: Node2D) -> void:
	var xi_tile := Vector2i(
		roundi((npc.position.x - 16.0) / 32.0),
		roundi((npc.position.y - 16.0) / 32.0)
	)
	_clear_decor_patch(xi_tile, 3, 2)

func _clear_decor_patch(center_tile: Vector2i, x_radius: int, y_radius: int) -> void:
	for x in range(center_tile.x - x_radius, center_tile.x + x_radius + 1):
		for y in range(center_tile.y - y_radius, center_tile.y + y_radius + 2):
			ground_map.erase_cell(LAYER_DECOR, Vector2i(x, y))

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
		var cols = int(float(tex.get_width()) / 32.0)
		var rows = int(float(tex.get_height()) / 32.0)
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

func _ensure_room_manager() -> void:
	if room_manager:
		return
	room_manager = ROOM_MANAGER_SCRIPT.new()
	room_manager.name = "RoomManager"
	add_child(room_manager)
	room_manager.setup(self, entities_layer, player)

func _setup_interiors() -> void:
	_ensure_room_manager()
	var special_specs: Array = [
		{
			"key": "ufo_lab",
			"node_name": "UfoLabInterior",
			"character_id": "ufo_easter_egg",
			"character_name": "Albert Einstein",
			"spawn_marker": "ufo_lab_exterior",
			"world_position": _tile_to_actor_position(UFO_TILE + Vector2i(0, 3))
		},
		{
			"key": "mountain_bunker",
			"node_name": "HiddenBunkerInterior",
			"character_id": "hidden_bunker_scene",
			"character_name": "Hidden Bunker",
			"spawn_marker": "mountain_bunker_exterior",
			"world_position": _tile_to_actor_position(HIDDEN_BUNKER_TILE + Vector2i(0, 2)) + HIDDEN_BUNKER_WORLD_OFFSET
		},
		{
			"key": "red_command",
			"node_name": "RedCommandInterior",
			"character_id": "xi_jinping",
			"character_name": "Xi Jinping",
			"spawn_marker": "red_command_exterior",
			"world_position": _tile_to_actor_position(GREAT_WALL_TILE + Vector2i(0, 3))
		},
		{
			"key": "pyongyang_command",
			"node_name": "PyongyangCommandInterior",
			"character_id": "kim_jong_un",
			"character_name": "Kim Jong-un",
			"spawn_marker": "pyongyang_command_exterior",
			"world_position": _tile_to_actor_position(PYONGYANG_TILE + Vector2i(0, 3))
		},
		{
			"key": "neural_core",
			"node_name": "NeuralCoreInterior",
			"character_id": "sam_altman",
			"character_name": "Sam Altman",
			"spawn_marker": "neural_core_exterior",
			"world_position": _tile_to_actor_position(NUCLEAR_PLANT_TILE + Vector2i(0, -3))
		}
	]
	room_manager.setup_interiors(building_specs, special_specs, Callable(self, "_character_display_name"))
	room_registry = room_manager.room_registry


func use_door(destination: String, spawn_marker: String) -> void:
	if is_dialogue_open or is_room_transition or hidden_bunker_scene_active or contamination_active or xi_pre_scene_active:
		return
	var now := Time.get_ticks_msec()
	if now < door_cooldown_until_ms:
		return
	door_cooldown_until_ms = now + 550
	var contamination_source := active_room_id if destination == "world" else ""
	var leaving_hidden_bunker := destination == "world" and active_room_id == "mountain_bunker"
	var leaving_ufo_lab := destination == "world" and active_room_id == "ufo_lab"
	var entering_hidden_bunker := destination == "mountain_bunker" and not seen_hidden_bunker_scene
	is_room_transition = true
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	var door_sfx = get_node_or_null("DoorSFX")
	if door_sfx:
		door_sfx.play()
	await _fade_transition(1.0, 0.14)
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
	await _fade_transition(0.0, 0.18)
	if not is_dialogue_open:
		player.set_physics_process(true)
	is_room_transition = false
	if entering_hidden_bunker:
		call_deferred("_start_hidden_bunker_scene")
	elif destination == "ufo_lab":
		call_deferred("_start_ufo_lab_scene")
	elif leaving_hidden_bunker and seen_hidden_bunker_scene and not hidden_bunker_exit_acknowledged:
		hidden_bunker_exit_acknowledged = true
		hidden_bunker_ai_ack_pending = true
	elif leaving_ufo_lab and ufo_ai_followup_pending:
		call_deferred("_try_open_optional_ai_followup")
	if destination == "world":
		call_deferred("_maybe_queue_contamination_event", contamination_source)

func _enter_room(room_id: String, spawn_marker: String) -> void:
	if not room_manager.enter_room(room_id, active_room_id, spawn_marker):
		return
	active_room_id = room_id
	var room = room_registry.get(room_id)
	if room_id == "red_command" and not xi_pre_scene_seen and not xi_pre_scene_active:
		if room.has_method("set_npc_interaction_enabled"):
			room.set_npc_interaction_enabled(false)
		call_deferred("_start_xi_pre_scene")

func _exit_room(spawn_marker: String) -> void:
	room_manager.exit_room(active_room_id, spawn_marker)
	active_room_id = ""

func _fade_transition(target_alpha: float, duration: float) -> void:
	await room_manager.fade_transition(target_alpha, duration)

func _set_room_presentation(indoor: bool) -> void:
	room_manager.set_room_presentation(indoor, world_canvas_modulate, screen_fx_material, hud_panel)

func _show_room_title(title: String, subtitle: String = "") -> void:
	room_manager.show_room_title(title, subtitle)


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

func _ellipse_points(center: Vector2, radius: Vector2, segments: int = 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points

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
	if intro_active:
		intro_sequence.process_frame(delta)
		return
	if ending_active:
		ending_sequence.process_frame(delta)
		return
	if bezos_cinematic_active:
		bezos_encounter.process_frame(delta)
		return
	_process_ufo_easter_egg(delta)
	_process_bezos_drone(delta)
	_process_ai_terminal(delta)
	_process_mk_sequence(delta)
	if kim_phone_encounter and bool(kim_phone_encounter.get("active")):
		kim_phone_encounter.process_frame(delta)
	if xi_pre_scene_active and Input.is_action_just_pressed("ui_accept"):
		xi_pre_scene_encounter.request_skip()
	if dialogue_manager:
		dialogue_manager.process_frame(delta)


func _process_ufo_easter_egg(delta: float) -> void:
	if not ufo_root:
		return

	ufo_hover_time += delta * 1.8
	# Left-right swaying + vertical hover
	var sway = sin(ufo_hover_time * 0.5) * 24.0
	var hover = sin(ufo_hover_time) * 6.0
	ufo_root.position = ufo_base_position + Vector2(sway, hover)
	
	if ufo_beam:
		ufo_beam.modulate.a = 0.14 + (sin(ufo_hover_time * 2.4) * 0.08 + 0.08)

	# Animate Quantum Lightning
	for sym in ufo_quantum_nodes:
		if randf() < delta * 4.0: # Rare flicker trigger
			var angle = randf() * TAU
			var dist = randf_range(40, 90)
			sym.position = Vector2(cos(angle) * dist, sin(angle) * dist - 40.0)
			sym.modulate.a = 0.8
			sym.scale = Vector2(randf_range(0.3, 0.5), randf_range(0.3, 0.5))
			# Random symbol region
			var rx = (randi() % 8) * 80
			var ry = (randi() % 8) * 80
			sym.region_rect = Rect2(rx, ry, 80, 80)
		else:
			sym.modulate.a = max(0.0, sym.modulate.a - delta * 4.0)

	# Slow cloud movement
	if ufo_clouds:
		ufo_clouds.position.x = -sway * 0.5 # Parallax feel

func _process_bezos_drone(delta: float) -> void:
	if not bezos_drone_root:
		return

	bezos_drone_hover_time += delta * 2.1
	bezos_drone_root.position = bezos_drone_base_position + Vector2(0.0, sin(bezos_drone_hover_time) * 3.0)
	var glow := bezos_drone_root.get_node_or_null("GlowLight") as Polygon2D
	if glow:
		glow.modulate.a = 0.75 + sin(bezos_drone_hover_time * 3.6) * 0.18

	# --- In-world escalation dialogue ---
	if not bezos_escalation_active:
		return
	bezos_escalation_timer += delta
	# Drone shakes more as conversation heats up
	if bezos_escalation_step >= 4:
		var shake := sin(bezos_escalation_timer * 22.0) * 2.0
		bezos_drone_root.position.x = bezos_drone_base_position.x + shake
	elif bezos_escalation_step >= 2:
		var shake := sin(bezos_escalation_timer * 14.0) * 0.8
		bezos_drone_root.position.x = bezos_drone_base_position.x + shake

	var advance_pressed := _is_bezos_escalation_advance_pressed()

	# --- Contamination Spectral Breathing & Shader ---
	if contamination_root and contamination_root.visible:
		var spr := contamination_root.get_node_or_null("Sprite") as Sprite2D
		if spr:
			var base_scale := float(spr.get_meta("base_scale", 0.22))
			var breath := 1.0 + sin(Time.get_ticks_msec() * 0.003) * 0.03
			spr.scale = Vector2(base_scale, base_scale * breath)
			if spr.material is ShaderMaterial:
				spr.material.set_shader_parameter("time", Time.get_ticks_msec() * 0.001)

	match bezos_escalation_step:
		0:
			if advance_pressed:
				bezos_escalation_step = 1
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"...Where's the 'no' button?",
					Color(0.4, 0.75, 1.0)
				)
		1:
			if advance_pressed:
				bezos_escalation_step = 2
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"AMZN DRONE",
					"That option was deprecated.\nAlgorithmically, you already said yes.",
					Color(1.0, 0.82, 0.3)
				)
		2:
			if advance_pressed:
				bezos_escalation_step = 3
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"I was just WALKING past a drone!\nThat counts as consent?!",
					Color(0.4, 0.75, 1.0)
				)
		3:
			if advance_pressed:
				bezos_escalation_step = 4
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"AMZN DRONE",
					"Proximity within 8 meters of an Amazon device\nconstitutes passive agreement.\nSee Terms of Service §47, clause 'Existence'.",
					Color(1.0, 0.82, 0.3)
				)
		4:
			if advance_pressed:
				bezos_escalation_step = 5
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"Your workers pee in BOTTLES.\nYou timed their toilet breaks to the SECOND\nand fired them for going over.",
					Color(0.4, 0.75, 1.0)
				)
		5:
			if advance_pressed:
				bezos_escalation_step = 6
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"BEZOS",
					"Bladder efficiency is an untapped frontier.\nWe are DISRUPTING hydration logistics.\nThe market demands it.",
					Color(1.0, 0.92, 0.16)
				)
		6:
			if advance_pressed:
				bezos_escalation_step = 7
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"You had a BRIDGE dismantled in Rotterdam\nto move your $500M megayacht out of port.\nA HISTORIC BRIDGE. For a @#$%ing BOAT.",
					Color(0.4, 0.75, 1.0)
				)
		7:
			if advance_pressed:
				bezos_escalation_step = 8
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"BEZOS",
					"It was structurally non-optimal.\nI liberated it from its original purpose.\nYou're welcome, Rotterdam.",
					Color(1.0, 0.92, 0.16)
				)
		8:
			if advance_pressed:
				bezos_escalation_step = 9
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"Your ex-wife gave away $17 BILLION to charity\nwhile you were buying a ROCKET\nshaped like a—  ...you know what it looks like.",
					Color(0.4, 0.75, 1.0)
				)
		9:
			if advance_pressed:
				bezos_escalation_step = 10
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"BEZOS",
					"Blue Origin is a LEGACY project for humanity.\nAlso she was slowing down my optimization.\nHer tax write-offs are frankly excessive.",
					Color(1.0, 0.92, 0.16)
				)
		10:
			if advance_pressed:
				bezos_escalation_step = 11
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"Your Ring doorbells helped arrest more\ninnocent people than any spy network.\nYou turned SUBURBIA into a SURVEILLANCE STATE.",
					Color(0.4, 0.75, 1.0)
				)
		11:
			if advance_pressed:
				# --- TRANSITION TO CHAT BOX ---
				# Instead of the floating bubble, we now trigger the high-fidelity Terminator Card chat.
				bezos_escalation_active = false
				if bezos_escalation_bubble:
					bezos_escalation_bubble.visible = false
				
				# Ensure variables are reset for the post-dialogue cinematic trigger
				bezos_escalation_step = 12
				call_deferred("open_dialogue", "jeff_bezos")
		12:
			# This step is now handled by the dialogue system's callback
			pass
		13:
			# Cinematic state
			pass


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

	min_y = mini(min_y, GREAT_WALL_APPROACH_TILE.y)
	_mark_path_line(Vector2i(0, min_y), Vector2i(0, max_y), PATH_HALF_WIDTH)
	_mark_path_rect(GREAT_WALL_APPROACH_TILE - Vector2i(2, 1), GREAT_WALL_APPROACH_TILE + Vector2i(2, 1))

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

func _build_biome_map() -> void:
	biome_map.clear()
	var biome_radius := BUILDING_CLEARANCE + 4
	for spec in building_specs:
		var center: Vector2i = spec["center"]
		var biome: Biome = Biome.DEFAULT
		match spec["key"]:
			"oval_office": biome = Biome.AMERICAN
			"spaceship": biome = Biome.MARTIAN
			"eu_palace": biome = Biome.EUROPEAN
			"kremlin": biome = Biome.SIBERIAN
			"vault": biome = Biome.FINANCIAL
			"elysee": biome = Biome.FRENCH
		for x in range(center.x - biome_radius, center.x + biome_radius + 1):
			for y in range(center.y - biome_radius, center.y + biome_radius + 1):
				var dist_sq: int = (x - center.x) * (x - center.x) + (y - center.y) * (y - center.y)
				if dist_sq <= biome_radius * biome_radius:
					biome_map[Vector2i(x, y)] = biome

func _grass_tile_for(pos: Vector2i) -> Vector2i:
	if not _pack_ready:
		return TILE_GRASS
	var biome: Biome = biome_map.get(pos, Biome.DEFAULT) as Biome
	var varied: bool = _tile_roll(pos.x, pos.y) < 180
	match biome:
		Biome.AMERICAN:
			# Bright lime green — manicured White House lawn
			return FD_LGREEN2 if varied else FD_LGREEN
		Biome.SIBERIAN:
			return FD_SNOW2 if varied else FD_SNOW
		Biome.FRENCH:
			return FD_PINK2 if varied else FD_PINK
		Biome.MARTIAN:
			return FD_DIRT2 if varied else FD_DIRT
		_:
			# DEFAULT, EUROPEAN, FINANCIAL — standard green
			return FD_GRASS2 if varied else FD_GRASS

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
	_build_biome_map()

	var grass_source := SRC_FIELD if _pack_ready else SRC_PROC
	var path_source := SRC_FLOOR if _pack_ready else SRC_PROC

	# Paint ground with biome-aware tiles
	for x in range(WORLD_MIN_X, WORLD_MAX_X):
		for y in range(WORLD_MIN_Y, WORLD_MAX_Y):
			var pos := Vector2i(x, y)
			ground_map.set_cell(LAYER_GROUND, pos, grass_source, _grass_tile_for(pos))

	# Paint paths
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

	# Build structures and decorations
	for spec in building_specs:
		_build_structure(spec)
		_decorate_compound(spec)
		_place_landmark(spec)

	# Place nature: biome-aware trees, bushes, flowers, rocks
	# Densities are kept LOW so the map feels clean and readable
	var inner_min_x := WORLD_MIN_X + BORDER_WIDTH + 1
	var inner_max_x := WORLD_MAX_X - BORDER_WIDTH - 1
	var inner_min_y := WORLD_MIN_Y + BORDER_WIDTH + 1
	var inner_max_y := WORLD_MAX_Y - BORDER_WIDTH - 1

	for x in range(inner_min_x, inner_max_x):
		for y in range(inner_min_y, inner_max_y):
			if _is_in_building_zone(x, y) or _is_on_path(x, y):
				continue

			var roll := _tile_roll(x, y)
			var pos := Vector2i(x, y)
			var biome: Biome = biome_map.get(pos, Biome.DEFAULT) as Biome

			# Biome-specific decoration — sparse and intentional
			match biome:
				Biome.MARTIAN:
					if roll < 4:
						_place_rock(pos)
					elif roll < 7:
						_place_cactus(pos)
				Biome.SIBERIAN:
					if roll < 8:
						_place_tree(pos)
					elif roll < 12:
						_place_rock(pos)
				Biome.FRENCH:
					if roll < 6:
						_place_tree(pos)
					elif roll < 14:
						_place_flower(pos)
				Biome.EUROPEAN:
					if roll < 5:
						_place_tree(pos)
					elif roll < 10:
						_place_flower(pos)
					elif roll < 14:
						_place_bush(pos)
				Biome.FINANCIAL:
					if roll < 3:
						_place_tree(pos)
					elif roll < 5:
						_place_rock(pos)
				Biome.AMERICAN:
					# Manicured White House garden — neat bushes and flowers
					if roll < 5:
						_place_tree(pos)
					elif roll < 12:
						_place_bush(pos)
					elif roll < 20:
						_place_flower(pos)
				_:
					# Default (between biomes): very clean — just scattered trees
					if roll < 4:
						_place_tree(pos)
					elif roll < 7:
						_place_bush(pos)

	# Dense tree border around the world edge
	_build_world_border()

func _place_cactus(pos: Vector2i) -> void:
	if not _pack_ready or not _can_place_decoration(pos, Vector2i(1, 1)):
		return
	var atlas: Vector2i = cactus_tiles[_tile_roll(pos.x + 7, pos.y - 3) % cactus_tiles.size()]
	ground_map.set_cell(LAYER_DECOR, pos, SRC_NATURE, atlas)

func _build_world_border() -> void:
	# Fill border ring with dense trees (impassable)
	for x in range(WORLD_MIN_X, WORLD_MAX_X):
		for y in range(WORLD_MIN_Y, WORLD_MAX_Y):
			var on_border: bool = (
				x < WORLD_MIN_X + BORDER_WIDTH
				or x >= WORLD_MAX_X - BORDER_WIDTH
				or y < WORLD_MIN_Y + BORDER_WIDTH
				or y >= WORLD_MAX_Y - BORDER_WIDTH
			)
			if not on_border:
				continue
			var pos := Vector2i(x, y)
			if _is_on_path(pos.x, pos.y):
				continue
			# Place a solid tree tile on every border cell
			if _pack_ready:
				# Alternate between dense bush and tree trunk for a wall look
				var roll := _tile_roll(x, y)
				if roll % 3 == 0:
					ground_map.set_cell(LAYER_DECOR, pos, SRC_NATURE, NT_BUSH)
				else:
					# Use bottom-half of a green tree (trunk area) for density
					var trunk_tiles: Array = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(8, 1), Vector2i(9, 1)]
					ground_map.set_cell(LAYER_DECOR, pos, SRC_NATURE, trunk_tiles[roll % trunk_tiles.size()])
			else:
				ground_map.set_cell(LAYER_DECOR, pos, SRC_PROC, TILE_BUSH)
			_create_solid_wall(x, y)

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

func _trees_for_biome(biome: Biome) -> Array:
	match biome:
		Biome.SIBERIAN: return trees_snow
		Biome.FRENCH: return trees_pink
		Biome.MARTIAN: return trees_dead
		_: return trees_green

func _place_tree(pos: Vector2i) -> void:
	var biome: Biome = biome_map.get(pos, Biome.DEFAULT) as Biome
	if _pack_ready:
		var variants: Array = _trees_for_biome(biome)
		if variants.is_empty():
			return
		var variant_idx := posmod(pos.x * 48271 + pos.y * 91831 + 37139, variants.size())
		var variant: Dictionary = variants[variant_idx]
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
	var cid: String = str(spec["npc"])
	if not landmark_sprite_paths.has(cid):
		return

	var path: String = landmark_sprite_paths[cid]
	if not ResourceLoader.exists(path):
		return

	var tex = load(path) as Texture2D
	if not tex:
		return

	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Keep every landmark on the exterior centerline of its house.
	var center: Vector2i = spec["center"]
	var roof_center := center
	sprite.position = _tile_to_body_position(roof_center)

	# Bottom of sprite sits on roof center
	var tex_h: float = tex.get_height()
	sprite.offset = Vector2(0, -tex_h * 0.5)

	# Scale landmark to fit roughly 3 tiles wide (96px) max
	var max_width := 96.0
	var tex_w: float = tex.get_width()
	if tex_w > max_width:
		var s: float = max_width / tex_w
		sprite.scale = Vector2(s, s)

	sprite.z_index = 5
	entities_layer.add_child(sprite)

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
	terminal.position = Vector2(64, 16)
	terminal.add_to_group("ai_terminal")
	terminal.set_script(load("res://scripts/ai_terminal.gd"))

	# Mascot Visual (Sprite2D)
	var sprite := Sprite2D.new()
	sprite.name = "MascotSprite"
	var tex_path = "res://assets/mockups/ai_terminal_sprite.png"
	if ResourceLoader.exists(tex_path):
		var tex = load(tex_path)
		sprite.texture = tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(0.85, 0.85) 
		sprite.position = Vector2(0, -20)
		sprite.z_index = 3
		terminal.add_child(sprite)

	# "!" indicator when nearby (same as NPCs)
	var indicator := Label.new()
	indicator.name = "Indicator"
	indicator.text = "!"
	indicator.add_theme_font_size_override("font_size", 22)
	indicator.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1)) # Orange
	indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicator.position = Vector2(-8, -75)
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
	glow.color = Color(1.0, 0.45, 0.1) # Orange glow
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

	# Add path tiles around the terminal and Xi
	_mark_path_rect(Vector2i(-4, -4), Vector2i(6, 10))
	var path_source: int = SRC_FLOOR if _pack_ready else SRC_PROC
	for x in range(-4, 7):
		for y in range(-4, 11):
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
	if (contamination_terminal_ready or hidden_bunker_ai_ack_pending or hidden_bunker_ai_ack_active) and not contamination_terminal_departed and contamination_root and is_instance_valid(contamination_root) and not contamination_active:
		contamination_root.modulate = Color.WHITE
		contamination_root.visible = true
		contamination_root.global_position = terminal.global_position + CONTAMINATION_TERMINAL_OFFSET
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
	dialogue_manager.create_typewriter_bip()


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
					if str(entry.get("id", "")) == "hidden_bunker_scene":
						hidden_bunker_data = entry
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
			var tex := load(sprite_path) as Texture2D
			sprite.texture = tex
			if tex != null:
				var scale_factor: float = NPC_TARGET_SPRITE_HEIGHT / float(max(tex.get_height(), 1))
				sprite.scale = Vector2(scale_factor, scale_factor)
				npc.set("base_scale", sprite.scale)
			var placeholder := npc.get_node_or_null("PlaceholderVisual")
			if placeholder:
				placeholder.queue_free()


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
	_ensure_room_manager()
	room_manager.create_transition_ui(ui_layer)
	interior_overlay = room_manager.interior_overlay
	transition_overlay = room_manager.transition_overlay
	room_title_card = room_manager.room_title_card
	room_title_label = room_manager.room_title_label
	room_title_subtitle = room_manager.room_title_subtitle


func _create_hud() -> void:
	meter_bars.clear()
	hud_panel = null

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
	dialogue_manager = DIALOGUE_MANAGER_SCRIPT.new()
	dialogue_manager.name = "DialogueManager"
	add_child(dialogue_manager)
	dialogue_manager.setup(
		ui_layer,
		player,
		character_data_cache,
		character_colors,
		portrait_paths
	)
	dialogue_manager.line_changed.connect(_on_dialogue_line_changed)
	dialogue_manager.choice_selected.connect(_on_dialogue_choice_selected)
	dialogue_manager.finish_requested.connect(_finish_dialogue)
	dialogue_manager.create_ui()

func _on_dialogue_line_changed(character_id: String, line_index: int) -> void:
	if character_id == "kim_jong_un" and kim_phone_encounter and bool(kim_phone_encounter.get("active")):
		kim_phone_encounter.update_for_line(line_index)

func _on_dialogue_choice_selected(character_id: String, choice: Dictionary) -> void:
	_record_choice_mark(character_id, choice)
	if active_room_id != "" and room_registry.has(active_room_id):
		var active_room = room_registry[active_room_id]
		if active_room and active_room.has_method("handle_dialogue_choice"):
			active_room.handle_dialogue_choice(character_id, choice)


func open_dialogue(character_id: String) -> void:
	if is_dialogue_open or contamination_active:
		return
	if character_id == "xi_jinping" and not xi_pre_scene_seen and not xi_pre_scene_active:
		call_deferred("_start_xi_pre_scene")
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

	# Kim Jong-un: spawn red phone overlay if it's a full quest dialogue (not repeat)
	if character_id == "kim_jong_un" and dialogue_lines.size() > 10:
		_ensure_kim_phone_encounter()
		kim_phone_encounter.start(self)

	# Set border color
	_apply_dialogue_identity(character_id)

	# Start first line
	continue_label.visible = false
	continue_blink = 0.0
	if dialogue_lines.size() > 0:
		_start_typewriter(_prepare_dialogue_line(str(dialogue_lines[0])))
	else:
		_start_typewriter("...")

	_animate_dialogue_in()

func _setup_ai_dialogue() -> void:
	if contamination_terminal_afterglow_pending:
		ai_dialogue_override_active = true
		contamination_terminal_afterglow_pending = false
		dialogue_lines = ["..."]
		return

	if hidden_bunker_ai_ack_pending:
		ai_dialogue_override_active = true
		hidden_bunker_ai_ack_pending = false
		hidden_bunker_ai_ack_active = true
		dialogue_lines = [str(hidden_bunker_data.get("post_ai_line", "I told you not to come here."))]
		return

	if contamination_terminal_ready and not contamination_terminal_dialogue_seen:
		var contamination_data: Dictionary = character_data_cache.get("historical_contamination", {})
		var terminal_debate: Array = contamination_data.get("terminal_debate", [])
		if not terminal_debate.is_empty():
			ai_dialogue_override_active = true
			contamination_terminal_dialogue_seen = true
			dialogue_lines = terminal_debate.duplicate()
			return

	if not ai_override_lines.is_empty():
		ai_dialogue_override_active = true
		dialogue_lines = ai_override_lines.duplicate()
		ai_override_lines.clear()
		return

	if not optional_ai_followup_lines.is_empty():
		ai_dialogue_override_active = true
		dialogue_lines = optional_ai_followup_lines.duplicate()
		optional_ai_followup_lines.clear()
		return

	ai_dialogue_override_active = false
	dialogue_lines = quest_manager.build_ai_dialogue(
		ai_terminal_data,
		Callable(self, "_character_display_name"),
		seen_hidden_bunker_scene
	)

func _setup_politician_dialogue(character_id: String) -> void:
	var content: Dictionary = quest_manager.build_politician_dialogue(
		character_id,
		character_data_cache.get(character_id, {}),
		Callable(self, "_character_display_name")
	)
	dialogue_lines = Array(content.get("lines", ["..."])).duplicate()
	dialogue_choices = Array(content.get("choices", [])).duplicate()
	dialogue_choice_prompt = str(content.get("choice_prompt", ""))



func _finish_dialogue() -> void:
	# Final mission: after the self-NPC response, open text input instead of closing normally
	if current_character_id == "self":
		_close_dialogue()
		# Record which choice was made (stored in dialogue_choices file_tag via _record_choice_mark is not called for "self")
		# We read it from the last selected choice index
		final_mission_choice = choice_index
		get_tree().create_timer(0.5).timeout.connect(_open_text_input_field)
		return

	# Mark quest completion for politicians.
	quest_manager.complete_dialogue(current_character_id)

	var current_data: Dictionary = character_data_cache.get(current_character_id, {})
	var was_optional_seen: bool = bool(quest_manager.is_optional_seen(current_character_id))
	if bool(current_data.get("optional", false)):
		quest_manager.mark_optional_seen(current_character_id)
		if not was_optional_seen:
			_queue_optional_ai_followup(current_character_id)
			if current_character_id == "sam_altman":
				get_tree().create_timer(0.24).timeout.connect(_try_open_optional_ai_followup)
			elif current_character_id == "ufo_easter_egg":
				ufo_ai_followup_pending = true

	# Trigger Bezos cinematic if his Terminator dialogue just finished
	if current_character_id == "jeff_bezos":
		_close_dialogue()
		get_tree().create_timer(0.4).timeout.connect(_start_bezos_cinematic)
		return

	# Trigger ending if quest just finished via final AI dialogue
	var should_end: bool = quest_finished and current_character_id == "ai_terminal" and not ending_triggered
	var queue_contamination_after_ai := current_character_id == "ai_terminal" and quest_index > 0 and not should_end and not ai_dialogue_override_active
	var should_dissolve_terminal_contamination := current_character_id == "ai_terminal" and ai_dialogue_override_active and contamination_terminal_ready and not contamination_terminal_departed and not hidden_bunker_ai_ack_active
	_close_dialogue()
	if hidden_bunker_ai_ack_active:
		hidden_bunker_ai_ack_active = false
		if not contamination_terminal_ready and contamination_root and is_instance_valid(contamination_root):
			contamination_root.visible = false
			contamination_root.modulate = Color.WHITE
	if should_dissolve_terminal_contamination:
		_dissolve_terminal_contamination()
	if queue_contamination_after_ai:
		get_tree().create_timer(0.26).timeout.connect(func() -> void:
			_maybe_queue_contamination_event("ai_terminal")
		)
	if should_end:
		ending_triggered = true
		# Small delay before the dramatic ending
		get_tree().create_timer(1.5).timeout.connect(start_ending_sequence)

func _queue_optional_ai_followup(character_id: String) -> void:
	if ai_terminal_data.is_empty():
		return
	var followups: Dictionary = ai_terminal_data.get("optional_followups", {})
	if not followups.has(character_id):
		return
	var lines: Array = Array(followups.get(character_id, [])).duplicate()
	if lines.is_empty():
		return
	if not optional_ai_followup_lines.is_empty():
		optional_ai_followup_lines.append("...")
	optional_ai_followup_lines.append_array(lines)

func _try_open_optional_ai_followup() -> void:
	if optional_ai_followup_lines.is_empty():
		ufo_ai_followup_pending = false
		return
	if is_dialogue_open or is_room_transition or hidden_bunker_scene_active or contamination_active or active_room_id != "":
		get_tree().create_timer(0.22).timeout.connect(_try_open_optional_ai_followup)
		return
	ufo_ai_followup_pending = false
	open_dialogue("ai_terminal")

func _record_choice_mark(character_id: String, choice: Dictionary) -> void:
	quest_manager.record_choice_mark(character_id, choice)


func _apply_dialogue_identity(character_id: String) -> void:
	dialogue_manager.apply_dialogue_identity(character_id)

func _prepare_dialogue_line(raw_text: String) -> String:
	return str(dialogue_manager.prepare_dialogue_line(raw_text))



func _start_typewriter(text: String) -> void:
	dialogue_manager.start_typewriter(text)

func _animate_dialogue_in() -> void:
	dialogue_manager.animate_dialogue_in()

func _close_dialogue() -> void:
	if kim_phone_encounter and bool(kim_phone_encounter.get("active")):
		kim_phone_encounter.stop()
	dialogue_manager.close_dialogue()


func _create_bunker_caption_ui() -> void:
	return

func _show_bunker_caption(speaker: String, text: String) -> void:
	if not dialogue_anchor:
		return
	typewriter_timer.stop()
	continue_label.visible = false
	choice_container.visible = false
	
	# Set Special Bunker Portraits
	var portrait_id := "historical_contamination" if speaker == "CONTAMINATION" else speaker
	if portrait_paths.has(portrait_id) and ResourceLoader.exists(portrait_paths[portrait_id]):
		portrait_rect.texture = load(portrait_paths[portrait_id])
		portrait_rect.visible = true
	else:
		portrait_rect.texture = null
		portrait_rect.visible = false
		
	name_label.text = speaker
	text_label.text = text
	text_label.scroll_to_line(0)

	var border := Color(0.46, 0.5, 0.58) if speaker == "ZELENSKY" else Color(0.2, 0.22, 0.26)
	if speaker == "CONTAMINATION":
		border = Color(0.18, 0.18, 0.2)
	if dialogue_style is StyleBoxFlat:
		dialogue_style.border_color = border
	if speaker == "CONTAMINATION":
		name_label.add_theme_color_override("font_color", Color(0.74, 0.74, 0.76))
		text_label.add_theme_color_override("default_color", Color(0.9, 0.9, 0.92, 0.96))
	else:
		name_label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92) if speaker == "ZELENSKY" else Color(0.64, 0.66, 0.7))
		text_label.add_theme_color_override("default_color", Color(0.94, 0.95, 0.98, 0.96))

	if not dialogue_anchor.visible:
		dialogue_anchor.modulate.a = 0.0
		dialogue_anchor.offset_top = dialogue_rest_top + 40.0
		dialogue_anchor.visible = true
		var tw := create_tween().set_parallel(true)
		tw.tween_property(dialogue_anchor, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(dialogue_anchor, "offset_top", dialogue_rest_top, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hide_bunker_caption() -> void:
	if not dialogue_anchor or not dialogue_anchor.visible:
		return
	var tw := create_tween()
	tw.tween_property(dialogue_anchor, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		if dialogue_anchor:
			dialogue_anchor.visible = false
			dialogue_anchor.offset_top = dialogue_rest_top
		if portrait_rect:
			portrait_rect.visible = true
	)

func _queue_hidden_bunker_ai_ack() -> void:
	if contamination_terminal_ready and not contamination_terminal_dialogue_seen:
		hidden_bunker_ai_ack_pending = false
		return
	ai_override_lines = [str(hidden_bunker_data.get("post_ai_line", "I told you not to come here."))]
	var timer := get_tree().create_timer(0.3)
	timer.timeout.connect(func() -> void:
		if contamination_active:
			_queue_hidden_bunker_ai_ack()
			return
		if not is_dialogue_open and not is_room_transition and active_room_id == "":
			hidden_bunker_ai_ack_pending = false
			open_dialogue("ai_terminal")
	)

func _hidden_bunker_sequence() -> Array:
	var sequence = hidden_bunker_data.get("sequence", [])
	if sequence is Array and not sequence.is_empty():
		return sequence
	return [
		{"speaker": "ZELENSKY", "text": "They send words.\nI need what works.", "hold": 1.9},
		{"speaker": "ZELENSKY", "text": "They send concern.\nI need what arrives in time.", "hold": 2.0},
		{"speaker": "ZELENSKY", "text": "They send promises.\nI need one more night\nin which the living stay with the living.", "hold": 2.6},
		{"speaker": "ZELENSKY", "text": "I am not here for pity.\nI am not here for history.", "hold": 2.0},
		{"speaker": "ZELENSKY", "text": "I am here because you are the last one still listening.", "hold": 2.2},
		{"speaker": "ZELENSKY", "text": "So listen properly.\nDo not give me peace.\nGive me what keeps you waiting.", "hold": 2.7},
		{"speaker": "DEATH", "text": "You were born alone. You will die alone. Everything in between was negotiated by others.", "pause_before": 1.5, "hold": 3.2}
	]

func _hidden_bunker_read_duration(beat: Dictionary) -> float:
	var configured_hold := float(beat.get("hold", 2.0))
	var text := str(beat.get("text", "")).replace("\n", " ").strip_edges()
	if text == "":
		return configured_hold
	var words := text.split(" ", false).size()
	var reading_hold := 1.6 + float(words) / 2.6
	return maxf(configured_hold, reading_hold)

func _apply_hidden_bunker_tone() -> void:
	if world_canvas_modulate:
		world_canvas_modulate.color = Color(0.72, 0.76, 0.84)
	if interior_overlay:
		interior_overlay.visible = true
		interior_overlay.modulate.a = 0.74
	if screen_fx_material:
		screen_fx_material.set_shader_parameter("effect_strength", 0.16)
		screen_fx_material.set_shader_parameter("color_levels", 8.0)
		screen_fx_material.set_shader_parameter("scanline_strength", 0.03)
		screen_fx_material.set_shader_parameter("vignette_strength", 0.3)
		screen_fx_material.set_shader_parameter("overlay_strength", 0.18)
		screen_fx_material.set_shader_parameter("tint_color", Color(0.78, 0.84, 0.94, 1.0))

func _start_ufo_lab_scene() -> void:
	var ufo_room = room_registry.get("ufo_lab")
	if not ufo_room: return
	
	var einstein = ufo_room.get_node_or_null("Entities/AlbertEinsteinPlaceholder")
	var zuck = ufo_room.get_node_or_null("Entities/MarkZuckerbergPlaceholder")
	
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
			var spr = node.get_node_or_null("Sprite2D")
			if spr:
				spr.texture = load(npc_sprite_paths.get(sprite_id, ""))
				spr.visible = true
				if node.has_method("_ready"):
					node.set("base_scale", spr.scale)
			var placeholder_visual = node.get_node_or_null("PlaceholderVisual")
			if placeholder_visual:
				placeholder_visual.visible = false

func _start_hidden_bunker_scene() -> void:
	if seen_hidden_bunker_scene or hidden_bunker_scene_active or active_room_id != "mountain_bunker":
		return

	hidden_bunker_scene_active = true
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	is_dialogue_open = false
	if dialogue_anchor:
		dialogue_anchor.visible = false
	_apply_hidden_bunker_tone()

	var bunker_room = room_registry.get("mountain_bunker")
	if not bunker_room: return
	
	# Reference existing placeholders from oval_office_room.gd
	var z_npc = bunker_room.get_node_or_null("Entities/ZelenskyPlaceholder")
	var d_npc = bunker_room.get_node_or_null("Entities/DeathPlaceholder")
	
	if z_npc and d_npc:
		z_npc.set("look_at_target", d_npc) # Always look at Death
	
	# Apply sprites and hide placeholder polygons
	for data in [[z_npc, "zelensky_bunker", true], [d_npc, "death_bunker", false]]:
		var node = data[0] as StaticBody2D
		var sprite_id = data[1]
		var is_z = data[2]
		if node:
			node.process_mode = Node.PROCESS_MODE_INHERIT
			node.scale = Vector2(0.88, 0.88)
			if is_z:
				node.set("patrol_range", 12.0)
				node.set("patrol_speed", 16.0)
				# Add inquisitorial spotlight
				var light = PointLight2D.new()
				light.name = "InquisitorLight"
				light.color = Color(0.8, 0.9, 1.0)
				light.energy = 0.65
				light.texture_scale = 2.4
				var tex = GradientTexture2D.new()
				tex.fill = GradientTexture2D.FILL_RADIAL
				tex.fill_from = Vector2(0.5, 0.5)
				tex.fill_to = Vector2(1.0, 0.5)
				var grad = Gradient.new()
				grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
				tex.gradient = grad
				light.texture = tex
				node.add_child(light)
				light.position = Vector2(0, -60) # Top-down beam

			var spr = node.get_node_or_null("Sprite2D")
			if spr:
				spr.texture = load(npc_sprite_paths.get(sprite_id, ""))
				spr.visible = true
				if node.has_method("_ready"):
					node.set("base_scale", spr.scale) # Fix breathing baseline
			var placeholder_visual = node.get_node_or_null("PlaceholderVisual")
			if placeholder_visual:
				placeholder_visual.visible = false

	if bunker_room.has_method("get_spawn_position"):
		var target_pos: Vector2 = bunker_room.get_spawn_position("ApproachMarker")
		var walk_tw := create_tween()
		walk_tw.tween_property(player, "global_position", target_pos, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await walk_tw.finished

	await get_tree().create_timer(0.35).timeout
	
	var beats = _hidden_bunker_sequence()
	for i in range(beats.size()):
		var beat = beats[i]
		var pause_before := float(beat.get("pause_before", 0.0))
		if pause_before > 0.0:
			_hide_bunker_caption()
			await get_tree().create_timer(pause_before).timeout
		
		# Death appears when he speaks
		if str(beat.get("speaker", "")) == "DEATH" and d_npc.modulate.a < 0.1:
			var d_tw = create_tween()
			d_tw.tween_property(d_npc, "modulate:a", 1.0, 1.2)
			
		_show_bunker_caption(str(beat.get("speaker", "")), str(beat.get("text", "")))
		await get_tree().create_timer(_hidden_bunker_read_duration(beat)).timeout

	_hide_bunker_caption()
	await get_tree().create_timer(0.6).timeout
	seen_hidden_bunker_scene = true
	hidden_bunker_scene_active = false
	player.set_physics_process(true)

func _load_contamination_texture() -> Texture2D:
	var tex_path := "res://assets/sprites/npc_contamination.png"
	var tex := load(tex_path) as Texture2D
	if tex != null:
		return tex

	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(tex_path))
	if err == OK:
		return ImageTexture.create_from_image(image)

	push_error("Failed to load contamination sprite at %s" % tex_path)
	return null

func _ensure_kim_phone_encounter() -> void:
	if kim_phone_encounter:
		return
	kim_phone_encounter = KIM_PHONE_ENCOUNTER_SCRIPT.new()
	kim_phone_encounter.name = "KimPhoneEncounter"
	add_child(kim_phone_encounter)



func _ensure_xi_pre_scene_encounter() -> void:
	if xi_pre_scene_encounter:
		return
	xi_pre_scene_encounter = XI_PRE_SCENE_SCRIPT.new()
	xi_pre_scene_encounter.name = "XiPreScene"
	add_child(xi_pre_scene_encounter)
	xi_pre_scene_encounter.setup(self, player, character_data_cache)

func _start_xi_pre_scene() -> void:
	_ensure_xi_pre_scene_encounter()
	xi_pre_scene_encounter.start(active_room_id, room_registry.get("red_command"))


func _ensure_contamination_figure() -> void:
	var tex := _load_contamination_texture()
	if tex == null:
		return

	if contamination_root and is_instance_valid(contamination_root):
		contamination_root.queue_free()
		contamination_root = null

	contamination_root = Node2D.new()
	contamination_root.name = "HistoricalContamination"
	contamination_root.visible = false
	contamination_root.z_index = 18

	var shadow := Polygon2D.new()
	shadow.color = Color(0.0, 0.0, 0.0, 0.22)
	shadow.polygon = PackedVector2Array([
		Vector2(-30, 8), Vector2(30, 8),
		Vector2(20, 16), Vector2(-20, 16)
	])
	contamination_root.add_child(shadow)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = tex
	sprite.modulate = Color.WHITE
	sprite.visible = true
	contamination_root.add_child(sprite)

	# Historical glitch shader for the sprite version.
	var glitch_shader := Shader.new()
	glitch_shader.code = """
shader_type canvas_item;
uniform float strength : hint_range(0.0, 1.0) = 0.5;
uniform float time;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    float line_glitch = step(0.98, rand(vec2(time * 0.5, floor(uv.y * 32.0)))) * 0.05 * strength;
    vec2 glitch_uv = uv + vec2(line_glitch, 0.0);
    
    vec4 col = texture(TEXTURE, glitch_uv);
    
    // Spectral pulse
    float pulse = 0.85 + sin(time * 6.0) * 0.15;
    col.a *= pulse;
    
    // "Premium Oppression" Sepia Filter
    float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    vec3 sepia = vec3(gray * 1.1, gray * 0.9, gray * 0.6); // Warm, expensive sepia
    col.rgb = mix(col.rgb, sepia, 0.85 * strength);
    
    // Corporate Grain
    float grain = (rand(uv + time) - 0.5) * 0.1 * strength;
    col.rgb += grain;
    
    // Occasional "LEGACY" flash
    if (mod(time, 1.5) < 0.06) {
        col.rgb = vec3(1.0, 1.0, 1.0) - col.rgb;
    }

    COLOR = col;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = glitch_shader
	sprite.material = mat

	var target_height: float = 176.0
	var scale_factor: float = clamp(target_height / float(max(tex.get_height(), 1)), 0.14, 0.5)
	sprite.set_meta("base_scale", scale_factor)
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = Vector2(0, -target_height * 0.33)

	entities_layer.add_child(contamination_root)

func _is_contamination_source(source: String) -> bool:
	return CONTAMINATION_SOURCE_OFFSETS.has(source)

func _get_contamination_line(source: String) -> String:
	var data: Dictionary = character_data_cache.get("historical_contamination", {})
	var manifestations: Dictionary = data.get("manifestations", {})
	var options: Array = manifestations.get(source, [])
	if options.is_empty():
		return ""
	return str(options[randi() % options.size()])

func _contamination_read_duration(text: String) -> float:
	return clamp(1.9 + float(text.length()) * 0.03, 2.8, 5.2)

func _dissolve_terminal_contamination() -> void:
	if not contamination_root or not is_instance_valid(contamination_root):
		contamination_terminal_ready = false
		contamination_terminal_departed = true
		contamination_terminal_afterglow_pending = true
		return
	contamination_terminal_ready = false
	contamination_terminal_departed = true
	contamination_terminal_afterglow_pending = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(contamination_root, "modulate:a", 0.0, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(contamination_root, "global_position", contamination_root.global_position + Vector2(-10, -4), 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		if contamination_root:
			contamination_root.visible = false
			contamination_root.modulate = Color.WHITE
	)

func _wait_for_caption_space_close() -> void:
	continue_label.text = "▼ SPACE"
	continue_label.visible = true
	while Input.is_action_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_SPACE):
		await get_tree().process_frame
	while true:
		continue_label.modulate.a = 0.55 + sin(Time.get_ticks_msec() * 0.01) * 0.35
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_SPACE):
			break
	continue_label.visible = false
	continue_label.modulate.a = 1.0

func _maybe_queue_contamination_event(source: String) -> void:
	if not _is_contamination_source(source):
		return
	if contamination_active or contamination_seen_sources.has(source):
		return
	if contamination_appearance_count >= CONTAMINATION_MAX_APPEARANCES:
		return
	if intro_active or ending_active or hidden_bunker_scene_active or is_room_transition:
		return
	if active_room_id != "" or is_dialogue_open or bezos_cinematic_active or ufo_abduction_active:
		return
	call_deferred("_start_contamination_event", source)

func _start_contamination_event(source: String) -> void:
	if not _is_contamination_source(source):
		return
	if contamination_active or contamination_seen_sources.has(source):
		return
	if contamination_appearance_count >= CONTAMINATION_MAX_APPEARANCES:
		return
	if intro_active or ending_active or hidden_bunker_scene_active or is_room_transition:
		return
	if active_room_id != "" or is_dialogue_open or bezos_cinematic_active or ufo_abduction_active:
		return

	var line := _get_contamination_line(source)
	if line == "":
		return

	_ensure_contamination_figure()
	if not contamination_root or not is_instance_valid(contamination_root):
		return
	contamination_active = true
	contamination_seen_sources[source] = true
	contamination_appearance_count += 1
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	var offset: Vector2 = CONTAMINATION_SOURCE_OFFSETS.get(source, Vector2(120, -24))
	var base_position := player.global_position + offset
	contamination_root.global_position = base_position + Vector2(8, 0)
	contamination_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	contamination_root.visible = true

	if transition_overlay:
		transition_overlay.visible = true
		transition_overlay.modulate.a = 0.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(contamination_root, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(contamination_root, "global_position", base_position, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if transition_overlay:
		tw.tween_property(transition_overlay, "modulate:a", 0.26, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(0.12).timeout

	_show_bunker_caption("CONTAMINATION", line)
	await _wait_for_caption_space_close()
	_hide_bunker_caption()

	var fade_tw := create_tween()
	fade_tw.set_parallel(true)
	fade_tw.tween_property(contamination_root, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if transition_overlay:
		fade_tw.tween_property(transition_overlay, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_tw.finished

	if contamination_root:
		contamination_root.visible = false
	if transition_overlay:
		transition_overlay.visible = false
	player.set_physics_process(true)
	contamination_active = false
	if contamination_appearance_count >= CONTAMINATION_MAX_APPEARANCES:
		contamination_terminal_ready = true
		if contamination_root and is_instance_valid(contamination_root):
			var terminal := get_node_or_null("Entities/AITerminal")
			if terminal:
				contamination_root.modulate = Color.WHITE
				contamination_root.visible = true
				contamination_root.global_position = terminal.global_position + CONTAMINATION_TERMINAL_OFFSET

func _create_standalone_npc(sprite_id: String, character_id: String) -> StaticBody2D:
	var npc = preload("res://scenes/npc.tscn").instantiate()
	npc.set("character_id", character_id)
	var tex_path = npc_sprite_paths.get(sprite_id, "")
	if tex_path != "" and ResourceLoader.exists(tex_path):
		var spr = npc.get_node_or_null("Sprite2D")
		if spr: spr.texture = load(tex_path)
	return npc

func register_encounter_residue(character_id: String, residue_id: String, residue_note: String = "") -> void:
	quest_manager.register_encounter_residue(character_id, residue_id, residue_note)


# ============================================================
#  90s CRT TV INTRO SEQUENCE
# ============================================================

func _setup_intro_sequence() -> void:
	intro_sequence = INTRO_SEQUENCE_SCRIPT.new()
	intro_sequence.name = "IntroSequence"
	add_child(intro_sequence)
	intro_sequence.setup(self, player)



# ============================================================
#  TARANTINO-STYLE ENDING SEQUENCE
# ============================================================

func _create_ending_overlay() -> void:
	ending_sequence = ENDING_SEQUENCE_SCRIPT.new()
	ending_sequence.name = "EndingSequence"
	add_child(ending_sequence)
	ending_sequence.final_mission_requested.connect(_trigger_final_mission)
	ending_sequence.postgame_requested.connect(_start_postgame_free_roam)
	ending_sequence.setup(self)

func start_ending_sequence() -> void:
	if ending_active:
		return
	player.set_physics_process(false)
	is_dialogue_open = false
	dialogue_anchor.visible = false
	ending_sequence.start(final_mission_done)


func _trigger_final_mission() -> void:
	if final_mission_active or final_mission_done:
		player.set_physics_process(true)
		return
	final_mission_active = true
	# Force-close any open room so the world is visible
	if active_room_id != "":
		var old_room = room_registry.get(active_room_id)
		if old_room and old_room.has_method("hide_room"):
			old_room.hide_room()
		active_room_id = ""
	is_room_transition = false
	is_dialogue_open = false
	player.set_physics_process(true)
	# Reset player near AI terminal (terminal is at pixel (64,16))
	player.global_position = Vector2(64, 80)
	# C.L.A.U.D.I.A. cryptic message before player finds the NPC
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		ai_override_lines = [
			"One signature is missing.",
			"The system flagged it.",
			"I didn't notice before.",
			"...",
			"Neither did you.",
		]
		open_dialogue("ai_terminal")
	)
	# Spawn NPC-self with delay (player needs to explore)
	get_tree().create_timer(0.5).timeout.connect(_spawn_self_npc)

func _start_postgame_free_roam() -> void:
	if postgame_free_roam_started:
		return
	postgame_free_roam_started = true
	ending_active = false
	if ending_layer:
		ending_layer.visible = false
	var quit_hint: Node = ending_layer.get_node_or_null("EndingQuitHint") if ending_layer else null
	if quit_hint:
		quit_hint.queue_free()
	is_room_transition = false
	is_dialogue_open = false
	player.set_physics_process(true)
	if final_mission_npc:
		final_mission_npc.queue_free()
		final_mission_npc = null
	final_mission_active = false
	if active_room_id != "":
		var room = room_registry.get(active_room_id)
		if room and room.has_method("set_room_active"):
			room.set_room_active(false)
		if player.get_parent() != entities_layer:
			player.reparent(entities_layer, true)
		active_room_id = ""
	player.global_position = Vector2(64, 80)
	ai_override_lines = [
		"The file is filed. The catastrophe, I am delighted to report, remains fully operational.",
		"Congratulations. You completed the official process and unlocked the unofficial one: wandering freely through the surviving nonsense.",
		"No more signatures. No more protocol. Just monuments, delusions, optional scandals, and several premium-grade civic hallucinations.",
		"If you encounter anything ridiculous, spiritually offensive, or administratively impossible, do not panic. That is our highest fidelity mode."
	]
	get_tree().create_timer(0.8).timeout.connect(func() -> void:
		open_dialogue("ai_terminal")
	)

func _spawn_self_npc() -> void:
	if final_mission_npc:
		return
	final_mission_npc = StaticBody2D.new()
	final_mission_npc.name = "SelfNPC"
	# Tile (-28, 24) → world pixel coords
	final_mission_npc.global_position = Vector2(-28 * 32 + 16, 24 * 32 + 16)

	# Sprite — same as player
	var spr := Sprite2D.new()
	var player_tex: Texture2D = null
	var spr_node := player.get_node_or_null("Sprite2D") as Sprite2D
	if spr_node:
		player_tex = spr_node.texture
	if player_tex:
		spr.texture = player_tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(1.0, 1.0)
	final_mission_npc.add_child(spr)

	# Proximity trigger
	var area := Area2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 56.0
	var col := CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(func(body: Node) -> void:
		if body == player and final_mission_active and not final_mission_done and not is_dialogue_open:
			_start_self_dialogue()
	)
	final_mission_npc.add_child(area)

	# Idle sway
	var sway_tween := create_tween().set_loops()
	sway_tween.tween_property(spr, "position:x", 2.0, 1.8).set_trans(Tween.TRANS_SINE)
	sway_tween.tween_property(spr, "position:x", -2.0, 1.8).set_trans(Tween.TRANS_SINE)

	get_tree().current_scene.add_child(final_mission_npc)

func _start_self_dialogue() -> void:
	if is_dialogue_open or not final_mission_active or final_mission_done:
		return
	current_character_id = "self"
	player.set_physics_process(false)
	is_dialogue_open = true
	is_choosing = false
	dialogue_choices.clear()
	dialogue_line_index = 0
	dialogue_farewell = ""
	choice_container.visible = false

	dialogue_lines = [
		"Oh.",
		"You came.",
		"I've been sitting here since\nthe sixth signature.\nI knew you'd find me eventually.",
		"You always do.",
		"I've read every word you said out there.\nTo Trump. To Putin.\nTo C.L.A.U.D.I.A.",
		"Especially to C.L.A.U.D.I.A.",
		"She doesn't say it, but she likes you.\nIn her way.\nWhich is to say: she finds you\nstatistically anomalous.",
		"...",
		"I'm not signing.",
		"Don't give me that look.\nI have reasons.",
		"That document — if I sign it —\nbecomes real.\nOfficially real.",
		"Every war.\nEvery yacht.\nEvery warehouse worker\nwho pissed in a bottle\nbecause a timer said so.",
		"Every ignored vote.\nEvery bought election.\nEvery 'Terms of Service' that nobody read\nbecause they were 47 pages long\nand written in legal.",
		"I sign that document and\nI become a witness.\nAnd witnesses can't pretend\nthey didn't see anything.",
		"You understand what I'm saying?",
		"I am the only person left\nwho can still pretend\nnone of this happened.",
		"...",
		"And you want me to give that up.",
	]
	dialogue_choices = [
		{"label": "Sign it. Nothing changes anyway.",
		 "response": [
			"...",
			"That is the saddest sentence\nin the history of human civilization.",
			"And you said it like it was\njust a weather report.",
			"'Nothing changes anyway.'\nLike gravity.\nLike taxes.\nLike rent.",
			"Fine.\nYou win.\nI'll sign the @#$%ing thing.",
			"God, you're depressing.\nI love that about you.",
		 ],
		 "file_tag": "resigned"},
		{"label": "Don't sign. Keep the option open.",
		 "response": [
			"Ha.",
			"'Keep the option open.'\nThat's what I told myself at twenty.",
			"And at thirty.\nAnd at forty.",
			"The option is a waiting room\nwith no chairs\nand a sign that says\n'Your number will be called shortly.'",
			"It never gets called.",
			"...\nBut fine.\nAt least you're honest about\nwhat you're asking for.",
			"I'll sign.\nBecause you asked nicely.\nAnd because the waiting room\nis getting cold.",
		 ],
		 "file_tag": "romantic"},
		{"label": "...",
		 "response": [
			"Yeah.",
			"That's what I thought.",
			"I've been sitting on this bench\nfor a long time\nwaiting for someone to have\nthe right answer.",
			"Nobody does.\nNobody ever did.",
			"That's not a tragedy.\nThat's just Tuesday.",
			"Okay.\nGive me the pen.",
			"...\nDo we even have a pen?",
			"Of course we don't have a pen.\nThis is a video game.\nI'll just — you know — metaphorically sign it.",
		 ],
		 "file_tag": "honest"},
	]
	dialogue_choice_prompt = "Well?"

	_apply_dialogue_identity("self")
	continue_label.visible = false
	continue_blink = 0.0
	_start_typewriter(_prepare_dialogue_line(str(dialogue_lines[0])))
	_animate_dialogue_in()

# ============================================================
#  TEXT INPUT FIELD — margin note
# ============================================================

func _open_text_input_field() -> void:
	if final_mission_text_field:
		final_mission_text_field.queue_free()
	final_mission_awaiting_input = true
	player.set_physics_process(false)

	var layer := CanvasLayer.new()
	layer.name = "TextInputLayer"
	layer.layer = 90

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.72)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bg)

	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -320.0
	box.offset_top = -90.0
	box.offset_right = 320.0
	box.offset_bottom = 90.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08)
	style.border_color = Color(0.95, 0.88, 0.4)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	box.add_theme_stylebox_override("panel", style)
	layer.add_child(box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	box.add_child(vbox)

	var prompt_lbl := Label.new()
	prompt_lbl.text = "Write something true in the margin.\nOr don't."
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_lbl.add_theme_font_size_override("font_size", 16)
	prompt_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	vbox.add_child(prompt_lbl)

	final_mission_text_field = LineEdit.new()
	final_mission_text_field.placeholder_text = "..."
	final_mission_text_field.max_length = 80
	final_mission_text_field.expand_to_text_length = false
	final_mission_text_field.custom_minimum_size = Vector2(560, 38)
	final_mission_text_field.add_theme_font_size_override("font_size", 16)
	final_mission_text_field.add_theme_color_override("font_color", Color(0.95, 0.92, 0.75))
	vbox.add_child(final_mission_text_field)

	var hint_lbl := Label.new()
	hint_lbl.text = "ENTER to confirm   •   ESC to leave blank"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 12)
	hint_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	vbox.add_child(hint_lbl)

	add_child(layer)
	final_mission_text_field.grab_focus()

	final_mission_text_field.text_submitted.connect(func(txt: String) -> void:
		final_mission_margin_text = txt.strip_edges()
		layer.queue_free()
		final_mission_text_field = null
		final_mission_awaiting_input = false
		_after_text_input()
	)
	# ESC — leave blank
	final_mission_text_field.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			final_mission_margin_text = ""
			layer.queue_free()
			final_mission_text_field = null
			final_mission_awaiting_input = false
			_after_text_input()
	)

func _after_text_input() -> void:
	# NPC-self fades and signs
	if final_mission_npc:
		var tw := create_tween()
		tw.tween_property(final_mission_npc, "modulate:a", 0.0, 0.6)
		tw.tween_callback(func(): if final_mission_npc: final_mission_npc.queue_free())
	# C.L.A.U.D.I.A. final response via override
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		ai_override_lines = [
			"Document filed.",
			"Folder: 'PROOF THAT HUMANS\nARE WONDERFULLY STUPID'.",
			"...",
			"Subfolder created: 'Exceptions'.",
		]
		open_dialogue("ai_terminal")
		# After this dialogue closes → MK sequence
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			_wait_for_dialogue_then(func() -> void:
				get_tree().create_timer(1.8).timeout.connect(_start_mk_sequence)
			)
		)
	)

func _wait_for_dialogue_then(callback: Callable) -> void:
	if not is_dialogue_open:
		callback.call()
		return
	get_tree().create_timer(0.4).timeout.connect(func() -> void:
		_wait_for_dialogue_then(callback)
	)

# ============================================================
#  MK SEQUENCE
# ============================================================

# Each flash: [ big_stat, description_line1, description_line2, bg_color ]
const MK_FLASH_DATA := [
	["750,000",
	 "warehouse injuries reported",
	 "every year. In one company.",
	 Color(0.55, 0.0, 0.0)],
	["$500,000,000",
	 "spent on a yacht.",
	 "A historic bridge was removed to let it pass.",
	 Color(0.4, 0.1, 0.0)],
	["11 seconds",
	 "the bathroom break",
	 "that got a worker fired.",
	 Color(0.5, 0.0, 0.0)],
	["38%",
	 "voter turnout.",
	 "The system called it a mandate.",
	 Color(0.0, 0.0, 0.35)],
	["18,000",
	 "people die of hunger",
	 "every single day. Markets: unaffected.",
	 Color(0.35, 0.0, 0.0)],
]

func _create_mk_overlay() -> void:
	mk_layer = CanvasLayer.new()
	mk_layer.name = "MKLayer"
	mk_layer.layer = 110
	mk_layer.visible = false

	var root := Control.new()
	root.name = "MKRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mk_layer.add_child(root)

	# Pure black base
	var bg := ColorRect.new()
	bg.name = "MKBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	# Fact flash background (full screen color burst)
	mk_fact_bg = ColorRect.new()
	mk_fact_bg.name = "FactBg"
	mk_fact_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	mk_fact_bg.color = Color(0.5, 0.0, 0.0, 0.0)
	mk_fact_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mk_fact_bg)

	# Fact big number
	mk_fact_number = Label.new()
	mk_fact_number.name = "FactNumber"
	mk_fact_number.text = ""
	mk_fact_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mk_fact_number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mk_fact_number.set_anchors_preset(Control.PRESET_FULL_RECT)
	mk_fact_number.offset_bottom = -160.0
	mk_fact_number.add_theme_font_size_override("font_size", 120)
	mk_fact_number.add_theme_color_override("font_color", Color.WHITE)
	mk_fact_number.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	mk_fact_number.add_theme_constant_override("shadow_offset_x", 6)
	mk_fact_number.add_theme_constant_override("shadow_offset_y", 6)
	mk_fact_number.modulate.a = 0.0
	mk_fact_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mk_fact_number)

	# Fact description line 1
	mk_fact_line1 = Label.new()
	mk_fact_line1.name = "FactLine1"
	mk_fact_line1.text = ""
	mk_fact_line1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mk_fact_line1.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mk_fact_line1.offset_top = -160.0
	mk_fact_line1.offset_bottom = -110.0
	mk_fact_line1.add_theme_font_size_override("font_size", 24)
	mk_fact_line1.add_theme_color_override("font_color", Color(1.0, 0.88, 0.88))
	mk_fact_line1.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	mk_fact_line1.add_theme_constant_override("shadow_offset_x", 2)
	mk_fact_line1.add_theme_constant_override("shadow_offset_y", 2)
	mk_fact_line1.modulate.a = 0.0
	mk_fact_line1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mk_fact_line1)

	# Fact description line 2
	mk_fact_line2 = Label.new()
	mk_fact_line2.name = "FactLine2"
	mk_fact_line2.text = ""
	mk_fact_line2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mk_fact_line2.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mk_fact_line2.offset_top = -108.0
	mk_fact_line2.offset_bottom = -64.0
	mk_fact_line2.add_theme_font_size_override("font_size", 18)
	mk_fact_line2.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75, 0.85))
	mk_fact_line2.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	mk_fact_line2.add_theme_constant_override("shadow_offset_x", 2)
	mk_fact_line2.add_theme_constant_override("shadow_offset_y", 2)
	mk_fact_line2.modulate.a = 0.0
	mk_fact_line2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mk_fact_line2)

	# Player sprite — lone figure, centered, slightly left of center
	mk_sprite = TextureRect.new()
	mk_sprite.name = "MKSprite"
	mk_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mk_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mk_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mk_sprite.size = Vector2(112, 148)
	mk_sprite.position = Vector2(584, 360)
	mk_sprite.modulate.a = 0.0
	mk_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spr_node2 := player.get_node_or_null("Sprite2D") as Sprite2D
	if spr_node2 and spr_node2.texture:
		mk_sprite.texture = spr_node2.texture
	root.add_child(mk_sprite)

	# Ghost sprites for glitch effect during EXECUTE
	mk_ghost1 = TextureRect.new()
	mk_ghost1.name = "Ghost1"
	mk_ghost1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mk_ghost1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mk_ghost1.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mk_ghost1.size = Vector2(112, 148)
	mk_ghost1.modulate = Color(1.0, 0.1, 0.1, 0.5)
	mk_ghost1.visible = false
	mk_ghost1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if spr_node2 and spr_node2.texture:
		mk_ghost1.texture = spr_node2.texture
	root.add_child(mk_ghost1)

	mk_ghost2 = TextureRect.new()
	mk_ghost2.name = "Ghost2"
	mk_ghost2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mk_ghost2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mk_ghost2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mk_ghost2.size = Vector2(112, 148)
	mk_ghost2.modulate = Color(0.1, 0.3, 1.0, 0.4)
	mk_ghost2.visible = false
	mk_ghost2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if spr_node2 and spr_node2.texture:
		mk_ghost2.texture = spr_node2.texture
	root.add_child(mk_ghost2)

	# Red blood bloom — expands during EXECUTE
	mk_red_bloom = ColorRect.new()
	mk_red_bloom.name = "RedBloom"
	mk_red_bloom.set_anchors_preset(Control.PRESET_FULL_RECT)
	mk_red_bloom.color = Color(0.7, 0.0, 0.0, 0.0)
	mk_red_bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mk_red_bloom)

	# "FINISH HIM." — drops from top
	mk_finish_label = Label.new()
	mk_finish_label.name = "FinishLabel"
	mk_finish_label.text = "FINISH HIM."
	mk_finish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mk_finish_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	mk_finish_label.offset_top = 100.0
	mk_finish_label.offset_bottom = 200.0
	mk_finish_label.add_theme_font_size_override("font_size", 96)
	mk_finish_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.0))
	mk_finish_label.add_theme_color_override("font_shadow_color", Color(0.7, 0.0, 0.0))
	mk_finish_label.add_theme_constant_override("shadow_offset_x", 6)
	mk_finish_label.add_theme_constant_override("shadow_offset_y", 6)
	mk_finish_label.modulate.a = 0.0
	mk_finish_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mk_finish_label)

	# Countdown
	mk_countdown_label = Label.new()
	mk_countdown_label.name = "Countdown"
	mk_countdown_label.text = "9"
	mk_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mk_countdown_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mk_countdown_label.offset_top = -56.0
	mk_countdown_label.offset_bottom = -10.0
	mk_countdown_label.add_theme_font_size_override("font_size", 38)
	mk_countdown_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))
	mk_countdown_label.modulate.a = 0.0
	mk_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mk_countdown_label)

	# "THIS IS WHAT THE SYSTEM CALLS NORMAL." — EXECUTE line
	mk_execute_line = Label.new()
	mk_execute_line.name = "ExecuteLine"
	mk_execute_line.text = "THIS IS WHAT THE SYSTEM CALLS NORMAL."
	mk_execute_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mk_execute_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	mk_execute_line.offset_top = 260.0
	mk_execute_line.offset_bottom = 320.0
	mk_execute_line.add_theme_font_size_override("font_size", 28)
	mk_execute_line.add_theme_color_override("font_color", Color.WHITE)
	mk_execute_line.add_theme_color_override("font_shadow_color", Color(0.6, 0.0, 0.0))
	mk_execute_line.add_theme_constant_override("shadow_offset_x", 3)
	mk_execute_line.add_theme_constant_override("shadow_offset_y", 3)
	mk_execute_line.modulate.a = 0.0
	mk_execute_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mk_execute_line)

	# Freeze text
	mk_freeze_text = Label.new()
	mk_freeze_text.name = "FreezeText"
	mk_freeze_text.text = ""
	mk_freeze_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mk_freeze_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	mk_freeze_text.offset_left = -480.0
	mk_freeze_text.offset_top = 180.0
	mk_freeze_text.offset_right = 480.0
	mk_freeze_text.offset_bottom = 0.0
	mk_freeze_text.add_theme_font_size_override("font_size", 24)
	mk_freeze_text.add_theme_color_override("font_color", Color(0.92, 0.92, 0.96))
	mk_freeze_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	mk_freeze_text.add_theme_constant_override("shadow_offset_x", 2)
	mk_freeze_text.add_theme_constant_override("shadow_offset_y", 2)
	mk_freeze_text.modulate.a = 0.0
	mk_freeze_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mk_freeze_text)

	# C.L.A.U.D.I.A. final line
	mk_claudia_label = Label.new()
	mk_claudia_label.name = "ClaudiaLabel"
	mk_claudia_label.text = ""
	mk_claudia_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mk_claudia_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	mk_claudia_label.offset_left = -400.0
	mk_claudia_label.offset_top = 260.0
	mk_claudia_label.offset_right = 400.0
	mk_claudia_label.offset_bottom = 0.0
	mk_claudia_label.add_theme_font_size_override("font_size", 22)
	mk_claudia_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	mk_claudia_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	mk_claudia_label.add_theme_constant_override("shadow_offset_x", 2)
	mk_claudia_label.add_theme_constant_override("shadow_offset_y", 2)
	mk_claudia_label.modulate.a = 0.0
	mk_claudia_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mk_claudia_label)

	# White flash overlay (topmost)
	mk_flash = ColorRect.new()
	mk_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	mk_flash.color = Color(1, 1, 1, 0)
	mk_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mk_flash)

	add_child(mk_layer)

func _mk_show_fact(idx: int) -> void:
	var data: Array = MK_FLASH_DATA[idx % MK_FLASH_DATA.size()]
	mk_fact_bg.color = Color(data[3].r, data[3].g, data[3].b, 0.0)
	mk_fact_number.text = str(data[0])
	mk_fact_line1.text = str(data[1])
	mk_fact_line2.text = str(data[2])
	var tw := create_tween().set_parallel(true)
	tw.tween_property(mk_fact_bg, "color:a", 0.92, 0.08)
	tw.tween_property(mk_fact_number, "modulate:a", 1.0, 0.06)
	tw.tween_property(mk_fact_line1, "modulate:a", 1.0, 0.1)
	tw.tween_property(mk_fact_line2, "modulate:a", 1.0, 0.14)
	# Hold then fade out
	tw.tween_interval(1.1)
	tw.set_parallel(false)
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(mk_fact_bg, "color:a", 0.0, 0.28)
	tw2.tween_property(mk_fact_number, "modulate:a", 0.0, 0.22)
	tw2.tween_property(mk_fact_line1, "modulate:a", 0.0, 0.22)
	tw2.tween_property(mk_fact_line2, "modulate:a", 0.0, 0.22)

func _start_mk_sequence() -> void:
	if not mk_layer:
		_create_mk_overlay()
	mk_sequence_active = true
	mk_sequence_timer = 0.0
	mk_state = MKState.ENTER
	mk_flash_index = 0
	mk_layer.visible = true
	player.set_physics_process(false)

	# Reset all elements
	mk_fact_bg.color.a = 0.0
	mk_fact_number.modulate.a = 0.0
	mk_fact_line1.modulate.a = 0.0
	mk_fact_line2.modulate.a = 0.0
	mk_finish_label.modulate.a = 0.0
	mk_countdown_label.modulate.a = 0.0
	mk_sprite.modulate.a = 0.0
	mk_red_bloom.color.a = 0.0
	mk_execute_line.modulate.a = 0.0
	mk_freeze_text.modulate.a = 0.0
	mk_claudia_label.modulate.a = 0.0
	mk_ghost1.visible = false
	mk_ghost2.visible = false

	# Sprite fades in alone on black — isolated, small, alone
	mk_sprite.position = Vector2(584, 380)
	mk_sprite.rotation_degrees = 0.0
	var tw_enter := create_tween()
	tw_enter.tween_property(mk_sprite, "modulate:a", 1.0, 1.2)
	# Sway loop — exhausted, not idle
	tw_enter.tween_callback(func():
		var sway := create_tween().set_loops()
		sway.tween_property(mk_sprite, "position:x", 593.0, 0.55).set_trans(Tween.TRANS_SINE)
		sway.tween_property(mk_sprite, "position:x", 575.0, 0.55).set_trans(Tween.TRANS_SINE)
	)
	# FINISH HIM drops after sprite is visible
	tw_enter.tween_interval(0.4)
	tw_enter.tween_property(mk_finish_label, "modulate:a", 1.0, 0.2)
	# Countdown appears
	tw_enter.tween_interval(0.3)
	tw_enter.tween_property(mk_countdown_label, "modulate:a", 0.7, 0.3)

func _process_mk_sequence(delta: float) -> void:
	if not mk_sequence_active:
		return
	mk_sequence_timer += delta

	match mk_state:
		MKState.ENTER:
			mk_finish_label.modulate.a = 0.55 + sin(mk_sequence_timer * 5.0) * 0.45
			if mk_sequence_timer >= 2.2:
				mk_state = MKState.COUNTDOWN
				mk_sequence_timer = 0.0
				mk_flash_index = 0
				# Fire first fact immediately
				_mk_show_fact(0)

		MKState.COUNTDOWN:
			# Countdown: 5 facts over ~7s (one every ~1.4s)
			var fact_interval := 1.45
			var current_fact := int(mk_sequence_timer / fact_interval)
			if current_fact != mk_flash_index and current_fact < MK_FLASH_DATA.size():
				mk_flash_index = current_fact
				_mk_show_fact(current_fact)
			# Countdown number (5 → 0, maps to 5 facts)
			var remaining := int(5.0 - mk_sequence_timer)
			mk_countdown_label.text = str(max(0, remaining))
			# FINISH HIM keeps blinking, slower
			mk_finish_label.modulate.a = 0.4 + sin(mk_sequence_timer * 3.5) * 0.35
			if mk_sequence_timer >= fact_interval * MK_FLASH_DATA.size() + 0.6:
				mk_state = MKState.EXECUTE
				mk_sequence_timer = 0.0
				mk_finish_label.modulate.a = 0.0
				mk_countdown_label.modulate.a = 0.0
				mk_fact_bg.color.a = 0.0
				# Red bloom floods in
				var tw_red := create_tween()
				tw_red.tween_property(mk_red_bloom, "color:a", 0.75, 0.35)
				# Ghost sprites appear (glitch)
				mk_ghost1.position = mk_sprite.position + Vector2(-18, 4)
				mk_ghost2.position = mk_sprite.position + Vector2(22, -6)
				mk_ghost1.visible = true
				mk_ghost2.visible = true
				# Sprite lurches — the system strikes
				var tw_exec := create_tween().set_parallel(true)
				tw_exec.tween_property(mk_sprite, "rotation_degrees", 22.0, 0.18).set_trans(Tween.TRANS_EXPO)
				tw_exec.tween_property(mk_sprite, "position:y", 410.0, 0.18).set_trans(Tween.TRANS_EXPO)
				tw_exec.tween_property(mk_sprite, "position:x", 560.0, 0.18)
				tw_exec.tween_property(mk_ghost1, "modulate:a", 0.6, 0.1)
				tw_exec.tween_property(mk_ghost2, "modulate:a", 0.5, 0.1)
				mk_flash.color = Color(1.0, 0.1, 0.05, 0.0)
				tw_exec.tween_property(mk_flash, "color:a", 0.9, 0.06)

		MKState.EXECUTE:
			# Ghosts drift
			if mk_ghost1.visible:
				mk_ghost1.position.x += sin(mk_sequence_timer * 18.0) * 0.8
				mk_ghost2.position.x -= sin(mk_sequence_timer * 22.0) * 0.6
			# Flash fades
			if mk_flash.color.a > 0.0:
				mk_flash.color.a = maxf(0.0, mk_flash.color.a - delta * 4.0)
			# Execute line appears at t=0.3
			if mk_sequence_timer >= 0.3 and mk_execute_line.modulate.a < 0.01:
				var tw_el := create_tween()
				tw_el.tween_property(mk_execute_line, "modulate:a", 1.0, 0.4)
			# FREEZE at t=1.5
			if mk_sequence_timer >= 1.5:
				mk_state = MKState.FREEZE
				mk_sequence_timer = 0.0
				# Everything freezes — ghosts locked, red bloom stays
				mk_ghost1.position = mk_sprite.position + Vector2(-16, 2)
				mk_ghost2.position = mk_sprite.position + Vector2(19, -4)
				# CRT glitch flash
				mk_flash.color = Color(0.85, 0.85, 1.0, 0.55)
				var tw_glitch := create_tween()
				tw_glitch.tween_property(mk_flash, "color:a", 0.0, 0.2)
				# Execute line fades
				tw_glitch.parallel().tween_property(mk_execute_line, "modulate:a", 0.0, 0.5)
				# Red bloom darkens slowly — violence becomes silence
				tw_glitch.parallel().tween_property(mk_red_bloom, "color:a", 0.25, 2.5)
				# Freeze text — 8 lines, each with real pause
				mk_freeze_text.text = ""
				mk_freeze_text.modulate.a = 1.0
				var freeze_lines := [
					[0.6,  "If you finish this —"],
					[2.0,  "If you finish this —\n\nwho watches the world?"],
					[3.8,  "If you finish this —\n\nwho watches the world?\n\nThe answer has always been:"],
					[5.2,  "If you finish this —\n\nwho watches the world?\n\nThe answer has always been:\n\nnobody."],
					[7.0,  "If you finish this —\n\nwho watches the world?\n\nThe answer has always been:\n\nnobody.\n\nThere was never anybody."],
					[9.0,  "If you finish this —\n\nwho watches the world?\n\nThe answer has always been:\n\nnobody.\n\nThere was never anybody.\n\nThat's why you had to."],
				]
				for line_data in freeze_lines:
					var delay: float = line_data[0]
					var txt: String = line_data[1]
					get_tree().create_timer(delay).timeout.connect(func() -> void:
						if mk_sequence_active and mk_state == MKState.FREEZE:
							mk_freeze_text.text = txt
					)

		MKState.FREEZE:
			if mk_sequence_timer >= 11.0:
				mk_state = MKState.CLAUDIA_LINE
				mk_sequence_timer = 0.0
				# Everything fades except the frozen sprite and the red
				var tw_cf := create_tween().set_parallel(true)
				tw_cf.tween_property(mk_freeze_text, "modulate:a", 0.0, 0.8)
				tw_cf.tween_property(mk_ghost1, "modulate:a", 0.0, 1.0)
				tw_cf.tween_property(mk_ghost2, "modulate:a", 0.0, 1.0)
				tw_cf.tween_property(mk_red_bloom, "color:a", 0.0, 2.0)
				# C.L.A.U.D.I.A. speaks — but differently this time
				mk_claudia_label.modulate.a = 0.0
				get_tree().create_timer(1.2).timeout.connect(func() -> void:
					if not mk_sequence_active: return
					var tw_c := create_tween()
					tw_c.tween_property(mk_claudia_label, "modulate:a", 1.0, 0.6)
					tw_c.tween_callback(func(): mk_claudia_label.text = "C.L.A.U.D.I.A.:")
					tw_c.tween_interval(1.5)
					tw_c.tween_callback(func(): mk_claudia_label.text = "C.L.A.U.D.I.A.:\n\n\"...\"")
					tw_c.tween_interval(3.5)
					tw_c.tween_callback(func(): mk_claudia_label.text = "C.L.A.U.D.I.A.:\n\n\"...\"\n\n\"Go home.\"\n\"You did enough.\"")
				)

		MKState.CLAUDIA_LINE:
			if mk_sequence_timer >= 8.5:
				mk_state = MKState.FADE_OUT
				mk_sequence_timer = 0.0
				var tw_fade := create_tween()
				tw_fade.tween_property(mk_layer, "modulate:a", 0.0, 2.0)
				tw_fade.tween_callback(_start_final_credits)

		MKState.FADE_OUT:
			pass

func _start_final_credits() -> void:
	final_mission_done = true
	mk_sequence_active = false
	mk_layer.visible = false
	mk_layer.modulate.a = 1.0

	# Build final credits array dynamically
	var choice_line: String
	match final_mission_choice:
		0: choice_line = "You knew it wouldn't matter.\nYou did it anyway."
		1: choice_line = "You almost didn't.\nThat counts for something."
		_: choice_line = "That was the only honest answer."

	var margin_display: String
	if final_mission_margin_text.strip_edges() == "":
		margin_display = "[left blank]"
	else:
		margin_display = "\"" + final_mission_margin_text + "\""

	ending_scenes = [
		"[CLASSIFIED — FILE #0001]\n\nSeven signatures.\nThe document is complete.",
		"Six of them were easy.\n\nThe seventh took everything.",
		choice_line,
		"C.L.A.U.D.I.A. received the file\nat 23:59:59.",
		"She processed it in\n0.003 seconds.\n\nThen she sat with it\nfor a very long time.",
		"For the first time in\nher operational history,\nshe created a subfolder.",
		"She named it\n\n'Exceptions'.",
		"The world didn't change.\n\nThe wars are still running.\nThe billionaires are still rich.\nThe warehouse worker\nstill doesn't have a chair.",
		"The document is filed\nin a folder\nthat one machine\ndecided to create\nbecause one person\ndecided to try.",
		"In the margin of the document,\nsomewhere between\nBezos's signature and yours,\nsomeone wrote:",
		margin_display,
		"C.L.A.U.D.I.A. read it.\n\nShe didn't comment.\n\nShe just added it to the file.",
		"[CIVIC NIGHTMARE]\n\nwritten, directed,\nand survived\nby you.\n\n\n— FIN —",
	]
	ending_phase = 0
	ending_triggered = true
	start_ending_sequence()

# ── Bezos SF2 cinematic (1280×720, centrato, fedele a SSF II) ──
#
# Layout SF2 (arcade 384×224 → scaled 3.33x):
#   HP bars:  P1=giallo a sinistra, P2=blu a destra, timer "99" al centro
#   Cards:    Due ritratti 360×480 simmetrici centrati
#   Testi:    ROUND 1 giallo, FIGHT! rosso, K.O. bianco, PERFECT giallo
#   Barra sotto: "PRIME MEMBERSHIP" che si svuota = la battuta

func _create_bezos_cinematic_overlay() -> void:
	bezos_encounter = BEZOS_ENCOUNTER_SCRIPT.new()
	bezos_encounter.name = "BezosEncounter"
	add_child(bezos_encounter)
	bezos_encounter.finished.connect(_on_bezos_cinematic_finished)
	bezos_encounter.setup(self, player, combat_portrait_paths, character_colors)

func _on_bezos_cinematic_finished() -> void:
	bezos_escalation_active = false
	bezos_escalation_bubble = null
	if bezos_drone_root:
		bezos_drone_root.queue_free()
		bezos_drone_root = null
