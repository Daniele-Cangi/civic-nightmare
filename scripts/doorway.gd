extends Area2D

@export var destination: String = ""
@export var spawn_marker: String = ""
@export var prompt_name: String = "Door"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func interact() -> void:
	var world = get_tree().current_scene
	if world and world.has_method("use_door"):
		world.use_door(destination, spawn_marker)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	interact()
