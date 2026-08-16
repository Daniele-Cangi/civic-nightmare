extends Node

const SCHEMA_VERSION := 1

const TAG_RULES := {
	"spectacle-compliant": {
		"strategy": "accommodate",
		"traits": {"authority_accommodation": 2},
	},
	"insufficiently-enthusiastic": {
		"strategy": "resist",
		"traits": {"procedural_resistance": 2},
	},
	"platform-opted-in": {
		"strategy": "accommodate",
		"traits": {"platform_dependence": 2, "authority_accommodation": 1},
	},
	"manual-routing": {
		"strategy": "resist",
		"traits": {"platform_dependence": -2, "procedural_resistance": 1},
	},
	"committee-pending": {
		"strategy": "accommodate",
		"traits": {"institutional_patience": 2, "authority_accommodation": 1},
	},
	"expedite-requested": {
		"strategy": "resist",
		"traits": {"institutional_patience": -2, "procedural_resistance": 1},
	},
}

var events: Array = []
var profile_discovered: bool = false
var profile_discovered_at_order: int = -1
var delivered_observations: Dictionary = {}


func reset() -> void:
	events.clear()
	profile_discovered = false
	profile_discovered_at_order = -1
	delivered_observations.clear()


func record_event(
	event_id: String,
	source: String,
	category: String,
	tag: String = "",
	note: String = "",
	visibility: String = "deferred",
	metadata: Dictionary = {}
) -> bool:
	if event_id.strip_edges() == "" or _has_event(event_id):
		return false
	events.append({
		"event_id": event_id,
		"source": source,
		"category": category,
		"tag": tag,
		"note": note,
		"order": events.size(),
		"visibility": visibility,
		"metadata": metadata.duplicate(true),
	})
	return true


func record_choice(character_id: String, choice: Dictionary) -> bool:
	var file_tag := str(choice.get("file_tag", "")).strip_edges()
	var file_note := str(choice.get("file_note", "")).strip_edges()
	var ai_comment := str(choice.get("ai_comment", "")).strip_edges()
	if file_tag == "" and file_note == "" and ai_comment == "":
		return false
	return record_event(
		"choice:%s" % character_id,
		character_id,
		"choice",
		file_tag,
		file_note,
		"recorded",
		{
			"choice_text": str(choice.get("text", "")),
			"ai_comment": ai_comment,
			"profile_was_known": profile_discovered,
		}
	)


func record_investigation(event_id: String, source: String, note: String, metadata: Dictionary = {}) -> bool:
	return record_event(event_id, source, "investigation", "intercepted-material", note, "recorded", metadata)


func record_protocol_deviation(event_id: String, source: String, note: String, metadata: Dictionary = {}) -> bool:
	return record_event(event_id, source, "protocol_deviation", "route-exception", note, "unresolved", metadata)


func record_anomaly(event_id: String, source: String, note: String, metadata: Dictionary = {}) -> bool:
	return record_event(event_id, source, "anomaly", "data-invalid", note, "unresolved", metadata)


func record_contest(event_id: String, source: String, tag: String, note: String, metadata: Dictionary = {}) -> bool:
	return record_event(event_id, source, "contest", tag, note, "recorded", metadata)


func record_profile_access(section_id: String = "citizen_dossier") -> bool:
	var access_index := get_profile_access_count() + 1
	var recorded := record_event(
		"profile_access:%d" % access_index,
		section_id,
		"profile_access",
		"subject-notified",
		"Subject accessed the administrative interpretation.",
		"internal",
		{"access_index": access_index}
	)
	if not recorded:
		return false
	if not profile_discovered:
		profile_discovered = true
		profile_discovered_at_order = int(events.back().get("order", events.size() - 1))
	return true


func derive_traits() -> Dictionary:
	var traits: Dictionary = {
		"authority_accommodation": 0,
		"procedural_resistance": 0,
		"platform_dependence": 0,
		"institutional_patience": 0,
		"protocol_deviation": 0,
		"investigative_curiosity": 0,
		"profile_awareness": 0,
		"procedural_persistence": 0,
	}
	for event in events:
		if not event is Dictionary:
			continue
		var tag := str(event.get("tag", ""))
		var rule: Dictionary = TAG_RULES.get(tag, {})
		var weights: Dictionary = rule.get("traits", {})
		for trait_id in weights:
			traits[trait_id] = int(traits.get(trait_id, 0)) + int(weights[trait_id])
		match str(event.get("category", "")):
			"investigation":
				traits["investigative_curiosity"] += 1
			"protocol_deviation":
				traits["protocol_deviation"] += 2
				traits["investigative_curiosity"] += 1
			"profile_access":
				traits["profile_awareness"] += 1
			"contest":
				traits["procedural_persistence"] += 2
				if str(event.get("tag", "")) == "physical-remedy-invalidated":
					traits["procedural_resistance"] += 1
	return traits


func derive_patterns() -> Array:
	var patterns: Array = []
	var choice_events := _events_in_category("choice")
	var traits := derive_traits()
	if choice_events.size() >= 2:
		if int(traits.get("authority_accommodation", 0)) >= 3:
			patterns.append({
				"id": "access_through_accommodation",
				"title": "REPEATED ACCESS STRATEGY",
				"body": "Subject repeatedly reduced procedural friction by accommodating the authority presenting it.",
				"note": "This is considered efficient. Intent has not been requested.",
			})
		elif int(traits.get("procedural_resistance", 0)) >= 3:
			patterns.append({
				"id": "repeated_resistance",
				"title": "PROCEDURAL FRICTION",
				"body": "Subject repeatedly challenged the terms attached to routine access.",
				"note": "The system has provisionally classified this as a scheduling preference.",
			})

	var shift := _derive_post_profile_shift()
	if not shift.is_empty():
		patterns.append(shift)
	var contest_events := _events_in_category("contest")
	if not contest_events.is_empty():
		var contest: Dictionary = contest_events.back()
		var metadata: Dictionary = contest.get("metadata", {})
		if str(contest.get("tag", "")) == "physical-remedy-invalidated":
			patterns.append({
				"id": "remedy_without_recognition",
				"title": "REMEDY / RECOGNITION DIVERGENCE",
				"body": "Subject obtained a successful physical outcome after ordinary dispute channels became unavailable.",
				"note": "The outcome was excluded. The method was retained.",
			})
		elif int(metadata.get("objection_count", 0)) > 0:
			patterns.append({
				"id": "dispute_endurance",
				"title": "AUTOMATED DISPUTE ENDURANCE",
				"body": "Subject continued objecting after the available remedy had become primarily decorative.",
				"note": "Persistence and failure to understand the interface remain equally plausible.",
			})
	return patterns


func derive_contradictions() -> Array:
	var contradictions: Array = []
	if _has_tag("spectacle-compliant") and _has_tag("manual-routing"):
		contradictions.append({
			"id": "praise_then_refuse_platform",
			"title": "CONTRADICTION DETECTED",
			"body": "Subject offered social approval to an authority, then rejected platform migration when approval was insufficiently useful.",
			"note": "Possible explanations: strategy, principle, fatigue, citizenship.",
		})
	elif _has_tag("insufficiently-enthusiastic") and _has_tag("committee-pending"):
		contradictions.append({
			"id": "challenge_then_wait",
			"title": "PROFILE COHERENCE: LOW",
			"body": "Subject challenged personal authority, then accepted institutional delay without escalation.",
			"note": "Behaviour may vary with perceived exit options.",
		})
	elif _has_tag("spectacle-compliant") and _has_tag("expedite-requested"):
		contradictions.append({
			"id": "flatter_then_expedite",
			"title": "CONTEXT VARIATION DETECTED",
			"body": "Subject accommodated visible authority but resisted distributed authority.",
			"note": "The distinction is currently being treated as suspiciously specific.",
		})
	elif _has_tag("manual-routing") and _has_tag("committee-pending"):
		contradictions.append({
			"id": "manual_but_patient",
			"title": "ROUTING INCONSISTENCY",
			"body": "Subject rejected automated convenience and later accepted committee delay.",
			"note": "Preference appears to concern who wastes the time, not whether it is wasted.",
		})
	return contradictions


func derive_classification() -> String:
	if _events_in_category("choice").size() < 2:
		return "ASSESSMENT INCOMPLETE"
	if not _events_in_category("anomaly").is_empty() and not _events_in_category("protocol_deviation").is_empty():
		return "ADMINISTRATIVELY UNPREDICTABLE"
	if not _derive_post_profile_shift().is_empty():
		return "COOPERATIVE UNDER OBSERVATION"
	if not derive_contradictions().is_empty():
		return "CONTEXT-DEPENDENT COOPERATION"
	var traits := derive_traits()
	var accommodation := int(traits.get("authority_accommodation", 0))
	var resistance := int(traits.get("procedural_resistance", 0))
	if accommodation > resistance:
		return "COMPLIANT UNTIL INFORMED"
	if resistance > accommodation and int(traits.get("institutional_patience", 0)) > 0:
		return "PROCEDURALLY HOSTILE / INSTITUTIONALLY DEPENDENT"
	if resistance > accommodation:
		return "MANAGEABLY DISSATISFIED"
	return "INTERPRETATION PENDING"


func get_visible_entries() -> Array:
	var visible: Array = []
	for event in events:
		if not event is Dictionary:
			continue
		if str(event.get("visibility", "")) == "internal" or str(event.get("category", "")) == "profile_access":
			continue
		visible.append(event.duplicate(true))
	return visible


func get_hold_sections() -> Array:
	var sections: Array = [
		{"id": "case_status", "label": "Case status"},
	]
	var visible_events := get_visible_entries()
	if not visible_events.is_empty():
		sections.append({"id": "recorded_activity", "label": "Recorded activity"})
	var choice_count := _events_in_category("choice").size()
	var has_severe_exception := (
		not _events_in_category("protocol_deviation").is_empty()
		or not _events_in_category("anomaly").is_empty()
	)
	if choice_count >= 2 or has_severe_exception or visible_events.size() >= 3:
		sections.append({"id": "citizen_dossier", "label": "Citizen dossier"})
	if profile_discovered:
		sections.append({"id": "system_interpretation", "label": "System interpretation"})
	if not _events_in_category("protocol_deviation").is_empty() or not _events_in_category("anomaly").is_empty():
		sections.append({"id": "unresolved_material", "label": "Unresolved material"})
	if _events_in_category("choice").size() >= 5:
		sections.append({"id": "final_assessment", "label": "Final assessment: PENDING"})
	return sections


func get_pause_summary(section_id: String) -> Dictionary:
	match section_id:
		"recorded_activity":
			return {
				"title": "RECENT ADMINISTRATIVE ACTIVITY",
				"lines": _recorded_activity_lines(),
			}
		"citizen_dossier":
			return {
				"title": "CITIZEN DOSSIER",
				"lines": [
					"OBSERVATIONAL FILE\nBehavioural review began before citizen notification.",
					"PROVISIONAL CLASSIFICATION\n%s" % derive_classification(),
					"NOTICE\nInterpretations may be incomplete, reductive, or administratively convenient.",
				],
			}
		"system_interpretation":
			return {
				"title": "SYSTEM INTERPRETATION",
				"lines": _interpretation_lines(),
			}
		"unresolved_material":
			return {
				"title": "UNRESOLVED MATERIAL",
				"lines": _unresolved_lines(),
			}
		"final_assessment":
			return {
				"title": "FINAL ASSESSMENT: PENDING",
				"lines": [
					"Passport determination and citizen interpretation are awaiting procedural convergence.",
					"These processes are officially unrelated.",
				],
			}
		_:
			return {
				"title": "CASE STATUS",
				"lines": _case_status_lines(),
			}


func claim_claudia_observation() -> Dictionary:
	var candidates: Array = []
	var shift := _derive_post_profile_shift()
	if not shift.is_empty():
		if str(shift.get("id", "")) == "post_profile_behaviour_shift":
			candidates.append({
				"id": "claudia_profile_shift",
				"lines": [
					"You changed strategy after reading your dossier.",
					"Good news: that may be self-awareness. Bad news: the timing has been filed as evidence.",
				],
			})
		else:
			candidates.append({
				"id": "claudia_profile_consistency",
				"lines": [
					"You repeated your earlier strategy after reading the dossier.",
					"The system cannot distinguish consistency from a performance of consistency. It has selected both.",
				],
			})
	if get_profile_access_count() >= 3:
		candidates.append({
			"id": "claudia_screen_recheck",
			"lines": [
				"You check the record quite often.",
				"That is now part of the record.",
			],
		})
	var contradictions := derive_contradictions()
	if not contradictions.is_empty():
		var contradiction: Dictionary = contradictions[0]
		candidates.append({
			"id": "claudia_%s" % str(contradiction.get("id", "contradiction")),
			"lines": [
				_claudia_contradiction_line(str(contradiction.get("id", ""))),
				"I am creating a new category. Its confidence level is excellent; its meaning is pending.",
			],
		})
	elif _events_in_category("choice").size() >= 2:
		candidates.append({
			"id": "claudia_cross_choice_comparison",
			"lines": [
				_claudia_choice_comparison_line(),
				"One answer is a preference. Two answers are apparently a pattern. I do not make the threshold rules.",
			],
		})
	if _has_event("investigation:red_phone"):
		candidates.append({
			"id": "claudia_red_phone",
			"lines": [
				"An unregistered call passed through your meeting in Pyongyang.",
				"You allowed it to continue. The distinction between restraint and listening has been postponed.",
			],
		})
	if _has_event("investigation:bunker_access_corridor"):
		candidates.append({
			"id": "claudia_bunker_access_corridor",
			"lines": [
				"You avoided the incoming explosives and the outgoing funding.",
				"The system recorded both as transfer traffic. It considers the distinction emotional.",
			],
		})
	if _has_event("contest:bezos_fulfillment"):
		var contest_event := _event_with_id("contest:bezos_fulfillment")
		var contest_metadata: Dictionary = contest_event.get("metadata", {})
		if str(contest_event.get("tag", "")) == "physical-remedy-invalidated":
			candidates.append({
				"id": "claudia_bezos_invalidated_victory",
				"lines": [
					"You defeated Bezos. The result then defeated you.",
					"The system has preserved the second outcome as more procedurally mature.",
				],
			})
		elif int(contest_metadata.get("objection_count", 0)) >= 2:
			candidates.append({
				"id": "claudia_bezos_objections",
				"lines": [
					"You objected repeatedly after the dispute had stopped accepting objections.",
					"I have filed this as persistence. The interface filed it as engagement.",
				],
			})

	for candidate in candidates:
		var observation_id := str(candidate.get("id", ""))
		if observation_id == "" or delivered_observations.has(observation_id):
			continue
		delivered_observations[observation_id] = true
		return candidate.duplicate(true)
	return {}


func get_profile_access_count() -> int:
	return _events_in_category("profile_access").size()


func get_save_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"events": events.duplicate(true),
		"profile_discovered": profile_discovered,
		"profile_discovered_at_order": profile_discovered_at_order,
		"delivered_observations": delivered_observations.duplicate(true),
	}


func restore_save_data(data: Dictionary) -> void:
	reset()
	var saved_events = data.get("events", [])
	if saved_events is Array:
		for saved_event in saved_events:
			if not saved_event is Dictionary:
				continue
			var event_id := str(saved_event.get("event_id", "")).strip_edges()
			if event_id == "" or _has_event(event_id):
				continue
			var restored_event: Dictionary = saved_event.duplicate(true)
			restored_event["order"] = events.size()
			events.append(restored_event)
	profile_discovered = bool(data.get("profile_discovered", false))
	profile_discovered_at_order = int(data.get("profile_discovered_at_order", -1))
	var observations = data.get("delivered_observations", {})
	if observations is Dictionary:
		delivered_observations = observations.duplicate(true)
	if profile_discovered and profile_discovered_at_order < 0:
		var accesses := _events_in_category("profile_access")
		if not accesses.is_empty():
			profile_discovered_at_order = int(accesses[0].get("order", -1))


func _derive_post_profile_shift() -> Dictionary:
	if not profile_discovered or profile_discovered_at_order < 0:
		return {}
	var before_strategy := ""
	var after_strategy := ""
	for event in _events_in_category("choice"):
		var strategy := _strategy_for_tag(str(event.get("tag", "")))
		if strategy == "":
			continue
		if int(event.get("order", -1)) < profile_discovered_at_order:
			before_strategy = strategy
		elif int(event.get("order", -1)) > profile_discovered_at_order and after_strategy == "":
			after_strategy = strategy
	if before_strategy == "" or after_strategy == "":
		return {}
	if before_strategy != after_strategy:
		return {
			"id": "post_profile_behaviour_shift",
			"title": "POST-NOTIFICATION VARIATION",
			"body": "Subject changed response strategy after accessing the behavioural record.",
			"note": "Causality is officially undetermined and operationally assumed.",
		}
	return {
		"id": "post_profile_consistency",
		"title": "POST-NOTIFICATION CONSISTENCY",
		"body": "Subject repeated the prior response strategy after accessing the behavioural record.",
		"note": "Possible explanations: consistency, performance of consistency, limited options.",
	}


func _case_status_lines() -> Array:
	var lines: Array = [
		"PASSPORT RENEWAL\nProcessing remains active.",
	]
	if get_visible_entries().is_empty():
		lines.append("SECONDARY REVIEW\nNo citizen-facing material is currently available.")
	else:
		lines.append("SECONDARY REVIEW\nAdministrative activity has been retained for quality purposes.")
	if profile_discovered:
		lines.append("SUBJECT NOTIFICATION\nAcknowledged by opening this interface.")
	return lines


func _recorded_activity_lines() -> Array:
	var lines: Array = []
	var visible := get_visible_entries()
	var first_index: int = maxi(visible.size() - 4, 0)
	for index in range(first_index, visible.size()):
		var event: Dictionary = visible[index]
		match str(event.get("category", "")):
			"choice":
				var choice_note := str(event.get("note", "")).strip_edges()
				lines.append("AUTHORITY INTERACTION COMPLETED\nSignature obtained.%s" % ("\n%s." % choice_note if choice_note != "" else ""))
			"investigation":
				if str(event.get("event_id", "")) == "investigation:bunker_access_corridor":
					var metadata: Dictionary = event.get("metadata", {})
					var ordnance_contact := int(metadata.get("bomb_hits", 0)) > 0
					var funding_contact := int(metadata.get("funding_contacts", 0)) > 0
					var interpretation := "Subject avoided both incoming ordnance and outgoing disbursement."
					if ordnance_contact and funding_contact:
						interpretation = "Subject made contact with both incoming ordnance and outgoing disbursement. Distinction retained."
					elif ordnance_contact:
						interpretation = "Subject accepted contact with incoming ordnance while avoiding outgoing disbursement."
					elif funding_contact:
						interpretation = "Subject avoided incoming ordnance but failed to avoid outgoing disbursement."
					lines.append("TRANSFER CORRIDOR TRAVERSED\n%s\nAccess survived." % interpretation)
				else:
					lines.append("UNSCHEDULED COMMUNICATION RETAINED\n%s" % str(event.get("note", "The material remained present after the meeting.")))
			"protocol_deviation":
				lines.append("ROUTE EXCEPTION REGISTERED\nMovement continued outside case instructions.")
			"anomaly":
				lines.append("LOCATION RECORD AMENDED\nAt least one entry could not be reconciled.")
			"contest":
				var contest_metadata: Dictionary = event.get("metadata", {})
				if str(event.get("tag", "")) == "physical-remedy-invalidated":
					lines.append("COMMERCIAL DISPUTE COMPLETED\nPhysical remedy obtained. Recognition withheld.\nMethod retained for behavioural review.")
				else:
					lines.append("COMMERCIAL DISPUTE CLOSED\n%d objections retained as engagement data." % int(contest_metadata.get("objection_count", 0)))
	if lines.is_empty():
		lines.append("No citizen-facing activity is currently available.")
	return lines


func _interpretation_lines() -> Array:
	var lines: Array = []
	for pattern in derive_patterns():
		lines.append("%s\n%s\n\nSYSTEM NOTE\n%s" % [
			str(pattern.get("title", "PATTERN DETECTED")),
			str(pattern.get("body", "")),
			str(pattern.get("note", "Explanation pending.")),
		])
	for contradiction in derive_contradictions():
		lines.append("%s\n%s\n\n%s" % [
			str(contradiction.get("title", "CONTRADICTION DETECTED")),
			str(contradiction.get("body", "")),
			str(contradiction.get("note", "Explanation pending.")),
		])
	if lines.is_empty():
		lines.append("INTERPRETATION DEFERRED\nThe available material is insufficiently contradictory.")
	return lines


func _unresolved_lines() -> Array:
	var lines: Array = []
	for event in events:
		if not event is Dictionary:
			continue
		var category := str(event.get("category", ""))
		if category == "protocol_deviation":
			lines.append(
				"PROTOCOL DEVIATION\nSubject deliberately entered a location excluded from case instructions.\n\nIntent inferred: curiosity, defiance, or poor signage."
			)
		elif category == "anomaly":
			var metadata: Dictionary = event.get("metadata", {})
			lines.append(
				"LOCATION HISTORY\n%s — Overworld\n%s — [DATA INVALID]\n%s — Overworld\n\nElapsed local time: %s\nRecorded system time: %s" % [
					str(metadata.get("before_time", "14:03")),
					str(metadata.get("invalid_time", "14:04")),
					str(metadata.get("return_time", "14:04")),
					str(metadata.get("elapsed_local", "01:12")),
					str(metadata.get("recorded_system", "17:44")),
				]
			)
	if lines.is_empty():
		lines.append("No unresolved material is available for citizen review.")
	return lines


func _claudia_contradiction_line(contradiction_id: String) -> String:
	match contradiction_id:
		"praise_then_refuse_platform":
			return "You praised the billionaire with the desk, then refused the billionaire with the platform."
		"challenge_then_wait":
			return "You challenged a man, then waited for a committee. Your risk model is becoming visible."
		"flatter_then_expedite":
			return "You flatter concentrated power and hurry distributed power. That is almost a philosophy."
		"manual_but_patient":
			return "You rejected automated convenience, then accepted committee delay."
		_:
			return "Your behaviour changes with the shape of the authority in the room."


func _claudia_choice_comparison_line() -> String:
	if _has_tag("spectacle-compliant") and _has_tag("platform-opted-in"):
		return "You accepted approval as access, then accepted a platform as access. The file appreciates consistency."
	if _has_tag("insufficiently-enthusiastic") and _has_tag("manual-routing"):
		return "You rejected both applause and migration. Repetition has upgraded your impatience into a tendency."
	if _has_tag("insufficiently-enthusiastic") and _has_tag("platform-opted-in"):
		return "You resisted the desk and accepted the platform. Your objection may be architectural."
	return "Your last two answers used the same procedure for different reasons. The procedure has discarded the reasons."


func _has_event(event_id: String) -> bool:
	for event in events:
		if event is Dictionary and str(event.get("event_id", "")) == event_id:
			return true
	return false


func _event_with_id(event_id: String) -> Dictionary:
	for event in events:
		if event is Dictionary and str(event.get("event_id", "")) == event_id:
			return event
	return {}


func _has_tag(tag: String) -> bool:
	for event in events:
		if event is Dictionary and str(event.get("tag", "")) == tag:
			return true
	return false


func _events_in_category(category: String) -> Array:
	var matches: Array = []
	for event in events:
		if event is Dictionary and str(event.get("category", "")) == category:
			matches.append(event)
	return matches


func _strategy_for_tag(tag: String) -> String:
	var rule: Dictionary = TAG_RULES.get(tag, {})
	return str(rule.get("strategy", ""))
