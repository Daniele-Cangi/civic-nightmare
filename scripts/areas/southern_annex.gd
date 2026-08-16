extends Node2D

const WORLD_LANDMARK_BUILDER_SCRIPT = preload("res://scripts/managers/world_landmark_builder.gd")
const DOORWAY_SCRIPT = preload("res://scripts/doorway.gd")

const AREA_SIZE := Vector2(1536.0, 1024.0)
const PYONGYANG_LANDMARK_POSITION := Vector2(352.0, 640.0)
const NEURAL_CORE_LANDMARK_POSITION := Vector2(1184.0, 640.0)
const PYONGYANG_ACCESS_POSITION := Vector2(272.0, 700.0)
const NEURAL_CORE_ACCESS_POSITION := Vector2(1184.0, 700.0)
const PYONGYANG_ART_OFFSET := Vector2(-80.0, 95.0)
const NEURAL_CORE_ART_OFFSET := Vector2(0.0, 102.0)

@onready var ground_map: TileMap = $GroundMap
@onready var interactables: Node2D = $Interactables
@onready var entities: Node2D = $Entities
@onready var markers: Node2D = $Markers

var landmark_builder: Node


func _ready() -> void:
	_build_landmarks()
	_create_north_exit()
	_create_perimeter_collision()
	set_room_active(false)


func set_room_active(active: bool) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func is_indoor() -> bool:
	return false


func get_entity_container() -> Node2D:
	return entities


func get_spawn_position(marker_name: String) -> Vector2:
	var marker := markers.get_node_or_null(marker_name) as Marker2D
	if marker:
		return marker.global_position
	return global_position + Vector2(768.0, 260.0)


func get_room_title() -> String:
	return "SOUTHERN ADMINISTRATIVE ANNEX"


func get_room_subtitle() -> String:
	return "Two strategic visions. One municipal electricity account."


func apply_camera_limits(camera: Camera2D) -> void:
	camera.limit_left = int(global_position.x)
	camera.limit_top = int(global_position.y)
	camera.limit_right = int(global_position.x + AREA_SIZE.x)
	camera.limit_bottom = int(global_position.y + AREA_SIZE.y)
	camera.reset_smoothing()


func _build_landmarks() -> void:
	while ground_map.get_layers_count() < 3:
		ground_map.add_layer(-1)
	landmark_builder = WORLD_LANDMARK_BUILDER_SCRIPT.new()
	landmark_builder.name = "AnnexLandmarkBuilder"
	add_child(landmark_builder)
	landmark_builder.setup(entities, ground_map)
	landmark_builder.create_pyongyang(Vector2i(14, 21))
	landmark_builder.create_nuclear_plant(Vector2i(32, 21))

	var pyongyang := entities.get_node_or_null("PyongyangEntrance") as Node2D
	if pyongyang:
		pyongyang.position = PYONGYANG_LANDMARK_POSITION
		var pyongyang_art := pyongyang.get_node_or_null("PyongyangLandmark") as Sprite2D
		if pyongyang_art:
			pyongyang_art.position += PYONGYANG_ART_OFFSET
		var pyongyang_door := pyongyang.get_node_or_null("PyongyangCannonDoor") as Area2D
		if pyongyang_door:
			pyongyang_door.position = PYONGYANG_ACCESS_POSITION - PYONGYANG_LANDMARK_POSITION
	var neural_core := entities.get_node_or_null("NuclearPlantEntrance") as Node2D
	if neural_core:
		neural_core.position = NEURAL_CORE_LANDMARK_POSITION
		var neural_core_art := neural_core.get_node_or_null("NuclearPlantLandmark") as Sprite2D
		if neural_core_art:
			neural_core_art.position += NEURAL_CORE_ART_OFFSET
		var neural_core_door := neural_core.get_node_or_null("NeuralCoreDoor") as Area2D
		if neural_core_door:
			neural_core_door.position = NEURAL_CORE_ACCESS_POSITION - NEURAL_CORE_LANDMARK_POSITION


func _create_north_exit() -> void:
	var door := Area2D.new()
	door.name = "ReturnToMainDistrict"
	door.position = Vector2(768.0, 205.0)
	door.collision_layer = 0
	door.collision_mask = 1
	door.monitoring = true
	door.monitorable = true
	door.set_script(DOORWAY_SCRIPT)
	door.set("destination", "world")
	door.set("spawn_marker", "southern_annex_exterior")
	door.set("prompt_name", "Return to Main District")
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(150.0, 46.0)
	collision.shape = shape
	door.add_child(collision)
	interactables.add_child(door)


func _create_perimeter_collision() -> void:
	var perimeter := StaticBody2D.new()
	perimeter.name = "AnnexPerimeterCollision"
	entities.add_child(perimeter)
	_add_collision_rect(perimeter, "NorthBackstop", Vector2(768.0, 34.0), Vector2(1536.0, 68.0))
	_add_collision_rect(perimeter, "WestBoundary", Vector2(34.0, 512.0), Vector2(68.0, 1024.0))
	_add_collision_rect(perimeter, "EastBoundary", Vector2(1502.0, 512.0), Vector2(68.0, 1024.0))
	_add_collision_rect(perimeter, "SouthBoundary", Vector2(768.0, 990.0), Vector2(1536.0, 68.0))


func _add_collision_rect(parent: StaticBody2D, shape_name: String, local_position: Vector2, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	collision.name = shape_name
	collision.position = local_position
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	parent.add_child(collision)
