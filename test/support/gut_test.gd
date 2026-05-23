# Lightweight GUT-compatible test base for this repository.
# Provides only the assertion helpers currently needed by local unit tests.
# This keeps tests loadable without vendoring the full GUT addon.
extends RefCounted
class_name GutTest

func assert_eq(actual, expected, message := ""):
	assert(actual == expected, message)

func assert_true(value, message := ""):
	assert(value, message)

func assert_null(value, message := ""):
	assert(value == null, message)

func assert_gt(actual, threshold, message := ""):
	assert(actual > threshold, message)

func assert_almost_eq(actual: float, expected: float, tolerance: float, message := ""):
	# Inclusive tolerance mirrors common testing frameworks and avoids flaky boundary failures.
	# For small physics deltas in this project, tests typically use a 0.01 tolerance.
	assert(abs(actual - expected) <= tolerance, message)
