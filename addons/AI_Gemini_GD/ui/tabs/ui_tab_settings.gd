@tool
extends Control
class_name UiTabSettings

const GeminiToolManagerScript = preload("res://addons/AI_Gemini_GD/tools/gemini_tool_manager.gd")

const SETTING_MODEL = "gemini_gd/gemini_configuration/model"
const SETTING_THINKING_LEVEL = "gemini_gd/gemini_configuration/thinking_level"
const SETTING_MAX_HISTORY = "gemini_gd/gemini_configuration/max_history"
const SETTING_DYNAMIC_CONTEXT = "gemini_gd/gemini_configuration/max_dynamic_context"
const SETTING_ALLOW_TOOL_USE = "gemini_gd/tools/allow_tool_use"
const SETTING_TOOL_ALLOWANCE = "gemini_gd/tools/tool_use_allowance"

const MODELS = [
	{"id": "gemini-3.1-flash-lite", "label": "Gemini 3.1 Flash Lite"},
	{"id": "gemini-3.5-flash-lite", "label": "Gemini 3.5 Flash Lite"},
	{"id": "gemini-3.7-flash", "label": "Gemini 3.7 Flash"}
]

const THINKING_LEVELS = [
	{"id": "MINIMAL", "label": "Minimal"},
	{"id": "LOW", "label": "Low"},
	{"id": "MEDIUM", "label": "Medium"},
	{"id": "HIGH", "label": "High"}
]

@onready var option_button_model: OptionButton = $MarginContainer/ScrollContainer/VBoxContainer/GridContainer/OptionButtonModel
@onready var option_button_thinking_level: OptionButton = $MarginContainer/ScrollContainer/VBoxContainer/GridContainer/OptionButtonThinkingLevel
@onready var spin_box_max_history: SpinBox = $MarginContainer/ScrollContainer/VBoxContainer/GridContainer/SpinBoxMaxHistory
@onready var spin_box_dynamic_context: SpinBox = $MarginContainer/ScrollContainer/VBoxContainer/GridContainer/SpinBoxDynamicContext
@onready var check_box_allow_tools: CheckBox = $MarginContainer/ScrollContainer/VBoxContainer/FoldableContainerTools/MarginContainerTools/VBoxContainerTools/GridContainerTools/CheckBoxAllowTools
@onready var spin_box_tool_allowance: SpinBox = $MarginContainer/ScrollContainer/VBoxContainer/FoldableContainerTools/MarginContainerTools/VBoxContainerTools/GridContainerTools/SpinBoxToolAllowance
@onready var label_tools_active_value: Label = $MarginContainer/ScrollContainer/VBoxContainer/FoldableContainerTools/MarginContainerTools/VBoxContainerTools/GridContainerTools/LabelToolsActiveValue
@onready var button_open_settings: Button = $MarginContainer/ScrollContainer/VBoxContainer/FoldableContainerTools/MarginContainerTools/VBoxContainerTools/ButtonOpenSettings


func _ready() -> void:
	_setup_options()
	_update_values_from_settings()
	ProjectSettings.settings_changed.connect(_update_values_from_settings)


func _setup_options() -> void:
	if is_instance_valid(option_button_model):
		option_button_model.clear()
		for item in MODELS:
			option_button_model.add_item(item["label"])

	if is_instance_valid(option_button_thinking_level):
		option_button_thinking_level.clear()
		for item in THINKING_LEVELS:
			option_button_thinking_level.add_item(item["label"])


func _update_values_from_settings() -> void:
	if is_instance_valid(option_button_model):
		var current_model = ProjectSettings.get_setting(SETTING_MODEL, "gemini-3.5-flash-lite")
		for i in range(MODELS.size()):
			if MODELS[i]["id"] == current_model:
				if option_button_model.selected != i:
					option_button_model.select(i)
				break

	if is_instance_valid(option_button_thinking_level):
		var current_level = ProjectSettings.get_setting(SETTING_THINKING_LEVEL, "LOW")
		for i in range(THINKING_LEVELS.size()):
			if THINKING_LEVELS[i]["id"] == current_level:
				if option_button_thinking_level.selected != i:
					option_button_thinking_level.select(i)
				break

	if is_instance_valid(spin_box_max_history) and ProjectSettings.has_setting(SETTING_MAX_HISTORY):
		var history_val = ProjectSettings.get_setting(SETTING_MAX_HISTORY, 10)
		if spin_box_max_history.value != history_val:
			spin_box_max_history.set_value_no_signal(history_val)

	if is_instance_valid(spin_box_dynamic_context) and ProjectSettings.has_setting(SETTING_DYNAMIC_CONTEXT):
		var dynamic_context_val = ProjectSettings.get_setting(SETTING_DYNAMIC_CONTEXT, 5)
		if spin_box_dynamic_context.value != dynamic_context_val:
			spin_box_dynamic_context.set_value_no_signal(dynamic_context_val)

	if is_instance_valid(check_box_allow_tools) and ProjectSettings.has_setting(SETTING_ALLOW_TOOL_USE):
		var allow_tools_val = ProjectSettings.get_setting(SETTING_ALLOW_TOOL_USE, true)
		if check_box_allow_tools.button_pressed != allow_tools_val:
			check_box_allow_tools.set_pressed_no_signal(allow_tools_val)

	if is_instance_valid(spin_box_tool_allowance) and ProjectSettings.has_setting(SETTING_TOOL_ALLOWANCE):
		var allowance_val = ProjectSettings.get_setting(SETTING_TOOL_ALLOWANCE, 30)
		if spin_box_tool_allowance.value != allowance_val:
			spin_box_tool_allowance.set_value_no_signal(allowance_val)

	if is_instance_valid(label_tools_active_value):
		var counts = GeminiToolManagerScript.get_tool_counts()
		label_tools_active_value.text = str(counts["enabled"]) + " of " + str(counts["total"]) + " enabled"


func _on_option_button_model_item_selected(index: int) -> void:
	if index >= 0 and index < MODELS.size():
		var model_id = MODELS[index]["id"]
		if ProjectSettings.get_setting(SETTING_MODEL, "gemini-3.5-flash-lite") != model_id:
			ProjectSettings.set_setting(SETTING_MODEL, model_id)
			ProjectSettings.save()


func _on_option_button_thinking_level_item_selected(index: int) -> void:
	if index >= 0 and index < THINKING_LEVELS.size():
		var level_id = THINKING_LEVELS[index]["id"]
		if ProjectSettings.get_setting(SETTING_THINKING_LEVEL, "LOW") != level_id:
			ProjectSettings.set_setting(SETTING_THINKING_LEVEL, level_id)
			ProjectSettings.save()


func _on_spin_box_max_history_value_changed(val: float) -> void:
	var int_val = int(val)
	if ProjectSettings.get_setting(SETTING_MAX_HISTORY, 10) != int_val:
		ProjectSettings.set_setting(SETTING_MAX_HISTORY, int_val)
		ProjectSettings.save()


func _on_spin_box_dynamic_context_value_changed(val: float) -> void:
	var int_val = int(val)
	if ProjectSettings.get_setting(SETTING_DYNAMIC_CONTEXT, 5) != int_val:
		ProjectSettings.set_setting(SETTING_DYNAMIC_CONTEXT, int_val)
		ProjectSettings.save()


func _on_check_box_allow_tools_toggled(toggled_on: bool) -> void:
	if ProjectSettings.get_setting(SETTING_ALLOW_TOOL_USE, true) != toggled_on:
		ProjectSettings.set_setting(SETTING_ALLOW_TOOL_USE, toggled_on)
		ProjectSettings.save()


func _on_spin_box_tool_allowance_value_changed(val: float) -> void:
	var int_val = int(val)
	if ProjectSettings.get_setting(SETTING_TOOL_ALLOWANCE, 30) != int_val:
		ProjectSettings.set_setting(SETTING_TOOL_ALLOWANCE, int_val)
		ProjectSettings.save()


func _on_button_open_settings_pressed() -> void:
	if not Engine.is_editor_hint():
		return
	var base = EditorInterface.get_base_control()
	if base:
		var dialog = _find_project_settings_dialog(base)
		if dialog:
			dialog.popup_centered_ratio(0.7)


func _find_project_settings_dialog(node: Node) -> Window:
	if node is Window:
		if "project" in node.name.to_lower() and ("setting" in node.name.to_lower() or "setting" in node.title.to_lower()):
			return node
	for child in node.get_children():
		var res = _find_project_settings_dialog(child)
		if res:
			return res
	return null
