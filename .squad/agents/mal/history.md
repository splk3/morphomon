# Project Context

- **Owner:** Patrick Boyle
- **Project:** Morphomon — Godot 4.5 GDScript side-scrolling platformer. A boy who uses a morphomon scanner to shapeshift into magical creatures he sees on adventures to solve challenges.
- **Stack:** Godot 4.5, GDScript, SVG assets (nearest-neighbor pixel art filter)
- **Created:** 2026-04-19

## Core Context

- Entry point: `scenes/main_menu.tscn` → `scenes/level1.tscn`
- Player: `CharacterBody2D` in `scenes/player.tscn`, driven by `scripts/player.gd`
- Input actions: `move_left`, `move_right`, `jump` (defined in `project.godot`)
- Animations via `AnimationPlayer` swapping `Sprite2D` textures (idle/run/jump)
- Parallax background: 4 layers (sky 0.0, clouds_far 0.1, mountains 0.3, trees 0.6)
- TileMap: 32×32 tiles, physics layer 0
- Camera2D: zoom 1.5×, position_smoothing_enabled, follows player in level1.gd `_process()`
- CI: `godot --headless --import --quit` via `.github/workflows/test-build.yml`

## Learnings

<!-- Append new learnings below. -->
