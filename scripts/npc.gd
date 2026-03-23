extends StaticBody2D

@export var character_id: String = "donald_trump"
@export var character_name: String = "Unknown"
@export var faces_right_by_default: bool = false

@onready var sprite: Sprite2D = $Sprite2D

var player_ref: CharacterBody2D = null
var indicator_label: Label
var indicator_time: float = 0.0
var idle_time: float = 0.0
var base_scale := Vector2.ONE

func _ready() -> void:
	if sprite:
		base_scale = sprite.scale
	_create_interaction_indicator()
	call_deferred("_find_player")
	queue_redraw()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _create_interaction_indicator() -> void:
	indicator_label = Label.new()
	indicator_label.text = "!"
	indicator_label.add_theme_font_size_override("font_size", 22)
	indicator_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	indicator_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.05, 0.0, 0.6))
	indicator_label.add_theme_constant_override("shadow_offset_x", 1)
	indicator_label.add_theme_constant_override("shadow_offset_y", 1)
	indicator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicator_label.position = Vector2(-8, -70)
	indicator_label.visible = false
	indicator_label.z_index = 10
	add_child(indicator_label)

func _draw() -> void:
	# Shadow ellipse at NPC feet
	draw_set_transform(Vector2(0, 2), 0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.15))

func _process(delta: float) -> void:
	if sprite:
		idle_time += delta * 2.0
		var breathe = sin(idle_time) * 0.025
		sprite.scale = base_scale + Vector2(-breathe * 0.4, breathe)

	if not player_ref:
		return

	var dist = global_position.distance_to(player_ref.global_position)
	var nearby = dist < 90.0
	indicator_label.visible = nearby

	if nearby:
		indicator_time += delta * 3.5
		indicator_label.position.y = -70 + sin(indicator_time) * 3.0
		indicator_label.modulate.a = 0.6 + sin(indicator_time * 2.0) * 0.4

	if sprite:
		var player_on_left := player_ref.global_position.x < global_position.x
		sprite.flip_h = player_on_left if faces_right_by_default else not player_on_left

func interact() -> void:
	indicator_label.visible = false

	# Jump reaction
	var tween = create_tween()
	tween.tween_property(sprite, "position:y", -10.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	var world = get_tree().current_scene
	if world and world.has_method("open_dialogue"):
		world.open_dialogue(character_id)
