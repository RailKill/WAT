extends Node
class_name WATTest

# We can't namespace stuff in a single script unfortunately
const EXPECTATIONS = preload("res://addons/WAT/test/expectations.gd")
const DOUBLE = preload("res://addons/WAT/double/doubler.gd")
const WATCHER = preload("res://addons/WAT/test/watcher.gd")
const YIELD: String = "finished"

var expect: EXPECTATIONS
var watcher: WATCHER
var case

func _init():
	_set_properties()
	_create_connections()
	
func _set_properties():
	expect = EXPECTATIONS.new()
	watcher = WATCHER.new()
#	case = CASE.new(title())

func _create_connections():
	expect.set_meta("watcher", watcher)
#	expect.connect("OUTPUT", case, "_add_expectation")
	
var methods: Array = []

func start():
	pass
	
func pre():
	pass
	
func post():
	pass
	
func end():
	pass

func title() -> String:
	return self.get_script().get_path()
	
func watch(emitter, event: String) -> void:
	watcher.watch(emitter, event)
	
## Untested
## Thanks to bitwes @ https://github.com/bitwes/Gut/
func simulate(obj, times, delta):
	for i in range(times):
		if(obj.has_method("_process")):
			obj._process(delta)
		if(obj.has_method("_physics_process")):
			obj._physics_process(delta)

		for kid in obj.get_children():
			simulate(kid, 1, delta)
			
func until_signal(emitter: Object, event: String, time_limit: float) -> Node:
	watch(emitter, event)
	return get_parent().until_signal(emitter, event, time_limit)
	
func until_timeout(time_limit: float) -> Node:
	return get_parent().until_timeout(time_limit)