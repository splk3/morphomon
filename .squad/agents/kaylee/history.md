# Project Context

- **Owner:** Patrick Boyle
- **Project:** Morphomon — Godot 4.5 GDScript side-scrolling platformer. A boy who uses a morphomon scanner to shapeshift into magical creatures he sees on adventures to solve challenges.
- **Stack:** Godot 4.5, GDScript, SVG assets (nearest-neighbor pixel art filter)
- **Created:** 2026-04-19

## Core Context

- Player: `CharacterBody2D`, `scripts/player.gd` — SPEED=200, JUMP_VELOCITY=-400
- Input: named actions `move_left`, `move_right`, `jump` (never raw keycodes)
- Animations: `AnimationPlayer` swapping `Sprite2D` textures — idle/run/jump
- Player collision: `RectangleShape2D` 20×30
- Physics convention: gravity from `ProjectSettings`, `move_and_slide()` for movement
- `@onready` for node refs, always null-check before use

## Learnings

<!-- Append new learnings below. -->
