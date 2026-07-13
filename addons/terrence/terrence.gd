@tool
extends EditorPlugin

var mesh_importer
var anim_importer


func _enter_tree():

	mesh_importer = preload("res://addons/terrence/timf_importer.gd").new()
	anim_importer = preload("res://addons/terrence/tiaf_importer.gd").new()

	add_import_plugin(mesh_importer)
	add_import_plugin(anim_importer)

	add_tool_menu_item(
		"Build Terrence Assets",
		Callable(self, "_build_assets")
	)


func _exit_tree():

	remove_import_plugin(mesh_importer)
	remove_import_plugin(anim_importer)

	remove_tool_menu_item(
		"Build Terrence Assets"
	)


func _build_assets():

	_scan("res://")


func _scan(path):

	var dir = DirAccess.open(path)

	if dir == null:
		return

	dir.list_dir_begin()

	while true:

		var file = dir.get_next()

		if file == "":
			break

		if file.begins_with("."):
			continue

		var full = path.path_join(file)

		if dir.current_is_dir():

			_scan(full)

		elif file.ends_with(".timf") or file.ends_with(".tiaf"):

			_compile(full)

	dir.list_dir_end()


func _compile(path):

	var script

	if path.ends_with(".timf"):
		script = "timfpy.py"
	else:
		script = "tiafpy.py"


	var py = ProjectSettings.globalize_path(
		"res://addons/terrence/py/" + script
	)

	var output_path = "res://export/%s.h" % path.get_file().get_basename()

	var output = []

	OS.execute(
		"python",
		[
			py,
			ProjectSettings.globalize_path(path),
			ProjectSettings.globalize_path(output_path)
		],
		output,
		true
	)
