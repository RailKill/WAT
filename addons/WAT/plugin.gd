tool
extends EditorPlugin

const TITLE: String = "Tests"
const Global: String = "res://addons/WAT/globals/namespace.gd"
const EditorContext = preload("res://addons/WAT/ui/editor_context.gd")
const ControlPanel: PackedScene = preload("res://addons/WAT/gui.tscn")
const TestMetadataEditor: Script = preload("res://addons/WAT/ui/metadata/editor.gd")
const DockController: Script = preload("ui/dock.gd")

var _ControlPanel: PanelContainer
var _TestMetadataEditor: EditorInspectorPlugin
var _DockController: Node

func get_plugin_name() -> String:
   return "WAT"

func _enter_tree() -> void:
	yield(get_tree(), "idle_frame")
	if not get_tree().root.has_node("WATNamespace"):
		var autoload = load(Global).new()
		autoload.name = "WATNamespace"
		get_tree().root.add_child(autoload, true)
#		add_autoload_singleton("WATNamespace", Global)

	_ControlPanel = ControlPanel.instance()
	_ControlPanel.EditorContext = EditorContext
	_TestMetadataEditor = TestMetadataEditor.new()
	_DockController = DockController.new(self, _ControlPanel)
	
	add_inspector_plugin(_TestMetadataEditor)
	add_child(_DockController)
	
	_ControlPanel.Results.connect("function_sought", self, "goto_function")
		
func connect_filemanager() -> void:
	var filedock = get_editor_interface().get_file_system_dock()
	filedock.connect("files_moved", get_tree().root.get_node("WATNamespace").FileManager, "_on_files_moved")
	filedock.connect("file_removed", get_tree().root.get_node("WATNamespace").FileManager, "_on_files_removed")
	filedock.connect("folder_moved", get_tree().root.get_node("WATNamespace").FileManager, "_on_folder_moved")
	filedock.connect("folder_removed", get_tree().root.get_node("WATNamespace").FileManager, "_on_folder_removed")
	
func goto_function(path: String, function: String):
	var script: Script = load(path)
	get_editor_interface().edit_resource(script)
	var source: PoolStringArray = script.source_code.split("\n")
	for i in source.size():
		if function in source[i] and "describe" in source[i]:
			get_editor_interface().get_script_editor().goto_line(i)
			return

func _exit_tree() -> void:
	_DockController.free()
	_ControlPanel.free()
	remove_inspector_plugin(_TestMetadataEditor)
	
