extends RefCounted
class_name MorphForms
## Static definitions for Morphomon's transformation forms.
##
## Each form sets movement parameters and an offensive style. `attack_kind` is
## one of: "missile" (homing projectile), "laser" (straight projectile),
## "melee" (short-range hitbox). `ability` names the special movement skill,
## surfaced to gameplay and the HUD ("dash", "toss", "fly", "swing").

const S := "res://sprites/forms/"

const FORMS := {
	"default": {
		"name": "Morphomon",
		"idle": S + "morphomon_idle.svg", "run": S + "morphomon_run.svg",
		"speed": 220.0, "jump": -430.0, "can_fly": false, "double_jump": false,
		"attack_kind": "missile", "ability": "dash",
		"phase_walls": false,
	},
	"panther": {
		"name": "Panther",
		"idle": S + "panther_idle.svg", "run": S + "panther_run.svg",
		"speed": 280.0, "jump": -620.0, "can_fly": false, "double_jump": true,
		"attack_kind": "melee", "ability": "dash",
		"phase_walls": false,
	},
	"mammoth": {
		"name": "Mammoth",
		"idle": S + "mammoth_idle.svg", "run": S + "mammoth_run.svg",
		"speed": 200.0, "jump": -380.0, "can_fly": false, "double_jump": false,
		"attack_kind": "melee", "ability": "toss",
		"phase_walls": true,
	},
	"eagle": {
		"name": "Eagle",
		"idle": S + "eagle_idle.svg", "run": S + "eagle_fly.svg",
		"speed": 260.0, "jump": -420.0, "can_fly": true, "double_jump": false,
		"attack_kind": "laser", "ability": "fly",
		"phase_walls": false,
	},
	"monkey": {
		"name": "Monkey",
		"idle": S + "monkey_idle.svg", "run": S + "monkey_run.svg",
		"speed": 250.0, "jump": -500.0, "can_fly": false, "double_jump": true,
		"attack_kind": "melee", "ability": "roll",
		"phase_walls": false,
	},
	"swordfish": {
		"name": "Swordfish",
		"idle": S + "swordfish_form_idle.svg", "run": S + "swordfish_form_run.svg",
		"speed": 295.0, "jump": -470.0, "can_fly": false, "double_jump": true,
		"attack_kind": "laser", "ability": "dash",
		"phase_walls": false,
	},
	"alien": {
		"name": "Alien",
		"idle": S + "alien_form_idle.svg", "run": S + "alien_form_run.svg",
		"speed": 240.0, "jump": -420.0, "can_fly": true, "double_jump": false,
		"attack_kind": "missile", "ability": "fly",
		"phase_walls": true,
	},
	"stuffed_bear": {
		"name": "Stuffed Bear",
		"idle": S + "stuffed_bear_form_idle.svg", "run": S + "stuffed_bear_form_run.svg",
		"speed": 215.0, "jump": -390.0, "can_fly": false, "double_jump": false,
		"attack_kind": "melee", "ability": "toss",
		"phase_walls": false,
	},
}


static func get_form(form_id: String) -> Dictionary:
	return FORMS.get(form_id, FORMS["default"])
