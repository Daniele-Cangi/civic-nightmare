extends Node

var host: Node
var player: CharacterBody2D
var active: bool = true

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

func setup(owner: Node, player_node: CharacterBody2D) -> void:
	host = owner
	player = player_node
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

	host.add_child(intro_layer)

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

func process_frame(delta: float) -> void:
	# Skip on Space/Enter (but not during boot or shutdown)
	if intro_state >= 0 and intro_state < 3:
		if Input.is_action_just_pressed("ui_accept"):
			intro_skip_held += 1.0
		if intro_skip_held > 0.0:
			_finish()
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
				_finish()

func _finish() -> void:
	active = false
	if intro_layer:
		intro_layer.queue_free()
		intro_layer = null
	player.set_physics_process(true)
