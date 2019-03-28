extends Reference

const SCRIPT_DATA = preload("script_data.gd")
var _nodes: Dictionary = {}
var instance: Node

func _init(nodes, scene: Node) -> void:
	self.instance = scene
	for data in nodes:
		if data.scriptpath != null:
			var path: String = str(data.nodepath)
			var node = instance.get_node(path)
			var methods = data.methods
			_nodes[path] = SCRIPT_DATA.new(methods, node)
	
func get_retval(node: String, method: String, arguments: Dictionary):
	return _nodes[node].get_retval(method, arguments)
	
func stub(node: String, method: String, arguments: Dictionary, retval) -> void:
	_nodes[node].stub(method, arguments, retval)
	
func call_count(node: String, method: String) -> int:
	return _nodes[node].call_count(method)
	
func calls(node: String, method: String) -> Array:
	return _nodes[node].calls(method)