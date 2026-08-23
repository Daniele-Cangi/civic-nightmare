extends Node

signal completed(result: Dictionary)

const BACKGROUND_PATH := "res://assets/encounters/greatest_deal_stage_v1.png"
const MUSIC_PATH := "res://assets/audio/civic_nightmare_greatest_deal_snake_eyes.ogg"
const VIEW_SIZE := Vector2(1280, 720)
const TARGET := 21
const REQUIRED_MAJORITY := 3
const STARTING_CHALLENGES := 4
const MUSIC_VOLUME_DB := -8.5
const MUSIC_LOOP_OFFSET := 10.0
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
	CLEARED,
}

# Five distinct hands create a fixed certified-majority match. Four are
# winnable with readable blackjack play; one is a legitimate Trump 21. Trump
# claims every hand only after the mathematical result has been frozen, so a
# challenge can finally be correct or wrong without hiding the arithmetic.
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
			{"rank": "A", "suit": "♠", "value": 11},
			{"rank": "K", "suit": "♦", "value": 10},
		],
		"citizen": [
			{"rank": "9", "suit": "♠", "value": 9},
			{"rank": "9", "suit": "♥", "value": 9},
		],
		"draw": [
			{"rank": "2", "suit": "♣", "value": 2},
			{"rank": "10", "suit": "♦", "value": 10},
		],
		"event": {
			"title": "ACCURATE FOR ONCE",
			"line": "DEALER TOTAL REMAINS: 21",
			"claim": "TRUMP CLAIMS ACTUAL VICTORY",
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
	{
		"trump": [
			{"rank": "K", "suit": "♣", "value": 10},
			{"rank": "8", "suit": "♥", "value": 8},
		],
		"citizen": [
			{"rank": "7", "suit": "♠", "value": 7},
			{"rank": "8", "suit": "♦", "value": 8},
		],
		"draw": [
			{"rank": "4", "suit": "♣", "value": 4},
			{"rank": "Q", "suit": "♥", "value": 10},
		],
		"event": {
			"title": "TARIFF RECOUNT",
			"line": "19  →  17  IMPORTED POINTS",
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
var music_player: AudioStreamPlayer
var card_slide_audio: AudioStreamPlayer
var card_land_audio: AudioStreamPlayer
var action_audio: AudioStreamPlayer
var ruling_audio: AudioStreamPlayer

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
var citizen_deals := 0
var trump_deals := 0
var accepted_false_claims := 0
var accepted_valid_claims := 0
var interference_events: Array[String] = []
var result: Dictionary = {}


func setup(owner: Node) -> void:
	host = owner
	_create_overlay()
	_create_audio()


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
	citizen_deals = 0
	trump_deals = 0
	accepted_false_claims = 0
	accepted_valid_claims = 0
	interference_events.clear()
	result.clear()
	active = true
	layer.visible = true
	_layout_frame()
	_start_audio()
	_deal_round()
	_set_state(State.INTRO)


func stop() -> void:
	active = false
	state = State.INACTIVE
	_stop_audio()
	if layer:
		layer.visible = false


func process_frame(delta: float) -> void:
	if not active:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		prompt_label.text = "CERTIFICATION CANNOT BE SUSPENDED"
		_play_ruling_audio(0.62)
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
	_refresh_hands(false, true)
	_refresh_totals()
	if citizen_total >= TARGET:
		_resolve_true_result()
	return true


func stand() -> bool:
	if not active or state != State.PLAYER_TURN:
		return false
	stand_count += 1
	_play_action_audio(0.86)
	_resolve_true_result()
	return true


func choose_claim(challenge: bool) -> void:
	if not active or state != State.CLAIM:
		return
	_play_action_audio(1.28 if challenge else 0.78)
	if challenge and challenges_remaining > 0:
		challenges_remaining -= 1
		if true_player_won:
			successful_challenges += 1
			citizen_deals += 1
			prompt_label.text = "ORIGINAL RESULT RESTORED  ·  CITIZEN +1"
		else:
			failed_challenges += 1
			trump_deals += 1
			prompt_label.text = "CHALLENGE DENIED  ·  TRUMP +1"
	else:
		accepted_claims += 1
		trump_deals += 1
		if true_player_won:
			accepted_false_claims += 1
			prompt_label.text = "CLAIM ACCEPTED  ·  TRUMP +1"
		else:
			accepted_valid_claims += 1
			prompt_label.text = "RESULT ACCEPTED  ·  TRUMP +1"
	round_index += 1
	claim_panel.visible = false
	interference_panel.visible = false
	_refresh_header()
	_set_state(State.VERDICT)


func _process_player_input() -> void:
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		action_selection = 1 - action_selection
		_refresh_actions()
		_play_action_audio(1.08 + float(action_selection) * 0.12)
	if Input.is_action_just_pressed("ui_accept"):
		if action_selection == 0:
			hit()
		else:
			stand()


func _process_claim_input() -> void:
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		claim_selection = 1 - claim_selection
		_refresh_claim_options()
		_play_action_audio(0.96 + float(claim_selection) * 0.22)
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
	_play_ruling_audio(1.16 if true_player_won else 0.76)
	_set_state(State.TRUE_RESULT)


func _after_true_result() -> void:
	var event: Dictionary = ROUND_DATA[round_index]["event"]
	var event_title := str(event.get("title", "RESULT UNDER REVIEW"))
	interference_events.append(event_title)
	interference_title.text = event_title
	interference_line.text = str(event.get("line", "RESULT ALTERED"))
	interference_panel.visible = true
	prompt_label.text = "RESULT UNDER REVIEW"
	_play_ruling_audio(0.58)
	_set_state(State.INTERFERENCE)


func _open_claim() -> void:
	var event: Dictionary = ROUND_DATA[round_index]["event"]
	claim_selection = 1 if challenges_remaining > 0 else 0
	claim_label.text = str(event.get("claim", "TRUMP CLAIMS VICTORY"))
	claim_panel.visible = true
	_refresh_claim_options()
	_play_ruling_audio(0.88)
	_set_state(State.CLAIM)


func _after_verdict() -> void:
	if round_index >= ROUND_DATA.size():
		var citizen_majority := citizen_deals >= REQUIRED_MAJORITY
		result = {
			"outcome": "access_granted",
			"certified_winner": "citizen" if citizen_majority else "trump",
			"citizen_deals": citizen_deals,
			"trump_deals": trump_deals,
			"required_majority": REQUIRED_MAJORITY,
			"hands_played": ROUND_DATA.size(),
			"target": TARGET,
			"accepted_claims": accepted_claims,
			"accepted_false_claims": accepted_false_claims,
			"accepted_valid_claims": accepted_valid_claims,
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
		header_label.text = "CITIZEN MAJORITY — ACCESS GRANTED" if citizen_majority else "TRUMP WINS TREMENDOUSLY — ACCESS GRANTED"
		round_label.text = "FINAL  C %d · T %d" % [citizen_deals, trump_deals]
		target_label.text = "TARGET: 21"
		challenge_label.text = "CHALLENGES: %s" % ("◆".repeat(challenges_remaining) if challenges_remaining > 0 else "0")
		true_result_label.text = "CERTIFIED DEALS  ·  CITIZEN %d  /  TRUMP %d" % [citizen_deals, trump_deals]
		true_result_label.visible = true
		prompt_label.text = "ACCESS GRANTED — SURPRISING" if citizen_majority else "ACCESS GRANTED TO WITNESS THE CELEBRATION"
		_set_state(State.CLEARED)
		return
	_deal_round()
	_set_state(State.PLAYER_TURN)


func _deal_round() -> void:
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
	_refresh_hands(true, false)
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
	round_label.text = "DEAL %d / %d   C %d · T %d" % [round_index + 1, ROUND_DATA.size(), citizen_deals, trump_deals]
	target_label.text = "TARGET: 21"
	challenge_label.text = "CHALLENGES: %s" % ("◆".repeat(challenges_remaining) if challenges_remaining > 0 else "0")


func _refresh_totals() -> void:
	trump_total = _hand_total(trump_hand)
	citizen_total = _hand_total(citizen_hand)
	trump_total_label.text = "TRUMP\n%d" % trump_total
	citizen_total_label.text = "CITIZEN\n%d" % citizen_total


func _refresh_hands(animate_all: bool = false, animate_citizen_last: bool = false) -> void:
	_clear_hand(trump_hand_root, trump_card_nodes)
	_clear_hand(citizen_hand_root, citizen_card_nodes)
	_build_hand(trump_hand_root, trump_hand, trump_card_nodes, true, animate_all, false, 0)
	_build_hand(
		citizen_hand_root,
		citizen_hand,
		citizen_card_nodes,
		false,
		animate_all,
		animate_citizen_last,
		trump_hand.size() if animate_all else 0
	)


func _clear_hand(hand_root: Control, nodes: Array[PanelContainer]) -> void:
	for child in hand_root.get_children():
		hand_root.remove_child(child)
		child.queue_free()
	nodes.clear()


func _build_hand(
	hand_root: Control,
	cards: Array[Dictionary],
	nodes: Array[PanelContainer],
	dealer: bool,
	animate_all: bool,
	animate_last: bool,
	sequence_offset: int
) -> void:
	var spread := 76.0
	var card_width := 116.0
	var total_width := card_width + maxf(0.0, float(cards.size() - 1) * spread)
	var start_x := 640.0 - total_width * 0.5
	for i in range(cards.size()):
		var card := _create_physical_card(cards[i], dealer)
		var target_position := Vector2(start_x + i * spread, 0)
		card.position = target_position
		card.z_index = i
		hand_root.add_child(card)
		nodes.append(card)
		if animate_all or (animate_last and i == cards.size() - 1):
			_animate_card_deal(card, target_position, dealer, sequence_offset + i if animate_all else 0)


func _animate_card_deal(card: PanelContainer, target_position: Vector2, dealer: bool, sequence_index: int) -> void:
	card.pivot_offset = card.size * 0.5
	card.position = Vector2(582.0, 222.0 if dealer else -182.0)
	card.rotation = (-0.16 if dealer else 0.16) + float(sequence_index % 2) * 0.07
	card.scale = Vector2.ONE * 0.72
	card.modulate = Color(1.0, 1.0, 1.0, 0.68)
	var delay := float(sequence_index) * 0.075
	var slide_pitch := 0.92 + float(sequence_index % 4) * 0.055 + (0.08 if not dealer else 0.0)
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(Callable(self, "_play_card_slide").bind(slide_pitch))
	tween.tween_property(card, "position", target_position, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation", 0.0, 0.18)
	tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "modulate", Color.WHITE, 0.16)
	tween.tween_callback(Callable(self, "_play_card_land").bind(0.94 + float(sequence_index % 3) * 0.08))


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


func get_music_asset_path() -> String:
	return MUSIC_PATH


func _create_audio() -> void:
	if music_player:
		return
	music_player = AudioStreamPlayer.new()
	music_player.name = "SnakeEyesMusic"
	music_player.volume_db = MUSIC_VOLUME_DB
	if ResourceLoader.exists(MUSIC_PATH):
		var delivered_stream := load(MUSIC_PATH) as AudioStreamOggVorbis
		if delivered_stream:
			delivered_stream.loop = true
			delivered_stream.loop_offset = MUSIC_LOOP_OFFSET
			music_player.stream = delivered_stream
	add_child(music_player)

	card_slide_audio = _make_audio_player(
		"CardSlideAudio",
		_make_card_foley(0.14, true),
		-1.5,
		6
	)
	card_land_audio = _make_audio_player(
		"CardLandAudio",
		_make_card_foley(0.085, false),
		-0.5,
		6
	)
	action_audio = _make_audio_player(
		"DealActionAudio",
		_make_tone(520.0, 0.065, 0.08),
		-4.0,
		3
	)
	ruling_audio = _make_audio_player(
		"ResultReviewAudio",
		_make_tone(138.0, 0.26, 0.24),
		-2.0,
		2
	)


func _make_audio_player(
	player_name: String,
	stream: AudioStream,
	volume: float,
	polyphony: int
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.stream = stream
	player.volume_db = volume
	player.max_polyphony = polyphony
	add_child(player)
	return player


func _start_audio() -> void:
	if music_player and music_player.stream:
		music_player.play(0.0)


func _stop_audio() -> void:
	for player in [music_player, card_slide_audio, card_land_audio, action_audio, ruling_audio]:
		if player:
			player.stop()


func _play_card_slide(pitch: float = 1.0) -> void:
	if not active or not card_slide_audio:
		return
	card_slide_audio.pitch_scale = pitch
	card_slide_audio.play()


func _play_card_land(pitch: float = 1.0) -> void:
	if not active or not card_land_audio:
		return
	card_land_audio.pitch_scale = pitch
	card_land_audio.play()


func _play_action_audio(pitch: float = 1.0) -> void:
	if not active or not action_audio:
		return
	action_audio.pitch_scale = pitch
	action_audio.play()


func _play_ruling_audio(pitch: float = 1.0) -> void:
	if not active or not ruling_audio:
		return
	ruling_audio.pitch_scale = pitch
	ruling_audio.play()


func _make_card_foley(duration: float, sliding: bool) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := maxi(1, int(duration * sample_rate))
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for i in range(sample_count):
		var time := float(i) / float(sample_rate)
		var progress := float(i) / float(sample_count)
		var envelope := sin(PI * progress) if sliding else pow(1.0 - progress, 3.4)
		var paper_noise := sin(float((i * 7919 + 31) % 997) * 0.071)
		var paper_grain := sin(TAU * (1220.0 + 180.0 * progress) * time)
		var table_thump := sin(TAU * 92.0 * time) * exp(-time * 31.0)
		var wave := (paper_noise * 0.68 + paper_grain * 0.22) * envelope
		if not sliding:
			wave = table_thump * 0.82 + paper_noise * envelope * 0.34
		bytes[i] = clampi(int(128.0 + wave * 82.0), 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream


func _make_tone(frequency: float, duration: float, noise_amount: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := maxi(1, int(duration * sample_rate))
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for i in range(sample_count):
		var time := float(i) / float(sample_rate)
		var envelope := pow(1.0 - float(i) / float(sample_count), 1.8)
		var primary := sin(TAU * frequency * time)
		var harmonic := sin(TAU * frequency * 2.0 * time) * 0.24
		var noise := sin(float((i * 3571 + 17) % 991) * 0.019) * noise_amount
		var wave := (primary + harmonic) * (1.0 - noise_amount) + noise
		bytes[i] = clampi(int(128.0 + wave * envelope * 86.0), 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream


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
