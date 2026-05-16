@tool
extends Control
class_name UiResponse

@onready var container: VBoxContainer = $VBoxContainer

func set_responses(content_array: Array):
	var prev_item_type: String = ""
	for item in content_array:
		var type = item.get("response_content_type", "text")
		var value = item.get("response_content_value", "-")
		var original_file = item.get("code_original_file", "")
		var code_original = item.get("code_original_reference", "")
		match type:
			"header":
				var ui_header: UiHeader = load("res://addons/AI_Gemini_GD/ui/ui_header.tscn").instantiate()
				container.add_child(ui_header)
				ui_header.set_value(value)
			"text":
				var ui_text: UiText = load("res://addons/AI_Gemini_GD/ui/ui_text.tscn").instantiate()
				container.add_child(ui_text)
				ui_text.set_value(value)
			"list_item_bullet":
				var ui_text: UiText = load("res://addons/AI_Gemini_GD/ui/ui_text.tscn").instantiate()
				container.add_child(ui_text)
				ui_text.set_value(value)
			"list_item_numeric":
				var ui_text: UiText = load("res://addons/AI_Gemini_GD/ui/ui_text.tscn").instantiate()
				container.add_child(ui_text)
				ui_text.set_value(value)
			"code":
				var ui_code: UiCode = load("res://addons/AI_Gemini_GD/ui/ui_code.tscn").instantiate()
				container.add_child(ui_code)
				ui_code.set_value(value, original_file, "")
			"code_edit":
				var ui_code: UiCode = load("res://addons/AI_Gemini_GD/ui/ui_code.tscn").instantiate()
				container.add_child(ui_code)
				ui_code.set_value(value, original_file, code_original)
			"resource_reference":
				var ui_ref: UiReference = load("res://addons/AI_Gemini_GD/ui/ui_reference.tscn").instantiate()
				container.add_child(ui_ref)
				ui_ref.set_value(value)
				ui_ref.set_resource(original_file, code_original)
	pass

func get_response() -> String:
	var full_text = ""
	for child in container.get_children():
		if child.has_method("get_value"):
			full_text += child.get_value() + "\n\n"
	return full_text
