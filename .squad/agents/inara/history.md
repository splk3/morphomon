# Inara — History

## Project Context

- **Project:** Morphomon — Godot 4.5 GDScript side-scrolling platformer
- **Stack:** Godot 4.5, GDScript, SVG assets
- **Owner:** Patrick Boyle
- **Joined:** 2026-04-20

## What This Game Is

A boy uses a morphomon scanner to shapeshift into magical creatures to solve environmental challenges. Side-scrolling platformer with parallax backgrounds, pixel art style (nearest-neighbor texture filter), 1280×720 viewport.

## Key Architecture (as I understand it)

- `scenes/` — `.tscn` files; `scripts/` — `.gd` files; `sprites/` — player sprites; `backgrounds/` — parallax layers; `tilesets/` — ground tiles
- Entry point: `main_menu.tscn` → `level1.tscn` on Start
- CI: `godot --headless --import --quit` via `.github/workflows/test-build.yml`
- No local build step — open `project.godot` in Godot 4.5+ and press F5

## Documentation Conventions

- Diagrams in Mermaid format, embedded in markdown (decided 2026-04-20)
- For complex diagrams, collaborate with Book

## Learnings

(append here as work progresses)
