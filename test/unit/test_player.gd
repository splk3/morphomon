extends GutTest

const PlayerScript = preload("res://scripts/player.gd")
# 0.01 is sufficient for gravity * delta float math in these physics assertions.
const PHYSICS_FLOAT_TOLERANCE = 0.01
var _player = null

func before_each():
	_player = PlayerScript.new()

func after_each():
	if _player:
		_player.free()

func test_initial_values():
	assert_eq(_player.SPEED, 200.0, "Default SPEED should be 200.0")
	assert_eq(_player.JUMP_VELOCITY, -400.0, "Default JUMP_VELOCITY should be -400.0")
	assert_true(_player.facing_right, "Player should face right by default")

func test_gravity_setup():
	var expected_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	assert_eq(_player.gravity, expected_gravity, "Player gravity should match project settings")

func test_update_animation_handles_null_animation_player():
	# By default, animation_player is @onready and will be null when using .new()
	# without adding to the SceneTree.
	# We want to ensure calling update_animation doesn't crash when animation_player is null.
	_player.update_animation()
	assert_null(_player.animation_player, "animation_player should be null for new instance")

func test_physics_process_applies_gravity():
	# CharacterBody2D.is_on_floor() returns false by default for a new instance not in SceneTree.
	_player.gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	_player.velocity.y = 0.0
	_player._physics_process(0.1)
	assert_almost_eq(_player.velocity.y, _player.gravity * 0.1, PHYSICS_FLOAT_TOLERANCE, "Vertical velocity should increase by gravity * delta")
