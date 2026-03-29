extends StaticBody2D

@export var character_id: String = "donald_trump"
@export var character_name: String = "Unknown"
@export var faces_right_by_default: bool = false
@export var interaction_distance: float = 85.0
@export var indicator_distance: float = 125.0

@onready var sprite: Sprite2D = $Sprite2D

var player_ref: CharacterBody2D = null
var indicator_label: Label
var indicator_time: float = 0.0
var idle_time: float = 0.0
var base_scale := Vector2.ONE

# Idle patrol
enum NPCState { PATROL, PAUSE, LOOK, FACING_PLAYER }
var state := NPCState.PAUSE
var state_timer := 0.0
var patrol_origin := Vector2.ZERO
var patrol_dir := 1.0
var patrol_range := 44.0
var patrol_speed := 34.0
var interaction_enabled := true
var require_reapproach := false
var look_at_target: Node2D = null

var interact_cooldown := 0.0

func _ready() -> void:
	if sprite:
		base_scale = sprite.scale
	_create_interaction_indicator()
	call_deferred("_find_player")
	call_deferred("_init_patrol")
	queue_redraw()

func _init_patrol() -> void:
	patrol_origin = position
	state = NPCState.PAUSE
	state_timer = randf_range(1.0, 3.0)

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

func set_interaction_enabled(value: bool) -> void:
	interaction_enabled = value
	if indicator_label:
		indicator_label.visible = false

func require_reapproach_before_interaction() -> void:
	require_reapproach = true
	if indicator_label:
		indicator_label.visible = false

func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.15))

func _process(delta: float) -> void:
	# Breathing animation (Subtle & Ironic)
	if sprite:
		idle_time += delta * 1.5
		var breathe = sin(idle_time) * 0.007
		sprite.scale = base_scale + Vector2(-breathe * 0.3, breathe)

	# Keep cooldown alive while dialogue is open so it only counts down AFTER close
	var world = get_tree().current_scene
	if world and world.get("is_dialogue_open"):
		interact_cooldown = 1.5
		return

	if interact_cooldown > 0.0:
		interact_cooldown -= delta

	if not player_ref:
		return

	var dist = global_position.distance_to(player_ref.global_position)
	if require_reapproach:
		if dist > indicator_distance + 8.0:
			require_reapproach = false
		else:
			if indicator_label:
				indicator_label.visible = false
			_update_patrol(delta)
			return
	var nearby: bool = dist < indicator_distance and interaction_enabled
	indicator_label.visible = nearby

	if nearby:
		# Show indicator
		indicator_time += delta * 3.5
		indicator_label.position.y = -70 + sin(indicator_time) * 3.0
		indicator_label.modulate.a = 0.6 + sin(indicator_time * 2.0) * 0.4

		# Only stop and face player if VERY close or interacting
		if dist < interaction_distance:
			if sprite:
				var player_on_left := player_ref.global_position.x < global_position.x
				sprite.flip_h = player_on_left if faces_right_by_default else not player_on_left
			state = NPCState.FACING_PLAYER
			
			# Auto-trigger dialogue
			if interact_cooldown <= 0.0:
				if world and world.has_method("open_dialogue") and not world.get("is_dialogue_open"):
					interact()
			return

	# Idle patrol behavior when player is far
	_update_patrol(delta)

func _update_patrol(delta: float) -> void:
	state_timer -= delta
	match state:
		NPCState.FACING_PLAYER:
			state = NPCState.PAUSE
			state_timer = randf_range(0.5, 1.5)
		NPCState.PAUSE:
			if state_timer <= 0:
				var roll := randf()
				if roll < 0.6:
					state = NPCState.PATROL
					patrol_dir = 1.0 if randf() > 0.5 else -1.0
					state_timer = randf_range(1.5, 3.5)
				else:
					state = NPCState.LOOK
					state_timer = randf_range(0.8, 2.0)
					if sprite:
						sprite.flip_h = randf() > 0.5
		NPCState.PATROL:
			position.x += patrol_dir * patrol_speed * delta
			if sprite:
				sprite.flip_h = (patrol_dir < 0) if not faces_right_by_default else (patrol_dir > 0)
			if abs(position.x - patrol_origin.x) > patrol_range:
				patrol_dir *= -1.0
			if state_timer <= 0:
				state = NPCState.PAUSE
				state_timer = randf_range(1.0, 3.0)
		NPCState.LOOK:
			if state_timer <= 0:
				state = NPCState.PAUSE
				state_timer = randf_range(0.5, 2.0)

func interact() -> void:
	if not interaction_enabled:
		return
	indicator_label.visible = false
	state = NPCState.FACING_PLAYER
	interact_cooldown = 2.0

	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "position:y", -10.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	var world = get_tree().current_scene
	if world and world.has_method("open_dialogue"):
		world.open_dialogue(character_id)
