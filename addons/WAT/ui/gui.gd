tool
extends PanelContainer


# Resources require tool to work inside the editor whereas..
# ..scripts objects without tool can be called from tool based scripts
const TestRunner: PackedScene = preload("res://addons/WAT/runner/TestRunner.tscn")
const XML: Script = preload("res://addons/WAT/editor/junit_xml.gd")
const PluginAssetsRegistry: Script = preload("res://addons/WAT/ui/plugin_assets_registry.gd")

onready var TestMenu: Button = $Core/Menu/TestMenu
onready var Results: TabContainer = $Core/Results
onready var Summary: HBoxContainer = $Core/Summary
onready var Threads: SpinBox = $Core/Menu/RunSettings/Threads
onready var Repeats: SpinBox = $Core/Menu/RunSettings/Repeats

# Buttons
onready var RunAll: Button = $Core/Menu/RunAll
onready var DebugAll: Button = $Core/Menu/DebugAll
onready var RunFailed: Button = $Core/Menu/RunFailed
onready var DebugFailed: Button = $Core/Menu/DebugFailed

onready var ViewMenu: PopupMenu = $Core/Menu/ResultsMenu.get_popup()
onready var Menu: HBoxContainer = $Core/Menu
onready var Server: Node = $Server

var filesystem = preload("res://addons/WAT/filesystem/filesystem.gd").new()
var instance: Node
var _plugin: Node

func _ready() -> void:
	TestMenu.filesystem = filesystem
	setup_game_context()
	Threads.max_value = OS.get_processor_count() - 1
	Threads.min_value = 1
	Results.connect("function_selected", self, "_on_function_selected")
	ViewMenu.connect("index_pressed", Results, "_on_view_pressed")
	TestMenu.connect("tests_selected", self, "_launch")	
	_connect_run_button(RunAll, WAT.RUN, filesystem)
	_connect_run_button(DebugAll, WAT.DEBUG, filesystem)
	_connect_run_button(RunFailed, WAT.RUN, filesystem.failed)
	_connect_run_button(DebugFailed, WAT.DEBUG, filesystem.failed)

func _connect_run_button(run: Button, run_type: int, source: Reference) -> void:
	run.connect("pressed", self, "_launch", [WAT.TestParcel.new(run_type, source)])

func setup_game_context() -> void:
	if Engine.is_editor_hint():
		return
	OS.window_size = ProjectSettings.get_setting("WAT/Window_Size")
	# No argument makes the AssetsRegistry default to a scale of 1, which
	# should make every icon look normal when the Tests UI launches
	# outside of the editor.
	DebugAll.disabled = true
	DebugFailed.disabled = true
	_setup_editor_assets(PluginAssetsRegistry.new())
	
func _launch(parcel: WAT.TestParcel) -> void:
	var tests: Array = parcel.get_tests()
	if tests.empty():
		push_warning("Tests not found")
		return
	Results.clear()
	Summary.time()
	var results: Array = []
	match parcel.run_type:
		WAT.RUN:
			results = yield(_launch_runner(tests, Repeats.value, Threads.value), WAT.COMPLETED)
		WAT.DEBUG:
			results = yield(_launch_debugger(tests, Repeats.value, Threads.value), WAT.COMPLETED)
	Summary.summarize(results)
	XML.write(results)
	Results.display(results)
	filesystem.set_failed(results)

func _launch_runner(tests: Array, repeat: int, threads: int) -> Array:
	instance = TestRunner.instance()
	add_child(instance)
	var results = yield(instance.run(tests, repeat, threads), "completed")
	instance.queue_free()
	return results
	
func _launch_debugger(tests: Array, repeat: int, threads: int) -> Array:
	# Likely best to replace run/play these with signals
	_plugin.get_editor_interface().play_custom_scene("res://addons/WAT/runner/TestRunner.tscn")
	_plugin.make_bottom_panel_item_visible(self)
	yield(Server, "network_peer_connected")
	Server.send_tests(tests, repeat, threads)
	var results = yield(Server, "results_received")
	_plugin.get_editor_interface().stop_playing_scene()
	return results
	
# TO BE MOVED SOMEWHERE MORE PROPER
func setup_editor_context(plugin: Node) -> void:
	# Seems like this would be better in plugin.gd?
	# Maybe even a seperate script?
	_plugin = plugin
	var file_dock: Node = plugin.get_editor_interface().get_file_system_dock()
	for event in ["folder_removed", "folder_moved", "file_removed"]:
		file_dock.connect(event, filesystem, "_on_filesystem_changed", [], CONNECT_DEFERRED)
	file_dock.connect("files_moved", filesystem, "_on_file_moved")
	_plugin.connect("resource_saved", filesystem, "_on_resource_saved", [], CONNECT_DEFERRED)
	
# Loads scaled assets like icons and fonts
func _setup_editor_assets(assets_registry):
	Summary._setup_editor_assets(assets_registry)
	Results._setup_editor_assets(assets_registry)
#	TestMenu._setup_editor_assets(assets_registry)
	RunAll.icon = assets_registry.load_asset(RunAll.icon)
	DebugAll.icon = assets_registry.load_asset(DebugAll.icon)
	RunFailed.icon = assets_registry.load_asset(RunFailed.icon)
	DebugFailed.icon = assets_registry.load_asset(DebugFailed.icon)

func _on_function_selected(path: String, function: String) -> void:
	if not _plugin:
		return
	var script: Script = load(path)
	var script_editor = _plugin.get_editor_interface().get_script_editor()
	_plugin.get_editor_interface().edit_resource(script)
	
	# We could add this as metadata information when looking for yield times
	# ..in scripts?
	var idx: int = 0
	for line in script.source_code.split("\n"):
		idx += 1
		if function in line and line.begins_with("func"):
			script_editor.goto_line(idx)
			return
