tool
extends Tree

enum {
	SCRIPT
	METHOD
	EXPECTATION
}

enum {
	TOTAL
	PASSED
}

const TOTALS: Dictionary = {SCRIPT: {TOTAL: 0, PASSED: 0}, METHOD: {TOTAL: 0, PASSED: 0}, EXPECTATION: {TOTAL: 0, PASSED: 0}}
const SUCCESS: Color = Color(0, 1, 0, 1)
const FAILED: Color = Color(1, 1, 1, 1)
var _root: TreeItem

func _enter_tree() -> void:
	reset()

func reset() -> void:
	_reset_all_totals()
	clear()
	_root = create_item()
	_root.set_text(0, "Test Root Created")
	

func _display_results(cases: Array):	
	for case in cases:
		display(case)

func display(case) -> void:
	var script: TreeItem = create_item(_root)
	script.collapsed = true
	for test in case.tests():
		_add_tests(test, script)
	_set_base_details(script, case)
	_transform_totals(SCRIPT, _root, case.success)
	_reset_totals(METHOD)

func _add_tests(test, root_script: TreeItem) -> void:
	var method: TreeItem = create_item(root_script)
	for expectation in test.expectations:
		_add_expectation(expectation, method)
	_set_base_details(method, test)
	_transform_totals(METHOD, root_script, test.success)
	_reset_totals(EXPECTATION)

func _add_expectation(expectation: Dictionary, method: TreeItem):
	# We may need to expand this further later
	var expect: TreeItem = create_item(method)
	_set_base_details(expect, expectation)
	expect.set_text(1, "Result:    %s" % expectation.result)
	_transform_totals(EXPECTATION, method, expectation.success)

func _set_base_details(item: TreeItem, test) -> void:
	item.set_text(0, test.details)
	if test.success:
		item.set_custom_color(0, SUCCESS)
		item.set_custom_color(1, SUCCESS)
	if test.get("notes"):
		var example = "Implicit Conversion\nInt will never be Float\nRandomNote"
		test.notes = example
		item.set_text(2, "Notes: %s" % str(len(test.notes.split("\n"))))
		item.set_tooltip(2, test.notes)

func _add_total(key: int, success) -> void:
	TOTALS[key][TOTAL] += 1
	if success:
		TOTALS[key][PASSED] += 1

func _set_totals(key: int, item: TreeItem = self._root):
	item.set_text(1, "%s / %s " % [TOTALS[key][PASSED], TOTALS[key][TOTAL]])
	if TOTALS[key][PASSED] == TOTALS[key][TOTAL]:
		item.set_custom_color(1, SUCCESS)
		# We're mainly doing this for the top root but maybe we can change it for others to?
		item.set_custom_color(0, SUCCESS)
	else:
		item.set_custom_color(0, FAILED)
		item.set_custom_color(1, FAILED)

func _transform_totals(key: int, parent: TreeItem, success: bool):
	_add_total(key, success)
	_set_totals(key, parent)

func _reset_totals(key: int):
	TOTALS[key][PASSED] = 0
	TOTALS[key][TOTAL] = 0

func _reset_all_totals():
	_reset_totals(SCRIPT)
	_reset_totals(METHOD)
	_reset_totals(EXPECTATION)

