# Book — History

## Project Context

- **Project:** Morphomon — Godot 4.5 GDScript side-scrolling platformer
- **Stack:** Godot 4.5, GDScript, SVG assets
- **Owner:** Patrick Boyle
- **Joined:** 2026-04-20

## What This Game Is

A boy uses a morphomon scanner to shapeshift into magical creatures to solve environmental challenges. Side-scrolling platformer with parallax backgrounds, pixel art style, 1280×720 viewport.

## Key Architecture (as I understand it)

Scene graph:
- `main_menu.tscn` → entry point
- `level1.tscn` → ParallaxBackground (Sky, CloudsFar, Mountains, Trees), TileMap, Player (player.tscn), Camera2D
- `player.tscn` → CharacterBody2D with Sprite2D, CollisionShape2D, AnimationPlayer

Scripts in `scripts/`, scenes in `scenes/`, sprites in `sprites/`, backgrounds in `backgrounds/`, tilesets in `tilesets/`.

## Diagram Conventions

- All diagrams in Mermaid format (decided 2026-04-20)
- Diagrams embedded in markdown docs or stored in `docs/diagrams/` as `.md` files
- Collaborate with Inara: she writes prose, I draw the diagrams

## Learnings

(append here as work progresses)
