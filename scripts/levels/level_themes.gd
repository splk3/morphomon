extends RefCounted
class_name LevelThemes
## Static visual configuration for each level theme.
##
## Drives the shared `base_level` scene: a list of parallax layers (texture +
## horizontal motion scale, ordered back-to-front), an optional weather overlay
## (`fx`), and the ground/platform tint colors. Keeping this data-driven lets a
## single scene render every themed level.

const B := "res://backgrounds/"

const THEMES := {
	"cruise": {
		"layers": [
			{"tex": B + "cruise/sky_day.svg", "scale": 0.0},
			{"tex": B + "cruise/sea.svg", "scale": 0.15},
			{"tex": B + "cruise/deck_props.svg", "scale": 0.4},
			{"tex": B + "cruise/ship_rail.svg", "scale": 0.6},
		],
		"fx": "none", "ground": Color(0.78, 0.65, 0.45), "platform": Color(0.55, 0.4, 0.25),
	},
	"ice": {
		"layers": [
			{"tex": B + "ice/sky_ice.svg", "scale": 0.0},
			{"tex": B + "ice/mountains_snow.svg", "scale": 0.2},
			{"tex": B + "ice/ice_trees.svg", "scale": 0.45},
			{"tex": B + "ice/snow_drift.svg", "scale": 0.7},
		],
		"fx": "snow", "fx_tex": B + "ice/snowflakes.svg",
		"ground": Color(0.85, 0.92, 0.98), "platform": Color(0.6, 0.78, 0.9),
	},
	"lava": {
		"layers": [
			{"tex": B + "lava/sky_lava.svg", "scale": 0.0},
			{"tex": B + "lava/volcanoes.svg", "scale": 0.2},
			{"tex": B + "lava/rocks_far.svg", "scale": 0.4},
		],
		"fx": "embers", "fx_tex": B + "lava/embers.svg",
		"lava_anim": [B + "lava/lava_a.svg", B + "lava/lava_b.svg"],
		"ground": Color(0.25, 0.12, 0.1), "platform": Color(0.4, 0.18, 0.12),
	},
	"island": {
		"layers": [
			{"tex": B + "island/sky_island.svg", "scale": 0.0},
			{"tex": B + "island/sea_island.svg", "scale": 0.15},
			{"tex": B + "island/island_hills.svg", "scale": 0.35},
			{"tex": B + "island/palms_island.svg", "scale": 0.55},
			{"tex": B + "island/sand.svg", "scale": 0.75},
		],
		"fx": "none", "ground": Color(0.93, 0.85, 0.6), "platform": Color(0.7, 0.6, 0.4),
	},
	"jungle": {
		"layers": [
			{"tex": B + "jungle/sky_jungle.svg", "scale": 0.0},
			{"tex": B + "jungle/canopy_far.svg", "scale": 0.2},
			{"tex": B + "jungle/vines.svg", "scale": 0.4},
			{"tex": B + "jungle/foliage_near.svg", "scale": 0.65},
		],
		"fx": "rain", "fx_tex": B + "jungle/rain.svg",
		"ground": Color(0.3, 0.4, 0.2), "platform": Color(0.35, 0.28, 0.18),
	},
	"pirate": {
		"layers": [
			{"tex": B + "pirate/sky_dusk.svg", "scale": 0.0},
			{"tex": B + "pirate/sea_dark.svg", "scale": 0.15},
			{"tex": B + "pirate/masts_rigging.svg", "scale": 0.4},
			{"tex": B + "pirate/deck_pirate.svg", "scale": 0.6},
		],
		"fx": "none", "ground": Color(0.45, 0.32, 0.2), "platform": Color(0.3, 0.2, 0.12),
	},
	"boss": {
		"layers": [
			{"tex": B + "lava/sky_lava.svg", "scale": 0.0},
			{"tex": B + "lava/rocks_far.svg", "scale": 0.3},
		],
		"fx": "embers", "fx_tex": B + "lava/embers.svg",
		"ground": Color(0.15, 0.15, 0.2), "platform": Color(0.25, 0.25, 0.3),
	},
}


static func get_theme(theme_id: String) -> Dictionary:
	return THEMES.get(theme_id, THEMES["island"])
