@tool
extends EditorPlugin

var context_menu_plugin = preload("res://addons/AI_Gemini_GD/gdd_context_menu_scripts.gd").new()

var scn_geminigd_dock: EditorDock
var script_editor: ScriptEditor

func _enable_plugin() -> void:
	pass

func _disable_plugin() -> void:
	pass

func _enter_tree() -> void:
	if not ProjectSettings.has_setting("gemini_gd/api_key"):
		ProjectSettings.set_setting("gemini_gd/api_key", "")
		ProjectSettings.set_as_basic("gemini_gd/api_key", true)
		ProjectSettings.set_initial_value("gemini_gd/api_key", "")

	var dock_scene = preload("res://addons/AI_Gemini_GD/ui/main/GGD_Dock_Main.tscn").instantiate()
	scn_geminigd_dock = EditorDock.new()
	scn_geminigd_dock.add_child(dock_scene)
	scn_geminigd_dock.title = "Gemini GD"
	scn_geminigd_dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_BL
	scn_geminigd_dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING
	add_dock(scn_geminigd_dock)
	context_menu_plugin.set_script_callback(_explain_pressed)
	context_menu_plugin.set_script_func_callback(_explain_func_pressed)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, context_menu_plugin)
pass

func _explain_pressed(script: Script) -> void:
	print("Should Explain: "+script.resource_path)
	if script:
		var dock = scn_geminigd_dock.get_child(0)
		var text_edit: TextEdit = dock.get_node("TabContainer/PanelChat/VBoxContainer/VBoxContainer/TextEdit")
		text_edit.text = "Explain the following script: " + script.resource_path
		dock._on_button_send_pressed()
pass

func _explain_func_pressed(script: Script, function: String) -> void:
	if script:
		var dock = scn_geminigd_dock.get_child(0)
		var text_edit: TextEdit = dock.get_node("TabContainer/PanelChat/VBoxContainer/VBoxContainer/TextEdit")
		text_edit.text = "Explain the function '" + function + "' in the following script: " + script.resource_path
		dock._on_button_send_pressed()
pass

func _exit_tree() -> void:
	remove_context_menu_plugin(context_menu_plugin)
	remove_dock(scn_geminigd_dock)
	scn_geminigd_dock.queue_free()
