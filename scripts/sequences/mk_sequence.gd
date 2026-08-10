extends Node

signal finished

var host: Node
var player: CharacterBody2D
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


func setup(owner: Node, player_node: CharacterBody2D) -> void:
	host = owner
	player = player_node
	_create_overlay()


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

func _create_overlay() -> void:
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

	host.add_child(mk_layer)

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

func start() -> void:
	if not mk_layer:
		_create_overlay()
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

func process_frame(delta: float) -> void:
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
				tw_fade.tween_callback(_complete)

		MKState.FADE_OUT:
			pass


func _complete() -> void:
	mk_sequence_active = false
	mk_layer.visible = false
	mk_layer.modulate.a = 1.0
	finished.emit()
