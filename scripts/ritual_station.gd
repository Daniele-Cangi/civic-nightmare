extends StaticBody2D

@export var station_id: String = ""
@export var station_name: String = "Station"
@export var station_visual: String = "kiosk"
@export var accent_color: Color = Color(0.86, 0.72, 0.32)

var room_ref: Node = null
var player_ref: CharacterBody2D = null
var indicator_label: Label
var interaction_enabled := true
var completed := false
var pulse_time := 0.0

const INTERACT_DISTANCE := 72.0

func _ready() -> void:
	_create_indicator()
	call_deferred("_find_player")
	queue_redraw()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _create_indicator() -> void:
	indicator_label = Label.new()
	indicator_label.text = "!"
	indicator_label.add_theme_font_size_override("font_size", 20)
	indicator_label.add_theme_color_override("font_color", accent_color.lightened(0.2))
	indicator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicator_label.position = Vector2(-8, -66)
	indicator_label.visible = false
	indicator_label.z_index = 10
	add_child(indicator_label)

func set_station_state(enabled: bool, is_completed: bool) -> void:
	interaction_enabled = enabled
	completed = is_completed
	if indicator_label:
		indicator_label.visible = false
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, 0.12))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	var base_color := Color(0.24, 0.24, 0.28)
	if interaction_enabled:
		base_color = accent_color.darkened(0.35)
	if completed:
		base_color = accent_color.lightened(0.08)

	if station_visual == "printer":
		draw_rect(Rect2(Vector2(-18, -42), Vector2(36, 48)), base_color)
		draw_rect(Rect2(Vector2(-12, -34), Vector2(24, 10)), Color(accent_color.r, accent_color.g, accent_color.b, 0.94 if completed else 0.72))
		draw_rect(Rect2(Vector2(-10, -18), Vector2(20, 8)), Color(0.92, 0.88, 0.74, 0.86 if completed else 0.62))
		draw_rect(Rect2(Vector2(-8, 6), Vector2(16, 8)), base_color.darkened(0.25))
	else:
		draw_rect(Rect2(Vector2(-16, -38), Vector2(32, 44)), base_color)
		draw_rect(Rect2(Vector2(-10, -30), Vector2(20, 8)), Color(accent_color.r, accent_color.g, accent_color.b, 0.94 if completed else 0.68))
		draw_rect(Rect2(Vector2(-10, -14), Vector2(20, 10)), Color(0.92, 0.88, 0.74, 0.82 if completed else 0.48))
		draw_rect(Rect2(Vector2(-7, 6), Vector2(14, 8)), base_color.darkened(0.25))

	if completed:
		draw_line(Vector2(-8, -54), Vector2(-2, -48), Color(0.9, 0.96, 0.78), 3.0)
		draw_line(Vector2(-2, -48), Vector2(10, -60), Color(0.9, 0.96, 0.78), 3.0)

func _process(delta: float) -> void:
	if not player_ref:
		return
	pulse_time += delta * 3.4

	var near := global_position.distance_to(player_ref.global_position) < INTERACT_DISTANCE
	indicator_label.visible = near and interaction_enabled and not completed
	if indicator_label.visible:
		indicator_label.position.y = -66 + sin(pulse_time) * 3.0
		indicator_label.modulate.a = 0.62 + sin(pulse_time * 2.0) * 0.3

func interact() -> void:
	if room_ref and room_ref.has_method("handle_ritual_station_interaction"):
		room_ref.handle_ritual_station_interaction(station_id)
