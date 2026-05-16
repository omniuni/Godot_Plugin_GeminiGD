@tool
extends MarginContainer
class_name UiCode

@onready var code_edit: CodeEdit = $VBoxContainer/MarginContainer/CodeEdit
@onready var label_file: Label = $VBoxContainer/HBoxContainer/LabelFile
@onready var label_file_container: HBoxContainer = $VBoxContainer/HBoxContainer
@onready var btn_apply: Button = $VBoxContainer/HBoxContainer/ButtonApply
@onready var btn_copy: Button = $VBoxContainer/MarginContainer/ButtonCopy

var _file: String = ""
var _code: String = ""
var _code_original: String = ""

func _ready() -> void:
	btn_copy.hide()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	code_edit.add_gutter(0)
	code_edit.set_gutter_type(0, CodeEdit.GUTTER_TYPE_STRING)

func get_value() -> String:
	return code_edit.text

func _on_mouse_entered() -> void:
	btn_copy.show()

func _on_mouse_exited() -> void:
	btn_copy.hide()

func set_value(code: String, file: String, code_original: String):
	_code = code
	_file = file
	_code_original = code_original
	
	if not file.is_empty():
		label_file.text = file
		label_file.show()
	else:
		label_file.hide()
	
	code_edit.text = code
	
	var can_apply = false
	var target_line = -1
	if not code_original.is_empty() and FileAccess.file_exists(file):
		var content = FileAccess.get_file_as_string(file)
		if code_original.is_valid_int():
			target_line = int(code_original)
			can_apply = true
		elif content.contains(code_original):
			target_line = content.left(content.find(code_original)).count("\n")+1
			can_apply = true
	
	if can_apply:
		code_edit.set_gutter_width(0, 40)
		btn_apply.show()
		var code_lines = code.split("\n")
		for i in range(code_lines.size()):
			code_edit.set_line_gutter_text(i, 0, str(target_line + i))
	else:
		btn_apply.hide()
	pass

func _on_button_copy_pressed() -> void:
	DisplayServer.clipboard_set(_code)
	btn_copy.text = "Copied!"
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(btn_copy):
		btn_copy.text = "Copy"

func _on_button_apply_pressed() -> void:
	if not FileAccess.file_exists(_file):
		printerr("File does not exist: " + _file)
		return

	if _file.ends_with(".gd"):
		var script = load(_file)
		if not script:
			printerr("Failed to load script: " + _file)
			return
		EditorInterface.edit_resource(script)
		var script_editor = EditorInterface.get_script_editor()
		var code_edit: CodeEdit = script_editor.get_current_editor().get_base_editor()
		var text = code_edit.text
		
		if _code_original.is_valid_int():
			var lines = text.split("\n")
			var line_number = int(_code_original)
			lines.insert(line_number, _code)
			code_edit.text = "\n".join(lines)
			code_edit.set_line_as_first_visible(line_number)
			print("Code successfully inserted at line " + str(line_number) + ".")
		else:
			var index = text.find(_code_original)
			if index != -1:
				var new_text = text.substr(0, index) + _code + text.substr(index + _code_original.length())
				code_edit.text = new_text
				var line_number = new_text.left(index).count("\n")
				code_edit.set_line_as_first_visible(line_number)
				print("Code successfully replaced on line " + str(line_number) + ".")
			else:
				printerr("Could not find original code block to replace.")
	elif _file.ends_with(".tscn"):
		var file = FileAccess.open(_file, FileAccess.READ_WRITE)
		if file:
			var content = file.get_as_text()
			var index = content.find(_code_original)
			if index != -1:
				var new_content = content.substr(0, index) + _code + content.substr(index + _code_original.length())
				file.store_string(new_content)
				file.close()
				EditorInterface.get_resource_filesystem().scan()
				print("Scene code successfully replaced. Reload the scene if necessary.")
