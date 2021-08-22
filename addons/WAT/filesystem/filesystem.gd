#tool
extends Reference

const Validator: GDScript = preload("validator.gd")
const DO_NOT_SEARCH_PARENT_DIRECTORIES: bool = true
var root: TestDirectory
var changed: bool = false

func _init() -> void:
	root = TestDirectory.new()
	root.path = load("res://addons/WAT/settings.gd").test_directory()
	
func update(testdir: TestDirectory = root) -> void:
	var dir: Directory = Directory.new()
	var err: int = dir.open(root.path)
	if err != OK:
		push_warning("WAT: Could not update filesystem")
		return
	
	var subdirs: Array = []
	dir.list_dir_begin(DO_NOT_SEARCH_PARENT_DIRECTORIES)
	var absolute: String = ""
	var relative: String = dir.get_next()
	while relative != "":
		absolute = "%s/%s" % [testdir.path, relative]
		
		if dir.current_is_dir():
			var sub_testdir: TestDirectory = TestDirectory.new()
			sub_testdir.path = absolute
			
		elif Validator.is_valid_test(absolute):
			var test_script: TestScript = TestScript.new()
			test_script.path = absolute
			
		relative = dir.get_next()
		
	dir.list_dir_end()
			
	testdir.relative_subdirs += subdirs
	testdir.nested_subdirs += subdirs
	for subdir in subdirs:
		update(subdir)
		testdir.nested_subdirs += subdir.nested_subdirs
	
### BEGIN VALIDATOR CLASS ###

### BEGIN FACTORY CLASS ###
class TestDirectory:
	var path: String
	var relative_subdirs: Array
	var nested_subdirs: Array
	
	func _init() -> void:
		pass
		
class TestScript:
	var path: String
	var methods: Array # TestMethods
	
	func _init() -> void:
		pass
		
class TestMethod:
	var path: String
	var method: String
		
class TestTag:
	var tag: String
	var tagged: Array
	
	func _init() -> void:
		pass
### END VALIDATOR CLASS ###


#const Settings: Script = preload("res://addons/WAT/settings.gd")
#const YieldCalculator: GDScript = preload("res://addons/WAT/filesystem/yield_calculator.gd")
#const FileObjects: GDScript = preload("res://addons/WAT/filesystem/objects.gd")
#const TestDirectory: GDScript = FileObjects.TestDirectory
#const TestScript: GDScript = FileObjects.TestScript
#const TestMethod: GDScript = FileObjects.TestMethod
#const TestTag: GDScript = FileObjects.TestTag
#const TestFailures: GDScript = FileObjects.TestFailures
#var has_been_changed: bool = false
#var resource
#
#var dirs: Array = []
#var _all_tests: Array = []
#var _tag_metadata: Dictionary = {} # resource path, script,
#var tags: Dictionary = {} 
#var failed
#var indexed: Dictionary = {}
#
#func get_tests() -> Array:
#	return _all_tests
#
#func set_failed(results: Array) -> void:
#	# TODO: Cache for better performance
#	failed.tests.clear()
#	for result in results:
#		if not result.success:
#			for test in _all_tests:
#				if test.path == result.path:
#					print(test)
#					failed.tests.append(test)
#					resource.scripts[test.path] = {"failed": true, "tags": test.tags}
#
#func initialize() -> void:
#	resource = load(ProjectSettings.get_setting("WAT/Test_Metadata_Directory") + "/test_metadata.tres")
#	failed = TestFailures.new()
#	indexed["failed"] = failed
#	# add failures from resource script
#	update()
#
#	# Initialize old failures
#	for test in _all_tests:
#		if resource.scripts.has(test.path) and resource.scripts[test.path]["failed"]:
#			failed.tests.append(test)
#
#func _initialize_tags() -> void:
#	for tag in Settings.tags():
#		indexed[tag] = TestTag.new(tag)
#
#func update() -> void:
#	dirs.clear()
#	_all_tests.clear()
#	indexed.clear()
#	_initialize_tags()
#	var absolute_path = Settings.test_directory()
#	var primary = TestDirectory.new(absolute_path)
#	indexed["all"] = self
#	indexed[absolute_path] = primary
#	dirs.append(primary)
#	_update(primary)
#	has_been_changed = true
#
#func _update(testdir: TestDirectory) -> void:
#	var dir: Directory = Directory.new()
#	if dir.open(testdir["path"]) != OK:
#		push_warning("WAT: Could not update filesystem")
#		return
#
#	# Should this be a different function?
#	var subdirs: Array = []
#	dir.list_dir_begin(DO_NOT_SEARCH_PARENT_DIRECTORIES)
#	var relative_path: String = dir.get_next()
#	while relative_path != "":
#		var absolute_path: String = "%s/%s" % [testdir.path, relative_path]
#		if dir.dir_exists(absolute_path):
#			var directory = TestDirectory.new(absolute_path)
#			subdirs.append(directory)
#			indexed[absolute_path] = directory
#
#		elif Validator.is_valid_test(absolute_path):
#			var test: TestScript = _get_test_script(testdir.path, absolute_path)
#			indexed[absolute_path] = test
#			for tag in test.tags:
#				if tag in Settings.tags():
#					indexed[tag].tests.append(test)
#				else:
#					# Push an add check here to auto-add it?
#					push_warning("Tag %s does not exist in WAT Settings")
#
#			for method in test.methods:
#				indexed[absolute_path+method.name] = method
#			if not test.methods.empty():
#				testdir.tests.append(test)
#				_all_tests += test.get_tests()
#
#			# We load our saved tags
#			# We check if our saved tags exist
#			# If they don't, we don't add them
#			# If they do, we do add them
#			# However we do not delete old tags, we just hide them..
#			# ..so that when a tag is re-added, the old tests pop up again
#
#		relative_path = dir.get_next()
#	dir.list_dir_end()
#
#	dirs += subdirs
#	for subdir in subdirs:
#		_update(subdir)
#
#
#func _get_test_script(dir: String, path: String) -> TestScript:
#	var gdscript: Script = load(path)
#	var test: TestScript = TestScript.new(dir, path, load(path))
#	if _tag_metadata.has(test.gdscript.resource_path):
#		test.tags = _tag_metadata[test.gdscript.resource_path]
#
#	# Check if it had failed
#	var failed = false if not resource.scripts.has(path) else resource.scripts[path]["failed"] 
#	# get tags from resource
#	if resource.scripts.has(path):
#		for tag in resource.scripts[path]["tags"]:
#			if not tag in test.tags:
#				test.tags.append(tag)
#		resource.scripts[path] = {"failed": failed, "tags": test.tags}
#	else:
#		resource.scripts[path] = {"failed": false, "tags": test.tags}
#
#	var methods = test.gdscript.new().get_test_methods()
#	for m in methods:
#		test.method_names.append(m)
#		test.methods.append(TestMethod.new(dir, test.path, test.gdscript, m))
#	test.yield_time = YieldCalculator.calculate_yield_time(test.gdscript, test.method_names.size())
#	return test
#
#func add_test_to_tag(test, tag: String) -> void:
#	indexed[tag].tests.append(test)
#
#func remove_test_from_tag(test, tag: String) -> void:
#	indexed[tag].tests.erase(test)
#
#func _on_file_moved(source: String, destination: String) -> void:
#	if(source.ends_with(".sln") or source.ends_with(".csproj") or ".mono" in source or ".import" in source):
#		return
#	if(destination.ends_with(".sln") or destination.ends_with(".csproj") or ".mono" in destination or ".import" in destination):
#		return
#	var key: String = source.rstrip("/")
#	var tags: Array = _tag_metadata.get(key, [])
#	var dest: Resource = load(destination)
#	if _is_in_test_directory(source) or _is_in_test_directory(destination):
#		# Swapping Tags
#		_tag_metadata[dest.resource_path] = tags
#		_tag_metadata.erase(key)
#		has_been_changed = true
#
#func _on_resource_saved(resource: Resource) -> void:
#	if("res://addons/WAT/" in resource.resource_path):
#		return
#	if _is_in_test_directory(resource.resource_path):
#		has_been_changed = true
#
#func _is_in_test_directory(path: String) -> bool:
#	return path.begins_with(Settings.test_directory())
#
#func _on_filesystem_changed(source: String, destination: String = "") -> void:
#	for path in [source, destination]:
#		if _is_in_test_directory(path):
#			has_been_changed = true
