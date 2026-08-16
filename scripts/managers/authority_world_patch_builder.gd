extends Node

const TILE_SIZE := 32

# A world patch is the smallest complete exterior unit: the authored facade,
# its contact with the district plate, its readable approach, and the collision
# footprint implied by the visible lower mass.  Coordinates are local to the
# building center unless otherwise noted.
const PATCH_PROFILES := {
	"oval_office": {
		"collision_rows": [
			[-3, 0, 0], [-2, -3, 3], [-1, -4, 4], [0, -4, 4],
			[1, -5, 5], [2, -4, 4], [3, -4, 4], [4, -3, 3]
		],
		"approach_half_width": 2,
		"foundation": Color(0.55, 0.43, 0.24, 0.3),
		"edge": Color(1.0, 0.75, 0.24, 0.58),
		"route": Color(0.48, 0.035, 0.025, 0.65),
		"motif": "spectacle"
	},
	"spaceship": {
		"collision_rows": [
			[-3, 0, 0], [-2, -1, 1], [-1, -2, 2], [0, -3, 3],
			[1, -4, 4], [2, -5, 5], [3, -4, 4], [4, -3, 3]
		],
		"approach_half_width": 2,
		"foundation": Color(0.08, 0.13, 0.16, 0.38),
		"edge": Color(0.16, 0.82, 0.92, 0.55),
		"route": Color(0.08, 0.25, 0.3, 0.52),
		"motif": "prototype"
	},
	"eu_palace": {
		"collision_rows": [
			[-4, -4, 4], [-3, -5, 5], [-2, -5, 5], [-1, -5, 5],
			[0, -5, 5], [1, -5, 5], [2, -5, 5], [3, -5, 5], [4, -4, 4]
		],
		"approach_half_width": 2,
		"foundation": Color(0.16, 0.27, 0.43, 0.3),
		"edge": Color(0.43, 0.68, 1.0, 0.62),
		"route": Color(0.08, 0.22, 0.52, 0.5),
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
		"foundation": Color(0.19, 0.18, 0.12, 0.36),
		"edge": Color(0.76, 0.22, 0.12, 0.58),
		"route": Color(0.32, 0.035, 0.025, 0.52),
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
		"foundation": Color(0.16, 0.21, 0.16, 0.36),
		"edge": Color(0.91, 0.68, 0.25, 0.58),
		"route": Color(0.19, 0.22, 0.14, 0.5),
		"motif": "stability"
	},
	"elysee": {
		"collision_rows": [
			[-4, -5, 5], [-3, -5, 5], [-2, -5, 5],
			[-1, -3, 3], [0, -3, 3], [1, -3, 3], [2, -3, 3], [3, -3, 3]
		],
		"approach_half_width": 2,
		"foundation": Color(0.3, 0.25, 0.22, 0.3),
		"edge": Color(0.88, 0.68, 0.35, 0.56),
		"route": Color(0.34, 0.055, 0.07, 0.48),
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
	if not _build_raster_motif(root, profile):
		_build_motif(root, str(profile.get("motif", "")), profile)

	var facade := Sprite2D.new()
	facade.name = "%sFacade" % _pascal_case(building_key)
	facade.texture = texture
	facade.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	facade.position = Vector2(0.0, -texture.get_height() * 0.5)
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


func _build_raster_motif(root: Node2D, profile: Dictionary) -> bool:
	var texture_path := str(profile.get("motif_asset", ""))
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return false
	var texture := load(texture_path) as Texture2D
	if texture == null or texture.get_width() <= 0:
		return false

	var motif := Sprite2D.new()
	motif.name = "SiegeForecourt"
	motif.texture = texture
	motif.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	motif.position = profile.get("motif_position", Vector2.ZERO)
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
	var route: Color = profile["route"]

	# Banded, pixel-snapped contact shadow. Unlike the former duplicated facade
	# silhouette it reads as weight on the ground instead of a pasted drop shadow.
	_add_polygon(root, "OuterContactShadow", [
		Vector2(-172, -42), Vector2(172, -42), Vector2(188, -12),
		Vector2(160, 14), Vector2(-160, 14), Vector2(-188, -12)
	], Color(0.015, 0.02, 0.028, 0.2), -3)
	_add_polygon(root, "InnerContactShadow", [
		Vector2(-158, -34), Vector2(158, -34), Vector2(170, -8),
		Vector2(148, 8), Vector2(-148, 8), Vector2(-170, -8)
	], Color(0.01, 0.015, 0.02, 0.3), -2)

	# A shallow civic plinth covers the exact seam between transparent facade
	# pixels and the authored district plate.
	_add_polygon(root, "FoundationApron", [
		Vector2(-154, -30), Vector2(154, -30), Vector2(166, -4),
		Vector2(142, 18), Vector2(50, 18), Vector2(42, 30),
		Vector2(-42, 30), Vector2(-50, 18), Vector2(-142, 18), Vector2(-166, -4)
	], foundation, -1)
	_add_line(root, "FoundationEdge", PackedVector2Array([
		Vector2(-142, 18), Vector2(-50, 18), Vector2(-42, 30),
		Vector2(42, 30), Vector2(50, 18), Vector2(142, 18)
	]), edge, 2.0, 0)

	# The route begins inside the architecture and continues into the existing
	# path network, so the door no longer appears to end at an image boundary.
	_add_polygon(root, "Approach", [
		Vector2(-30, -8), Vector2(30, -8), Vector2(34, 88), Vector2(-34, 88)
	], route, -1)
	_add_line(root, "ApproachWestEdge", PackedVector2Array([
		Vector2(-30, -6), Vector2(-32, 88)
	]), Color(edge.r, edge.g, edge.b, edge.a * 0.72), 2.0, 0)
	_add_line(root, "ApproachEastEdge", PackedVector2Array([
		Vector2(30, -6), Vector2(32, 88)
	]), Color(edge.r, edge.g, edge.b, edge.a * 0.72), 2.0, 0)


func _build_motif(root: Node2D, motif: String, profile: Dictionary) -> void:
	var edge: Color = profile["edge"]
	match motif:
		"spectacle":
			# A red-carpet funnel and too many gold markers turn access into a show.
			_add_line(root, "CarpetCenter", PackedVector2Array([Vector2(0, 4), Vector2(0, 84)]), Color(0.9, 0.54, 0.12, 0.58), 3.0, 0)
			for y in [16.0, 48.0, 80.0]:
				_add_ground_marker(root, Vector2(-47, y), edge)
				_add_ground_marker(root, Vector2(47, y), edge)
		"procedure":
			# The shortest route is visibly divided into a needlessly formal queue.
			for x in [-17.0, 0.0, 17.0]:
				_add_line(root, "QueueLane%s" % str(int(x + 18.0)), PackedVector2Array([Vector2(x, 8), Vector2(x, 82)]), Color(edge.r, edge.g, edge.b, 0.38), 2.0, 0)
			for y in [22.0, 46.0, 70.0]:
				_add_line(root, "QueueGate%s" % str(int(y)), PackedVector2Array([Vector2(-28, y), Vector2(10, y)]), Color(edge.r, edge.g, edge.b, 0.42), 2.0, 0)
		"managed_decline":
			# The ceremonial route remains polished; the surrounding repairs do not.
			_add_line(root, "CeremonialInlay", PackedVector2Array([Vector2(-12, 2), Vector2(-12, 84)]), edge, 2.0, 0)
			_add_line(root, "DeferredRepair", PackedVector2Array([
				Vector2(48, 20), Vector2(66, 34), Vector2(54, 48), Vector2(72, 64)
			]), Color(0.08, 0.07, 0.065, 0.42), 3.0, 0)
			for x in [-76.0, 76.0]:
				_add_line(root, "RepairBarrier%s" % str(int(x)), PackedVector2Array([Vector2(x - 14, 52), Vector2(x + 14, 52)]), Color(0.94, 0.67, 0.2, 0.72), 4.0, 0)
		"prototype":
			for y in [18.0, 42.0, 66.0]:
				_add_line(root, "LaunchMark%s" % str(int(y)), PackedVector2Array([Vector2(-28, y), Vector2(-12, y + 8)]), edge, 3.0, 0)
		"siege":
			for x in [-64.0, 64.0]:
				_add_line(root, "Barrier%s" % str(int(x)), PackedVector2Array([Vector2(x - 20, 42), Vector2(x + 20, 42)]), edge, 6.0, 0)
		"stability":
			for y in [24.0, 40.0, 56.0]:
				_add_line(root, "Tier%s" % str(int(y)), PackedVector2Array([Vector2(-26, y), Vector2(26, y)]), Color(edge.r, edge.g, edge.b, 0.56), 2.0, 0)


func _add_ground_marker(parent: Node2D, position: Vector2, color: Color) -> void:
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([
		position + Vector2(-4, -4), position + Vector2(4, -4),
		position + Vector2(5, 4), position + Vector2(-5, 4)
	])
	marker.color = color
	marker.z_index = 0
	parent.add_child(marker)


func _add_polygon(parent: Node2D, node_name: String, points: Array, color: Color, z_index: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = PackedVector2Array(points)
	polygon.color = color
	polygon.z_index = z_index
	parent.add_child(polygon)
	return polygon


func _add_line(parent: Node2D, node_name: String, points: PackedVector2Array, color: Color, width: float, z_index: int) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.default_color = color
	line.width = width
	line.antialiased = false
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
