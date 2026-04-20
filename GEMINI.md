# GEMINI.md - Morphomon Project Mandates

This file contains foundational mandates for all AI agents working on the **Morphomon** project. These instructions take absolute precedence over general workflows.

## Project Overview
**Morphomon** is a side-scrolling platformer built in Godot 4.5. The core loop involves a boy using a "morphomon scanner" to shapeshift into magical creatures to solve environmental challenges.

- **Stack:** Godot 4.5, GDScript, SVG assets.
- **Architecture:** Node-based composition, signal-driven communication, and state-machine-driven mechanics.

## Technical Standards & Conventions

### GDScript Implementation
- **Node References:** Use `@onready` for all node references. Always perform a null-check before use if there's any chance the node could be missing.
- **Physics:** 
  - Use `_physics_process(delta)` for movement and physics logic.
  - Fetch gravity via `ProjectSettings.get_setting("physics/2d/default_gravity")`.
  - Use `move_and_slide()` for `CharacterBody2D`.
- **Input:** Always use named actions defined in `project.godot` (e.g., `move_left`, `move_right`, `jump`). Never hardcode keycodes.
- **Animations:** Driven by `AnimationPlayer` nodes. We prefer swapping textures or properties via `AnimationPlayer` over using `AnimatedSprite2D`.

### Scene & Resource Management
- **Surgical Edits:** When modifying `.tscn` files (which are text-based in Godot 4), ensure the `uid` and resource IDs remain consistent.
- **SVG Workflow:** Assets are primarily SVG. Ensure proper scale and import settings are maintained.

## Team & Workflow Mandates
The project utilizes a specialized squad. Always respect the domain boundaries defined in `.squad/team.md` and `.squad/routing.md`.

- **Mal (Lead):** Consult for architecture, system design, and "tech debt" calls.
- **Kaylee (Game Dev):** The primary owner of GDScript logic and player mechanics.
- **Wash (Level & Art):** The owner of scene layouts, UI, and visual polish.
- **Routing:** 
  - Logic/Bugs -> Kaylee
  - Layout/Visuals -> Wash
  - Design/Review -> Mal

## Operational Guidelines
- **Research First:** Before implementing new mechanics (like a specific transformation), reproduce the current state or prototype in a sandbox scene if available.
- **Validation:** Always verify changes by checking GDScript syntax (if tools are available) or describing the intended scene tree changes clearly.
- **No Reverts:** Do not revert changes unless they break the project or were explicitly requested.

## Sandbox Protocol
- When creating a sandbox, use the `scenes/sandbox/` directory.
- A sandbox should be a self-contained scene for testing specific mechanics (e.g., `jump_tuning.tscn`, `transformation_test.tscn`).
