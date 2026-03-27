extends CharacterBody2D

const SPEED = 250.0
const BOB_SPEED = 12.0
const BOB_AMPLITUDE = 2.0
const DEFAULT_CAMERA_ZOOM = 1.5
const INDOOR_CAMERA_ZOOM = 2.05
const DEFAULT_CAMERA_SMOOTHING = 8.0
const INDOOR_CAMERA_SMOOTHING = 4.5

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var camera: Camera2D = $Camera2D

var last_direction := Vector2.DOWN
var is_moving := false
var walk_time := 0.0
var base_sprite_offset := Vector2(0, -16)
var dust_particles: CPUParticles2D
var speed_multiplier := 1.0
var dust_enabled := true
var footstep_player: AudioStreamPlayer2D
var footstep_timer := 0.0
const FOOTSTEP_INTERVAL := 0.28

func _ready() -> void:
	_create_dust_particles()
	_create_footstep_audio()

func set_traversal_context(indoor: bool) -> void:
	speed_multiplier = 0.72 if indoor else 1.0
	dust_enabled = not indoor
	camera.position_smoothing_speed = INDOOR_CAMERA_SMOOTHING if indoor else DEFAULT_CAMERA_SMOOTHING

	var target_zoom := Vector2.ONE * (INDOOR_CAMERA_ZOOM if indoor else DEFAULT_CAMERA_ZOOM)
	var tw = create_tween()
	tw.tween_property(camera, "zoom", target_zoom, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

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

func _create_footstep_audio() -> void:
	footstep_player = AudioStreamPlayer2D.new()
	footstep_player.volume_db = -24.0
	footstep_player.max_distance = 300.0
	add_child(footstep_player)
	# Generate a short procedural footstep sound
	var sample_rate := 22050
	var duration := 0.06
	var num_samples := int(sample_rate * duration)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	var data := PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var env := 1.0 - (t / duration)
		# Noise burst with quick decay
		var noise := (randf() * 2.0 - 1.0) * env * env
		data[i] = int(clampf(noise * 40.0 + 128.0, 0.0, 255.0))
	stream.data = data
	footstep_player.stream = stream

func _play_footstep() -> void:
	if footstep_player and not footstep_player.playing:
		footstep_player.pitch_scale = randf_range(0.85, 1.15)
		footstep_player.play()

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

		dust_particles.emitting = dust_enabled

		# Footstep audio on each bob cycle peak
		footstep_timer += delta
		if footstep_timer >= FOOTSTEP_INTERVAL:
			footstep_timer = 0.0
			_play_footstep()
	else:
		footstep_timer = 0.0
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

	velocity = direction * SPEED * speed_multiplier
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
