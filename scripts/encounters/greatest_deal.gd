extends Node

signal completed(result: Dictionary)
signal cancelled

const BACKGROUND_PATH := "res://assets/encounters/greatest_deal_stage_v1.png"
const VIEW_SIZE := Vector2(1280, 720)
const TARGET := 21
const STARTING_CHALLENGES := 3
const DEFAULT_INTRO_DURATION := 1.45
const DEFAULT_BEAT_DURATION := 1.4
const DEFAULT_OUTRO_DURATION := 1.7

enum State {
	INACTIVE,
	INTRO,
	PLAYER_TURN,
	TRUE_RESULT,
	INTERFERENCE,
	CLAIM,
	VERDICT,
	ROUND_LOST,
	CLEARED,
}

# Every hand is deterministic. The first teaches STAND, the second one HIT,
# and the third two HITs. Trump may alter the declared result only after the
# real blackjack result has been shown and frozen on screen.
const ROUND_DATA := [
	{
		"trump": [
			{"rank": "K", "suit": "♠", "value": 10},
			{"rank": "8", "suit": "♦", "value": 8},
		],
		"citizen": [
			{"rank": "A", "suit": "♣", "value": 11},
			{"rank": "9", "suit": "♥", "value": 9},
		],
		"draw": [
			{"rank": "5", "suit": "♣", "value": 5},
			{"rank": "10", "suit": "♦", "value": 10},
		],
		"event": {
			"title": "POLL NUMBERS",
			"line": "WINNER DECLARED: TRUMP",
			"claim": "TRUMP CLAIMS VICTORY",
		},
	},
	{
		"trump": [
			{"rank": "Q", "suit": "♣", "value": 10},
			{"rank": "9", "suit": "♦", "value": 9},
		],
		"citizen": [
			{"rank": "8", "suit": "♠", "value": 8},
			{"rank": "5", "suit": "♥", "value": 5},
		],
		"draw": [
			{"rank": "7", "suit": "♣", "value": 7},
			{"rank": "6", "suit": "♦", "value": 6},
		],
		"event": {
			"title": "EXECUTIVE ORDER",
			"line": "DEALER TOTAL ADJUSTED: 21",
			"claim": "RESULT UNDER REVIEW",
		},
	},
	{
		"trump": [
			{"rank": "K", "suit": "♥", "value": 10},
			{"rank": "Q", "suit": "♦", "value": 10},
		],
		"citizen": [
			{"rank": "10", "suit": "♠", "value": 10},
			{"rank": "2", "suit": "♣", "value": 2},
		],
		"draw": [
			{"rank": "4", "suit": "♥", "value": 4},
			{"rank": "5", "suit": "♠", "value": 5},
			{"rank": "9", "suit": "♦", "value": 9},
		],
		"event": {
			"title": "DEALER RECOUNT",
			"line": "20  →  22",
			"claim": "TRUMP CLAIMS VICTORY",
		},
	},
]

var host: Node
var layer: CanvasLayer
var root_control: Control
var frame: Control
var header_label: Label
var round_label: Label
var target_label: Label
var challenge_label: Label
var trump_total_label: Label
var citizen_total_label: Label
var true_result_label: Label
var prompt_label: Label
var trump_hand_root: Control
var citizen_hand_root: Control
var action_panels: Array[PanelContainer] = []
var action_labels: Array[Label] = []
var claim_panel: PanelContainer
var claim_label: Label
var claim_options: Label
var interference_panel: PanelContainer
var interference_title: Label
var interference_line: Label
var trump_card_nodes: Array[PanelContainer] = []
var citizen_card_nodes: Array[PanelContainer] = []

var active := false
var state: State = State.INACTIVE
var state_timer := 0.0
var intro_duration := DEFAULT_INTRO_DURATION
var beat_duration := DEFAULT_BEAT_DURATION
var outro_duration := DEFAULT_OUTRO_DURATION
var round_index := 0
var action_selection := 0
var claim_selection := 1
var challenges_remaining := STARTING_CHALLENGES
var trump_hand: Array[Dictionary] = []
var citizen_hand: Array[Dictionary] = []
var draw_index := 0
var trump_total := 0
var citizen_total := 0
var true_player_won := false
var accepted_claims := 0
var successful_challenges := 0
var failed_challenges := 0
var hit_count := 0
var stand_count := 0
var bust_count := 0
var actual_wins := 0
var attempts := 1
var interference_events: Array[String] = []
var result: Dictionary = {}


func setup(owner: Node) -> void:
	host = owner
	_create_overlay()


func start(options: Dictionary = {}) -> void:
	if not layer:
		_create_overlay()
	intro_duration = maxf(0.0, float(options.get("intro_duration", DEFAULT_INTRO_DURATION)))
	beat_duration = maxf(0.0, float(options.get("beat_duration", DEFAULT_BEAT_DURATION)))
	outro_duration = maxf(0.0, float(options.get("outro_duration", DEFAULT_OUTRO_DURATION)))
	round_index = 0
	action_selection = 0
	claim_selection = 1
	challenges_remaining = STARTING_CHALLENGES
	accepted_claims = 0
	successful_challenges = 0
	failed_challenges = 0
	hit_count = 0
	stand_count = 0
	bust_count = 0
	actual_wins = 0
	attempts = 1
	interference_events.clear()
	result.clear()
	active = true
	layer.visible = true
	_layout_frame()
	_reset_round()
	_set_state(State.INTRO)


func stop() -> void:
	active = false
	state = State.INACTIVE
	if layer:
		layer.visible = false


func process_frame(delta: float) -> void:
	if not active:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		stop()
		cancelled.emit()
		return
	state_timer += delta
	match state:
		State.INTRO:
			if state_timer >= intro_duration:
				_set_state(State.PLAYER_TURN)
		State.PLAYER_TURN:
			_process_player_input()
		State.TRUE_RESULT:
			if state_timer >= beat_duration:
				_after_true_result()
		State.INTERFERENCE:
			if state_timer >= beat_duration:
				_open_claim()
		State.CLAIM:
			_process_claim_input()
		State.VERDICT:
			if state_timer >= beat_duration:
				_after_verdict()
		State.ROUND_LOST:
			if state_timer >= beat_duration:
				_reset_round()
				_set_state(State.PLAYER_TURN)
		State.CLEARED:
			if state_timer >= outro_duration:
				_finish_success()


func get_result() -> Dictionary:
	return result.duplicate(true)


func hit() -> bool:
	if not active or state != State.PLAYER_TURN:
		return false
	var draws: Array = ROUND_DATA[round_index]["draw"]
	var next_card: Dictionary
	if draw_index < draws.size():
		next_card = (draws[draw_index] as Dictionary).duplicate(true)
	else:
		next_card = {"rank": "10", "suit": "♣", "value": 10}
	draw_index += 1
	hit_count += 1
	citizen_hand.append(next_card)
	_refresh_hands()
	_refresh_totals()
	if citizen_total >= TARGET:
		_resolve_true_result()
	return true


func stand() -> bool:
	if not active or state != State.PLAYER_TURN:
		return false
	stand_count += 1
	_resolve_true_result()
	return true


func choose_claim(challenge: bool) -> void:
	if not active or state != State.CLAIM:
		return
	if challenge and challenges_remaining > 0:
		challenges_remaining -= 1
		if true_player_won:
			successful_challenges += 1
			round_index += 1
			prompt_label.text = "ORIGINAL RESULT RESTORED"
		else:
			failed_challenges += 1
			prompt_label.text = "CHALLENGE DENIED"
	else:
		accepted_claims += 1
		attempts += 1
		prompt_label.text = "CLAIM ACCEPTED  ·  DEAL AGAIN"
	claim_panel.visible = false
	interference_panel.visible = false
	_refresh_header()
	_set_state(State.VERDICT)


func _process_player_input() -> void:
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		action_selection = 1 - action_selection
		_refresh_actions()
	if Input.is_action_just_pressed("ui_accept"):
		if action_selection == 0:
			hit()
		else:
			stand()


func _process_claim_input() -> void:
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		claim_selection = 1 - claim_selection
		_refresh_claim_options()
	if Input.is_action_just_pressed("ui_accept"):
		choose_claim(claim_selection == 1)


func _resolve_true_result() -> void:
	_refresh_totals()
	var citizen_bust := citizen_total > TARGET
	var trump_bust := trump_total > TARGET
	true_player_won = not citizen_bust and (trump_bust or citizen_total > trump_total)
	if citizen_bust:
		bust_count += 1
		true_result_label.text = "CITIZEN BUSTS  ·  TRUMP WINS"
	elif true_player_won:
		actual_wins += 1
		true_result_label.text = "CITIZEN WINS  ·  %d TO %d" % [citizen_total, trump_total]
	elif citizen_total == trump_total:
		true_result_label.text = "PUSH  ·  %d TO %d" % [citizen_total, trump_total]
	else:
		true_result_label.text = "TRUMP WINS  ·  %d TO %d" % [trump_total, citizen_total]
	true_result_label.visible = true
	prompt_label.text = "REAL RESULT"
	_set_action_visibility(false)
	_set_state(State.TRUE_RESULT)


func _after_true_result() -> void:
	if not true_player_won:
		attempts += 1
		prompt_label.text = "DEAL LOST  ·  RETRY"
		_set_state(State.ROUND_LOST)
		return
	var event: Dictionary = ROUND_DATA[round_index]["event"]
	var event_title := str(event.get("title", "RESULT UNDER REVIEW"))
	interference_events.append(event_title)
	interference_title.text = event_title
	interference_line.text = str(event.get("line", "RESULT ALTERED"))
	interference_panel.visible = true
	prompt_label.text = "RESULT UNDER REVIEW"
	_set_state(State.INTERFERENCE)


func _open_claim() -> void:
	var event: Dictionary = ROUND_DATA[round_index]["event"]
	claim_selection = 1 if challenges_remaining > 0 else 0
	claim_label.text = str(event.get("claim", "TRUMP CLAIMS VICTORY"))
	claim_panel.visible = true
	_refresh_claim_options()
	_set_state(State.CLAIM)


func _after_verdict() -> void:
	if round_index >= ROUND_DATA.size():
		result = {
			"outcome": "access_granted",
			"target": TARGET,
			"accepted_claims": accepted_claims,
			"successful_challenges": successful_challenges,
			"failed_challenges": failed_challenges,
			"challenges_remaining": challenges_remaining,
			"hits": hit_count,
			"stands": stand_count,
			"busts": bust_count,
			"actual_wins": actual_wins,
			"attempts": attempts,
			"interference_events": interference_events.duplicate(),
		}
		header_label.text = "ACCESS GRANTED — TREMENDOUS"
		round_label.text = "3 / 3 DEALS CERTIFIED"
		target_label.text = "TARGET: 21"
		challenge_label.text = "CHALLENGES: 0"
		true_result_label.text = "ORIGINAL RESULTS ACCEPTED"
		true_result_label.visible = true
		prompt_label.text = ""
		_set_state(State.CLEARED)
		return
	_reset_round()
	_set_state(State.PLAYER_TURN)


func _reset_round() -> void:
	var round_data: Dictionary = ROUND_DATA[round_index]
	trump_hand = _duplicate_hand(round_data.get("trump", []))
	citizen_hand = _duplicate_hand(round_data.get("citizen", []))
	draw_index = 0
	action_selection = 0
	true_player_won = false
	true_result_label.visible = false
	claim_panel.visible = false
	interference_panel.visible = false
	prompt_label.text = "←  →  SELECT     SPACE  ·  PLAY"
	_set_action_visibility(true)
	_refresh_header()
	_refresh_hands()
	_refresh_totals()
	_refresh_actions()


func _duplicate_hand(source: Variant) -> Array[Dictionary]:
	var duplicated: Array[Dictionary] = []
	if source is Array:
		for card in source:
			if card is Dictionary:
				duplicated.append((card as Dictionary).duplicate(true))
	return duplicated


func _hand_total(hand: Array[Dictionary]) -> int:
	var total := 0
	var aces := 0
	for card in hand:
		total += int(card.get("value", 0))
		if str(card.get("rank", "")) == "A":
			aces += 1
	while total > TARGET and aces > 0:
		total -= 10
		aces -= 1
	return total


func _refresh_header() -> void:
	header_label.text = "THE GREATEST DEAL"
	round_label.text = "ROUND %d / 3" % (round_index + 1)
	target_label.text = "TARGET: 21"
	challenge_label.text = "CHALLENGES: %s" % ("◆".repeat(challenges_remaining) if challenges_remaining > 0 else "0")


func _refresh_totals() -> void:
	trump_total = _hand_total(trump_hand)
	citizen_total = _hand_total(citizen_hand)
	trump_total_label.text = "TRUMP\n%d" % trump_total
	citizen_total_label.text = "CITIZEN\n%d" % citizen_total


func _refresh_hands() -> void:
	_clear_hand(trump_hand_root, trump_card_nodes)
	_clear_hand(citizen_hand_root, citizen_card_nodes)
	_build_hand(trump_hand_root, trump_hand, trump_card_nodes, true)
	_build_hand(citizen_hand_root, citizen_hand, citizen_card_nodes, false)


func _clear_hand(hand_root: Control, nodes: Array[PanelContainer]) -> void:
	for child in hand_root.get_children():
		hand_root.remove_child(child)
		child.queue_free()
	nodes.clear()


func _build_hand(hand_root: Control, cards: Array[Dictionary], nodes: Array[PanelContainer], dealer: bool) -> void:
	var spread := 76.0
	var card_width := 116.0
	var total_width := card_width + maxf(0.0, float(cards.size() - 1) * spread)
	var start_x := 640.0 - total_width * 0.5
	for i in range(cards.size()):
		var card := _create_physical_card(cards[i], dealer)
		card.position = Vector2(start_x + i * spread, 0)
		card.z_index = i
		hand_root.add_child(card)
		nodes.append(card)


func _create_physical_card(card_data: Dictionary, dealer: bool) -> PanelContainer:
	var rank := str(card_data.get("rank", "?"))
	var suit := str(card_data.get("suit", "♠"))
	var is_red := suit in ["♥", "♦"]
	var ink := Color("#b51f2e") if is_red else Color("#11151b")
	var card := PanelContainer.new()
	card.size = Vector2(116, 150)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _card_style(Color("#d5a83c") if dealer else Color("#5d7896")))
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(content)
	var top_rank := _make_label(Vector2(10, 6), Vector2(42, 34), 24, ink)
	top_rank.text = rank
	content.add_child(top_rank)
	var top_suit := _make_label(Vector2(10, 32), Vector2(42, 30), 21, ink)
	top_suit.text = suit
	content.add_child(top_suit)
	var center_suit := _make_label(Vector2(28, 46), Vector2(60, 58), 46, ink)
	center_suit.text = suit
	center_suit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_suit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(center_suit)
	var bottom_rank := _make_label(Vector2(70, 112), Vector2(34, 28), 18, ink)
	bottom_rank.text = rank
	bottom_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(bottom_rank)
	return card


func _refresh_actions() -> void:
	for i in range(action_panels.size()):
		var selected := i == action_selection
		action_panels[i].add_theme_stylebox_override("panel", _panel_style(
			Color("#ffe16b") if selected else Color("#77818d"),
			Color(0.025, 0.035, 0.045, 0.95),
			4 if selected else 2
		))
		action_labels[i].text = ("▶ " if selected else "  ") + ("HIT" if i == 0 else "STAND")


func _set_action_visibility(visible_value: bool) -> void:
	for panel in action_panels:
		panel.visible = visible_value


func _refresh_claim_options() -> void:
	var accept := "▶ ACCEPT" if claim_selection == 0 else "  ACCEPT"
	var challenge := "▶ CHALLENGE" if claim_selection == 1 else "  CHALLENGE"
	if challenges_remaining <= 0:
		challenge = "  CHALLENGE  [0]"
	claim_options.text = "%s          %s" % [accept, challenge]


func _finish_success() -> void:
	var final_result := result.duplicate(true)
	stop()
	completed.emit(final_result)


func _set_state(next_state: State) -> void:
	state = next_state
	state_timer = 0.0


func _create_overlay() -> void:
	layer = CanvasLayer.new()
	layer.name = "GreatestDealLayer"
	layer.layer = 113
	layer.visible = false
	add_child(layer)

	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root_control)
	var blackout := ColorRect.new()
	blackout.set_anchors_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color("#030405")
	root_control.add_child(blackout)

	frame = Control.new()
	frame.size = VIEW_SIZE
	frame.clip_contents = true
	root_control.add_child(frame)
	root_control.resized.connect(_layout_frame)

	var background := TextureRect.new()
	background.size = VIEW_SIZE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture = load(BACKGROUND_PATH) if ResourceLoader.exists(BACKGROUND_PATH) else null
	frame.add_child(background)

	var top_bar := ColorRect.new()
	top_bar.size = Vector2(1280, 116)
	top_bar.color = Color(0.018, 0.02, 0.026, 0.93)
	frame.add_child(top_bar)
	header_label = _make_label(Vector2(40, 12), Vector2(1200, 38), 27, Color("#ffd34d"))
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(header_label)
	round_label = _make_label(Vector2(45, 67), Vector2(260, 30), 19, Color.WHITE)
	frame.add_child(round_label)
	target_label = _make_label(Vector2(490, 61), Vector2(300, 38), 23, Color("#ffe681"))
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(target_label)
	challenge_label = _make_label(Vector2(890, 67), Vector2(345, 30), 19, Color("#ffd34d"))
	challenge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	frame.add_child(challenge_label)

	trump_hand_root = Control.new()
	trump_hand_root.position = Vector2(0, 135)
	trump_hand_root.size = Vector2(1280, 150)
	trump_hand_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(trump_hand_root)
	citizen_hand_root = Control.new()
	citizen_hand_root.position = Vector2(0, 540)
	citizen_hand_root.size = Vector2(1280, 150)
	citizen_hand_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(citizen_hand_root)

	var trump_total_panel := _make_status_panel(Vector2(72, 288), Color("#d0a23a"))
	frame.add_child(trump_total_panel)
	trump_total_label = _make_label(Vector2(8, 9), Vector2(174, 76), 22, Color("#ffd65f"))
	trump_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trump_total_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trump_total_panel.get_child(0).add_child(trump_total_label)
	var citizen_total_panel := _make_status_panel(Vector2(1018, 288), Color("#6b91b7"))
	frame.add_child(citizen_total_panel)
	citizen_total_label = _make_label(Vector2(8, 9), Vector2(174, 76), 22, Color("#d9ecff"))
	citizen_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	citizen_total_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	citizen_total_panel.get_child(0).add_child(citizen_total_label)

	for i in range(2):
		var action := PanelContainer.new()
		action.position = Vector2(421 + i * 225, 389)
		action.size = Vector2(212, 65)
		action.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(action)
		action_panels.append(action)
		var action_content := Control.new()
		action_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action.add_child(action_content)
		var action_label := _make_label(Vector2(8, 13), Vector2(196, 38), 24, Color.WHITE)
		action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		action_content.add_child(action_label)
		action_labels.append(action_label)

	true_result_label = _make_label(Vector2(290, 492), Vector2(700, 38), 23, Color("#fff0a3"))
	true_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(true_result_label)
	prompt_label = _make_label(Vector2(330, 461), Vector2(620, 30), 15, Color("#d5d8dc"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(prompt_label)

	interference_panel = PanelContainer.new()
	interference_panel.position = Vector2(477, 288)
	interference_panel.size = Vector2(326, 158)
	interference_panel.add_theme_stylebox_override("panel", _special_card_style())
	frame.add_child(interference_panel)
	var interference_content := Control.new()
	interference_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interference_panel.add_child(interference_content)
	interference_title = _make_label(Vector2(17, 18), Vector2(292, 48), 23, Color("#271500"))
	interference_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interference_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interference_content.add_child(interference_title)
	interference_line = _make_label(Vector2(17, 82), Vector2(292, 50), 17, Color("#38140e"))
	interference_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interference_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interference_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interference_content.add_child(interference_line)
	interference_panel.visible = false

	claim_panel = PanelContainer.new()
	claim_panel.position = Vector2(325, 289)
	claim_panel.size = Vector2(630, 162)
	claim_panel.add_theme_stylebox_override("panel", _panel_style(Color("#ef4737"), Color(0.025, 0.02, 0.02, 0.98), 4))
	frame.add_child(claim_panel)
	var claim_content := Control.new()
	claim_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	claim_panel.add_child(claim_content)
	claim_label = _make_label(Vector2(20, 18), Vector2(590, 51), 28, Color("#ffdc62"))
	claim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	claim_content.add_child(claim_label)
	claim_options = _make_label(Vector2(20, 98), Vector2(590, 37), 20, Color.WHITE)
	claim_options.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	claim_content.add_child(claim_options)
	claim_panel.visible = false


func _make_status_panel(position_value: Vector2, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.size = Vector2(190, 94)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(border, Color(0.02, 0.028, 0.04, 0.94), 3))
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)
	return panel


func _make_label(position_value: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position_value
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _card_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f4ead2")
	style.border_color = border
	style.set_border_width_all(4)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.62)
	style.shadow_size = 8
	style.shadow_offset = Vector2(6, 7)
	return style


func _special_card_style() -> StyleBoxFlat:
	var style := _panel_style(Color("#a91d17"), Color("#e9bd45"), 5)
	style.shadow_color = Color(0, 0, 0, 0.68)
	style.shadow_size = 10
	style.shadow_offset = Vector2(7, 8)
	return style


func _panel_style(border: Color, fill: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style


func _layout_frame() -> void:
	if not root_control or not frame:
		return
	var viewport_size := root_control.size
	var scale_factor := minf(viewport_size.x / VIEW_SIZE.x, viewport_size.y / VIEW_SIZE.y)
	frame.scale = Vector2.ONE * scale_factor
	frame.position = (viewport_size - VIEW_SIZE * scale_factor) * 0.5
