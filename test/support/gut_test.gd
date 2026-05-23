extends RefCounted
class_name GutTest

# Minimal assertion base used by unit tests in this repo when full GUT addon isn't vendored.
func assert_eq(actual, expected, message := ""):
	assert(actual == expected, message)

func assert_true(value, message := ""):
	assert(value, message)

func assert_null(value, message := ""):
	assert(value == null, message)

func assert_gt(actual, threshold, message := ""):
	assert(actual > threshold, message)

func assert_almost_eq(actual: float, expected: float, tolerance: float, message := ""):
	assert(abs(actual - expected) <= tolerance, message)
