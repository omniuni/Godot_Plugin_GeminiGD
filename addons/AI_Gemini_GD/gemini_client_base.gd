@abstract
extends Node
class_name GeminiClientBase

signal request_completed(response_content: Array)
signal request_failed(error_message: String)
signal request_progress(progress: String)

var _http_request: HTTPRequest
var _url: String = ""

var _query: String = ""

func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	pass
	
@abstract func prepare()
	
func set_query(query: String):
	_query = query
	pass

func _get_model_url() -> String:
	var model = ProjectSettings.get_setting("gemini_gd/gemini_configuration/model", "gemini-3.5-flash-lite")
	if not model is String or model.is_empty():
		model = "gemini-3.5-flash-lite"
	return "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":streamGenerateContent"

func _get_thinking_level() -> String:
	var level = ProjectSettings.get_setting("gemini_gd/gemini_configuration/thinking_level", "LOW")
	if not level is String or level.is_empty():
		level = "LOW"
	return level

func send():
	prepare()
	
	_url = _get_model_url()
	_log("[" + _get_client_name() + "] Sending request to: " + _url)
	
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
	
	var contents_array = []
	
	var history = _get_history_array()
	for chat_entry in history:
		if chat_entry.has("user") and not chat_entry["user"].is_empty():
			contents_array.append({"role": "user", "parts": [{"text": chat_entry["user"]}]})
		if chat_entry.has("assistant") and not chat_entry["assistant"].is_empty():
			contents_array.append({"role": "model", "parts": [{"text": chat_entry["assistant"]}]})
			
	var user_parts = [{"text": _query}]
	contents_array.append({
		"role": "user",
		"parts": user_parts
	})
	
	var payload = {
		"contents": contents_array,
		"generationConfig": {
			"thinkingConfig": {
				"thinkingLevel": _get_thinking_level(),
				"includeThoughts": true
			},
			"responseMimeType": "application/json",
			"responseSchema": _get_schema()
		},
		"systemInstruction": system_instruction
	}
	
	var use_ssl = _url.begins_with("https://")
	var host = _url.replace("https://", "").replace("http://", "")
	var slash_pos = host.find("/")
	var path = ""
	if slash_pos != -1:
		path = host.substr(slash_pos)
		host = host.substr(0, slash_pos)
	else:
		path = "/"
	
	if not "alt=sse" in path:
		if path.contains("?"):
			path += "&alt=sse"
		else:
			path += "?alt=sse"

	var port = 443 if use_ssl else 80
	var client = HTTPClient.new()
	var err = client.connect_to_host(host, port, TLSOptions.client() if use_ssl else null)
	if err != OK:
		_fail_request("Failed to connect to host: " + str(err))
		return null
		
	while client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING:
		client.poll()
		await get_tree().process_frame
		
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		_fail_request("Connection failed. Status: " + str(client.get_status()))
		return null
		
	_log("[" + _get_client_name() + "] Connected to host successfully.")
	
	var json_body = JSON.stringify(payload)
	_log_request_payload(json_body)
	var req_err = client.request(HTTPClient.METHOD_POST, path, headers, json_body)
	if req_err != OK:
		_fail_request("Failed to send HTTP request: " + str(req_err))
		return null
		
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		await get_tree().process_frame
		
	if client.get_status() != HTTPClient.STATUS_BODY and client.get_status() != HTTPClient.STATUS_CONNECTED:
		_fail_request("Request failed. Status: " + str(client.get_status()))
		return null
		
	if not client.has_response():
		_fail_request("No response from server.")
		return null
		
	var response_code = client.get_response_code()
	_log("[" + _get_client_name() + "] Response received. Code: " + str(response_code))
	
	var raw_response_body = ""
	var sse_buffer = ""
	var context = {
		"full_text": "",
		"thinking_buffer": ""
	}
	
	var process_chunk = func(json_chunk: Dictionary):
		if json_chunk.has("candidates") and json_chunk["candidates"].size() > 0:
			var candidate = json_chunk["candidates"][0]
			if candidate.has("content") and candidate["content"].has("parts"):
				for part in candidate["content"]["parts"]:
					if typeof(part) == TYPE_DICTIONARY:
						var text_part = part.get("text", "")
						if part.get("thought", false) == true:
							context["thinking_buffer"] += text_part
							if "\n" in context["thinking_buffer"]:
								var lines = context["thinking_buffer"].split("\n")
								context["thinking_buffer"] = lines[-1]
								for i in range(lines.size() - 1):
									var line = lines[i]
									if not line.strip_edges().is_empty():
										_log("[" + _get_client_name() + "] THINKING: " + line.strip_edges())
										request_progress.emit(line.strip_edges())
						else:
							if not text_part.strip_edges().is_empty():
								context["full_text"] += text_part
								var stripped_ft = context["full_text"].strip_edges()
								if stripped_ft.begins_with("{") and stripped_ft.ends_with("}"):
									var complete_response: Dictionary = JSON.parse_string(stripped_ft)
									_log("[" + _get_client_name() + "] Request completed successfully.")
									request_completed.emit(complete_response)
	
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		if client.has_response():
			var chunk = client.read_response_body_chunk()
			if chunk.size() > 0:
				var chunk_str = chunk.get_string_from_utf8()
				raw_response_body += chunk_str
				sse_buffer += chunk_str
				var lines = sse_buffer.split("\n")
				sse_buffer = lines[-1]
				lines.remove_at(lines.size() - 1)
				for line in lines:
					line = line.strip_edges()
					if line.begins_with("data:"):
						var data_str = line.substr(5)
						if not data_str.strip_edges().is_empty():
							var json_chunk = JSON.parse_string(data_str)
							if typeof(json_chunk) == TYPE_DICTIONARY:
								process_chunk.call(json_chunk)
		await get_tree().process_frame

	_log_response_payload(raw_response_body, response_code)
	if response_code != 200:
		_fail_request("API request failed. HTTP Code: " + str(response_code) + "\n" + raw_response_body)
		return null

	pass
	
@abstract func _get_system_prompt()
@abstract func _get_schema()
@abstract func _get_history_array()

func get_key() -> String:
	var api_key = ProjectSettings.get_setting("gemini_gd/gemini_configuration/api_key")
	if not api_key is String or api_key.is_empty():
		_fail_request("API Key is missing.")
		return ""
	return api_key

func _get_client_name() -> String:
	if self.get_script() and not self.get_script().resource_path.is_empty():
		return self.get_script().resource_path.get_file().get_basename()
	return "GeminiClient"

func _log(message: String) -> void:
	if ProjectSettings.get_setting("gemini_gd/debugging/behavior_debugging", false):
		print(message)

func _log_request_payload(payload_str: String) -> void:
	var req_debug = ProjectSettings.get_setting("gemini_gd/debugging/request_debugging", false)
	var behav_debug = ProjectSettings.get_setting("gemini_gd/debugging/behavior_debugging", false)
	var byte_count = payload_str.to_utf8_buffer().size()
	if req_debug:
		print("[" + _get_client_name() + "] Request payload (" + str(byte_count) + " bytes):\n" + payload_str)
	elif behav_debug:
		print("[" + _get_client_name() + "] Request payload sent (" + str(byte_count) + " bytes)")

func _log_response_payload(response_str: String, response_code: int = 200) -> void:
	var req_debug = ProjectSettings.get_setting("gemini_gd/debugging/request_debugging", false)
	var behav_debug = ProjectSettings.get_setting("gemini_gd/debugging/behavior_debugging", false)
	var byte_count = response_str.to_utf8_buffer().size()
	if req_debug:
		print("[" + _get_client_name() + "] Response received (Code: " + str(response_code) + ", " + str(byte_count) + " bytes):\n" + response_str)
	elif behav_debug:
		print("[" + _get_client_name() + "] Response received (Code: " + str(response_code) + ", " + str(byte_count) + " bytes)")

func _fail_request(error_message: String) -> void:
	_log("[" + _get_client_name() + "] ERROR: " + error_message)
	request_failed.emit(error_message)
