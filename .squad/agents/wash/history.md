# Project Context

- **Owner:** Patrick Boyle
- **Project:** Morphomon — Godot 4.5 GDScript side-scrolling platformer. A boy who uses a morphomon scanner to shapeshift into magical creatures he sees on adventures to solve challenges.
- **Stack:** Godot 4.5, GDScript, SVG assets (nearest-neighbor pixel art filter)
- **Created:** 2026-04-19

## Core Context

- Viewport: 1280×720, stretch mode `viewport`, Camera2D zoom 1.5×
- Graphics: SVG files with `.svg.import` sidecars — never edit `.import` files
- Texture filter: nearest-neighbor (`default_texture_filter=0`) — pixel art style, do not change
- Parallax layers: sky (0,0), clouds_far (0.1), mountains (0.3), trees (0.6) — motion_mirroring=1280
- TileMap: 32×32 tiles, physics layer 0 collision
- Scene structure: `main_menu.tscn` → `level1.tscn` → instances `player.tscn`
- `scenes/` for `.tscn`, `sprites/` for player, `backgrounds/` for parallax, `tilesets/` for ground

## Learnings

<!-- Append new learnings below. -->
