extends Node

signal final_mission_requested
signal postgame_requested

var host: Node
var ending_active: bool = false
var ending_layer: CanvasLayer
var ending_bg: ColorRect
var ending_text: Label
var ending_timer: float = 0.0
var ending_phase: int = 0
var ending_char_index: int = 0
var ending_current_text: String = ""
var ending_full_text: String = ""
var final_mission_done: bool = false
var postgame_free_roam_started: bool = false

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


func setup(owner: Node) -> void:
	host = owner
	_create_overlay()


func _create_overlay() -> void:
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

	host.add_child(ending_layer)

func start(final_mission_complete: bool) -> void:
	if ending_active:
		return
	ending_active = true
	ending_phase = 0
	ending_timer = 0.0
	ending_char_index = 0
	final_mission_done = final_mission_complete
	postgame_free_roam_started = false

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

func process_frame(delta: float) -> void:
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
			ending_timer = ENDING_HOLD_TIME * (1.8 if final_mission_done else 1.0)
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
			var hold_time := ENDING_HOLD_TIME * (1.8 if final_mission_done else 1.0)
			if ending_timer >= hold_time:
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

		4:  # DONE — hold final screen then either trigger final mission or wait for quit
			ending_timer += delta
			if final_mission_done:
				# True ending — dissolve back into free roam with one last AI line.
				if ending_timer >= 4.0:
					ending_text.modulate.a = max(0.0, 1.0 - (ending_timer - 4.0) / 1.6)
				if ending_timer >= 5.8 and not postgame_free_roam_started:
					postgame_free_roam_started = true
					postgame_requested.emit()
			else:
				# First ending — fade then trigger final mission
				if ending_timer >= 4.0:
					ending_text.modulate.a = max(0.0, 1.0 - (ending_timer - 4.0) / 2.0)
				if ending_timer >= 6.0:
					ending_active = false
					ending_layer.visible = false
					final_mission_requested.emit()
