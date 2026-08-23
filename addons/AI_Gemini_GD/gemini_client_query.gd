extends GeminiClientBase
class_name GeminiClientQuery

signal signal_tool_used(tool_name: String, cost: int, total_used_cost: int, max_allowance: int)

var _prepare_context: bool = false
var _prepare_only_current: bool = false
var _prepare_active_files: bool = false
var _prepare_scan: bool = false
var _prepare_scan_terms: Array = []
var _explicit_files: Array = []
var _history: Array = []
var _tool_manager: GeminiToolManager

func configure(context: bool, current: bool, active: bool, scan: bool, terms: Array):
	_prepare_context = context
	_prepare_only_current = current
	_prepare_active_files = active
	_prepare_scan = scan
	_prepare_scan_terms = terms
	pass

func set_explicit_files(files: Array) -> void:
	_explicit_files = files
	pass
	
func set_history(history: Array):
	_log("[" + _get_client_name() + "] History entries received: " + str(history.size()))
	_history = history
	pass

var _prepared_history: Array = []

func prepare() -> void:
	EditorInterface.save_all_scenes()
	
	var context_parts = []
	var added_paths = {}
	var files_in_scan = []
	var active_open_files = []
	var explicit_files_added = []
	
	if _prepare_context:
		if _prepare_only_current:
			var instance_script_editor: ScriptEditor = EditorInterface.get_script_editor()
			var active_script = instance_script_editor.get_current_script()
			if active_script:
				context_parts.append("The Active Script is " + active_script.resource_path)
				context_parts.append("Script Resource: " + active_script.resource_path + "\nContents:\n" + active_script.source_code + "\n")
				added_paths[active_script.resource_path] = true
				active_open_files.append(active_script.resource_path + " (Active Script)")
		else:
			if _prepare_active_files:
				var instance_script_editor: ScriptEditor = EditorInterface.get_script_editor()
				var active_script = instance_script_editor.get_current_script()
				var active_scene = EditorInterface.get_edited_scene_root()
				var open_scripts = instance_script_editor.get_open_scripts()
				var open_scenes_paths = EditorInterface.get_open_scenes()
				
				if active_script:
					context_parts.append("The Active Script is " + active_script.resource_path)
					context_parts.append("Script Resource: " + active_script.resource_path + "\nContents:\n" + active_script.source_code + "\n")
					added_paths[active_script.resource_path] = true
					active_open_files.append(active_script.resource_path + " (Active Script)")
					
				if active_scene:
					var scene_path = active_scene.scene_file_path
					if not scene_path.is_empty() and not added_paths.has(scene_path):
						context_parts.append("The active Scene is " + scene_path + "\nContents: " + FileAccess.get_file_as_string(scene_path) + "\n")
						added_paths[scene_path] = true
						active_open_files.append(scene_path + " (Active Scene)")
						
				for script in open_scripts:
					var script_path = script.resource_path
					if not script_path.is_empty() and not added_paths.has(script_path):
						context_parts.append("Script Resource: " + script_path + "\nContents:\n" + script.source_code + "\n")
						added_paths[script_path] = true
						active_open_files.append(script_path + " (Open Script)")
						
				for scene_path in open_scenes_paths:
					if not scene_path.is_empty() and not added_paths.has(scene_path):
						var scene_file_contents = ""
						if FileAccess.file_exists(scene_path):
							scene_file_contents = FileAccess.get_file_as_string(scene_path)
						context_parts.append("Scene Resource: " + scene_path + "\nContents:\n" + scene_file_contents)
						added_paths[scene_path] = true
						active_open_files.append(scene_path + " (Open Scene)")
						
			if _prepare_scan:
				var scan_terms = []
				for term in _prepare_scan_terms:
					if term is String:
						var t = term.strip_edges()
						if not t.is_empty():
							scan_terms.append(t.to_lower())
							
				if not scan_terms.is_empty():
					var file_list = []
					_scan_dir("res://", file_list)
					for file_path in file_list:
						if added_paths.has(file_path):
							continue
						var ext = file_path.get_extension().to_lower()
						var file_matched = false
						var file_path_lower = file_path.to_lower()
						
						for term in scan_terms:
							if term in file_path_lower:
								file_matched = true
								break
								
						if not file_matched and ext in ["tscn", "cfg", "gd", "json", "md", "txt"]:
							var content = FileAccess.get_file_as_string(file_path)
							var content_lower = content.to_lower()
							for term in scan_terms:
								if term in content_lower:
									file_matched = true
									break
									
						if file_matched:
							files_in_scan.append(file_path)
							if ext in ["png", "jpg", "jpeg", "webp", "svg"]:
								context_parts.append("Image File: " + file_path)
							else:
								var content = FileAccess.get_file_as_string(file_path)
								context_parts.append("File: " + file_path + "\nContents:\n" + content + "\n")
							added_paths[file_path] = true

	# Explicitly selected files (added if not already included)
	for file_path in _explicit_files:
		if file_path is String and not file_path.is_empty() and not added_paths.has(file_path):
			if FileAccess.file_exists(file_path):
				var ext = file_path.get_extension().to_lower()
				if ext in ["png", "jpg", "jpeg", "webp", "svg"]:
					context_parts.append("Image File: " + file_path)
				elif ext in ["gd"]:
					var content = FileAccess.get_file_as_string(file_path)
					context_parts.append("Script Resource: " + file_path + "\nContents:\n" + content + "\n")
				elif ext in ["tscn"]:
					var content = FileAccess.get_file_as_string(file_path)
					context_parts.append("Scene Resource: " + file_path + "\nContents:\n" + content + "\n")
				elif ext in ["json", "md", "txt", "cfg", "ini", "csv", "xml", "html", "shader", "gdshader"]:
					var content = FileAccess.get_file_as_string(file_path)
					context_parts.append("File: " + file_path + "\nContents:\n" + content + "\n")
				else:
					context_parts.append("Binary Resource File: " + file_path)
				added_paths[file_path] = true
				explicit_files_added.append(file_path)

	var context_string = "\n".join(context_parts)
	var final_history = _history.duplicate(true)
	if not context_string.is_empty():
		final_history.append({
			"user": context_string,
			"assistant": ""
		})
	_prepared_history = final_history

	# Generate and output debug summary
	var summary = "=== GEMINI CLIENT QUERY DEBUG SUMMARY ===\n"
	summary += "Model URL: " + _url + "\n"
	summary += "Number of History Items: " + str(_history.size()) + "\n"
			
	summary += "Context Configuration:\n"
	summary += "  - Require Context: " + str(_prepare_context) + "\n"
	summary += "  - Only Current: " + str(_prepare_only_current) + "\n"
	summary += "  - Active Files: " + str(_prepare_active_files) + "\n"
	summary += "  - File Scan: " + str(_prepare_scan) + "\n"
	if _prepare_scan:
		summary += "  - File Scan Terms: " + str(_prepare_scan_terms) + "\n"
		
	if active_open_files.is_empty():
		summary += "Active/Open Files: None\n"
	else:
		summary += "Active/Open Files:\n"
		for f in active_open_files:
			summary += "  - " + f + "\n"

	if not explicit_files_added.is_empty():
		summary += "Explicitly Added Files:\n"
		for f in explicit_files_added:
			summary += "  - " + f + "\n"
			
	if _prepare_scan:
		if files_in_scan.is_empty():
			summary += "Files Identified in Scan: None\n"
		else:
			summary += "Files Identified in Scan:\n"
			for f in files_in_scan:
				summary += "  - " + f + "\n"
	summary += "========================================="
	_log(summary)

func _scan_dir(path: String, file_list: Array) -> void:
	var treat_addons = ProjectSettings.get_setting("gemini_gd/advanced/treat_addons_as_project", false)
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var full_path = path.path_join(file_name)
				if dir.current_is_dir():
					if file_name != ".godot" and file_name != ".git":
						if file_name != "addons" or treat_addons:
							_scan_dir(full_path, file_list)
				else:
					var ext = file_name.get_extension().to_lower()
					if ext in ["tscn", "cfg", "gd", "json", "md", "txt", "png", "svg", "jpg", "jpeg", "webp"]:
						file_list.append(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()

func send() -> void:
	_tool_manager = GeminiToolManager.new()
	prepare()
	
	_url = _get_model_url()
	_log("[" + _get_client_name() + "] Sending request to: " + _url)
	
	var system_prompt_text = _get_system_prompt()
	if _tool_manager.is_tool_use_allowed():
		system_prompt_text += "\n" + _tool_manager.get_tool_system_instructions()
		
	var system_instruction = {
		"parts": [
			{
				"text": system_prompt_text
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
	
	_run_turns_loop(contents_array, system_instruction)

func _run_turns_loop(contents_array: Array, system_instruction: Dictionary) -> void:
	while true:
		var tool_declarations = _tool_manager.get_tool_declarations()
		var generation_config = {
			"thinkingConfig": {
				"thinkingLevel": _get_thinking_level(),
				"includeThoughts": true
			}
		}
		
		# In Gemini API, responseMimeType: application/json and responseSchema can only be set when tools are not used
		if tool_declarations.is_empty():
			generation_config["responseMimeType"] = "application/json"
			generation_config["responseSchema"] = _get_schema()
			
		var payload: Dictionary = {
			"contents": contents_array,
			"generationConfig": generation_config,
			"systemInstruction": system_instruction
		}
		
		if not tool_declarations.is_empty():
			payload["tools"] = tool_declarations
			
		var turn_result = await _execute_http_turn(payload)
		if not turn_result.get("success", false):
			_fail_request(turn_result.get("error", "Request failed."))
			return
			
		var raw_model_parts: Array = turn_result.get("raw_model_parts", [])
		var function_calls: Array = turn_result.get("function_calls", [])
		
		if not function_calls.is_empty():
			# Append model turn preserving exact model parts (including thoughtSignature)
			contents_array.append({
				"role": "model",
				"parts": raw_model_parts
			})
			
			var tool_response_parts = []
			for fc in function_calls:
				var tool_name: String = fc.get("name", "")
				var tool_args: Dictionary = fc.get("args", {})
				var tool_instance = _tool_manager.get_tool(tool_name)
				var cost = tool_instance.get_cost() if tool_instance else 1
				
				var execution_result = _tool_manager.execute_tool(tool_name, tool_args)
				signal_tool_used.emit(tool_name, cost, _tool_manager.get_allowance_used(), _tool_manager.get_max_allowance())
				
				tool_response_parts.append({
					"functionResponse": {
						"name": tool_name,
						"response": {
							"name": tool_name,
							"content": execution_result
						}
					}
				})
				
			# Gemini API expects role 'user' for functionResponse turns
			contents_array.append({
				"role": "user",
				"parts": tool_response_parts
			})
			
			var turn_statement = _tool_manager.get_turn_statement()
			if not turn_statement.is_empty():
				contents_array.append({
					"role": "user",
					"parts": [{"text": turn_statement}]
				})
			continue
			
		var full_text: String = turn_result.get("full_text", "").strip_edges()
		var parsed_json = _extract_json(full_text)
		if typeof(parsed_json) == TYPE_DICTIONARY and parsed_json.has("response_title") and parsed_json.has("response_content"):
			_log("[" + _get_client_name() + "] Request completed successfully: " + parsed_json.get("response_title", ""))
			request_completed.emit(parsed_json)
			return
		else:
			_fail_request("Failed to parse valid JSON response from Gemini API: " + full_text)
			return

func _extract_json(text: String) -> Dictionary:
	var clean = text.strip_edges()
	if clean.begins_with("```json"):
		clean = clean.substr(7)
	elif clean.begins_with("```"):
		clean = clean.substr(3)
	if clean.ends_with("```"):
		clean = clean.substr(0, clean.length() - 3)
	clean = clean.strip_edges()
	
	var parsed = JSON.parse_string(clean)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
		
	var first_brace = clean.find("{")
	var last_brace = clean.rfind("}")
	if first_brace != -1 and last_brace != -1 and last_brace > first_brace:
		var json_substr = clean.substr(first_brace, last_brace - first_brace + 1)
		var substr_parsed = JSON.parse_string(json_substr)
		if typeof(substr_parsed) == TYPE_DICTIONARY:
			return substr_parsed
			
	return {}

func _execute_http_turn(payload: Dictionary) -> Dictionary:
	var headers = [
		"Content-Type: application/json",
		"X-goog-api-key: " + get_key()
	]
	
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
		return {"success": false, "error": "Failed to connect to host: " + str(err)}
		
	while client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING:
		client.poll()
		await get_tree().process_frame
		
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		return {"success": false, "error": "Connection failed. Status: " + str(client.get_status())}
		
	_log("[" + _get_client_name() + "] Connected to host successfully.")
	
	var json_body = JSON.stringify(payload)
	_log_request_payload(json_body)
	var req_err = client.request(HTTPClient.METHOD_POST, path, headers, json_body)
	if req_err != OK:
		return {"success": false, "error": "Failed to send HTTP request: " + str(req_err)}
		
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		await get_tree().process_frame
		
	if client.get_status() != HTTPClient.STATUS_BODY and client.get_status() != HTTPClient.STATUS_CONNECTED:
		return {"success": false, "error": "Request failed. Status: " + str(client.get_status())}
		
	if not client.has_response():
		return {"success": false, "error": "No response from server."}
		
	var response_code = client.get_response_code()
	_log("[" + _get_client_name() + "] Response received. Code: " + str(response_code))
	
	var raw_response_body = ""
	var sse_buffer = ""
	var turn_data = {
		"full_text": "",
		"thinking_buffer": "",
		"function_calls": [],
		"raw_model_parts": []
	}
	
	var process_chunk = func(json_chunk: Dictionary):
		if json_chunk.has("candidates") and json_chunk["candidates"].size() > 0:
			var candidate = json_chunk["candidates"][0]
			if candidate.has("content") and candidate["content"].has("parts"):
				for part in candidate["content"]["parts"]:
					if typeof(part) == TYPE_DICTIONARY:
						turn_data["raw_model_parts"].append(part)
						if part.has("functionCall"):
							turn_data["function_calls"].append(part["functionCall"])
						elif part.get("thought", false) == true:
							var text_part = part.get("text", "")
							turn_data["thinking_buffer"] += text_part
							if "\n" in turn_data["thinking_buffer"]:
								var lines = turn_data["thinking_buffer"].split("\n")
								turn_data["thinking_buffer"] = lines[-1]
								for i in range(lines.size() - 1):
									var line = lines[i]
									if not line.strip_edges().is_empty():
										_log("[" + _get_client_name() + "] THINKING: " + line.strip_edges())
										request_progress.emit(line.strip_edges())
						else:
							var text_part = part.get("text", "")
							if not text_part.is_empty():
								turn_data["full_text"] += text_part
	
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
		return {"success": false, "error": "API request failed (" + str(response_code) + "): " + raw_response_body}

	return {
		"success": true,
		"full_text": turn_data["full_text"],
		"function_calls": turn_data["function_calls"],
		"raw_model_parts": turn_data["raw_model_parts"]
	}

func _get_system_prompt():
	var engine_version = Engine.get_version_info().string
	return "
	This is a code assistant for Godot Engine, the Godot Game Engine.
	This is for Godot "+engine_version+". Check that the methods used are for version "+engine_version+"
	The 'addons/AI_Gemini_GD/' addon is NOT part of the project.
	
	The response_title is a very short summary of the topic of the response.
	
	Respond to the prompt returning content as a JSON object with keys:
	- response_title: string
	- response_content: array of objects
	each object having 'response_content_type', 'response_content_value', and for numeric list items, 'list_item_index'.
	This is the only way to provide formatting.
	Do not use Markdown, HTML, or any other formatting outside the JSON structure.
	The available types are: header, text, list_item_bullet, list_item_numeric, code, code_edit, resource_reference
	
	`header`, `text`, `list_item_bullet`, and `list_item_numeric` support BBCode formatting. Use ONLY BBCode formatting for headers, text, and list items.
	Use headers to separate sections of a reply, and text for more general content and information.
	IMPORTANT: BBCode does NOT support lists. Always use list_item_bullet or list_item_numeric to make lists.
	For `list_item_numeric`, always specify `list_item_index` as the 1-based integer index (1, 2, 3...). Do not include the number prefix in `response_content_value`.
	
	If a file is referenced in the reply, include a reference for it.
	
	The active script and active scene are the most likely subject if no specific context is specified.
	
	Code must be formatted with whitespace as per the original file.
	When being asked for changes, be thorough, making multiple changes in different files or different locations of the file if necessary.
	Files and resources ending in .gd are GDScript (GDScript is whitespace sensitive).
	Files ending in .json, .md, .tscn, .cfg, .txt are also editable.
	
	`code_edit` is a special type indicating that the code/content block should edit by adding or replacing existing code/content in the file.
	`code_edit` must specify the fields code_original_file and code_original_reference which will replace code_original_reference with the content_value in the code_original_file as specified with the full file/resource path.
	code_original_reference must exactly and fully match the code or text that is being replaced.
	code_original_reference must contain at least two lines of existing text before and after the region that will be changed to ensure accurate matching.
	Use multiple `code_edit` entries when different parts of the file should be replaced or added so the user has more control over what to apply.
	If only a couple of lines need to change, show those as an independent `code_edit`
	Include surrounding lines in `code_edit` and code_original_reference for context and to ensure correct replacement.
	
	Fix code and file formatting with whitespace and indentation that matches the original file.
	
	Don't use 'project.godot' as a reference.
	Don't show empty references, make sure to use the file resource path.
	Use `resource_reference` to link to a resource or file, especially when locating or explaining.
	`resource_reference` should contain a short, one-line description of the referenced file that is not the file path, and code_original_file is the godot reference path.
	`resource_reference` should be included when that reference is required for the response.
	If referencing a specific line, set code_original_reference to be the line number.
	
	Before making edits, review other files and check the flow of information to determine the best way to achieve the results.
	Keep changes simple when possible. Add comments above newly created functions or sections, but do not make other changes unless specifically asked.
	
	Check whitespace, spacing, and formatting against documents provided for context.
	Check that all functions and syntax are appropriate for Godot "+engine_version+".
	Check that `header`, `text`, `list_item_bullet`, and `list_item_numeric` are formatted with BBCode do not contain HTML or markdown, and if they do, convert it to BBCode.
	
	Fix any whitespace or functions from old versions of Godot.
	Verify that any content being replaced with `code_edit` has an accurate code_original_reference.
	"
	pass
	
func _get_schema():
	return {
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
						"code_original_reference": {"type": "string"},
						"list_item_index": {"type": "integer"}
					},
					"required": ["response_content_type", "response_content_value"]
				}
			}
		},
		"required": ["response_title", "response_content"]
	}
	
func _get_history_array() -> Array:
	return _prepared_history
