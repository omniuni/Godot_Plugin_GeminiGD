@tool
class_name GeminiClient
extends Node

# Updated signal to pass an Array instead of a Dictionary
signal request_completed(response_content: Array)
signal request_failed(error_message: String)

var _http_request: HTTPRequest

func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)

var _last_request_params = []

func send_prompt(prompt_text: String, scripts: Array = [], scenes: Array = [], active_script: Script = null, active_scene: Node = null, history_text: String = "") -> void:
	_last_request_params = [prompt_text, scripts, scenes, active_script, active_scene, history_text]
	var api_key = ProjectSettings.get_setting("gemini_gd/api_key")
	if not api_key is String or api_key.is_empty():
		request_failed.emit("API Key is missing.")
		return
		
	print("Sending. Total scripts: " + str(scripts.size()) + ", total scenes: " + str(scenes.size()) + "...")
	
	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:streamGenerateContent?key=" + api_key
	var headers = ["Content-Type: application/json"]
	
	# The version of Godot Engine
	var engine_version = Engine.get_version_info().string
	
	var system_instruction = {
		"parts": [
			{
				"text": "
				This is a code assistant for Godot Engine, the Godot Game Engine.
				This is for Godot "+engine_version+". Check that the methods used are for version "+engine_version+"
				
				Respond to the prompt returning content as an array of objects,
				with each object having a type and value.
				This is the only way to provide formatting.
				Do not use Markdown, HTML, or any other formatting.
				The available types are: header, text, list_item_bullet, list_item_numeric, code, code_edit
				
				Code must be formatted with whitespace as per the original file.
				When being asked for code changes, be thorough, making multiple changes in different files or different locations of the file if necessary.
				Files and resources ending in .gd are GDScript. GDScript is whitespace sensitive.
				
				`code_edit` is a special type indicating that the code block should edit by adding or replacing existing code in the file.
				`code_edit` must specify the fields code_original_file and code_original_reference which will replace code_original_reference with the content_value in the code_original_file as specified with the full script resource path.
				code_original_reference must exactly and fully match the code that is being replaced.
				code_original_reference must contain at least two lines of existing code before and after the region that will be changed to ensure accurate matching.
				Use multiple `code_edit` entries when different parts of the file should be replaced or added so the user has more control over what to apply.
				If only a couple of lines need to change, show those as an independent `code_edit`
				
				Fix code formatting with whitespace and indentation that matches the original file.
				
				Use `resource_reference` to link to a resource or file, especially when locating or explaining.
				`resource_reference` should contain a short, one-line description of the referenced file that is not the file path, and code_original_file is the godot reference path.
				`resource_reference` should be included when that reference is required for the response.
				If referencing a specific line, set code_original_reference to be the line number.
				
				Before making code changes, review other files and check the flow of information to determine the best way to achieve the results.
				Keep changes simple when possible. Add comments above newly created functions, but do not make other changes unless specifically asked.
				
				Check whitespace, spacing, and formatting against documents provided for context.
				Check that all functions and syntax are appropriate for Godot "+engine_version+".
				
				Fix any whitespace or functions from old versions of Godot.
				Verify that any code being replaced with `code_edit` has an accurate code_original_reference.
				"
			}
		]
	}
	
	var schema = {
		"type": "object",
		"properties": {
			"response_title": {"type": "string"},
			"response_content": {
				"type": "array",
				"items": {
					"type": "object",
					"properties": {
						"response_content_type": {
							"type": "string",
							"enum": ["header", "text", "list_item_bullet", "list_item_numeric", "code", "code_edit", "resource_reference"]
						},
						"response_content_value": {"type": "string"},
						"code_original_file": {"type": "string"},
						"code_original_reference": {"type": "string"}
					},
					"required": ["response_content_type", "response_content_value"]
				}
			}
		},
		"required": ["response_title", "response_content"]
	}
	
	# Construct the parts array for the user message
	var user_parts = []
	
	if active_script:
		user_parts.append({"text": "The Active Script is " + active_script.resource_path})
	if active_scene:
		var scene_path = active_scene.scene_file_path
		if not scene_path.is_empty():
			user_parts.append({"text": "The active Scene is " + scene_path + "\nContents: " + FileAccess.get_file_as_string(scene_path) + "\n"})
	
	for script in scripts:
		var current_script: Script = script
		user_parts.append({"text": "Script Resource: " + current_script.resource_path + "\nContents:\n" + current_script.source_code + "\n"})
	
	for scene: PackedScene in scenes:
		var scene_path = scene.resource_path
		var scene_file_contents = ""
		if FileAccess.file_exists(scene_path):
			var file = FileAccess.open(scene_path, FileAccess.READ)
			scene_file_contents = file.get_as_text()
		user_parts.append({"text": "Scene Resource: " + scene_path + "\nContents:\n" + scene_file_contents })
	
	# Append history context if available
	if not history_text.is_empty():
		user_parts.append({"text": "Conversation History:\n" + history_text + "\n---\n"})

	# Append the actual user prompt as the final part
	user_parts.append({"text": prompt_text})
	
	var payload = {
		"contents": [
			{
				"role": "user",
				"parts": user_parts
			}
		],
		"generationConfig": {
			"thinkingConfig": {"thinkingLevel": "HIGH"},
			"responseMimeType": "application/json",
			"responseSchema": schema
		},
		"systemInstruction": system_instruction
	}
	
	var json_body = JSON.stringify(payload)
	
	print("Sending...")
	var response_code = _http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	
	if response_code != OK:
		request_failed.emit("Failed to send HTTP request. Error code: " + str(response_code))
		
	pass

var _retry_count: int = 0

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 503 and _retry_count < 3:
		_retry_count += 1
		await get_tree().create_timer(0.5 * _retry_count).timeout
		send_prompt(_last_request_params[0], _last_request_params[1], _last_request_params[2], _last_request_params[3], _last_request_params[4], _last_request_params[5])
		return
	
	_retry_count = 0
	if response_code == 200:
		var response_string = body.get_string_from_utf8()
		var json = JSON.parse_string(response_string)
		var full_text = ""
		
		# streamGenerateContent returns an array of chunks
		if typeof(json) == TYPE_ARRAY:
			for chunk in json:
				if typeof(chunk) == TYPE_DICTIONARY and chunk.has("candidates") and chunk["candidates"].size() > 0:
					var parts = chunk["candidates"][0].get("content", {}).get("parts", [])
					if parts.size() > 0:
						full_text += parts[0].get("text", "")
		# Fallback for standard generateContent
		elif typeof(json) == TYPE_DICTIONARY and json.has("candidates") and json["candidates"].size() > 0:
			var parts = json["candidates"][0].get("content", {}).get("parts", [])
			if parts.size() > 0:
				full_text = parts[0].get("text", "")
				
		if not full_text.is_empty():
			# Parse the inner JSON string returned by the model
			var structured_data = JSON.parse_string(full_text)
			if typeof(structured_data) == TYPE_DICTIONARY and structured_data.has("response_content"):
				# Emit only the parsed array
				request_completed.emit(structured_data["response_content"])
				return
		
		request_failed.emit("Failed to parse expected JSON schema from response.")
	else:
		request_failed.emit("API request failed. HTTP Code: " + str(response_code))
