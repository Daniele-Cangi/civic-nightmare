# Contributing to Civic Nightmare

Civic Nightmare welcomes external contributions. The game already exists, is playable, and deliberately has no strict public roadmap: focused improvements are welcome, as are bounded ideas that take part of its strange world in an interesting direction. Large rewrites or changes to the main story should be discussed before implementation.

Opening an issue first is **not** required for small bug fixes, documentation improvements, or other clearly scoped changes. Not every proposal or pull request can be merged, but good ideas and careful execution are always welcome.

## Useful contributions

- Godot and GDScript improvements
- bug fixes and gameplay polish
- focused encounters, rooms, or scenes
- dialogue and content
- pixel art and visual polish
- UI, UX, accessibility, and translations
- sound and audio
- tests and documentation
- performance work and tooling
- carefully scoped architectural improvements

## Getting started

1. Fork the repository and clone your fork.
2. Install **Godot 4.6 Standard**.
3. Open `project.godot` in Godot.
4. Run the main scene, `scenes/main.tscn`.
5. Read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) before changing behavior that crosses systems.

The short repository map is:

- dialogue mechanics → `scripts/managers/dialogue_manager.gd`
- quest and progression rules → `scripts/managers/quest_manager.gd`
- local dossier persistence → `scripts/managers/save_manager.gd`
- interior travel and transitions → `scripts/managers/room_manager.gd`
- global visual and ambient setup → `scripts/managers/environment_effects.gd`
- static world landmarks → `scripts/managers/world_landmark_builder.gd`
- character colors, portraits, and sprite metadata → `scripts/data/character_visual_catalog.gd`
- standalone encounters → `scripts/encounters/`
- presentation timelines and title flow → `scripts/sequences/`
- dialogue and content data → `data/`
- room-local behavior → `scenes/interiors/` and room scripts
- cross-system story coordination and overworld generation → `scripts/main.gd`

The architecture guide contains the actual ownership boundaries and deliberately retained technical debt; this list is only an entry point.

## Contribution workflow

1. Fork the repository.
2. Create a focused branch.
3. Make one coherent change.
4. Run the relevant validation.
5. Open a pull request explaining the intent and results.

Please open an issue before starting a major gameplay change, large architectural change, rewrite, main-story change, cross-system change, or major asset/style change. This prevents two people from solving different versions of the same nightmare.

## Validation

Run these checks from the repository root:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --log-file .godot/flow-smoke.log --script res://tests/smoke_test.gd
```

For startup, scene-loading, or runtime-flow changes, also use the short launch check:

```bash
godot --headless --path . --quit-after 3
```

`tests/smoke_test.gd` is a focused boundary test, not full game coverage. It currently checks the main scene, title/save flow, manager initialization, dialogue lifecycle, room entry and exit, visual-catalog NPC assignment, world landmarks, UFO lab actors, the Bezos handoff, and final-credit variants.

The same parse, smoke, and Web export commands run on pull requests. The Pages
deployment step runs only after a successful push to `main`; never weaken a
smoke assertion to make a feature mergeable.

Add a manual check when your change is visual, interactive, audio-related, or outside the smoke test's reach. Include the commands and manual checks in the pull request.

## Media and asset provenance

The repository separates the MIT-licensed source code from media and narrative rights. Read [`ASSET_NOTICE.md`](ASSET_NOTICE.md) before adding content.

For every pull request that introduces media, disclose:

- whether it is original, generated, or third-party;
- the source or generation tool where relevant;
- applicable usage rights for third-party material;
- meaningful modifications, when useful to reviewers.

Runtime-ready media belongs in `assets/`, retained masters in `asset_sources/`,
and reproducible previews in ignored `tmp/generated/`. Update
`docs/ASSET_INVENTORY.md` when a material asset enters or leaves the runtime set.

Do not submit third-party material whose rights are unclear. No contributor license agreement is required.
