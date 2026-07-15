@tool
extends EditorImportPlugin


func _get_importer_name():
	return "terrence.tiaf"


func _get_visible_name():
	return "Terrence Animated Mesh"


func _get_recognized_extensions():
	return PackedStringArray(["tiaf"])


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "ArrayMesh"


func _get_preset_count():
	return 0


func _get_import_options(_path, _preset_index):
	return []


func _get_priority():
	return 1.0


func _get_import_order():
	return 0


func _import(
	source_file,
	save_path,
	_options,
	_platform_variants,
	_gen_files
):

	var file = FileAccess.open(source_file, FileAccess.READ)

	if file == null:
		return ERR_CANT_OPEN

	#
	# Header
	#

	var magic = file.get_buffer(4).get_string_from_ascii()

	if magic != "TIAF":
		push_error("Invalid TIAF")
		return ERR_FILE_CORRUPT

	var version = file.get_32()

	if version != 1:
		push_error("Unsupported TIAF version")
		return ERR_FILE_CORRUPT

	var frame_count = file.get_32()
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
	# Read ONLY the first frame
	#

	for i in range(vertex_count):

		vertices.push_back(Vector3(
			file.get_float(),
			file.get_float(),
			file.get_float()
		))

		normals.push_back(Vector3(
			file.get_float(),
			file.get_float(),
			file.get_float()
		))

		uvs.push_back(Vector2(
			file.get_float(),
			file.get_float()
		))

		colors.push_back(Color(
			file.get_8() / 255.0,
			file.get_8() / 255.0,
			file.get_8() / 255.0,
			file.get_8() / 255.0
		))

	#
	# Skip remaining frames
	#

	if frame_count > 1:

		var vertex_size = 36 # 8 floats + 4 bytes

		file.seek(
			file.get_position() +
			(frame_count - 1) * vertex_count * vertex_size
		)

	#
	# Shared indices
	#

	for i in range(index_count):
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

	var mesh = MeshTIAF.new()

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
