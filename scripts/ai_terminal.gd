extends StaticBody2D

const INTERACT_DISTANCE := 55.0
var interact_cooldown := 0.0

func _process(delta: float) -> void:
	# Keep cooldown alive while dialogue is open so it only counts down AFTER close
	var world = get_tree().current_scene
	if world and world.get("is_dialogue_open"):
		interact_cooldown = 1.5
		return

	if interact_cooldown > 0.0:
		interact_cooldown -= delta
		return

	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return

	var player = players[0]
	var dist: float = global_position.distance_to(player.global_position)
	if dist < INTERACT_DISTANCE:
		if world and world.has_method("open_dialogue") and not world.get("is_dialogue_open"):
			interact()

func interact() -> void:
	interact_cooldown = 1.5
	var world = get_tree().current_scene
	if world and world.has_method("open_dialogue"):
		world.open_dialogue("ai_terminal")
