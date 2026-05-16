extends EditorContextMenuPlugin

var script_callback: Callable
var func_callback: Callable

func _popup_menu(paths: PackedStringArray):
	add_context_menu_item("Gemini GD: Explain Script", _on_explain_script_pressed)
	add_context_menu_item("Gemini GD: Explain Function", _on_explain_script_func_pressed)

func set_script_callback(cb: Callable):
	script_callback = cb
	
func set_script_func_callback(cb: Callable):
	func_callback = cb

func _on_explain_script_pressed(code_edit: CodeEdit):
	script_callback.call(EditorInterface.get_script_editor().get_current_script())

func _on_explain_script_func_pressed(code_edit: CodeEdit):
	var line = code_edit.get_caret_line()
	var script = EditorInterface.get_script_editor().get_current_script()
	if script:
		var source = script.source_code.split("\n")
		var func_name = ""
		for i in range(line, -1, -1):
			var line_text = source[i].strip_edges()
			if line_text.begins_with("func "):
				func_name = line_text.split("(")[0].replace("func ", "").strip_edges()
				break
		func_callback.call(script, func_name)
	pass
