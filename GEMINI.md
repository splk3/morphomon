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
  - `main_menu.tscn`: Animated entry point (parallax beach/sunset + racing Morphomon).
  - `player.tscn`: The player character scene (form-driven controller).
  - `ui/`: HUD, pause menu, settings menu, level select, credits.
  - `levels/`: Data-driven `base_level.tscn` (all themed levels) and `level_boss.tscn`.
  - `entities/`: `projectile.tscn`, `enemy.tscn`, `rescue_animal.tscn`.
- `scripts/`: GDScript (`.gd`) logic files.
  - `autoload/`: `game_state.gd` (progression/save), `settings.gd`, `audio_manager.gd` — registered as autoloads.
  - `levels/`: `base_level.gd`, `level_boss.gd`, `level_themes.gd`.
  - `forms/`: `morph_forms.gd` — per-form movement/attack/ability data.
  - `entities/`, `ui/`: entity and UI logic.
- `sprites/`: Player, forms, animals, enemies, items, boss sprites.
- `backgrounds/`: Multi-layer parallax assets, organized per theme.
- `assets/music/`, `assets/sfx/`: Procedurally generated WAV audio.
- `tools/`: `generate_music.py`, `generate_sfx.py` — reproducible audio pipeline (Python + numpy).
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
Defined in `project.godot` (all support keyboard + gamepad, remappable in Settings → Controls):
- `move_left`, `move_right`, `move_up`, `move_down`
- `jump`: Space, W, Up Arrow / gamepad A
- `attack`: J / gamepad X
- `ability`: K / gamepad B (form special ability)
- `cycle_form`: Q / gamepad Y, RB
- `pause`: Esc / gamepad Start

## 🔊 Audio
- Music and SFX are generated procedurally via `tools/generate_music.py` and `tools/generate_sfx.py` (Python + numpy) into `assets/music/` and `assets/sfx/`.
- `AudioManager` autoload plays looping music on a `Music` bus and pooled SFX on an `SFX` bus (`default_bus_layout.tres`); volumes are driven by `Settings`.
