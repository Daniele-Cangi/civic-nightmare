extends SceneTree

const CHARACTER_VISUAL_CATALOG = preload("res://scripts/data/character_visual_catalog.gd")
const DIALOGUE_MANAGER_SCRIPT = preload("res://scripts/managers/dialogue_manager.gd")
const QUEST_MANAGER_SCRIPT = preload("res://scripts/managers/quest_manager.gd")
const SAVE_MANAGER_SCRIPT = preload("res://scripts/managers/save_manager.gd")
const DOSSIER_MANAGER_SCRIPT = preload("res://scripts/managers/dossier_manager.gd")

const TEST_SAVE_PATH := "user://civic_nightmare_smoke_dossier.json"
const WORLD_DISTRICT_PLATE_PATH := "res://assets/backgrounds/world_district_plate_v2.png"

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
	_test_authority_facades()
	_test_world_district_plate()
	_test_ai_terminal_assets()
	_test_ai_terminal_expressions()

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
	_check(ufo_encounter != null, "UFO encounter is initialized")
	_check(bezos_drone_encounter != null, "Bezos drone encounter is initialized")
	var authority_facades := game.get_tree().get_nodes_in_group("authority_facade")
	_check(authority_facades.size() == 6, "all six authority facades are placed in the overworld")
	var facade_character_ids: Dictionary = {}
	for facade in authority_facades:
		facade_character_ids[str(facade.get_meta("character_id", ""))] = true
	for character_id in CHARACTER_VISUAL_CATALOG.AUTHORITY_FACADE_PATHS:
		_check(facade_character_ids.has(character_id), "%s receives its authority facade" % character_id)
	var ground_map: TileMap = game.get("ground_map")
	var expected_authority_centers := {
		"oval_office": Vector2i(16, -16),
		"spaceship": Vector2i(-16, -16),
		"eu_palace": Vector2i(16, 0),
		"kremlin": Vector2i(-16, 0),
		"vault": Vector2i(16, 16),
		"elysee": Vector2i(-16, 16)
	}
	for building_spec in game.get("building_specs"):
		var building_center: Vector2i = building_spec["center"]
		_check(ground_map.get_cell_source_id(2, building_center) == -1, "%s old roof tiles are hidden behind the hero facade" % building_spec["key"])
		_check(building_center == expected_authority_centers[building_spec["key"]], "%s is centered on its authored district clearing" % building_spec["key"])
		_check((building_spec["entrance"] as Vector2i).x == building_center.x, "%s entrance stays aligned with its facade" % building_spec["key"])
		_check((building_spec["npc_spawn"] as Vector2i).x == building_center.x, "%s NPC spawn stays aligned with its facade" % building_spec["key"])
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
	_check(not solid_positions.has(putin_center + Vector2i(0, 6)), "Putin exterior doorway remains accessible")
	var district_plates := game.get_tree().get_nodes_in_group("world_district_plate")
	_check(district_plates.size() == 1, "the overworld installs exactly one district ground plate")
	_check(ground_map.get_cell_source_id(0, Vector2i(8, 12)) == -1, "the ground plate replaces repeated biome field tiles")
	_check(ground_map.get_cell_source_id(0, Vector2i.ZERO) == -1, "legacy path tiles do not band the authored civic corridor")
	if ending_sequence:
		for final_case in [[0, "wouldn't matter"], [1, "almost didn't"], [-1, "only honest"]]:
			ending_sequence.call("configure_final_credits", final_case[0], "still here")
			var configured_scenes: Array = ending_sequence.get("ending_scenes")
			_check(configured_scenes.size() == 13, "final credits contain every scene")
			_check(str(configured_scenes[2]).contains(final_case[1]), "final credits reflect choice %s" % final_case[0])
			_check(str(configured_scenes[10]) == "\"still here\"", "final credits include the margin note")
		ending_sequence.call("configure_final_credits", 0, "")
		_check(str((ending_sequence.get("ending_scenes") as Array)[10]) == "[left blank]", "final credits preserve a blank margin")
	_check(game.get_node_or_null("Entities/GreatWallEntrance") != null, "Great Wall landmark is created")
	_check(game.get_node_or_null("Entities/NuclearPlantEntrance") != null, "nuclear plant landmark is created")
	_check(game.get_node_or_null("Entities/HiddenBunkerEntrance") != null, "hidden bunker landmark is created")
	_check(game.get_node_or_null("Entities/PyongyangEntrance") != null, "Pyongyang landmark is created")
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
		_check(bezos_drone_encounter.get("bezos_drone_root") != null, "Bezos drone world node is created")

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

	game.call("_start_bezos_escalation")
	await process_frame
	_check(bool(bezos_drone_encounter.get("bezos_escalation_active")), "Bezos drone prelude starts")
	bezos_drone_encounter.call("prepare_cinematic")
	_check(not bool(bezos_drone_encounter.get("bezos_escalation_active")), "Bezos drone prelude hands off cleanly")

	var resume_snapshot: Dictionary = game.call("_build_save_snapshot")
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
	_check((dossier_manager.get("events") as Array).size() == 1, "Continue restores integrated behavioural evidence")
	_check(player.get_parent() == entities, "Continue always resumes in the overworld")

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
		_check(texture.get_height() >= 280 and texture.get_height() <= 330, "%s authority facade fits the world footprint" % character_id)
		var image := texture.get_image()
		_check(image != null and image.get_pixel(0, 0).a < 0.05, "%s authority facade has a transparent corner" % character_id)


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
		"world": {"safe_position": [12.5, -8.0]},
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
	_check(_has_dossier_section(manager, "unresolved_material"), "deviation and anomaly unlock unresolved material")
	_check((manager.get_pause_summary("unresolved_material").get("lines", []) as Array).size() == 2, "unresolved material distinguishes bunker and UFO evidence")
	var investigation_only := DOSSIER_MANAGER_SCRIPT.new()
	root.add_child(investigation_only)
	investigation_only.record_investigation("investigation:red_phone", "pyongyang_red_phone", "Private channel remained open.")
	_check(str(investigation_only.claim_claudia_observation().get("id", "")) == "claudia_red_phone", "Red Phone evidence creates a later CLAUDIA callback")

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
