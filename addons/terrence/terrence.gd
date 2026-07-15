@tool
extends EditorPlugin

var mesh_importer
var anim_importer
var terrence_button
var exported_scenes = []
var scene_file_dialog

func _enter_tree():

	mesh_importer = preload("res://addons/terrence/timf_importer.gd").new()
	anim_importer = preload("res://addons/terrence/tiaf_importer.gd").new()

	add_import_plugin(mesh_importer)
	add_import_plugin(anim_importer)

	terrence_button = Button.new()
	terrence_button.text = "Terrence"
	terrence_button.pressed.connect(_show_terrence_menu)

	add_control_to_container(
		CONTAINER_TOOLBAR,
		terrence_button
	)
	
	add_custom_type(
		"Thing",
		"Node",
		preload("res://addons/terrence/nodes/thing.gd"),
		null
	)

	add_custom_type(
		"Thing2D",
		"Node2D",
		preload("res://addons/terrence/nodes/thing2d.gd"),
		null
	)

	add_custom_type(
		"Thing3D",
		"Node3D",
		preload("res://addons/terrence/nodes/thing3d.gd"),
		null
	)

	add_custom_type(
		"MeshRendererTE",
		"MeshInstance3D",
		preload("res://addons/terrence/nodes/meshrenderer.gd"),
		null
	)

	add_custom_type(
		"AnimatedMeshTE",
		"MeshInstance3D",
		preload("res://addons/terrence/nodes/animatedmesh.gd"),
		null
	)
	
	scene_file_dialog = EditorFileDialog.new()

	scene_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	scene_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	scene_file_dialog.title = "Create Terrence Scene"

	scene_file_dialog.add_filter("*.tscn ; Terrence Scene")

	scene_file_dialog.file_selected.connect(_create_terrence_scene)

	add_child(scene_file_dialog)

func _exit_tree():

	remove_import_plugin(mesh_importer)
	remove_import_plugin(anim_importer)
	
	remove_custom_type("Thing")
	remove_custom_type("Thing2D")
	remove_custom_type("Thing3D")
	remove_custom_type("MeshRendererTE")
	remove_custom_type("AnimatedMeshTE")
	
	if terrence_button:
		remove_control_from_container(
			CONTAINER_TOOLBAR,
			terrence_button
		)

		terrence_button.queue_free()
	
func _show_terrence_menu():

	var menu = PopupMenu.new()

	menu.add_item("Build Assets", 0)
	menu.add_item("Build", 1)
	menu.add_item("Build and Run", 2)
	menu.add_item("Create Scene", 3)
	menu.add_item("Run", 4)

	menu.id_pressed.connect(_terrence_action)

	add_child(menu)

	menu.popup(Rect2(
		terrence_button.global_position + Vector2(0, terrence_button.size.y),
		Vector2.ZERO
	))
	
func _create_terrence_scene(path:String):

	var template_path = "res://addons/terrence/templateScene.tscn"

	var scene = load(template_path)

	if scene == null:
		push_error("Terrence template scene not found")
		return

	var instance = scene.instantiate()

	var packed = PackedScene.new()
	packed.pack(instance)

	instance.queue_free()

	if not path.ends_with(".tscn"):
		path += ".tscn"

	var result = ResourceSaver.save(packed, path)

	if result == OK:
		print("Created Terrence scene:", path)
		EditorInterface.open_scene_from_path(path)
	else:
		push_error("Failed to save Terrence scene")
		
		
func _build_and_run():

	print("=== Build and Run ===")

	_build_all()
	_run()

	
func _run():
	var dol_path = ProjectSettings.globalize_path(
		"res://engine/engine.dol"
	)

	if not FileAccess.file_exists(
		"res://engine/engine.dol"
	):
		push_error("DOL not found: " + dol_path)
		return

	var output = []

	OS.execute(
		"dolphin.exe",
		[
			dol_path
		],
		output,
		true
	)

	print("\n".join(output))
	
func _show_create_scene_picker():

	scene_file_dialog.current_path = "res://NewTerrenceScene.tscn"
	scene_file_dialog.popup_centered_ratio()
	
func _terrence_action(id):

	match id:

		0:
			_build_assets()

		1:
			_build_all()
		
		2:
			_build_and_run()
			
		3:
			_show_create_scene_picker()
		
		4:
			_run()


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

	var output_path = "res://engine/source/game/%s.h" % path.get_file().get_basename()

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
	
	
func _export_scene(scene):

	if scene == null:
		return

	if not scene.has_method("terrence_type"):
		print("Not a Terrence scene")
		return

	var func_name = scene.name.to_snake_case()

	var function = ""
	function += "static void build_%s(Thing* root)\n{\n" % func_name

	# Make the scene root available as a variable
	function += "    Thing* %s = root;\n\n" % scene.name

	for child in scene.get_children():
		function += _export_node(child, "    ")

	function += "}\n\n"

	exported_scenes.append({
		"name": scene.name,
		"func": func_name,
		"code": function
	})

	print("Exported scene:", scene.name)
	
func _write_scenes_header():

	var output = "#pragma once\n\n"
	output += "#include \"terrence.h\"\n"
	output += "#include <map>\n"
	output += "#include <string>\n\n"

	output += "struct SceneDefinition {\n"
	output += "    const char* name;\n"
	output += "    void (*build)(Thing* root);\n"
	output += "};\n\n"


	for scene in exported_scenes:
		output += scene.code


	output += "static std::map<std::string, SceneDefinition> scenes = {\n"

	for scene in exported_scenes:
		output += "    { \"%s\", { \"%s\", build_%s } },\n" % [
			scene.name,
			scene.name,
			scene.func
		]

	output += "};\n"


	var file = FileAccess.open(
		"res://engine/source/game/scenes.h",
		FileAccess.WRITE
	)

	file.store_string(output)
	
func _get_terrence_type(node):

	if node.has_method("terrence_type"):
		return node.terrence_type()

	return null
	
func _export_node(node, indent):

	if not node.has_method("terrence_type"):
		return ""

	var type = node.terrence_type()
	var out = ""

	var var_name = node.name

	# Create
	out += "%s%s* %s = dynamic_cast<%s*>(ThingFactory::create(\"%s\"));\n" % [
		indent,
		type,
		var_name,
		type,
		type
	]
	
	out += "%s%s->setVisible(%s);\n"%[indent, var_name, str(node.get("visible"))]


	# Position
	if node is Thing3D or type in ["MeshRenderer", "AnimatedMesh"]:
		out += "%s%s->setPosition(%ff, %ff, %ff);\n" % [
			indent,
			var_name,
			node.position.x,
			node.position.y,
			node.position.z
		]
		
		out += "%s%s->setRotation(%ff, %ff, %ff);\n" % [
			indent,
			var_name,
			rad_to_deg(node.rotation.x),
			rad_to_deg(node.rotation.y),
			rad_to_deg(node.rotation.z)
		]
		
		out += "%s%s->setScale(%ff, %ff, %ff);\n" % [
			indent,
			var_name,
			node.scale.x,
			node.scale.y,
			node.scale.z
		]


	elif node is Thing2D:
		out += "%s%s->setPosition(%ff, %ff);\n" % [
			indent,
			var_name,
			node.position.x,
			node.position.y
		]


	# Special data
	match type:

		"MeshRenderer":
			out += _export_mesh_load(node, indent, var_name)

		"AnimatedMesh":
			out += _export_animation_load(node, indent, var_name)


	# Parent
	if node.get_parent() and node.get_parent().has_method("terrence_type"):
		out += "%s%s->addChild(%s);\n" % [
			indent,
			node.get_parent().name,
			var_name
		]


	for child in node.get_children():
		out += _export_node(child, indent)

	return out
	
func _export_mesh_load(node, indent, var_name):
	return """
	%sLoadable %s_load;
	%s%s_load.mesh = &%s_mesh;
	%s%s->load(%s_load);
	""" % [
		indent,
		var_name,
		indent,
		var_name,
		node.mesh.resource_path.get_file().get_basename(),
		indent,
		var_name,
		var_name
	]
	
func _export_animation_load(node, indent, var_name):

	return """
	%sLoadable %s_load;
	%s%s_load.animatedMesh = &%s_animation;
	%s%s->load(%s_load);
	""" % [
		indent,
		var_name,
		indent,
		var_name,
		node.mesh.resource_path.get_file().get_basename(),
		indent,
		var_name,
		var_name
	]
	
func _build_base_umbrella():

	var output = "#pragma once\n\n"

	var dir = DirAccess.open(
		"res://engine/source"
	)

	if dir == null:
		return

	dir.list_dir_begin()

	while true:

		var file = dir.get_next()

		if file == "":
			break

		if file.ends_with(".h"):
			# skip generated/game headers
			if file in [
				"terrence.h",
				"scenes.h"
			]:
				continue

			output += '#include "../%s"\n' % file

	dir.list_dir_end()


	var f = FileAccess.open(
		"res://engine/source/game/terrence_base.h",
		FileAccess.WRITE
	)

	f.store_string(output)
	
func _build_umbrella():

	var output = "#pragma once\n\n"
	
	var dir = DirAccess.open(
		"res://engine/source"
	)

	dir.list_dir_begin()

	while true:

		var file = dir.get_next()

		if file == "":
			break

		if file.ends_with(".h"):
			output += '#include "../%s"\n' % file

	dir.list_dir_end()
	
	dir = DirAccess.open(
		"res://engine/source/game/include"
	)

	dir.list_dir_begin()

	while true:

		var file = dir.get_next()

		if file == "":
			break

		if file.ends_with(".h") and file != "_HaxeUtils.h":
			output += '#include "include/%s"\n' % file

	dir.list_dir_end()
	
	dir = DirAccess.open(
		"res://engine/source/game"
	)

	dir.list_dir_begin()

	while true:

		var file = dir.get_next()

		if file == "":
			break

		if file.ends_with(".h") and file != "terrence.h" and file != "scenes.h":
			output += '#include "%s"\n' % file

	dir.list_dir_end()

	output += '#include "scenes.h"\n'
	var f = FileAccess.open(
		"res://engine/source/game/terrence.h",
		FileAccess.WRITE
	)

	f.store_string(output)
	
func _export_all_scenes():

	var scenes_dir = DirAccess.open("res://")

	if scenes_dir == null:
		return

	_scan_scenes("res://")


func _scan_scenes(path):

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
			_scan_scenes(full)

		elif file.ends_with(".tscn"):

			_export_scene_file(full)

	dir.list_dir_end()


func _export_scene_file(path):

	var packed = load(path)

	if packed == null:
		return

	var scene = packed.instantiate()

	if not scene is Thing:
		scene.queue_free()
		return

	print("Exporting Terrence scene:", path)

	var output_name = path.get_file().get_basename()

	_export_scene(scene)

	scene.queue_free()
	
func _write_thing_registrations():

	var output = ""
	
	output += '#include "terrence.h"\n\n'


	var dir = DirAccess.open(
    	"res://engine/source/game/include"
	)

	if dir == null:
		return

	var things = []

	dir.list_dir_begin()

	while true:

		var file = dir.get_next()

		if file == "":
			break

		if file.ends_with(".h") && file != "_HaxeUtils.h":
			var thing_name = file.trim_suffix(".h")
			things.append(thing_name)

	dir.list_dir_end()


	output += "\n"


	for thing in things:
		output += 'REGISTER_THING(%s, "%s");\n' % [
			thing,
			thing
		]


	var f = FileAccess.open(
		"res://engine/source/game/thing_registrations.cpp",
		FileAccess.WRITE
	)

	f.store_string(output)
	
func _clean_generated_main():

	var files = [
		"res://engine/source/game/include/Main.h",
		"res://engine/source/game/src/Main.cpp",
		"res://engine/source/game/src/_main_.cpp"
	]

	for file in files:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(
				ProjectSettings.globalize_path(file)
			)
		
func fix_directory(path:String, src:bool=false):
	var dir = DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file = dir.get_next()

	while file != "":
		var full_path = path + "/" + file

		if dir.current_is_dir():
			if file != "." and file != "..":
				fix_directory(full_path)

		elif file.ends_with(".h") || file.ends_with(".cpp"):
			fix_file(full_path, src)

		file = dir.get_next()

	dir.list_dir_end()


func fix_file(path:String, src:bool = false):
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return

	var text = f.get_as_text()
	f.close()
	

	if "double" in text:
		text = text.replace("double", "float")
				
		if !src:
			text = '#pragma once\n\n#include "../terrence_base.h"\n\n' + text
			
		f = FileAccess.open(path, FileAccess.WRITE)
		f.store_string(text)
		f.close()

		print("Fixed: ", path)	
	
	if ('#include "' in text) && src:
		text = text.replace('#include "', '#include "../include/')

		f = FileAccess.open(path, FileAccess.WRITE)
		f.store_string(text)
		f.close()

		print("Fixed: ", path)	
		
func _build_haxe():
	var output = []

	var game_path = ProjectSettings.globalize_path("res://game")

	var result = OS.execute(
		"cmd",
		[
			"/c",
			"cd /d \"%s\" && haxe build.hxml" % game_path
		],
		output,
		true
	)

	print("\n".join(output))

	if result != 0:
		push_error("Haxe build failed")
		
		
func _msys_path(win_path:String):

	var home = OS.get_environment("USERPROFILE")
	home = home.replace("\\", "/")

	win_path = win_path.replace("\\", "/")

	if win_path.begins_with(home):
		return "/home/" + home.get_file() + win_path.substr(home.length())

	return win_path
	
func _build_wii():
	
	var win_path = ProjectSettings.globalize_path("res://engine")
	var msys_path = _msys_path(
		win_path
	)

	var output = []

	var result = OS.execute(
		"C:/devkitpro/msys2/usr/bin/bash.exe",
		[
			"-lc",
			"cd '%s' && make" % msys_path
		],
		output,
		true
	)

	print("\n".join(output))
	print("Exit:", result)
	
func _build_all():

	print("=== Building Terrence ===")

	_build_haxe()
	
	_build_assets()
	
	exported_scenes.clear()
	
	_export_all_scenes()
	
	_clean_generated_main()
	
	_build_base_umbrella()
	_build_umbrella()

	_write_scenes_header()
	
	
	_write_thing_registrations()
	
	fix_directory("res://engine/source/game/include")
	fix_directory("res://engine/source/game/src", true)
	
	_build_wii()
	
	print("=== Done ===")
