extends SceneTree

const CHARACTER_VISUAL_CATALOG = preload("res://scripts/data/character_visual_catalog.gd")
const DIALOGUE_MANAGER_SCRIPT = preload("res://scripts/managers/dialogue_manager.gd")
const QUEST_MANAGER_SCRIPT = preload("res://scripts/managers/quest_manager.gd")
const SAVE_MANAGER_SCRIPT = preload("res://scripts/managers/save_manager.gd")
const DOSSIER_MANAGER_SCRIPT = preload("res://scripts/managers/dossier_manager.gd")
const BEZOS_BATTLE_STAGE_SCRIPT = preload("res://scripts/encounters/bezos_battle_stage.gd")
const BUNKER_ACCESS_GAUNTLET_SCRIPT = preload("res://scripts/encounters/bunker_access_gauntlet.gd")
const GREATEST_DEAL_SCRIPT = preload("res://scripts/encounters/greatest_deal.gd")
const CONSENSUS_ENGINE_SCRIPT = preload("res://scripts/encounters/consensus_engine.gd")
const PRICE_STABILITY_PINBALL_SCRIPT = preload("res://scripts/encounters/price_stability_pinball.gd")
const PUTIN_SPECIAL_OPERATION_SCRIPT = preload("res://scripts/encounters/putin_special_operation.gd")
const UFO_OBSERVATION_PROBLEM_SCRIPT = preload("res://scripts/encounters/ufo_observation_problem.gd")
const XI_PRE_SCENE_SCRIPT = preload("res://scripts/encounters/xi_pre_scene.gd")
const NEWS_BROADCAST_SEQUENCE_SCRIPT = preload("res://scripts/sequences/news_broadcast_sequence.gd")
const TOUCH_CONTROL_LAYER_SCRIPT = preload("res://scripts/managers/touch_control_layer.gd")

const TEST_SAVE_PATH := "user://civic_nightmare_smoke_dossier.json"
const WORLD_DISTRICT_PLATE_PATH := "res://assets/backgrounds/world_district_plate_v3.png"
const NORTHERN_GREAT_WALL_PATH := "res://assets/landmarks/northern_great_wall_v1.png"
const INFERENCE_REACTOR_PATH := "res://assets/landmarks/inference_reactor_demo_v1.png"
const PYONGYANG_ARTILLERY_PATH := "res://assets/landmarks/pyongyang_broadcast_artillery_v1.png"
const SOUTHERN_ANNEX_GATE_PATH := "res://assets/landmarks/southern_annex_gate_v1.png"
const WESTERN_AID_DISTRICT_PATCH_PATH := "res://assets/backgrounds/western_aid_district_patch_v1.png"
const WESTERN_AID_BARRIER_PATH := "res://assets/landmarks/western_aid_gate_barrier_v1.png"
const SOUTHERN_ANNEX_BACKGROUND_PATH := "res://assets/backgrounds/southern_administrative_annex_v1.png"
const BUNKER_ACCESS_BACKGROUND_PATH := "res://assets/encounters/bunker_aid_corridor_v1.png"
const GREATEST_DEAL_BACKGROUND_PATH := "res://assets/encounters/greatest_deal_stage_v1.png"
const GREATEST_DEAL_MUSIC_PATH := "res://assets/audio/civic_nightmare_greatest_deal_snake_eyes.ogg"
const CONSENSUS_ENGINE_BACKGROUND_PATH := "res://assets/encounters/consensus_engine_stage_v1.png"
const PRICE_STABILITY_PINBALL_BACKGROUND_PATH := "res://assets/encounters/price_stability_pinball_stage_v1.png"
const PRICE_STABILITY_PINBALL_MUSIC_PATH := "res://assets/audio/civic_nightmare_price_stability_jackpot_jive.ogg"
const OVERWORLD_MUSIC_PATH := "res://assets/audio/civic_nightmare_overworld_dead_mans_hand.ogg"
const PUTIN_OPERATION_ASSET_PATHS := [
	"res://assets/encounters/putin_operation/matryoshka_security_unit_v1.png",
	"res://assets/encounters/putin_operation/mobilization_copier_v1.png",
	"res://assets/encounters/putin_operation/state_television_camera_v1.png",
	"res://assets/encounters/putin_operation/strategic_bear_washer_boss_v1.png",
	"res://assets/encounters/putin_operation/diplomatic_note_launcher_centered_v2.png",
]
const HISTORICAL_CONTAMINATION_SPRITE_PATH := "res://assets/sprites/npc_contamination_v2.png"
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


class TouchReceiver:
	extends Node
	var control_state: Dictionary = {}

	func set_touch_control(control_id: String, pressed: bool) -> void:
		control_state[control_id] = pressed


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
	_test_touch_control_layer()
	_test_greatest_deal()
	_test_consensus_engine()
	_test_price_stability_pinball()
	_test_putin_special_operation()
	_test_ufo_observation_problem()
	_test_authority_facades()
	_test_authority_interiors()
	_test_world_district_plate()
	_test_ai_terminal_assets()
	_test_ai_terminal_expressions()
	_test_historical_contamination_asset()
	_test_news_broadcast_sequence()
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
	var ufo_observation_problem: Node = game.get("ufo_observation_problem")
	var bezos_drone_encounter: Node = game.get("bezos_drone_encounter")
	var bezos_encounter: Node = game.get("bezos_encounter")
	var bunker_access_gauntlet: Node = game.get("bunker_access_gauntlet")
	var greatest_deal: Node = game.get("greatest_deal")
	var consensus_engine: Node = game.get("consensus_engine")
	var price_stability_pinball: Node = game.get("price_stability_pinball")
	var putin_special_operation: Node = game.get("putin_special_operation")
	var touch_controls: Node = game.get("touch_controls")
	var contamination_root: Node = game.get("contamination_root")
	var registry: Dictionary = game.get("room_registry")
	_check(start_menu != null and bool(start_menu.get("active")), "start menu owns the initial flow")
	_check(save_manager != null, "save manager is initialized")
	_check(start_menu.get("continue_button") != null, "Continue command is present")
	_check(start_menu.get("new_game_button") != null, "New Game command is present")
	_check(game.get("news_broadcast_sequence") == null, "news broadcast waits for a menu command")
	_check(game.get("intro_sequence") == null, "opening drive waits behind the menu and broadcast")
	_check(room_manager != null, "room manager is initialized")
	_check(quest_manager != null, "quest manager is initialized")
	_check(dialogue_manager != null, "dialogue manager is initialized")
	_check(dossier_manager != null, "dossier manager is initialized")
	_check(administrative_hold != null, "Administrative Hold is initialized")
	var route_label := game.get_node_or_null("Entities/AITerminal/CaseRouteLabel") as Label
	_check(route_label != null and not route_label.visible, "behavioural routing exists in-world but stays hidden before evidence accumulates")
	var vault_room: Node = registry.get("vault")
	if vault_room and vault_room.has_method("apply_administrative_context"):
		vault_room.apply_administrative_context({
			"subtitle": "SECURITY NOTE: CAUTION RETAINED",
			"notice": "COST REVIEW\nLANGUAGE ALREADY ADJUSTED",
			"npc_posture": "precleared",
		})
		var routing_notice := vault_room.get_node_or_null("Entities/AdministrativeRoutingNotice") as Label
		var routed_clerk := vault_room.get("room_npc") as Node
		_check(routing_notice != null and routing_notice.visible, "a dossier route becomes a physical room notice")
		_check(str(vault_room.get_room_subtitle()).contains("CAUTION RETAINED"), "a dossier route changes room presentation")
		_check(routed_clerk != null and str((routed_clerk.get("indicator_label") as Label).text) == "·", "a dossier route changes clerk posture without branching the encounter")
		vault_room.apply_administrative_context({})
	_check(contamination_root != null, "historical contamination apparition is initialized")
	if contamination_root:
		var contamination_sprite := contamination_root.get_node_or_null("Sprite") as Sprite2D
		_check(contamination_sprite != null and contamination_sprite.texture != null, "historical contamination apparition mounts its authored sprite")
		if contamination_sprite and contamination_sprite.texture:
			_check(contamination_sprite.texture.resource_path == HISTORICAL_CONTAMINATION_SPRITE_PATH, "historical contamination uses the corrected face variant")
	_check(mk_sequence != null, "MK sequence is initialized")
	_check(ending_sequence != null, "ending sequence is initialized")
	_check(environment_effects != null, "environment effects are initialized")
	_check(ResourceLoader.exists(OVERWORLD_MUSIC_PATH), "Dead Man's Hand overworld delivery exists")
	var world_music := environment_effects.get("world_music_player") as AudioStreamPlayer
	var world_music_stream := world_music.stream as AudioStreamOggVorbis if world_music else null
	_check(str(environment_effects.call("get_world_music_asset_path")) == OVERWORLD_MUSIC_PATH, "environment effects exposes the approved overworld music path")
	_check(world_music_stream != null and world_music_stream.get_length() >= 168.8 and world_music_stream.get_length() <= 169.2, "the browser-ready overworld edit loads at its verified duration")
	_check(world_music_stream != null and world_music_stream.loop and is_equal_approx(world_music_stream.loop_offset, 25.75), "the first play keeps its intro while later loops resume after the baked crossfade")
	_check(world_music != null and not world_music.playing and environment_effects.process_mode == Node.PROCESS_MODE_ALWAYS, "the title keeps overworld music silent while its fade owner remains pause-safe")
	environment_effects.call("set_world_music_context", true, false)
	environment_effects.call("_update_world_music_mix", 2.0)
	_check(world_music != null and world_music.playing and is_equal_approx(world_music.volume_db, -12.5), "free roam starts Dead Man's Hand at the restrained world mix")
	if world_music:
		world_music.seek(42.0)
	environment_effects.call("set_world_music_context", true, true)
	environment_effects.call("_update_world_music_mix", 1.0)
	_check(world_music != null and is_equal_approx(world_music.volume_db, -20.0), "dialogue context ducks rather than restarts the overworld theme")
	environment_effects.call("set_world_music_context", false, false)
	environment_effects.call("_update_world_music_mix", 2.0)
	_check(world_music != null and not world_music.playing and float(environment_effects.get("world_music_resume_position")) > 30.0, "interior context fades out and retains the overworld playback position")
	start_menu.set("active", false)
	game.set("active_room_id", "southern_annex")
	game.call("_update_world_music_context")
	_check(bool(environment_effects.get("world_music_requested")), "the non-indoor Southern Annex continues the world theme")
	game.set("active_room_id", "oval_office")
	game.call("_update_world_music_context")
	_check(not bool(environment_effects.get("world_music_requested")), "an authored interior requests a music fade without resetting the track")
	game.set("active_room_id", "")
	start_menu.set("active", true)
	game.call("_update_world_music_context")
	_check(world_landmark_builder != null, "world landmark builder is initialized")
	var overworld_camera := game.get_node_or_null("Entities/Player/Camera2D") as Camera2D
	_check(overworld_camera != null and overworld_camera.zoom.is_equal_approx(Vector2(1.35, 1.35)), "the overworld camera reveals slightly more of each district")
	_check(overworld_camera != null and overworld_camera.limit_left == -1088 and overworld_camera.limit_right == 1088, "the overworld camera cannot reveal beyond the authored horizontal plate")
	_check(overworld_camera != null and overworld_camera.limit_top == -1427 and overworld_camera.limit_bottom == 1024, "the overworld camera includes the complete northern wall without revealing beyond the authored south edge")
	var player_node := game.get_node_or_null("Entities/Player") as CharacterBody2D
	var initial_player_position := player_node.global_position if player_node else Vector2.ZERO
	if player_node and overworld_camera:
		player_node.global_position = Vector2(0.0, -930.0)
		game.call("_update_northern_wall_camera", 0.5)
		_check(is_equal_approx(overworld_camera.position.y, -150.0), "approaching the northern gate raises the real gameplay framing to reveal its monument")
		player_node.global_position = initial_player_position
		game.call("_update_northern_wall_camera", 0.5)
		_check(overworld_camera.position.is_zero_approx(), "leaving the northern approach restores the neutral overworld framing")
	_check(ufo_encounter != null, "UFO encounter is initialized")
	_check(ufo_observation_problem != null, "UFO Observation Problem is initialized behind the overworld encounter")
	_check(bezos_drone_encounter != null, "Bezos drone encounter is initialized")
	_check(bezos_encounter != null and bezos_encounter.get("battle_stage") != null, "Bezos encounter owns a playable battle stage")
	_check(bunker_access_gauntlet != null and bunker_access_gauntlet.get("layer") != null, "hidden bunker owns a modular access gauntlet")
	_check(greatest_deal != null and greatest_deal.get("layer") != null, "Trump's entrance owns the Greatest Deal procedure")
	_check(consensus_engine != null and consensus_engine.get("layer") != null, "Ursula's entrance owns the Consensus Engine procedure")
	_check(price_stability_pinball != null and price_stability_pinball.get("layer") != null, "Lagarde's entrance owns the Price Stability procedure")
	_check(putin_special_operation != null and putin_special_operation.get("layer") != null, "Putin's entrance owns the Special Administrative Operation")
	_check(touch_controls != null and touch_controls.get("layer") != null, "the main composition mounts one contextual touch-control layer")
	var trump_access_lines: Array = game.call("_authority_access_intro_lines", "donald_trump")
	var ursula_access_lines: Array = game.call("_authority_access_intro_lines", "ursula_von_der_leyen")
	var lagarde_access_lines: Array = game.call("_authority_access_intro_lines", "christine_lagarde")
	var putin_access_lines: Array = game.call("_authority_access_intro_lines", "vladimir_putin")
	_check(trump_access_lines.size() == 1 and str(trump_access_lines[0]).contains("reserve the right to have won"), "Trump introduces his game with one character-specific card")
	_check(ursula_access_lines.size() == 1 and str(ursula_access_lines[0]).contains("same form"), "Ursula introduces her game with one character-specific card")
	_check(lagarde_access_lines.size() == 1 and str(lagarde_access_lines[0]).contains("stabilize the economy"), "Lagarde introduces her game with one character-specific card")
	_check(putin_access_lines.size() == 1 and str(putin_access_lines[0]).contains("defensive perimeter"), "Putin introduces his corridor with one character-specific card")
	game.call("_start_greatest_deal")
	_check(bool(game.get("is_dialogue_open")) and str(game.get("authority_access_intro_pending")) == "greatest_deal", "Trump's entrance opens the card before the table")
	_check(not bool(greatest_deal.get("active")) and str(dialogue_manager.get("current_character_id")) == "donald_trump", "Trump's game waits behind his portrait card")
	game.call("_finish_dialogue")
	await _wait_for_authority_launch(game, greatest_deal)
	_check(bool(greatest_deal.get("active")), "closing Trump's card launches the existing game")
	greatest_deal.stop()
	game.call("_start_consensus_engine")
	_check(bool(game.get("is_dialogue_open")) and str(game.get("authority_access_intro_pending")) == "consensus_engine", "Ursula's entrance opens the card before the machine")
	_check(not bool(consensus_engine.get("active")) and str(dialogue_manager.get("current_character_id")) == "ursula_von_der_leyen", "Ursula's game waits behind her portrait card")
	game.call("_finish_dialogue")
	await _wait_for_authority_launch(game, consensus_engine)
	_check(bool(consensus_engine.get("active")), "closing Ursula's card launches the existing game")
	consensus_engine.stop()
	game.call("_start_price_stability_pinball")
	_check(bool(game.get("is_dialogue_open")) and str(game.get("authority_access_intro_pending")) == "price_stability_pinball", "Lagarde's entrance opens the card before the monetary table")
	_check(not bool(price_stability_pinball.get("active")) and str(dialogue_manager.get("current_character_id")) == "christine_lagarde", "Lagarde's game waits behind her portrait card")
	game.call("_finish_dialogue")
	await _wait_for_authority_launch(game, price_stability_pinball)
	_check(bool(price_stability_pinball.get("active")), "closing Lagarde's card launches the monetary pinball")
	price_stability_pinball.stop()
	game.call("_start_putin_special_operation")
	_check(bool(game.get("is_dialogue_open")) and str(game.get("authority_access_intro_pending")) == "putin_special_operation", "Putin's entrance opens the card before the defensive corridor")
	_check(not bool(putin_special_operation.get("active")) and str(dialogue_manager.get("current_character_id")) == "vladimir_putin", "Putin's operation waits behind his portrait card")
	game.call("_finish_dialogue")
	await _wait_for_authority_launch(game, putin_special_operation)
	_check(bool(putin_special_operation.get("active")), "closing Putin's card launches the pseudo-3D operation")
	putin_special_operation.stop()
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
	_check(hidden_bunker != null, "the western aid gate is created")
	if hidden_bunker:
		var aid_district_patch := hidden_bunker.get_node_or_null("WesternAidDistrictPatch") as Sprite2D
		var aid_gate_passage := hidden_bunker.get_node_or_null("HiddenBunkerDoor") as Area2D
		var aid_gate_collision := hidden_bunker.get_node_or_null("WesternAidGateCollision") as StaticBody2D
		var aid_gate_shutter := hidden_bunker.get_node_or_null("AidGateShutter") as Node2D
		var aid_gate_barrier := hidden_bunker.get_node_or_null("AidGateShutter/AidGateBarrierProp") as Sprite2D
		var aid_gate_shutter_shape := hidden_bunker.get_node_or_null("AidGateShutterCollision/CollisionShape2D") as CollisionShape2D
		var aid_passage_world_position: Vector2 = hidden_bunker.get_meta("passage_world_position", Vector2.ZERO)
		_check(str(hidden_bunker.get_meta("asset_path", "")) == WESTERN_AID_DISTRICT_PATCH_PATH, "the bunker route uses the environment-integrated western district patch")
		_check(hidden_bunker.position.is_equal_approx(Vector2(-1088.0, -336.0)), "the aid gate is anchored to the western map boundary and road")
		_check(aid_passage_world_position.is_equal_approx(Vector2(-888.0, -336.0)), "the aid passage follows the existing horizontal road")
		_check(aid_district_patch != null and aid_district_patch.texture != null and aid_district_patch.texture.get_size() == Vector2(560.0, 700.0), "the aid gate mounts its authored background patch")
		_check(aid_district_patch != null and not aid_district_patch.centered and aid_district_patch.position.is_equal_approx(Vector2(0.0, -348.0)), "the aid patch replaces the exact western plate crop")
		_check(aid_district_patch != null and not aid_district_patch.z_as_relative and aid_district_patch.z_index == -9, "the aid patch renders with the district below the player")
		_check(hidden_bunker.get_node_or_null("WesternAidGateLandmark") == null, "the pasted-on transparent landmark is no longer mounted")
		_check(aid_gate_passage != null and str(aid_gate_passage.get("destination")) == "mountain_bunker", "the aid gate preserves the bunker destination")
		_check(aid_gate_collision != null and aid_gate_collision.get_child_count() == 2, "the aid gate has solid upper and lower wings around its road")
		_check(aid_gate_shutter != null and aid_gate_shutter.visible, "the aid barrier begins sealed before the corridor is cleared")
		_check(aid_gate_barrier != null and aid_gate_barrier.texture != null and aid_gate_barrier.texture.resource_path == WESTERN_AID_BARRIER_PATH, "the sealed gate uses its authored mechanical barrier prop")
		_check(aid_gate_shutter_shape != null and not aid_gate_shutter_shape.disabled, "the sealed aid barrier blocks crossing the western boundary")
	var world_spawn_points: Dictionary = room_manager.get("world_spawn_points") if room_manager else {}
	var xi_exit_position: Vector2 = world_spawn_points.get("red_command_exterior", Vector2.ZERO)
	_check(xi_exit_position.is_equal_approx(Vector2(16.0, -896.0)), "exiting Xi returns the player south of the gate trigger")
	var bunker_exit_position: Vector2 = world_spawn_points.get("mountain_bunker_exterior", Vector2.ZERO)
	_check(bunker_exit_position.is_equal_approx(Vector2(-728.0, -336.0)), "leaving the bunker returns east of the aid gate trigger")
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
	var news_broadcast: Node = game.get("news_broadcast_sequence")
	_check(news_broadcast != null and bool(news_broadcast.get("active")), "New Game starts the skippable news broadcast")
	_check(game.get("intro_sequence") == null, "Opening drive waits until the broadcast finishes or is skipped")
	_check(not bool(start_menu.get("active")), "New Game closes the start menu")
	if news_broadcast:
		var broadcast_skip_hint := news_broadcast.get("skip_hint") as Label
		_check(broadcast_skip_hint != null and broadcast_skip_hint.text.contains("SKIP BROADCAST"), "Only the news prologue advertises a skip command")
		var broadcast_skip := InputEventAction.new()
		broadcast_skip.action = "ui_accept"
		broadcast_skip.pressed = true
		Input.parse_input_event(broadcast_skip)
		news_broadcast.call("request_skip")
		news_broadcast.call("process_frame", 0.5)
		_check(not bool(news_broadcast.get("active")), "Accept input skips the news broadcast")
		var broadcast_skip_release := InputEventAction.new()
		broadcast_skip_release.action = "ui_accept"
		broadcast_skip_release.pressed = false
		Input.parse_input_event(broadcast_skip_release)
	await process_frame
	var intro: Node = game.get("intro_sequence")
	_check(intro != null and bool(intro.get("active")), "Skipping the broadcast hands off to the mandatory opening drive")
	if intro:
		var opening_background := intro.get("background") as TextureRect
		var opening_car := intro.get("car_sprite") as Sprite2D
		_check(
			opening_background != null
			and opening_background.texture != null
			and opening_background.texture.resource_path == "res://assets/sequences/opening_drive_sunset_v2.png",
			"Opening drive mounts its authored sunset highway"
		)
		_check(
			opening_car != null
			and opening_car.texture != null
			and opening_car.texture.resource_path == "res://assets/sequences/opening_drive_car_v1.png",
			"Opening drive mounts the battered citizen vehicle"
		)
		_check((intro.get("road_markers") as Array).size() == 24, "Opening drive owns a perspective road-marker field")
		_check((intro.get("shoulder_segments") as Array).size() == 36, "Opening drive owns alternating arcade shoulder segments")
		_check((intro.get("edge_streaks") as Array).size() == 28, "Opening drive owns roadside speed motion")
		var drive_controls := intro.get("control_hint") as Label
		_check(drive_controls != null and not drive_controls.text.contains("SKIP"), "Opening drive is mandatory gameplay, not a skippable cinematic")
		var skip_attempt := InputEventAction.new()
		skip_attempt.action = "ui_accept"
		skip_attempt.pressed = true
		Input.parse_input_event(skip_attempt)
		intro.call("process_frame", 0.01)
		_check(bool(intro.get("active")), "Accept input cannot skip the mandatory opening drive")
		var skip_release := InputEventAction.new()
		skip_release.action = "ui_accept"
		skip_release.pressed = false
		Input.parse_input_event(skip_release)
		var opening_music_path := str(intro.call("get_music_asset_path"))
		_check(
			opening_music_path == "res://assets/audio/civic_nightmare_opening_drive.ogg",
			"Opening drive exposes the approved runtime-music path"
		)
		_check(ResourceLoader.exists(opening_music_path), "Opening-drive music is present and importable")
		var opening_music_player := intro.get("music_player") as AudioStreamPlayer
		_check(
			opening_music_player != null
			and opening_music_player.stream != null
			and opening_music_player.stream.get_length() >= 87.5
			and opening_music_player.stream.get_length() <= 90.5,
			"Opening-drive music resolves inside the authored arrival window"
		)
		_check(is_equal_approx(float(intro.call("get_sequence_duration")), 89.8), "Opening drive keeps its authored 80-90 second duration")
		var opening_set_piece_assets := intro.call("get_set_piece_asset_paths") as PackedStringArray
		_check(opening_set_piece_assets.size() == 4, "Opening drive declares its four authored physical set-piece assets")
		for set_piece_asset_path in opening_set_piece_assets:
			_check(ResourceLoader.exists(set_piece_asset_path), "Opening set-piece asset is importable: %s" % set_piece_asset_path)
		intro.set("elapsed", 31.9)
		intro.call("process_frame", 0.2)
		_check((intro.get("signs") as Array).size() == 2, "Opening drive schedules contradictory civic road signs without crowding its set pieces")
		_check((intro.get("hazards") as Array).size() == 1, "Opening drive schedules physical road deterioration without crowding its set pieces")
		var spawned_opening_set_pieces := intro.get("spawned_set_piece_ids") as Array
		_check(spawned_opening_set_pieces == ["ceremony"], "The pothole inauguration is the first authored road set piece")
		var opening_set_piece_root := intro.get("set_piece_root") as Node2D
		_check(
			opening_set_piece_root != null
			and opening_set_piece_root.get_node_or_null("Ceremony/PotholeInauguration") != null,
			"Pothole inauguration mounts its authored transparent scene"
		)
		var road_surface := intro.get("road_surface") as Polygon2D
		_check(road_surface != null and road_surface.polygon.size() == 38, "Opening drive rebuilds a curved perspective road surface")
		intro.set("elapsed", 87.9)
		intro.call("process_frame", 0.2)
		_check(
			spawned_opening_set_pieces == ["ceremony", "motorcade", "tollbooth", "checkpoint"],
			"Opening drive reaches privilege, procedure, and failed-checkpoint set pieces in order"
		)
		_check(
			opening_set_piece_root.get_node_or_null("Motorcade/InstitutionalMotorcade") != null
			and opening_set_piece_root.get_node_or_null("Tollbooth/MobileAdministrativeTollbooth") != null
			and opening_set_piece_root.get_node_or_null("Checkpoint/DecayedAdministrativeCheckpoint") != null
			and opening_set_piece_root.get_node_or_null("Checkpoint/RustFailedBarrierPivot") != null,
			"Every later set piece owns its expected world object"
		)
		_check(bool(intro.get("engine_dead")), "Citizen vehicle dies after the heroic musical window")
		var arrival_panel := intro.get("arrival_panel") as Control
		_check(arrival_panel != null and arrival_panel.visible, "Administrative arrival resolves before the game begins")
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
	game.call("_show_bunker_caption", "DEATH", "Audio channel verification.")
	await process_frame
	var sequence_bip := dialogue_manager.get("sequence_bip") as AudioStreamPlayer
	_check(sequence_bip != null and sequence_bip.stream != null, "cinematic dialogue owns an audible sequence channel")
	_check(str(dialogue_manager.get("active_sequence_voice")) == "death", "Death's bunker caption selects its distinct low voice")
	game.call("_hide_bunker_caption")
	await create_timer(0.25).timeout
	_check(str(dialogue_manager.get("active_sequence_voice")) == "", "closing a bunker caption stops its sequence voice")

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
		game.call("_update_northern_wall_camera", 0.1)
		_check(
			overworld_camera != null
			and is_equal_approx(overworld_camera.global_position.x, office.global_position.x)
			and overworld_camera.global_position.y > office.global_position.y
			and overworld_camera.global_position.y <= office.global_position.y + 80.0,
			"an authored interior tracks down within a strict limit to keep its entrance visible"
		)
		player.global_position = office.global_position
		game.call("_update_northern_wall_camera", 0.1)
		_check(
			overworld_camera != null
			and overworld_camera.global_position.is_equal_approx(office.global_position),
			"approaching the authority returns the camera to the central room composition"
		)
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
	_check(overworld_camera != null and overworld_camera.position.is_zero_approx(), "leaving an interior restores the player-follow camera")
	var entities: Node = game.get("entities_layer")
	_check(player.get_parent() == entities, "player is reparented into the world")

	game.call("use_door", "red_command", "EntryMarker")
	await create_timer(0.5).timeout
	var xi_door_encounter: Node = game.get("xi_pre_scene_encounter")
	_check(str(game.get("active_room_id")) == "red_command", "the northern gate enters Xi's command room")
	_check(xi_door_encounter != null and bool(xi_door_encounter.get("xi_pre_scene_active")), "Xi intercept claims control during the door transition")
	_check(not player.is_physics_processing(), "the door transition cannot restore movement while Xi's intercept is active")
	_check(not player.is_processing_unhandled_input(), "Xi intercept suppresses gameplay interaction input")
	if xi_door_encounter:
		xi_door_encounter.call("request_skip")
	await create_timer(1.0).timeout
	_check(xi_door_encounter != null and not bool(xi_door_encounter.get("xi_pre_scene_active")), "closing Xi's intercept releases its active state")
	_check(player.is_physics_processing(), "closing Xi's intercept restores movement after the real door flow")
	_check(player.is_processing_unhandled_input(), "closing Xi's intercept restores interaction on the following frame")
	game.call("use_door", "world", "red_command_exterior")
	await create_timer(0.5).timeout
	_check(str(game.get("active_room_id")) == "", "the player can leave Xi's command room after the intercept")
	_check(player.get_parent() == entities, "Xi's exit returns the released player to the world")

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
	dossier_manager.record_anomaly(
		"anomaly:ufo_time_discontinuity",
		"ufo_observation_chamber",
		"Three observations accepted for one citizen.",
		{"concurrent_subject_count": 3, "registered_citizen_count": 1, "reconciliation": "postponed"}
	)
	game.set("ufo_observation_complete", true)

	var resume_snapshot: Dictionary = game.call("_build_save_snapshot")
	resume_snapshot["story"]["bunker_access_complete"] = true
	resume_snapshot["story"]["trump_deal_complete"] = true
	resume_snapshot["story"]["ursula_consensus_complete"] = true
	resume_snapshot["story"]["lagarde_price_stability_complete"] = true
	resume_snapshot["story"]["putin_special_operation_complete"] = true
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
	_check((dossier_manager.get("events") as Array).size() == 3, "Continue restores integrated behavioural evidence")
	_check(player.get_parent() == entities, "Continue always resumes in the overworld")
	_check(bool(game.get("bunker_access_complete")), "Continue preserves cleared bunker access without resuming the gauntlet")
	_check(bool(game.get("trump_deal_complete")), "Continue preserves Greatest Deal access clearance")
	_check(bool(game.get("ursula_consensus_complete")), "Continue preserves Consensus Engine access clearance")
	_check(bool(game.get("lagarde_price_stability_complete")), "Continue preserves Price Stability access clearance")
	_check(bool(game.get("putin_special_operation_complete")), "Continue preserves Putin access clearance without resuming the operation")
	_check(bool(game.get("ufo_observation_complete")), "Continue preserves the completed UFO identity procedure")
	var legacy_access_snapshot := resume_snapshot.duplicate(true)
	legacy_access_snapshot["story"].erase("trump_deal_complete")
	legacy_access_snapshot["story"].erase("ursula_consensus_complete")
	legacy_access_snapshot["story"].erase("lagarde_price_stability_complete")
	legacy_access_snapshot["story"].erase("putin_special_operation_complete")
	legacy_access_snapshot["story"].erase("ufo_observation_complete")
	legacy_access_snapshot["quest"]["quest_completed"]["ursula_von_der_leyen"] = true
	legacy_access_snapshot["quest"]["quest_completed"]["christine_lagarde"] = true
	legacy_access_snapshot["quest"]["quest_completed"]["vladimir_putin"] = true
	game.call("_apply_save_snapshot", legacy_access_snapshot)
	await process_frame
	_check(bool(game.get("trump_deal_complete")) and bool(game.get("ursula_consensus_complete")) and bool(game.get("lagarde_price_stability_complete")) and bool(game.get("putin_special_operation_complete")), "older dossiers infer access clearance from signatures already obtained")
	_check(bool(game.get("ufo_observation_complete")), "older dossiers infer UFO clearance from the raw anomaly event")
	if hidden_bunker:
		var restored_shutter := hidden_bunker.get_node_or_null("AidGateShutter") as Node2D
		var restored_shutter_shape := hidden_bunker.get_node_or_null("AidGateShutterCollision/CollisionShape2D") as CollisionShape2D
		_check(not restored_shutter.visible and restored_shutter_shape.disabled, "Continue restores the cleared physical aid gate")
		_check(hidden_bunker.get_node_or_null("AidGateClearedBeacon") == null, "the cleared gate no longer leaves a floating status marker")

	_finish()


func _test_news_broadcast_sequence() -> void:
	var host := Node.new()
	root.add_child(host)
	var preview_player := CharacterBody2D.new()
	host.add_child(preview_player)
	var broadcast: Node = NEWS_BROADCAST_SEQUENCE_SCRIPT.new()
	host.add_child(broadcast)
	var finish_count := [0]
	broadcast.finished.connect(func() -> void: finish_count[0] += 1)
	broadcast.setup(host, preview_player)
	_check(bool(broadcast.get("active")), "Standalone news broadcast starts active")
	_check(is_equal_approx(float(broadcast.call("get_duration")), 21.5), "News broadcast remains a short 20-25 second prologue")
	_check(bool(broadcast.call("is_skippable")), "News broadcast explicitly owns the opening skip contract")
	_check(not preview_player.is_physics_processing(), "News broadcast freezes overworld movement")
	var headline := broadcast.get("headline_label") as Label
	var ticker := broadcast.get("ticker_label") as Label
	_check(headline != null and ticker != null, "News broadcast mounts headline and ticker presentation")
	broadcast.set("elapsed", 21.4)
	broadcast.call("process_frame", 0.2)
	_check(not bool(broadcast.get("active")) and int(finish_count[0]) == 1, "News broadcast completes naturally and emits one handoff")
	host.queue_free()


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
	var requested_audio_voices: Array[String] = []
	encounter.dialogue_audio_requested.connect(func(_text: String, voice: String) -> void:
		requested_audio_voices.append(voice)
	)
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
	_check(requested_audio_voices == ["xi", "claudia"], "Xi intercept requests a distinct audible voice for every active speaker")
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

	var release_host := Node.new()
	release_host.name = "XiReleaseSmokeHost"
	root.add_child(release_host)
	var release_player := CharacterBody2D.new()
	release_host.add_child(release_player)
	var release_encounter := XI_PRE_SCENE_SCRIPT.new()
	release_host.add_child(release_encounter)
	release_encounter.call("setup", release_host, release_player, {
		"xi_jinping": {
			"xi_pre_scene": [
				{
					"channel": "deepsick",
					"from": "xi",
					"text": "Release-control test.",
					"hold": 0.0
				}
			]
		}
	})
	release_encounter.call("start", "red_command", null)
	await create_timer(2.7).timeout
	_check(not bool(release_encounter.get("xi_pre_scene_active")), "Xi intercept automatically releases its active state after the final beat")
	_check(bool(release_encounter.get("xi_pre_scene_seen")), "Xi intercept records completion after automatic release")
	_check(release_player.is_physics_processing(), "Xi intercept always restores player movement after completion")
	release_host.queue_free()
	await process_frame


func _test_bezos_battle_stage() -> void:
	var arena_path := "res://assets/mockups/bezos_fulfillment_cathedral.png"
	var bezos_poses_path := "res://assets/mockups/bezos_battle_poses.png"
	var citizen_poses_path := "res://assets/mockups/citizen_battle_poses.png"
	var music_path := "res://assets/audio/civic_nightmare_bezos_goofy_arcade_steel_strike.ogg"
	for asset_path in [arena_path, bezos_poses_path, citizen_poses_path]:
		_check(ResourceLoader.exists(asset_path), "%s battle asset exists" % asset_path)
		if ResourceLoader.exists(asset_path):
			_check(load(asset_path) is Texture2D, "%s battle asset can be loaded" % asset_path)
	var arena := load(arena_path) as Texture2D
	_check(arena != null and arena.get_size() == Vector2(1280, 720), "Fulfillment Cathedral matches the battle viewport")
	_check(ResourceLoader.exists(music_path), "Bezos battle soundtrack exists")
	if ResourceLoader.exists(music_path):
		_check(load(music_path) is AudioStreamOggVorbis, "Bezos battle soundtrack can be loaded")

	var stage := BEZOS_BATTLE_STAGE_SCRIPT.new()
	root.add_child(stage)
	stage.setup()
	stage.start_music_preview()
	_check(stage.get("music_player").playing, "Bezos soundtrack starts during the pre-fight presentation")
	stage.start()
	var round_maxima: Dictionary = stage.get_round_maxima()
	_check(is_equal_approx(float(round_maxima.get("legal_shield", 0.0)), 56.0), "Bezos round retains a substantial legal-shield phase")
	_check(is_equal_approx(float(round_maxima.get("bezos_hp", 0.0)), 96.0), "Bezos round durability supports the intended encounter length")
	_check(stage.get("music_player").playing, "Bezos combat preserves the soundtrack started by the intro")
	_check(stage.get("shield_hit_audio").stream != null, "legal shield has dedicated impact audio")
	_check(stage.get("body_hit_audio").stream != null, "Bezos body has dedicated impact audio")
	_check(float(stage.get("body_hit_audio").volume_db) > float(stage.get("music_player").volume_db), "combat impact audio remains louder than music")
	_check(int(stage.get("round_number")) == 1, "Bezos battle starts on round one")
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
	_check(stage.get_result().is_empty(), "winning one round does not prematurely resolve a best-of-three match")
	_check(int(stage.get("citizen_round_wins")) == 1, "first citizen KO records one round")
	_check(bool(stage.get("round_transition_active")), "first round victory opens a short arcade transition")
	stage.process_frame(1.7)
	_check(int(stage.get("round_number")) == 2, "round transition advances to round two")
	stage.set("contest_cooldown", 0.0)
	stage.set("legal_shield", 0.0)
	stage.set("bezos_hp", 1.0)
	stage.perform_contest()
	stage.process_frame(0.01)
	var victory_result: Dictionary = stage.get_result()
	_check(str(victory_result.get("outcome", "")) == "citizen_victory", "two won rounds produce a mechanical citizen victory before administrative review")
	_check(int(victory_result.get("citizen_round_wins", 0)) == 2, "citizen must claim two rounds")
	_check(int(victory_result.get("rounds_played", 0)) == 2, "a straight victory ends after two rounds")
	_check(not stage.get("music_player").playing, "Bezos battle music stops when the match resolves")
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
	_check(wrong_stage.get_result().is_empty(), "one lost round does not end the best-of-three match")
	_check(int(wrong_stage.get("bezos_round_wins")) == 1, "five errors award Bezos one round")
	wrong_stage.process_frame(1.7)
	for penalty_index in range(5):
		wrong_stage.call("_penalize_current_prompt")
	var defeat_result: Dictionary = wrong_stage.get_result()
	_check(str(defeat_result.get("outcome", "")) == "administrative_defeat", "two lost rounds produce an administrative defeat")
	_check(int(defeat_result.get("bezos_round_wins", 0)) == 2, "Bezos must claim two rounds")
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


func _test_ufo_observation_problem() -> void:
	var observation := UFO_OBSERVATION_PROBLEM_SCRIPT.new()
	root.add_child(observation)
	observation.setup(root)
	observation.start({
		"intro_duration": 0.0,
		"transition_duration": 0.0,
		"collapse_duration": 0.0,
		"outro_duration": 0.0,
		"scanner_enabled": false,
		"manual_input_enabled": false,
	})
	observation.process_frame(0.01)
	_check(str(observation.get_state_name()) == "PHASE_ONE", "UFO chamber starts with a readable two-observation proof")
	Input.action_press("ui_cancel")
	observation.process_frame(0.01)
	Input.action_release("ui_cancel")
	_check(bool(observation.get("active")), "the mandatory UFO procedure cannot be skipped with Administrative Hold")
	_check((observation.get_pad_positions() as Array).size() == 2, "the first proof exposes exactly two physical observation nodes")
	for audio_name in ["hum_audio", "record_audio", "error_audio", "phase_audio", "collapse_audio"]:
		var observation_audio := observation.get(audio_name) as AudioStreamPlayer
		_check(observation_audio != null and observation_audio.stream != null, "UFO chamber owns %s feedback" % audio_name)
	var first_phase_pads: Array = observation.get_pad_positions()
	observation.set("citizen_position", first_phase_pads[0])
	observation.call("_sync_citizen_node")
	_check(observation.commit_recording(), "the citizen can record a movement timeline from an observation node")
	observation.set("citizen_position", first_phase_pads[1])
	observation.call("_sync_citizen_node")
	observation.process_frame(0.10)
	observation.process_frame(0.01)
	_check(str(observation.get_state_name()) == "PHASE_TWO", "two concurrent observations escalate to the three-node contradiction")
	var second_phase_pads: Array = observation.get_pad_positions()
	_check(second_phase_pads.size() == 3, "the final proof requires two echoes and the present citizen")
	observation.set("citizen_position", second_phase_pads[0])
	observation.call("_sync_citizen_node")
	_check(observation.commit_recording(), "the first final timeline is accepted")
	_check(observation.simulate_scan_hit(), "a scan can invalidate the latest timeline without restarting the chamber")
	_check(int(observation.get("scanner_resets")) == 1 and (observation.get("echoes") as Array).is_empty(), "scanner pressure removes only the latest echo")
	observation.set("citizen_position", second_phase_pads[0])
	observation.call("_sync_citizen_node")
	_check(observation.commit_recording(), "the invalidated timeline can be re-recorded immediately")
	observation.set("citizen_position", second_phase_pads[1])
	observation.call("_sync_citizen_node")
	_check(observation.commit_recording(), "the second final timeline is accepted")
	observation.set("citizen_position", second_phase_pads[2])
	observation.call("_sync_citizen_node")
	observation.process_frame(0.10)
	_check(str(observation.get_state_name()) == "CERTIFY", "three occupied observations produce one explicit identity certification")
	_check(observation.certify_identity(), "the player can certify the administrative contradiction")
	observation.process_frame(0.01)
	observation.process_frame(0.01)
	_check(not bool(observation.get("active")), "certification closes the UFO chamber cleanly")
	var observation_result: Dictionary = observation.get_result()
	_check(str(observation_result.get("outcome", "")) == "identity_verified", "UFO chamber emits a semantic identity result")
	_check(int(observation_result.get("concurrent_subject_count", 0)) == 3 and int(observation_result.get("registered_citizen_count", 0)) == 1, "UFO result preserves the contradiction consumed by the dossier")
	observation.queue_free()


func _test_touch_control_layer() -> void:
	var host := Node.new()
	root.add_child(host)
	var touch := TOUCH_CONTROL_LAYER_SCRIPT.new()
	host.add_child(touch)
	touch.setup(host, true)
	_check(touch.is_enabled() and bool(touch.get("layer").visible), "touch controls can be explicitly enabled for browser-device verification")

	touch.apply_orientation_for_test(Vector2(844.0, 390.0))
	touch.apply_context_for_test("pinball")
	var pinball_controls: Array[String] = touch.get_active_control_ids()
	_check(pinball_controls.has("left_flipper") and pinball_controls.has("right_flipper"), "pinball exposes two independent touch flippers")
	_check(touch.press_control("left_flipper", 11) and touch.press_control("right_flipper", 12), "two touch pointers can press both flippers simultaneously")
	_check(Input.is_action_pressed("ui_left") and Input.is_action_pressed("ui_right"), "multitouch feeds both existing gameplay actions")
	touch.release_control("left_flipper", 11)
	_check(not Input.is_action_pressed("ui_left") and Input.is_action_pressed("ui_right"), "releasing one pointer does not release another held control")
	touch.apply_orientation_for_test(Vector2(390.0, 844.0))
	_check(bool(touch.get("rotate_overlay").visible) and not bool(touch.get("controls_root").visible), "portrait orientation replaces gameplay controls with the landscape notice")
	_check(not Input.is_action_pressed("ui_right"), "rotating to portrait releases a control held before the overlay is hidden")
	touch.release_control("right_flipper", 12)
	touch.apply_orientation_for_test(Vector2(844.0, 390.0))
	_check(not bool(touch.get("rotate_overlay").visible) and bool(touch.get("controls_root").visible), "returning to landscape restores the current contextual controls")
	touch.apply_context_for_test("consensus")
	_check(not Input.is_action_pressed("ui_right"), "changing touch context releases every action from the previous scene")
	_check(touch.get_active_control_ids().has("process"), "the Consensus Engine exposes one touch action that can remain held")

	var receiver := TouchReceiver.new()
	host.add_child(receiver)
	touch.apply_context_for_test("putin", receiver)
	touch.press_control("forward", 21)
	touch.press_control("fire", 22)
	_check(bool(receiver.control_state.get("forward", false)) and bool(receiver.control_state.get("fire", false)), "exceptional touch controls reach Putin through semantic input instead of fake keyboard keys")
	touch.release_control("forward", 21)
	touch.apply_context_for_test("bezos_objection", receiver)
	_check(not bool(receiver.control_state.get("fire", true)), "a target/profile transition releases custom controls before rebuilding the overlay")
	_check(touch.get_active_control_ids() == ["objection"], "Bezos exposes only the action requested by the live combat prompt")
	touch.set_enabled(false)
	_check(not bool(touch.get("layer").visible), "desktop mode can hide the entire touch presentation")
	host.queue_free()


func _test_greatest_deal() -> void:
	_check(ResourceLoader.exists(GREATEST_DEAL_BACKGROUND_PATH), "Greatest Deal stage background exists")
	_check(ResourceLoader.exists(GREATEST_DEAL_MUSIC_PATH), "Snake Eyes Greatest Deal soundtrack exists")
	if ResourceLoader.exists(GREATEST_DEAL_BACKGROUND_PATH):
		var stage_texture := load(GREATEST_DEAL_BACKGROUND_PATH) as Texture2D
		_check(stage_texture != null and stage_texture.get_size() == Vector2(1280, 720), "Greatest Deal stage is authored for the gameplay viewport")
	var deal := GREATEST_DEAL_SCRIPT.new()
	root.add_child(deal)
	deal.setup(root)
	deal.start({"intro_duration": 0.0, "beat_duration": 0.0, "outro_duration": 0.0})
	deal.process_frame(0.01)
	var deal_music := deal.get("music_player") as AudioStreamPlayer
	var deal_music_stream := deal_music.stream as AudioStreamOggVorbis if deal_music else null
	_check(str(deal.call("get_music_asset_path")) == GREATEST_DEAL_MUSIC_PATH, "Greatest Deal exposes the approved Snake Eyes delivery")
	_check(deal_music_stream != null and deal_music_stream.get_length() >= 159.4 and deal_music_stream.get_length() <= 159.7, "Snake Eyes loads as the browser-ready table edit")
	_check(deal_music_stream != null and deal_music_stream.loop and is_equal_approx(deal_music_stream.loop_offset, 10.0), "Snake Eyes preserves its entrance before looping the casino body")
	_check(deal_music != null and deal_music.playing and is_equal_approx(deal_music.volume_db, -8.5), "Snake Eyes starts only with the Greatest Deal table")
	for audio_name in ["card_slide_audio", "card_land_audio", "action_audio", "ruling_audio"]:
		var table_audio := deal.get(audio_name) as AudioStreamPlayer
		_check(table_audio != null and table_audio.stream != null and table_audio.volume_db > deal_music.volume_db, "Greatest Deal owns audible %s feedback above its soundtrack" % audio_name)
	deal.call("_play_card_slide", 1.0)
	_check(bool((deal.get("card_slide_audio") as AudioStreamPlayer).playing), "physical card movement triggers dedicated table foley")
	_check(str(deal.get("target_label").text) == "TARGET: 21", "Greatest Deal states the blackjack target immediately")
	_check(int(deal.get("trump_total")) == 18 and int(deal.get("citizen_total")) == 20, "both blackjack totals are visible before the first action")
	_check(str((deal.get("action_labels") as Array)[0].text).contains("HIT") and str((deal.get("action_labels") as Array)[1].text).contains("STAND"), "HIT and STAND are the only primary actions")
	var citizen_cards: Array = deal.get("citizen_card_nodes")
	var first_card_style := citizen_cards[0].get_theme_stylebox("panel") as StyleBoxFlat
	_check(citizen_cards.size() == 2 and first_card_style != null and first_card_style.bg_color.a > 0.99, "the citizen hand uses complete opaque physical cards")
	_check(deal.stand(), "the first hand accepts the readable STAND action")
	_check(str(deal.get("true_result_label").text).contains("CITIZEN WINS"), "the real blackjack result is shown before any Trump intervention")
	_check(not bool(deal.get("claim_panel").visible) and not bool(deal.get("interference_panel").visible), "the claim cannot obscure the original result immediately")
	deal.process_frame(0.01)
	_check(bool(deal.get("interference_panel").visible) and str(deal.get("prompt_label").text) == "RESULT UNDER REVIEW", "Trump's special move appears only after the real result")
	_check(str(deal.get("true_result_label").text).contains("CITIZEN WINS"), "the true score remains visible during the review")
	deal.process_frame(0.01)
	_check(bool(deal.get("claim_panel").visible), "Accept and Challenge appear only after the special-move beat")
	deal.choose_claim(true)
	deal.process_frame(0.01)
	_check(int(deal.get("round_index")) == 1 and int(deal.get("challenges_remaining")) == 3 and int(deal.get("citizen_deals")) == 1, "a correct challenge restores the result, certifies the Citizen point, and advances")
	_check(int(deal.get("citizen_total")) == 13 and int(deal.get("trump_total")) == 19, "round two clearly exposes the need to HIT")
	_check(deal.hit() and int(deal.get("citizen_total")) == 20, "round two HIT produces a readable total of 20")
	deal.stand()
	deal.process_frame(0.01)
	deal.process_frame(0.01)
	deal.choose_claim(false)
	deal.process_frame(0.01)
	_check(int(deal.get("round_index")) == 2 and int(deal.get("trump_deals")) == 1 and int(deal.get("accepted_false_claims")) == 1, "accepting a false claim awards Trump the point but advances to a different hand")
	_check(int(deal.get("citizen_total")) == 18 and int(deal.get("trump_total")) == 21, "round three visibly gives Trump one legitimate blackjack win")
	deal.stand()
	deal.process_frame(0.01)
	deal.process_frame(0.01)
	deal.choose_claim(true)
	deal.process_frame(0.01)
	_check(int(deal.get("round_index")) == 3 and int(deal.get("failed_challenges")) == 1 and int(deal.get("trump_deals")) == 2, "challenging a legitimate Trump win spends the objection and certifies his point")
	_check(int(deal.get("citizen_total")) == 12 and int(deal.get("trump_total")) == 20, "round four starts as the two-HIT hand")
	_check(deal.hit() and int(deal.get("citizen_total")) == 16, "the first final-round HIT updates the citizen total")
	_check(deal.hit() and int(deal.get("citizen_total")) == 21, "the second final-round HIT reaches the target and resolves automatically")
	deal.process_frame(0.01)
	deal.process_frame(0.01)
	deal.choose_claim(true)
	deal.process_frame(0.01)
	_check(int(deal.get("round_index")) == 4 and int(deal.get("citizen_deals")) == 2 and int(deal.get("citizen_total")) == 15, "round five begins with a distinct majority-deciding hand")
	_check(deal.hit() and int(deal.get("citizen_total")) == 19, "the fifth deal rewards one controlled HIT")
	deal.stand()
	deal.process_frame(0.01)
	deal.process_frame(0.01)
	deal.choose_claim(true)
	deal.process_frame(0.01)
	deal.process_frame(0.01)
	_check(not bool(deal.get("active")), "all five distinct deals close the certified-majority procedure")
	_check(not bool(deal_music.playing), "the table soundtrack stops before Trump dialogue resumes")
	var deal_result: Dictionary = deal.get_result()
	_check(str(deal_result.get("outcome", "")) == "access_granted", "Greatest Deal emits semantic access clearance")
	_check(str(deal_result.get("certified_winner", "")) == "citizen" and int(deal_result.get("citizen_deals", 0)) == 3 and int(deal_result.get("trump_deals", 0)) == 2, "three certified points create a Citizen majority without hiding Trump's points")
	_check(int(deal_result.get("successful_challenges", 0)) == 3 and int(deal_result.get("failed_challenges", 0)) == 1 and int(deal_result.get("challenges_remaining", -1)) == 0, "four challenges support correct and incorrect verdicts")
	_check(int(deal_result.get("accepted_false_claims", 0)) == 1 and int(deal_result.get("hands_played", 0)) == 5, "acceptance remains a semantic choice while every deal advances")
	_check(int(deal_result.get("hits", 0)) == 4 and int(deal_result.get("stands", 0)) == 4 and int(deal_result.get("actual_wins", 0)) == 4, "Greatest Deal preserves blackjack behaviour separately from certified outcomes")
	deal.queue_free()

	var bust_deal := GREATEST_DEAL_SCRIPT.new()
	root.add_child(bust_deal)
	bust_deal.setup(root)
	bust_deal.start({"intro_duration": 0.0, "beat_duration": 0.0})
	bust_deal.process_frame(0.01)
	bust_deal.hit()
	bust_deal.hit()
	_check(int(bust_deal.get("citizen_total")) == 25 and str(bust_deal.get("true_result_label").text).contains("BUSTS"), "an unnecessary HIT produces a normal blackjack bust")
	_check(not bool(bust_deal.get("interference_panel").visible), "certification cannot obscure the immediate blackjack result")
	bust_deal.process_frame(0.01)
	bust_deal.process_frame(0.01)
	bust_deal.choose_claim(false)
	bust_deal.process_frame(0.01)
	_check(int(bust_deal.get("round_index")) == 1 and int(bust_deal.get("citizen_total")) == 13 and int(bust_deal.get("accepted_valid_claims")) == 1, "a lost hand is certified once and advances instead of repeating identical cards")
	bust_deal.queue_free()

	var accommodated_deal := GREATEST_DEAL_SCRIPT.new()
	root.add_child(accommodated_deal)
	accommodated_deal.setup(root)
	accommodated_deal.start({"intro_duration": 0.0, "beat_duration": 0.0, "outro_duration": 0.0})
	accommodated_deal.process_frame(0.01)
	Input.action_press("ui_cancel")
	accommodated_deal.process_frame(0.01)
	Input.action_release("ui_cancel")
	_check(bool(accommodated_deal.get("active")), "the mandatory five-deal procedure cannot be skipped with Administrative Hold")
	for deal_index in range(5):
		_check(accommodated_deal.stand(), "certified deal %d can be resolved with standard blackjack actions" % (deal_index + 1))
		accommodated_deal.process_frame(0.01)
		accommodated_deal.process_frame(0.01)
		accommodated_deal.choose_claim(false)
		accommodated_deal.process_frame(0.01)
	accommodated_deal.process_frame(0.01)
	var accommodated_result: Dictionary = accommodated_deal.get_result()
	_check(not bool(accommodated_deal.get("active")), "an accommodated five-deal match also reaches a terminal access verdict")
	_check(str(accommodated_result.get("outcome", "")) == "access_granted" and str(accommodated_result.get("certified_winner", "")) == "trump", "a Trump certified majority changes the verdict without blocking the existing dialogue")
	_check(int(accommodated_result.get("trump_deals", 0)) == 5 and int(accommodated_result.get("hands_played", 0)) == 5, "Accept certifies one point and advances through every distinct hand")
	accommodated_deal.queue_free()


func _test_consensus_engine() -> void:
	_check(ResourceLoader.exists(CONSENSUS_ENGINE_BACKGROUND_PATH), "Consensus Engine stage background exists")
	if ResourceLoader.exists(CONSENSUS_ENGINE_BACKGROUND_PATH):
		var stage_texture := load(CONSENSUS_ENGINE_BACKGROUND_PATH) as Texture2D
		_check(stage_texture != null and stage_texture.get_size() == Vector2(1280, 720), "Consensus Engine stage is authored for the gameplay viewport")
	var engine := CONSENSUS_ENGINE_SCRIPT.new()
	root.add_child(engine)
	engine.setup(root)
	engine.start({"intro_duration": 0.0, "beat_duration": 0.0, "outro_duration": 0.0, "timers_enabled": false})
	engine.process_frame(0.01)
	for audio_name in ["station_audio", "approval_audio", "error_audio", "phase_audio", "printer_audio"]:
		var procedure_audio := engine.get(audio_name) as AudioStreamPlayer
		_check(procedure_audio != null and procedure_audio.stream != null, "Consensus Engine owns generated %s feedback" % audio_name)
	_check(engine.get("procedure_flash") != null and engine.get("action_stamp_label") != null and engine.get("action_burst") != null, "Consensus Engine owns a dedicated machine-impact layer")
	var approval_lights: Array = engine.get("lights")
	var first_light_style := (approval_lights[0] as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	_check(approval_lights.size() == 27 and first_light_style != null and first_light_style.bg_color.a > 0.99, "all 27 approvals use complete physical indicators")
	var scanner_console := (engine.get("station_nodes") as Dictionary)["scanner"] as PanelContainer
	var scanner_style := scanner_console.get_theme_stylebox("panel") as StyleBoxFlat
	_check(scanner_style != null and scanner_style.bg_color.a > 0.99 and (scanner_console.get_child(0) as Control).get_child_count() >= 5, "procedure stations are opaque machine consoles rather than floating labels")
	_check((engine.get("dossier_root") as Node2D).get_child_count() >= 9 and str((engine.get("dossier_stamp") as Label).text) == "00 / 27", "the movable dossier is a layered physical case with a live approval counter")
	var derogation_style := (engine.get("emergency_panel") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	_check(derogation_style != null and derogation_style.bg_color.a > 0.99, "the emergency derogation is housed in a complete physical console")
	_check(not engine.interact_at_station("translation"), "an incorrect first counter is rejected")
	_check(str((engine.get("action_stamp_label") as Label).text) == "MISROUTED" and float((engine.get("procedure_flash") as ColorRect).modulate.a) > 0.0, "a misroute produces immediate red machine feedback")
	_check(engine.interact_at_station("scanner"), "simple-majority route accepts scanner")
	_check(is_equal_approx(float((engine.get("station_audio") as AudioStreamPlayer).pitch_scale), 1.34) and str((engine.get("action_stamp_label") as Label).text) == "SCANNED", "the scanner resolves with its own physical stamp and pitch")
	for station_id in ["stamp", "submit"]:
		_check(engine.interact_at_station(station_id), "simple-majority route accepts %s" % station_id)
	_check(is_equal_approx(float((engine.get("station_audio") as AudioStreamPlayer).pitch_scale), 0.92) and str((engine.get("action_stamp_label") as Label).text) == "INSUFFICIENT", "filing retains its own pitch before the machine replaces its stamp with a phase ruling")
	engine.process_frame(0.01)
	_check(int(engine.get("phase_index")) == 1 and int(engine.get("approvals")) == 8, "simple majority is achieved and then declared insufficient")
	for station_id in ["stamp", "translation", "mobile_stamp", "submit"]:
		_check(engine.interact_at_station(station_id), "qualified-majority route accepts %s" % station_id)
	engine.process_frame(0.01)
	_check(int(engine.get("phase_index")) == 2 and int(engine.get("approvals")) == 26, "qualified majority advances to the single unresolved approval")
	for station_id in ["submit", "scanner", "translation"]:
		_check(engine.interact_at_station(station_id), "unanimity route accepts %s" % station_id)
	_check(bool(engine.get("derogation_unlocked")), "Annex B exposes the lawful emergency derogation")
	_check(engine.activate_derogation(), "the discovered derogation can complete unanimity")
	engine.process_frame(3.0)
	_check(int(engine.get("last_print_audio_line")) > 0 and bool((engine.get("printer_label") as Label).visible), "the 847-page printout advances with mechanical line feedback")
	engine.process_frame(0.01)
	_check(not bool(engine.get("active")), "printed unanimous approval closes the procedure")
	var consensus_result: Dictionary = engine.get_result()
	_check(str(consensus_result.get("outcome", "")) == "access_granted", "Consensus Engine emits semantic access clearance")
	_check(bool(consensus_result.get("derogation_used", false)) and str(consensus_result.get("route", "")) == "emergency_derogation", "Consensus Engine records the procedural route rather than a generic win")
	engine.queue_free()


func _test_price_stability_pinball() -> void:
	_check(ResourceLoader.exists(PRICE_STABILITY_PINBALL_BACKGROUND_PATH), "Price Stability pinball background exists")
	_check(ResourceLoader.exists(PRICE_STABILITY_PINBALL_MUSIC_PATH), "Jackpot Jive Price Stability soundtrack exists")
	if ResourceLoader.exists(PRICE_STABILITY_PINBALL_BACKGROUND_PATH):
		var stage_texture := load(PRICE_STABILITY_PINBALL_BACKGROUND_PATH) as Texture2D
		_check(stage_texture != null and stage_texture.get_size() == Vector2(1280, 720), "Price Stability stage is authored for the gameplay viewport")
	var pinball := PRICE_STABILITY_PINBALL_SCRIPT.new()
	root.add_child(pinball)
	pinball.setup(root)
	pinball.start({
		"intro_duration": 0.0,
		"beat_duration": 0.0,
		"outro_duration": 0.0,
		"physics_enabled": false,
		"timers_enabled": false,
	})
	pinball.process_frame(0.01)
	var pinball_music := pinball.get("music_player") as AudioStreamPlayer
	var pinball_music_stream := pinball_music.stream as AudioStreamOggVorbis if pinball_music else null
	_check(str(pinball.call("get_music_asset_path")) == PRICE_STABILITY_PINBALL_MUSIC_PATH, "Price Stability exposes the approved Jackpot Jive delivery")
	_check(pinball_music_stream != null and pinball_music_stream.get_length() >= 171.0 and pinball_music_stream.get_length() <= 171.2, "Jackpot Jive loads as the browser-ready pinball edit")
	_check(pinball_music != null and pinball_music.playing and is_equal_approx(pinball_music.volume_db, -8.5), "Jackpot Jive starts only with the monetary table")
	for audio_name in ["bumper_audio", "flipper_audio", "event_audio", "bailout_audio", "success_audio"]:
		var monetary_audio := pinball.get(audio_name) as AudioStreamPlayer
		_check(monetary_audio != null and monetary_audio.stream != null and monetary_audio.volume_db > pinball_music.volume_db, "Price Stability owns audible %s feedback above its soundtrack" % audio_name)
	_check(pinball.get("table_flash") != null and pinball.get("impact_burst") != null and pinball.get("celebration_root") != null, "Price Stability owns a dedicated monetary-impact layer")
	_check(str(pinball.get("title_label").text) == "THE 2% MIRACLE", "Lagarde's procedure names its impossible target immediately")
	_check(is_equal_approx(float(pinball.get("inflation")), 4.8) and str(pinball.get("target_label").text).contains("2.00%"), "the inflation reading and target are visible before play")
	_check((pinball.get("bumper_nodes") as Dictionary).size() == 6, "the monetary table exposes six physical policy and household bumpers")
	_check((pinball.get("balls") as Array).size() == 1 and pinball.get("left_flipper") != null and pinball.get("right_flipper") != null, "the procedure begins as a readable two-flipper pinball table")
	_check(pinball.register_bumper_hit("rates_left"), "the first policy bumper accepts a deterministic hit")
	_check(float((pinball.get("bumper_audio") as AudioStreamPlayer).pitch_scale) > 1.0 and (pinball.get("impact_burst") as Line2D).position == Vector2(427, 276), "rate policy produces a bright localized pinball impact")
	for bumper_id in ["energy", "rates_right", "rent", "rates_left"]:
		_check(pinball.register_bumper_hit(bumper_id), "policy table accepts the %s bumper" % bumper_id)
	_check(bool(pinball.get("multiball_spawned")) and (pinball.get("balls") as Array).size() == 2, "five interventions trigger the readable liquidity-injection multiball")
	_check(is_equal_approx(float((pinball.get("event_audio") as AudioStreamPlayer).pitch_scale), 1.42) and str((pinball.get("policy_message_label") as Label).text) == "LIQUIDITY INJECTION", "liquidity injection receives a distinct audiovisual super-move cue")
	for bumper_id in ["wages", "rates_right", "bank_rescue", "energy", "rates_left"]:
		_check(pinball.register_bumper_hit(bumper_id), "accelerated policy table accepts the %s bumper" % bumper_id)
	_check(bool(pinball.get("rate_shock_active")), "ten interventions trigger the authored rate shock")
	_check(pinball.simulate_ball_loss(), "a drained economy reaches the bailout rule")
	_check(int(pinball.get("bailouts")) == 1 and (pinball.get("balls") as Array).size() == 1, "the last drained ball is restored as a systemic bailout")
	_check(float((pinball.get("bailout_audio") as AudioStreamPlayer).pitch_scale) > 0.9 and (pinball.get("impact_burst") as Line2D).position == Vector2(640, 555), "systemic bailout returns with a central serve impact")
	_check(pinball.force_statistical_adjustment(), "the timeout route can publish the target statistically")
	pinball.process_frame(0.01)
	pinball.process_frame(0.01)
	pinball.process_frame(0.01)
	_check(not bool(pinball.get("active")), "the published indicator closes the monetary procedure")
	_check(not bool(pinball_music.playing), "the pinball soundtrack stops before Lagarde dialogue resumes")
	var adjusted_result: Dictionary = pinball.get_result()
	_check(str(adjusted_result.get("outcome", "")) == "access_granted" and str(adjusted_result.get("route", "")) == "statistical_adjustment", "the adjustment route grants access without pretending it was player mastery")
	_check(bool(adjusted_result.get("multiball_used", false)) and bool(adjusted_result.get("rate_shock", false)) and int(adjusted_result.get("bailouts", 0)) == 1, "the result preserves monetary interventions for the dossier")
	pinball.queue_free()

	var served_pinball := PRICE_STABILITY_PINBALL_SCRIPT.new()
	root.add_child(served_pinball)
	served_pinball.setup(root)
	served_pinball.start({
		"intro_duration": 0.0,
		"physics_enabled": true,
		"timers_enabled": false,
	})
	served_pinball.process_frame(0.01)
	_check(served_pinball.simulate_ball_loss(), "a live drained table requests a systemic serve")
	var served_ball: Dictionary = (served_pinball.get("balls") as Array)[0]
	_check((served_ball.get("position") as Vector2).is_equal_approx(Vector2(640, 555)), "the replacement ball starts in the protected central service lane")
	_check(absf((served_ball.get("velocity") as Vector2).x) <= 18.0 and is_equal_approx((served_ball.get("velocity") as Vector2).y, -260.0), "the replacement ball uses a controlled flipper-aligned serve")
	for frame_index in range(240):
		served_pinball.process_frame(1.0 / 120.0)
	_check(int(served_pinball.get("bailouts")) == 1 and (served_pinball.get("balls") as Array).size() == 1, "the replacement ball reaches a flipper instead of immediately draining again")
	served_pinball.queue_free()

	var rail_pinball := PRICE_STABILITY_PINBALL_SCRIPT.new()
	root.add_child(rail_pinball)
	rail_pinball.setup(root)
	rail_pinball.start({
		"intro_duration": 0.0,
		"physics_enabled": true,
		"timers_enabled": false,
	})
	rail_pinball.process_frame(0.01)
	var rail_ball: Dictionary = (rail_pinball.get("balls") as Array)[0]
	rail_ball["position"] = Vector2(410, 510)
	rail_ball["velocity"] = Vector2(-250, 600)
	(rail_ball.get("node") as Node2D).position = rail_ball["position"]
	rail_pinball.process_frame(0.08)
	_check((rail_ball.get("velocity") as Vector2).x > 0.0 and (rail_ball.get("velocity") as Vector2).y < 0.0, "the left south guide returns a fast edge ball toward play")
	rail_ball["position"] = Vector2(870, 510)
	rail_ball["velocity"] = Vector2(250, 600)
	(rail_ball.get("node") as Node2D).position = rail_ball["position"]
	rail_pinball.process_frame(0.08)
	_check((rail_ball.get("velocity") as Vector2).x < 0.0 and (rail_ball.get("velocity") as Vector2).y < 0.0, "the right south guide returns a fast edge ball toward play")
	rail_ball["position"] = Vector2(640, 690)
	rail_ball["velocity"] = Vector2(0, 300)
	(rail_ball.get("node") as Node2D).position = rail_ball["position"]
	rail_pinball.process_frame(0.08)
	_check(int(rail_pinball.get("bailouts")) == 1, "the intentional central drain remains open between the protected south edges")
	rail_pinball.queue_free()

	var stabilized_pinball := PRICE_STABILITY_PINBALL_SCRIPT.new()
	root.add_child(stabilized_pinball)
	stabilized_pinball.setup(root)
	stabilized_pinball.start({
		"intro_duration": 0.0,
		"beat_duration": 0.0,
		"outro_duration": 0.0,
		"physics_enabled": false,
		"timers_enabled": false,
	})
	stabilized_pinball.process_frame(0.01)
	for hit_index in range(6):
		_check(stabilized_pinball.register_bumper_hit("rates_left"), "rate policy hit %d is deterministic" % (hit_index + 1))
	_check(is_equal_approx(float(stabilized_pinball.get("inflation")), 2.1), "six rate hits reach the visible stability band without hidden arithmetic")
	stabilized_pinball.process_frame(2.1)
	_check((stabilized_pinball.get("celebration_root") as Node2D).get_child_count() == 18 and is_equal_approx(float((stabilized_pinball.get("success_audio") as AudioStreamPlayer).pitch_scale), 1.0), "real stabilization explodes into a full euro celebration and success cue")
	stabilized_pinball.process_frame(0.01)
	stabilized_pinball.process_frame(0.01)
	stabilized_pinball.process_frame(0.01)
	var stabilized_result: Dictionary = stabilized_pinball.get_result()
	_check(not bool(stabilized_pinball.get("active")) and str(stabilized_result.get("route", "")) == "market_stabilized", "holding the real target records the genuine stabilization route")
	stabilized_pinball.queue_free()


func _test_putin_special_operation() -> void:
	for asset_path in PUTIN_OPERATION_ASSET_PATHS:
		_check(ResourceLoader.exists(asset_path), "%s exists" % asset_path)
		if not ResourceLoader.exists(asset_path):
			continue
		var texture := load(asset_path) as Texture2D
		_check(texture != null, "%s can be loaded" % asset_path)
		if texture:
			var image := texture.get_image()
			if asset_path.ends_with("diplomatic_note_launcher_centered_v2.png"):
				var margin := image.get_pixel(0, 0) if image else Color.BLACK
				_check(image != null and minf(margin.r, minf(margin.g, margin.b)) > 0.95, "%s preserves the neutral cutout margin" % asset_path)
			else:
				_check(image != null and image.get_pixel(0, 0).a < 0.05, "%s preserves a transparent runtime margin" % asset_path)

	var operation := PUTIN_SPECIAL_OPERATION_SCRIPT.new()
	root.add_child(operation)
	operation.setup(root)
	operation.start({
		"intro_duration": 0.0,
		"outro_duration": 0.0,
		"combat_enabled": false,
	})
	operation.process_frame(0.01)
	var operation_music := operation.get("music_player") as AudioStreamPlayer
	_check(str(operation.call("get_music_asset_path")) == "res://assets/audio/civic_nightmare_putin_special_operation.ogg", "the Special Operation exposes its approved runtime music path")
	_check(operation_music != null and operation_music.stream != null and operation_music.stream.get_length() >= 165.0 and operation_music.stream.get_length() <= 167.0, "the delivered Three-Minute Special Operation track loads at its verified duration")
	_check(operation_music != null and operation_music.playing, "the soundtrack starts with the Special Operation")
	_check(operation_music != null and is_equal_approx(operation_music.volume_db, -4.0), "the Special Operation soundtrack uses its raised arena mix")
	for effect_name in ["shot_audio", "reload_audio", "hit_audio", "damage_audio", "gate_audio", "success_audio"]:
		var effect_player := operation.get(effect_name) as AudioStreamPlayer
		_check(effect_player != null and effect_player.volume_db > operation_music.volume_db, "%s remains louder than the soundtrack" % effect_name)
	_check(bool(operation.get("active")) and operation.get("render_viewport") != null and operation.get("camera_3d") != null, "Putin's operation owns an isolated low-resolution 3D world")
	var operation_world := operation.get("world_root") as Node3D
	var reserve_ceiling := operation_world.get_node_or_null("StrategicReserveCeiling") as MeshInstance3D
	var low_ceiling := operation_world.get_node_or_null("LowCeiling") as MeshInstance3D
	_check(reserve_ceiling != null and reserve_ceiling.position.y >= 7.0, "the Strategic Bear arena has full authored headroom")
	_check(low_ceiling != null and (low_ceiling.mesh as BoxMesh).size.z <= 58.0, "the service ceiling ends before the tall boss arena")
	_check(operation_world.get_node_or_null("DomesticReserveLabel") != null and operation_world.get_node_or_null("RecoveredAppliance4") != null, "the final arena owns its reserve signage and appliance gallery")
	Input.action_press("ui_left")
	operation.process_frame(0.1)
	Input.action_release("ui_left")
	_check(float(operation.get("player_yaw")) > 0.0, "left input turns the operation toward the player's visible left")
	operation.set("player_yaw", 0.0)
	operation.call("_update_camera")
	var lateral_origin := operation.get("player_position") as Vector3
	var right_direction := operation.call("_right_vector") as Vector3
	var visible_right := ((operation.get("camera_3d") as Camera3D).global_transform.basis.x as Vector3).normalized()
	operation.call("_try_move", right_direction * 0.8)
	var lateral_result := operation.get("player_position") as Vector3
	_check(right_direction.dot(visible_right) > 0.99 and (lateral_result - lateral_origin).dot(visible_right) > 0.0, "D strafe follows the camera-visible right instead of the mirrored world axis")
	var first_wave_counts: Dictionary = operation.get_enemy_counts()
	_check(int(first_wave_counts.get("required", 0)) == 2 and int(first_wave_counts.get("cameras", 0)) == 1, "the opening wave separates required defenses from the optional state camera")
	_check((operation.get("note_marks") as Array).size() == 6 and int(operation.get("notes_loaded")) == 6, "the Diplomatic Note Launcher exposes its six physical notes")
	var centered_weapon := operation.get("weapon_rect") as TextureRect
	_check(centered_weapon != null and is_equal_approx(centered_weapon.position.x + centered_weapon.size.x * 0.5, 640.0), "the Diplomatic Note Launcher is physically centered beneath the reticle")
	_check(centered_weapon != null and centered_weapon.material is ShaderMaterial, "the centered launcher removes its generated neutral margin at runtime")
	operation.set("player_yaw", PI * 0.5)
	for note_index in range(6):
		operation.call("_fire")
	operation.process_frame(0.01)
	_check(int(operation.get("notes_loaded")) == 0 and float(operation.get("reload_remaining")) > 0.0 and bool((operation.get("reload_sheet") as ColorRect).visible), "the empty launcher visibly feeds a new R-6 form into its upper receiver")
	operation.process_frame(1.2)
	_check(int(operation.get("notes_loaded")) == 6 and is_zero_approx(float(operation.get("reload_remaining"))), "automatic re-filing restores exactly six diplomatic notes")
	operation.set("player_yaw", 0.0)

	for wave_index in range(3):
		for cleanup_pass in range(6):
			var enemy_snapshot: Array = (operation.get("enemies") as Array).duplicate()
			for enemy in enemy_snapshot:
				if not bool(enemy.get("alive", false)) or int(enemy.get("wave", -1)) != wave_index or not bool(enemy.get("blocks_gate", false)):
					continue
				var enemy_id := str(enemy.get("id", ""))
				for hit_index in range(4):
					operation.register_enemy_hit(enemy_id)
		operation.process_frame(0.01)
		if wave_index < 2:
			_check(bool((operation.get("gate_open") as Array)[wave_index]), "required wave %d opens its continuity gate" % (wave_index + 1))
			var next_position := operation.get("player_position") as Vector3
			next_position.z = 21.0 if wave_index == 0 else 41.0
			operation.set("player_position", next_position)
			operation.process_frame(0.01)

	_check(bool(operation.get("final_seals_active")), "the final wave exposes the three physical Potemkin seals")
	_check(int(operation.get("matryoshka_splits")) == 3, "each mandatory armored matryoshka splits into smaller security units")
	var seal_targets := operation.get("seal_target_nodes") as Array
	var final_display_label := operation.get("final_display_label") as Label3D
	_check(seal_targets.size() == 3 and bool((seal_targets[0] as Node3D).visible) and bool((seal_targets[1] as Node3D).visible) and bool((seal_targets[2] as Node3D).visible), "all three final seals gain visible target brackets")
	_check(final_display_label != null and final_display_label.text == "STAMP 3 FLASHING SEALS", "the Potemkin display gives one concise physical instruction")
	operation.set("player_position", Vector3(0.0, 1.55, 48.0))
	operation.set("player_yaw", 0.0)
	_check(bool(operation.call("_is_aiming_at_live_seal")), "the reticle can recognize a live authorization seal")
	for seal_index in range(3):
		_check(operation.register_seal_hit(seal_index), "seal %d accepts the first diplomatic note" % (seal_index + 1))
		var seal_node := (operation.get("seal_nodes") as Array)[seal_index] as MeshInstance3D
		_check(int((operation.get("seal_health") as Array)[seal_index]) == 1 and seal_node.material_override == operation.get("seal_damaged_material"), "seal %d visibly changes state after its first hit" % (seal_index + 1))
		_check(operation.register_seal_hit(seal_index), "seal %d accepts the second diplomatic note" % (seal_index + 1))
		_check(not bool((seal_targets[seal_index] as Node3D).visible), "destroyed seal %d stops flashing as a target" % (seal_index + 1))
	_check(not bool((operation.get("gate_open") as Array)[2]), "destroying all three seals exposes rather than skips the final defense")
	var bear_state: Dictionary = operation.get_strategic_bear_state()
	_check(bool(bear_state.get("active", false)) and int(bear_state.get("health", 0)) == 6, "the Strategic Bear arrives with one readable three-load health model")
	_check(not bool((operation.get("strategic_bear_target") as Node3D).visible), "the washing-machine drum is not presented as vulnerable before its reload")
	var bear_id := str(bear_state.get("id", ""))
	for wash_cycle in range(5):
		var bear_index := -1
		var active_enemies := operation.get("enemies") as Array
		for enemy_index in range(active_enemies.size()):
			if str((active_enemies[enemy_index] as Dictionary).get("id", "")) == bear_id:
				bear_index = enemy_index
				break
		_check(bear_index >= 0, "wash cycle %d retains the Strategic Bear" % (wash_cycle + 1))
		if bear_index < 0:
			continue
		var alarm_before_cycle := bool(operation.get("strategic_bear_alarm_phase"))
		var bear_enemy: Dictionary = active_enemies[bear_index]
		bear_enemy["alive"] = true
		bear_enemy["attack_state"] = "idle"
		bear_enemy["vulnerable"] = false
		active_enemies[bear_index] = bear_enemy
		_check(bool(operation.call("_begin_enemy_telegraph", bear_index)), "wash cycle %d clearly telegraphs before firing" % (wash_cycle + 1))
		bear_enemy = (operation.get("enemies") as Array)[bear_index] as Dictionary
		var is_double_cycle := bool(bear_enemy.get("double_attack", false))
		if alarm_before_cycle and is_double_cycle:
			_check(bear_enemy.get("telegraph_node_secondary") is MeshInstance3D, "alarm cycle %d paints both consecutive trajectories before firing" % (wash_cycle + 1))
		_check(bool(operation.call("_release_enemy_projectile", bear_index)), "wash cycle %d opens a physical reload window" % (wash_cycle + 1))
		bear_state = operation.get_strategic_bear_state()
		_check(bool(bear_state.get("vulnerable", false)) and bool((operation.get("strategic_bear_target") as Node3D).visible), "wash cycle %d exposes and brackets the open drum" % (wash_cycle + 1))
		if alarm_before_cycle:
			bear_enemy = (operation.get("enemies") as Array)[bear_index] as Dictionary
			_check(is_equal_approx(float(bear_enemy.get("reload_timer", 0.0)), 1.70), "alarm cycle %d shortens but preserves the readable reload window" % (wash_cycle + 1))
			var expected_projectiles := 2 if is_double_cycle else 1
			_check((operation.get("enemy_projectiles") as Array).size() == expected_projectiles, "alarm cycle %d launches only its visibly announced load" % (wash_cycle + 1))
			if is_double_cycle:
				var delayed_load := (operation.get("enemy_projectiles") as Array)[1] as Dictionary
				_check(float(delayed_load.get("delay", 0.0)) > 0.0, "the second announced load follows rather than overlaps the first")
		var allowed_hits := 2 if wash_cycle == 0 else 1
		for hit_index in range(allowed_hits):
			_check(operation.register_enemy_hit(bear_id), "wash cycle %d accepts authorized drum hit %d" % [wash_cycle + 1, hit_index + 1])
		_check(not operation.register_enemy_hit(bear_id), "wash cycle %d rejects extra fire during the same appliance opening" % (wash_cycle + 1))
		if wash_cycle == 1:
			bear_state = operation.get_strategic_bear_state()
			_check(bool(bear_state.get("alarm_phase", false)) and not bool(bear_state.get("vulnerable", true)), "the third hit ends the normal reload and starts the sanctions-proof phase")
			var reserve_label := operation.get("domestic_reserve_label") as Label3D
			var alarm_strips := operation.get("strategic_bear_alarm_strips") as Array
			_check(reserve_label != null and reserve_label.text == "DOMESTIC PRODUCTION SUCCESSFUL", "the reserve hall reinterprets the emergency as domestic success")
			_check(alarm_strips.size() == 4 and bool((alarm_strips[0] as MeshInstance3D).visible), "the Strategic Bear phase change activates physical warning strips")
			operation.set("elapsed", 1.0)
			operation.set("combat_enabled", true)
			operation.call("_update_enemies", 0.01)
			operation.set("combat_enabled", false)
			bear_enemy = (operation.get("enemies") as Array)[bear_index] as Dictionary
			_check(absf((bear_enemy.get("position") as Vector3).x) > 1.0, "the alarm phase makes lateral movement materially useful")
		operation.call("_clear_enemy_projectiles")
	_check(bool(operation.get("strategic_bear_defeated")) and bool(operation.get("strategic_bear_departure_active")), "six drum hits trigger the unbalanced-load departure instead of a violent death")
	operation.call("_update_strategic_bear_departure", 2.0)
	_check(bool((operation.get("gate_open") as Array)[2]), "the runaway appliance physically opens Kremlin access")
	var exit_position := operation.get("player_position") as Vector3
	exit_position.z = 61.4
	operation.set("player_position", exit_position)
	operation.process_frame(0.01)
	operation.process_frame(0.01)
	var operation_result: Dictionary = operation.get_result()
	_check(not bool(operation.get("active")) and str(operation_result.get("outcome", "")) == "access_granted", "the short operation grants semantic Kremlin access")
	_check(operation_music != null and not operation_music.playing, "the Special Operation music yields to the completion sting")
	_check(str(operation_result.get("route", "")) == "defensive_corridor" and int(operation_result.get("cameras_destroyed", -1)) == 0, "the result distinguishes bypassing propaganda from destroying it")
	_check(bool(operation_result.get("strategic_bear_defeated", false)) and int(operation_result.get("strategic_bear_hits", 0)) == 6 and bool(operation_result.get("strategic_bear_alarm_phase", false)), "the result records the completed two-phase appliance defense")
	operation.queue_free()

	var fair_firefight := PUTIN_SPECIAL_OPERATION_SCRIPT.new()
	root.add_child(fair_firefight)
	fair_firefight.setup(root)
	fair_firefight.start({"intro_duration": 0.0, "combat_enabled": true})
	fair_firefight.process_frame(0.01)
	var locked_origin := fair_firefight.get("player_position") as Vector3
	_check(bool(fair_firefight.call("_begin_enemy_telegraph", 0)), "one enemy visibly reserves an attack lane")
	var telegraphed_enemy: Dictionary = (fair_firefight.get("enemies") as Array)[0]
	_check((telegraphed_enemy.get("locked_target") as Vector3).is_equal_approx(Vector3(locked_origin.x, 1.1, locked_origin.z)), "enemy fire locks the player's position before launching")
	var dodge_position := locked_origin + Vector3(3.0, 0.0, 0.0)
	fair_firefight.set("player_position", dodge_position)
	_check(bool(fair_firefight.call("_release_enemy_projectile", 0)), "the warning lane becomes a physical administrative projectile")
	_check(not bool(fair_firefight.call("_begin_enemy_telegraph", 1)), "only one enemy threat can be active at a time")
	var integrity_before_dodge := int(fair_firefight.get("case_integrity"))
	for projectile_step in range(100):
		fair_firefight.call("_update_enemy_projectiles", 0.05)
	_check(int(fair_firefight.get("case_integrity")) == integrity_before_dodge, "moving after the warning cleanly dodges non-tracking enemy fire")
	_check(bool(fair_firefight.call("_segment_hits_cover", Vector3(-3.9, 1.1, 13.5), Vector3(-3.9, 1.1, 10.5), 0.25)), "ceremonial barriers physically intercept incoming forms")
	_check(bool(fair_firefight.call("_position_hits_cover", Vector3(-3.9, 1.55, 12.0), 0.42)), "ceremonial barriers also block player traversal")
	_check(bool(fair_firefight.call("_begin_enemy_telegraph", 0)), "an enemy may fire again only after the previous threat resolves")
	_check(bool(fair_firefight.call("_release_enemy_projectile", 0)), "a stationary target receives the announced projectile")
	for projectile_step in range(100):
		fair_firefight.call("_update_enemy_projectiles", 0.05)
	_check(int(fair_firefight.get("case_integrity")) == integrity_before_dodge - 1, "remaining in the announced lane costs exactly one case-integrity mark")
	fair_firefight.stop()
	fair_firefight.queue_free()


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


func _test_historical_contamination_asset() -> void:
	_check(ResourceLoader.exists(HISTORICAL_CONTAMINATION_SPRITE_PATH), "corrected historical contamination sprite exists")
	if not ResourceLoader.exists(HISTORICAL_CONTAMINATION_SPRITE_PATH):
		return
	var texture := load(HISTORICAL_CONTAMINATION_SPRITE_PATH) as Texture2D
	_check(texture != null, "corrected historical contamination sprite can be loaded")
	if texture:
		_check(texture.get_size() == Vector2(1024, 1024), "corrected historical contamination sprite preserves its authored canvas")
		var image := texture.get_image()
		_check(image != null and image.get_pixel(0, 0).a < 0.05, "corrected historical contamination sprite preserves transparent margins")


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
	manager.set_claudia_session_tone("sad")
	_check(str(manager.get("claudia_session_tone")) == "sad", "CLAUDIA accepts a dossier-derived session tone")
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
	var ufo_only := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(ufo_only)
	ufo_only.record_anomaly(
		"anomaly:ufo_time_discontinuity",
		"ufo_observation_chamber",
		"Three observations accepted for one citizen.",
		{"concurrent_subject_count": 3, "registered_citizen_count": 1, "reconciliation": "postponed"}
	)
	_check(ufo_only.has_event("anomaly:ufo_time_discontinuity"), "dossier exposes stable event ownership for legacy clearance inference")
	var ufo_unresolved: Array = ufo_only.get_pause_summary("unresolved_material").get("lines", [])
	_check(not ufo_unresolved.is_empty() and str(ufo_unresolved[0]).contains("Subjects observed concurrently: 3"), "Administrative Hold retains the UFO identity contradiction")
	_check(str(ufo_only.claim_claudia_observation().get("id", "")) == "claudia_ufo_observation_problem", "the observation chamber creates one sparse CLAUDIA callback")
	var putin_operation_only := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(putin_operation_only)
	putin_operation_only.record_contest(
		"contest:putin_special_operation",
		"kremlin_access",
		"official-reality-suppressed",
		"Defensive corridor crossed.",
		{"cameras_destroyed": 2, "shots_fired": 17}
	)
	var putin_activity: Array = putin_operation_only.get_pause_summary("recorded_activity").get("lines", [])
	_check(not putin_activity.is_empty() and str(putin_activity[0]).contains("2 broadcast assets"), "Administrative Hold interprets the operation without exposing combat statistics")
	_check(str(putin_operation_only.claim_claudia_observation().get("id", "")) == "claudia_putin_special_operation", "the defensive corridor creates a sparse CLAUDIA callback")

	var expected_classification: String = manager.derive_classification()
	var snapshot: Dictionary = manager.get_save_data()
	var restored := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(restored)
	restored.restore_save_data(snapshot)
	_check((restored.get("events") as Array).size() == (manager.get("events") as Array).size(), "dossier round trip preserves raw event history")
	_check(restored.derive_classification() == expected_classification, "classification is deterministically reconstructed after restore")
	_check(bool(restored.get("profile_discovered")), "dossier round trip preserves profile awareness")

	var six_signature_manager := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(six_signature_manager)
	var six_signature_choices := [
		["donald_trump", "Approve the performance.", "spectacle-compliant"],
		["elon_musk", "Request the manual route.", "manual-routing"],
		["ursula_von_der_leyen", "Request an exception.", "expedite-requested"],
		["vladimir_putin", "Adjust the wording.", "self-censored"],
		["christine_lagarde", "Ask for the total cost.", "household-adjusted"],
		["emmanuel_macron", "Allow the discourse.", "discursively-delayed"],
	]
	for item in six_signature_choices:
		six_signature_manager.record_choice(str(item[0]), {
			"label": str(item[1]),
			"file_tag": str(item[2]),
			"file_note": "Semantic smoke evidence",
		})
	var semantic_summary: Dictionary = six_signature_manager.derive_observation_summary()
	_check(int(semantic_summary.get("choice_count", 0)) == 6, "all six signatures produce behavioural evidence")
	_check((semantic_summary.get("pressure_channels", []) as Array).size() == 6, "six signatures observe six distinct pressure channels")
	_check(int((semantic_summary.get("response_modes", {}) as Dictionary).get("inspect", 0)) == 1, "Lagarde distinguishes inspection from compliance and refusal")
	_check(_has_pattern(six_signature_manager.derive_patterns(), "terms_before_trust"), "Lagarde can complete a cross-signature legibility pattern")
	_check(_has_pattern(six_signature_manager.derive_patterns(), "full_authority_comparison"), "the complete quest derives a six-authority comparison")
	_check(six_signature_manager.derive_contradictions().size() >= 3, "contradictions can cross the complete quest without collapsing to one result")
	_check(str(six_signature_manager.get_world_state().get("route_id", "")) == "context_review", "derived contradictions alter the in-world case route")
	_check(str(six_signature_manager.get_room_response("kremlin").get("notice", "")).contains("DIRECTNESS"), "Putin routing responds to earlier boundary-setting")
	_check(str(six_signature_manager.get_room_response("vault").get("notice", "")).contains("LANGUAGE ALREADY ADJUSTED"), "Lagarde routing retains speech-under-threat evidence")
	_check(str(six_signature_manager.get_room_response("elysee").get("notice", "")).contains("TERMS REQUESTED"), "Macron routing retains financial-legibility evidence")
	var first_choice_event: Dictionary = (six_signature_manager.get("events") as Array)[0]
	_check(str((first_choice_event.get("metadata", {}) as Dictionary).get("choice_text", "")) == "Approve the performance.", "choice evidence stores the visible label instead of an empty legacy field")

	var late_profile_manager := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(late_profile_manager)
	late_profile_manager.record_choice("vladimir_putin", {"label": "Adjust the wording.", "file_tag": "self-censored", "file_note": "Caution"})
	late_profile_manager.record_profile_access()
	late_profile_manager.record_choice("christine_lagarde", {"label": "Ask for terms.", "file_tag": "household-adjusted", "file_note": "Inspection"})
	_check(_has_pattern(late_profile_manager.derive_patterns(), "post_profile_behaviour_shift"), "post-profile behaviour change works across the late signatures")

	var legacy_manager := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(legacy_manager)
	legacy_manager.restore_save_data({
		"schema_version": 1,
		"events": [{"event_id": "choice:vladimir_putin", "source": "vladimir_putin", "category": "choice", "tag": "self-censored", "note": "Caution", "order": 0, "visibility": "recorded", "metadata": {}}],
	})
	_check(int((legacy_manager.derive_observation_summary().get("response_modes", {}) as Dictionary).get("concede", 0)) == 1, "schema-1 choice evidence is semantically reconstructed on restore")
	manager.queue_free()
	restored.queue_free()
	investigation_only.queue_free()
	bezos_only.queue_free()
	corridor_only.queue_free()
	ufo_only.queue_free()
	six_signature_manager.queue_free()
	late_profile_manager.queue_free()
	legacy_manager.queue_free()


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


func _wait_for_authority_launch(game: Node, procedure: Node, timeout := 1.0) -> void:
	var elapsed := 0.0
	while elapsed < timeout and (bool(game.get("is_dialogue_open")) or not bool(procedure.get("active"))):
		await create_timer(0.05).timeout
		elapsed += 0.05


func _finish() -> void:
	if failures.is_empty():
		print("SMOKE_TEST_OK")
		quit(0)
		return
	for failure in failures:
		push_error("SMOKE_TEST_FAILED: %s" % failure)
	quit(1)
