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
		# Overcast: cool-white ambient, dim diffuse sky light, blue-white snow uplight.
		"lighting": {
			"ambient": Color(0.84, 0.89, 0.98),
			"sky_color": Color(0.96, 0.98, 1.0), "sky_energy": 0.35,
			"uplight_color": Color(0.62, 0.78, 1.0), "uplight_energy": 0.5,
		},
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
		# Lava glow: darken the scene so warm pools cast yellow/orange/red light
		# onto the player and platforms; an eagle laser turret patrols the right.
		"lighting": {
			"ambient": Color(0.6, 0.42, 0.36),
			"glow_colors": [Color(1.0, 0.78, 0.2), Color(1.0, 0.5, 0.15), Color(1.0, 0.3, 0.12)],
			"glow_energy": 1.1,
		},
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
		# Bright daytime sun: warm key light plus simulated drop-shadows cast toward
		# the ground. Distant scenery drifts slowly far behind the island layers.
		"lighting": {
			"sun_color": Color(1.0, 0.95, 0.82), "sun_energy": 0.3,
		},
		"far_layers": [
			{"tex": B + "island/volcano_dormant.svg", "scale": 0.05},
			{"tex": B + "island/green_mountains.svg", "scale": 0.1},
			{"tex": B + "island/waterfalls.svg", "scale": 0.13},
		],
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
		# Dusk galleon: darken the deck so the strung lanterns read as live flames.
		"lighting": {
			"ambient": Color(0.6, 0.58, 0.74),
			"lantern_color": Color(1.0, 0.66, 0.32), "lantern_energy": 1.2,
		},
	},
	"ocean_floor": {
		"layers": [
			{"tex": B + "ocean_floor/sky_ocean_floor.svg", "scale": 0.0},
			{"tex": B + "ocean_floor/reef_far.svg", "scale": 0.2},
			{"tex": B + "ocean_floor/kelp_mid.svg", "scale": 0.42},
			{"tex": B + "ocean_floor/seabed_near.svg", "scale": 0.65},
		],
		"fx": "rain", "fx_tex": B + "ocean_floor/bubbles.svg",
		"ground": Color(0.14, 0.26, 0.31), "platform": Color(0.2, 0.38, 0.44),
	},
	"space": {
		"layers": [
			{"tex": B + "space/sky_space.svg", "scale": 0.0},
			{"tex": B + "space/stars_far.svg", "scale": 0.12},
			{"tex": B + "space/nebula_mid.svg", "scale": 0.32},
			{"tex": B + "space/station_near.svg", "scale": 0.58},
		],
		"fx": "rain", "fx_tex": B + "space/cosmic_dust.svg",
		"ground": Color(0.18, 0.2, 0.31), "platform": Color(0.33, 0.36, 0.52),
	},
	"factory": {
		"layers": [
			{"tex": B + "factory/sky_factory.svg", "scale": 0.0},
			{"tex": B + "factory/smokestacks_far.svg", "scale": 0.15},
			{"tex": B + "factory/pipes_mid.svg", "scale": 0.36},
			{"tex": B + "factory/conveyor_near.svg", "scale": 0.62},
		],
		"fx": "embers", "fx_tex": B + "factory/sparks.svg",
		"ground": Color(0.33, 0.31, 0.3), "platform": Color(0.46, 0.42, 0.36),
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
