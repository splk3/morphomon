# morphomon
Godot-based side scrolling platformer using pixel art graphics. About a boy who uses his morphomon scanner to shapeshift into robotic versions of the magical animals he rescues on his adventures, gaining special powers to overcome each level's challenges.

## Features
- Animated **main menu** with driving chiptune music and a deep parallax scene: sunset, beachside road, palm trees, waves, and Morphomon racing along the street
- **Settings menu** with Graphics (resolution, fullscreen), Audio (music & SFX volume), and Controls (keyboard + gamepad button remapping) tabs
- **Gamepad support** across all actions, with in-game remapping
- **Intro level** aboard a cruise ship that teaches the basics
- **Mega Man-style level select** with completion tracking and an animated center unlock for the final boss
- Five themed levels — **ice** (windy snow), **lava** (animated lava & erupting volcanoes), **island**, **jungle** (rainfall), and **pirate ship** — each with unique chiptune music and deep parallax backgrounds
- **Transformation system**: rescue an animal in each level to morph into its robotic form with unique movement and attack powers
- **Multi-phase final boss**: a mad scientist who fights with fake Morphomons; defeat each form (swapping your own forms), then scan and bonk him
- **Credits sequence** with Morphomon racing into the screen past the same sunset/beach scene
- Procedurally generated chiptune **music** and **sound effects**

## Forms & Powers
| Form | Movement | Attack |
| --- | --- | --- |
| **Morphomon (default)** | Rolls on treads, dash | Homing missiles |
| **Panther** (jungle) | High double-jump | Claw scratch (melee) |
| **Mammoth** (ice) | Phase through walls, toss objects | Heavy melee |
| **Eagle** (lava) | Flight (hold jump) | Lasers |
| **Monkey** (pirate) | Roll dodge, double-jump | Melee |

## Controls
| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move | Arrow Keys / WASD | Left stick / D-pad |
| Jump | Space / W / Up | A |
| Attack | J | X |
| Special ability | K | B |
| Cycle form | Q | Y / RB |
| Pause | Esc | Start |

All bindings are remappable in **Settings -> Controls**.

## Running the Game
1. Install [Godot Engine 4.5+](https://godotengine.org/download) (Standard, non-C#)
2. Open the project in Godot by opening the `project.godot` file
3. Press **F5** or click the **Play** button to run the game

### Regenerating audio assets (optional)
Audio is generated procedurally with Python + numpy:
```bash
python tools/generate_music.py   # writes assets/music/*.wav
python tools/generate_sfx.py     # writes assets/sfx/*.wav
```

## Project Structure
- `scenes/` - Game scenes
  - `ui/` - HUD, pause menu, settings, level select, credits
  - `levels/` - data-driven `base_level` and the boss level
  - `entities/` - projectile, enemy, rescue animal
- `scripts/`
  - `autoload/` - GameState (progression/save), Settings, AudioManager
  - `levels/`, `forms/`, `entities/`, `ui/`
- `sprites/` - player, forms, animals, enemies, items, boss
- `backgrounds/` - per-theme parallax layers (menu, cruise, ice, lava, jungle, island, pirate, credits)
- `assets/music/`, `assets/sfx/` - generated audio
- `tools/` - audio generation scripts

## Future Plans / Next Steps
- Full mammoth wall-phasing and object-toss physics
- Monkey rigging-swing traversal and dedicated eagle vertical flying section
- Richer hand-authored tilemap geometry per level
- OGG-compressed music, more enemy variety, and expanded boss attack patterns
- Save-slot UI and accessibility options
