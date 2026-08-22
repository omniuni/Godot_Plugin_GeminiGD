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
	_cleanup_settings()
	
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
	
	# Model Selection
	var setting_model = "gemini_gd/gemini_configuration/model"
	if not ProjectSettings.has_setting(setting_model):
		ProjectSettings.set_setting(setting_model, "gemini-3.5-flash-lite")
		ProjectSettings.set_initial_value(setting_model, "gemini-3.5-flash-lite")
		ProjectSettings.add_property_info({
			"name": setting_model,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "gemini-3.1-flash-lite,gemini-3.5-flash-lite,gemini-3.7-flash"
		})
	ProjectSettings.set_as_basic(setting_model, true)

	# Thinking Level
	var setting_thinking = "gemini_gd/gemini_configuration/thinking_level"
	if not ProjectSettings.has_setting(setting_thinking):
		ProjectSettings.set_setting(setting_thinking, "LOW")
		ProjectSettings.set_initial_value(setting_thinking, "LOW")
		ProjectSettings.add_property_info({
			"name": setting_thinking,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "MINIMAL,LOW,MEDIUM,HIGH"
		})
	ProjectSettings.set_as_basic(setting_thinking, true)

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

	# Max Dynamic Context
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
	
	# Debugging - Behavior Debugging
	var setting_behavior_debug = "gemini_gd/debugging/behavior_debugging"
	if not ProjectSettings.has_setting(setting_behavior_debug):
		ProjectSettings.set_setting(setting_behavior_debug, false)
		ProjectSettings.set_initial_value(setting_behavior_debug, false)
		ProjectSettings.add_property_info({
			"name": setting_behavior_debug,
			"type": TYPE_BOOL
		})
	ProjectSettings.set_as_basic(setting_behavior_debug, false)

	# Debugging - Request Debugging
	var setting_request_debug = "gemini_gd/debugging/request_debugging"
	if not ProjectSettings.has_setting(setting_request_debug):
		ProjectSettings.set_setting(setting_request_debug, false)
		ProjectSettings.set_initial_value(setting_request_debug, false)
		ProjectSettings.add_property_info({
			"name": setting_request_debug,
			"type": TYPE_BOOL
		})
	ProjectSettings.set_as_basic(setting_request_debug, false)

	# Advanced - Treat Addons as Project Files
	var setting_treat_addons = "gemini_gd/advanced/treat_addons_as_project"
	if not ProjectSettings.has_setting(setting_treat_addons):
		ProjectSettings.set_setting(setting_treat_addons, false)
		ProjectSettings.set_initial_value(setting_treat_addons, false)
		ProjectSettings.add_property_info({
			"name": setting_treat_addons,
			"type": TYPE_BOOL
		})
	ProjectSettings.set_as_basic(setting_treat_addons, false)

	# Tools - Allow Tool Use
	var setting_allow_tools = "gemini_gd/tools/allow_tool_use"
	if not ProjectSettings.has_setting(setting_allow_tools):
		ProjectSettings.set_setting(setting_allow_tools, true)
		ProjectSettings.set_initial_value(setting_allow_tools, true)
		ProjectSettings.add_property_info({
			"name": setting_allow_tools,
			"type": TYPE_BOOL
		})
	ProjectSettings.set_as_basic(setting_allow_tools, true)

	# Tools - Tool Use Allowance
	var setting_tool_allowance = "gemini_gd/tools/tool_use_allowance"
	if not ProjectSettings.has_setting(setting_tool_allowance):
		ProjectSettings.set_setting(setting_tool_allowance, 30)
		ProjectSettings.set_initial_value(setting_tool_allowance, 30)
		ProjectSettings.add_property_info({
			"name": setting_tool_allowance,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "1,100"
		})
	ProjectSettings.set_as_basic(setting_tool_allowance, true)

	# Tools - Project Structure Tool Toggle
	var setting_tool_proj_struct = "gemini_gd/tools/enable_tool_project_structure"
	if not ProjectSettings.has_setting(setting_tool_proj_struct):
		ProjectSettings.set_setting(setting_tool_proj_struct, true)
		ProjectSettings.set_initial_value(setting_tool_proj_struct, true)
		ProjectSettings.add_property_info({
			"name": setting_tool_proj_struct,
			"type": TYPE_BOOL
		})
	ProjectSettings.set_as_basic(setting_tool_proj_struct, true)

	# Tools - Syntax & Lint Checking Tool Toggle
	var setting_tool_check_syntax = "gemini_gd/tools/enable_tool_check_syntax"
	if not ProjectSettings.has_setting(setting_tool_check_syntax):
		ProjectSettings.set_setting(setting_tool_check_syntax, true)
		ProjectSettings.set_initial_value(setting_tool_check_syntax, true)
		ProjectSettings.add_property_info({
			"name": setting_tool_check_syntax,
			"type": TYPE_BOOL
		})
	ProjectSettings.set_as_basic(setting_tool_check_syntax, true)

	# Tools - Addons Directory Tool Toggle
	var setting_tool_addons_dir = "gemini_gd/tools/enable_tool_addons_directory"
	if not ProjectSettings.has_setting(setting_tool_addons_dir):
		ProjectSettings.set_setting(setting_tool_addons_dir, true)
		ProjectSettings.set_initial_value(setting_tool_addons_dir, true)
		ProjectSettings.add_property_info({
			"name": setting_tool_addons_dir,
			"type": TYPE_BOOL
		})
	ProjectSettings.set_as_basic(setting_tool_addons_dir, true)
	
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

func _cleanup_settings() -> void:
	var active_settings = [
		"gemini_gd/gemini_configuration/api_key",
		"gemini_gd/gemini_configuration/model",
		"gemini_gd/gemini_configuration/thinking_level",
		"gemini_gd/gemini_configuration/max_history",
		"gemini_gd/gemini_configuration/max_dynamic_context",
		"gemini_gd/debugging/behavior_debugging",
		"gemini_gd/debugging/request_debugging",
		"gemini_gd/advanced/treat_addons_as_project",
		"gemini_gd/tools/allow_tool_use",
		"gemini_gd/tools/tool_use_allowance",
		"gemini_gd/tools/enable_tool_project_structure",
		"gemini_gd/tools/enable_tool_check_syntax",
		"gemini_gd/tools/enable_tool_addons_directory"
	]
	var changed = false
	for prop in ProjectSettings.get_property_list():
		var prop_name: String = prop["name"]
		if prop_name.begins_with("gemini_gd/") and not prop_name in active_settings:
			ProjectSettings.clear(prop_name)
			changed = true
	if changed:
		ProjectSettings.save()

func _explain_pressed(script: Script) -> void:
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
