# Release checklist

1. Confirm `CHANGELOG.md` describes the player-visible and technical delta.
2. Run the editor parse, smoke test, and Web export with Godot 4.6.
3. Manually verify New Game, Continue, all six signature rooms, Administrative
   Hold discovery, C.L.A.U.D.I.A. callbacks, bunker routing, and one web save/load.
4. Review `docs/ASSET_INVENTORY.md` and disclose provenance for new media.
5. Merge only after the pull-request workflow passes. Deployment runs only from
   `main`; the Pages step is skipped on pull requests.
6. Verify the deployed URL and browser console after Pages completes.
7. When cutting a tag, move `Unreleased` notes to a dated version and create
   matching GitHub release notes. Do not imply a tagged release exists before
   one is actually created.
