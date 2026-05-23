# Morphomon Project Context

Morphomon is a 2D side-scrolling platformer developed using **Godot Engine 4.5**. The game revolves around a protagonist who uses a "morphomon scanner" to shapeshift into various magical creatures to overcome platforming challenges.

## 🚀 Quick Start

### Prerequisites
- **Godot Engine:** Version 4.5 or higher (Standard version, non-C#).
- **Assets:** The project uses SVG source files which Godot imports as textures.

### Running the Project
1. Open Godot Engine and import `project.godot`.
2. Press **F5** (or the Play button) to run the main scene (`res://scenes/main_menu.tscn`).

### Validation (CI)
The project is validated in CI using headless Godot:
```bash
godot --headless --import --quit
```

## 📂 Project Structure

- `scenes/`: Contains `.tscn` files.
  - `main_menu.tscn`: The entry point of the game.
  - `player.tscn`: The player character scene.
  - `level1.tscn`: The first playable level.
- `scripts/`: GDScript (`.gd`) logic files.
- `sprites/`: Player animations and character sprites.
- `backgrounds/`: Multi-layer parallax background assets.
- `tilesets/`: Ground and platform tiles.
- `.github/workflows/`: GitHub Actions for automated testing/validation.

## 🛠 Development Conventions

### Coding Style (GDScript)
- Follow the official [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
- **Indentation:** Tabs (Godot default).
- **Naming:**
  - `snake_case`: Files, folders, variables, and functions.
  - `PascalCase`: Classes and Node names in scenes.
  - `SCREAMING_SNAKE_CASE`: Constants.

### Scene Organization
- Scripts should generally be attached to the root node of a scene and named after the scene (e.g., `player.tscn` -> `player.gd`).
- Use `@onready` for node references.
- Use `Input.get_axis` or `Input.is_action_pressed` with actions defined in `project.godot` (`move_left`, `move_right`, `jump`).

### Asset Workflow
- Graphics are provided as `.svg`.
- The `textures/canvas_textures/default_texture_filter=0` setting in `project.godot` ensures pixel-perfect rendering for SVG/Pixel art.

## 🎮 Input Actions
Defined in `project.godot`:
- `move_left`: Left Arrow, A.
- `move_right`: Right Arrow, D.
- `jump`: Space, W, Up Arrow.
