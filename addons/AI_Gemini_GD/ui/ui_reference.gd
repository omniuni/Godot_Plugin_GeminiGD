@tool
extends MarginContainer
class_name UiReference

@onready var label: Label = $VBoxContainer/Label
@onready var btn_open: Button = $VBoxContainer/Button

func set_value(title: String):
	label.text = title
	btn_open.hide()
	
func set_resource(path: String, line: String = ""): 
	label.text = "Reference: " + path.get_file() + ((" (Line " + line + ")") if line.is_valid_int() else "")
	btn_open.text = path
	btn_open.show()
	btn_open.pressed.connect(_on_button_pressed.bind(path, line))

func _on_button_pressed(path: String, line: String):
	if FileAccess.file_exists(path):
		var res = load(path)
		if res:
			EditorInterface.edit_resource(res)
			if line.is_valid_int():
				var script_editor = EditorInterface.get_script_editor()
				var current_editor = script_editor.get_current_editor()
				if current_editor and current_editor.get_base_editor():
					var code_edit: CodeEdit = current_editor.get_base_editor()
					code_edit.set_line_as_first_visible(int(line) - 1)
		else:
			EditorInterface.select_file(path)
