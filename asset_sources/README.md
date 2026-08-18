# Asset sources

This directory is for editable masters, licensed source packs, and archived art
that must remain available to contributors but must not enter the Godot import
or web-export graph. Godot ignores the complete directory through `.gdignore`.

Runtime-ready, deliberately referenced files belong under `assets/`. Disposable
generator output belongs under `tmp/generated/`. Large editable formats in this
directory use Git LFS; ordinary runtime PNG files intentionally do not.
Approved store, press, and community artwork belongs under `marketing/` so it
can remain versioned without increasing the Godot import or Web-export graph.
