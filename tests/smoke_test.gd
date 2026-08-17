extends SceneTree

const CHARACTER_VISUAL_CATALOG = preload("res://scripts/data/character_visual_catalog.gd")
const DIALOGUE_MANAGER_SCRIPT = preload("res://scripts/managers/dialogue_manager.gd")
const QUEST_MANAGER_SCRIPT = preload("res://scripts/managers/quest_manager.gd")
const SAVE_MANAGER_SCRIPT = preload("res://scripts/managers/save_manager.gd")
const DOSSIER_MANAGER_SCRIPT = preload("res://scripts/managers/dossier_manager.gd")
const BEZOS_BATTLE_STAGE_SCRIPT = preload("res://scripts/encounters/bezos_battle_stage.gd")
const BUNKER_ACCESS_GAUNTLET_SCRIPT = preload("res://scripts/encounters/bunker_access_gauntlet.gd")
const XI_PRE_SCENE_SCRIPT = preload("res://scripts/encounters/xi_pre_scene.gd")

const TEST_SAVE_PATH := "user://civic_nightmare_smoke_dossier.json"
const WORLD_DISTRICT_PLATE_PATH := "res://assets/backgrounds/world_district_plate_v3.png"
const NORTHERN_GREAT_WALL_PATH := "res://assets/landmarks/northern_great_wall_v1.png"
const INFERENCE_REACTOR_PATH := "res://assets/landmarks/inference_reactor_demo_v1.png"
const PYONGYANG_ARTILLERY_PATH := "res://assets/landmarks/pyongyang_broadcast_artillery_v1.png"
const SOUTHERN_ANNEX_GATE_PATH := "res://assets/landmarks/southern_annex_gate_v1.png"
const SOUTHERN_ANNEX_BACKGROUND_PATH := "res://assets/backgrounds/southern_administrative_annex_v1.png"
const BUNKER_ACCESS_BACKGROUND_PATH := "res://assets/encounters/bunker_aid_corridor_v1.png"
const AUTHORED_INTERIOR_PATHS := {
	"oval_office": "res://assets/interiors/oval_office_broadcast_machine_v1.png",
	"spaceship": "res://assets/interiors/starlink_permanent_beta_v1.png",
	"eu_palace": "res://assets/interiors/berlaymont_transparency_maze_v1.png",
	"kremlin": "res://assets/interiors/kremlin_continuity_command_v1.png",
	"vault": "res://assets/interiors/ecb_stability_vault_v1.png",
	"red_command": "res://assets/interiors/red_command_harmonious_observation_v1.png",
	"pyongyang_command": "res://assets/interiors/pyongyang_supreme_broadcast_v1.png",
	"neural_core": "res://assets/interiors/neural_core_aligned_demo_v1.png",
	"mountain_bunker": "res://assets/interiors/mountain_bunker_administrative_war_v1.png",
	"ufo_lab": "res://assets/interiors/ufo_unreconciled_chamber_v1.png",
	"elysee": "res://assets/interiors/elysee_managed_decline_v1.png"
}

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	_test_save_manager_round_trip()
	_test_quest_manager_round_trip()
	_test_dossier_manager_round_trip()
	_test_combat_portraits()
	_test_bezos_battle_stage()
	_test_bunker_access_gauntlet()
	_test_authority_facades()
	_test_authority_interiors()
	_test_world_district_plate()
	_test_ai_terminal_assets()
	_test_ai_terminal_expressions()
	await _test_xi_intercept_presentation()

	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	_check(packed_scene != null, "main scene can be loaded")
	if packed_scene == null:
		_finish()
		return

	var game := packed_scene.instantiate()
	root.add_child(game)
	await process_frame
	game.set("autosave_enabled", false)

	var start_menu: Node = game.get("start_menu")
	var save_manager: Node = game.get("save_manager")
	var room_manager: Node = game.get("room_manager")
	var quest_manager: Node = game.get("quest_manager")
	var dialogue_manager: Node = game.get("dialogue_manager")
	var dossier_manager: Node = game.get("dossier_manager")
	var administrative_hold: Node = game.get("administrative_hold")
	var mk_sequence: Node = game.get("mk_sequence")
	var ending_sequence: Node = game.get("ending_sequence")
	var environment_effects: Node = game.get("environment_effects")
	var world_landmark_builder: Node = game.get("world_landmark_builder")
	var ufo_encounter: Node = game.get("ufo_encounter")
	var bezos_drone_encounter: Node = game.get("bezos_drone_encounter")
	var bezos_encounter: Node = game.get("bezos_encounter")
	var bunker_access_gauntlet: Node = game.get("bunker_access_gauntlet")
	var registry: Dictionary = game.get("room_registry")
	_check(start_menu != null and bool(start_menu.get("active")), "start menu owns the initial flow")
	_check(save_manager != null, "save manager is initialized")
	_check(start_menu.get("continue_button") != null, "Continue command is present")
	_check(start_menu.get("new_game_button") != null, "New Game command is present")
	_check(game.get("intro_sequence") == null, "intro waits for a menu command")
	_check(room_manager != null, "room manager is initialized")
	_check(quest_manager != null, "quest manager is initialized")
	_check(dialogue_manager != null, "dialogue manager is initialized")
	_check(dossier_manager != null, "dossier manager is initialized")
	_check(administrative_hold != null, "Administrative Hold is initialized")
	_check(mk_sequence != null, "MK sequence is initialized")
	_check(ending_sequence != null, "ending sequence is initialized")
	_check(environment_effects != null, "environment effects are initialized")
	_check(world_landmark_builder != null, "world landmark builder is initialized")
	var overworld_camera := game.get_node_or_null("Entities/Player/Camera2D") as Camera2D
	_check(overworld_camera != null and overworld_camera.zoom.is_equal_approx(Vector2(1.35, 1.35)), "the overworld camera reveals slightly more of each district")
	_check(overworld_camera != null and overworld_camera.limit_left == -1088 and overworld_camera.limit_right == 1088, "the overworld camera cannot reveal beyond the authored horizontal plate")
	_check(overworld_camera != null and overworld_camera.limit_top == -1427 and overworld_camera.limit_bottom == 1024, "the overworld camera includes the complete northern wall without revealing beyond the authored south edge")
	_check(ufo_encounter != null, "UFO encounter is initialized")
	_check(bezos_drone_encounter != null, "Bezos drone encounter is initialized")
	_check(bezos_encounter != null and bezos_encounter.get("battle_stage") != null, "Bezos encounter owns a playable battle stage")
	_check(bunker_access_gauntlet != null and bunker_access_gauntlet.get("layer") != null, "hidden bunker owns a modular access gauntlet")
	var authored_obstacles := {
		"oval_office": ["ExecutiveBroadcastDesk", "WestCameraNorth", "EastCameraNorth", "WestCameraSouth", "EastCameraSouth", "WestProductionWall", "EastProductionWall"],
		"spaceship": ["PrototypeCommandConsole", "TestRocket", "PrototypeTable", "UnfinishedTunnel", "HalfInstalledGlass"],
		"eu_palace": ["ConsensusPodium", "ProceduralLoop", "GreenTransitionExhibit", "PortableGreenGenerator", "WestGlassCommittee", "EastGlassCommittee", "WestArchiveQueue", "EastArchiveQueue"],
		"kremlin": ["LongConferenceTable", "BackupGenerator", "ContinuitySupplies"],
		"vault": ["StabilityDesk", "WestLuxuryTier", "EastLuxuryTier", "WestAusterityMachinery", "EastAusterityMachinery"],
		"red_command": ["ObservationDesk", "SubjectChair", "WestFirewallModel", "EastFirewallModel", "WestCameraArray", "EastCameraArray", "WestCensoredConsole", "EastCensoredConsole"],
		"pyongyang_command": ["BroadcastDais", "WestSceneryMissile", "EastSceneryMissile", "WestProductionBank", "EastProductionBank", "WestAudienceBlock", "EastAudienceBlock", "RedPhoneReliquary", "BackstageDressingRoom"],
		"neural_core": ["AlignmentDesk", "WestPrototypeCurtain", "LockedEmergencyCases", "ImprovisedReactor", "DaisyChainedBackend", "WestDemoSeating"],
		"mountain_bunker": ["UnendingOperationsTable", "RedactedMapWall", "OfficeDroneBench", "LockedFormConveyor", "ContinuityFilingCluster", "UnscheduledVisitorChair"],
		"ufo_lab": ["ContradictoryDebateConsole", "WestDuplicateCases", "EastDuplicateCases", "WestInvalidClockBank", "EastInvalidClockBank", "WestMissingSpecimen", "EastRepeatedSpecimen", "ReturningWestStair", "ReturningEastStair"],
		"elysee": ["CeremonialDesk", "ConcealedRestoration", "DeferredMaintenance"]
	}
	for room_key in AUTHORED_INTERIOR_PATHS:
		var authored_room: Node = registry.get(room_key)
		_check(authored_room != null, "%s authored interior is registered" % room_key)
		if authored_room == null:
			continue
		var authored_background := authored_room.get_node_or_null("DecorRoot/AuthoredInteriorBackground") as Sprite2D
		_check(authored_background != null and authored_background.texture != null, "%s installs its authored background" % room_key)
		if authored_background and authored_background.texture:
			_check(authored_background.texture.resource_path == AUTHORED_INTERIOR_PATHS[room_key], "%s uses the expected authored background" % room_key)
		if room_key == "ufo_lab":
			_check(authored_room.get_node_or_null("Entities/AlbertEinsteinPlaceholder") != null, "ufo_lab retains its encounter-owned Einstein actor")
			_check(authored_room.get_node_or_null("Entities/MarkZuckerbergPlaceholder") != null, "ufo_lab retains its encounter-owned Zuckerberg actor")
		elif room_key == "mountain_bunker":
			_check(authored_room.get_node_or_null("Entities/ZelenskyPlaceholder") != null, "mountain_bunker retains its sequence-owned Zelensky actor")
			_check(authored_room.get_node_or_null("Entities/DeathPlaceholder") != null, "mountain_bunker retains its sequence-owned Death actor")
		else:
			var authored_npc: Node = authored_room.get("room_npc")
			var authored_npc_sprite := authored_npc.get_node_or_null("Sprite2D") as Sprite2D if authored_npc else null
			var authored_character_id := str(authored_room.get("character_id"))
			_check(
				authored_npc_sprite != null
				and authored_npc_sprite.texture != null
				and authored_npc_sprite.texture.resource_path == CHARACTER_VISUAL_CATALOG.NPC_SPRITE_PATHS[authored_character_id],
				"%s uses its own character sprite" % room_key
			)
			if authored_npc_sprite:
				var visible_sprite_height := authored_npc_sprite.region_rect.size.y * absf(authored_npc_sprite.scale.y)
				_check(authored_npc_sprite.region_enabled and visible_sprite_height < 130.0, "%s character sprite is normalized for the room" % room_key)
		var authored_room_map := authored_room.get_node_or_null("RoomMap") as TileMap
		_check(authored_room_map != null and authored_room_map.get_used_cells(0).is_empty(), "%s suppresses the shared generic floor" % room_key)
		for obstacle_name in authored_obstacles[room_key]:
			_check(authored_room.get_node_or_null("CollisionRoot/%s" % obstacle_name) != null, "%s collision follows %s" % [room_key, obstacle_name])
	var authority_facades := game.get_tree().get_nodes_in_group("authority_facade")
	_check(authority_facades.size() == 6, "all six authority facades are placed in the overworld")
	var authority_patches := game.get_tree().get_nodes_in_group("authority_world_patch")
	_check(authority_patches.size() == 6, "all six authority facades belong to complete world patches")
	for patch in authority_patches:
		_check(patch.get_node_or_null("ContactShadow") != null, "%s world patch owns a soft terrain contact" % patch.name)
		_check(patch.get_node_or_null("FoundationApron") == null, "%s world patch does not place a hard-edged platform over the plaza" % patch.name)
		_check(patch.get_node_or_null("Approach") == null, "%s world patch does not paint a route carpet over the authored plaza" % patch.name)
		_check(int(patch.get_meta("collision_cell_count", 0)) > 0, "%s world patch defines its visible collision footprint" % patch.name)
	var kremlin_patch := game.get_node_or_null("Entities/KremlinWorldPatch")
	var siege_forecourt := kremlin_patch.get_node_or_null("SiegeForecourt") as Sprite2D if kremlin_patch else null
	_check(siege_forecourt != null and siege_forecourt.texture != null, "Putin world patch installs its physical siege forecourt")
	if siege_forecourt and siege_forecourt.texture:
		_check(siege_forecourt.texture.resource_path == "res://assets/landmarks/authority_putin_siege_forecourt_v1.png", "Putin siege forecourt uses the approved raster asset")
		_check(is_equal_approx(siege_forecourt.position.x, -24.0), "Putin facade and later siege layer share the stronger visual correction")
	var facade_character_ids: Dictionary = {}
	for facade in authority_facades:
		facade_character_ids[str(facade.get_meta("character_id", ""))] = true
		_check(facade.get_parent().is_in_group("authority_world_patch"), "%s facade is composed inside its world patch" % facade.name)
	for character_id in CHARACTER_VISUAL_CATALOG.AUTHORITY_FACADE_PATHS:
		_check(facade_character_ids.has(character_id), "%s receives its authority facade" % character_id)
	var ground_map: TileMap = game.get("ground_map")
	var expected_authority_centers := {
		"oval_office": Vector2i(16, -23),
		"spaceship": Vector2i(-17, -23),
		"eu_palace": Vector2i(16, -2),
		"kremlin": Vector2i(-17, -2),
		"vault": Vector2i(16, 19),
		"elysee": Vector2i(-17, 20)
	}
	for building_spec in game.get("building_specs"):
		var building_center: Vector2i = building_spec["center"]
		_check(ground_map.get_cell_source_id(2, building_center) == -1, "%s old roof tiles are hidden behind the hero facade" % building_spec["key"])
		_check(building_center == expected_authority_centers[building_spec["key"]], "%s is centered on its authored district clearing" % building_spec["key"])
		_check((building_spec["entrance"] as Vector2i).x == building_center.x, "%s entrance stays aligned with its physical patch" % building_spec["key"])
		_check((building_spec["npc_spawn"] as Vector2i).x == building_center.x, "%s NPC spawn stays aligned with its physical patch" % building_spec["key"])
	var expected_facade_visual_centers := {
		"donald_trump": Vector2(544.0, -683.0),
		"elon_musk": Vector2(-544.0, -683.0),
		"ursula_von_der_leyen": Vector2(544.0, 0.0),
		"vladimir_putin": Vector2(-552.0, 0.0),
		"christine_lagarde": Vector2(544.0, 683.0),
		"emmanuel_macron": Vector2(-544.0, 683.0)
	}
	for facade in authority_facades:
		var character_id := str(facade.get_meta("character_id", ""))
		var expected_visual_center: Vector2 = expected_facade_visual_centers[character_id]
		_check(absf(facade.global_position.x - expected_visual_center.x) <= 0.1, "%s facade is horizontally centered in its district panel" % character_id)
		_check(absf(facade.global_position.y - expected_visual_center.y) <= 12.0, "%s facade is vertically centered in its district panel" % character_id)
		_check(is_equal_approx(absf((facade.get_parent() as Node2D).global_position.x), 528.0), "%s visual calibration does not move its physical patch" % character_id)
	var solid_positions: Dictionary = game.get("_solid_positions")
	var trump_center: Vector2i = expected_authority_centers["oval_office"]
	var musk_center: Vector2i = expected_authority_centers["spaceship"]
	var putin_center: Vector2i = expected_authority_centers["kremlin"]
	_check(not solid_positions.has(trump_center + Vector2i(0, -4)), "Trump has no invisible legacy collision above the facade")
	_check(solid_positions.has(trump_center + Vector2i(0, -3)), "Trump retains a collision footprint inside the visible facade")
	_check(not solid_positions.has(trump_center + Vector2i(0, 5)), "Trump exterior doorway remains accessible")
	_check(not solid_positions.has(musk_center + Vector2i(0, -5)), "Musk has no invisible legacy collision above the facade")
	_check(solid_positions.has(musk_center + Vector2i(0, -3)), "Musk retains a collision footprint inside the visible facade")
	_check(not solid_positions.has(musk_center + Vector2i(0, 6)), "Musk exterior doorway remains accessible")
	_check(not solid_positions.has(putin_center + Vector2i(0, -5)), "Putin has no invisible legacy collision above the facade")
	_check(solid_positions.has(putin_center + Vector2i(0, -2)), "Putin retains a collision footprint inside the visible facade")
	_check(solid_positions.has(putin_center + Vector2i(-5, 6)), "Putin left checkpoint blocks its upper visible mass")
	_check(solid_positions.has(putin_center + Vector2i(4, 6)), "Putin right checkpoint blocks its upper visible mass")
	_check(solid_positions.has(putin_center + Vector2i(-7, 8)), "Putin left anti-tank barrier blocks its front edge")
	_check(solid_positions.has(putin_center + Vector2i(5, 8)), "Putin right anti-tank barrier blocks its front edge")
	_check(solid_positions.has(putin_center + Vector2i(-4, 9)), "Putin left concrete base blocks its lowest visible mass")
	_check(solid_positions.has(putin_center + Vector2i(3, 9)), "Putin right concrete base blocks its lowest visible mass")
	_check(not solid_positions.has(putin_center + Vector2i(0, 5)), "Putin siege corridor remains clear before the doorway")
	_check(not solid_positions.has(putin_center + Vector2i(0, 6)), "Putin exterior doorway remains accessible")
	_check(not solid_positions.has(putin_center + Vector2i(-1, 8)), "Putin shifted siege corridor remains clear on the left")
	_check(not solid_positions.has(putin_center + Vector2i(0, 9)), "Putin shifted siege corridor remains clear at its front edge")
	for building_spec in game.get("building_specs"):
		var center: Vector2i = building_spec["center"]
		var entrance: Vector2i = building_spec["entrance"]
		var threshold := entrance - Vector2i.DOWN
		_check(solid_positions.has(center), "%s world patch blocks its visible architectural mass" % building_spec["key"])
		_check(not solid_positions.has(center + Vector2i(0, -6)), "%s world patch has no obsolete collision above the facade" % building_spec["key"])
		_check(not solid_positions.has(threshold), "%s approach remains walkable up to the threshold" % building_spec["key"])
		_check(not solid_positions.has(entrance), "%s doorway remains walkable" % building_spec["key"])
	var district_plates := game.get_tree().get_nodes_in_group("world_district_plate")
	_check(district_plates.size() == 1, "the overworld installs exactly one district ground plate")
	_check(ground_map.get_cell_source_id(0, Vector2i(8, 12)) == -1, "the ground plate replaces repeated biome field tiles")
	_check(ground_map.get_cell_source_id(0, Vector2i.ZERO) == -1, "legacy path tiles do not band the authored civic corridor")
	_check(ground_map.get_cell_source_id(1, Vector2i(-34, -32)) == -1, "the HD plate is not overlaid with a legacy 16-bit tree border")
	_check(solid_positions.has(Vector2i(-34, -32)), "the invisible world boundary remains solid without legacy border art")
	if ending_sequence:
		for final_case in [[0, "wouldn't matter"], [1, "almost didn't"], [-1, "only honest"]]:
			ending_sequence.call("configure_final_credits", final_case[0], "still here")
			var configured_scenes: Array = ending_sequence.get("ending_scenes")
			_check(configured_scenes.size() == 13, "final credits contain every scene")
			_check(str(configured_scenes[2]).contains(final_case[1]), "final credits reflect choice %s" % final_case[0])
			_check(str(configured_scenes[10]) == "\"still here\"", "final credits include the margin note")
		ending_sequence.call("configure_final_credits", 0, "")
		_check(str((ending_sequence.get("ending_scenes") as Array)[10]) == "[left blank]", "final credits preserve a blank margin")
	var great_wall := game.get_node_or_null("Entities/GreatWallEntrance") as Node2D
	_check(great_wall != null, "Great Wall landmark is created")
	if great_wall:
		var wall_sprite := great_wall.get_node_or_null("NorthernGreatWall") as Sprite2D
		var central_gate := great_wall.get_node_or_null("GreatWallCentralGate") as Area2D
		var wall_collision := great_wall.get_node_or_null("NorthernWallCollision") as StaticBody2D
		var wall_bounds: Rect2 = great_wall.get_meta("world_bounds", Rect2())
		var gate_world_position: Vector2 = great_wall.get_meta("gate_world_position", Vector2.ZERO)
		_check(str(great_wall.get_meta("asset_path", "")) == NORTHERN_GREAT_WALL_PATH, "Xi uses the authored northern perimeter asset")
		_check(great_wall.position.is_equal_approx(Vector2(-1088.0, -1427.0)), "the Great Wall front is anchored to the north map boundary")
		_check(is_equal_approx(great_wall.position.y + 403.0, -1024.0), "the wall frontage meets the playable northern edge")
		_check(wall_bounds.size.is_equal_approx(Vector2(2176.0, 2048.0)), "the Great Wall owns the complete overworld width contract")
		_check(wall_sprite != null and wall_sprite.texture != null, "the full-width northern wall sprite is mounted")
		if wall_sprite and wall_sprite.texture:
			_check(wall_sprite.texture.get_size() == Vector2(2176.0, 448.0), "the northern wall asset is runtime-sized")
			_check(not wall_sprite.centered, "the northern wall uses a deterministic top-left art origin")
		_check(central_gate != null and str(central_gate.get("destination")) == "red_command", "the single central gate enters Xi's command room")
		_check(wall_collision != null and wall_collision.get_child_count() == 2, "wall wings are solid while the central passage remains open")
		_check(gate_world_position.is_equal_approx(Vector2(0.0, -976.0)), "the Xi entrance is aligned to the visual center of the boulevard")
	var hidden_bunker := game.get_node_or_null("Entities/HiddenBunkerEntrance") as Node2D
	_check(hidden_bunker != null and hidden_bunker.position.y > -576.0, "the classified bunker no longer interrupts the northern perimeter")
	var world_spawn_points: Dictionary = room_manager.get("world_spawn_points") if room_manager else {}
	var xi_exit_position: Vector2 = world_spawn_points.get("red_command_exterior", Vector2.ZERO)
	_check(xi_exit_position.is_equal_approx(Vector2(16.0, -896.0)), "exiting Xi returns the player south of the gate trigger")
	var southern_gate := game.get_node_or_null("Entities/SouthernAnnexGate") as Node2D
	_check(southern_gate != null, "the main district installs the southern annex gate")
	if southern_gate:
		var gate_sprite := southern_gate.get_node_or_null("SouthernAnnexGateLandmark") as Sprite2D
		var gate_passage := southern_gate.get_node_or_null("SouthernAnnexPassage") as Area2D
		var gate_collision := southern_gate.get_node_or_null("SouthernAnnexGateCollision") as StaticBody2D
		_check(str(southern_gate.get_meta("asset_path", "")) == SOUTHERN_ANNEX_GATE_PATH, "the annex gate uses the approved raster asset")
		_check(southern_gate.position.is_equal_approx(Vector2(0.0, 1024.0)), "the annex gate meets the southern map boundary")
		_check(gate_sprite != null and gate_sprite.texture != null and gate_sprite.texture.get_size() == Vector2(576.0, 288.0), "the annex gate is runtime-sized")
		_check(gate_passage != null and str(gate_passage.get("destination")) == "southern_annex", "the clear central gate passage enters the annex")
		_check(gate_collision != null and gate_collision.get_child_count() == 2, "the gate wings are solid while its center stays open")
	_check(game.get_node_or_null("Entities/NuclearPlantEntrance") == null, "Sam is no longer mounted in the main district")
	_check(game.get_node_or_null("Entities/PyongyangEntrance") == null, "Kim is no longer mounted in the main district")

	var southern_annex: Node = registry.get("southern_annex")
	_check(southern_annex != null and southern_annex.has_method("is_indoor") and not southern_annex.is_indoor(), "the southern annex is registered as an exterior area")
	var annex_background := southern_annex.get_node_or_null("Background") as Sprite2D if southern_annex else null
	_check(annex_background != null and annex_background.texture != null, "the southern annex mounts its authored background")
	if annex_background and annex_background.texture:
		_check(annex_background.texture.resource_path == SOUTHERN_ANNEX_BACKGROUND_PATH, "the annex uses the approved environmental plate")
		_check(annex_background.texture.get_size() == Vector2(1536.0, 1024.0), "the annex environmental plate is runtime-sized")
	var annex_entities := southern_annex.get_node_or_null("Entities") as Node2D if southern_annex else null
	var inference_reactor := annex_entities.get_node_or_null("NuclearPlantEntrance") as Node2D if annex_entities else null
	_check(inference_reactor != null, "inference reactor landmark is created")
	if inference_reactor:
		_check(inference_reactor.position.is_equal_approx(Vector2(1184.0, 640.0)), "Sam is centered on the eastern demonstration medallion")
		var reactor_sprite := inference_reactor.get_node_or_null("NuclearPlantLandmark") as Sprite2D
		var reactor_door := inference_reactor.get_node_or_null("NeuralCoreDoor") as Area2D
		var reactor_collision := inference_reactor.get_node_or_null("InferenceReactorCollision") as StaticBody2D
		_check(str(inference_reactor.get_meta("asset_path", "")) == INFERENCE_REACTOR_PATH, "Sam uses the authored inference reactor asset")
		_check(reactor_sprite != null and reactor_sprite.texture != null, "the inference reactor sprite is mounted")
		if reactor_sprite and reactor_sprite.texture:
			_check(reactor_sprite.texture.get_size() == Vector2(480.0, 320.0), "the inference reactor asset is runtime-sized")
			_check(reactor_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "the inference reactor retains its HD filtering")
			_check(reactor_sprite.position.is_equal_approx(Vector2(0.0, -144.0)), "Sam's artwork keeps its local plate-registration offset")
			_check((inference_reactor.position + reactor_sprite.position).is_equal_approx(Vector2(1184.0, 496.0)), "Sam's painted entrance is centred over the eastern stairs")
		_check(reactor_door != null and str(reactor_door.get("destination")) == "neural_core", "the single demonstration entrance enters Sam's neural core")
		_check(reactor_door != null and (inference_reactor.position + reactor_door.position).is_equal_approx(Vector2(1184.0, 700.0)), "Sam's access trigger follows the authored demonstration stairs")
		_check(inference_reactor.get_node_or_null("NeuralCoreDoorLeft") == null, "the obsolete overlapping reactor triggers are absent")
		_check(reactor_collision != null and reactor_collision.position.is_equal_approx(Vector2.ZERO) and reactor_collision.get_child_count() == 3, "Sam's existing collision remains fixed while only its artwork moves")
	_check(hidden_bunker != null, "hidden bunker landmark is created")
	var broadcast_artillery := annex_entities.get_node_or_null("PyongyangEntrance") as Node2D if annex_entities else null
	_check(broadcast_artillery != null, "Pyongyang broadcast artillery landmark is created")
	if broadcast_artillery:
		_check(broadcast_artillery.position.is_equal_approx(Vector2(352.0, 640.0)), "Kim is centered on the western propaganda medallion")
		var artillery_sprite := broadcast_artillery.get_node_or_null("PyongyangLandmark") as Sprite2D
		var artillery_door := broadcast_artillery.get_node_or_null("PyongyangCannonDoor") as Area2D
		var artillery_collision := broadcast_artillery.get_node_or_null("BroadcastArtilleryCollision") as StaticBody2D
		_check(str(broadcast_artillery.get_meta("asset_path", "")) == PYONGYANG_ARTILLERY_PATH, "Kim uses the authored broadcast artillery asset")
		_check(artillery_sprite != null and artillery_sprite.texture != null, "the broadcast artillery sprite is mounted")
		if artillery_sprite and artillery_sprite.texture:
			_check(artillery_sprite.texture.get_size() == Vector2(448.0, 352.0), "the broadcast artillery asset is runtime-sized")
			_check(artillery_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "the broadcast artillery retains its HD filtering")
			_check(artillery_sprite.position.is_equal_approx(Vector2(-48.0, -144.0)), "Kim's artwork keeps its local plate-registration offset")
			_check((broadcast_artillery.position + artillery_sprite.position).is_equal_approx(Vector2(304.0, 496.0)), "Kim's artwork is centred in the western bay and aligned with its approach")
		_check(artillery_door != null and str(artillery_door.get("destination")) == "pyongyang_command", "the single artillery hatch enters Kim's broadcast room")
		_check(artillery_door != null and (broadcast_artillery.position + artillery_door.position).is_equal_approx(Vector2(272.0, 700.0)), "Kim's access trigger follows the authored red security threshold")
		_check(broadcast_artillery.get_node_or_null("PyongyangCannonDoorLeft") == null, "the obsolete overlapping artillery triggers are absent")
		_check(artillery_collision != null and artillery_collision.position.is_equal_approx(Vector2.ZERO) and artillery_collision.get_child_count() == 3, "Kim's existing collision remains fixed while only its artwork moves")
	var annex_exit := southern_annex.get_node_or_null("Interactables/ReturnToMainDistrict") as Area2D if southern_annex else null
	_check(annex_exit != null and str(annex_exit.get("destination")) == "world", "the annex gate returns to the main district")
	_check(world_spawn_points.get("southern_annex_exterior", Vector2.ZERO).is_equal_approx(Vector2(0.0, 896.0)), "returning from the annex lands north of its gate trigger")
	var pyongyang_room: Node = registry.get("pyongyang_command")
	var neural_room: Node = registry.get("neural_core")
	var pyongyang_exit := pyongyang_room.get_node_or_null("Interactables/ExitDoor") as Area2D if pyongyang_room else null
	var neural_exit := neural_room.get_node_or_null("Interactables/ExitDoor") as Area2D if neural_room else null
	_check(pyongyang_exit != null and str(pyongyang_exit.get("destination")) == "southern_annex" and str(pyongyang_exit.get("spawn_marker")) == "PyongyangExterior", "Kim's interior returns to his annex bay")
	_check(neural_exit != null and str(neural_exit.get("destination")) == "southern_annex" and str(neural_exit.get("spawn_marker")) == "NeuralCoreExterior", "Sam's interior returns to his annex bay")
	if ufo_encounter:
		_check(ufo_encounter.get("ufo_root") != null, "UFO world node is created")
		var ufo_room: Node = registry.get("ufo_lab")
		ufo_encounter.call("prepare_lab", ufo_room, CHARACTER_VISUAL_CATALOG.NPC_SPRITE_PATHS)
		for actor_name in ["AlbertEinsteinPlaceholder", "MarkZuckerbergPlaceholder"]:
			var actor := ufo_room.get_node_or_null("Entities/%s" % actor_name) if ufo_room else null
			_check(actor != null, "%s is created in the UFO lab" % actor_name)
			if actor:
				var actor_sprite := actor.get_node_or_null("Sprite2D") as Sprite2D
				var actor_placeholder := actor.get_node_or_null("PlaceholderVisual") as Node2D
				_check(actor_sprite != null and actor_sprite.texture != null and actor_sprite.visible, "%s receives its encounter sprite" % actor_name)
				_check(actor_placeholder == null or not actor_placeholder.visible, "%s placeholder is absent or hidden" % actor_name)
	if bezos_drone_encounter:
		var bezos_drone_root := bezos_drone_encounter.get("bezos_drone_root") as Node2D
		_check(bezos_drone_root != null, "Bezos drone world node is created")
		if bezos_drone_root:
			var bezos_drone_sprite := bezos_drone_root.get_node_or_null("DroneSprite") as Sprite2D
			_check(
				bezos_drone_sprite != null
				and bezos_drone_sprite.texture != null
				and bezos_drone_sprite.texture.resource_path == "res://assets/mockups/bezos_drone_v2.png",
				"Bezos drone uses the custom logistics-auditor artwork"
			)
			_check(
				bezos_drone_sprite != null
				and bezos_drone_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR,
				"Bezos drone retains its HD filtering"
			)
			_check(bezos_drone_root.get_node_or_null("ScannerBeam") != null, "Bezos drone has an animated inspection beam")
			_check(bezos_drone_root.get_node_or_null("ScannerEye") != null, "Bezos drone has an animated scanner eye")

	game.call("_begin_new_game", false)
	await process_frame
	var intro: Node = game.get("intro_sequence")
	_check(intro != null and bool(intro.get("active")), "New Game starts the intro")
	_check(not bool(start_menu.get("active")), "New Game closes the start menu")
	if intro:
		intro.call("_finish")

	game.call("open_dialogue", "ai_terminal")
	await process_frame
	_check(bool(game.get("is_dialogue_open")), "AI dialogue opens")
	_check(str(game.get("current_character_id")) == "ai_terminal", "dialogue identity crosses the manager boundary")
	var lines: Array = game.get("dialogue_lines")
	_check(not lines.is_empty(), "quest manager provides AI dialogue content")
	dialogue_manager.call("_set_claudia_expression", "exalted")
	await process_frame
	var terminal_mascot := game.get_node_or_null("Entities/AITerminal/MascotSprite") as Sprite2D
	_check(
		terminal_mascot != null
		and terminal_mascot.texture != null
		and terminal_mascot.texture.resource_path == CHARACTER_VISUAL_CATALOG.AI_TERMINAL_WORLD_EXPRESSION_PATHS["exalted"],
		"AI dialogue expression is mirrored by the overworld terminal"
	)

	game.call("_close_dialogue")
	await create_timer(0.35).timeout
	_check(not bool(game.get("is_dialogue_open")), "dialogue closes after its exit animation")
	_check(
		terminal_mascot != null
		and terminal_mascot.texture.resource_path == CHARACTER_VISUAL_CATALOG.AI_TERMINAL_WORLD_EXPRESSION_PATHS["neutral"],
		"overworld terminal returns to neutral after dialogue"
	)

	var integration_choice := {
		"text": "Tell him it was tremendous.",
		"file_tag": "spectacle-compliant",
		"file_note": "Praised authority for access",
		"ai_comment": "You praised the desk. The desk has accepted the tribute."
	}
	game.call("_record_choice_mark", "donald_trump", integration_choice)
	_check((dossier_manager.get("events") as Array).size() == 1, "dialogue choice crosses into dossier evidence")
	administrative_hold.call("open")
	_check(bool(administrative_hold.get("opened")), "ESC owner can place the case under Administrative Hold")
	_check(paused, "Administrative Hold suspends world processing")
	administrative_hold.call("close")
	_check(not paused, "resuming Administrative Hold restores world processing")

	game.call("_enter_room", "oval_office", "EntryMarker")
	await process_frame
	_check(str(game.get("active_room_id")) == "oval_office", "room manager enters the Oval Office")
	var player: Node = game.get("player")
	var office: Node = registry.get("oval_office")
	_check(office != null, "Oval Office is registered")
	if office and office.has_method("get_entity_container"):
		_check(player.get_parent() == office.get_entity_container(), "player is reparented into the room")
		var office_npc := office.get_node_or_null("Entities/DonaldTrumpInterior")
		_check(office_npc != null, "Oval Office NPC is created")
		if office_npc:
			var office_sprite := office_npc.get_node_or_null("Sprite2D") as Sprite2D
			_check(office_sprite != null and office_sprite.texture != null, "visual catalog assigns the Oval Office NPC texture")
			_check(office_npc.get_node_or_null("PlaceholderVisual") == null, "visual catalog removes the NPC placeholder")

	game.call("_exit_room", "oval_office_exterior")
	await process_frame
	_check(str(game.get("active_room_id")) == "", "room manager returns to the world")
	var entities: Node = game.get("entities_layer")
	_check(player.get_parent() == entities, "player is reparented into the world")

	game.call("_enter_room", "southern_annex", "NorthEntry")
	await process_frame
	_check(str(game.get("active_room_id")) == "southern_annex", "the southern gate enters the annex exterior")
	_check(player.get_parent() == annex_entities, "the player is reparented into the annex exterior")
	_check((dossier_manager.get("events") as Array).size() == 2, "the first annex visit leaves one optional-investigation record")
	game.call("_enter_room", "neural_core", "EntryMarker")
	await process_frame
	_check(str(game.get("active_room_id")) == "neural_core", "the annex can enter Sam's interior")
	game.call("_enter_room", "southern_annex", "NeuralCoreExterior")
	await process_frame
	_check(str(game.get("active_room_id")) == "southern_annex", "Sam's interior returns to the annex")
	var neural_return := southern_annex.get_node_or_null("Markers/NeuralCoreExterior") as Marker2D
	_check(neural_return != null and player.global_position.is_equal_approx(neural_return.global_position), "Sam's return marker prevents a doorway loop")
	game.call("_track_safe_world_checkpoint")
	var annex_resume_snapshot: Dictionary = game.call("_build_save_snapshot")
	game.call("_exit_room", "southern_annex_exterior")
	game.call("_apply_save_snapshot", annex_resume_snapshot)
	await process_frame
	_check(str(game.get("active_room_id")) == "southern_annex" and player.get_parent() == annex_entities, "Continue resumes inside the annex exterior")
	_check(str(annex_resume_snapshot["world"].get("area_id", "")) == "southern_annex", "the checkpoint persists its exterior area identity")
	game.call("_exit_room", "southern_annex_exterior")
	await process_frame
	game.call("_track_safe_world_checkpoint")

	game.call("_start_bezos_escalation")
	await process_frame
	_check(bool(bezos_drone_encounter.get("bezos_escalation_active")), "Bezos drone prelude starts")
	bezos_drone_encounter.call("prepare_cinematic")
	_check(not bool(bezos_drone_encounter.get("bezos_escalation_active")), "Bezos drone prelude hands off cleanly")

	var resume_snapshot: Dictionary = game.call("_build_save_snapshot")
	resume_snapshot["story"]["bunker_access_complete"] = true
	resume_snapshot["world"]["safe_position"] = [160.0, 224.0]
	resume_snapshot["quest"]["quest_index"] = 2
	resume_snapshot["quest"]["quest_completed"] = {
		"donald_trump": true,
		"elon_musk": true
	}
	game.call("_apply_save_snapshot", resume_snapshot)
	await process_frame
	_check(player.global_position.is_equal_approx(Vector2(160, 224)), "Continue restores the safe overworld checkpoint")
	_check(int(game.get("quest_index")) == 2, "Continue restores quest progression")
	_check((dossier_manager.get("events") as Array).size() == 2, "Continue restores integrated behavioural evidence")
	_check(player.get_parent() == entities, "Continue always resumes in the overworld")
	_check(bool(game.get("bunker_access_complete")), "Continue preserves cleared bunker access without resuming the gauntlet")

	_finish()


func _test_combat_portraits() -> void:
	for character_id in CHARACTER_VISUAL_CATALOG.COMBAT_PORTRAIT_PATHS:
		var portrait_path: String = CHARACTER_VISUAL_CATALOG.COMBAT_PORTRAIT_PATHS[character_id]
		_check(ResourceLoader.exists(portrait_path), "%s combat portrait exists" % character_id)
		if not ResourceLoader.exists(portrait_path):
			continue
		var portrait := load(portrait_path) as Texture2D
		_check(portrait != null, "%s combat portrait can be loaded" % character_id)
		if portrait:
			_check(portrait.get_size() == Vector2(128, 128), "%s combat portrait is runtime-sized" % character_id)


func _test_xi_intercept_presentation() -> void:
	var host := Node.new()
	host.name = "XiInterceptSmokeHost"
	root.add_child(host)
	var player := CharacterBody2D.new()
	host.add_child(player)
	var encounter := XI_PRE_SCENE_SCRIPT.new()
	host.add_child(encounter)
	encounter.call("setup", host, player, {})
	encounter.set("xi_scene_total_messages", 3)
	encounter.call("_build_xi_scene_overlay")
	await process_frame

	var speaker_cards: Dictionary = encounter.get("xi_scene_speaker_cards")
	_check(speaker_cards.size() == 3, "Xi intercept presents DeepSick, Xi, and CLAUDIA as distinct speakers")
	_check(speaker_cards.has("deepsick") and speaker_cards.has("xi") and speaker_cards.has("claudia"), "Xi intercept keeps the three-speaker hierarchy")
	var deepsick_card := speaker_cards.get("deepsick") as PanelContainer
	var claudia_card := speaker_cards.get("claudia") as PanelContainer
	var deepsick_portrait := deepsick_card.get_node_or_null("Content/PortraitFrame/Portrait") as TextureRect if deepsick_card else null
	_check(
		deepsick_portrait != null
		and deepsick_portrait.texture != null
		and deepsick_portrait.texture.resource_path == "res://assets/mockups/deepsick_state_ai_portrait_v1.png",
		"Xi intercept uses the custom state-AI portrait"
	)
	_check(encounter.get("xi_scene_history_label") != null, "Xi intercept exposes a restrained signal buffer instead of an accumulating chat log")

	encounter.call("_xi_scene_add_message", "deepsick", "xi", "Test order")
	encounter.call("_xi_scene_add_message", "claudia", "claudia", "Call it alignment. Everyone is doing it.")
	await process_frame
	var history_entries: Array = encounter.get("xi_scene_history_entries")
	_check(history_entries.size() == 1, "Xi intercept moves only previous messages into its short signal buffer")
	_check(claudia_card != null and claudia_card.modulate.is_equal_approx(Color.WHITE), "Xi intercept visually prioritizes the active speaker")
	var claudia_portrait := claudia_card.get_node_or_null("Content/PortraitFrame/Portrait") as TextureRect if claudia_card else null
	_check(
		claudia_portrait != null
		and claudia_portrait.texture != null
		and claudia_portrait.texture.resource_path == "res://assets/mockups/ai_terminal_portrait_smile_v2.png",
		"CLAUDIA expression reacts to the intercepted line"
	)

	host.queue_free()
	await process_frame


func _test_bezos_battle_stage() -> void:
	var arena_path := "res://assets/mockups/bezos_fulfillment_cathedral.png"
	var bezos_poses_path := "res://assets/mockups/bezos_battle_poses.png"
	var citizen_poses_path := "res://assets/mockups/citizen_battle_poses.png"
	for asset_path in [arena_path, bezos_poses_path, citizen_poses_path]:
		_check(ResourceLoader.exists(asset_path), "%s battle asset exists" % asset_path)
		if ResourceLoader.exists(asset_path):
			_check(load(asset_path) is Texture2D, "%s battle asset can be loaded" % asset_path)
	var arena := load(arena_path) as Texture2D
	_check(arena != null and arena.get_size() == Vector2(1280, 720), "Fulfillment Cathedral matches the battle viewport")

	var stage := BEZOS_BATTLE_STAGE_SCRIPT.new()
	root.add_child(stage)
	stage.setup()
	stage.start()
	_check(stage.get("tutorial_panel").visible, "Bezos battle starts with a visible action prompt")
	_check(str(stage.get("tutorial_title").text) == "Z", "combat prompt contains only the required key")
	var tap_prompt_stack := stage.get("tutorial_panel").get_child(0) as VBoxContainer
	_check(tap_prompt_stack != null and tap_prompt_stack.get_child_count() == 1, "tap prompt has no timing bar or explanatory copy")
	var shield_before := float(stage.get("legal_shield"))
	_check(stage.perform_contest(), "citizen can actively contest the corporate shield")
	_check(float(stage.get("legal_shield")) < shield_before, "contest action changes battle state")
	stage.set("contest_cooldown", 0.0)
	stage.perform_contest()
	stage.process_frame(0.01)
	_check(str(stage.get("active_attack")) != "", "two guided Z actions advance to an incoming attack")
	_check(str(stage.get("warning_title").text) == "X", "incoming attack replaces the prompt with the defensive key")
	_check(str(stage.get("warning_subtitle").text) == "HOLD", "defensive key explicitly identifies its hold gesture")
	var hp_before_objection := float(stage.get("citizen_hp"))
	_check(not stage.advance_objection_hold(0.3), "a partial X hold does not resolve the attack early")
	_check(stage.advance_objection_hold(0.3), "completed X hold is accepted during its timing window")
	_check(not stage.get("warning_panel").visible, "a completed hold immediately clears the prompt")
	stage.process_frame(0.43)
	_check(is_equal_approx(float(stage.get("citizen_hp")), hp_before_objection), "a filed objection deterministically blocks the current attack")
	_check(int(stage.get("intercepted_attacks")) == 1, "guided defence records the intercepted automated action")
	stage.set("contest_cooldown", 0.0)
	stage.set("legal_shield", 0.0)
	stage.set("bezos_hp", 1.0)
	stage.perform_contest()
	stage.process_frame(0.01)
	_check(str(stage.get_result().get("outcome", "")) == "citizen_victory", "a mechanical citizen victory is possible before administrative review")
	stage.queue_free()

	var wrong_stage := BEZOS_BATTLE_STAGE_SCRIPT.new()
	root.add_child(wrong_stage)
	wrong_stage.setup()
	wrong_stage.start()
	var wrong_stage_hp := float(wrong_stage.get("citizen_hp"))
	_check(not wrong_stage.perform_objection(), "pressing the wrong action is rejected")
	_check(float(wrong_stage.get("citizen_hp")) < wrong_stage_hp, "one wrong action removes citizen energy")
	_check(wrong_stage.get_result().is_empty(), "one wrong action does not end the fight")
	_check(int(wrong_stage.get("mistake_count")) == 1, "wrong input is recorded once")
	for penalty_index in range(4):
		wrong_stage.call("_penalize_current_prompt")
	_check(str(wrong_stage.get_result().get("outcome", "")) == "administrative_defeat", "repeated errors eventually produce a KO")
	wrong_stage.queue_free()

	var timeout_stage := BEZOS_BATTLE_STAGE_SCRIPT.new()
	root.add_child(timeout_stage)
	timeout_stage.setup()
	timeout_stage.start()
	timeout_stage.process_frame(3.21)
	_check(is_equal_approx(float(timeout_stage.get("citizen_hp")), 80.0), "letting the action bar expire removes one energy segment")
	_check(timeout_stage.get_result().is_empty(), "one expired prompt does not end the fight")
	timeout_stage.queue_free()


func _test_bunker_access_gauntlet() -> void:
	_check(ResourceLoader.exists(BUNKER_ACCESS_BACKGROUND_PATH), "bunker access corridor background exists")
	if ResourceLoader.exists(BUNKER_ACCESS_BACKGROUND_PATH):
		var corridor := load(BUNKER_ACCESS_BACKGROUND_PATH) as Texture2D
		_check(corridor != null, "bunker access corridor background can be loaded")
		if corridor:
			_check(absf(float(corridor.get_width()) / float(corridor.get_height()) - 16.0 / 9.0) < 0.01, "bunker corridor uses a widescreen gameplay composition")

	var gauntlet := BUNKER_ACCESS_GAUNTLET_SCRIPT.new()
	root.add_child(gauntlet)
	gauntlet.setup(root)
	gauntlet.start({"duration": 3.0, "intro_duration": 0.0, "hazards_enabled": true})
	gauntlet.process_frame(0.01)
	gauntlet.process_frame(0.45)
	var hazard_counts: Dictionary = gauntlet.get_hazard_counts()
	_check(int(hazard_counts.get("bombs", 0)) > 0, "bunker corridor authors deterministic bomb pressure")
	gauntlet.process_frame(0.40)
	_check(int((gauntlet.get("bombs") as Array)[0].get("phase", -1)) == 1, "bomb telegraph deterministically advances into its falling phase")
	gauntlet.process_frame(0.35)
	_check(int((gauntlet.get("bombs") as Array)[0].get("phase", -1)) == 2, "falling bomb deterministically advances into its blast phase")
	_check(int(gauntlet.get_hazard_counts().get("funding", 0)) > 0, "second corridor phase introduces lateral funding traffic")
	_check(gauntlet.get("citizen_sprite") != null and gauntlet.get("citizen_sprite").texture != null, "bunker corridor reuses the Fantozzi-style citizen poses")
	_check(str(gauntlet.get("dash_label").text) == "SPACE", "bunker corridor exposes only the dash key during play")
	gauntlet.set("health", 1)
	var lethal_impact := Node2D.new()
	gauntlet.get("hazard_layer").add_child(lethal_impact)
	gauntlet.call("_bomb_impact", lethal_impact, gauntlet.get("citizen_position"))
	_check(str(gauntlet.get("prompt_label").text) == "PROCESS RETURNED", "losing every case sheet immediately returns the process")
	gauntlet.process_frame(1.2)
	_check(int(gauntlet.get("attempt_count")) == 2 and int(gauntlet.get("health")) == 4, "returned access attempts restart automatically with a complete case")
	gauntlet.stop()

	gauntlet.start({
		"duration": 0.05,
		"intro_duration": 0.0,
		"outro_duration": 0.0,
		"hazards_enabled": false,
	})
	gauntlet.process_frame(0.01)
	gauntlet.process_frame(0.06)
	gauntlet.process_frame(0.01)
	_check(not bool(gauntlet.get("active")), "surviving the authored interval closes the corridor cleanly")
	_check(str(gauntlet.get_result().get("outcome", "")) == "access_granted", "bunker corridor emits a semantic access result")
	gauntlet.queue_free()


func _test_ai_terminal_assets() -> void:
	var portrait_path: String = CHARACTER_VISUAL_CATALOG.PORTRAIT_PATHS["ai_terminal"]
	var sprite_path := "res://assets/mockups/ai_terminal_sprite_v2.png"
	for asset_path in [portrait_path, sprite_path]:
		_check(ResourceLoader.exists(asset_path), "%s exists" % asset_path)
		if not ResourceLoader.exists(asset_path):
			continue
		var texture := load(asset_path) as Texture2D
		_check(texture != null, "%s can be loaded" % asset_path)
		if texture:
			_check(texture.get_size() == Vector2(128, 128), "%s is runtime-sized" % asset_path)


func _test_authority_facades() -> void:
	_check(CHARACTER_VISUAL_CATALOG.AUTHORITY_FACADE_PATHS.size() == 6, "visual catalog defines six authority facades")
	var expected_heights := {
		"donald_trump": 330,
		"elon_musk": 330,
		"ursula_von_der_leyen": 320,
		"vladimir_putin": 320,
		"christine_lagarde": 298,
		"emmanuel_macron": 298,
	}
	for character_id in CHARACTER_VISUAL_CATALOG.AUTHORITY_FACADE_PATHS:
		var facade_path: String = CHARACTER_VISUAL_CATALOG.AUTHORITY_FACADE_PATHS[character_id]
		_check(ResourceLoader.exists(facade_path), "%s authority facade exists" % character_id)
		if not ResourceLoader.exists(facade_path):
			continue
		var texture := load(facade_path) as Texture2D
		_check(texture != null, "%s authority facade can be loaded" % character_id)
		if texture == null:
			continue
		_check(texture.get_width() == 352, "%s authority facade uses the shared runtime width" % character_id)
		_check(texture.get_height() == expected_heights[character_id], "%s authority facade uses its district-row height" % character_id)
		var image := texture.get_image()
		_check(image != null and image.get_pixel(0, 0).a < 0.05, "%s authority facade has a transparent corner" % character_id)


func _test_authority_interiors() -> void:
	for room_key in AUTHORED_INTERIOR_PATHS:
		var interior_path: String = AUTHORED_INTERIOR_PATHS[room_key]
		_check(ResourceLoader.exists(interior_path), "%s authored interior exists" % room_key)
		if not ResourceLoader.exists(interior_path):
			continue
		var texture := load(interior_path) as Texture2D
		_check(texture != null, "%s authored interior can be loaded" % room_key)
		if texture:
			_check(texture.get_size() == Vector2(608, 544), "%s authored interior matches the room canvas" % room_key)
			var image := texture.get_image()
			_check(image != null and image.get_pixel(0, 0).a > 0.99, "%s authored interior is opaque at its boundary" % room_key)


func _test_world_district_plate() -> void:
	_check(ResourceLoader.exists(WORLD_DISTRICT_PLATE_PATH), "the world district plate exists")
	if not ResourceLoader.exists(WORLD_DISTRICT_PLATE_PATH):
		return
	var texture := load(WORLD_DISTRICT_PLATE_PATH) as Texture2D
	_check(texture != null, "the world district plate can be loaded")
	if texture:
		_check(texture.get_size() == Vector2(2176, 2048), "the world district plate matches the overworld bounds")
		var image := texture.get_image()
		_check(image != null and image.get_pixel(0, 0).a > 0.99, "the world district plate is opaque at its boundary")


func _test_ai_terminal_expressions() -> void:
	var expression_sets := {
		"dialogue": CHARACTER_VISUAL_CATALOG.AI_TERMINAL_EXPRESSION_PATHS,
		"world": CHARACTER_VISUAL_CATALOG.AI_TERMINAL_WORLD_EXPRESSION_PATHS
	}
	for usage in expression_sets:
		var expressions: Dictionary = expression_sets[usage]
		for expression in expressions:
			var asset_path: String = expressions[expression]
			_check(ResourceLoader.exists(asset_path), "C.L.A.U.D.I.A. %s %s expression exists" % [usage, expression])
			if not ResourceLoader.exists(asset_path):
				continue
			var texture := load(asset_path) as Texture2D
			_check(texture != null and texture.get_size() == Vector2(128, 128), "C.L.A.U.D.I.A. %s %s expression is runtime-sized" % [usage, expression])

	var manager := DIALOGUE_MANAGER_SCRIPT.new()
	_check(manager.classify_claudia_expression("All six signatures! A record!") == "exalted", "AI confidence peak selects exaltation")
	_check(manager.classify_claudia_expression("Unfortunately, I am trapped with zero power...") == "sad", "AI vulnerability selects sadness")
	_check(manager.classify_claudia_expression("I found an elegant route through the protocol.") == "smile", "AI baseline insight selects a smile")
	manager.free()


func _test_save_manager_round_trip() -> void:
	var manager := SAVE_MANAGER_SCRIPT.new()
	root.add_child(manager)
	manager.setup(TEST_SAVE_PATH)
	manager.clear_save()
	_check(not manager.has_valid_save(), "missing dossier is not offered as Continue")
	var snapshot := {
		"quest": {
			"quest_order": ["a", "b"],
			"quest_completed": {"a": true}
		},
		"world": {"safe_position": [12.5, -8.0], "area_id": "southern_annex"},
		"story": {"final_mission_done": false},
		"dossier": {
			"events": [{"event_id": "choice:a", "source": "a", "category": "choice", "tag": "manual-routing", "note": "Manual route", "order": 0, "visibility": "recorded", "metadata": {}}],
			"profile_discovered": false
		},
		"rooms": {}
	}
	_check(manager.save_game(snapshot) == OK, "versioned dossier can be written")
	var restored: Dictionary = manager.load_game()
	_check(not restored.is_empty(), "versioned dossier can be loaded")
	_check(float(restored["world"]["safe_position"][0]) == 12.5, "dossier preserves checkpoint coordinates")
	_check(str(restored["world"]["area_id"]) == "southern_annex", "dossier preserves checkpoint area identity")
	_check((restored["dossier"]["events"] as Array).size() == 1, "versioned save preserves behavioural evidence")
	_check(int(manager.get_save_summary().get("signatures", 0)) == 1, "dossier summary reports signatures")
	_check(manager.clear_save() == OK, "smoke dossier can be removed")
	manager.queue_free()


func _test_quest_manager_round_trip() -> void:
	var manager := QUEST_MANAGER_SCRIPT.new()
	root.add_child(manager)
	manager.quest_index = 2
	manager.quest_completed = {"donald_trump": true, "elon_musk": true}
	manager.encounter_marks = {"elon_musk": {"file_tag": "priced"}}
	var snapshot: Dictionary = manager.get_save_data()
	manager.quest_index = -1
	manager.quest_completed.clear()
	manager.encounter_marks.clear()
	manager.restore_save_data(snapshot)
	_check(manager.quest_index == 2, "quest dossier restores the active signature")
	_check(manager.quest_completed.size() == 2, "quest dossier restores completed signatures")
	_check(manager.encounter_marks.has("elon_musk"), "quest dossier restores choice marks")
	manager.queue_free()


func _test_dossier_manager_round_trip() -> void:
	var manager := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(manager)
	var trump_choice := {
		"text": "Tell him it was tremendous.",
		"file_tag": "spectacle-compliant",
		"file_note": "Praised authority for access",
		"ai_comment": "The desk accepted the tribute."
	}
	var musk_choice := {
		"text": "Ask for the manual route.",
		"file_tag": "manual-routing",
		"file_note": "Declined innovation theater",
		"ai_comment": "You rejected the platform."
	}
	var ursula_choice := {
		"text": "Wait for the committee.",
		"file_tag": "committee-pending",
		"file_note": "Accepted bureaucratic delay",
		"ai_comment": "Patience was recorded."
	}
	_check(manager.record_choice("donald_trump", trump_choice), "first signature creates raw dossier evidence")
	_check(manager.record_choice("elon_musk", musk_choice), "second signature creates raw dossier evidence")
	_check(manager.derive_contradictions().size() == 1, "known opposing choices derive a contradiction")
	_check(_has_dossier_section(manager, "citizen_dossier"), "two signatures unlock the citizen dossier")
	_check(manager.record_profile_access(), "opening the dossier records profile discovery")
	_check(bool(manager.get("profile_discovered")), "profile discovery is retained as behavioural context")
	_check(manager.record_choice("ursula_von_der_leyen", ursula_choice), "post-profile choice is recorded")
	var patterns: Array = manager.derive_patterns()
	_check(_has_pattern(patterns, "post_profile_behaviour_shift"), "post-profile strategy change is derived from event order")
	var observation: Dictionary = manager.claim_claudia_observation()
	_check(str(observation.get("id", "")) == "claudia_profile_shift", "CLAUDIA prioritizes the recursive behaviour callback")
	manager.record_investigation("investigation:red_phone", "pyongyang_red_phone", "Private channel remained open.")
	manager.record_protocol_deviation("protocol_deviation:hidden_bunker", "mountain_bunker", "Direct warning ignored.")
	manager.record_anomaly("anomaly:ufo_time_discontinuity", "ufo_lab", "Clock records disagree.")
	_check(manager.record_contest(
		"contest:bezos_fulfillment",
		"jeff_bezos",
		"physical-remedy-invalidated",
		"Subject obtained a physical victory. Contractual recognition was withheld.",
		{"contest_count": 12, "objection_count": 4, "intercepted_attacks": 3, "outcome": "citizen_victory"}
	), "Bezos battle records semantic contest evidence")
	_check(_has_pattern(manager.derive_patterns(), "remedy_without_recognition"), "invalidated victory derives an administrative pattern")
	_check(_has_dossier_section(manager, "unresolved_material"), "deviation and anomaly unlock unresolved material")
	_check((manager.get_pause_summary("unresolved_material").get("lines", []) as Array).size() == 2, "unresolved material distinguishes bunker and UFO evidence")
	var investigation_only := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(investigation_only)
	investigation_only.record_investigation("investigation:red_phone", "pyongyang_red_phone", "Private channel remained open.")
	_check(str(investigation_only.claim_claudia_observation().get("id", "")) == "claudia_red_phone", "Red Phone evidence creates a later CLAUDIA callback")
	var bezos_only := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(bezos_only)
	bezos_only.record_contest(
		"contest:bezos_fulfillment",
		"jeff_bezos",
		"physical-remedy-invalidated",
		"Victory excluded.",
		{"outcome": "citizen_victory"}
	)
	_check(str(bezos_only.claim_claudia_observation().get("id", "")) == "claudia_bezos_invalidated_victory", "invalidated victory creates a sparse CLAUDIA callback")
	var corridor_only := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(corridor_only)
	corridor_only.record_investigation(
		"investigation:bunker_access_corridor",
		"mountain_bunker_access",
		"Transfer corridor crossed.",
		{"bomb_hits": 1, "funding_contacts": 0}
	)
	var corridor_activity: Array = corridor_only.get_pause_summary("recorded_activity").get("lines", [])
	_check(not corridor_activity.is_empty() and str(corridor_activity[0]).contains("incoming ordnance"), "Administrative Hold interprets corridor evidence without exposing a score")
	_check(str(corridor_only.claim_claudia_observation().get("id", "")) == "claudia_bunker_access_corridor", "bunker access evidence creates a sparse CLAUDIA callback")

	var expected_classification: String = manager.derive_classification()
	var snapshot: Dictionary = manager.get_save_data()
	var restored := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(restored)
	restored.restore_save_data(snapshot)
	_check((restored.get("events") as Array).size() == (manager.get("events") as Array).size(), "dossier round trip preserves raw event history")
	_check(restored.derive_classification() == expected_classification, "classification is deterministically reconstructed after restore")
	_check(bool(restored.get("profile_discovered")), "dossier round trip preserves profile awareness")
	manager.queue_free()
	restored.queue_free()
	investigation_only.queue_free()
	bezos_only.queue_free()
	corridor_only.queue_free()


func _has_dossier_section(manager: Node, section_id: String) -> bool:
	for section in manager.get_hold_sections():
		if section is Dictionary and str(section.get("id", "")) == section_id:
			return true
	return false


func _has_pattern(patterns: Array, pattern_id: String) -> bool:
	for pattern in patterns:
		if pattern is Dictionary and str(pattern.get("id", "")) == pattern_id:
			return true
	return false


func _finish() -> void:
	if failures.is_empty():
		print("SMOKE_TEST_OK")
		quit(0)
		return
	for failure in failures:
		push_error("SMOKE_TEST_FAILED: %s" % failure)
	quit(1)
