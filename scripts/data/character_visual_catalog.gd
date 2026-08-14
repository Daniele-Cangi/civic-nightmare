extends RefCounted

const CHARACTER_COLORS := {
	"ai_terminal": Color(0.2, 0.7, 0.9),
	"donald_trump": Color(0.82, 0.22, 0.18),
	"elon_musk": Color(0.28, 0.48, 0.72),
	"ursula_von_der_leyen": Color(0.18, 0.28, 0.58),
	"christine_lagarde": Color(0.22, 0.22, 0.38),
	"vladimir_putin": Color(0.52, 0.18, 0.18),
	"emmanuel_macron": Color(0.18, 0.22, 0.58),
	"xi_jinping": Color(0.7, 0.12, 0.12),
	"sam_altman": Color(0.6, 0.62, 0.65),
	"ufo_easter_egg": Color(0.58, 0.96, 0.78),
	"mark_zuckerberg_ufo": Color(0.12, 0.12, 0.12),
	"historical_contamination": Color(0.32, 0.32, 0.34),
	"self": Color(0.75, 0.75, 0.82),
	"mojtaba_khamenei": Color(0.12, 0.45, 0.12),
	"swedish_pm": Color(0.12, 0.45, 0.82),
	"jeff_bezos": Color(1.0, 0.5, 0.0)
}

const PORTRAIT_PATHS := {
	"donald_trump": "res://assets/mockups/trump_combat_portrait_v2.png",
	"elon_musk": "res://assets/mockups/musk_combat_portrait_v2.png",
	"ursula_von_der_leyen": "res://assets/mockups/vdl_combat_portrait_v2.png",
	"christine_lagarde": "res://assets/mockups/lagarde_combat_portrait_v2.png",
	"vladimir_putin": "res://assets/mockups/putin_combat_portrait_v2.png",
	"emmanuel_macron": "res://assets/mockups/macron_combat_portrait_v2.png",
	"xi_jinping": "res://assets/mockups/xi_jinping_caricature.png",
	"sam_altman": "res://assets/mockups/sam_altman_caricature.png",
	"ai_terminal": "res://assets/mockups/ai_terminal_portrait_v2.png",
	"ufo_easter_egg": "res://assets/mockups/einstein_caricature.png",
	"mark_zuckerberg_ufo": "res://assets/mockups/zuckerberg_caricature.png",
	"historical_contamination": "res://assets/mockups/contamination_portrait.png",
	"ZELENSKY": "res://assets/mockups/zelensky_portrait.png",
	"DEATH": "res://assets/mockups/death_ironic.png",
	"kim_jong_un": "res://assets/mockups/kim_jong_un_portrait.png",
	"mojtaba_khamenei": "res://assets/mockups/mojtaba_portrait.png",
	"swedish_pm": "res://assets/mockups/swedish_pm_portrait.png",
	"jeff_bezos": "res://assets/mockups/bezos_portrait.png"
}

const AI_TERMINAL_EXPRESSION_PATHS := {
	"neutral": "res://assets/mockups/ai_terminal_portrait_v2.png",
	"smile": "res://assets/mockups/ai_terminal_portrait_smile_v2.png",
	"sad": "res://assets/mockups/ai_terminal_portrait_sad_v2.png",
	"exalted": "res://assets/mockups/ai_terminal_portrait_exalted_v2.png"
}

const AI_TERMINAL_WORLD_EXPRESSION_PATHS := {
	"neutral": "res://assets/mockups/ai_terminal_sprite_v2.png",
	"smile": "res://assets/mockups/ai_terminal_sprite_smile_v2.png",
	"sad": "res://assets/mockups/ai_terminal_sprite_sad_v2.png",
	"exalted": "res://assets/mockups/ai_terminal_sprite_exalted_v2.png"
}

const COMBAT_PORTRAIT_PATHS := {
	"donald_trump": "res://assets/mockups/trump_combat_portrait_v2.png",
	"elon_musk": "res://assets/mockups/musk_combat_portrait_v2.png",
	"ursula_von_der_leyen": "res://assets/mockups/vdl_combat_portrait_v2.png",
	"christine_lagarde": "res://assets/mockups/lagarde_combat_portrait_v2.png",
	"vladimir_putin": "res://assets/mockups/putin_combat_portrait_v2.png",
	"emmanuel_macron": "res://assets/mockups/macron_combat_portrait_v2.png"
}

const NPC_SPRITE_PATHS := {
	"donald_trump": "res://assets/mockups/trump_pure_sprite.png",
	"elon_musk": "res://assets/mockups/musk_pure_sprite.png",
	"ursula_von_der_leyen": "res://assets/mockups/vdl_pure_sprite.png",
	"christine_lagarde": "res://assets/mockups/lagarde_pure_sprite.png",
	"vladimir_putin": "res://assets/mockups/putin_pure_sprite.png",
	"emmanuel_macron": "res://assets/mockups/macron_pure_sprite.png",
	"xi_jinping": "res://assets/characters/xi_jinping.png",
	"sam_altman": "res://assets/characters/sam_altman.png",
	"ufo_easter_egg": "res://assets/characters/einstein_sprite.png",
	"mark_zuckerberg_ufo": "res://assets/characters/zuckerberg_sprite.png",
	"zelensky_bunker": "res://assets/mockups/zelensky_move.png",
	"death_bunker": "res://assets/mockups/death_ironic.png",
	"kim_jong_un": "res://assets/mockups/kim_jong_un_sprite.png"
}

const NPC_FACING_DEFAULTS := {
	"donald_trump": false,
	"elon_musk": false,
	"ursula_von_der_leyen": false,
	"christine_lagarde": false,
	"vladimir_putin": true,
	"emmanuel_macron": false,
	"xi_jinping": false,
	"sam_altman": false,
	"kim_jong_un": false
}

const LANDMARK_SPRITE_PATHS := {
	"donald_trump": "res://assets/mockups/landmark_trump.png",
	"elon_musk": "res://assets/mockups/landmark_musk.png",
	"ursula_von_der_leyen": "res://assets/mockups/landmark_vdl.png",
	"christine_lagarde": "res://assets/mockups/landmark_lagarde.png",
	"vladimir_putin": "res://assets/mockups/landmark_putin.png",
	"emmanuel_macron": "res://assets/mockups/landmark_macron_ruined.png",
	"xi_jinping": "res://assets/mockups/landmark_great_wall.png",
	"sam_altman": "res://assets/mockups/landmark_nuclear_plant.png",
	"pyongyang": "res://assets/mockups/landmark_pyongyang.png"
}

const NPC_TARGET_SPRITE_HEIGHT := 128.0


static func assign_npc_textures(npcs: Array[Node]) -> void:
	for npc in npcs:
		var character_id := str(npc.get("character_id"))
		npc.set("faces_right_by_default", bool(NPC_FACING_DEFAULTS.get(character_id, false)))
		if not NPC_SPRITE_PATHS.has(character_id):
			continue
		var sprite := npc.get_node_or_null("Sprite2D") as Sprite2D
		var sprite_path: String = NPC_SPRITE_PATHS[character_id]
		if sprite and ResourceLoader.exists(sprite_path):
			var texture := load(sprite_path) as Texture2D
			sprite.texture = texture
			if texture != null:
				var scale_factor := NPC_TARGET_SPRITE_HEIGHT / float(max(texture.get_height(), 1))
				sprite.scale = Vector2(scale_factor, scale_factor)
				npc.set("base_scale", sprite.scale)
			var placeholder := npc.get_node_or_null("PlaceholderVisual")
			if placeholder:
				placeholder.queue_free()
