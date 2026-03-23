extends CharacterBody2D

const SPEED = 250.0
const BOB_SPEED = 12.0
const BOB_AMPLITUDE = 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var camera: Camera2D = $Camera2D

var last_direction := Vector2.DOWN
var is_moving := false
var walk_time := 0.0
var base_sprite_offset := Vector2(0, -16)
var dust_particles: CPUParticles2D

func _ready() -> void:
	_create_dust_particles()

func _create_dust_particles() -> void:
	dust_particles = CPUParticles2D.new()
	dust_particles.emitting = false
	dust_particles.amount = 6
	dust_particles.lifetime = 0.4
	dust_particles.position = Vector2(0, 2)
	dust_particles.direction = Vector2(0, -1)
	dust_particles.spread = 55.0
	dust_particles.initial_velocity_min = 8.0
	dust_particles.initial_velocity_max = 22.0
	dust_particles.gravity = Vector2(0, 35)
	dust_particles.scale_amount_min = 1.0
	dust_particles.scale_amount_max = 2.5
	dust_particles.color = Color(0.6, 0.55, 0.4, 0.45)
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(0.6, 0.55, 0.4, 0.5), Color(0.6, 0.55, 0.4, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	dust_particles.color_ramp = grad
	add_child(dust_particles)

func _draw() -> void:
	# Shadow ellipse at character feet
	draw_set_transform(Vector2(0, 2), 0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, 0.18))

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	if direction.x == 0:
		direction.x = float(Input.is_physical_key_pressed(Key.KEY_D)) - float(Input.is_physical_key_pressed(Key.KEY_A))
	if direction.y == 0:
		direction.y = float(Input.is_physical_key_pressed(Key.KEY_S)) - float(Input.is_physical_key_pressed(Key.KEY_W))

	var was_moving = is_moving
	is_moving = direction.length() > 0

	if is_moving:
		direction = direction.normalized()
		last_direction = direction
		walk_time += delta * BOB_SPEED

		# Walking bob
		sprite.offset = base_sprite_offset + Vector2(0, sin(walk_time) * BOB_AMPLITUDE)

		# Rhythmic squash-stretch
		var sq = 1.0 + sin(walk_time * 2.0) * 0.035
		sprite.scale = Vector2(1.0 / sq, sq)

		# Flip sprite horizontally
		if abs(direction.x) > 0.1:
			sprite.flip_h = direction.x < 0

		# Snap interaction ray to 4 cardinal directions
		if abs(direction.x) > abs(direction.y):
			interaction_ray.target_position = Vector2(sign(direction.x) * 40, 0)
		else:
			interaction_ray.target_position = Vector2(0, sign(direction.y) * 40)

		dust_particles.emitting = true
	else:
		# Idle breathing
		walk_time += delta * 2.0
		var breathe = sin(walk_time) * 0.02
		sprite.scale = Vector2(1.0 - breathe * 0.5, 1.0 + breathe)
		sprite.offset = base_sprite_offset
		dust_particles.emitting = false

	# Landing squash when player stops moving
	if was_moving and not is_moving:
		var tw = create_tween()
		tw.tween_property(sprite, "scale", Vector2(1.08, 0.92), 0.06)
		tw.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.12).set_ease(Tween.EASE_OUT)

	velocity = direction * SPEED
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_attempt_interaction()

func _attempt_interaction() -> void:
	interaction_ray.force_raycast_update()
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider and collider.has_method("interact"):
			collider.interact()
