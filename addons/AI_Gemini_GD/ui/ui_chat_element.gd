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
var _selected_files: Array = []

var _status_word: String = ""
var _status_percent: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_status_changed()
	pass # Replace with function body.
	
func _on_status_changed():
	signal_status.emit(_status_word, _status_percent)
	pass

func set_selected_files(files: Array) -> void:
	_selected_files = files.duplicate()

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
	_status_percent = 15
	_on_status_changed()
	_send_query(dict)
	pass
	
var has_updated_checks_once: bool = false
func _on_g_checks_progress(string: String):
	if not has_updated_checks_once:
		has_updated_checks_once = true
		_status_word = "Considering Context..."
		_status_percent = 10
		_on_status_changed()
	signal_thinking.emit(string)
	pass

func _send_checks():
	signal_thinking.emit("")
	_status_word = "Checking Requirements..."
	_status_percent = 5
	_on_status_changed()
	gemini_client_checks = GeminiClientChecks.new()
	gemini_client_checks.request_completed.connect(_on_g_checks_success)
	gemini_client_checks.request_failed.connect(_on_g_checks_error)
	gemini_client_checks.request_progress.connect(_on_g_checks_progress)
	add_child(gemini_client_checks)
	gemini_client_checks.set_explicit_files(_selected_files)
	node_ui_request.set_request(_prompt)
	gemini_client_checks.set_query(_prompt)
	gemini_client_checks.send()
	pass

func _send_query(checks: Dictionary):
	_status_word = "Preparing Query..."
	_status_percent = 20
	_on_status_changed()
	signal_thinking.emit("")
	gemini_client_query = GeminiClientQuery.new()
	gemini_client_query.request_completed.connect(_on_g_query_success)
	gemini_client_query.request_failed.connect(_on_g_query_error)
	gemini_client_query.request_progress.connect(_on_g_query_progress)
	gemini_client_query.signal_tool_used.connect(_on_tool_used)
	add_child(gemini_client_query)
	gemini_client_query.set_explicit_files(_selected_files)
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

func _on_tool_used(tool_name: String, _cost: int, total_used_cost: int, max_allowance: int) -> void:
	_status_word = "Tool: " + tool_name + "..."
	var tool_ratio: float = clampf(float(total_used_cost) / float(max(1, max_allowance)), 0.0, 1.0)
	_status_percent = int(20.0 + (60.0 * tool_ratio))
	_on_status_changed()
	pass

func _on_g_query_error(string: String):
	signal_thinking.emit("")
	pass
	
func _on_g_query_success(dict: Dictionary):
	_status_word = "Done"
	_status_percent = 100
	node_foldable_container.title = dict.get('response_title', 'Response')
	node_ui_response.set_responses(dict.get('response_content', []))
	_on_status_changed()
	signal_thinking.emit("")
	pass
	
var has_updated_query_once: bool = false
func _on_g_query_progress(string: String):
	if not has_updated_query_once:
		has_updated_query_once = true
		_status_word = "Generating Response..."
		_status_percent = max(_status_percent, 85)
		_on_status_changed()
	signal_thinking.emit(string)
	pass

func get_chat_item() -> Dictionary:
	return {
		"user": node_ui_request.get_request(),
		"assistant": node_ui_response.get_response()
	}
	pass
