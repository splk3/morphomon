# River — History

## Project Context

- **Project:** Morphomon — Godot 4.5 GDScript side-scrolling platformer
- **Stack:** Godot 4.5, GDScript, SVG assets
- **Owner:** Patrick Boyle
- **Joined:** 2026-04-19

## What This Game Is

A boy uses a morphomon scanner to shapeshift into magical creatures to solve environmental challenges. The audio should reflect that sense of wonder, transformation, and a hand-crafted pixel-art world — chiptune-style fits the aesthetic.

## Key Architecture (as I understand it)

- Scenes in `scenes/`, scripts in `scripts/`, sprites in `sprites/`, backgrounds in `backgrounds/`
- No `audio/` directory exists yet — I'll need to create it when first assets are added
- Godot 4.5 audio: `.ogg` for music, `.wav` for SFX; `AudioStreamPlayer` (global) vs `AudioStreamPlayer2D` (positional)
- `main_menu.tscn` is the entry point; `level1.tscn` is the first level

## Format Status

- **Undecided** — Patrick hasn't locked in a toolchain (MIDI, tracker, direct synthesis) yet
- My job is to prototype and propose, not decide unilaterally
- First audio work: propose 2-3 short clips or format demos for Patrick to evaluate

## Learnings

(append here as work progresses)
