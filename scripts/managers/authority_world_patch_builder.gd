extends Node

const TILE_SIZE := 32

# A world patch is the smallest complete exterior unit: the authored facade,
# its contact with the district plate, its entrance axis, and the collision
# footprint implied by the visible lower mass.  Coordinates are local to the
# building center unless otherwise noted.
const PATCH_PROFILES := {
	"oval_office": {
		"collision_rows": [
			[-3, 0, 0], [-2, -3, 3], [-1, -4, 4], [0, -4, 4],
			[1, -5, 5], [2, -4, 4], [3, -4, 4], [4, -3, 3]
		],
		"approach_half_width": 2,
		"visual_offset": Vector2(16.0, 0.0),
		"foundation": Color(0.55, 0.43, 0.24, 0.3),
		"edge": Color(1.0, 0.75, 0.24, 0.58),
		"motif": "spectacle"
	},
	"spaceship": {
		"collision_rows": [
			[-3, 0, 0], [-2, -1, 1], [-1, -2, 2], [0, -3, 3],
			[1, -4, 4], [2, -5, 5], [3, -4, 4], [4, -3, 3]
		],
		"approach_half_width": 2,
		"visual_offset": Vector2(-16.0, 0.0),
		"foundation": Color(0.08, 0.13, 0.16, 0.38),
		"edge": Color(0.16, 0.82, 0.92, 0.55),
		"motif": "prototype"
	},
	"eu_palace": {
		"collision_rows": [
			[-4, -4, 4], [-3, -5, 5], [-2, -5, 5], [-1, -5, 5],
			[0, -5, 5], [1, -5, 5], [2, -5, 5], [3, -5, 5], [4, -4, 4]
		],
		"approach_half_width": 2,
		"visual_offset": Vector2(16.0, 0.0),
		"foundation": Color(0.16, 0.27, 0.43, 0.3),
		"edge": Color(0.43, 0.68, 1.0, 0.62),
		"motif": "procedure"
	},
	"kremlin": {
		"collision_rows": [
			[-2, -2, 2], [-1, -2, 2], [0, -2, 2],
			[1, -5, 5], [2, -5, 5], [3, -5, 5], [4, -5, 5]
		],
		"prop_collision_cells": [
			Vector2i(-6, 5), Vector2i(-5, 5), Vector2i(-4, 5), Vector2i(-3, 5),
			Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5),
			Vector2i(-6, 6), Vector2i(-5, 6), Vector2i(-4, 6),
			Vector2i(4, 6), Vector2i(5, 6), Vector2i(6, 6),
			Vector2i(-6, 7), Vector2i(-5, 7), Vector2i(5, 7), Vector2i(6, 7)
		],
		"approach_half_width": 2,
		"visual_offset": Vector2(-24.0, 0.0),
		"foundation": Color(0.19, 0.18, 0.12, 0.36),
		"edge": Color(0.76, 0.22, 0.12, 0.58),
		"motif": "siege",
		"motif_asset": "res://assets/landmarks/authority_putin_siege_forecourt_v1.png",
		"motif_display_width": 416.0,
		"motif_position": Vector2(0.0, 0.0),
		"motif_z_index": 1
	},
	"vault": {
		"collision_rows": [
			[-4, -3, 3], [-3, -4, 4], [-2, -5, 5], [-1, -5, 5],
			[0, -5, 5], [1, -5, 5], [2, -5, 5], [3, -4, 4], [4, -3, 3]
		],
		"approach_half_width": 2,
		"visual_offset": Vector2(16.0, 0.0),
		"foundation": Color(0.16, 0.21, 0.16, 0.36),
		"edge": Color(0.91, 0.68, 0.25, 0.58),
		"motif": "stability"
	},
	"elysee": {
		"collision_rows": [
			[-4, -5, 5], [-3, -5, 5], [-2, -5, 5],
			[-1, -3, 3], [0, -3, 3], [1, -3, 3], [2, -3, 3], [3, -3, 3]
		],
		"approach_half_width": 2,
		"visual_offset": Vector2(-16.0, 0.0),
		"foundation": Color(0.3, 0.25, 0.22, 0.3),
		"edge": Color(0.88, 0.68, 0.35, 0.56),
		"motif": "managed_decline"
	}
}

var entities_layer: Node2D


func setup(world_entities: Node2D) -> void:
	entities_layer = world_entities


func has_profile(building_key: String) -> bool:
	return PATCH_PROFILES.has(building_key)


func get_approach_half_width(building_key: String) -> int:
	var profile: Dictionary = PATCH_PROFILES.get(building_key, {})
	return int(profile.get("approach_half_width", 1))


func get_collision_cells(building_key: String, center: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var profile: Dictionary = PATCH_PROFILES.get(building_key, {})
	for row_value in profile.get("collision_rows", []):
		var row: Array = row_value
		var local_y := int(row[0])
		for local_x in range(int(row[1]), int(row[2]) + 1):
			cells.append(center + Vector2i(local_x, local_y))
	for local_cell_value in profile.get("prop_collision_cells", []):
		var local_cell: Vector2i = local_cell_value
		cells.append(center + local_cell)
	return cells


func create_authority_patch(spec: Dictionary, texture: Texture2D) -> Dictionary:
	if entities_layer == null or texture == null:
		return {}

	var building_key := str(spec.get("key", ""))
	if not PATCH_PROFILES.has(building_key):
		return {}

	var center: Vector2i = spec["center"]
	var entrance: Vector2i = spec["entrance"]
	var profile: Dictionary = PATCH_PROFILES[building_key]
	var visual_offset: Vector2 = profile.get("visual_offset", Vector2.ZERO)
	var root := Node2D.new()
	root.name = "%sWorldPatch" % _pascal_case(building_key)
	root.position = Vector2(
		center.x * TILE_SIZE + TILE_SIZE * 0.5,
		entrance.y * TILE_SIZE + TILE_SIZE
	)
	root.add_to_group("authority_world_patch")
	root.set_meta("building_key", building_key)
	root.set_meta("character_id", str(spec.get("npc", "")))
	root.set_meta("center_tile", center)
	root.set_meta("entrance_tile", entrance)
	root.set_meta("npc_spawn_tile", spec.get("npc_spawn", entrance + Vector2i.DOWN))
	entities_layer.add_child(root)

	_build_ground_contact(root, profile)
	_build_raster_motif(root, profile, visual_offset)

	var facade := Sprite2D.new()
	facade.name = "%sFacade" % _pascal_case(building_key)
	facade.texture = texture
	facade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	facade.position = visual_offset + Vector2(0.0, -texture.get_height() * 0.5)
	facade.z_index = 4
	facade.add_to_group("authority_facade")
	facade.set_meta("character_id", str(spec.get("npc", "")))
	root.add_child(facade)

	var collision_cells := get_collision_cells(building_key, center)
	root.set_meta("collision_cell_count", collision_cells.size())
	return {
		"root": root,
		"facade": facade,
		"collision_cells": collision_cells
	}


func _build_raster_motif(root: Node2D, profile: Dictionary, visual_offset: Vector2) -> bool:
	var texture_path := str(profile.get("motif_asset", ""))
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return false
	var texture := load(texture_path) as Texture2D
	if texture == null or texture.get_width() <= 0:
		return false

	var motif := Sprite2D.new()
	motif.name = "SiegeForecourt"
	motif.texture = texture
	motif.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var motif_position: Vector2 = profile.get("motif_position", Vector2.ZERO)
	motif.position = visual_offset + motif_position
	var display_width := float(profile.get("motif_display_width", texture.get_width()))
	var motif_scale := display_width / float(texture.get_width())
	motif.scale = Vector2(motif_scale, motif_scale)
	motif.z_index = int(profile.get("motif_z_index", 1))
	motif.add_to_group("authority_patch_motif")
	motif.set_meta("motif", str(profile.get("motif", "")))
	root.add_child(motif)
	return true


func _build_ground_contact(root: Node2D, profile: Dictionary) -> void:
	var foundation: Color = profile["foundation"]
	var edge: Color = profile["edge"]

	# One soft radial contact shadow gives the facade weight without drawing a
	# second hard-edged platform or carpet over the authored plaza.
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.01, 0.015, 0.02, 0.28),
		Color(0.01, 0.015, 0.02, 0.15),
		Color(0.01, 0.015, 0.02, 0.0)
	])
	var shadow_texture := GradientTexture2D.new()
	shadow_texture.width = 384
	shadow_texture.height = 96
	shadow_texture.gradient = gradient
	shadow_texture.fill = GradientTexture2D.FILL_RADIAL
	shadow_texture.fill_from = Vector2(0.5, 0.5)
	shadow_texture.fill_to = Vector2(0.5, 1.0)
	var shadow := Sprite2D.new()
	shadow.name = "ContactShadow"
	shadow.texture = shadow_texture
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shadow.position = Vector2(0.0, -8.0)
	shadow.z_index = -2
	root.add_child(shadow)

	# A short low-alpha seam is enough to tie the threshold to the ground. It
	# stops at the doorway and never continues into a player-facing route strip.
	_add_line(root, "FoundationSeam", PackedVector2Array([
		Vector2(-142, 8), Vector2(-46, 8), Vector2(-40, 14),
		Vector2(40, 14), Vector2(46, 8), Vector2(142, 8)
	]), Color(edge.r, edge.g, edge.b, minf(edge.a, foundation.a) * 0.42), 1.5, -1)

func _add_line(parent: Node2D, node_name: String, points: PackedVector2Array, color: Color, width: float, z_index: int) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.default_color = color
	line.width = width
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_BOX
	line.end_cap_mode = Line2D.LINE_CAP_BOX
	line.joint_mode = Line2D.LINE_JOINT_SHARP
	line.z_index = z_index
	parent.add_child(line)
	return line


func _pascal_case(value: String) -> String:
	var result := ""
	for part in value.split("_", false):
		if not part.is_empty():
			result += part.substr(0, 1).to_upper() + part.substr(1).to_lower()
	return result if not result.is_empty() else "Authority"
