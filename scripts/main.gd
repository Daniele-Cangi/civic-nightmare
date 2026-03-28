extends Node2D

const OVAL_OFFICE_ROOM_SCENE = preload("res://scenes/interiors/oval_office.tscn")
const NPC_SCENE = preload("res://scenes/npc.tscn")
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
var dialogue_rest_top: float = -210.0
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
var hidden_bunker_data: Dictionary = {}
var encounter_residues: Dictionary = {}
var encounter_marks: Dictionary = {}
var ai_override_lines: Array = []
var ai_dialogue_override_active: bool = false
var seen_hidden_bunker_scene: bool = false
var hidden_bunker_scene_active: bool = false
var hidden_bunker_exit_acknowledged: bool = false
var contamination_active: bool = false
var contamination_seen_sources: Dictionary = {}
var contamination_appearance_count: int = 0
var contamination_root: Node2D

const CONTAMINATION_TRIGGER_CHANCE := 0.42
const CONTAMINATION_MAX_APPEARANCES := 2
const CONTAMINATION_SOURCE_OFFSETS := {
	"vault": Vector2(-116, -24),
	"eu_palace": Vector2(-118, -24),
	"spaceship": Vector2(118, -24),
	"kremlin": Vector2(122, -24),
	"ai_terminal": Vector2(134, -20)
}

# --- Intro sequence ---
var intro_active: bool = true
var intro_layer: CanvasLayer
var intro_bg: ColorRect
var intro_text: Label
var intro_scanlines: ColorRect
var intro_static_rect: ColorRect
var intro_timer: float = 0.0
var intro_phase: int = 0
var intro_char_index: int = 0
var intro_current_text: String = ""
var intro_full_text: String = ""
var intro_fade_alpha: float = 1.0
var intro_static_timer: float = 0.0
var intro_skip_held: float = 0.0
var intro_breaking_bar: ColorRect
var intro_breaking_label: Label
var intro_ticker_bar: ColorRect
var intro_ticker_label: Label
var intro_channel_label: Label
var intro_datetime_label: Label
var intro_vhs_overlay: ColorRect
var intro_live_dot: ColorRect
var intro_live_label: Label
var intro_ch_label: Label
var intro_crt_line: ColorRect
var intro_crt_dot: ColorRect
var intro_boot_done: bool = false
var intro_shutdown: bool = false
var intro_shutdown_timer: float = 0.0

var intro_headlines: Array = [
	"Seven wars. Zero ceasefires.\nThree arms manufacturers\npost record quarterly profits.",
	"Billionaire buys historic bridge.\nThen removes it. For a yacht.\nRotterdam declines to comment.",
	"AI replaces 800,000 jobs.\nCEO calls it 'exciting opportunity'.\nExciting for whom: unspecified.",
	"Oligarch purchases social media platform.\nFires half the staff.\nCalls remaining employees 'warriors'.",
	"Democracy index: historic low.\nTurnout: 38%.\nApathy index: not measured. Why bother.",
	"The system is not broken.\nIt is working exactly as designed.\n\n...for someone.",
]

var intro_breaking_titles: Array = [
	"BREAKING NEWS",
	"MARKETS UPDATE",
	"WORLD REPORT",
	"SPECIAL ALERT",
	"LIVE COVERAGE",
	"EMERGENCY BROADCAST",
]

var intro_ticker_texts: Array = [
	"WAREHOUSE WORKER FIRED FOR 11-SEC TOILET BREAK ... AMAZON Q3: RECORD PROFITS ... PISS BOTTLES FOUND IN VAN: NO COMMENT ... ",
	"MUSK BUYS TWITTER ... FIRES 75% ... REINSTATES NAZIS ... RENAMES IT X ... LOSES $20B ... CALLS IT WIN ... ",
	"TRUMP INDICTED ... TRUMP ACQUITTED ... TRUMP ELECTED ... TRUMP INDICTED AGAIN ... MARKETS UNAFFECTED ... ",
	"ZUCKERBERG BUILDS BUNKER IN HAWAII ... META LAYS OFF 11,000 ... METAVERSE: 38 DAILY USERS ... ",
	"PUTIN INVADES UKRAINE ... UN CONDEMNS ... NOTHING HAPPENS ... REPEAT FOR 3RD YEAR ... ARMS SALES UP 400% ... ",
	"SIGNAL LOST ... SIGNAL LOST ... PLEASE STAND BY ... CIVIC NIGHTMARE LOADING ... THIS IS FINE ... ",
]

# --- Ending sequence ---
var ending_triggered: bool = false
var ending_active: bool = false
var ending_layer: CanvasLayer
var ending_bg: ColorRect
var ending_text: Label
var ending_timer: float = 0.0
var ending_phase: int = 0
var ending_char_index: int = 0
var ending_current_text: String = ""
var ending_full_text: String = ""

# --- Bezos cinematic easter egg (SF2 style, 1280x720) ---
var bezos_cinematic_active: bool = false
var bezos_cinematic_seen: bool = false
var bezos_cinematic_layer: CanvasLayer
var bezos_cinematic_root: Control
var bezos_cinematic_frame: Control
var bezos_cinematic_bg: ColorRect
var bezos_cinematic_scanlines: ColorRect
var bezos_cinematic_stage: Label
var bezos_cinematic_vs: Label
var bezos_cinematic_fight: Label
var bezos_cinematic_round: Label
var bezos_cinematic_ko: Label
var bezos_cinematic_perfect: Label
var bezos_cinematic_denial: Label
var bezos_cinematic_subtitle: Label
var bezos_cinematic_speaker: Label
var bezos_cinematic_dialogue: Label
var bezos_cinematic_timer_label: Label
var bezos_cinematic_left_card: PanelContainer
var bezos_cinematic_right_card: PanelContainer
var bezos_cinematic_left_bar: ColorRect
var bezos_cinematic_right_bar: ColorRect
var bezos_cinematic_left_hp: ColorRect
var bezos_cinematic_right_hp: ColorRect
var bezos_cinematic_flash: ColorRect
var bezos_cinematic_state: int = 0
var bezos_cinematic_timer: float = 0.0
var bezos_cinematic_frame_base_position: Vector2 = Vector2.ZERO

enum BezosCinematicState { STAGE, SLIDE_IN, VS_SLAM, FIGHT, COMBAT, DENIED, OUTRO }

const BEZOS_CINEMATIC_FRAME_SIZE := Vector2(1280, 720)
const BEZOS_STAGE_DURATION := 2.0
const BEZOS_SLIDE_IN_DURATION := 2.1
const BEZOS_VS_DURATION := 2.0
const BEZOS_FIGHT_DURATION := 4.2
const BEZOS_COMBAT_DURATION := 3.8
const BEZOS_DENIED_DURATION := 13.2
const BEZOS_ROUND_HOLD := 1.9
const BEZOS_KO_DELAY := 0.9
const BEZOS_PERFECT_DELAY := 1.6
const BEZOS_DENIAL_REVEAL_DELAY := 1.9
const BEZOS_SUBTITLE_REVEAL_DELAY := 1.6

var ending_scenes: Array = [
	"[CLASSIFIED — FILE #0000]\n\nYou collected all six signatures.\nThe document is complete.",
	"Six of the most powerful people\non Earth signed a piece of paper\nbecause a stranger asked nicely.",
	"Trump signed it to prove\nhe signs the best documents.\n\nMusk signed it because\nhe thought it was an NDA.",
	"Von der Leyen added\n47 amendments first.\n\nPutin signed it\n\"under protest.\"\n(He wasn't protesting.)",
	"Lagarde charged you\na processing fee.\n\nMacron wrote a poem\nin the margin.",
	"C.L.A.U.D.I.A. filed the document\nin a folder labeled:\n\n\"PROOF THAT HUMANS\nARE WONDERFULLY STUPID\"",
	"The world didn't change.\nThe wars didn't stop.\nThe billionaires stayed rich.\n\nBut for one brief moment...",
	"...six world leaders agreed\non exactly one thing:\n\n\nYou were really, really annoying.",
	"[CIVIC NIGHTMARE]\n\nwritten, directed, and\nendured by you.\n\n— FIN —",
]

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
const BEZOS_DRONE_TILE := Vector2i(31, 16)
const BEZOS_DRONE_FLOAT_OFFSET := Vector2(0, -14)
const HIDDEN_BUNKER_TILE := Vector2i(-32, -28)

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
	"mark_zuckerberg_ufo": Color(0.12, 0.12, 0.12)
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
	"ZELENSKY": "res://assets/mockups/zelensky_portrait.png",
	"DEATH": "res://assets/mockups/death_ironic.png"
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
	"death_bunker": "res://assets/mockups/death_ironic.png"
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
	"sam_altman": false
}
var landmark_sprite_paths: Dictionary = {
	"donald_trump": "res://assets/mockups/landmark_trump.png",
	"elon_musk": "res://assets/mockups/landmark_musk.png",
	"ursula_von_der_leyen": "res://assets/mockups/landmark_vdl.png",
	"christine_lagarde": "res://assets/mockups/landmark_lagarde.png",
	"vladimir_putin": "res://assets/mockups/landmark_putin.png",
	"emmanuel_macron": "res://assets/mockups/landmark_macron_ruined.png",
	"xi_jinping": "res://assets/mockups/landmark_great_wall.png",
	"sam_altman": "res://assets/mockups/landmark_nuclear_plant.png"
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
	_create_bunker_caption_ui()
	_create_transition_fx()
	_setup_interiors()
	_remove_world_npcs()
	_create_xi_world_npc()
	_create_great_wall_landmark()
	_create_sam_altman_encounter()
	_create_ufo_easter_egg()
	_create_bezos_drone_encounter()
	_create_hidden_bunker_entrance()
	_ensure_contamination_figure()
	_assign_npc_textures()
	_create_ai_terminal()
	_create_typewriter_bip()
	_setup_ambient_audio()
	_create_atmosphere_particles()
	_create_intro_overlay()
	_create_ending_overlay()
	_create_bezos_cinematic_overlay()

func _remove_world_npcs() -> void:
	for child in entities_layer.get_children():
		if child == player:
			continue
		if child.is_in_group("npc"):
			entities_layer.remove_child(child)
			child.queue_free()

func _create_xi_world_npc() -> void:
	var npc = NPC_SCENE.instantiate()
	npc.name = "XiJinpingWorld"
	npc.character_id = "xi_jinping"
	npc.character_name = "Xi Jinping"
	npc.interaction_distance = 96.0
	npc.indicator_distance = 140.0
	var sprite := npc.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.scale = Vector2(1.0, 1.0)
	# Position: attached to the side of the Great Wall
	npc.position = _tile_to_body_position(GREAT_WALL_TILE) + XI_WORLD_PIXEL_OFFSET
	npc.z_index = 3
	entities_layer.add_child(npc)
	_clear_decor_near_xi(npc)

func _create_great_wall_landmark() -> void:
	var sprite = Sprite2D.new()
	sprite.name = "GreatWallLandmark"
	var tex_path = "res://assets/mockups/landmark_great_wall.png"
	if not ResourceLoader.exists(tex_path):
		return
	
	var tex = load(tex_path)
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = _tile_to_body_position(GREAT_WALL_TILE)
	sprite.z_index = 1
	var tex_h = tex.get_height()
	sprite.offset = Vector2(0, -tex_h * 0.5)
	sprite.scale = Vector2(0.38, 0.38)
	entities_layer.add_child(sprite)

func _create_sam_altman_encounter() -> void:
	# Create Landmark (Nuclear Plant)
	var plant = Sprite2D.new()
	plant.name = "NuclearPlantLandmark"
	var tex_path = "res://assets/mockups/landmark_nuclear_plant.png"
	if ResourceLoader.exists(tex_path):
		var tex = load(tex_path)
		plant.texture = tex
		plant.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		plant.position = _tile_to_body_position(NUCLEAR_PLANT_TILE)
		plant.z_index = 1
		plant.offset = Vector2(0, -tex.get_height() * 0.5)
		plant.scale = Vector2(0.38, 0.38)
		entities_layer.add_child(plant)
	
	# Create NPC (Sam)
	var npc = NPC_SCENE.instantiate()
	npc.name = "SamAltmanWorld"
	npc.character_id = "sam_altman"
	npc.character_name = "Sam Altman"
	npc.position = _tile_to_body_position(SAM_ALTMAN_TILE) + Vector2(165, 75)
	npc.z_index = 3
	entities_layer.add_child(npc)
	var sprite := npc.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.scale = Vector2(1.0, 1.0)
	_clear_decor_near_xi(npc)

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
	# Flash effect on new line
	if bezos_escalation_bubble:
		bezos_escalation_bubble.modulate = Color(1.4, 1.4, 1.4, 1.0)
		var tw := create_tween()
		tw.tween_property(bezos_escalation_bubble, "modulate", Color.WHITE, 0.2)

func _start_bezos_cinematic() -> void:
	bezos_cinematic_seen = true
	bezos_cinematic_active = true
	bezos_escalation_active = false
	# Clean up world bubble
	if bezos_escalation_bubble:
		bezos_escalation_bubble.queue_free()
		bezos_escalation_bubble = null

	await _fade_transition(1.0, 0.15)
	if bezos_cinematic_layer:
		bezos_cinematic_layer.visible = true
		if bezos_cinematic_root:
			bezos_cinematic_root.modulate.a = 1.0
		_layout_bezos_cinematic_frame()
		transition_overlay.visible = false
		transition_overlay.modulate.a = 0.0
		_begin_bezos_cinematic_state(BezosCinematicState.STAGE)

func _create_hidden_bunker_entrance() -> void:
	_clear_decor_patch(HIDDEN_BUNKER_TILE, 3, 2)

	hidden_bunker_root = Node2D.new()
	hidden_bunker_root.name = "HiddenBunkerEntrance"
	hidden_bunker_root.position = _tile_to_body_position(HIDDEN_BUNKER_TILE)
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

	var label := Label.new()
	label.text = "DO NOT ENTER"
	label.position = Vector2(-44, 48)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.82, 0.84, 0.9, 0.78))
	hidden_bunker_root.add_child(label)

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

	var ufo_room = OVAL_OFFICE_ROOM_SCENE.instantiate()
	ufo_room.name = "UfoLabInterior"
	ufo_room.position = Vector2(0, 3200 + building_specs.size() * 960)
	ufo_room.set("room_key", "ufo_lab")
	ufo_room.set("character_id", "ufo_easter_egg")
	ufo_room.set("character_name", "Albert Einstein")
	interiors_layer.add_child(ufo_room)
	room_registry["ufo_lab"] = ufo_room
	if ufo_room.has_method("set_room_active"):
		ufo_room.set_room_active(false)
	world_spawn_points["ufo_lab_exterior"] = _tile_to_actor_position(UFO_TILE + Vector2i(0, 3))

	var bunker_room = OVAL_OFFICE_ROOM_SCENE.instantiate()
	bunker_room.name = "HiddenBunkerInterior"
	bunker_room.position = Vector2(0, 3200 + (building_specs.size() + 1) * 960)
	bunker_room.set("room_key", "mountain_bunker")
	bunker_room.set("character_id", "hidden_bunker_scene")
	bunker_room.set("character_name", "Hidden Bunker")
	interiors_layer.add_child(bunker_room)
	room_registry["mountain_bunker"] = bunker_room
	if bunker_room.has_method("set_room_active"):
		bunker_room.set_room_active(false)
	world_spawn_points["mountain_bunker_exterior"] = _tile_to_actor_position(HIDDEN_BUNKER_TILE + Vector2i(0, 2))

func _create_world_doorway(door_name: String, tile_pos: Vector2i, destination: String, spawn_marker: String) -> void:
	var door := Area2D.new()
	door.name = door_name
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
	if is_dialogue_open or is_room_transition or hidden_bunker_scene_active or contamination_active:
		return
	var now := Time.get_ticks_msec()
	if now < door_cooldown_until_ms:
		return
	door_cooldown_until_ms = now + 550
	var contamination_source := active_room_id if destination == "world" else ""
	var leaving_hidden_bunker := destination == "world" and active_room_id == "mountain_bunker"
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
		call_deferred("_queue_hidden_bunker_ai_ack")
	if destination == "world":
		call_deferred("_maybe_queue_contamination_event", contamination_source)

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
	tw.tween_property(room_title_card, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.55)
	tw.tween_property(room_title_card, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
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
		_process_intro(delta)
		return
	if ending_active:
		_process_ending(delta)
		return
	if bezos_cinematic_active:
		_process_bezos_cinematic(delta)
		return
	_process_ufo_easter_egg(delta)
	_process_bezos_drone(delta)
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

	# --- Contamination Spectral Breathing & Shader ---
	if contamination_active and contamination_root:
		var spr := contamination_root.get_node_or_null("Sprite") as Sprite2D
		if spr:
			var base_scale := float(spr.get_meta("base_scale", 0.22))
			var breath := 1.0 + sin(Time.get_ticks_msec() * 0.003) * 0.03
			spr.scale = Vector2(base_scale, base_scale * breath)
			if spr.material is ShaderMaterial:
				spr.material.set_shader_parameter("time", Time.get_ticks_msec() * 0.001)

	match bezos_escalation_step:
		0:
			if bezos_escalation_timer >= 3.2:
				bezos_escalation_step = 1
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"...Where's the 'no' button?",
					Color(0.4, 0.75, 1.0)
				)
		1:
			if bezos_escalation_timer >= 2.4:
				bezos_escalation_step = 2
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"AMZN DRONE",
					"That option was deprecated.\nAlgorithmically, you already said yes.",
					Color(1.0, 0.82, 0.3)
				)
		2:
			if bezos_escalation_timer >= 2.6:
				bezos_escalation_step = 3
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"I was just WALKING past a drone!\nThat counts as consent?!",
					Color(0.4, 0.75, 1.0)
				)
		3:
			if bezos_escalation_timer >= 2.8:
				bezos_escalation_step = 4
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"AMZN DRONE",
					"Proximity within 8 meters of an Amazon device\nconstitutes passive agreement.\nSee Terms of Service §47, clause 'Existence'.",
					Color(1.0, 0.82, 0.3)
				)
		4:
			if bezos_escalation_timer >= 3.0:
				bezos_escalation_step = 5
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"Your workers pee in BOTTLES.\nYou timed their toilet breaks to the SECOND\nand fired them for going over.",
					Color(0.4, 0.75, 1.0)
				)
		5:
			if bezos_escalation_timer >= 2.8:
				bezos_escalation_step = 6
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"BEZOS",
					"Bladder efficiency is an untapped frontier.\nWe are DISRUPTING hydration logistics.\nThe market demands it.",
					Color(1.0, 0.92, 0.16)
				)
		6:
			if bezos_escalation_timer >= 3.2:
				bezos_escalation_step = 7
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"You had a BRIDGE dismantled in Rotterdam\nto move your $500M megayacht out of port.\nA HISTORIC BRIDGE. For a @#$%ing BOAT.",
					Color(0.4, 0.75, 1.0)
				)
		7:
			if bezos_escalation_timer >= 3.0:
				bezos_escalation_step = 8
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"BEZOS",
					"It was structurally non-optimal.\nI liberated it from its original purpose.\nYou're welcome, Rotterdam.",
					Color(1.0, 0.92, 0.16)
				)
		8:
			if bezos_escalation_timer >= 3.4:
				bezos_escalation_step = 9
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"Your ex-wife gave away $17 BILLION to charity\nwhile you were buying a ROCKET\nshaped like a—  ...you know what it looks like.",
					Color(0.4, 0.75, 1.0)
				)
		9:
			if bezos_escalation_timer >= 3.2:
				bezos_escalation_step = 10
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"BEZOS",
					"Blue Origin is a LEGACY project for humanity.\nAlso she was slowing down my optimization.\nHer tax write-offs are frankly excessive.",
					Color(1.0, 0.92, 0.16)
				)
		10:
			if bezos_escalation_timer >= 3.4:
				bezos_escalation_step = 11
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"CITIZEN",
					"Your Ring doorbells helped arrest more\ninnocent people than any spy network.\nYou turned SUBURBIA into a SURVEILLANCE STATE.",
					Color(0.4, 0.75, 1.0)
				)
		11:
			if bezos_escalation_timer >= 3.4:
				bezos_escalation_step = 12
				bezos_escalation_timer = 0.0
				_set_bezos_escalation_line(
					"BEZOS",
					"Your dissatisfaction has been ESCALATED\nto the Dispute Resolution Dept.\nThat's me. I AM the department.",
					Color(1.0, 0.4, 0.2)
				)
		12:
			if bezos_escalation_timer >= 3.0:
				bezos_escalation_step = 13
				call_deferred("_start_bezos_cinematic")


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
	# Typewriter timer
	typewriter_timer = Timer.new()
	typewriter_timer.one_shot = false
	typewriter_timer.wait_time = 0.018
	typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(typewriter_timer)

	# Anchor control (holds panel + continue indicator)
	dialogue_anchor = Control.new()
	dialogue_anchor.name = "DialogueAnchor"
	dialogue_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_anchor.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_anchor.offset_left = -340.0
	dialogue_anchor.offset_right = 340.0
	dialogue_anchor.offset_top = -232.0
	dialogue_anchor.offset_bottom = -10.0
	dialogue_anchor.visible = false

	# Single flat panel background to avoid nested boxes fighting for space
	dialogue_panel = PanelContainer.new()
	dialogue_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogue_style = StyleBoxFlat.new()
	dialogue_style.bg_color = Color(0.05, 0.05, 0.08, 0.96)
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
	dialogue_style.content_margin_top = 12
	dialogue_style.content_margin_bottom = 12
	dialogue_panel.add_theme_stylebox_override("panel", dialogue_style)

	# Horizontal layout: portrait | text
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	# Portrait without a second framed panel
	portrait_rect = TextureRect.new()
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.custom_minimum_size = Vector2(96, 96)
	hbox.add_child(portrait_rect)

	# Text column
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.4))
	vbox.add_child(name_label)

	text_label = RichTextLabel.new()
	text_label.add_theme_font_size_override("normal_font_size", 15)
	text_label.add_theme_color_override("default_color", Color(0.88, 0.88, 0.92))
	text_label.bbcode_enabled = false
	text_label.fit_content = false
	text_label.scroll_active = false
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.custom_minimum_size = Vector2(0, 96)
	text_label.clip_contents = true
	vbox.add_child(text_label)

	# Choice panel (JRPG style selection)
	choice_container = VBoxContainer.new()
	choice_container.name = "ChoiceContainer"
	choice_container.add_theme_constant_override("separation", 6)
	choice_container.visible = false
	vbox.add_child(choice_container)

	hbox.add_child(vbox)
	dialogue_panel.add_child(hbox)
	dialogue_anchor.add_child(dialogue_panel)

	# Continue indicator
	continue_label = Label.new()
	continue_label.text = "▼ SPACE"
	continue_label.add_theme_font_size_override("font_size", 12)
	continue_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	continue_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	continue_label.offset_left = -80.0
	continue_label.offset_top = -24.0
	continue_label.visible = false
	dialogue_anchor.add_child(continue_label)

	ui_layer.add_child(dialogue_anchor)


# ============================================================
#  DIALOGUE SYSTEM
# ============================================================

func open_dialogue(character_id: String) -> void:
	if is_dialogue_open or contamination_active:
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
	if not ai_override_lines.is_empty():
		ai_dialogue_override_active = true
		dialogue_lines = ai_override_lines.duplicate()
		ai_override_lines.clear()
		return

	ai_dialogue_override_active = false

	if ai_terminal_data.is_empty():
		dialogue_lines = ["System offline. Try again later."]
		return

	var phases: Dictionary = ai_terminal_data.get("phases", {})
	var phase_key := ""
	var last_done := ""

	if quest_finished:
		dialogue_lines = ["You already have all signatures. The file still has you."]
		var completed_summary := _build_file_summary_line()
		if completed_summary != "":
			dialogue_lines.append(completed_summary)
		var bunker_penalty := _build_hidden_bunker_final_line()
		if bunker_penalty != "":
			dialogue_lines.append(bunker_penalty)
		return

	if quest_index < 0:
		phase_key = "intro"
		quest_index = 0
	elif quest_index < quest_order.size():
		last_done = quest_order[quest_index - 1] if quest_index > 0 else ""
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
		last_done = quest_order[quest_order.size() - 1]
		quest_finished = true

	if phases.has(phase_key):
		var phase: Dictionary = phases[phase_key]
		dialogue_lines = Array(phase.get("lines", ["..."])).duplicate()
	else:
		dialogue_lines = ["..."]

	if last_done != "":
		var ai_mark_line := _build_ai_mark_line(last_done)
		if ai_mark_line != "":
			dialogue_lines.append(ai_mark_line)

	if quest_finished:
		var final_summary := _build_file_summary_line()
		if final_summary != "":
			dialogue_lines.append(final_summary)
		var bunker_penalty := _build_hidden_bunker_final_line()
		if bunker_penalty != "":
			dialogue_lines.append(bunker_penalty)

func _setup_politician_dialogue(character_id: String) -> void:
	var c_data: Dictionary = character_data_cache.get(character_id, {})
	var qd: Dictionary = c_data.get("quest_dialogue", {})
	var is_optional := bool(c_data.get("optional", false))

	if not is_optional and quest_completed.has(character_id):
		dialogue_lines = ["You already have my signature. What more do you want?"]
		return

	if not is_optional and quest_index < 0:
		dialogue_lines = ["Protocol says you talk to C.L.A.U.D.I.A. first. Start with the kiosk, not me."]
		return

	# Check if this is the correct target
	if not is_optional and quest_index >= 0 and quest_index < quest_order.size():
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
		_start_typewriter(_prepare_dialogue_line(str(dialogue_lines[dialogue_line_index])))
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
	_record_choice_mark(current_character_id, choice)

	if active_room_id != "" and room_registry.has(active_room_id):
		var active_room = room_registry[active_room_id]
		if active_room and active_room.has_method("handle_dialogue_choice"):
			active_room.handle_dialogue_choice(current_character_id, choice)

	# Show response lines
	var response: Array = choice.get("response", [])
	if response.size() > 0:
		dialogue_lines = response
		dialogue_line_index = 0
		continue_label.visible = false
		_start_typewriter(_prepare_dialogue_line(str(response[0])))
	else:
		_finish_dialogue()

func _finish_dialogue() -> void:
	# Mark quest completion for politicians
	if current_character_id != "ai_terminal" and not quest_completed.has(current_character_id):
		if quest_index >= 0 and quest_index < quest_order.size() and quest_order[quest_index] == current_character_id:
			quest_completed[current_character_id] = true
			quest_index += 1

	# Trigger ending if quest just finished via final AI dialogue
	var should_end: bool = quest_finished and current_character_id == "ai_terminal" and not ending_triggered
	var queue_contamination_after_ai := current_character_id == "ai_terminal" and quest_index > 0 and not should_end and not ai_dialogue_override_active
	_close_dialogue()
	if queue_contamination_after_ai:
		get_tree().create_timer(0.26).timeout.connect(func() -> void:
			_maybe_queue_contamination_event("ai_terminal")
		)
	if should_end:
		ending_triggered = true
		# Small delay before the dramatic ending
		get_tree().create_timer(1.5).timeout.connect(start_ending_sequence)

func _record_choice_mark(character_id: String, choice: Dictionary) -> void:
	if character_id == "ai_terminal":
		return

	var file_tag := str(choice.get("file_tag", "")).strip_edges()
	var file_note := str(choice.get("file_note", "")).strip_edges()
	var ai_comment := str(choice.get("ai_comment", "")).strip_edges()
	if file_tag == "" and file_note == "" and ai_comment == "":
		return

	encounter_marks[character_id] = {
		"file_tag": file_tag,
		"file_note": file_note,
		"ai_comment": ai_comment
	}

func _build_ai_mark_line(character_id: String) -> String:
	if not encounter_marks.has(character_id):
		return ""

	var mark: Dictionary = encounter_marks[character_id]
	var ai_comment := str(mark.get("ai_comment", "")).strip_edges()
	if ai_comment != "":
		return "File note: %s" % ai_comment

	var file_note := str(mark.get("file_note", "")).strip_edges()
	if file_note != "":
		return "File note: %s" % file_note

	return ""

func _build_file_summary_line() -> String:
	var tags: Array = []
	for character_id in quest_order:
		if not encounter_marks.has(character_id):
			continue
		var mark: Dictionary = encounter_marks[character_id]
		var file_tag := str(mark.get("file_tag", "")).strip_edges()
		if file_tag != "":
			tags.append(file_tag)

	if tags.is_empty():
		return ""

	var preview: Array = []
	var preview_limit: int = mini(tags.size(), 4)
	for i in range(preview_limit):
		preview.append(tags[i])

	if tags.size() > 4:
		return "File profile: %s, plus %d more marks." % [_join_readable_list(preview), tags.size() - 4]
	return "File profile: %s." % _join_readable_list(tags)

func _build_hidden_bunker_final_line() -> String:
	if not seen_hidden_bunker_scene:
		return ""
	return "Administrative correction: because you visited the man in the bunker asking death for one more delivery, all obtained documents are withdrawn until further notice. In bureaucratic terms, that means until death."

func _dialogue_display_name(character_id: String) -> String:
	match character_id:
		"ufo_easter_egg":
			return "Albert Einstein"
		"mark_zuckerberg_ufo":
			return "Mark Zuckerberg"
		_:
			var c_data: Dictionary = character_data_cache.get(character_id, {})
			return str(c_data.get("name", "C.L.A.U.D.I.A." if character_id == "ai_terminal" else "Unknown"))

func _apply_dialogue_identity(character_id: String) -> void:
	var border_color: Color = character_colors.get(character_id, Color(0.2, 0.7, 0.9))
	if dialogue_style is StyleBoxFlat:
		dialogue_style.border_color = border_color
	elif dialogue_style is StyleBoxTexture:
		dialogue_style.modulate_color = border_color.lightened(0.5)

	portrait_rect.visible = true
	if portrait_paths.has(character_id) and ResourceLoader.exists(portrait_paths[character_id]):
		portrait_rect.texture = load(portrait_paths[character_id])
	else:
		portrait_rect.texture = null

	name_label.text = _dialogue_display_name(character_id)

func _prepare_dialogue_line(raw_text: String) -> String:
	if current_character_id != "ufo_easter_egg":
		_apply_dialogue_identity(current_character_id)
		return raw_text

	var stripped := raw_text.strip_edges()
	if stripped.begins_with("ZUCKERBERG:"):
		_apply_dialogue_identity("mark_zuckerberg_ufo")
		return stripped.trim_prefix("ZUCKERBERG:").strip_edges()
	if stripped.begins_with("EINSTEIN:"):
		_apply_dialogue_identity("ufo_easter_egg")
		return stripped.trim_prefix("EINSTEIN:").strip_edges()

	_apply_dialogue_identity("ufo_easter_egg")
	return raw_text

func _join_readable_list(items: Array) -> String:
	if items.is_empty():
		return ""
	if items.size() == 1:
		return str(items[0])
	if items.size() == 2:
		return "%s and %s" % [items[0], items[1]]

	var result := ""
	for i in range(items.size()):
		var item := str(items[i])
		if i == items.size() - 1:
			result += "and %s" % item
		else:
			if i > 0:
				result += ", "
			result += item
	return result

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

func _create_bunker_caption_ui() -> void:
	return

func _show_bunker_caption(speaker: String, text: String) -> void:
	if not dialogue_anchor:
		return
	typewriter_timer.stop()
	continue_label.visible = false
	choice_container.visible = false
	
	# Set Special Bunker Portraits
	if portrait_paths.has(speaker) and ResourceLoader.exists(portrait_paths[speaker]):
		portrait_rect.texture = load(portrait_paths[speaker])
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
	ai_override_lines = [str(hidden_bunker_data.get("post_ai_line", "I told you not to come here."))]
	var timer := get_tree().create_timer(0.3)
	timer.timeout.connect(func() -> void:
		if not is_dialogue_open and not is_room_transition and active_room_id == "":
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
	if randf() > CONTAMINATION_TRIGGER_CHANCE:
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
	await get_tree().create_timer(_contamination_read_duration(line)).timeout
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

func _create_standalone_npc(sprite_id: String, character_id: String) -> StaticBody2D:
	var npc = preload("res://scenes/npc.tscn").instantiate()
	npc.set("character_id", character_id)
	var tex_path = npc_sprite_paths.get(sprite_id, "")
	if tex_path != "" and ResourceLoader.exists(tex_path):
		var spr = npc.get_node_or_null("Sprite2D")
		if spr: spr.texture = load(tex_path)
	return npc

func register_encounter_residue(character_id: String, residue_id: String, residue_note: String = "") -> void:
	encounter_residues[character_id] = {
		"id": residue_id,
		"note": residue_note
	}


# ============================================================
#  90s CRT TV INTRO SEQUENCE
# ============================================================

func _create_intro_overlay() -> void:
	player.set_physics_process(false)

	intro_layer = CanvasLayer.new()
	intro_layer.layer = 100

	# Dark blue TV background
	intro_bg = ColorRect.new()
	intro_bg.color = Color(0.04, 0.04, 0.12, 1.0)
	intro_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_layer.add_child(intro_bg)

	# VHS distortion + CRT curvature + scanlines — all in one shader
	intro_vhs_overlay = ColorRect.new()
	intro_vhs_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_vhs_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vhs_mat := ShaderMaterial.new()
	var vhs_shader := Shader.new()
	vhs_shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = SCREEN_UV;
	// CRT curvature
	vec2 curved = uv * 2.0 - 1.0;
	curved *= 1.0 + pow(abs(curved.yx), vec2(2.0)) * 0.04;
	curved = curved * 0.5 + 0.5;
	// Vignette (dark edges like old TV)
	float vignette = 1.0 - length((uv - 0.5) * 1.6);
	vignette = clamp(vignette, 0.0, 1.0);
	vignette = pow(vignette, 0.8);
	// Scanlines
	float scanline = sin(FRAGCOORD.y * 1.5) * 0.12 + 0.88;
	// Flicker
	float flicker = 0.97 + sin(TIME * 12.0) * 0.015 + sin(TIME * 7.3) * 0.01;
	// VHS tracking line
	float track_y = fract(TIME * 0.08);
	float track = 1.0 - smoothstep(0.0, 0.015, abs(uv.y - track_y)) * 0.25;
	// Combine
	float alpha = (1.0 - vignette) * 0.5 + (1.0 - scanline) * 0.5;
	alpha += (1.0 - flicker) * 0.5;
	alpha += (1.0 - track) * 0.3;
	COLOR = vec4(0.0, 0.0, 0.0, clamp(alpha, 0.0, 0.65));
}
"""
	vhs_mat.shader = vhs_shader
	intro_vhs_overlay.material = vhs_mat
	intro_layer.add_child(intro_vhs_overlay)

	# === TOP: Red "BREAKING NEWS" bar ===
	intro_breaking_bar = ColorRect.new()
	intro_breaking_bar.color = Color(0.75, 0.08, 0.08, 0.95)
	intro_breaking_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	intro_breaking_bar.offset_bottom = 38.0
	intro_layer.add_child(intro_breaking_bar)

	intro_breaking_label = Label.new()
	intro_breaking_label.text = "BREAKING NEWS"
	intro_breaking_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_breaking_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_breaking_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	intro_breaking_label.offset_bottom = 38.0
	intro_breaking_label.add_theme_font_size_override("font_size", 20)
	intro_breaking_label.add_theme_color_override("font_color", Color.WHITE)
	intro_breaking_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	intro_breaking_label.add_theme_constant_override("shadow_offset_x", 1)
	intro_breaking_label.add_theme_constant_override("shadow_offset_y", 1)
	intro_layer.add_child(intro_breaking_label)

	# White separator line under red bar
	var sep_top := ColorRect.new()
	sep_top.color = Color(1.0, 1.0, 1.0, 0.6)
	sep_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sep_top.offset_top = 38.0
	sep_top.offset_bottom = 40.0
	intro_layer.add_child(sep_top)

	# === BOTTOM: White ticker bar (CNN-style) ===
	intro_ticker_bar = ColorRect.new()
	intro_ticker_bar.name = "TickerBar"
	intro_ticker_bar.color = Color(1.0, 1.0, 1.0, 0.97)
	intro_ticker_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	intro_ticker_bar.offset_top = -42.0
	intro_layer.add_child(intro_ticker_bar)

	# Red "BREAKING" badge on left of ticker
	var ticker_badge := ColorRect.new()
	ticker_badge.name = "TickerBadge"
	ticker_badge.color = Color(0.80, 0.04, 0.04, 1.0)
	ticker_badge.position = Vector2(0, 0)
	ticker_badge.size = Vector2(138, 42)
	intro_ticker_bar.add_child(ticker_badge)

	var ticker_badge_label := Label.new()
	ticker_badge_label.text = "BREAKING"
	ticker_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ticker_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ticker_badge_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	ticker_badge_label.add_theme_font_size_override("font_size", 15)
	ticker_badge_label.add_theme_color_override("font_color", Color.WHITE)
	ticker_badge_label.add_theme_color_override("font_outline_color", Color(0.4, 0.0, 0.0))
	ticker_badge_label.add_theme_constant_override("outline_size", 2)
	ticker_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ticker_badge.add_child(ticker_badge_label)

	# Scrolling ticker text — dark red on white, bigger font
	intro_ticker_label = Label.new()
	intro_ticker_label.text = intro_ticker_texts[0]
	intro_ticker_label.add_theme_font_size_override("font_size", 16)
	intro_ticker_label.add_theme_color_override("font_color", Color(0.60, 0.0, 0.0))
	intro_ticker_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.25))
	intro_ticker_label.add_theme_constant_override("shadow_offset_x", 1)
	intro_ticker_label.add_theme_constant_override("shadow_offset_y", 1)
	intro_ticker_label.position = Vector2(148, 4)
	intro_ticker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_ticker_bar.add_child(intro_ticker_label)

	# Blue strip above ticker (CNN lower-third style)
	var blue_strip := ColorRect.new()
	blue_strip.name = "BlueStrip"
	blue_strip.color = Color(0.04, 0.18, 0.58, 0.95)
	blue_strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	blue_strip.offset_top = -72.0
	blue_strip.offset_bottom = -42.0
	intro_layer.add_child(blue_strip)

	# White 1px separator between blue strip and ticker
	var sep_mid := ColorRect.new()
	sep_mid.name = "SepMid"
	sep_mid.color = Color(1.0, 1.0, 1.0, 0.7)
	sep_mid.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sep_mid.offset_top = -43.0
	sep_mid.offset_bottom = -42.0
	intro_layer.add_child(sep_mid)

	# Network name inside blue strip (left)
	var blue_network := Label.new()
	blue_network.name = "BlueNetwork"
	blue_network.text = "CIVIC NIGHTMARE NEWS NETWORK"
	blue_network.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	blue_network.set_anchors_preset(Control.PRESET_FULL_RECT)
	blue_network.offset_left = 12.0
	blue_network.add_theme_font_size_override("font_size", 14)
	blue_network.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	blue_network.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blue_strip.add_child(blue_network)

	# === TOP-RIGHT: Channel logo (CNN-style red block) ===
	var logo_bg := ColorRect.new()
	logo_bg.name = "LogoBg"
	logo_bg.color = Color(0.82, 0.05, 0.05, 0.95)
	logo_bg.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	logo_bg.offset_left = -88.0
	logo_bg.offset_top = 44.0
	logo_bg.offset_right = -8.0
	logo_bg.offset_bottom = 90.0
	intro_layer.add_child(logo_bg)

	# "CN" white text centered in red box
	intro_channel_label = Label.new()
	intro_channel_label.text = "CN"
	intro_channel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_channel_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_channel_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_channel_label.add_theme_font_size_override("font_size", 30)
	intro_channel_label.add_theme_color_override("font_color", Color.WHITE)
	intro_channel_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
	intro_channel_label.add_theme_constant_override("shadow_offset_x", 2)
	intro_channel_label.add_theme_constant_override("shadow_offset_y", 2)
	intro_channel_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_bg.add_child(intro_channel_label)

	# "CIVIC NIGHTMARE" small subtitle under logo box
	var logo_sub := Label.new()
	logo_sub.name = "LogoSub"
	logo_sub.text = "CIVIC NIGHTMARE"
	logo_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_sub.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	logo_sub.offset_left = -88.0
	logo_sub.offset_top = 92.0
	logo_sub.offset_right = -8.0
	logo_sub.offset_bottom = 106.0
	logo_sub.add_theme_font_size_override("font_size", 9)
	logo_sub.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	logo_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_layer.add_child(logo_sub)

	# === TOP-LEFT: Date / time ===
	intro_datetime_label = Label.new()
	intro_datetime_label.text = "03.27.1989  22:41"
	intro_datetime_label.add_theme_font_size_override("font_size", 11)
	intro_datetime_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 0.5))
	intro_datetime_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	intro_datetime_label.offset_left = 12.0
	intro_datetime_label.offset_top = 46.0
	intro_datetime_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_layer.add_child(intro_datetime_label)

	# === CENTER: Main news text ===
	intro_text = Label.new()
	intro_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_text.offset_top = 50.0
	intro_text.offset_bottom = -60.0
	intro_text.add_theme_font_size_override("font_size", 24)
	intro_text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
	intro_text.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	intro_text.add_theme_constant_override("shadow_offset_x", 2)
	intro_text.add_theme_constant_override("shadow_offset_y", 2)
	intro_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	intro_text.text = ""
	intro_layer.add_child(intro_text)

	# Static noise overlay (channel transitions)
	intro_static_rect = ColorRect.new()
	intro_static_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_static_rect.visible = false
	intro_static_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var static_mat := ShaderMaterial.new()
	var static_shader := Shader.new()
	static_shader.code = """
shader_type canvas_item;
float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}
void fragment() {
	float n = rand(FRAGCOORD.xy * 0.01 + vec2(TIME * 100.0, TIME * 73.0));
	float colored = rand(FRAGCOORD.xy * 0.005 + vec2(TIME * 50.0, 0.0));
	vec3 col = mix(vec3(n), vec3(n * 0.8, n * 0.9, n), colored * 0.3);
	COLOR = vec4(col, 0.9);
}
"""
	static_mat.shader = static_shader
	intro_static_rect.material = static_mat
	intro_layer.add_child(intro_static_rect)

	# CRT scanlines on top of everything (including static)
	intro_scanlines = ColorRect.new()
	intro_scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scanline_mat := ShaderMaterial.new()
	var scanline_shader := Shader.new()
	scanline_shader.code = """
shader_type canvas_item;
void fragment() {
	float line = mod(FRAGCOORD.y, 3.0);
	float scanline = step(1.5, line) * 0.18;
	COLOR = vec4(0.0, 0.0, 0.0, scanline);
}
"""
	scanline_mat.shader = scanline_shader
	intro_scanlines.material = scanline_mat
	intro_layer.add_child(intro_scanlines)

	# "Press SPACE to skip" hint (subtle, bottom-right)
	var skip_hint := Label.new()
	skip_hint.name = "SkipHint"
	skip_hint.text = "SPACE to skip"
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_hint.offset_left = -140.0
	skip_hint.offset_top = -18.0
	skip_hint.add_theme_font_size_override("font_size", 10)
	skip_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.35))
	skip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_layer.add_child(skip_hint)

	# === LIVE indicator (blinking red dot + text) ===
	intro_live_dot = ColorRect.new()
	intro_live_dot.color = Color(0.9, 0.1, 0.1)
	intro_live_dot.custom_minimum_size = Vector2(8, 8)
	intro_live_dot.set_anchors_preset(Control.PRESET_TOP_LEFT)
	intro_live_dot.offset_left = 14.0
	intro_live_dot.offset_top = 60.0
	intro_live_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_layer.add_child(intro_live_dot)

	intro_live_label = Label.new()
	intro_live_label.text = "LIVE"
	intro_live_label.add_theme_font_size_override("font_size", 10)
	intro_live_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 0.9))
	intro_live_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	intro_live_label.offset_left = 26.0
	intro_live_label.offset_top = 57.0
	intro_live_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_layer.add_child(intro_live_label)

	# === Channel number (top-right, under CN logo) ===
	intro_ch_label = Label.new()
	intro_ch_label.text = "CH 01"
	intro_ch_label.add_theme_font_size_override("font_size", 10)
	intro_ch_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.2))
	intro_ch_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	intro_ch_label.offset_left = -56.0
	intro_ch_label.offset_top = 72.0
	intro_ch_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_layer.add_child(intro_ch_label)

	# === CRT boot-up line (white horizontal line, centered) ===
	intro_crt_line = ColorRect.new()
	intro_crt_line.color = Color(0.9, 0.92, 1.0, 0.95)
	intro_crt_line.set_anchors_preset(Control.PRESET_CENTER)
	intro_crt_line.offset_left = -400.0
	intro_crt_line.offset_right = 400.0
	intro_crt_line.offset_top = -1.0
	intro_crt_line.offset_bottom = 1.0
	intro_crt_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_crt_line.visible = true
	intro_layer.add_child(intro_crt_line)

	# === CRT shutdown dot (white circle in center, hidden until shutdown) ===
	intro_crt_dot = ColorRect.new()
	intro_crt_dot.color = Color(0.95, 0.95, 1.0)
	intro_crt_dot.set_anchors_preset(Control.PRESET_CENTER)
	intro_crt_dot.offset_left = -3.0
	intro_crt_dot.offset_right = 3.0
	intro_crt_dot.offset_top = -3.0
	intro_crt_dot.offset_bottom = 3.0
	intro_crt_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_crt_dot.visible = false
	intro_layer.add_child(intro_crt_dot)

	add_child(intro_layer)

	# Hide all UI elements during boot — only the line shows
	intro_boot_done = false
	intro_shutdown = false
	_set_intro_ui_visible(false)
	intro_crt_line.visible = true
	intro_bg.visible = true

	# Start boot-up sequence
	intro_phase = 0
	intro_timer = 0.0
	intro_state = -1  # BOOT state

func _set_intro_ui_visible(vis: bool) -> void:
	intro_breaking_bar.visible = vis
	intro_breaking_label.visible = vis
	intro_ticker_bar.visible = vis
	intro_ticker_label.visible = vis
	intro_channel_label.visible = vis
	intro_datetime_label.visible = vis
	intro_text.visible = vis
	intro_vhs_overlay.visible = vis
	intro_scanlines.visible = vis
	# New CNN-style elements
	for n in ["BlueStrip", "SepMid", "LogoBg", "LogoSub"]:
		var nd := intro_layer.get_node_or_null(n)
		if nd: nd.visible = vis
	intro_live_dot.visible = vis
	intro_live_label.visible = vis
	intro_ch_label.visible = vis

func _intro_start_headline(index: int) -> void:
	if index >= intro_headlines.size():
		return
	intro_full_text = intro_headlines[index]
	intro_current_text = ""
	intro_char_index = 0
	intro_text.text = ""
	intro_text.modulate.a = 1.0

	# Update breaking news bar title
	if index < intro_breaking_titles.size():
		intro_breaking_label.text = intro_breaking_titles[index]
	# Update ticker
	if index < intro_ticker_texts.size():
		intro_ticker_label.text = intro_ticker_texts[index]
		intro_ticker_label.position.x = 800.0

	# Color scheme per channel
	var bar_colors: Array = [
		Color(0.75, 0.08, 0.08),  # red — breaking
		Color(0.12, 0.45, 0.12),  # green — markets
		Color(0.15, 0.2, 0.55),   # navy — world
		Color(0.6, 0.35, 0.08),   # amber — special
		Color(0.4, 0.08, 0.08),   # dark red — live
		Color(0.08, 0.08, 0.08),  # black — emergency
	]
	if index < bar_colors.size():
		intro_breaking_bar.color = Color(bar_colors[index], 0.95)

	# Channel number
	intro_ch_label.text = "CH %02d" % (index + 1)

	# Fake clock advance
	var fake_minutes: int = 41 + index * 7
	@warning_ignore("integer_division")
	var fake_hours: int = 22 + fake_minutes / 60
	fake_minutes = fake_minutes % 60
	intro_datetime_label.text = "03.27.1989  %02d:%02d" % [fake_hours % 24, fake_minutes]

const INTRO_CHAR_SPEED := 0.045
const INTRO_HOLD_TIME := 2.2
const INTRO_STATIC_TIME := 0.5

enum IntroState { TYPING, HOLDING, STATIC_OUT, DONE }
var intro_state: int = 0  # IntroState

func _process_intro(delta: float) -> void:
	# Skip on Space/Enter (but not during boot or shutdown)
	if intro_state >= 0 and intro_state < 3:
		if Input.is_action_just_pressed("ui_accept"):
			intro_skip_held += 1.0
		if intro_skip_held > 0.0:
			_end_intro()
			return

	# Animate ticker scroll
	if intro_ticker_label and intro_boot_done and intro_state >= 0 and intro_state < 3:
		intro_ticker_label.position.x -= delta * 80.0
		if intro_ticker_label.position.x < -600.0:
			intro_ticker_label.position.x = 800.0

	# LIVE dot blink
	if intro_boot_done and intro_live_dot and intro_state >= 0 and intro_state < 3:
		intro_live_dot.modulate.a = 0.5 + sin(intro_timer * 4.0) * 0.5

	match intro_state:
		-1:  # BOOT — CRT line expands vertically, then reveals UI
			intro_timer += delta
			if intro_timer < 0.3:
				# Thin white line flickers on
				intro_crt_line.modulate.a = 0.5 + sin(intro_timer * 40.0) * 0.5
			elif intro_timer < 1.0:
				# Line expands vertically to fill screen
				intro_crt_line.modulate.a = 1.0
				var expand := (intro_timer - 0.3) / 0.7  # 0→1
				var half_h: float = expand * 300.0
				intro_crt_line.offset_top = -half_h
				intro_crt_line.offset_bottom = half_h
			else:
				# Boot done — show everything, start first headline
				intro_crt_line.visible = false
				intro_boot_done = true
				_set_intro_ui_visible(true)
				intro_static_rect.visible = false
				intro_state = 0  # TYPING
				intro_timer = 0.0
				intro_phase = 0
				_intro_start_headline(0)

		0:  # TYPING
			intro_timer += delta
			while intro_timer >= INTRO_CHAR_SPEED and intro_char_index < intro_full_text.length():
				intro_current_text += intro_full_text[intro_char_index]
				intro_char_index += 1
				intro_timer -= INTRO_CHAR_SPEED
				intro_text.text = intro_current_text
			if intro_char_index >= intro_full_text.length():
				intro_state = 1  # HOLDING
				intro_timer = 0.0

		1:  # HOLDING
			intro_timer += delta
			if intro_timer >= INTRO_HOLD_TIME:
				intro_state = 2  # STATIC_OUT
				intro_timer = 0.0
				intro_static_rect.visible = true

		2:  # STATIC_OUT
			intro_timer += delta
			if intro_timer >= INTRO_STATIC_TIME:
				intro_static_rect.visible = false
				intro_phase += 1
				if intro_phase >= intro_headlines.size():
					# Start CRT shutdown instead of fade
					intro_state = 3  # SHUTDOWN
					intro_timer = 0.0
					_set_intro_ui_visible(false)
				else:
					intro_state = 0  # TYPING
					intro_timer = 0.0
					_intro_start_headline(intro_phase)

		3:  # SHUTDOWN — screen collapses to horizontal line, then dot, then black
			intro_timer += delta
			if intro_timer < 0.4:
				# Screen crushes vertically to a line
				var crush := intro_timer / 0.4  # 0→1
				intro_bg.visible = true
				intro_bg.color = Color(0.04, 0.04, 0.12, 1.0)
				# Simulate vertical crush via white flash then line
				if crush > 0.1:
					intro_crt_line.visible = true
					var line_h: float = lerpf(300.0, 1.0, (crush - 0.1) / 0.9)
					intro_crt_line.offset_top = -line_h
					intro_crt_line.offset_bottom = line_h
					intro_crt_line.modulate.a = 1.0
			elif intro_timer < 0.7:
				# Line shrinks to a dot
				intro_crt_line.visible = false
				intro_crt_dot.visible = true
				var dot_t := (intro_timer - 0.4) / 0.3  # 0→1
				var dot_size: float = lerpf(3.0, 2.0, dot_t)
				intro_crt_dot.offset_left = -dot_size
				intro_crt_dot.offset_right = dot_size
				intro_crt_dot.offset_top = -dot_size
				intro_crt_dot.offset_bottom = dot_size
				intro_crt_dot.modulate.a = 1.0
			elif intro_timer < 1.5:
				# Dot fades out with phosphor glow
				intro_crt_dot.visible = true
				var fade_t := (intro_timer - 0.7) / 0.8
				intro_crt_dot.modulate.a = 1.0 - fade_t
			else:
				# Done
				_end_intro()

func _end_intro() -> void:
	intro_active = false
	if intro_layer:
		intro_layer.queue_free()
		intro_layer = null
	player.set_physics_process(true)


# ============================================================
#  TARANTINO-STYLE ENDING SEQUENCE
# ============================================================

func _create_ending_overlay() -> void:
	ending_layer = CanvasLayer.new()
	ending_layer.layer = 100
	ending_layer.visible = false

	ending_bg = ColorRect.new()
	ending_bg.color = Color(0.0, 0.0, 0.0, 1.0)
	ending_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_layer.add_child(ending_bg)

	# Scanlines for ending too
	var end_scanlines := ColorRect.new()
	end_scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scanline_mat := ShaderMaterial.new()
	var scanline_shader := Shader.new()
	scanline_shader.code = """
shader_type canvas_item;
void fragment() {
	float line = mod(FRAGCOORD.y, 3.0);
	float scanline = step(1.5, line) * 0.2;
	COLOR = vec4(0.0, 0.0, 0.0, scanline);
}
"""
	scanline_mat.shader = scanline_shader
	end_scanlines.material = scanline_mat
	ending_layer.add_child(end_scanlines)

	ending_text = Label.new()
	ending_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_text.add_theme_font_size_override("font_size", 24)
	ending_text.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	ending_text.add_theme_color_override("font_shadow_color", Color(0.2, 0.1, 0.0, 0.7))
	ending_text.add_theme_constant_override("shadow_offset_x", 2)
	ending_text.add_theme_constant_override("shadow_offset_y", 2)
	ending_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	ending_text.text = ""
	ending_layer.add_child(ending_text)

	add_child(ending_layer)

func start_ending_sequence() -> void:
	if ending_active:
		return
	ending_active = true
	ending_phase = 0
	ending_timer = 0.0
	ending_char_index = 0
	player.set_physics_process(false)
	is_dialogue_open = false
	dialogue_anchor.visible = false

	ending_layer.visible = true
	ending_bg.color.a = 0.0

	# Fade to black first
	var tw := create_tween()
	tw.tween_property(ending_bg, "color:a", 1.0, 1.5)
	tw.tween_callback(_ending_begin_text)

const ENDING_CHAR_SPEED := 0.05
const ENDING_HOLD_TIME := 3.0

enum EndingState { FADE_IN, TYPING, HOLDING, FADE_BETWEEN, DONE }
var ending_state: int = 0

func _ending_begin_text() -> void:
	ending_state = 1  # TYPING
	ending_timer = 0.0
	_ending_start_scene(0)

func _ending_start_scene(index: int) -> void:
	if index >= ending_scenes.size():
		return
	ending_full_text = ending_scenes[index]
	ending_current_text = ""
	ending_char_index = 0
	ending_text.text = ""
	ending_text.modulate.a = 1.0
	# Alternate warm/cool colors Tarantino-style
	var colors: Array = [
		Color(0.95, 0.85, 0.4),   # gold
		Color(0.9, 0.9, 0.85),    # white
		Color(0.82, 0.22, 0.18),  # red (Trump)
		Color(0.28, 0.48, 0.72),  # blue (Musk)
		Color(0.72, 0.65, 0.3),   # amber
		Color(0.2, 0.7, 0.9),     # cyan (CLAUDIA)
		Color(0.85, 0.85, 0.85),  # silver
		Color(0.95, 0.6, 0.3),    # orange
		Color(0.95, 0.85, 0.4),   # gold again for FIN
	]
	if index < colors.size():
		ending_text.add_theme_color_override("font_color", colors[index])

func _process_ending(delta: float) -> void:
	# Allow skip with Enter after first scene
	if ending_phase > 0 and Input.is_action_just_pressed("ui_accept"):
		if ending_state == 1 and ending_char_index < ending_full_text.length():
			# Skip typing — show full text
			ending_text.text = ending_full_text
			ending_char_index = ending_full_text.length()
			ending_state = 2  # HOLDING
			ending_timer = 0.0
			return
		elif ending_state == 2:
			# Skip hold — advance
			ending_timer = ENDING_HOLD_TIME
		elif ending_state == 4:
			# Final — just quit faster
			ending_timer = 10.0

	match ending_state:
		1:  # TYPING
			ending_timer += delta
			while ending_timer >= ENDING_CHAR_SPEED and ending_char_index < ending_full_text.length():
				ending_current_text += ending_full_text[ending_char_index]
				ending_char_index += 1
				ending_timer -= ENDING_CHAR_SPEED
				ending_text.text = ending_current_text
			if ending_char_index >= ending_full_text.length():
				ending_state = 2  # HOLDING
				ending_timer = 0.0

		2:  # HOLDING
			ending_timer += delta
			if ending_timer >= ENDING_HOLD_TIME:
				ending_phase += 1
				if ending_phase >= ending_scenes.size():
					ending_state = 4  # DONE
					ending_timer = 0.0
				else:
					ending_state = 3  # FADE_BETWEEN
					ending_timer = 0.0

		3:  # FADE_BETWEEN
			ending_timer += delta
			var fade_dur := 0.8
			if ending_timer < fade_dur * 0.5:
				ending_text.modulate.a = 1.0 - (ending_timer / (fade_dur * 0.5))
			elif ending_timer < fade_dur:
				if ending_text.text != "":
					_ending_start_scene(ending_phase)
				ending_text.modulate.a = (ending_timer - fade_dur * 0.5) / (fade_dur * 0.5)
			else:
				ending_text.modulate.a = 1.0
				ending_state = 1  # TYPING
				ending_timer = 0.0

		4:  # DONE — hold final screen then fade
			ending_timer += delta
			if ending_timer >= 4.0:
				ending_text.modulate.a = max(0.0, 1.0 - (ending_timer - 4.0) / 2.0)
			if ending_timer >= 6.0:
				ending_active = false
				ending_layer.visible = false
				# Return to game (credits done)
				player.set_physics_process(true)

# ── Bezos SF2 cinematic (1280×720, centrato, fedele a SSF II) ──
#
# Layout SF2 (arcade 384×224 → scaled 3.33x):
#   HP bars:  P1=giallo a sinistra, P2=blu a destra, timer "99" al centro
#   Cards:    Due ritratti 360×480 simmetrici centrati
#   Testi:    ROUND 1 giallo, FIGHT! rosso, K.O. bianco, PERFECT giallo
#   Barra sotto: "PRIME MEMBERSHIP" che si svuota = la battuta

func _create_bezos_cinematic_overlay() -> void:
	bezos_cinematic_layer = CanvasLayer.new()
	bezos_cinematic_layer.layer = 105
	bezos_cinematic_layer.visible = false

	bezos_cinematic_root = Control.new()
	bezos_cinematic_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	bezos_cinematic_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bezos_cinematic_layer.add_child(bezos_cinematic_root)

	# Pure black bg
	bezos_cinematic_bg = ColorRect.new()
	bezos_cinematic_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bezos_cinematic_bg.color = Color.BLACK
	bezos_cinematic_root.add_child(bezos_cinematic_bg)

	# Scanlines
	bezos_cinematic_scanlines = ColorRect.new()
	bezos_cinematic_scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	bezos_cinematic_scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sl_mat := ShaderMaterial.new()
	var sl_sh := Shader.new()
	sl_sh.code = "shader_type canvas_item;\nvoid fragment() { COLOR = vec4(0,0,0, step(1.4, mod(FRAGCOORD.y, 3.0)) * 0.15); }\n"
	sl_mat.shader = sl_sh
	bezos_cinematic_scanlines.material = sl_mat
	bezos_cinematic_root.add_child(bezos_cinematic_scanlines)

	bezos_cinematic_frame = Control.new()
	bezos_cinematic_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bezos_cinematic_frame.size = BEZOS_CINEMATIC_FRAME_SIZE
	bezos_cinematic_root.add_child(bezos_cinematic_frame)
	bezos_cinematic_root.resized.connect(_layout_bezos_cinematic_frame)

	# ═══ TOP HUD: HP bars + names + timer (SF2 style) ═══
	# Symmetric: bars 480px each, 80px center gap for timer
	# Left bar x=120→600, Right bar x=680→1160
	# HP fill inside: 2px inset each side

	# P1 name (above bar, white like SF2)
	var p1_name := Label.new()
	p1_name.name = "P1Name"
	p1_name.text = "BEZOS"
	p1_name.position = Vector2(120, 8)
	p1_name.add_theme_font_size_override("font_size", 22)
	p1_name.add_theme_color_override("font_color", Color.WHITE)
	p1_name.add_theme_color_override("font_shadow_color", Color.BLACK)
	p1_name.add_theme_constant_override("shadow_offset_x", 2)
	p1_name.add_theme_constant_override("shadow_offset_y", 2)
	p1_name.visible = false
	bezos_cinematic_frame.add_child(p1_name)

	# P2 name (above bar, right-aligned, white)
	var p2_name := Label.new()
	p2_name.name = "P2Name"
	p2_name.text = "CITIZEN"
	p2_name.position = Vector2(680, 8)
	p2_name.size = Vector2(480, 28)
	p2_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	p2_name.add_theme_font_size_override("font_size", 22)
	p2_name.add_theme_color_override("font_color", Color.WHITE)
	p2_name.add_theme_color_override("font_shadow_color", Color.BLACK)
	p2_name.add_theme_constant_override("shadow_offset_x", 2)
	p2_name.add_theme_constant_override("shadow_offset_y", 2)
	p2_name.visible = false
	bezos_cinematic_frame.add_child(p2_name)

	# P1 HP bar bg (Dark Red)
	bezos_cinematic_left_bar = ColorRect.new()
	bezos_cinematic_left_bar.position = Vector2(120, 36)
	bezos_cinematic_left_bar.size = Vector2(480, 26)
	bezos_cinematic_left_bar.color = Color("#880000")
	bezos_cinematic_left_bar.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_left_bar)

	# P1 HP fill (SF2 Yellow)
	bezos_cinematic_left_hp = ColorRect.new()
	bezos_cinematic_left_hp.position = Vector2(122, 38)
	bezos_cinematic_left_hp.size = Vector2(476, 22)
	bezos_cinematic_left_hp.color = Color("#ffff29")
	bezos_cinematic_left_hp.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_left_hp)

	# Timer "99" (center)
	bezos_cinematic_timer_label = Label.new()
	bezos_cinematic_timer_label.name = "Timer"
	bezos_cinematic_timer_label.text = "99"
	bezos_cinematic_timer_label.position = Vector2(604, 26)
	bezos_cinematic_timer_label.size = Vector2(72, 44)
	bezos_cinematic_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bezos_cinematic_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bezos_cinematic_timer_label.add_theme_font_size_override("font_size", 38)
	bezos_cinematic_timer_label.add_theme_color_override("font_color", Color.WHITE)
	bezos_cinematic_timer_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	bezos_cinematic_timer_label.add_theme_constant_override("shadow_offset_x", 3)
	bezos_cinematic_timer_label.add_theme_constant_override("shadow_offset_y", 3)
	bezos_cinematic_timer_label.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_timer_label)

	# P2 HP bar bg (Dark Red)
	bezos_cinematic_right_bar = ColorRect.new()
	bezos_cinematic_right_bar.position = Vector2(680, 36)
	bezos_cinematic_right_bar.size = Vector2(480, 26)
	bezos_cinematic_right_bar.color = Color("#880000")
	bezos_cinematic_right_bar.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_right_bar)

	# P2 HP fill (SF2 Yellow)
	bezos_cinematic_right_hp = ColorRect.new()
	bezos_cinematic_right_hp.position = Vector2(682, 38)
	bezos_cinematic_right_hp.size = Vector2(476, 22)
	bezos_cinematic_right_hp.color = Color("#ffff29")
	bezos_cinematic_right_hp.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_right_hp)

	# ═══ BOTTOM: "PRIME MEMBERSHIP" energy bar (humor) ═══
	# Bottom bar: Bezos's CORP. LEGAL SHIELD — aligned under his HP bar (left side only)
	var bottom_label := Label.new()
	bottom_label.name = "BottomLabel"
	bottom_label.text = "BEZOS CORP. LEGAL SHIELD™"
	bottom_label.position = Vector2(120, 668)
	bottom_label.size = Vector2(480, 24)
	bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bottom_label.add_theme_font_size_override("font_size", 13)
	bottom_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.16, 0.85))
	bottom_label.visible = false
	bezos_cinematic_frame.add_child(bottom_label)

	var bottom_bar_bg := ColorRect.new()
	bottom_bar_bg.name = "BottomBarBg"
	bottom_bar_bg.position = Vector2(120, 692)
	bottom_bar_bg.size = Vector2(480, 16)
	bottom_bar_bg.color = Color(0.25, 0.0, 0.0)
	bottom_bar_bg.visible = false
	bezos_cinematic_frame.add_child(bottom_bar_bg)

	var bottom_bar_hp := ColorRect.new()
	bottom_bar_hp.name = "BottomBarHP"
	bottom_bar_hp.position = Vector2(122, 694)
	bottom_bar_hp.size = Vector2(476, 12)
	bottom_bar_hp.color = Color(1.0, 0.92, 0.16)
	bottom_bar_hp.visible = false
	bezos_cinematic_frame.add_child(bottom_bar_hp)

	# ═══ Stage name (centered, big) ═══
	bezos_cinematic_stage = Label.new()
	bezos_cinematic_stage.text = "FULFILLMENT CATHEDRAL"
	bezos_cinematic_stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bezos_cinematic_stage.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bezos_cinematic_stage.position = Vector2(240, 330)
	bezos_cinematic_stage.size = Vector2(800, 60)
	bezos_cinematic_stage.add_theme_font_size_override("font_size", 38)
	bezos_cinematic_stage.add_theme_color_override("font_color", Color(1.0, 0.92, 0.16))
	bezos_cinematic_stage.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	bezos_cinematic_stage.add_theme_constant_override("shadow_offset_x", 3)
	bezos_cinematic_stage.add_theme_constant_override("shadow_offset_y", 3)
	bezos_cinematic_stage.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_stage)

	# ═══ Fighter cards — centered: each 360×480, 100px gap ═══
	# Left: x=(1280-360-100-360)/2 = 230   Right: x=230+360+100 = 690
	# Left Card: Bezos (Default Boss)
	bezos_cinematic_left_card = _create_sf2_fighter_card(
		"JEFF BEZOS", "B", Color(1.0, 1.0, 1.0), "FULFILLMENT PRIME",
		"res://assets/mockups/bezos_combat_portrait.png")
	bezos_cinematic_left_card.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_left_card)

	# Right Card: The Player (Default Citizen) 
	# Note: In a future expansion, this could be the leader we are facing!
	bezos_cinematic_right_card = _create_sf2_fighter_card(
		"CITIZEN", "?", Color(1.0, 1.0, 1.0), "MANUAL PROCESSING",
		"res://assets/mockups/player_combat_portrait.png")
	bezos_cinematic_right_card.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_right_card)

	# ═══ VS (giant, perfectly centered) ═══
	bezos_cinematic_vs = Label.new()
	bezos_cinematic_vs.text = "VS"
	bezos_cinematic_vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bezos_cinematic_vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bezos_cinematic_vs.position = Vector2(490, 260)
	bezos_cinematic_vs.size = Vector2(300, 120)
	bezos_cinematic_vs.add_theme_font_size_override("font_size", 110)
	bezos_cinematic_vs.add_theme_color_override("font_color", Color(1.0, 0.75, 0.1))
	bezos_cinematic_vs.add_theme_color_override("font_shadow_color", Color(0.3, 0.15, 0.0, 1.0))
	bezos_cinematic_vs.add_theme_constant_override("shadow_offset_x", 5)
	bezos_cinematic_vs.add_theme_constant_override("shadow_offset_y", 5)
	bezos_cinematic_vs.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_vs)

	# ═══ ROUND 1 ═══
	bezos_cinematic_round = Label.new()
	bezos_cinematic_round.text = "ROUND 1"
	bezos_cinematic_round.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bezos_cinematic_round.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bezos_cinematic_round.position = Vector2(290, 290)
	bezos_cinematic_round.size = Vector2(700, 80)
	bezos_cinematic_round.add_theme_font_size_override("font_size", 82)
	bezos_cinematic_round.add_theme_color_override("font_color", Color.WHITE)
	bezos_cinematic_round.add_theme_color_override("font_shadow_color", Color("#b00000"))
	bezos_cinematic_round.add_theme_constant_override("shadow_offset_x", 4)
	bezos_cinematic_round.add_theme_constant_override("shadow_offset_y", 4)
	bezos_cinematic_round.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_round)

	# ═══ FIGHT! ═══
	bezos_cinematic_fight = Label.new()
	bezos_cinematic_fight.text = "FIGHT!"
	bezos_cinematic_fight.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bezos_cinematic_fight.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bezos_cinematic_fight.position = Vector2(290, 280)
	bezos_cinematic_fight.size = Vector2(700, 100)
	bezos_cinematic_fight.add_theme_font_size_override("font_size", 110)
	bezos_cinematic_fight.add_theme_color_override("font_color", Color("#ff8800"))
	bezos_cinematic_fight.add_theme_color_override("font_shadow_color", Color("#ffff29"))
	bezos_cinematic_fight.add_theme_constant_override("shadow_offset_x", 0)
	bezos_cinematic_fight.add_theme_constant_override("shadow_offset_y", 4) # Bottom flame shadow
	bezos_cinematic_fight.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_fight)

	# ═══ K.O. ═══
	bezos_cinematic_ko = Label.new()
	bezos_cinematic_ko.text = "K.O."
	bezos_cinematic_ko.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bezos_cinematic_ko.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bezos_cinematic_ko.position = Vector2(390, 260)
	bezos_cinematic_ko.size = Vector2(500, 120)
	bezos_cinematic_ko.add_theme_font_size_override("font_size", 120)
	bezos_cinematic_ko.add_theme_color_override("font_color", Color.WHITE)
	bezos_cinematic_ko.add_theme_color_override("font_shadow_color", Color("#b00000"))
	bezos_cinematic_ko.add_theme_constant_override("shadow_offset_x", 6)
	bezos_cinematic_ko.add_theme_constant_override("shadow_offset_y", 6)
	bezos_cinematic_ko.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_ko)

	# ═══ PERFECT ═══
	bezos_cinematic_perfect = Label.new()
	bezos_cinematic_perfect.text = "PERFECT"
	bezos_cinematic_perfect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bezos_cinematic_perfect.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bezos_cinematic_perfect.position = Vector2(290, 390)
	bezos_cinematic_perfect.size = Vector2(700, 60)
	bezos_cinematic_perfect.add_theme_font_size_override("font_size", 54)
	bezos_cinematic_perfect.add_theme_color_override("font_color", Color("#ffff29"))
	bezos_cinematic_perfect.add_theme_color_override("font_shadow_color", Color("#b00000"))
	bezos_cinematic_perfect.add_theme_constant_override("shadow_offset_x", 3)
	bezos_cinematic_perfect.add_theme_constant_override("shadow_offset_y", 3)
	bezos_cinematic_perfect.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_perfect)

	# ═══ Flash overlay ═══
	bezos_cinematic_flash = ColorRect.new()
	bezos_cinematic_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	bezos_cinematic_flash.color = Color(1, 1, 1, 0)
	bezos_cinematic_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bezos_cinematic_flash.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_flash)

	# ═══ DENIED punchline ═══
	bezos_cinematic_denial = Label.new()
	bezos_cinematic_denial.text = "DISPUTE RESOLVED\nBY TERMS OF SERVICE"
	bezos_cinematic_denial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bezos_cinematic_denial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bezos_cinematic_denial.position = Vector2(190, 250)
	bezos_cinematic_denial.size = Vector2(900, 120)
	bezos_cinematic_denial.add_theme_font_size_override("font_size", 42)
	bezos_cinematic_denial.add_theme_color_override("font_color", Color(0.98, 0.15, 0.08))
	bezos_cinematic_denial.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	bezos_cinematic_denial.add_theme_constant_override("shadow_offset_x", 3)
	bezos_cinematic_denial.add_theme_constant_override("shadow_offset_y", 3)
	bezos_cinematic_denial.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_denial)

	# Queue joke
	bezos_cinematic_subtitle = Label.new()
	bezos_cinematic_subtitle.text = "Physical conflict has been replaced by fulfillment arbitration.\nYour complaint has been added to the queue.\nEstimated wait: 4,700 years."
	bezos_cinematic_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bezos_cinematic_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bezos_cinematic_subtitle.position = Vector2(240, 400)
	bezos_cinematic_subtitle.size = Vector2(800, 112)
	bezos_cinematic_subtitle.add_theme_font_size_override("font_size", 18)
	bezos_cinematic_subtitle.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7, 0.85))
	bezos_cinematic_subtitle.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_subtitle)

	bezos_cinematic_speaker = Label.new()
	bezos_cinematic_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bezos_cinematic_speaker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bezos_cinematic_speaker.position = Vector2(220, 494)
	bezos_cinematic_speaker.size = Vector2(840, 34)
	bezos_cinematic_speaker.add_theme_font_size_override("font_size", 18)
	bezos_cinematic_speaker.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	bezos_cinematic_speaker.add_theme_constant_override("shadow_offset_x", 2)
	bezos_cinematic_speaker.add_theme_constant_override("shadow_offset_y", 2)
	bezos_cinematic_speaker.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_speaker)

	bezos_cinematic_dialogue = Label.new()
	bezos_cinematic_dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bezos_cinematic_dialogue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bezos_cinematic_dialogue.position = Vector2(180, 528)
	bezos_cinematic_dialogue.size = Vector2(920, 112)
	bezos_cinematic_dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bezos_cinematic_dialogue.add_theme_font_size_override("font_size", 24)
	bezos_cinematic_dialogue.add_theme_color_override("font_color", Color(0.92, 0.92, 0.96))
	bezos_cinematic_dialogue.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	bezos_cinematic_dialogue.add_theme_constant_override("shadow_offset_x", 3)
	bezos_cinematic_dialogue.add_theme_constant_override("shadow_offset_y", 3)
	bezos_cinematic_dialogue.visible = false
	bezos_cinematic_frame.add_child(bezos_cinematic_dialogue)

	add_child(bezos_cinematic_layer)
	_layout_bezos_cinematic_frame()

func _get_combat_card_for_leader(character_id: String) -> PanelContainer:
	var path: String = combat_portrait_paths.get(character_id, "res://assets/mockups/player_combat_portrait.png")
	var c_name: String = "UNKNOWN"
	var badge: String = "?"
	var sub: String = "CITIZEN"
	
	match character_id:
		"donald_trump":
			c_name = "DONALD TRUMP"
			badge = "T"
			sub = "MAGA STRIKE"
		"elon_musk":
			c_name = "ELON MUSK"
			badge = "X"
			sub = "TECHNOKING"
		"vladimir_putin":
			c_name = "VLADIMIR PUTIN"
			badge = "P"
			sub = "KREMLIN OPS"
		"ursula_von_der_leyen":
			c_name = "V. D. LEYEN"
			badge = "U"
			sub = "EU OVERLORD"
		"emmanuel_macron":
			c_name = "E. MACRON"
			badge = "M"
			sub = "JUPITERIAN"
		"christine_lagarde":
			c_name = "C. LAGARDE"
			badge = "L"
			sub = "ECB LIQUIDITY"
	
	return _create_sf2_fighter_card(c_name, badge, character_colors.get(character_id, Color.WHITE), sub, path)

func _layout_bezos_cinematic_frame() -> void:
	if not bezos_cinematic_root or not bezos_cinematic_frame:
		return
	bezos_cinematic_frame.size = BEZOS_CINEMATIC_FRAME_SIZE
	bezos_cinematic_frame_base_position = (bezos_cinematic_root.size - BEZOS_CINEMATIC_FRAME_SIZE) * 0.5
	bezos_cinematic_frame.position = bezos_cinematic_frame_base_position

func _create_sf2_fighter_card(fighter_name: String, badge_text: String, accent: Color, subtitle_text: String, portrait_path: String = "") -> PanelContainer:
	var card := PanelContainer.new()
	card.size = Vector2(360, 480)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.01, 0.02, 1.0)
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.border_color = Color("#b00000") # SF2 Red border
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", -4)
	card.add_child(vbox)

	# Portrait Area
	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(348, 360)
	vbox.add_child(portrait)

	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var spr := TextureRect.new()
		spr.texture = load(portrait_path)
		spr.set_anchors_preset(Control.PRESET_FULL_RECT)
		spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.add_child(spr)

	# Name Banner (Yellow bar look)
	var name_bg := ColorRect.new()
	name_bg.custom_minimum_size = Vector2(0, 48)
	name_bg.color = Color("#ffff29")
	vbox.add_child(name_bg)

	var nm := Label.new()
	nm.text = fighter_name
	nm.set_anchors_preset(Control.PRESET_FULL_RECT)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 32)
	nm.add_theme_color_override("font_color", Color.BLACK) # Black text on yellow bar
	name_bg.add_child(nm)

	# Territory/Subtitle
	var sub := Label.new()
	sub.text = subtitle_text
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(sub)

	return card

func _bezos_hide_all_ui() -> void:
	for node in [bezos_cinematic_stage, bezos_cinematic_vs, bezos_cinematic_round,
			bezos_cinematic_fight, bezos_cinematic_ko, bezos_cinematic_perfect,
			bezos_cinematic_denial, bezos_cinematic_subtitle, bezos_cinematic_flash,
			bezos_cinematic_left_bar, bezos_cinematic_right_bar,
			bezos_cinematic_left_hp, bezos_cinematic_right_hp,
			bezos_cinematic_left_card, bezos_cinematic_right_card,
			bezos_cinematic_speaker, bezos_cinematic_dialogue,
			bezos_cinematic_timer_label]:
		if node: node.visible = false
	for n in ["P1Name", "P2Name", "BottomLabel", "BottomBarBg", "BottomBarHP"]:
		var nd := bezos_cinematic_frame.get_node_or_null(n) if bezos_cinematic_frame else null
		if nd: nd.visible = false

func _bezos_show_hud() -> void:
	for node in [bezos_cinematic_left_bar, bezos_cinematic_right_bar,
			bezos_cinematic_left_hp, bezos_cinematic_right_hp,
			bezos_cinematic_timer_label]:
		if node: node.visible = true
	for n in ["P1Name", "P2Name", "BottomLabel", "BottomBarBg", "BottomBarHP"]:
		var nd := bezos_cinematic_frame.get_node_or_null(n) if bezos_cinematic_frame else null
		if nd: nd.visible = true

func _begin_bezos_cinematic_state(state: int) -> void:
	bezos_cinematic_state = state
	bezos_cinematic_timer = 0.0

	# Cards centered: (1280-360-100-360)/2 = 230  |  230+360+100 = 690
	const CARD_LEFT_X := 230.0
	const CARD_RIGHT_X := 690.0
	const CARD_Y := 100.0

	match state:
		BezosCinematicState.STAGE:
			_bezos_hide_all_ui()
			bezos_cinematic_stage.visible = true
			bezos_cinematic_stage.modulate.a = 0.0
			# Big centered stage name
			bezos_cinematic_stage.position = Vector2(240, 310)
			bezos_cinematic_stage.size = Vector2(800, 80)
			bezos_cinematic_stage.add_theme_font_size_override("font_size", 38)
			bezos_cinematic_stage.add_theme_color_override("font_color", Color(1.0, 0.92, 0.16))
			var tw := create_tween()
			tw.tween_property(bezos_cinematic_stage, "modulate:a", 1.0, 0.5)

		BezosCinematicState.SLIDE_IN:
			# The stage title belongs only to the black intro beat.
			bezos_cinematic_stage.visible = false
			_bezos_show_hud()
			bezos_cinematic_timer_label.text = "99"
			# Cards slam in from sides
			bezos_cinematic_left_card.visible = true
			bezos_cinematic_right_card.visible = true
			bezos_cinematic_left_card.position = Vector2(-400, CARD_Y)
			bezos_cinematic_right_card.position = Vector2(1400, CARD_Y)
			var tw2 := create_tween()
			tw2.set_parallel(true)
			tw2.tween_property(bezos_cinematic_left_card, "position", Vector2(CARD_LEFT_X, CARD_Y), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw2.tween_property(bezos_cinematic_right_card, "position", Vector2(CARD_RIGHT_X, CARD_Y), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		BezosCinematicState.VS_SLAM:
			bezos_cinematic_stage.visible = false
			# VS slams center between cards with flash
			bezos_cinematic_vs.visible = true
			bezos_cinematic_vs.modulate.a = 0.0
			bezos_cinematic_vs.scale = Vector2(4.0, 4.0)
			bezos_cinematic_vs.pivot_offset = Vector2(150, 60)
			bezos_cinematic_flash.visible = true
			bezos_cinematic_flash.color = Color(1, 1, 1, 0.9)
			var tw3 := create_tween()
			tw3.set_parallel(true)
			tw3.tween_property(bezos_cinematic_vs, "modulate:a", 1.0, 0.1)
			tw3.tween_property(bezos_cinematic_vs, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw3.tween_property(bezos_cinematic_flash, "color:a", 0.0, 0.4)

		BezosCinematicState.FIGHT:
			bezos_cinematic_stage.visible = false
			bezos_cinematic_vs.visible = false
			bezos_cinematic_left_card.visible = false
			bezos_cinematic_right_card.visible = false
			# ROUND 1
			bezos_cinematic_round.visible = true
			bezos_cinematic_round.modulate.a = 0.0
			bezos_cinematic_round.scale = Vector2(2.0, 2.0)
			bezos_cinematic_round.pivot_offset = Vector2(350, 40)
			var tw4 := create_tween()
			tw4.tween_property(bezos_cinematic_round, "modulate:a", 1.0, 0.15)
			tw4.parallel().tween_property(bezos_cinematic_round, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			# Hold ROUND 1 long enough to read before the fake start.
			tw4.tween_interval(BEZOS_ROUND_HOLD)
			tw4.tween_callback(func():
				bezos_cinematic_round.visible = false
				# FIGHT!
				bezos_cinematic_fight.visible = true
				bezos_cinematic_fight.modulate.a = 0.0
				bezos_cinematic_fight.scale = Vector2(3.0, 3.0)
				bezos_cinematic_fight.pivot_offset = Vector2(350, 50)
				bezos_cinematic_flash.visible = true
				bezos_cinematic_flash.color = Color(1, 0.95, 0.85, 0.8)
				var tw5 := create_tween()
				tw5.set_parallel(true)
				tw5.tween_property(bezos_cinematic_fight, "modulate:a", 1.0, 0.08)
				tw5.tween_property(bezos_cinematic_fight, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw5.tween_property(bezos_cinematic_flash, "color:a", 0.0, 0.3)
			)

		BezosCinematicState.COMBAT:
			# Fake combat: FIGHT! fades, timer counts down, HP bars animate
			bezos_cinematic_stage.visible = false
			bezos_cinematic_fight.visible = false
			# Player HP starts full (476px), will drain in _process via shake/hits
			# Bezos HP stays full (he's invincible, obviously)
			# We animate this in _process_bezos_cinematic for per-frame control
			# Kick off with an opening hit flash
			bezos_cinematic_flash.visible = true
			bezos_cinematic_flash.color = Color(1.0, 0.85, 0.2, 0.6)
			var tw_combat := create_tween()
			tw_combat.tween_property(bezos_cinematic_flash, "color:a", 0.0, 0.15)

		BezosCinematicState.DENIED:
			bezos_cinematic_fight.visible = false
			# Flash = instant KO
			bezos_cinematic_flash.visible = true
			bezos_cinematic_flash.color = Color(1, 1, 1, 1.0)
			var tw6 := create_tween()
			tw6.tween_property(bezos_cinematic_flash, "color:a", 0.0, 0.55)
			# Your HP drains to zero + timer drops to 00
			# P2 bar: right edge fixed at 1158, left edge sweeps right (SF2 correct)
			tw6.parallel().tween_property(bezos_cinematic_right_hp, "size:x", 0.0, 0.75).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tw6.parallel().tween_property(bezos_cinematic_right_hp, "position:x", 1158.0, 0.75).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tw6.parallel().tween_callback(func(): bezos_cinematic_timer_label.text = "00")
			# Bottom bar (Prime Membership) drains too
			var bottom_hp := bezos_cinematic_frame.get_node_or_null("BottomBarHP") if bezos_cinematic_frame else null
			if bottom_hp:
				tw6.parallel().tween_property(bottom_hp, "size:x", 0.0, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			# Pause, then K.O.
			tw6.tween_interval(BEZOS_KO_DELAY)
			tw6.tween_callback(func():
				bezos_cinematic_ko.visible = true
				bezos_cinematic_ko.modulate.a = 0.0
				bezos_cinematic_ko.scale = Vector2(3.0, 3.0)
				bezos_cinematic_ko.pivot_offset = Vector2(250, 60)
				bezos_cinematic_flash.visible = true
				bezos_cinematic_flash.color = Color(1, 0.3, 0.1, 0.7)
				var tw7 := create_tween()
				tw7.set_parallel(true)
				tw7.tween_property(bezos_cinematic_ko, "modulate:a", 1.0, 0.1)
				tw7.tween_property(bezos_cinematic_ko, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw7.tween_property(bezos_cinematic_flash, "color:a", 0.0, 0.4)
			)
			# Pause, then PERFECT
			tw6.tween_interval(BEZOS_PERFECT_DELAY)
			tw6.tween_callback(func():
				bezos_cinematic_perfect.visible = true
				bezos_cinematic_perfect.modulate.a = 0.0
				var tw8 := create_tween()
				tw8.tween_property(bezos_cinematic_perfect, "modulate:a", 1.0, 0.35)
			)
			# Pause, then dim + show denial
			tw6.tween_interval(BEZOS_DENIAL_REVEAL_DELAY)
			tw6.tween_callback(func():
				bezos_cinematic_ko.visible = false
				bezos_cinematic_perfect.visible = false
				bezos_cinematic_left_bar.modulate.a = 0.15
				bezos_cinematic_right_bar.modulate.a = 0.15
				bezos_cinematic_left_hp.modulate.a = 0.15
				bezos_cinematic_stage.visible = false
				bezos_cinematic_timer_label.visible = false
				var bl := bezos_cinematic_frame.get_node_or_null("BottomLabel") if bezos_cinematic_frame else null
				var bg := bezos_cinematic_frame.get_node_or_null("BottomBarBg") if bezos_cinematic_frame else null
				var hp := bezos_cinematic_frame.get_node_or_null("BottomBarHP") if bezos_cinematic_frame else null
				if bl: bl.modulate.a = 0.15
				if bg: bg.modulate.a = 0.15
				if hp: hp.visible = false
				# Denial
				bezos_cinematic_denial.visible = true
				bezos_cinematic_denial.modulate.a = 0.0
				var tw9 := create_tween()
				tw9.tween_property(bezos_cinematic_denial, "modulate:a", 1.0, 0.3)
				tw9.tween_interval(BEZOS_SUBTITLE_REVEAL_DELAY)
				tw9.tween_callback(func():
					bezos_cinematic_subtitle.visible = true
					bezos_cinematic_subtitle.modulate.a = 0.0
					var tw10 := create_tween()
					tw10.tween_property(bezos_cinematic_subtitle, "modulate:a", 1.0, 0.5)
				)
			)

		BezosCinematicState.OUTRO:
			var tw11 := create_tween()
			tw11.tween_property(bezos_cinematic_root, "modulate:a", 0.0, 0.6)
			tw11.tween_callback(_finish_bezos_cinematic)

func _process_bezos_cinematic(delta: float) -> void:
	if not bezos_cinematic_layer or not bezos_cinematic_layer.visible:
		return
	bezos_cinematic_timer += delta

	match bezos_cinematic_state:
		BezosCinematicState.STAGE:
			# Stage name alone on black — let it breathe
			if bezos_cinematic_timer >= BEZOS_STAGE_DURATION:
				_begin_bezos_cinematic_state(BezosCinematicState.SLIDE_IN)
		BezosCinematicState.SLIDE_IN:
			# Cards slide in, hold for player to see the matchup
			if bezos_cinematic_timer >= BEZOS_SLIDE_IN_DURATION:
				_begin_bezos_cinematic_state(BezosCinematicState.VS_SLAM)
		BezosCinematicState.VS_SLAM:
			# VS stays on screen
			if bezos_cinematic_timer >= BEZOS_VS_DURATION:
				_begin_bezos_cinematic_state(BezosCinematicState.FIGHT)
		BezosCinematicState.FIGHT:
			# ROUND 1 holds longer, then FIGHT! has time to land before combat starts.
			if bezos_cinematic_timer >= BEZOS_FIGHT_DURATION:
				_begin_bezos_cinematic_state(BezosCinematicState.COMBAT)
		BezosCinematicState.COMBAT:
			# Fake combat: timer counts down, player HP drains with hit jolts
			var t := bezos_cinematic_timer
			var progress := clampf(t / BEZOS_COMBAT_DURATION, 0.0, 1.0)
			# Timer counts 99 → ~70 during combat
			var timer_val: int = int(lerpf(99.0, 70.0, progress))
			if bezos_cinematic_timer_label:
				bezos_cinematic_timer_label.text = "%02d" % timer_val
			# Player HP drains: 476px → ~120px (takes heavy hits)
			# P2 bar drains SF2-correct: right edge fixed at x=1158, left edge advances right
			if bezos_cinematic_right_hp:
				var base_hp: float = lerpf(476.0, 120.0, progress)
				var hit_cycle := fmod(t, 0.5)
				var jitter := 0.0
				if hit_cycle < 0.08:
					jitter = -35.0  # sudden drop = "hit landed"
				var new_w := maxf(base_hp + jitter, 0.0)
				bezos_cinematic_right_hp.size.x = new_w
				bezos_cinematic_right_hp.position.x = 1158.0 - new_w
			# Bezos HP barely moves (he's untouchable)
			if bezos_cinematic_left_hp:
				bezos_cinematic_left_hp.size.x = lerpf(476.0, 468.0, progress)
			# Hit flash every ~0.5s (offset from jitter)
			var flash_cycle := fmod(t + 0.02, 0.5)
			if flash_cycle < 0.06 and bezos_cinematic_flash:
				bezos_cinematic_flash.visible = true
				# Alternate flash colors: red (player hit) and yellow (blocked)
				var hit_count := int(t / 0.5)
				if hit_count % 2 == 0:
					bezos_cinematic_flash.color = Color(1.0, 0.15, 0.05, 0.45)
				else:
					bezos_cinematic_flash.color = Color(1.0, 0.85, 0.2, 0.3)
			elif bezos_cinematic_flash and bezos_cinematic_flash.color.a > 0.0:
				bezos_cinematic_flash.color.a = maxf(bezos_cinematic_flash.color.a - delta * 6.0, 0.0)
			# Screen shake: offset only the fixed 1280x720 frame
			if bezos_cinematic_frame and fmod(t, 0.5) < 0.12:
				var shake_x := randf_range(-3.0, 3.0)
				var shake_y := randf_range(-2.0, 2.0)
				bezos_cinematic_frame.position = bezos_cinematic_frame_base_position + Vector2(shake_x, shake_y)
			elif bezos_cinematic_frame:
				bezos_cinematic_frame.position = bezos_cinematic_frame_base_position
			# Bottom bar (Prime Membership) also drains slowly
			if bezos_cinematic_frame:
				var bottom_hp := bezos_cinematic_frame.get_node_or_null("BottomBarHP")
				if bottom_hp:
					bottom_hp.size.x = lerpf(476.0, 240.0, progress)
			# Transition to DENIED (the devastating final blow)
			if bezos_cinematic_timer >= BEZOS_COMBAT_DURATION:
				if bezos_cinematic_frame:
					bezos_cinematic_frame.position = bezos_cinematic_frame_base_position
				_begin_bezos_cinematic_state(BezosCinematicState.DENIED)
		BezosCinematicState.DENIED:
			# The fake victory and the corporate denial both need a readable pause.
			if bezos_cinematic_timer >= BEZOS_DENIED_DURATION:
				_begin_bezos_cinematic_state(BezosCinematicState.OUTRO)

func _finish_bezos_cinematic() -> void:
	bezos_cinematic_active = false
	bezos_escalation_active = false
	bezos_escalation_bubble = null
	if bezos_cinematic_layer:
		bezos_cinematic_layer.visible = false
	if bezos_cinematic_root:
		bezos_cinematic_root.modulate.a = 1.0
	if bezos_cinematic_frame:
		bezos_cinematic_frame.position = bezos_cinematic_frame_base_position
	for node in [bezos_cinematic_left_card, bezos_cinematic_right_card,
			bezos_cinematic_left_bar, bezos_cinematic_right_bar,
			bezos_cinematic_left_hp]:
		if node: node.modulate = Color.WHITE
	if bezos_cinematic_left_hp:
		bezos_cinematic_left_hp.size.x = 476.0
	if bezos_cinematic_right_hp:
		bezos_cinematic_right_hp.modulate = Color.WHITE
		bezos_cinematic_right_hp.size.x = 476.0
		bezos_cinematic_right_hp.position.x = 682.0  # reset: right edge back at 1158
		bezos_cinematic_right_hp.visible = true
	if bezos_cinematic_timer_label:
		bezos_cinematic_timer_label.text = "99"
	if bezos_cinematic_speaker:
		bezos_cinematic_speaker.modulate = Color.WHITE
	if bezos_cinematic_dialogue:
		bezos_cinematic_dialogue.modulate = Color.WHITE
	var bottom_hp := bezos_cinematic_frame.get_node_or_null("BottomBarHP") if bezos_cinematic_frame else null
	if bottom_hp:
		bottom_hp.size.x = 476.0
		bottom_hp.visible = true
	for n in ["BottomLabel", "BottomBarBg", "BottomBarHP", "P1Name", "P2Name"]:
		var nd := bezos_cinematic_frame.get_node_or_null(n) if bezos_cinematic_frame else null
		if nd: nd.modulate = Color.WHITE
	player.set_physics_process(true)
	if bezos_drone_root:
		bezos_drone_root.queue_free()
		bezos_drone_root = null
