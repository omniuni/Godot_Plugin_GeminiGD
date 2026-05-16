@tool
extends Control
class_name UiRequest

@onready var container: VBoxContainer = $VBoxContainer

func set_request(request: String):
	var ui_header: UiHeader = load("res://addons/AI_Gemini_GD/ui/ui_header.tscn").instantiate()
	container.add_child(ui_header)
	ui_header.set_value(request)
	pass

func get_request() -> String:
	for child in container.get_children():
		if child is UiHeader:
			return child.label.text
	return ""
