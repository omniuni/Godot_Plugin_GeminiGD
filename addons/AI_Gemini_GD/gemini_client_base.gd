@abstract
extends Node
class_name GeminiClientBase

signal request_completed(response_content: Array)
signal request_failed(error_message: String)
signal request_progress(progress: String)

var _http_request: HTTPRequest
var _url: String = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:streamGenerateContent"

var _query: String = ""

func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	pass
	
@abstract func prepare()
	
func set_query(query: String):
	_query = query
	pass
	
func send():
	
	var headers = [
		"Content-Type: application/json",
		"X-goog-api-key: "+get_key()
	]
	
	var system_instruction = {
		"parts": [
			{
				"text": _get_system_prompt()
			}
		]
	}
	
	var user_parts = []
	
	var contents_array = []

	user_parts.append({"text": _query})
	
	contents_array.append(
		{
			"role": "user",
			"parts": user_parts
		}
	)
	
	var payload = {
		"contents": contents_array,
		"generationConfig": {
			"thinkingConfig": {"thinkingLevel": "HIGH"},
			"responseMimeType": "application/json",
			"responseSchema": _get_schema()
		},
		"systemInstruction": system_instruction
	}
	
	
	pass
	
@abstract func _get_system_prompt()
@abstract func _get_schema()
@abstract func _get_history_array()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:

	pass

func get_key() -> String:
	var api_key = ProjectSettings.get_setting("gemini_gd/gemini_configuration/api_key")
	if not api_key is String or api_key.is_empty():
		request_failed.emit("API Key is missing.")
		return ""
	return api_key
