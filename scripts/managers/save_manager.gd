extends Node

const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://civic_nightmare_dossier.json"

var save_path: String = DEFAULT_SAVE_PATH


func setup(path_override: String = "") -> void:
	save_path = path_override if not path_override.is_empty() else DEFAULT_SAVE_PATH


func has_valid_save() -> bool:
	return not load_game().is_empty()


func save_game(snapshot: Dictionary) -> Error:
	if snapshot.is_empty():
		return ERR_INVALID_DATA

	var payload := {
		"version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"snapshot": snapshot.duplicate(true)
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()
	return OK


func load_game() -> Dictionary:
	var payload := _load_payload()
	if payload.is_empty():
		return {}
	var snapshot = payload.get("snapshot", {})
	if not snapshot is Dictionary:
		return {}
	if not snapshot.has("quest") or not snapshot.has("world") or not snapshot.has("story"):
		return {}
	return (snapshot as Dictionary).duplicate(true)


func get_save_summary() -> Dictionary:
	var payload := _load_payload()
	if payload.is_empty():
		return {}
	var snapshot = payload.get("snapshot", {})
	if not snapshot is Dictionary or load_game().is_empty():
		return {}
	var quest = snapshot.get("quest", {})
	var story = snapshot.get("story", {})
	if not quest is Dictionary or not story is Dictionary:
		return {}
	var completed = quest.get("quest_completed", {})
	var order = quest.get("quest_order", [])
	return {
		"signatures": completed.size() if completed is Dictionary else 0,
		"total_signatures": order.size() if order is Array else 0,
		"final_mission_done": bool(story.get("final_mission_done", false)),
		"saved_at_unix": int(payload.get("saved_at_unix", 0))
	}


func clear_save() -> Error:
	if not FileAccess.file_exists(save_path):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func _load_payload() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var payload = json.get_data()
	if not payload is Dictionary:
		return {}
	if int(payload.get("version", -1)) != SAVE_VERSION:
		return {}
	return payload as Dictionary
