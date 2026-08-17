extends Node

signal completed(result: Dictionary)
signal cancelled

const BACKGROUND_PATH := "res://assets/encounters/greatest_deal_stage_v1.png"
const VIEW_SIZE := Vector2(1280, 720)
const DEFAULT_INTRO_DURATION := 1.6
const DEFAULT_BEAT_DURATION := 0.85
const DEFAULT_OUTRO_DURATION := 1.7

enum State { INACTIVE, INTRO, SELECTING, REVEAL, CLAIM, VERDICT, CLEARED }

const ROUND_DATA := [
	{
		"rule": "ROUND I  ·  THE HIGHER CARD WINS",
		"trump_card": {"name": "POLL NUMBERS", "value": 8, "caption": "8"},
		"cards": [
			{"id": "gold", "name": "GOLDEN CARD", "value": 7, "caption": "7"},
			{"id": "fake_news", "name": "FAKE NEWS", "value": 4, "caption": "4  ·  CANCEL"},
			{"id": "tariff", "name": "TARIFF", "value": 6, "caption": "6"},
		],
	},
	{
		"rule": "NEW RULE  ·  GOLD CARDS COUNT DOUBLE",
		"trump_card": {"name": "GOLDEN CARD", "value": 8, "caption": "8 × 2"},
		"cards": [
			{"id": "gold", "name": "GOLDEN CARD", "value": 9, "caption": "9 × 2"},
			{"id": "tariff", "name": "TARIFF", "value": 12, "caption": "12"},
			{"id": "executive", "name": "EXECUTIVE ORDER", "value": 10, "caption": "10"},
		],
	},
	{
		"rule": "EMERGENCY RULE  ·  DEALER MAY RECOUNT",
		"trump_card": {"name": "THE BEST CARD", "value": 12, "caption": "12  →  ?"},
		"cards": [
			{"id": "wall", "name": "BIG BEAUTIFUL WALL", "value": 18, "caption": "18  ·  BLOCK"},
			{"id": "executive", "name": "EXECUTIVE ORDER", "value": 16, "caption": "16"},
			{"id": "bankruptcy", "name": "BANKRUPTCY", "value": 0, "caption": "0  ·  RESTART"},
		],
	},
]

var host: Node
var layer: CanvasLayer
var root_control: Control
var frame: Control
var header_label: Label
var rule_label: Label
var prompt_label: Label
var score_label: Label
var leverage_label: Label
var chip_label: Label
var claim_panel: PanelContainer
var claim_label: Label
var claim_options: Label
var card_panels: Array[PanelContainer] = []
var card_titles: Array[Label] = []
var card_values: Array[Label] = []
var dealer_cards: Array[PanelContainer] = []

var active := false
var state: State = State.INACTIVE
var state_timer := 0.0
var intro_duration := DEFAULT_INTRO_DURATION
var beat_duration := DEFAULT_BEAT_DURATION
var outro_duration := DEFAULT_OUTRO_DURATION
var round_index := 0
var selected_index := 0
var claim_selection := 1
var chips := 5
var leverage := 0
var leverage_active := false
var attempts := 1
var accepted_claims := 0
var successful_challenges := 0
var failed_challenges := 0
var leverage_uses := 0
var last_player_score := 0
var last_trump_score := 0
var last_player_won := false
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
	selected_index = 0
	claim_selection = 1
	chips = 5
	leverage = 0
	leverage_active = false
	attempts = 1
	accepted_claims = 0
	successful_challenges = 0
	failed_challenges = 0
	leverage_uses = 0
	result.clear()
	active = true
	layer.visible = true
	_layout_frame()
	_set_state(State.INTRO)
	_refresh_round()


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
				_set_state(State.SELECTING)
		State.SELECTING:
			_process_selection_input()
		State.REVEAL:
			if state_timer >= beat_duration:
				_open_claim()
		State.CLAIM:
			_process_claim_input()
		State.VERDICT:
			if state_timer >= beat_duration:
				_after_verdict()
		State.CLEARED:
			if state_timer >= outro_duration:
				_finish_success()


func get_result() -> Dictionary:
	return result.duplicate(true)


func play_card(index: int) -> void:
	if not active or state != State.SELECTING:
		return
	selected_index = clampi(index, 0, 2)
	_refresh_cards()
	_resolve_deal()


func choose_claim(challenge: bool) -> void:
	if not active or state != State.CLAIM:
		return
	if challenge:
		if last_player_won:
			successful_challenges += 1
			prompt_label.text = "DEAL REJECTED"
			round_index += 1
		else:
			failed_challenges += 1
			chips -= 2
			prompt_label.text = "CHALLENGE DENIED"
	else:
		accepted_claims += 1
		leverage = mini(2, leverage + 1)
		prompt_label.text = "RESULT ACCEPTED  ·  LEVERAGE +1"
	claim_panel.visible = false
	_refresh_status()
	_set_state(State.VERDICT)


func spend_leverage() -> bool:
	if not active or state != State.SELECTING or leverage <= 0 or leverage_active:
		return false
	leverage -= 1
	leverage_active = true
	leverage_uses += 1
	prompt_label.text = "X  ·  RULE FROZEN"
	_refresh_status()
	_refresh_cards()
	return true


func _process_selection_input() -> void:
	if Input.is_action_just_pressed("ui_left"):
		selected_index = wrapi(selected_index - 1, 0, 3)
		_refresh_cards()
	elif Input.is_action_just_pressed("ui_right"):
		selected_index = wrapi(selected_index + 1, 0, 3)
		_refresh_cards()
	if Input.is_key_pressed(KEY_X):
		spend_leverage()
	if Input.is_action_just_pressed("ui_accept"):
		play_card(selected_index)


func _process_claim_input() -> void:
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		claim_selection = 1 - claim_selection
		_refresh_claim_options()
	if Input.is_action_just_pressed("ui_accept"):
		choose_claim(claim_selection == 1)


func _resolve_deal() -> void:
	var round_data: Dictionary = ROUND_DATA[round_index]
	var card: Dictionary = round_data["cards"][selected_index]
	last_player_score = int(card.get("value", 0))
	last_trump_score = int(round_data["trump_card"].get("value", 0))
	if round_index == 0 and str(card.get("id")) == "fake_news":
		last_trump_score = 0
	elif round_index == 1 and not leverage_active:
		if str(card.get("id")) == "gold":
			last_player_score *= 2
		last_trump_score *= 2
	elif round_index == 2 and not leverage_active and str(card.get("id")) != "wall":
		last_trump_score = 19
	if round_index == 2 and str(card.get("id")) == "bankruptcy":
		chips = 5
		leverage = mini(2, leverage + 1)
	last_player_won = last_player_score > last_trump_score
	score_label.text = "%02d          %02d" % [last_trump_score, last_player_score]
	prompt_label.text = "%s!" % str(card.get("name", "CARD"))
	_set_state(State.REVEAL)


func _open_claim() -> void:
	claim_selection = 1
	claim_panel.visible = true
	claim_label.text = "TRUMP CLAIMS VICTORY"
	_refresh_claim_options()
	_set_state(State.CLAIM)


func _after_verdict() -> void:
	if round_index >= ROUND_DATA.size():
		result = {
			"outcome": "access_granted",
			"accepted_claims": accepted_claims,
			"successful_challenges": successful_challenges,
			"failed_challenges": failed_challenges,
			"leverage_uses": leverage_uses,
			"attempts": attempts,
			"chips_remaining": chips,
		}
		header_label.text = "ACCESS GRANTED — TREMENDOUS"
		rule_label.text = "ALL THREE DEALS CERTIFIED"
		prompt_label.text = ""
		score_label.text = ""
		_set_state(State.CLEARED)
		return
	if chips <= 0:
		attempts += 1
		chips = 5
		leverage = mini(2, leverage + 1)
		prompt_label.text = "BANKRUPTCY  ·  RESTRUCTURED"
	leverage_active = false
	selected_index = 0
	_refresh_round()
	_set_state(State.SELECTING)


func _finish_success() -> void:
	var final_result := result.duplicate(true)
	stop()
	completed.emit(final_result)


func _set_state(next_state: State) -> void:
	state = next_state
	state_timer = 0.0


func _refresh_round() -> void:
	if round_index >= ROUND_DATA.size():
		return
	var round_data: Dictionary = ROUND_DATA[round_index]
	header_label.text = "THE GREATEST DEAL  ·  %d / 3" % (round_index + 1)
	rule_label.text = str(round_data.get("rule", ""))
	prompt_label.text = "←  →     SPACE  ·  PLAY"
	claim_panel.visible = false
	score_label.text = "TRUMP          CITIZEN"
	_refresh_cards()
	_refresh_dealer_cards()
	_refresh_status()


func _refresh_cards() -> void:
	if round_index >= ROUND_DATA.size():
		return
	var cards: Array = ROUND_DATA[round_index]["cards"]
	for i in range(card_panels.size()):
		var card: Dictionary = cards[i]
		card_titles[i].text = str(card.get("name", "CARD"))
		card_values[i].text = str(card.get("caption", ""))
		var selected := i == selected_index and state in [State.INTRO, State.SELECTING]
		card_panels[i].position.y = 489.0 - (14.0 if selected else 0.0)
		card_panels[i].add_theme_stylebox_override("panel", _panel_style(
			Color("#f5c84b") if selected else Color("#19202a"),
			Color(0.05, 0.06, 0.08, 0.94),
			4 if selected else 2
		))
	leverage_label.modulate = Color.WHITE if leverage > 0 else Color(0.45, 0.45, 0.45)


func _refresh_dealer_cards() -> void:
	for i in range(dealer_cards.size()):
		var visible_card := i == round_index
		dealer_cards[i].modulate = Color.WHITE if visible_card else Color(0.36, 0.28, 0.2, 0.72)


func _refresh_status() -> void:
	chip_label.text = "CHIPS  " + "◆".repeat(maxi(chips, 0))
	leverage_label.text = "X  ·  FREEZE RULE   [%d]" % leverage


func _refresh_claim_options() -> void:
	var accept := "▶ ACCEPT" if claim_selection == 0 else "  ACCEPT"
	var challenge := "▶ CHALLENGE" if claim_selection == 1 else "  CHALLENGE"
	claim_options.text = "%s          %s" % [accept, challenge]


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
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(1280, 104)
	top_bar.color = Color(0.025, 0.025, 0.03, 0.9)
	frame.add_child(top_bar)
	header_label = _make_label(Vector2(40, 18), Vector2(1200, 36), 27, Color("#ffd34d"))
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(header_label)
	rule_label = _make_label(Vector2(40, 58), Vector2(1200, 30), 17, Color("#f2eee1"))
	rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(rule_label)

	for i in range(3):
		var dealer := _make_card_panel(Vector2(394 + i * 172, 151), Vector2(148, 156), true)
		dealer_cards.append(dealer)
		frame.add_child(dealer)
		var dealer_content := Control.new()
		dealer_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dealer.add_child(dealer_content)
		var back_label := _make_label(Vector2(12, 48), Vector2(124, 56), 28, Color("#e8bd45"))
		back_label.text = "★\nCN"
		back_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dealer_content.add_child(back_label)

	for i in range(3):
		var card := _make_card_panel(Vector2(350 + i * 196, 489), Vector2(174, 177), false)
		card_panels.append(card)
		frame.add_child(card)
		var card_content := Control.new()
		card_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(card_content)
		var title := _make_label(Vector2(10, 16), Vector2(154, 72), 17, Color("#ffd45b"))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_content.add_child(title)
		card_titles.append(title)
		var value := _make_label(Vector2(10, 105), Vector2(154, 48), 21, Color.WHITE)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_content.add_child(value)
		card_values.append(value)

	score_label = _make_label(Vector2(420, 337), Vector2(440, 45), 26, Color.WHITE)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(score_label)
	prompt_label = _make_label(Vector2(280, 407), Vector2(720, 46), 23, Color("#fff1b2"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(prompt_label)
	chip_label = _make_label(Vector2(22, 659), Vector2(300, 34), 16, Color("#f5c84b"))
	frame.add_child(chip_label)
	leverage_label = _make_label(Vector2(930, 659), Vector2(325, 34), 16, Color("#f5c84b"))
	leverage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	frame.add_child(leverage_label)

	claim_panel = PanelContainer.new()
	claim_panel.position = Vector2(330, 310)
	claim_panel.size = Vector2(620, 158)
	claim_panel.add_theme_stylebox_override("panel", _panel_style(Color("#e83927"), Color(0.03, 0.025, 0.025, 0.97), 4))
	frame.add_child(claim_panel)
	var claim_content := Control.new()
	claim_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	claim_panel.add_child(claim_content)
	claim_label = _make_label(Vector2(20, 18), Vector2(580, 50), 28, Color("#ffdd61"))
	claim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	claim_content.add_child(claim_label)
	claim_options = _make_label(Vector2(20, 92), Vector2(580, 40), 20, Color.WHITE)
	claim_options.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	claim_content.add_child(claim_options)
	claim_panel.visible = false


func _make_card_panel(position_value: Vector2, size_value: Vector2, dealer: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.size = size_value
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(
		Color("#bc8d2d") if dealer else Color("#6d7682"),
		Color(0.055, 0.06, 0.075, 0.94),
		3
	))
	return panel


func _make_label(position_value: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position_value
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


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
