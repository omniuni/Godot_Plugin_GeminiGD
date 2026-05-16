@tool
extends MarginContainer
class_name UiChatElement

@onready var node_foldable_container: FoldableContainer = $FoldableContainer
@onready var node_ui_request: UiRequest = $FoldableContainer/VBoxContainer/UiRequest
@onready var node_ui_response: UiResponse = $FoldableContainer/VBoxContainer/UiResponse

var gemini_client: GeminiClient

signal signal_status

var _prompt: String = ""

var _status_word: String = ""
var _status_percent: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gemini_client = GeminiClient.new()
	gemini_client.request_completed.connect(_on_gemini_success)
	gemini_client.request_failed.connect(_on_gemini_error)
	add_child(gemini_client)
	_on_status_changed()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_status_changed():
	signal_status.emit(_status_word, _status_percent)
	pass

func set_prompt(prompt: String):
	if not prompt.strip_edges().is_empty():
		_prompt = prompt
		node_foldable_container.title = "..."
	_send_request()
	pass

func _send_request():
	node_ui_request.set_request(_prompt)
	EditorInterface.save_all_scenes()
	
	var instance_script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var active_script = instance_script_editor.get_current_script()
	var active_scene = EditorInterface.get_edited_scene_root()
	var open_scripts = instance_script_editor.get_open_scripts()
	var open_scenes_paths = EditorInterface.get_open_scenes()
	var open_scenes = []
	for path in open_scenes_paths:
		var scene = load(path)
		if scene:
			open_scenes.append(scene)
			
	_status_word = "Sending..."
	_status_percent = 50
	_on_status_changed()
	
	# get history
	var parent = get_parent().get_parent().get_parent().get_parent().get_parent()
	if parent is UiTabChat:
		var parent_chat: UiTabChat = parent
		var history = parent_chat.get_conversation_history()
		print("Got history")
		gemini_client.send_prompt(_prompt, open_scripts, open_scenes, active_script, active_scene, history)
	else:
		_status_word = "Error"
		_status_percent = 0
		_on_status_changed()
		pass

	_status_word = "Waiting for Gemini..."
	_status_percent = 55
	_on_status_changed()

	pass
	
func _on_gemini_error(error: String) -> void:
	_status_word = "Error sending to Gemini"
	_status_percent = 0
	_on_status_changed()
	pass
		
func _on_gemini_success(title: String, data: Array) -> void:
	_status_word = "Done"
	_status_percent = 100
	node_foldable_container.title = title
	node_ui_response.set_responses(data)
	_on_status_changed()
	pass

func get_chat_item() -> Dictionary:
	return {
		"user": node_ui_request.get_request(),
		"assistant": node_ui_response.get_response()
	}
	pass
