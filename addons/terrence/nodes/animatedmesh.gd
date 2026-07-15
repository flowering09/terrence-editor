@tool
extends MeshInstance3D
class_name AnimatedMeshTE

@export var tiaf_mesh: MeshTIAF:
	set(value):
		tiaf_mesh = value
		mesh = value


func terrence_type():
	return "AnimatedMesh"


func export_data():
	pass
