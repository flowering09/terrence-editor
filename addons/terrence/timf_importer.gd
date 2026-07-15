@tool
extends EditorImportPlugin


func _get_importer_name():
	return "terrence.timf"


func _get_visible_name():
	return "Terrence Mesh"


func _get_recognized_extensions():
	return PackedStringArray(["timf"])


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "ArrayMesh"


func _get_preset_count():
	return 0


func _get_import_options(path, preset_index):
	return []


func _get_priority():
	return 1.0


func _get_import_order():
	return 0


func _import(
		source_file,
		save_path,
		options,
		platform_variants,
		gen_files):

	var file = FileAccess.open(source_file, FileAccess.READ)

	if file == null:
		return ERR_CANT_OPEN


	#
	# Header
	#

	var magic = file.get_buffer(4).get_string_from_ascii()

	if magic != "TIMF":
		push_error("Invalid TIMF")
		return ERR_FILE_CORRUPT


	var version = file.get_32()

	if version != 1:
		push_error("Unsupported TIMF version")
		return ERR_FILE_CORRUPT


	var vertex_count = file.get_32()
	var index_count = file.get_32()


	#
	# Arrays
	#

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()


	#
	# Vertices
	#

	for i in vertex_count:

		var x = file.get_float()
		var y = file.get_float()
		var z = file.get_float()

		var nx = file.get_float()
		var ny = file.get_float()
		var nz = file.get_float()

		var u = file.get_float()
		var v = file.get_float()

		var r = file.get_8()
		var g = file.get_8()
		var b = file.get_8()
		var a = file.get_8()

		vertices.push_back(Vector3(x, y, z))
		normals.push_back(Vector3(nx, ny, nz))
		uvs.push_back(Vector2(u, v))

		colors.push_back(Color(
			r / 255.0,
			g / 255.0,
			b / 255.0,
			a / 255.0
		))


	#
	# Indices
	#

	for i in index_count:
		indices.push_back(file.get_16())


	#
	# Build mesh
	#

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh = MeshTIMF.new()

	mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		arrays
	)
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mesh.surface_set_material(0, material)


	return ResourceSaver.save(
		mesh,
		"%s.%s" % [
			save_path,
			_get_save_extension()
		]
	)
