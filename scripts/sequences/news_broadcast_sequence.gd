extends Node

signal finished

const VIEW_SIZE := Vector2(1280, 720)
const TOTAL_DURATION := 21.5
const BOOT_DURATION := 1.0
const SEGMENT_DURATION := 6.0
const SHUTDOWN_START := 19.0
const SKIP_AVAILABLE_AT := 0.45

const NEWS_SEGMENTS := [
	{
		"title": "WORLD REPORT",
		"channel": "CH 01",
		"time": "03.27.1989  22:41",
		"color": Color("#b51e2e"),
		"headline": "SEVEN WARS. ZERO CEASEFIRES.\nTHREE ARMS MANUFACTURERS REPORT\nRECORD QUARTERLY PROFITS.",
		"ticker": "CEASEFIRE TALKS ADJOURNED FOR CATERING  •  DEFENCE INDEX CLOSES AT RECORD HIGH  •  PEACE DIVIDEND SUBJECT TO REVIEW  •  ",
	},
	{
		"title": "MARKETS UPDATE",
		"channel": "CH 04",
		"time": "03.27.1989  22:47",
		"color": Color("#26734d"),
		"headline": "ARTIFICIAL INTELLIGENCE REPLACES\n800,000 JOBS. INDUSTRY DESCRIBES\nTHE TRANSITION AS HUMAN-CENTERED.",
		"ticker": "EFFICIENCY SAVINGS EXCEED HUMAN REQUIREMENTS  •  PRODUCTIVITY RISES  •  WAGES REMAIN IN BETA  •  ",
	},
	{
		"title": "PUBLIC SERVICE ALERT",
		"channel": "CH 27",
		"time": "03.27.1989  22:54",
		"color": Color("#956418"),
		"headline": "PASSPORT RENEWAL DISTRICT\nOPENS AT DAWN. CITIZENS SHOULD BRING\nPATIENCE AND A ROADWORTHY VEHICLE.",
		"ticker": "FORM A-38 NOW REQUIRES FORM A-38  •  APPOINTMENTS AVAILABLE YESTERDAY  •  CIVIC NIGHTMARE LOADING  •  ",
	},
]

var host: Node
var player: CharacterBody2D
var active := true
var elapsed := 0.0
var current_segment_index := -1
var skip_requested := false

var layer: CanvasLayer
var root_control: Control
var frame: Control
var broadcast_content: Control
var top_bar: ColorRect
var top_title: Label
var headline_label: Label
var ticker_label: Label
var channel_label: Label
var datetime_label: Label
var live_dot: ColorRect
var static_overlay: ColorRect
var boot_line: ColorRect
var shutdown_dot: ColorRect
var skip_hint: Label
var hum_player: AudioStreamPlayer


func setup(owner: Node, player_node: CharacterBody2D) -> void:
	host = owner
	player = player_node
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	_create_broadcast()
	_create_audio()
	active = true
	hum_player.play()


func process_frame(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	if elapsed >= SKIP_AVAILABLE_AT and elapsed < SHUTDOWN_START and (skip_requested or Input.is_action_just_pressed("ui_accept")):
		_finish()
		return
	_update_timeline(delta)
	if elapsed >= TOTAL_DURATION:
		_finish()


func get_duration() -> float:
	return TOTAL_DURATION


func is_skippable() -> bool:
	return true


func request_skip() -> void:
	skip_requested = true


func _create_broadcast() -> void:
	layer = CanvasLayer.new()
	layer.name = "NewsBroadcastLayer"
	layer.layer = 103
	host.add_child(layer)

	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root_control)

	var blackout := ColorRect.new()
	blackout.set_anchors_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color("#02030a")
	root_control.add_child(blackout)

	frame = Control.new()
	frame.size = VIEW_SIZE
	frame.clip_contents = true
	root_control.add_child(frame)
	root_control.resized.connect(_layout_frame)

	broadcast_content = Control.new()
	broadcast_content.name = "BroadcastContent"
	broadcast_content.size = VIEW_SIZE
	frame.add_child(broadcast_content)

	var signal_field := ColorRect.new()
	signal_field.position = Vector2(0, 0)
	signal_field.size = VIEW_SIZE
	var signal_material := ShaderMaterial.new()
	var signal_shader := Shader.new()
	signal_shader.code = """
shader_type canvas_item;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	float band = sin(uv.y * 34.0 + TIME * 0.7) * 0.5 + 0.5;
	float noise = hash(floor(uv * vec2(180.0, 100.0)) + floor(TIME * 12.0));
	vec3 deep = vec3(0.018, 0.028, 0.082);
	vec3 cold = vec3(0.035, 0.11, 0.18);
	vec3 col = mix(deep, cold, uv.y * 0.55 + band * 0.08);
	col += noise * 0.018;
	COLOR = vec4(col, 1.0);
}
"""
	signal_material.shader = signal_shader
	signal_field.material = signal_material
	broadcast_content.add_child(signal_field)

	var footage_frame := Panel.new()
	footage_frame.position = Vector2(96, 126)
	footage_frame.size = Vector2(1088, 430)
	footage_frame.add_theme_stylebox_override("panel", _panel_style(Color("#d5d9df"), Color(0.015, 0.025, 0.065, 0.86), 3))
	broadcast_content.add_child(footage_frame)

	var footage_caption := Label.new()
	footage_caption.position = Vector2(20, 14)
	footage_caption.size = Vector2(1048, 32)
	footage_caption.text = "CIVIC NIGHTMARE NEWS NETWORK // VERIFIED UNTIL CORRECTED"
	footage_caption.add_theme_font_size_override("font_size", 14)
	footage_caption.add_theme_color_override("font_color", Color("#8896ad"))
	footage_frame.add_child(footage_caption)

	var horizon := Polygon2D.new()
	horizon.polygon = PackedVector2Array([
		Vector2(40, 350), Vector2(40, 252), Vector2(120, 252), Vector2(120, 211),
		Vector2(184, 211), Vector2(184, 278), Vector2(258, 278), Vector2(258, 185),
		Vector2(330, 185), Vector2(330, 236), Vector2(405, 236), Vector2(405, 150),
		Vector2(490, 150), Vector2(490, 226), Vector2(564, 226), Vector2(564, 174),
		Vector2(646, 174), Vector2(646, 258), Vector2(720, 258), Vector2(720, 202),
		Vector2(800, 202), Vector2(800, 275), Vector2(884, 275), Vector2(884, 230),
		Vector2(970, 230), Vector2(970, 350),
	])
	horizon.color = Color(0.01, 0.018, 0.04, 0.82)
	horizon.position = Vector2(40, 48)
	footage_frame.add_child(horizon)

	headline_label = Label.new()
	headline_label.position = Vector2(54, 85)
	headline_label.size = Vector2(980, 250)
	headline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	headline_label.add_theme_font_size_override("font_size", 31)
	headline_label.add_theme_color_override("font_color", Color("#f4f2e9"))
	headline_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	headline_label.add_theme_constant_override("shadow_offset_x", 3)
	headline_label.add_theme_constant_override("shadow_offset_y", 3)
	footage_frame.add_child(headline_label)

	top_bar = ColorRect.new()
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(1280, 64)
	broadcast_content.add_child(top_bar)
	top_title = _make_label(Vector2(28, 8), Vector2(760, 48), 26, Color.WHITE)
	top_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(top_title)

	var network_box := ColorRect.new()
	network_box.position = Vector2(1080, 64)
	network_box.size = Vector2(176, 54)
	network_box.color = Color("#b51525")
	broadcast_content.add_child(network_box)
	var network_label := _make_label(Vector2.ZERO, network_box.size, 29, Color.WHITE)
	network_label.text = "CN"
	network_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	network_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	network_box.add_child(network_label)

	channel_label = _make_label(Vector2(988, 76), Vector2(80, 28), 14, Color("#9aa4b4"))
	channel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	broadcast_content.add_child(channel_label)
	datetime_label = _make_label(Vector2(24, 80), Vector2(280, 28), 13, Color("#9aa4b4"))
	broadcast_content.add_child(datetime_label)

	live_dot = ColorRect.new()
	live_dot.position = Vector2(316, 86)
	live_dot.size = Vector2(10, 10)
	live_dot.color = Color("#ff3347")
	broadcast_content.add_child(live_dot)
	var live_label := _make_label(Vector2(334, 77), Vector2(80, 28), 14, Color("#ff6070"))
	live_label.text = "LIVE"
	broadcast_content.add_child(live_label)

	var lower_strip := ColorRect.new()
	lower_strip.position = Vector2(0, 590)
	lower_strip.size = Vector2(1280, 42)
	lower_strip.color = Color("#143d78")
	broadcast_content.add_child(lower_strip)
	var network_name := _make_label(Vector2(22, 4), Vector2(600, 34), 16, Color.WHITE)
	network_name.text = "CN // NEWS BEFORE IT BECOMES HISTORY"
	network_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lower_strip.add_child(network_name)

	var ticker_bar := ColorRect.new()
	ticker_bar.position = Vector2(0, 632)
	ticker_bar.size = Vector2(1280, 48)
	ticker_bar.color = Color("#f3f0e4")
	broadcast_content.add_child(ticker_bar)
	var ticker_badge := ColorRect.new()
	ticker_badge.position = Vector2.ZERO
	ticker_badge.size = Vector2(158, 48)
	ticker_badge.color = Color("#b51525")
	ticker_bar.add_child(ticker_badge)
	var ticker_badge_label := _make_label(Vector2.ZERO, ticker_badge.size, 17, Color.WHITE)
	ticker_badge_label.text = "BREAKING"
	ticker_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ticker_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ticker_badge.add_child(ticker_badge_label)
	ticker_label = _make_label(Vector2(190, 6), Vector2(1700, 36), 17, Color("#63121d"))
	ticker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ticker_bar.add_child(ticker_label)

	skip_hint = _make_label(Vector2(1002, 687), Vector2(250, 25), 13, Color("#8b91a0"))
	skip_hint.text = "SPACE — SKIP BROADCAST"
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	frame.add_child(skip_hint)

	static_overlay = ColorRect.new()
	static_overlay.position = Vector2.ZERO
	static_overlay.size = VIEW_SIZE
	static_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var static_material := ShaderMaterial.new()
	var static_shader := Shader.new()
	static_shader.code = """
shader_type canvas_item;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float n = hash(floor(FRAGCOORD.xy * 0.55) + floor(TIME * 80.0));
	float tear = smoothstep(0.0, 0.018, abs(UV.y - fract(TIME * 0.37)));
	COLOR = vec4(vec3(n * 0.92), (0.72 + (1.0 - tear) * 0.2));
}
"""
	static_material.shader = static_shader
	static_overlay.material = static_material
	static_overlay.visible = false
	frame.add_child(static_overlay)

	var scanlines := ColorRect.new()
	scanlines.position = Vector2.ZERO
	scanlines.size = VIEW_SIZE
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scan_material := ShaderMaterial.new()
	var scan_shader := Shader.new()
	scan_shader.code = """
shader_type canvas_item;
void fragment() {
	float scan = step(2.0, mod(FRAGCOORD.y, 4.0)) * 0.085;
	float vignette = smoothstep(0.72, 1.12, length(SCREEN_UV - vec2(0.5)) * 1.48);
	COLOR = vec4(0.0, 0.005, 0.02, scan + vignette * 0.36);
}
"""
	scan_material.shader = scan_shader
	scanlines.material = scan_material
	frame.add_child(scanlines)

	boot_line = ColorRect.new()
	boot_line.color = Color("#e8f1ff")
	boot_line.position = Vector2(640, 359)
	boot_line.size = Vector2.ZERO
	frame.add_child(boot_line)
	shutdown_dot = ColorRect.new()
	shutdown_dot.color = Color("#e8f1ff")
	shutdown_dot.position = Vector2(637, 357)
	shutdown_dot.size = Vector2(6, 6)
	shutdown_dot.visible = false
	frame.add_child(shutdown_dot)

	broadcast_content.visible = false
	skip_hint.visible = false
	_layout_frame()


func _create_audio() -> void:
	hum_player = AudioStreamPlayer.new()
	hum_player.name = "BroadcastSignalHum"
	hum_player.stream = _make_broadcast_stream()
	hum_player.volume_db = -25.0
	add_child(hum_player)


func _update_timeline(delta: float) -> void:
	if elapsed < BOOT_DURATION:
		broadcast_content.visible = false
		skip_hint.visible = elapsed >= SKIP_AVAILABLE_AT
		boot_line.visible = true
		var boot_progress := clampf(elapsed / BOOT_DURATION, 0.0, 1.0)
		boot_line.position = Vector2(640.0 - 520.0 * boot_progress, 358.0 - boot_progress * 356.0)
		boot_line.size = Vector2(1040.0 * boot_progress, 2.0 + boot_progress * 712.0)
		boot_line.modulate.a = 0.72 + sin(elapsed * 44.0) * 0.24
		return

	boot_line.visible = false
	if elapsed < SHUTDOWN_START:
		broadcast_content.visible = true
		broadcast_content.modulate.a = 1.0
		skip_hint.visible = true
		var segment_index := mini(int((elapsed - BOOT_DURATION) / SEGMENT_DURATION), NEWS_SEGMENTS.size() - 1)
		if segment_index != current_segment_index:
			_apply_segment(segment_index)
		var local_time := fposmod(elapsed - BOOT_DURATION, SEGMENT_DURATION)
		static_overlay.visible = local_time < 0.24
		if static_overlay.visible:
			static_overlay.modulate.a = 1.0 - local_time / 0.24
		var headline := str(NEWS_SEGMENTS[segment_index]["headline"])
		var visible_characters := mini(headline.length(), int(maxf(0.0, local_time - 0.22) * 58.0))
		headline_label.text = headline.substr(0, visible_characters)
		ticker_label.position.x -= delta * 142.0
		if ticker_label.position.x + ticker_label.size.x < 160.0:
			ticker_label.position.x = 190.0
		live_dot.modulate.a = 0.35 + (sin(elapsed * 7.0) * 0.5 + 0.5) * 0.65
		return

	static_overlay.visible = false
	skip_hint.visible = false
	var shutdown_progress := clampf((elapsed - SHUTDOWN_START) / (TOTAL_DURATION - SHUTDOWN_START), 0.0, 1.0)
	broadcast_content.modulate.a = maxf(0.0, 1.0 - shutdown_progress * 2.4)
	if shutdown_progress < 0.55:
		boot_line.visible = true
		var crush := shutdown_progress / 0.55
		boot_line.position = Vector2(120.0 + 510.0 * crush, 2.0 + 356.0 * crush)
		boot_line.size = Vector2(1040.0 * (1.0 - crush), 716.0 * (1.0 - crush) + 2.0)
	else:
		boot_line.visible = false
		shutdown_dot.visible = true
		shutdown_dot.modulate.a = 1.0 - (shutdown_progress - 0.55) / 0.45


func _apply_segment(index: int) -> void:
	current_segment_index = index
	var segment: Dictionary = NEWS_SEGMENTS[index]
	top_bar.color = segment["color"]
	top_title.text = str(segment["title"])
	channel_label.text = str(segment["channel"])
	datetime_label.text = str(segment["time"])
	ticker_label.text = str(segment["ticker"])
	ticker_label.position.x = 190.0
	headline_label.text = ""


func _make_label(position_value: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position_value
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _panel_style(border: Color, fill: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	return style


func _make_broadcast_stream() -> AudioStreamWAV:
	var sample_rate := 11025
	var sample_count := sample_rate
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for index in range(sample_count):
		var time := float(index) / float(sample_rate)
		var hum := sin(TAU * 59.0 * time) * 0.12 + sin(TAU * 118.0 * time) * 0.045
		var carrier := sin(TAU * 1760.0 * time + sin(TAU * 3.0 * time)) * 0.018
		var sample := clampf(hum + carrier, -1.0, 1.0)
		bytes[index] = int(clampf(128.0 + sample * 92.0, 0.0, 255.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = bytes
	return stream


func _layout_frame() -> void:
	if not root_control or not frame:
		return
	var viewport_size := root_control.size
	var scale_factor := minf(viewport_size.x / VIEW_SIZE.x, viewport_size.y / VIEW_SIZE.y)
	frame.scale = Vector2.ONE * scale_factor
	frame.position = (viewport_size - VIEW_SIZE * scale_factor) * 0.5


func _finish() -> void:
	if not active:
		return
	active = false
	if hum_player:
		hum_player.stop()
	if layer:
		layer.queue_free()
		layer = null
	finished.emit()
