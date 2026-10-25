extends TestCase
## Self-tests for the test framework: a broken assertion helper would silently
## turn every other test green.


func test_assert_eq_passes_on_equal_values() -> void:
	var probe := TestCase.new()
	probe.assert_eq(3, 3)
	probe.assert_eq("iron", "iron")
	probe.assert_eq([1, 2], [1, 2])
	assert_eq(probe.failures.size(), 0)


func test_assert_eq_fails_on_different_values() -> void:
	var probe := TestCase.new()
	probe.assert_eq(3, 4)
	assert_eq(probe.failures.size(), 1)


func test_assert_eq_fails_on_mismatched_types() -> void:
	var probe := TestCase.new()
	probe.assert_eq(1, "1")
	assert_eq(probe.failures.size(), 1)


func test_assert_eq_treats_int_and_float_as_numeric() -> void:
	var probe := TestCase.new()
	probe.assert_eq(2, 2.0)
	assert_eq(probe.failures.size(), 0)


func test_failure_message_includes_context() -> void:
	var probe := TestCase.new()
	probe.assert_true(false, "battery check")
	assert_eq(probe.failures.size(), 1)
	assert_true(probe.failures[0].begins_with("battery check"))
