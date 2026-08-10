extends Node

var quest_order: Array = [
	"donald_trump", "elon_musk", "ursula_von_der_leyen",
	"vladimir_putin", "christine_lagarde", "emmanuel_macron"
]
var quest_completed: Dictionary = {}
var quest_index: int = -1
var quest_finished: bool = false
var encounter_residues: Dictionary = {}
var encounter_marks: Dictionary = {}
var optional_dialogue_seen: Dictionary = {}


func build_ai_dialogue(ai_terminal_data: Dictionary, display_name_resolver: Callable, saw_hidden_bunker: bool) -> Array:
	if ai_terminal_data.is_empty():
		return ["System offline. Try again later."]

	if quest_finished:
		var completed_lines: Array = ["You already have all signatures. The file still has you."]
		_append_final_file_notes(completed_lines, saw_hidden_bunker)
		return completed_lines

	var phases: Dictionary = ai_terminal_data.get("phases", {})
	var phase_key := ""
	var last_done := ""

	if quest_index < 0:
		phase_key = "intro"
		quest_index = 0
	elif quest_index < quest_order.size():
		last_done = quest_order[quest_index - 1] if quest_index > 0 else ""
		if last_done != "" and quest_completed.has(last_done):
			phase_key = "after_%s" % last_done
		else:
			var target_name: String = quest_order[quest_index]
			var display := str(display_name_resolver.call(target_name))
			return ["You haven't talked to %s yet. Go on, I'll wait. It's not like I have feelings." % display]

	if quest_index >= quest_order.size() and not quest_finished:
		phase_key = "after_%s" % quest_order[quest_order.size() - 1]
		last_done = quest_order[quest_order.size() - 1]
		quest_finished = true

	var lines: Array
	if phases.has(phase_key):
		var phase: Dictionary = phases[phase_key]
		lines = Array(phase.get("lines", ["..."])).duplicate()
	else:
		lines = ["..."]

	if last_done != "":
		var ai_mark_line := build_ai_mark_line(last_done)
		if ai_mark_line != "":
			lines.append(ai_mark_line)

	if quest_finished:
		_append_final_file_notes(lines, saw_hidden_bunker)
	return lines


func build_politician_dialogue(character_id: String, character_data: Dictionary, display_name_resolver: Callable) -> Dictionary:
	var quest_dialogue: Dictionary = character_data.get("quest_dialogue", {})
	var is_optional := bool(character_data.get("optional", false))
	var optional_repeat_lines: Array = character_data.get("optional_repeat_lines", [])

	if not is_optional and quest_completed.has(character_id):
		return _content(["You already have my signature. What more do you want?"])

	if is_optional and optional_dialogue_seen.has(character_id) and not optional_repeat_lines.is_empty():
		return _content(optional_repeat_lines.duplicate())

	if not is_optional and quest_index < 0:
		return _content(["Protocol says you talk to C.L.A.U.D.I.A. first. Start with the kiosk, not me."])

	if not is_optional and quest_index >= 0 and quest_index < quest_order.size():
		if quest_order[quest_index] != character_id:
			var correct_name := str(display_name_resolver.call(str(quest_order[quest_index])))
			return _content(["I wasn't expecting visitors. Try %s first." % correct_name])

	if quest_dialogue.is_empty():
		return _content(["..."])

	return _content(
		quest_dialogue.get("lines", ["..."]),
		quest_dialogue.get("choices", []),
		str(quest_dialogue.get("choice_prompt", ""))
	)


func complete_dialogue(character_id: String) -> void:
	if character_id == "ai_terminal" or quest_completed.has(character_id):
		return
	if quest_index >= 0 and quest_index < quest_order.size() and quest_order[quest_index] == character_id:
		quest_completed[character_id] = true
		quest_index += 1


func is_optional_seen(character_id: String) -> bool:
	return optional_dialogue_seen.has(character_id)


func mark_optional_seen(character_id: String) -> void:
	optional_dialogue_seen[character_id] = true


func record_choice_mark(character_id: String, choice: Dictionary) -> void:
	if character_id == "ai_terminal":
		return

	var file_tag := str(choice.get("file_tag", "")).strip_edges()
	var file_note := str(choice.get("file_note", "")).strip_edges()
	var ai_comment := str(choice.get("ai_comment", "")).strip_edges()
	if file_tag == "" and file_note == "" and ai_comment == "":
		return

	encounter_marks[character_id] = {
		"file_tag": file_tag,
		"file_note": file_note,
		"ai_comment": ai_comment
	}


func build_ai_mark_line(character_id: String) -> String:
	if not encounter_marks.has(character_id):
		return ""

	var mark: Dictionary = encounter_marks[character_id]
	var ai_comment := str(mark.get("ai_comment", "")).strip_edges()
	if ai_comment != "":
		return "File note: %s" % ai_comment

	var file_note := str(mark.get("file_note", "")).strip_edges()
	if file_note != "":
		return "File note: %s" % file_note
	return ""


func build_file_summary_line() -> String:
	var tags: Array = []
	for character_id in quest_order:
		if not encounter_marks.has(character_id):
			continue
		var mark: Dictionary = encounter_marks[character_id]
		var file_tag := str(mark.get("file_tag", "")).strip_edges()
		if file_tag != "":
			tags.append(file_tag)

	if tags.is_empty():
		return ""

	var preview: Array = []
	var preview_limit: int = mini(tags.size(), 4)
	for i in range(preview_limit):
		preview.append(tags[i])

	if tags.size() > 4:
		return "File profile: %s, plus %d more marks." % [_join_readable_list(preview), tags.size() - 4]
	return "File profile: %s." % _join_readable_list(tags)


func register_encounter_residue(character_id: String, residue_id: String, residue_note: String = "") -> void:
	encounter_residues[character_id] = {
		"residue_id": residue_id,
		"note": residue_note
	}


func _append_final_file_notes(lines: Array, saw_hidden_bunker: bool) -> void:
	var summary := build_file_summary_line()
	if summary != "":
		lines.append(summary)
	if saw_hidden_bunker:
		lines.append("Administrative correction: because you visited the man in the bunker asking death for one more delivery, all obtained documents are withdrawn until further notice. In bureaucratic terms, that means until death.")


func _content(lines: Array, choices: Array = [], prompt: String = "") -> Dictionary:
	return {
		"lines": lines,
		"choices": choices,
		"choice_prompt": prompt
	}


func _join_readable_list(items: Array) -> String:
	if items.is_empty():
		return ""
	if items.size() == 1:
		return str(items[0])
	if items.size() == 2:
		return "%s and %s" % [items[0], items[1]]

	var result := ""
	for i in range(items.size()):
		var item := str(items[i])
		if i == items.size() - 1:
			result += "and %s" % item
		else:
			if i > 0:
				result += ", "
			result += item
	return result
