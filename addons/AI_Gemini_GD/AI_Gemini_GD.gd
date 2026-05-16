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
	
	# API Key
	var setting_name = "gemini_gd/gemini_configuration/api_key"
	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, "")
		ProjectSettings.set_initial_value(setting_name, "")
		ProjectSettings.add_property_info({
			"name": setting_name,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_PASSWORD
		})
	ProjectSettings.set_as_basic(setting_name, true)
	
	# Max History
	var setting_history = "gemini_gd/gemini_configuration/max_history"
	if not ProjectSettings.has_setting(setting_history):
		ProjectSettings.set_setting(setting_history, 10)
		ProjectSettings.set_initial_value(setting_history, 10)
		ProjectSettings.add_property_info({
			"name": setting_history,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,30"
		})
	ProjectSettings.set_as_basic(setting_history, true)

	# Max Dynamic Context (Not used yet, indicates the maximum additional unopened files to include)
	var setting_dynamic_context = "gemini_gd/gemini_configuration/max_dynamic_context"
	if not ProjectSettings.has_setting(setting_dynamic_context):
		ProjectSettings.set_setting(setting_dynamic_context, 5)
		ProjectSettings.set_initial_value(setting_dynamic_context, 5)
		ProjectSettings.add_property_info({
			"name": setting_dynamic_context,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,20"
		})
	ProjectSettings.set_as_basic(setting_dynamic_context, true)
	
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
		var tab_chat: UiTabChat = dock.get_node("TabContainer/PanelChat/UiTabChat")
		tab_chat.send_now("Explain the following script: " + script.resource_path)
	pass

func _explain_func_pressed(script: Script, function: String) -> void:
	if script:
		var dock = scn_geminigd_dock.get_child(0)
		var tab_chat: UiTabChat = dock.get_node("TabContainer/PanelChat/UiTabChat")
		tab_chat.send_now("Explain the function '" + function + "' in the following script: " + script.resource_path)
	pass

func _exit_tree() -> void:
	remove_context_menu_plugin(context_menu_plugin)
	remove_dock(scn_geminigd_dock)
	scn_geminigd_dock.queue_free()
	pass
