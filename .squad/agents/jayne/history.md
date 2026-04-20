# Jayne — History

## Project Context

- **Project:** Morphomon — Godot 4.5 GDScript side-scrolling platformer
- **Stack:** Godot 4.5, GDScript, SVG assets
- **Owner:** Patrick Boyle
- **Joined:** 2026-04-19

## What This Game Is

A boy uses a morphomon scanner to shapeshift into magical creatures to solve environmental challenges. Side-scrolling platformer. Testing scope covers builds, player mechanics, menus, and eventually creature transformations.

## Key Test Surface

- **Entry point:** `main_menu.tscn` → `level1.tscn` (via Start button)
- **Player scene:** `player.tscn` — CharacterBody2D, `SPEED=200.0`, `JUMP_VELOCITY=-400.0`
- **Animations:** `AnimationPlayer` with `idle`, `run`, `jump` states; texture swaps via Sprite2D
- **Input actions:** `move_left`, `move_right`, `jump` (defined in `project.godot`)
- **Viewport:** 1280×720, stretch mode `viewport`
- **CI command:** `godot --headless --import --quit` via `.github/workflows/test-build.yml`
- **Godot version:** 4.5.1 (no .NET), via `chickensoft-games/setup-godot@v1`

## CI Pipeline Notes

- Workflow: `.github/workflows/test-build.yml`
- Triggers: PRs to `main`, `workflow_dispatch`
- Headless import validates scene/resource integrity — if `.svg.import` sidecars are missing or stale, this step may fail

## Known Mechanics to Test

1. Player spawns correctly in `level1.tscn`
2. `move_left` / `move_right` move player at `SPEED=200.0`
3. `jump` applies `JUMP_VELOCITY=-400.0` when on floor
4. Gravity from `ProjectSettings.get_setting("physics/2d/default_gravity")` affects player correctly
5. `AnimationPlayer` transitions: idle → run on movement, run → jump on jump input
6. Main menu loads and "Start" transitions to `level1.tscn`
7. Camera2D follows player (zoom 1.5×, in `level1.gd _process()`)

## Learnings

(append here as work progresses)
