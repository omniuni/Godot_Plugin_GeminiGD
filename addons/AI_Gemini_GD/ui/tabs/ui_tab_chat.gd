@tool
extends Control
class_name UiTabChat

@onready var node_text_prompt: TextEdit = $VBoxTabChat/MarginContainerPrompt/HBoxPrompt/TextEditPrompt
@onready var node_button_send: Button = $VBoxTabChat/MarginContainerPrompt/HBoxPrompt/ButtonSendPrompt
@onready var node_label_status: Label = $VBoxTabChat/MarginContainerChatButtons/HBoxChatButtons/PanelContainer/Label
@onready var node_progress: ProgressBar = $VBoxTabChat/MarginContainerChatButtons/HBoxChatButtons/PanelContainer/ProgressBarStatus
@onready var node_vbox_conversation: VBoxContainer = $VBoxTabChat/MarginContainerConversation/ScrollContainer/VBoxConversation
@onready var node_label_welcome: Label = $VBoxTabChat/MarginContainerConversation/ScrollContainer/VBoxConversation/LabelWelcome
@onready var node_scroll: ScrollContainer = $VBoxTabChat/MarginContainerConversation/ScrollContainer

var _current_prompt

var ui_preload_chat_element: PackedScene = preload("res://addons/AI_Gemini_GD/ui/ui_chat_element.tscn")

func _ready() -> void:
	node_button_send.disabled = true
	_check_api_key()
	ProjectSettings.settings_changed.connect(_check_api_key)
	pass
	
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
	
	if node_label_welcome.visible:
		node_label_welcome.hide()
			
	node_vbox_conversation.add_child(chat_element)
	chat_element.set_prompt(_current_prompt)
	if clear:
		node_text_prompt.clear()
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
