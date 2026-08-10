# Runtime architecture

This document describes the ownership boundaries around `scenes/main.tscn`. The refactor keeps that scene and its public gameplay flow intact while moving cohesive state machines out of `scripts/main.gd`.

## Runtime flow

```text
scenes/main.tscn
└── scripts/main.gd                 composition root and story coordinator
    ├── managers/quest_manager.gd   quest state and dialogue selection
    ├── managers/dialogue_manager.gd
    │                               dialogue UI, choices, portraits, typewriter
    ├── managers/room_manager.gd    interiors, doors, transitions, reparenting
    ├── managers/environment_effects.gd
    │                               lighting, CRT, ambient audio, particles
    ├── sequences/intro_sequence.gd CRT/news intro timeline
    ├── sequences/mk_sequence.gd    final-mission presentation timeline
    ├── sequences/ending_sequence.gd
    │                               ending cards and postgame transition
    └── encounters/
        ├── xi_pre_scene.gd         intercepted-communications pre-scene
        ├── kim_phone_encounter.gd  red-phone dialogue overlay
        ├── bezos_drone_encounter.gd
        │                           in-world drone prelude
        └── bezos_encounter.gd      arcade encounter presentation
```

`main.gd` instantiates these nodes in `_ready()`, supplies their scene dependencies, and handles signals whose consequences span more than one system. The extracted modules do not load or replace `main.tscn`.

## Ownership

| Area | Owner | Notes |
| --- | --- | --- |
| Quest order, signatures, optional encounters, residues and marks | `QuestManager` | Also builds AI and politician dialogue from loaded content. |
| Dialogue lifecycle and presentation | `DialogueManager` | Owns typewriter timing, portraits, choices, and open/close animation. |
| Interior registry and world return points | `RoomManager` | Creates interiors and doors, reparents the player, and owns transition UI. |
| Intro, MK, and ending presentation | `IntroSequence`, `MKSequence`, `EndingSequence` | Own their overlays, text, and timers. |
| Encounter-only presentation | `scripts/encounters/` | Each node owns one encounter overlay and its local timing. |
| Global visual and ambient setup | `EnvironmentEffects` | Creates lighting, the CRT shader, door audio, and atmospheric particles. |
| Overworld and global story orchestration | `main.gd` | Coordinates systems that need world nodes or multiple narrative states. |
| Room-local actors and geometry | `scripts/oval_office_room.gd`, `scenes/interiors/` | Separate from global travel. |

## Dependencies and contracts

- `main.gd` is the only module that knows all managers and sequences.
- Managers receive existing nodes in `setup(...)`; they do not search for global singletons.
- Presentation sequences emit signals for cross-system effects. For example, `EndingSequence` requests the final mission or postgame mode instead of mutating those systems.
- `DialogueManager` emits line, choice, and finish events. `main.gd` applies character-specific consequences and forwards room-local choices.
- `RoomManager` owns movement between world and interior containers. `main.gd` retains narrative hooks around travel.
- Compatibility properties in `main.gd` expose manager-owned state to remaining encounter code. They are migration seams, not duplicate sources of truth.

## Content and scenes

- `data/characters.json` is the primary character dialogue and choice source.
- `data/day_flow.json` and `data/crowd_fragments.json` contain supporting narrative data.
- `scenes/interiors/oval_office.tscn` is the shared interior scene instantiated for configured rooms.
- `assets/` and `shaders/` remain presentation resources; their paths were not changed.

## Adding or changing behavior

1. Put reusable quest rules in `QuestManager`, dialogue mechanics in `DialogueManager`, and travel mechanics in `RoomManager`.
2. Put a self-contained cinematic or encounter overlay in `scripts/sequences/` or `scripts/encounters/` and expose only the signals needed by `main.gd`.
3. Keep story decisions that touch multiple systems in `main.gd` so individual modules do not depend on each other.
4. Add data-driven dialogue to `data/characters.json` before hard-coding it in a manager.
5. Run the editor parse check and `tests/smoke_test.gd` before committing.

## Deliberately retained debt

The overworld generator, contamination/hidden-bunker storyline, final-mission flow, and several tightly coupled landmark builders remain in `main.gd`. Their state is interleaved with world nodes and narrative side effects; extracting them safely calls for dedicated scene tests and smaller follow-up changes. `scripts/oval_office_room.gd` is also large, but owns a different, room-local concern and was left untouched to keep this refactor behavior-preserving.
