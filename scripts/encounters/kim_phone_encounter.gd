extends Node

const LINE_SHOW := 4
const LINE_LINE2 := 13
const LINE_LINE3 := 21
const LINE_SETTLE := 29

var host: Node
var active: bool = false
var kim_phone_layer: CanvasLayer
var kim_phone_panel: Control
var kim_phone_dot1: ColorRect
var kim_phone_dot2: ColorRect
var kim_phone_dot3: ColorRect
var kim_phone_row2: Control
var kim_phone_row3: Control
var kim_phone_base_pos: Vector2 = Vector2.ZERO
var kim_phone_blink_t: float = 0.0
var kim_phone_intensity: float = 0.0
var kim_phone_ringing: bool = false

func start(owner: Node) -> void:
	host = owner
	if kim_phone_layer and is_instance_valid(kim_phone_layer):
		return
	kim_phone_layer = CanvasLayer.new()
	kim_phone_layer.layer = 8
	kim_phone_layer.name = "KimPhoneLayer"
	host.add_child(kim_phone_layer)

	var panel := Control.new()
	panel.name = "KimPhonePanel"
	panel.custom_minimum_size = Vector2(236, 122)
	panel.position = Vector2(1040, 345)
	kim_phone_base_pos = panel.position
	kim_phone_panel = panel

	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.09, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)

	var title_bar := ColorRect.new()
	title_bar.color = Color(0.72, 0.0, 0.0)
	title_bar.position = Vector2(0, 0)
	title_bar.size = Vector2(236, 28)
	panel.add_child(title_bar)

	var title_lbl := Label.new()
	title_lbl.text = "  RED PHONE — INCOMING"
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.position = Vector2(0, 5)
	title_lbl.size = Vector2(236, 22)
	panel.add_child(title_lbl)

	kim_phone_dot1 = _make_kim_phone_row(panel, 36.0, "LINE 1  —  MOSCOW")
	var row2 := _make_kim_phone_row_container(panel, 62.0)
	kim_phone_row2 = row2
	kim_phone_dot2 = _fill_kim_phone_row(row2, "LINE 2  —  TEHRAN")
	var row3 := _make_kim_phone_row_container(panel, 88.0)
	kim_phone_row3 = row3
	kim_phone_dot3 = _fill_kim_phone_row(row3, "LINE 3  —  STOCKHOLM")

	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	kim_phone_layer.add_child(panel)
	active = true
	kim_phone_blink_t = 0.0
	kim_phone_intensity = 0.0
	kim_phone_ringing = false

func _make_kim_phone_row(parent: Control, y: float, text: String) -> ColorRect:
	var row := _make_kim_phone_row_container(parent, y)
	return _fill_kim_phone_row(row, text)

func _make_kim_phone_row_container(parent: Control, y: float) -> Control:
	var row := Control.new()
	row.position = Vector2(0.0, y)
	row.size = Vector2(236.0, 26.0)
	row.visible = false
	parent.add_child(row)
	return row

func _fill_kim_phone_row(row: Control, text: String) -> ColorRect:
	var dot := ColorRect.new()
	dot.color = Color(1.0, 0.1, 0.1)
	dot.position = Vector2(10.0, 9.0)
	dot.size = Vector2(8.0, 8.0)
	row.add_child(dot)
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(26.0, 3.0)
	lbl.size = Vector2(206.0, 20.0)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	row.add_child(lbl)
	return dot

func update_for_line(idx: int) -> void:
	if not active or not kim_phone_panel or not is_instance_valid(kim_phone_panel):
		return
	if idx == LINE_SHOW:
		# Slide in from right
		kim_phone_panel.position = kim_phone_base_pos + Vector2(240.0, 0.0)
		if kim_phone_row2:
			kim_phone_row2.visible = false
		if kim_phone_row3:
			kim_phone_row3.visible = false
		if kim_phone_dot1:
			kim_phone_dot1.modulate.a = 1.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(kim_phone_panel, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_property(kim_phone_panel, "position:x", kim_phone_base_pos.x, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		kim_phone_ringing = true
		kim_phone_intensity = 1.0
	elif idx == LINE_LINE2:
		if kim_phone_row2:
			kim_phone_row2.visible = true
		kim_phone_intensity = 2.0
	elif idx == LINE_LINE3:
		if kim_phone_row3:
			kim_phone_row3.visible = true
		kim_phone_intensity = 3.2
	elif idx == LINE_SETTLE:
		kim_phone_ringing = false
		kim_phone_intensity = 0.0
		kim_phone_panel.position = kim_phone_base_pos
		var settled_color := Color(0.1, 0.55, 0.1)
		if kim_phone_dot1:
			kim_phone_dot1.color = settled_color
		if kim_phone_dot2:
			kim_phone_dot2.color = settled_color
		if kim_phone_dot3:
			kim_phone_dot3.color = settled_color

func stop() -> void:
	if not kim_phone_layer or not is_instance_valid(kim_phone_layer):
		active = false
		return
	var tw := create_tween()
	tw.tween_property(kim_phone_panel, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		if kim_phone_layer and is_instance_valid(kim_phone_layer):
			kim_phone_layer.queue_free()
		kim_phone_layer = null
		kim_phone_panel = null
		kim_phone_dot1 = null
		kim_phone_dot2 = null
		kim_phone_dot3 = null
		kim_phone_row2 = null
		kim_phone_row3 = null
		active = false
	)

func process_frame(delta: float) -> void:
	if not kim_phone_panel or not is_instance_valid(kim_phone_panel):
		return
	kim_phone_blink_t += delta
	var blink_speed := 6.0 + kim_phone_intensity * 2.5
	var b1 := fmod(kim_phone_blink_t * blink_speed, 1.0) < 0.5
	var b2 := fmod((kim_phone_blink_t + 0.18) * blink_speed, 1.0) < 0.5
	var b3 := fmod((kim_phone_blink_t + 0.36) * blink_speed, 1.0) < 0.5
	var red_on  := Color(1.0, 0.1, 0.1)
	var red_off := Color(0.22, 0.0, 0.0)
	if kim_phone_ringing:
		if kim_phone_dot1:
			kim_phone_dot1.color = red_on if b1 else red_off
		if kim_phone_dot2 and kim_phone_row2 and kim_phone_row2.visible:
			kim_phone_dot2.color = red_on if b2 else red_off
		if kim_phone_dot3 and kim_phone_row3 and kim_phone_row3.visible:
			kim_phone_dot3.color = red_on if b3 else red_off
		if kim_phone_intensity > 0.0:
			var sx := sin(kim_phone_blink_t * 24.0) * kim_phone_intensity * 1.1
			var sy := cos(kim_phone_blink_t * 19.0) * kim_phone_intensity * 0.55
			kim_phone_panel.position = kim_phone_base_pos + Vector2(sx, sy)
