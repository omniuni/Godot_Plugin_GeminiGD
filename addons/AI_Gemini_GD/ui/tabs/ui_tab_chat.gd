@tool
extends Control
class_name UiTabChat

@onready var node_text_prompt: TextEdit = $VBoxTabChat/MarginContainerPrompt/HBoxPrompt/TextEditPrompt
@onready var node_resource_picker: EditorResourcePicker = $VBoxTabChat/MarginContainerPrompt/HBoxPrompt/EditorResourcePicker
@onready var node_button_send: Button = $VBoxTabChat/MarginContainerPrompt/HBoxPrompt/ButtonSendPrompt
@onready var node_container_files: MarginContainer = $VBoxTabChat/MarginContainerFiles
@onready var node_vbox_file_list: VBoxContainer = $VBoxTabChat/MarginContainerFiles/VBoxFileList
@onready var node_label_status: Label = $VBoxTabChat/MarginContainerChatButtons/HBoxChatButtons/PanelContainer/Label
@onready var node_progress: ProgressBar = $VBoxTabChat/MarginContainerChatButtons/HBoxChatButtons/PanelContainer/ProgressBarStatus
@onready var node_vbox_conversation: VBoxContainer = $VBoxTabChat/MarginContainerConversation/ScrollContainer/VBoxConversation
@onready var node_label_welcome: Label = $VBoxTabChat/MarginContainerConversation/ScrollContainer/VBoxConversation/LabelWelcome
@onready var node_scroll: ScrollContainer = $VBoxTabChat/MarginContainerConversation/ScrollContainer
@onready var node_thinking: Label = $VBoxTabChat/MarginContainerThought/LabelThought
@onready var node_container_thought: MarginContainer = $VBoxTabChat/MarginContainerThought

var _current_prompt: String = ""
var _selected_files: Array[String] = []

var ui_preload_chat_element: PackedScene = preload("res://addons/AI_Gemini_GD/ui/ui_chat_element.tscn")

func _ready() -> void:
	node_button_send.disabled = true
	_check_api_key()
	ProjectSettings.settings_changed.connect(_check_api_key)
	_update_file_list_ui()
	pass


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY:
		if data.get("type", "") == "files" and data.has("files"):
			return true
		if data.get("type", "") == "resource" and data.has("resource"):
			return true
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	
	var files_to_add: Array[String] = []
	if data.get("type", "") == "files" and data.has("files"):
		for f in data.get("files"):
			files_to_add.append(str(f))
	elif data.get("type", "") == "resource" and data.has("resource"):
		var res = data.get("resource")
		if res is Resource and not res.resource_path.is_empty():
			files_to_add.append(res.resource_path)
			
	for file_path in files_to_add:
		_add_file(file_path)
	_update_file_list_ui()


func _on_editor_resource_picker_resource_changed(res: Resource) -> void:
	if res and not res.resource_path.is_empty():
		_add_file(res.resource_path)
		_update_file_list_ui()
		if is_instance_valid(node_resource_picker):
			node_resource_picker.set_edited_resource(null)


func _add_file(path: String) -> void:
	if not _selected_files.has(path):
		_selected_files.append(path)


func _remove_file(path: String) -> void:
	_selected_files.erase(path)
	_update_file_list_ui()


func _update_file_list_ui() -> void:
	if not is_instance_valid(node_vbox_file_list):
		return

	for child in node_vbox_file_list.get_children():
		child.queue_free()

	if _selected_files.is_empty():
		if is_instance_valid(node_container_files):
			node_container_files.visible = false
		return

	if is_instance_valid(node_container_files):
		node_container_files.visible = true

	for path in _selected_files:
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label = Label.new()
		label.text = path
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hbox.add_child(label)

		var btn_remove = Button.new()
		btn_remove.text = "Remove"
		btn_remove.tooltip_text = "Remove " + path
		if has_theme_icon("Remove", "EditorIcons"):
			btn_remove.icon = get_theme_icon("Remove", "EditorIcons")
		btn_remove.pressed.connect(_remove_file.bind(path))
		hbox.add_child(btn_remove)

		node_vbox_file_list.add_child(hbox)


func _check_api_key() -> void:
	var api_key = ProjectSettings.get_setting("gemini_gd/gemini_configuration/api_key")
	if api_key is String and not api_key.is_empty():
		node_label_status.text = "Ready"
		node_button_send.disabled = false
	else:
		node_label_status.text = "Set API Key in Settings"
		node_button_send.disabled = true
	pass


func _on_text_edit_prompt_text_changed() -> void:
	_current_prompt = node_text_prompt.text.strip_edges()
	node_button_send.disabled = _current_prompt.is_empty()
	pass


func _on_button_send_prompt_pressed(clear: bool = true) -> void:
	var chat_element: UiChatElement = ui_preload_chat_element.instantiate()
	chat_element.connect('signal_status', _on_status_update)
	chat_element.connect('signal_thinking', _on_thought_update)
	
	if node_label_welcome.visible:
		node_label_welcome.hide()
			
	node_vbox_conversation.add_child(chat_element)
	chat_element.set_selected_files(_selected_files.duplicate())
	chat_element.set_prompt(_current_prompt)
	if clear:
		node_text_prompt.clear()
		_selected_files.clear()
		_update_file_list_ui()
	pass
	
func _on_status_update(status_text: String, status_percent: int) -> void:
	node_label_status.text = status_text
	node_progress.value = status_percent
	await get_tree().create_timer(0.1).timeout
	node_scroll.scroll_vertical = int(node_scroll.get_v_scroll_bar().max_value)
	if status_percent == 100:
		_current_prompt = ""
		await get_tree().create_timer(0.75).timeout
		node_label_status.text = "Ready"
		node_progress.value = 0
	pass
	
func _on_thought_update(thought: String) -> void:
	if not thought.is_empty():
		node_container_thought.visible = true
		node_thinking.text = thought
	else:
		node_thinking.text = ""
		node_container_thought.visible = false
	pass

func _on_button_clear_chat_pressed() -> void:
	var first = true
	for child in node_vbox_conversation.get_children():
		if not first:
			child.queue_free()
		else:
			first = false
	node_label_welcome.show()
	pass

func get_conversation_history() -> Array:
	var history = []
	var children = node_vbox_conversation.get_children()
	
	if children.size() > 0 and not children[0].visible:
		children.remove_at(0)
	
	var max_history = ProjectSettings.get_setting("gemini_gd/gemini_configuration/max_history", 10)
	var start_index = max(0, children.size() - max_history)
	for i in range(start_index, children.size()):
		var child = children[i]
		if child is UiChatElement:
			var chat_item = child.get_chat_item()
			if not str(chat_item['assistant']).is_empty():
				history.append(child.get_chat_item())
	return history

func send_now(prmpt: String) -> void:
	_current_prompt = prmpt
	_on_button_send_prompt_pressed(false)
	pass
