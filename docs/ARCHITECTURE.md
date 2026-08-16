# Runtime architecture

This document describes the ownership boundaries around `scenes/main.tscn`. The refactor keeps that scene and its public gameplay flow intact while moving cohesive state machines out of `scripts/main.gd`.

## Runtime flow

```text
scenes/main.tscn
└── scripts/main.gd                 composition root and story coordinator
    ├── managers/quest_manager.gd   quest state and dialogue selection
    ├── managers/save_manager.gd    versioned local dossier persistence
    ├── managers/dossier_manager.gd behavioural evidence and interpretation
    ├── managers/dialogue_manager.gd
    │                               dialogue UI, choices, portraits, typewriter
    ├── managers/room_manager.gd    interiors, doors, transitions, reparenting
    ├── managers/environment_effects.gd
    │                               lighting, CRT, ambient audio, particles
    ├── managers/world_landmark_builder.gd
    │                               static landmark nodes and entry triggers
    ├── managers/authority_world_patch_builder.gd
    │                               facade, terrain seam, approach, footprint
    ├── data/character_visual_catalog.gd
    │                               read-only colors, portraits, sprites, facades
    ├── sequences/start_menu.gd     Continue/New Game title flow
    ├── sequences/administrative_hold.gd
    │                               diegetic pause and dossier presentation
    ├── sequences/intro_sequence.gd CRT/news intro timeline
    ├── sequences/mk_sequence.gd    final-mission presentation timeline
    ├── sequences/ending_sequence.gd
    │                               ending cards and postgame transition
    └── encounters/
        ├── xi_pre_scene.gd         intercepted-communications pre-scene
        ├── kim_phone_encounter.gd  red-phone dialogue overlay
        ├── ufo_encounter.gd        UFO world presentation, trigger, and lab actors
        ├── bezos_drone_encounter.gd
        │                           in-world drone prelude
		├── bezos_encounter.gd      arcade encounter sequence and verdict
		└── bezos_battle_stage.gd   local input, attacks, poses, and battle result
```

`main.gd` instantiates these nodes in `_ready()`, supplies their scene dependencies, and handles signals whose consequences span more than one system. The extracted modules do not load or replace `main.tscn`.

## Ownership

| Area | Owner | Notes |
| --- | --- | --- |
| Quest order, signatures, optional encounters, residues and marks | `QuestManager` | Also builds AI and politician dialogue from loaded content. |
| Behavioural evidence, patterns, contradictions, and classification | `DossierManager` | Stores ordered source events; derived interpretations are rebuilt from that evidence. |
| Versioned local persistence and dossier validation | `SaveManager` | Stores JSON under `user://`; the composition root owns snapshot assembly and safe resume policy. |
| Dialogue lifecycle and presentation | `DialogueManager` | Owns typewriter timing, portraits, choices, and open/close animation. |
| Interior registry and world return points | `RoomManager` | Creates interiors and doors, reparents the player, and owns transition UI. |
| Title, intro, MK, and ending presentation | `StartMenu`, `IntroSequence`, `MKSequence`, `EndingSequence` | Own their overlays, text, and timers. |
| Diegetic pause presentation | `AdministrativeHold` | Suspends the tree, reveals only currently unlocked dossier sections, and records profile access through `DossierManager`. |
| Encounter-only presentation | `scripts/encounters/` | Each node owns one encounter overlay and its local timing. |
| Character colors, portraits, sprite paths, and authority facades | `CharacterVisualCatalog` | Read-only presentation metadata shared by world, dialogue, and encounters. |
| Static landmark construction and entry triggers | `WorldLandmarkBuilder` | Builds the Great Wall, nuclear plant, hidden bunker, and Pyongyang entrances. |
| Main-authority exterior composition | `AuthorityWorldPatchBuilder` | Creates each facade, soft terrain contact, optional physical motif, and visible-mass collision footprint as one unit. |
| Global visual and ambient setup | `EnvironmentEffects` | Creates lighting, the CRT shader, door audio, and atmospheric particles. |
| Overworld and global story orchestration | `main.gd` | Coordinates systems that need world nodes or multiple narrative states. |
| Room-local actors and geometry | `scripts/oval_office_room.gd`, `scenes/interiors/` | Separate from global travel. |

## Dependencies and contracts

- `main.gd` is the only module that knows all managers and sequences.
- Save snapshots contain quest, raw dossier evidence, story, and room-local consequences, while their resume position is restricted to the latest stable overworld checkpoint.
- Managers receive existing nodes in `setup(...)`; they do not search for global singletons.
- Presentation sequences emit signals for cross-system effects. For example, `EndingSequence` requests the final mission or postgame mode instead of mutating those systems.
- `DialogueManager` emits line, choice, and finish events. `main.gd` applies character-specific consequences and forwards room-local choices.
- `main.gd` forwards existing choice metadata and selected encounter boundaries to `DossierManager`; it does not derive traits or write Administrative Hold copy.
- `DossierManager` treats `file_tag` and `file_note` as source evidence. It never owns dialogue mechanics, quest order, or persistence I/O.
- `RoomManager` owns movement between world and interior containers. `main.gd` retains narrative hooks around travel.
- Compatibility properties in `main.gd` expose manager-owned state to remaining encounter code. They are migration seams, not duplicate sources of truth.

## Content and scenes

- `data/characters.json` is the primary character dialogue and choice source.
- `data/day_flow.json` and `data/crowd_fragments.json` contain supporting narrative data.
- `scenes/interiors/oval_office.tscn` is the shared interior scene instantiated for configured rooms.
- `assets/interiors/` contains all eleven authored room backgrounds: six main authorities, three optional investigations, one classified deviation, and one anomaly. `oval_office_room.gd` suppresses its generic visual tile/prop pass when one is present, but retains the shared NPC/sequence actors, exit, lighting, boundary, dialogue, and room-state behavior. Named code-owned barriers follow baked furniture. See [authority interior art direction](AUTHORITY_INTERIOR_ART_DIRECTION.md).
- `assets/` and `shaders/` remain presentation resources; their paths were not changed.
- `assets/landmarks/authority_*_v2.png` contains the six runtime-sized satirical authority facades. Their architecture is narrative: spectacle masks neglect for Trump, permanent-beta industry for Musk, inaccessible transparency for Ursula, wartime paranoia for Putin, stratified stability for Lagarde, and theatrical grandeur for Macron. `AuthorityWorldPatchBuilder` aligns each transparent lower edge to the doorway and owns its visible-mass collision rows, soft ground contact, and optional physical motif. See [World Patch Visual System](WORLD_PATCH_VISUAL_SYSTEM.md).
- `assets/backgrounds/world_district_plate_v3.png` is a single opaque, collision-neutral HD ground plate matching the 2176×2048 overworld bounds. `main.gd` mounts it below the TileMap at `z=-10` with linear filtering; path reservations, structures, triggers, and collision remain generated runtime layers. The plate supplies broad contemporary civic materials and authored landscaping without the repeated 32 px visual grammar of the fallback atlas. Legacy nature and border tiles are suppressed while the plate is active, but the invisible world-edge collision remains. If the plate cannot load, the generator still falls back to the original ground, path, decoration, and border rendering.
- The six main compounds follow the authored plate's two-column/three-row visual grid. Their complete patches now land at world coordinates `x = ±528` and `y = -683 / 0 / 683`, moving image, doorway, collision, NPC, and lighting inward together. The 16 px difference from the ideal quarter-width axis is the smallest symmetric tile-centred placement possible. Facades use shared row heights (330 px top, 320 px middle, 298 px bottom), so paired landmarks align predictably with their doorway rows.
- All six authorities use facade-specific collision masks rather than legacy procedural silhouettes. Each mask follows the visible lower building mass and stops before the exterior threshold; the doorway trigger remains owned by `RoomManager`.

## Adding or changing behavior

1. Put reusable quest rules in `QuestManager`, behavioural interpretation in `DossierManager`, dialogue mechanics in `DialogueManager`, and travel mechanics in `RoomManager`.
2. Put a self-contained cinematic or encounter overlay in `scripts/sequences/` or `scripts/encounters/` and expose only the signals needed by `main.gd`.
3. Keep story decisions that touch multiple systems in `main.gd` so individual modules do not depend on each other.
4. Add data-driven dialogue to `data/characters.json` before hard-coding it in a manager.
5. Run the editor parse check and `tests/smoke_test.gd` before committing.

## Behavioural dossier vertical slice

The current slice records the first three signature choices from their existing `file_tag`, `file_note`, and `ai_comment` fields. It proves ordered evidence, deterministic patterns and contradictions, evolving Administrative Hold sections, profile discovery, post-discovery behaviour comparison, sparse C.L.A.U.D.I.A. callbacks, and save/restore.

Three optional-content grammars are connected at existing orchestration boundaries:

- the Red Phone is an optional investigation;
- the hidden bunker is a protocol deviation because its direct warning is part of the evidence;
- the UFO is an anomaly whose location and time records cannot be reconciled.

The Bezos/drone sequence now supplies a fourth optional grammar: a playable commercial contest. `BezosEncounter` coordinates the pre-fight presentation and administrative verdict, while `BezosBattleStage` owns its two-action combat model and emits a semantic result. `DossierManager` retains the method and recognition outcome rather than combat statistics. Xi, Sam Altman, and historical contamination retain their current behaviour until a follow-up pass decides what lasting evidence each genuinely creates. Do not classify every optional scene merely because it exists.

## Deliberately retained debt

The overworld generator, contamination/hidden-bunker storyline, and final-mission flow remain in `main.gd`. Their state is interleaved with world nodes and narrative side effects; extracting them safely calls for dedicated scene tests and smaller follow-up changes. `scripts/oval_office_room.gd` is also large, but owns a different, room-local concern and was left untouched to keep this refactor behavior-preserving.
