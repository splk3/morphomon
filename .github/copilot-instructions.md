# Copilot instructions for `morphomon`

## Build, test, and lint commands

This repository is a Godot 4.5 GDScript project (no separate compile step).

| Task | Command | Notes |
| --- | --- | --- |
| Run game locally | Open `project.godot` in Godot, then press **F5** | Main scene is `res://scenes/main_menu.tscn` |
| CI-style validation | `godot --headless --import --quit` | Matches `.github/workflows/test-build.yml` |
| Run a single test | No single-test command exists yet | There is no automated unit/integration test suite in the repo |
| Lint | No lint command is configured | No linter config or lint workflow is present |

## High-level architecture

- Entry point is configured in `project.godot` as `res://scenes/main_menu.tscn`.
- `scenes/main_menu.tscn` + `scripts/main_menu.gd` handle menu UI and scene transition to `res://scenes/level1.tscn`.
- `scenes/level1.tscn` + `scripts/level1.gd` define the playable level: parallax background layers, `TileMap` ground/collision, a `Player` instance, and a `Camera2D` that follows the player.
- `scenes/player.tscn` + `scripts/player.gd` encapsulate player behavior (`CharacterBody2D` movement/jump physics, sprite flip direction, and `AnimationPlayer` state switching).
- Asset folders are wired directly from scenes (`backgrounds/`, `sprites/`, `tilesets/`), so scene files are the source of truth for visual composition.

## Key conventions in this codebase

- Keep scene/script pairing explicit: each major scene has a matching script in `scripts/` (`main_menu`, `level1`, `player`).
- Use project input actions (`move_left`, `move_right`, `jump`) from `project.godot`; gameplay code should call `Input.get_axis(...)` and `Input.is_action_just_pressed(...)` rather than hardcoded keys.
- Scene transitions should check return codes from `change_scene_to_file(...)` and report failures (pattern used in `main_menu.gd` with `push_error`).
- `Player` animation state names are canonical (`idle`, `run`, `jump`) and must stay aligned between `player.gd` and the `AnimationLibrary` in `player.tscn`.
- Node access patterns use `$...` / `@onready` references to required child nodes (`Camera2D`, `Player`, `Sprite2D`, `AnimationPlayer`); preserve these node names when editing scenes or scripts.
