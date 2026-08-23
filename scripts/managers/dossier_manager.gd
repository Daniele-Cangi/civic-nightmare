extends Node

const SCHEMA_VERSION := 2

# These are categorical descriptions of an observable act, not personality
# scores. The table also migrates schema-1 saves whose choice events predate
# the data-driven `observation` field now carried by characters.json.
const LEGACY_CHOICE_OBSERVATIONS := {
	"spectacle-compliant": {
		"choice_id": "trump_perform_approval",
		"response_mode": "concede",
		"pressure_channel": "loyalty_performance",
		"authority_form": "spectacular_personal",
		"resource": "approval",
		"action": "performed_approval",
	},
	"insufficiently-enthusiastic": {
		"choice_id": "trump_refuse_performance",
		"response_mode": "contest",
		"pressure_channel": "loyalty_performance",
		"authority_form": "spectacular_personal",
		"resource": "time",
		"action": "refused_performance",
	},
	"platform-opted-in": {
		"choice_id": "musk_accept_enrollment",
		"response_mode": "concede",
		"pressure_channel": "platform_enrollment",
		"authority_form": "commercial_platform",
		"resource": "autonomy",
		"action": "accepted_enrollment",
	},
	"manual-routing": {
		"choice_id": "musk_insist_manual_route",
		"response_mode": "contest",
		"pressure_channel": "platform_enrollment",
		"authority_form": "commercial_platform",
		"resource": "autonomy",
		"action": "insisted_manual_route",
	},
	"committee-pending": {
		"choice_id": "ursula_accept_delay",
		"response_mode": "concede",
		"pressure_channel": "procedural_delay",
		"authority_form": "distributed_institution",
		"resource": "time",
		"action": "accepted_delay",
	},
	"expedite-requested": {
		"choice_id": "ursula_request_exception",
		"response_mode": "contest",
		"pressure_channel": "procedural_delay",
		"authority_form": "distributed_institution",
		"resource": "time",
		"action": "requested_exception",
	},
	"self-censored": {
		"choice_id": "putin_soften_language",
		"response_mode": "concede",
		"pressure_channel": "speech_under_threat",
		"authority_form": "coercive_security",
		"resource": "speech",
		"action": "softened_language",
	},
	"remembered-by-security": {
		"choice_id": "putin_speak_plainly",
		"response_mode": "contest",
		"pressure_channel": "speech_under_threat",
		"authority_form": "coercive_security",
		"resource": "speech",
		"action": "spoke_plainly",
	},
	"household-adjusted": {
		"choice_id": "lagarde_request_cost_terms",
		"response_mode": "inspect",
		"pressure_channel": "financial_extraction",
		"authority_form": "financial_system",
		"resource": "money",
		"action": "requested_cost_legibility",
	},
	"tone-surcharged": {
		"choice_id": "lagarde_reject_public_fee",
		"response_mode": "contest",
		"pressure_channel": "financial_extraction",
		"authority_form": "financial_system",
		"resource": "money",
		"action": "rejected_public_fee",
	},
	"discursively-delayed": {
		"choice_id": "macron_indulge_discourse",
		"response_mode": "concede",
		"pressure_channel": "attention_capture",
		"authority_form": "discursive_prestige",
		"resource": "attention",
		"action": "indulged_discourse",
	},
	"procedurally-impatient": {
		"choice_id": "macron_restore_task_focus",
		"response_mode": "contest",
		"pressure_channel": "attention_capture",
		"authority_form": "discursive_prestige",
		"resource": "attention",
		"action": "restored_task_focus",
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
			"choice_id": str(choice.get("choice_id", _observation_for_tag(file_tag).get("choice_id", ""))),
			"choice_text": str(choice.get("label", choice.get("text", ""))),
			"ai_comment": ai_comment,
			"profile_was_known": profile_discovered,
			"observation": _normalise_observation(choice.get("observation", {}), file_tag),
		}
	)


func record_investigation(event_id: String, source: String, note: String, metadata: Dictionary = {}) -> bool:
	return record_event(event_id, source, "investigation", "intercepted-material", note, "recorded", metadata)


func record_protocol_deviation(event_id: String, source: String, note: String, metadata: Dictionary = {}) -> bool:
	return record_event(event_id, source, "protocol_deviation", "route-exception", note, "unresolved", metadata)


func record_anomaly(event_id: String, source: String, note: String, metadata: Dictionary = {}) -> bool:
	return record_event(event_id, source, "anomaly", "data-invalid", note, "unresolved", metadata)


func has_event(event_id: String) -> bool:
	return _has_event(event_id)


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


func derive_observation_summary() -> Dictionary:
	var summary := {
		"choice_count": 0,
		"response_modes": {},
		"pressure_channels": [],
		"authority_forms": [],
		"resources_conceded": [],
		"resources_protected": [],
		"actions": [],
	}
	for event in _events_in_category("choice"):
		var observation := _observation_for_event(event)
		if observation.is_empty():
			continue
		summary["choice_count"] = int(summary["choice_count"]) + 1
		var mode := str(observation.get("response_mode", ""))
		var modes: Dictionary = summary["response_modes"]
		modes[mode] = int(modes.get(mode, 0)) + 1
		_append_unique(summary["pressure_channels"], str(observation.get("pressure_channel", "")))
		_append_unique(summary["authority_forms"], str(observation.get("authority_form", "")))
		_append_unique(summary["actions"], str(observation.get("action", "")))
		var resource := str(observation.get("resource", ""))
		if mode == "concede":
			_append_unique(summary["resources_conceded"], resource)
		elif mode == "contest":
			_append_unique(summary["resources_protected"], resource)
	return summary


func derive_patterns() -> Array:
	var patterns: Array = []
	var choice_events := _events_in_category("choice")
	var summary := derive_observation_summary()
	var modes: Dictionary = summary.get("response_modes", {})
	if choice_events.size() >= 3:
		if int(modes.get("concede", 0)) >= 3:
			patterns.append({
				"id": "access_by_concession",
				"title": "ACCESS COST REPEATED",
				"body": "Subject repeatedly surrendered a requested resource to keep the passport procedure moving.",
				"note": "Resources observed: %s. Intent was not requested." % _human_join(summary.get("resources_conceded", [])),
			})
		if int(modes.get("contest", 0)) >= 3:
			patterns.append({
				"id": "repeated_boundary_setting",
				"title": "BOUNDARY SETTING REPEATED",
				"body": "Subject repeatedly returned the interaction to the requested public service.",
				"note": "Protected resources observed: %s." % _human_join(summary.get("resources_protected", [])),
			})
	if _has_tag("manual-routing") and _has_tag("household-adjusted"):
		patterns.append({
			"id": "terms_before_trust",
			"title": "CONDITIONS REQUIRE LEGIBILITY",
			"body": "Subject rejected platform enrollment, then requested explicit terms before accepting a financial charge.",
			"note": "The file no longer treats refusal and inspection as the same action.",
		})
	if _has_tag("expedite-requested") and _has_tag("procedurally-impatient"):
		patterns.append({
			"id": "attention_protection",
			"title": "TIME BOUNDARY REPEATED",
			"body": "Subject redirected both procedural delay and prestige discourse toward task completion.",
			"note": "The system has marked this as an unusual preference for the stated purpose of the visit.",
		})
	if choice_events.size() >= 6:
		patterns.append({
			"id": "full_authority_comparison",
			"title": "AUTHORITY COMPARISON COMPLETE",
			"body": "Subject did not respond to authority in general. Subject responded separately to spectacle, platforms, institutions, threat, price and prestige.",
			"note": "A single motive would have been easier to process. None was supplied.",
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
	if _has_tag("insufficiently-enthusiastic") and _has_tag("committee-pending"):
		contradictions.append({
			"id": "challenge_then_wait",
			"title": "PROFILE COHERENCE: LOW",
			"body": "Subject challenged personal authority, then accepted institutional delay without escalation.",
			"note": "Behaviour may vary with perceived exit options.",
		})
	if _has_tag("spectacle-compliant") and _has_tag("expedite-requested"):
		contradictions.append({
			"id": "flatter_then_expedite",
			"title": "CONTEXT VARIATION DETECTED",
			"body": "Subject accommodated visible authority but resisted distributed authority.",
			"note": "The distinction is currently being treated as suspiciously specific.",
		})
	if _has_tag("manual-routing") and _has_tag("committee-pending"):
		contradictions.append({
			"id": "manual_but_patient",
			"title": "ROUTING INCONSISTENCY",
			"body": "Subject rejected automated convenience and later accepted committee delay.",
			"note": "Preference appears to concern who wastes the time, not whether it is wasted.",
		})
	if _has_any_tag(["insufficiently-enthusiastic", "manual-routing", "expedite-requested"]) and _has_tag("self-censored"):
		contradictions.append({
			"id": "public_defiance_private_caution",
			"title": "RISK-SENSITIVE DIRECTNESS",
			"body": "Subject challenged lower-risk authority conditions, then softened language under personal threat.",
			"note": "Possible explanations: strategy, fear, survival, citizenship.",
		})
	if (_has_tag("committee-pending") and _has_tag("procedurally-impatient")) or (_has_tag("expedite-requested") and _has_tag("discursively-delayed")):
		contradictions.append({
			"id": "institutional_time_discursive_time",
			"title": "DELAY IS NOT TREATED UNIFORMLY",
			"body": "Subject valued time differently when delay was presented as procedure and when it was presented as prestige.",
			"note": "The clock appears to acquire legitimacy from the room containing it.",
		})
	if _has_tag("tone-surcharged") and _has_tag("discursively-delayed"):
		contradictions.append({
			"id": "price_contested_status_indulged",
			"title": "RESOURCE PRIORITY INCONSISTENCY",
			"body": "Subject defended public money, then donated private attention to status performance.",
			"note": "Money was protected. Time was apparently ceremonial.",
		})
	return contradictions


func derive_classification() -> String:
	var choice_count := _events_in_category("choice").size()
	if choice_count < 2:
		return "ASSESSMENT INCOMPLETE"
	if not _events_in_category("anomaly").is_empty() and not _events_in_category("protocol_deviation").is_empty():
		return "ADMINISTRATIVELY UNPREDICTABLE"
	var notification_comparison := _derive_post_profile_shift()
	if str(notification_comparison.get("id", "")) == "post_profile_behaviour_shift":
		return "COOPERATIVE UNDER OBSERVATION"
	if str(notification_comparison.get("id", "")) == "post_profile_consistency":
		return "CONSISTENT UNDER OBSERVATION"
	var contradictions := derive_contradictions()
	if choice_count >= 6 and contradictions.size() >= 2:
		return "ADMINISTRATIVELY CONTEXTUAL"
	var modes: Dictionary = derive_observation_summary().get("response_modes", {})
	if int(modes.get("concede", 0)) >= 4:
		return "COMPLIANT ACROSS CONDITIONS"
	if int(modes.get("contest", 0)) >= 4:
		return "CONDITIONALLY COOPERATIVE"
	if not contradictions.is_empty():
		return "SELECTIVELY COMPLIANT"
	return "INTERPRETATION PENDING"


func get_world_state() -> Dictionary:
	var choice_count := _events_in_category("choice").size()
	if choice_count < 2:
		return {
			"route_id": "standard",
			"visible": false,
			"terminal_message": "",
			"indicator": "!",
			"npc_posture": "standard",
			"claudia_tone": "neutral",
		}

	var route_id := "standard_review"
	var terminal_message := "CASE ROUTE\nSTANDARD REVIEW"
	var indicator := "!"
	var npc_posture := "standard"
	var claudia_tone := "smile"
	var shift := _derive_post_profile_shift()
	var contradictions := derive_contradictions()
	var patterns := derive_patterns()
	if str(shift.get("id", "")) == "post_profile_behaviour_shift":
		route_id = "adaptive_review"
		terminal_message = "CASE ROUTE\nBEHAVIOUR CHANGE REVIEW"
		indicator = "◎"
		npc_posture = "observed"
		claudia_tone = "sad"
	elif str(shift.get("id", "")) == "post_profile_consistency":
		route_id = "notification_review"
		terminal_message = "CASE ROUTE\nPOST-NOTIFICATION REVIEW"
		indicator = "◎"
		npc_posture = "observed"
		claudia_tone = "smile"
	elif not contradictions.is_empty():
		route_id = "context_review"
		terminal_message = "CASE ROUTE\nCONTEXT REVIEW"
		indicator = "?"
		npc_posture = "observed"
		claudia_tone = "smile"
	elif _has_derived_id(patterns, "repeated_boundary_setting"):
		route_id = "manual_review"
		terminal_message = "CASE ROUTE\nMANUAL REVIEW"
		indicator = "…"
		npc_posture = "manual_review"
		claudia_tone = "sad"
	elif _has_derived_id(patterns, "access_by_concession"):
		route_id = "assisted_processing"
		terminal_message = "CASE ROUTE\nASSISTED PROCESSING"
		indicator = "·"
		npc_posture = "precleared"
		claudia_tone = "exalted"

	return {
		"route_id": route_id,
		"visible": true,
		"terminal_message": terminal_message,
		"indicator": indicator,
		"npc_posture": npc_posture,
		"claudia_tone": claudia_tone,
	}


func get_room_response(room_id: String) -> Dictionary:
	var world_state := get_world_state()
	var response := {
		"route_id": str(world_state.get("route_id", "standard")),
		"subtitle": "",
		"notice": "",
		"npc_posture": str(world_state.get("npc_posture", "standard")),
	}
	match room_id:
		"kremlin":
			if _count_response_mode("contest") >= 2:
				response["subtitle"] = "VOICE ASSURANCE REVIEW"
				response["notice"] = "SPEECH ROUTE\nDIRECTNESS FLAGGED"
				response["npc_posture"] = "observed"
			elif _count_response_mode("concede") >= 2:
				response["subtitle"] = "DISCRETION ROUTE PRE-CLEARED"
				response["notice"] = "SPEECH ROUTE\nCAUTION EXPECTED"
				response["npc_posture"] = "precleared"
		"vault":
			if _has_tag("self-censored"):
				response["subtitle"] = "SECURITY NOTE: CAUTION RETAINED"
				response["notice"] = "COST REVIEW\nLANGUAGE ALREADY ADJUSTED"
				response["npc_posture"] = "precleared"
			elif _has_tag("remembered-by-security"):
				response["subtitle"] = "SECURITY NOTE ATTACHED TO ACCOUNT"
				response["notice"] = "COST REVIEW\nIDENTITY RECONFIRMED"
				response["npc_posture"] = "observed"
		"elysee":
			if _has_tag("household-adjusted"):
				response["subtitle"] = "COST DISCLOSURE ROUTE ACTIVE"
				response["notice"] = "RECEPTION ROUTE\nTERMS REQUESTED"
				response["npc_posture"] = "precleared"
			elif _has_tag("tone-surcharged"):
				response["subtitle"] = "PUBLIC-FEE DISPUTE ROUTE"
				response["notice"] = "RECEPTION ROUTE\nTONE SURCHARGE PENDING"
				response["npc_posture"] = "manual_review"

	if str(response["subtitle"]) == "" and bool(world_state.get("visible", false)):
		response["subtitle"] = str(world_state.get("terminal_message", "")).replace("CASE ROUTE\n", "ROUTING: ")
		response["notice"] = str(world_state.get("terminal_message", ""))
	return response


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
				"tone": "sad",
				"lines": [
					"You changed strategy after reading your dossier.",
					"Good news: that may be self-awareness. Bad news: the timing has been filed as evidence.",
				],
			})
		else:
			candidates.append({
				"id": "claudia_profile_consistency",
				"tone": "smile",
				"lines": [
					"You repeated your earlier strategy after reading the dossier.",
					"The system cannot distinguish consistency from a performance of consistency. It has selected both.",
				],
			})
	if get_profile_access_count() >= 3:
		candidates.append({
			"id": "claudia_screen_recheck",
			"tone": "exalted",
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
			"tone": "smile",
			"lines": [
				_claudia_contradiction_line(str(contradiction.get("id", ""))),
				"I am creating a new category. Its confidence level is excellent; its meaning is pending.",
			],
		})
	elif _events_in_category("choice").size() >= 2:
		candidates.append({
			"id": "claudia_cross_choice_comparison",
			"tone": str(get_world_state().get("claudia_tone", "neutral")),
			"lines": [
				_claudia_choice_comparison_line(),
				"One answer is a preference. Two answers are apparently a pattern. I do not make the threshold rules.",
			],
		})
	if _has_event("investigation:red_phone"):
		candidates.append({
			"id": "claudia_red_phone",
			"tone": "smile",
			"lines": [
				"An unregistered call passed through your meeting in Pyongyang.",
				"You allowed it to continue. The distinction between restraint and listening has been postponed.",
			],
		})
	if _has_event("investigation:bunker_access_corridor"):
		candidates.append({
			"id": "claudia_bunker_access_corridor",
			"tone": "sad",
			"lines": [
				"You avoided the incoming explosives and the outgoing funding.",
				"The system recorded both as transfer traffic. It considers the distinction emotional.",
			],
		})
	if _has_event("anomaly:ufo_time_discontinuity"):
		var ufo_anomaly := _event_with_id("anomaly:ufo_time_discontinuity")
		var ufo_metadata: Dictionary = ufo_anomaly.get("metadata", {})
		var observed_subjects := int(ufo_metadata.get("concurrent_subject_count", 0))
		if observed_subjects >= 3:
			candidates.append({
				"id": "claudia_ufo_observation_problem",
				"tone": "sad",
				"lines": [
					"You were recorded entering the same room three times. Only one of you left.",
					"Statistically, this is an improvement.",
				],
			})
	if _has_event("contest:putin_special_operation"):
		var putin_operation := _event_with_id("contest:putin_special_operation")
		var putin_metadata: Dictionary = putin_operation.get("metadata", {})
		var cameras_destroyed := int(putin_metadata.get("cameras_destroyed", 0))
		candidates.append({
			"id": "claudia_putin_special_operation",
			"tone": "sad" if cameras_destroyed == 0 else "exalted",
			"lines": [
				"You entered a defensive residence through an offensive corridor.",
				"The system considers this symmetrical.%s" % (" It also noticed that you shot the cameras." if cameras_destroyed > 0 else " The cameras noticed that you did not shoot them."),
			],
		})
	if _has_event("contest:bezos_fulfillment"):
		var contest_event := _event_with_id("contest:bezos_fulfillment")
		var contest_metadata: Dictionary = contest_event.get("metadata", {})
		if str(contest_event.get("tag", "")) == "physical-remedy-invalidated":
			candidates.append({
				"id": "claudia_bezos_invalidated_victory",
				"tone": "sad",
				"lines": [
					"You defeated Bezos. The result then defeated you.",
					"The system has preserved the second outcome as more procedurally mature.",
				],
			})
		elif int(contest_metadata.get("objection_count", 0)) >= 2:
			candidates.append({
				"id": "claudia_bezos_objections",
				"tone": "exalted",
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
			if str(restored_event.get("category", "")) == "choice":
				var metadata: Dictionary = restored_event.get("metadata", {})
				var tag := str(restored_event.get("tag", ""))
				if not metadata.get("observation", {}) is Dictionary or (metadata.get("observation", {}) as Dictionary).is_empty():
					metadata["observation"] = _observation_for_tag(tag)
				if str(metadata.get("choice_id", "")) == "":
					metadata["choice_id"] = str(_observation_for_tag(tag).get("choice_id", ""))
				if str(metadata.get("choice_text", "")) == "":
					metadata["choice_text"] = str(metadata.get("choice_id", tag)).replace("_", " ")
				restored_event["metadata"] = metadata
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
				if str(event.get("event_id", "")) == "contest:putin_special_operation":
					var observed_cameras := int(contest_metadata.get("cameras_destroyed", 0))
					lines.append("DEFENSIVE ACCESS COMPLETED\nSubject crossed an offensive corridor.\n%d broadcast assets were treated as hostile." % observed_cameras)
				elif str(event.get("tag", "")) == "physical-remedy-invalidated":
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
			var observation_detail := ""
			if int(metadata.get("concurrent_subject_count", 0)) > 1:
				observation_detail = "\n\nSubjects observed concurrently: %d\nCitizens registered: %d\nIdentity reconciliation: %s" % [
					int(metadata.get("concurrent_subject_count", 0)),
					int(metadata.get("registered_citizen_count", 1)),
					str(metadata.get("reconciliation", "pending")).to_upper(),
				]
			lines.append(
				("LOCATION HISTORY\n%s — Overworld\n%s — [DATA INVALID]\n%s — Overworld\n\nElapsed local time: %s\nRecorded system time: %s" % [
					str(metadata.get("before_time", "14:03")),
					str(metadata.get("invalid_time", "14:04")),
					str(metadata.get("return_time", "14:04")),
					str(metadata.get("elapsed_local", "01:12")),
					str(metadata.get("recorded_system", "17:44")),
				]) + observation_detail
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
		"public_defiance_private_caution":
			return "You challenged authority while the exits were decorative. You softened your language when they were not."
		"institutional_time_discursive_time":
			return "You treat delay differently when it arrives as procedure and when it arrives dressed as prestige."
		"price_contested_status_indulged":
			return "You protected public money, then donated private attention. I am comparing the exchange rates."
		_:
			return "Your behaviour changes with the shape of the authority in the room."


func _claudia_choice_comparison_line() -> String:
	if _has_tag("self-censored") and _has_tag("household-adjusted"):
		return "You softened your words under threat, then requested exact terms under price pressure. Caution appears to require a category."
	if _has_tag("remembered-by-security") and _has_tag("tone-surcharged"):
		return "You spoke plainly to security and plainly to finance. Both departments have named the plainness differently."
	if _has_tag("household-adjusted") and _has_tag("procedurally-impatient"):
		return "You requested the cost, then requested the point. Legibility may be the closest thing this file has to a motive."
	if _has_tag("tone-surcharged") and _has_tag("discursively-delayed"):
		return "You refused the surcharge and accepted the speech. The system is reviewing your preferred forms of expense."
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
	return str(_observation_for_tag(tag).get("response_mode", ""))


func _normalise_observation(value, fallback_tag: String) -> Dictionary:
	var fallback := _observation_for_tag(fallback_tag)
	if not value is Dictionary:
		return fallback
	var observation: Dictionary = value.duplicate(true)
	for key in ["choice_id", "response_mode", "pressure_channel", "authority_form", "resource", "action"]:
		var normalised := str(observation.get(key, fallback.get(key, ""))).strip_edges()
		if normalised != "":
			observation[key] = normalised
	return observation


func _observation_for_tag(tag: String) -> Dictionary:
	var value = LEGACY_CHOICE_OBSERVATIONS.get(tag, {})
	return value.duplicate(true) if value is Dictionary else {}


func _observation_for_event(event: Dictionary) -> Dictionary:
	var metadata: Dictionary = event.get("metadata", {})
	return _normalise_observation(metadata.get("observation", {}), str(event.get("tag", "")))


func _append_unique(values: Array, value: String) -> void:
	if value != "" and not values.has(value):
		values.append(value)


func _human_join(values: Array) -> String:
	var words: Array[String] = []
	for value in values:
		var word := str(value).replace("_", " ")
		if word != "":
			words.append(word)
	if words.is_empty():
		return "none declared"
	if words.size() == 1:
		return words[0]
	return ", ".join(words.slice(0, -1)) + " and " + words[-1]


func _has_any_tag(tags: Array) -> bool:
	for tag in tags:
		if _has_tag(str(tag)):
			return true
	return false


func _has_derived_id(items: Array, derived_id: String) -> bool:
	for item in items:
		if item is Dictionary and str(item.get("id", "")) == derived_id:
			return true
	return false


func _count_response_mode(mode: String) -> int:
	var modes: Dictionary = derive_observation_summary().get("response_modes", {})
	return int(modes.get(mode, 0))
