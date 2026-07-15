@tool
extends Node
class_name Thing

@export var scrName = "Thing"
@export var visible = true

func terrence_type():
	return scrName


func export_data():
	return {}
