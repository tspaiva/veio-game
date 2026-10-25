class_name TestCase
extends RefCounted
## Base class for unit tests.
##
## Every method whose name starts with `test_` is run by `run_tests.gd`.
## A fresh instance is created per test method, so tests never share state.

var failures: PackedStringArray = []


## Called before each test method. Override to set up fixtures.
func before_each() -> void:
	pass


## Called after each test method. Override to tear down fixtures.
func after_each() -> void:
	pass


func fail(message: String) -> void:
	failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		fail(_with_context("expected true, got false", message))


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		fail(_with_context("expected false, got true", message))


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if not _equals(actual, expected):
		fail(_with_context("expected %s, got %s" % [_repr(expected), _repr(actual)], message))


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if _equals(actual, unexpected):
		fail(_with_context("expected anything but %s" % _repr(unexpected), message))


func assert_null(value: Variant, message: String = "") -> void:
	if value != null:
		fail(_with_context("expected null, got %s" % _repr(value), message))


func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		fail(_with_context("expected non-null value", message))


# Compares by type first so mismatched types fail instead of raising a runtime
# error. int and float are treated as one numeric type.
func _equals(a: Variant, b: Variant) -> bool:
	var ta := typeof(a)
	var tb := typeof(b)
	var numeric := [TYPE_INT, TYPE_FLOAT]
	if ta != tb and not (ta in numeric and tb in numeric):
		return false
	return a == b


func _repr(value: Variant) -> String:
	if value is String or value is StringName:
		return "\"%s\"" % value
	return var_to_str(value)


func _with_context(detail: String, message: String) -> String:
	return detail if message.is_empty() else "%s: %s" % [message, detail]
