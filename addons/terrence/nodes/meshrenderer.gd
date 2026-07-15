@tool
extends MeshInstance3D
class_name MeshRendererTE

@export var timf_mesh: MeshTIMF:
	set(value):
		timf_mesh = value
		mesh = value


func terrence_type():
	return "MeshRenderer"


func export_data():
	pass
