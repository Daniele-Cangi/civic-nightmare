extends Node

signal finished

const BEZOS_BATTLE_STAGE_SCRIPT = preload("res://scripts/encounters/bezos_battle_stage.gd")

var host: Node
var player: CharacterBody2D
var combat_portrait_paths: Dictionary
var character_colors: Dictionary
var dossier_manager: Node
var battle_stage: Control
var battle_result: Dictionary = {}

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
const BEZOS_ERROR_POPUPS := [
	["PRIME AUTO-RENEWAL NOTICE",
	 "Your card has been charged $14.99.\nYour refusal to consent has been noted.\nThis incident has been flagged."],
	["TERMS OF SERVICE §47 — EXISTENCE CLAUSE",
	 "By breathing within 8m of this drone\nyou agree to Clauses 47–891 incl.\n[  OK  ]   [  OK IN YELLOW  ]"],
	["WORKER EFFICIENCY ALERT™",
	 "A nearby human scored 0.3% below quota.\nAutomated reprimand issued (4th this week).\nHave a productive and Prime day!"],
	["DISPUTE RESOLUTION COMPLETE",
	 "Your complaint has been auto-dismissed.\nCase ID: 00000000000. Review: NEVER.\nThank you for choosing Amazon."],
]
const BEZOS_STAGE_DURATION := 2.0
const BEZOS_SLIDE_IN_DURATION := 2.1
const BEZOS_VS_DURATION := 2.0
const BEZOS_FIGHT_DURATION := 4.2
const BEZOS_DENIED_DURATION := 13.2
const BEZOS_ROUND_HOLD := 1.9
const BEZOS_KO_DELAY := 0.9
const BEZOS_PERFECT_DELAY := 1.6
const BEZOS_DENIAL_REVEAL_DELAY := 1.9
const BEZOS_SUBTITLE_REVEAL_DELAY := 1.6


func setup(owner: Node, player_node: CharacterBody2D, portrait_paths: Dictionary, colors: Dictionary, dossier: Node = null) -> void:
	host = owner
	player = player_node
	combat_portrait_paths = portrait_paths
	character_colors = colors
	dossier_manager = dossier
	_create_overlay()


func start() -> void:
	bezos_cinematic_seen = true
	bezos_cinematic_active = true
	battle_result.clear()
	if bezos_cinematic_layer:
		bezos_cinematic_layer.visible = true
		if bezos_cinematic_root:
			bezos_cinematic_root.modulate.a = 1.0
		_layout_bezos_cinematic_frame()
		_begin_bezos_cinematic_state(BezosCinematicState.STAGE)


func _create_overlay() -> void:
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
	bezos_cinematic_scanlines.z_index = 100
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

	battle_stage = BEZOS_BATTLE_STAGE_SCRIPT.new()
	battle_stage.name = "PlayableBattleStage"
	bezos_cinematic_frame.add_child(battle_stage)
	battle_stage.call("setup")
	battle_stage.connect("telemetry_changed", _on_battle_telemetry_changed)
	battle_stage.connect("resolved", _on_battle_resolved)

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
		"res://assets/mockups/bezos_portrait.png")
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

	# ═══ Amazon error popup (shown during combat) ═══
	var err_popup := Control.new()
	err_popup.name = "ErrorPopup"
	err_popup.size = Vector2(360, 156)
	err_popup.visible = false
	err_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bezos_cinematic_frame.add_child(err_popup)

	var ep_bg := ColorRect.new()
	ep_bg.color = Color(0.93, 0.93, 0.91)
	ep_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ep_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	err_popup.add_child(ep_bg)

	var ep_border := StyleBoxFlat.new()
	ep_border.border_color = Color(0.55, 0.55, 0.52)
	ep_border.border_width_left = 2
	ep_border.border_width_top = 2
	ep_border.border_width_right = 2
	ep_border.border_width_bottom = 2
	ep_border.bg_color = Color(0, 0, 0, 0)
	var ep_border_rect := PanelContainer.new()
	ep_border_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	ep_border_rect.add_theme_stylebox_override("panel", ep_border)
	ep_border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	err_popup.add_child(ep_border_rect)

	var ep_titlebar := ColorRect.new()
	ep_titlebar.name = "TitleBar"
	ep_titlebar.color = Color(1.0, 0.60, 0.0)  # Amazon orange
	ep_titlebar.position = Vector2(2, 2)
	ep_titlebar.size = Vector2(356, 28)
	ep_titlebar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	err_popup.add_child(ep_titlebar)

	var ep_icon := Label.new()
	ep_icon.text = "⚠"
	ep_icon.position = Vector2(4, 2)
	ep_icon.add_theme_font_size_override("font_size", 15)
	ep_icon.add_theme_color_override("font_color", Color.WHITE)
	ep_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ep_titlebar.add_child(ep_icon)

	var ep_title := Label.new()
	ep_title.name = "PopupTitle"
	ep_title.text = "AMAZON ERROR"
	ep_title.position = Vector2(26, 4)
	ep_title.add_theme_font_size_override("font_size", 13)
	ep_title.add_theme_color_override("font_color", Color.WHITE)
	ep_title.add_theme_color_override("font_shadow_color", Color(0.3, 0.0, 0.0, 0.6))
	ep_title.add_theme_constant_override("shadow_offset_x", 1)
	ep_title.add_theme_constant_override("shadow_offset_y", 1)
	ep_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ep_titlebar.add_child(ep_title)

	var ep_close := Label.new()
	ep_close.text = "✕"
	ep_close.position = Vector2(334, 4)
	ep_close.add_theme_font_size_override("font_size", 13)
	ep_close.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	ep_close.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ep_titlebar.add_child(ep_close)

	var ep_msg := Label.new()
	ep_msg.name = "PopupMsg"
	ep_msg.text = ""
	ep_msg.position = Vector2(14, 38)
	ep_msg.size = Vector2(332, 88)
	ep_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ep_msg.add_theme_font_size_override("font_size", 13)
	ep_msg.add_theme_color_override("font_color", Color(0.12, 0.12, 0.12))
	ep_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	err_popup.add_child(ep_msg)

	var ep_ok_bg := ColorRect.new()
	ep_ok_bg.name = "OkBg"
	ep_ok_bg.color = Color(0.80, 0.80, 0.78)
	ep_ok_bg.position = Vector2(138, 126)
	ep_ok_bg.size = Vector2(84, 22)
	ep_ok_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	err_popup.add_child(ep_ok_bg)

	var ep_ok_lbl := Label.new()
	ep_ok_lbl.text = "    OK    "
	ep_ok_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep_ok_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ep_ok_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ep_ok_lbl.add_theme_font_size_override("font_size", 12)
	ep_ok_lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	ep_ok_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ep_ok_bg.add_child(ep_ok_lbl)

	host.add_child(bezos_cinematic_layer)
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
	if battle_stage:
		battle_stage.call("stop")
	for node in [bezos_cinematic_stage, bezos_cinematic_vs, bezos_cinematic_round,
			bezos_cinematic_fight, bezos_cinematic_ko, bezos_cinematic_perfect,
			bezos_cinematic_denial, bezos_cinematic_subtitle, bezos_cinematic_flash,
			bezos_cinematic_left_bar, bezos_cinematic_right_bar,
			bezos_cinematic_left_hp, bezos_cinematic_right_hp,
			bezos_cinematic_left_card, bezos_cinematic_right_card,
			bezos_cinematic_speaker, bezos_cinematic_dialogue,
			bezos_cinematic_timer_label]:
		if node: node.visible = false
	for n in ["P1Name", "P2Name", "BottomLabel", "BottomBarBg", "BottomBarHP", "ErrorPopup"]:
		var nd := bezos_cinematic_frame.get_node_or_null(n) if bezos_cinematic_frame else null
		if nd: nd.visible = false

func _show_bezos_error_popup(popup_index: int, pos: Vector2) -> void:
	if not bezos_cinematic_frame: return
	var popup := bezos_cinematic_frame.get_node_or_null("ErrorPopup")
	if not popup: return
	var data: Array = BEZOS_ERROR_POPUPS[popup_index % BEZOS_ERROR_POPUPS.size()]
	var title_lbl := popup.get_node_or_null("TitleBar/PopupTitle") as Label
	var msg_lbl := popup.get_node_or_null("PopupMsg") as Label
	if title_lbl: title_lbl.text = data[0]
	if msg_lbl: msg_lbl.text = data[1]
	popup.position = pos
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.85, 0.85)
	popup.pivot_offset = Vector2(180, 78)
	popup.visible = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(popup, "modulate:a", 1.0, 0.18)
	tw.tween_property(popup, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Auto-dismiss after 2.4s
	tw.tween_interval(2.4)
	tw.set_parallel(false)
	tw.tween_property(popup, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): if popup: popup.visible = false)

func _bezos_show_hud() -> void:
	for node in [bezos_cinematic_left_bar, bezos_cinematic_right_bar,
			bezos_cinematic_left_hp, bezos_cinematic_right_hp,
			bezos_cinematic_timer_label]:
		if node: node.visible = true
	for n in ["P1Name", "P2Name", "BottomLabel", "BottomBarBg", "BottomBarHP"]:
		var nd := bezos_cinematic_frame.get_node_or_null(n) if bezos_cinematic_frame else null
		if nd: nd.visible = true


func _bezos_show_combat_hud() -> void:
	_bezos_show_hud()
	bezos_cinematic_timer_label.visible = false
	for node_name in ["P1Name", "P2Name", "BottomLabel"]:
		var node := bezos_cinematic_frame.get_node_or_null(node_name) if bezos_cinematic_frame else null
		if node:
			node.visible = false

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
			bezos_cinematic_stage.visible = false
			bezos_cinematic_fight.visible = false
			_bezos_show_combat_hud()
			bezos_cinematic_flash.visible = true
			bezos_cinematic_flash.color = Color(1.0, 0.85, 0.2, 0.6)
			var tw_combat := create_tween()
			tw_combat.tween_property(bezos_cinematic_flash, "color:a", 0.0, 0.15)
			if battle_stage:
				battle_stage.modulate = Color.WHITE
				battle_stage.call("start")

		BezosCinematicState.DENIED:
			bezos_cinematic_fight.visible = false
			var citizen_won := str(battle_result.get("outcome", "")) == "citizen_victory"
			bezos_cinematic_perfect.text = "CITIZEN WINS" if citizen_won else "PERFECT"
			bezos_cinematic_denial.text = (
				"RESULT NOT RECOGNIZED\nBY TERMS OF SERVICE"
				if citizen_won
				else "DISPUTE RESOLVED\nBY TERMS OF SERVICE"
			)
			bezos_cinematic_subtitle.text = (
				"Physical victory is not an accepted refund method.\nYour successful objection has been converted into account activity.\nEstimated recognition time: 4,700 years."
				if citizen_won
				else "Physical conflict has been replaced by fulfillment arbitration.\nYour complaint has been added to the queue.\nEstimated wait: 4,700 years."
			)
			# Flash = instant KO
			bezos_cinematic_flash.visible = true
			bezos_cinematic_flash.color = Color(1, 1, 1, 1.0)
			var tw6 := create_tween()
			tw6.tween_property(bezos_cinematic_flash, "color:a", 0.0, 0.55)
			# The mechanically defeated fighter drains here; the verdict follows later.
			if citizen_won:
				tw6.parallel().tween_property(bezos_cinematic_left_hp, "size:x", 0.0, 0.75).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			else:
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
			# Corporate software opens only after the physical result exists.
			tw6.tween_interval(0.5)
			tw6.tween_callback(func(): _show_bezos_error_popup(1 if citizen_won else 3, Vector2(460, 200)))
			# Pause, then dim + show denial
			tw6.tween_interval(BEZOS_DENIAL_REVEAL_DELAY - 0.5)
			tw6.tween_callback(func():
				if battle_stage:
					battle_stage.modulate.a = 0.24
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

func process_frame(delta: float) -> void:
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
			if battle_stage:
				battle_stage.call("process_frame", delta)
		BezosCinematicState.DENIED:
			# The fake victory and the corporate denial both need a readable pause.
			if bezos_cinematic_timer >= BEZOS_DENIED_DURATION:
				_begin_bezos_cinematic_state(BezosCinematicState.OUTRO)


func _on_battle_telemetry_changed(citizen_hp: float, bezos_hp: float, legal_shield: float, seconds_left: int) -> void:
	var citizen_max := 100.0
	var bezos_max := 32.0
	var shield_max := 16.0
	if battle_stage:
		var maxima: Dictionary = battle_stage.call("get_round_maxima")
		citizen_max = float(maxima.get("citizen_hp", citizen_max))
		bezos_max = float(maxima.get("bezos_hp", bezos_max))
		shield_max = float(maxima.get("legal_shield", shield_max))
	if bezos_cinematic_left_hp:
		bezos_cinematic_left_hp.size.x = 476.0 * clampf(bezos_hp / bezos_max, 0.0, 1.0)
	if bezos_cinematic_right_hp:
		var citizen_width := 476.0 * clampf(citizen_hp / citizen_max, 0.0, 1.0)
		bezos_cinematic_right_hp.size.x = citizen_width
		bezos_cinematic_right_hp.position.x = 1158.0 - citizen_width
	if bezos_cinematic_timer_label:
		bezos_cinematic_timer_label.text = "%02d" % seconds_left
	var bottom_hp := bezos_cinematic_frame.get_node_or_null("BottomBarHP") if bezos_cinematic_frame else null
	if bottom_hp:
		bottom_hp.size.x = 476.0 * clampf(legal_shield / shield_max, 0.0, 1.0)


func _on_battle_resolved(result: Dictionary) -> void:
	if bezos_cinematic_state != BezosCinematicState.COMBAT:
		return
	battle_result = result.duplicate(true)
	if dossier_manager:
		battle_result["profile_was_known"] = bool(dossier_manager.get("profile_discovered"))
		var outcome := str(battle_result.get("outcome", "administrative_defeat"))
		var tag := "physical-remedy-invalidated" if outcome == "citizen_victory" else "automated-dispute-endured"
		var note := (
			"Subject obtained a physical victory. Contractual recognition was withheld."
			if outcome == "citizen_victory"
			else "Subject remained in an automated dispute until the system declared resolution."
		)
		if dossier_manager.has_method("record_contest"):
			dossier_manager.call(
				"record_contest",
				"contest:bezos_fulfillment",
				"jeff_bezos",
				tag,
				note,
				battle_result
			)
	_begin_bezos_cinematic_state(BezosCinematicState.DENIED)

func _finish_bezos_cinematic() -> void:
	bezos_cinematic_active = false
	if battle_stage:
		battle_stage.call("stop")
		battle_stage.modulate = Color.WHITE
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
	finished.emit()
