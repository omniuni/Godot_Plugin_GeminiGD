@tool
extends Control

var instance_script_editor: ScriptEditor
var gemini_client: GeminiClient
@onready var chat_container = $TabContainer/PanelChat/VBoxContainer/ScrollContainer/VBoxContainer
@onready var label_status = $TabContainer/PanelChat/VBoxContainer/LabelStatus
@onready var btn_send = $TabContainer/PanelChat/VBoxContainer/VBoxContainer/HBoxContainer/ButtonSend

func _ready() -> void:
	instance_script_editor = EditorInterface.get_script_editor()
	instance_script_editor.editor_script_changed.connect(_on_script_editor_active_script_changed)
	gemini_client = GeminiClient.new()
	_check_api_key()
	ProjectSettings.settings_changed.connect(_check_api_key)
	add_child(gemini_client)
	gemini_client.request_completed.connect(_on_gemini_success)
	gemini_client.request_failed.connect(_on_gemini_error)
	pass

func _check_api_key() -> void:
	var api_key = ProjectSettings.get_setting("gemini_gd/api_key")
	if api_key is String and not api_key.is_empty():
		btn_send.disabled = false
		label_status.text = "Ready"
	else:
		btn_send.disabled = true
		label_status.text = "Set API Key in Settings"
	
func _on_script_editor_active_script_changed(script):
	if script:
		var active_script: Script = script
		var label: Label = $TabContainer/PanelContext/LabelOpenScript
		label.text = script.resource_path

func _on_button_send_pressed() -> void:
	print("Saving changes...")
	EditorInterface.save_all_scenes()
	
	print("Clicked button...")
	var open_scripts = instance_script_editor.get_open_scripts()
	var active_script = instance_script_editor.get_current_script()
	var open_scenes_paths = EditorInterface.get_open_scenes()
	var open_scenes = []
	for path in open_scenes_paths:
		var scene = load(path)
		if scene:
			open_scenes.append(scene)
	
	var active_scene = EditorInterface.get_edited_scene_root()
	var text_edit_prompt: TextEdit = $TabContainer/PanelChat/VBoxContainer/VBoxContainer/TextEdit
	var text_prompt: String = text_edit_prompt.text.strip_edges()
	if not text_prompt.is_empty():
		label_status.text = "Sending..."
		var history = _get_conversation_history()
		gemini_client.send_prompt(text_prompt, open_scripts, open_scenes, active_script, active_scene, history)
		var ui_request: UiRequest = load("res://addons/AI_Gemini_GD/ui/ui_request.tscn").instantiate()
		chat_container.add_child(ui_request)
		ui_request.set_request(text_prompt)
		text_edit_prompt.clear()
		var scroll_container = chat_container.get_parent()
		await get_tree().create_timer(0.1).timeout
		scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
	pass

func _get_conversation_history() -> String:
	var history = ""
	var children = chat_container.get_children()
	var start_index = max(0, children.size() - 10)
	for i in range(start_index, children.size()):
		var child = children[i]
		if child is UiRequest:
			history += "User: " + child.get_request() + "\n"
		elif child is UiResponse:
			history += "Assistant: " + child.get_response() + "\n"
	return history

func _on_button_clear_pressed() -> void:
	for child in chat_container.get_children():
		child.queue_free()
	pass

func _on_gemini_error(error: String) -> void:
	label_status.text = "Error"
	push_error("Gemini API Error: " + error)
	pass
		
func _on_gemini_success(data: Array) -> void:
	label_status.text = "Ready"
	var ui_response: UiResponse = load("res://addons/AI_Gemini_GD/ui/ui_response.tscn").instantiate()
	chat_container.add_child(ui_response)
	ui_response.set_responses(data)
	var scroll_container = chat_container.get_parent()
	await get_tree().create_timer(0.1).timeout
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
	pass
