@tool
extends EditorPlugin

var mesh_importer
var anim_importer

var exported_scenes = []

func _enter_tree():

	mesh_importer = preload("res://addons/terrence/timf_importer.gd").new()
	anim_importer = preload("res://addons/terrence/tiaf_importer.gd").new()

	add_import_plugin(mesh_importer)
	add_import_plugin(anim_importer)

	add_tool_menu_item(
		"Build Terrence Assets",
		Callable(self, "_build_assets")
	)
	
	add_tool_menu_item(
		"Build Terrence",
		Callable(self, "_build_all")
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
	
	add_custom_type(
		"ScriptedThing",
		"Node",
		preload("res://addons/terrence/nodes/scriptedThing.gd"),
		null
	)

func _exit_tree():

	remove_import_plugin(mesh_importer)
	remove_import_plugin(anim_importer)

	remove_tool_menu_item(
		"Build Terrence Assets"
	)
	
	remove_custom_type("Thing")
	remove_custom_type("Thing2D")
	remove_custom_type("Thing3D")
	remove_custom_type("MeshRendererTE")
	remove_custom_type("AnimatedMeshTE")
	remove_custom_type("ScriptedThing")
	
	remove_tool_menu_item(
		"Export Terrence Scene"
	)
	remove_tool_menu_item(
		"Build Terrence"
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

	var output_path = "res://terrence-wii/source/game/%s.h" % path.get_file().get_basename()

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
		"res://terrence-wii/source/game/scenes.h",
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


	# Position
	if node is Thing3D or type in ["MeshRenderer", "AnimatedMesh"]:
		out += "%s%s->setPosition(%ff, %ff, %ff);\n" % [
			indent,
			var_name,
			node.position.x,
			node.position.y,
			node.position.z
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
	
func _build_umbrella():

	var output = "#pragma once\n\n"

	var dir = DirAccess.open(
		"res://terrence-wii/source/game"
	)

	dir.list_dir_begin()

	while true:

		var file = dir.get_next()

		if file == "":
			break

		if file.ends_with(".h") and file != "terrence.h":
			output += '#include "%s"\n' % file

	dir.list_dir_end()

	var f = FileAccess.open(
		"res://terrence-wii/source/game/terrence.h",
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
	
func _build_all():

	print("=== Building Terrence ===")

	_build_assets()

	exported_scenes.clear()
	
	_export_all_scenes()

	_write_scenes_header()
	print("=== Done ===")
