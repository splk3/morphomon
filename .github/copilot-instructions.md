# Copilot instructions for `morphomon`

## Build, test, and lint commands

This is a Godot 4.5 GDScript project (no separate compile/build step).

| Task | Command | Notes |
| --- | --- | --- |
| Run game locally | Open `project.godot` in Godot, press **F5** | Main scene is `res://scenes/main_menu.tscn` |
| CI-style validation | `godot --headless --import --quit` | Matches `.github/workflows/test-build.yml` |
| Run all tests | No repository test runner command is wired into CI | There are GUT-style test scripts under `test/unit/` |
| Run a single test | No single-test command is currently documented in-repo | `test/unit/test_player.gd` exists, but no committed test CLI wrapper |
| Lint | No lint command is configured | No lint workflow/config is present |

## High-level architecture

- **Global state and services are autoload singletons** from `project.godot`:
  - `GameState` (`scripts/autoload/game_state.gd`) owns progression, unlocked forms, level metadata, and save/load (`user://savegame.cfg`).
  - `Settings` (`scripts/autoload/settings.gd`) owns video/audio/control bindings + persistence (`user://settings.cfg`).
  - `AudioManager` (`scripts/autoload/audio_manager.gd`) owns music/SFX playback and loop-point behavior.
- **Gameplay flow is data-driven**:
  - `main_menu` starts cruise intro (or level select if already cleared).
  - `GameState.go_to_level(level_id)` sets `pending_level_id` and loads a scene.
  - `scenes/levels/base_level.tscn` is a shared runtime-generated level; `scripts/levels/base_level.gd` reads `pending_level_id`, pulls theme config from `LevelThemes`, and builds world/background/entities/HUD procedurally.
  - Boss flow goes through `boss_intro.tscn` cutscene into `level_boss.tscn`, then credits.
- **Core gameplay is form-driven**:
  - `scripts/forms/morph_forms.gd` is the canonical form data table (movement, attack type, ability, sprite paths).
  - `scripts/player.gd` reads that data to apply movement/combat behavior and emits signals consumed by HUD/UI.
  - Rescue entities unlock/transform forms through `GameState` and player APIs.
- **Level select UI (`scripts/ui/level_select.gd`) is driven from `GameState.LEVELS` metadata** and boss unlock state (`GameState.is_final_unlocked()`).

## Key conventions in this codebase

- **Treat these as canonical data sources when extending content**:
  - Add/update level metadata in `GameState.LEVELS` (and `MAIN_LEVEL_IDS` for unlock logic).
  - Add/update per-theme visual/FX config in `LevelThemes.THEMES`.
  - Add/update transformation behavior in `MorphForms.FORMS`.
- **Use action names from `project.godot` and `Settings.REBINDABLE_ACTIONS`** (`move_left/right/up/down`, `jump`, `attack`, `ability`, `cycle_form`, `pause`); do not hardcode key codes in gameplay logic.
- **Use `GameState.go_to_level(...)` for level entry** so `pending_level_id` is set correctly for shared base-level scene construction.
- **Audio keys are file-name based** (`menu_theme`, `boss_theme`, etc.): keys map to `assets/music/*.wav` and `assets/sfx/*.wav` without extension; update `AudioManager.MUSIC_LOOP_BEGIN` when adding/changing music tracks.
- **UI/gameplay scripts rely heavily on stable node paths and `@onready` lookups**; when scene trees change, update matching script paths in the same change.
- **Tests are lightweight GUT-style scripts** (`extends GutTest` in `test/unit/`) with custom `test/support/gut_test.gd`; preserve this style if adding tests unless a project-wide runner is introduced.

## Copilot output visibility

- Print a brief status line indicating which agent is handling work.
- If multiple agents are used, list each agent when it starts and completes.
