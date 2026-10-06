extends SceneTree

const DEFAULT_PATH := "res://data/characters.json"

var errors: Array[String] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var path := args[0] if not args.is_empty() else DEFAULT_PATH
	_validate_file(path)
	if errors.is_empty():
		print("CHARACTER_DATA_OK: %s" % path)
		quit(0)
		return
	for error in errors:
		push_error(error)
	quit(1)


func _validate_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("file", "cannot open %s" % path)
		return
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		_fail("file", "invalid JSON at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return
	var data = json.get_data()
	if not data is Array:
		_fail("file", "top level must be an array of characters")
		return
	var seen_ids := {}
	for index in range(data.size()):
		var entry = data[index]
		if not entry is Dictionary:
			_fail("character[%d]" % index, "entry must be an object")
			continue
		var character := entry as Dictionary
		var raw_id = character.get("id", "")
		if not raw_id is String or (raw_id as String).strip_edges().is_empty():
			_fail("character[%d].id" % index, "must be a non-empty string")
			continue
		var character_id := (raw_id as String).strip_edges()
		if seen_ids.has(character_id):
			_fail(character_id + ".id", "duplicates character[%d]" % int(seen_ids[character_id]))
		else:
			seen_ids[character_id] = index
		_validate_character(character_id, character)


func _validate_character(character_id: String, character: Dictionary) -> void:
	_validate_optional_lines(character_id, character, "access_challenge_intro")
	_validate_optional_lines(character_id, character, "optional_repeat_lines")
	if character.has("quest_dialogue"):
		var dialogue = character["quest_dialogue"]
		if not dialogue is Dictionary:
			_fail(character_id + ".quest_dialogue", "must be an object")
		else:
			_validate_dialogue(character_id + ".quest_dialogue", dialogue as Dictionary)
	if character.has("optional_followups"):
		var followups = character["optional_followups"]
		if not followups is Dictionary:
			_fail(character_id + ".optional_followups", "must be an object")
		else:
			for followup_id in followups:
				_validate_string_array(
					character_id + ".optional_followups." + str(followup_id),
					followups[followup_id]
				)
	if character_id == "ai_terminal":
		_validate_ai_phases(character)


func _validate_dialogue(field: String, dialogue: Dictionary) -> void:
	if not dialogue.has("lines"):
		_fail(field + ".lines", "is required")
	else:
		_validate_string_array(field + ".lines", dialogue["lines"])
	if not dialogue.has("choices"):
		return
	var choices = dialogue["choices"]
	if not choices is Array:
		_fail(field + ".choices", "must be an array")
		return
	for index in range(choices.size()):
		var choice = choices[index]
		var choice_field := "%s.choices[%d]" % [field, index]
		if not choice is Dictionary:
			_fail(choice_field, "must be an object")
			continue
		if not choice.get("label", null) is String:
			_fail(choice_field + ".label", "must be a string")
		if choice.has("response"):
			_validate_string_array(choice_field + ".response", choice["response"])


func _validate_ai_phases(character: Dictionary) -> void:
	var phases = character.get("phases", null)
	if not phases is Dictionary:
		_fail("ai_terminal.phases", "must be an object")
		return
	for phase_id in phases:
		var phase = phases[phase_id]
		var phase_field := "ai_terminal.phases." + str(phase_id)
		if not phase is Dictionary:
			_fail(phase_field, "must be an object")
			continue
		if not phase.has("lines"):
			_fail(phase_field + ".lines", "is required")
		else:
			_validate_string_array(phase_field + ".lines", phase["lines"])


func _validate_optional_lines(character_id: String, character: Dictionary, key: String) -> void:
	if character.has(key):
		_validate_string_array(character_id + "." + key, character[key])


func _validate_string_array(field: String, value) -> void:
	if not value is Array:
		_fail(field, "must be an array of strings")
		return
	for index in range(value.size()):
		if not value[index] is String:
			_fail("%s[%d]" % [field, index], "must be a string")


func _fail(field: String, message: String) -> void:
	errors.append("%s: %s" % [field, message])
