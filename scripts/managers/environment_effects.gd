extends Node

var host: Node
var entities_layer: Node2D
var ui_layer: CanvasLayer

var world_canvas_modulate: CanvasModulate
var screen_fx_material: ShaderMaterial


func setup(owner: Node, world_entities: Node2D, world_ui: CanvasLayer) -> void:
	host = owner
	entities_layer = world_entities
	ui_layer = world_ui


func setup_world_lighting(building_specs: Array) -> void:
	# Very subtle cold tint — avoid washing out the pixel art
	world_canvas_modulate = CanvasModulate.new()
	world_canvas_modulate.color = Color(0.95, 0.96, 0.98)
	host.add_child(world_canvas_modulate)

	# Warm lights at each building entrance
	for spec in building_specs:
		_add_point_light(spec["entrance"], spec["light_color"])

func _add_point_light(tile_pos: Vector2i, color: Color) -> void:
	var light = PointLight2D.new()
	light.position = Vector2(tile_pos.x * 32 + 16, tile_pos.y * 32 + 16)
	light.color = color
	light.energy = 0.7
	light.texture_scale = 3.5

	# Programmatic radial gradient texture
	var tex = GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	tex.gradient = grad
	light.texture = tex
	entities_layer.add_child(light)

func setup_ambient_audio() -> void:
	# Door entry sound effect only (soft thud, no ambient noise)
	var door_sfx = AudioStreamPlayer.new()
	door_sfx.name = "DoorSFX"
	door_sfx.volume_db = -16.0
	var door_rate := 22050
	var door_dur := 0.1
	var door_samples := int(door_rate * door_dur)
	var door_stream := AudioStreamWAV.new()
	door_stream.format = AudioStreamWAV.FORMAT_8_BITS
	door_stream.mix_rate = door_rate
	door_stream.stereo = false
	var door_data := PackedByteArray()
	door_data.resize(door_samples)
	for i in range(door_samples):
		var t := float(i) / door_rate
		var env := (1.0 - t / door_dur)
		var thud := sin(t * 180.0 * TAU) * env * env
		door_data[i] = int(clampf(thud * 45.0 + 128.0, 0.0, 255.0))
	door_stream.data = door_data
	door_sfx.stream = door_stream
	host.add_child(door_sfx)

func create_atmosphere_particles() -> void:
	var player_node = host.get_node_or_null("Player")
	if not player_node:
		return

	# Floating leaves / pollen
	var leaves = CPUParticles2D.new()
	leaves.name = "LeafParticles"
	leaves.emitting = true
	leaves.amount = 12
	leaves.lifetime = 6.0
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = Vector2(400, 300)
	leaves.direction = Vector2(1.0, 0.5)
	leaves.spread = 30.0
	leaves.initial_velocity_min = 6.0
	leaves.initial_velocity_max = 14.0
	leaves.gravity = Vector2(2.0, 8.0)
	leaves.angular_velocity_min = -40.0
	leaves.angular_velocity_max = 40.0
	leaves.scale_amount_min = 1.5
	leaves.scale_amount_max = 3.0
	var leaf_grad = Gradient.new()
	leaf_grad.colors = PackedColorArray([
		Color(0.45, 0.55, 0.25, 0.0),
		Color(0.5, 0.6, 0.3, 0.35),
		Color(0.55, 0.5, 0.25, 0.3),
		Color(0.6, 0.45, 0.2, 0.0)
	])
	leaf_grad.offsets = PackedFloat32Array([0.0, 0.15, 0.7, 1.0])
	leaves.color_ramp = leaf_grad
	leaves.z_index = 5
	player_node.add_child(leaves)

	# Fireflies (subtle glowing dots)
	var fireflies = CPUParticles2D.new()
	fireflies.name = "Fireflies"
	fireflies.emitting = true
	fireflies.amount = 8
	fireflies.lifetime = 4.0
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = Vector2(350, 250)
	fireflies.direction = Vector2(0, -1)
	fireflies.spread = 180.0
	fireflies.initial_velocity_min = 2.0
	fireflies.initial_velocity_max = 8.0
	fireflies.gravity = Vector2(0, -3)
	fireflies.scale_amount_min = 1.0
	fireflies.scale_amount_max = 2.0
	var ff_grad = Gradient.new()
	ff_grad.colors = PackedColorArray([
		Color(1.0, 0.95, 0.5, 0.0),
		Color(1.0, 0.9, 0.4, 0.5),
		Color(1.0, 0.85, 0.3, 0.4),
		Color(1.0, 0.9, 0.5, 0.0)
	])
	ff_grad.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	fireflies.color_ramp = ff_grad
	fireflies.z_index = 6
	player_node.add_child(fireflies)


func create_screen_fx() -> void:
	var fx_rect = ColorRect.new()
	fx_rect.name = "ScreenFX"
	fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	var shader_res = load("res://shaders/screen_pixel_fx.gdshader")
	if shader_res:
		var mat = ShaderMaterial.new()
		mat.shader = shader_res
		mat.set_shader_parameter("effect_strength", 0.08)
		mat.set_shader_parameter("pixel_size", 1.0)
		mat.set_shader_parameter("color_levels", 10.0)
		mat.set_shader_parameter("scanline_strength", 0.04)
		mat.set_shader_parameter("vignette_strength", 0.1)
		mat.set_shader_parameter("overlay_strength", 0.2)
		mat.set_shader_parameter("tint_color", Color(0.96, 0.97, 0.98, 1.0))
		fx_rect.material = mat
		screen_fx_material = mat

	ui_layer.add_child(fx_rect)
	ui_layer.move_child(fx_rect, 0)
