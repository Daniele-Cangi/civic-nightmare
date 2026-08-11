extends SceneTree

const CHARACTER_VISUAL_CATALOG = preload("res://scripts/data/character_visual_catalog.gd")
const QUEST_MANAGER_SCRIPT = preload("res://scripts/managers/quest_manager.gd")
const SAVE_MANAGER_SCRIPT = preload("res://scripts/managers/save_manager.gd")

const TEST_SAVE_PATH := "user://civic_nightmare_smoke_dossier.json"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	_test_save_manager_round_trip()
	_test_quest_manager_round_trip()

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
	_check(mk_sequence != null, "MK sequence is initialized")
	_check(ending_sequence != null, "ending sequence is initialized")
	_check(environment_effects != null, "environment effects are initialized")
	_check(world_landmark_builder != null, "world landmark builder is initialized")
	_check(ufo_encounter != null, "UFO encounter is initialized")
	_check(bezos_drone_encounter != null, "Bezos drone encounter is initialized")
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

	game.call("_close_dialogue")
	await create_timer(0.35).timeout
	_check(not bool(game.get("is_dialogue_open")), "dialogue closes after its exit animation")

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
	_check(player.get_parent() == entities, "Continue always resumes in the overworld")

	_finish()


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
		"rooms": {}
	}
	_check(manager.save_game(snapshot) == OK, "versioned dossier can be written")
	var restored: Dictionary = manager.load_game()
	_check(not restored.is_empty(), "versioned dossier can be loaded")
	_check(float(restored["world"]["safe_position"][0]) == 12.5, "dossier preserves checkpoint coordinates")
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


func _finish() -> void:
	if failures.is_empty():
		print("SMOKE_TEST_OK")
		quit(0)
		return
	for failure in failures:
		push_error("SMOKE_TEST_FAILED: %s" % failure)
	quit(1)
