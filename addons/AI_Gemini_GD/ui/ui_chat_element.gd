@tool
extends MarginContainer
class_name UiChatElement

@onready var node_foldable_container: FoldableContainer = $FoldableContainer
@onready var node_ui_request: UiRequest = $FoldableContainer/VBoxContainer/UiRequest
@onready var node_ui_response: UiResponse = $FoldableContainer/VBoxContainer/UiResponse

var gemini_client_checks: GeminiClientChecks
var gemini_client_query: GeminiClientQuery

signal signal_status
signal signal_thinking

var _prompt: String = ""

var _status_word: String = ""
var _status_percent: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_status_changed()
	pass # Replace with function body.
	
func _on_status_changed():
	signal_status.emit(_status_word, _status_percent)
	pass

func set_prompt(prompt: String):
	if not prompt.strip_edges().is_empty():
		_prompt = prompt
		node_foldable_container.title = "..."
		_send_checks()
	pass

func _on_g_checks_error(string: String):
	signal_thinking.emit("")
	pass
	
func _on_g_checks_success(dict: Dictionary):
	signal_thinking.emit("")
	gemini_client_checks.queue_free()
	_status_word = "Checking Context..."
	_status_percent = 30
	_on_status_changed()
	_send_query(dict)
	pass
	
var has_updated_checks_once: bool = false
func _on_g_checks_progress(string: String):
	if not has_updated_checks_once:
		has_updated_checks_once = true
		_status_word = "Considering Context..."
		_status_percent = 20
		_on_status_changed()
	signal_thinking.emit(string)
	pass

func _send_checks():
	signal_thinking.emit("")
	_status_word = "Checking Requirements..."
	_status_percent = 10
	_on_status_changed()
	gemini_client_checks = GeminiClientChecks.new()
	gemini_client_checks.request_completed.connect(_on_g_checks_success)
	gemini_client_checks.request_failed.connect(_on_g_checks_error)
	gemini_client_checks.request_progress.connect(_on_g_checks_progress)
	add_child(gemini_client_checks)
	node_ui_request.set_request(_prompt)
	gemini_client_checks.set_query(_prompt)
	gemini_client_checks.send()
	pass

func _send_query(checks: Dictionary):
	_status_word = "Preparing Query..."
	_status_percent = 45
	_on_status_changed()
	signal_thinking.emit("")
	gemini_client_query = GeminiClientQuery.new()
	gemini_client_query.request_completed.connect(_on_g_query_success)
	gemini_client_query.request_failed.connect(_on_g_query_error)
	gemini_client_query.request_progress.connect(_on_g_query_progress)
	add_child(gemini_client_query)
	gemini_client_query.configure(
		checks['query_requires_context'],
		checks['query_requires_only_current'],
		checks['query_requires_active_files'],
		checks['query_requires_file_scan'],
		checks['file_scan_search_terms']
	)
	var parent = get_parent().get_parent().get_parent().get_parent().get_parent()
	if parent is UiTabChat:
		var parent_chat: UiTabChat = parent
		var history = parent_chat.get_conversation_history()
		gemini_client_query.set_history(history)
	gemini_client_query.set_query(_prompt)
	gemini_client_query.send()
	pass

func _on_g_query_error(string: String):
	signal_thinking.emit("")
	pass
	
func _on_g_query_success(dict: Dictionary):
	_status_word = "Done"
	_status_percent = 100
	node_foldable_container.title = dict['response_title']
	node_ui_response.set_responses(dict['response_content'])
	_on_status_changed()
	signal_thinking.emit("")
	pass
	
var has_updated_query_once: bool = false
func _on_g_query_progress(string: String):
	if not has_updated_query_once:
		has_updated_checks_once = true
		_status_word = "Analyzing Query..."
		_status_percent = 75
		_on_status_changed()
	signal_thinking.emit(string)
	pass

func get_chat_item() -> Dictionary:
	return {
		"user": node_ui_request.get_request(),
		"assistant": node_ui_response.get_response()
	}
	pass
