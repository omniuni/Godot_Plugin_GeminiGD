extends GeminiClientBase
class_name GeminiClientQuery

var _prepare_context: bool = false
var _prepare_only_current: bool = false
var _prepare_active_files: bool = false
var _prepare_scan: bool = false
var _prepare_scan_terms: Array = []
var _history: Array = []

func configure(context: bool, current: bool, active: bool, scan: bool, terms: Array):
	_prepare_context = context
	_prepare_only_current = current
	_prepare_active_files = active
	_prepare_scan = scan
	_prepare_scan_terms = terms
	pass
	
func set_history(history: Array):
	_log("[" + _get_client_name() + "] got history!")
	_history = history
	_log("[" + _get_client_name() + "] history details: " + str(history))
	pass

var _prepared_history: Array = []

func prepare() -> void:
	EditorInterface.save_all_scenes()
	
	var context_parts = []
	var added_paths = {}
	var files_in_scan = []
	var active_open_files = []
	
	if _prepare_context:
		if _prepare_only_current:
			var instance_script_editor: ScriptEditor = EditorInterface.get_script_editor()
			var active_script = instance_script_editor.get_current_script()
			if active_script:
				context_parts.append("The Active Script is " + active_script.resource_path)
				context_parts.append("Script Resource: " + active_script.resource_path + "\nContents:\n" + active_script.source_code + "\n")
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
								
						if not file_matched and ext in ["tscn", "cfg", "gd", "json", "txt"]:
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

	var context_string = "\n".join(context_parts)
	var final_history = _history.duplicate(true)
	if not context_string.is_empty():
		final_history.append({
			"user": context_string,
			"assistant": ""
		})
	_prepared_history = final_history

	# Generate and output the nice debug summary
	
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
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var full_path = path.path_join(file_name)
				if dir.current_is_dir():
					if file_name != ".godot" and file_name != ".git":
						_scan_dir(full_path, file_list)
				else:
					var ext = file_name.get_extension().to_lower()
					if ext in ["tscn", "cfg", "gd", "json", "txt", "png", "svg", "jpg", "jpeg", "webp"]:
						file_list.append(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()

func _get_system_prompt():
	var engine_version = Engine.get_version_info().string
	return "
	This is a code assistant for Godot Engine, the Godot Game Engine.
	This is for Godot "+engine_version+". Check that the methods used are for version "+engine_version+"
	
	The response_title is a very short summary of the topic of the response.
	
	Respond to the prompt returning content as an array of objects,
	with each object having a type and value.
	This is the only way to provide formatting.
	Do not use Markdown, HTML, or any other formatting.
	The available types are: header, text, list_item_bullet, list_item_numeric, code, code_edit
	
	The active script and active scene are the most likely subject if no specific context is specified.
	
	Code must be formatted with whitespace as per the original file.
	When being asked for code changes, be thorough, making multiple changes in different files or different locations of the file if necessary.
	Files and resources ending in .gd are GDScript. GDScript is whitespace sensitive.
	
	`code_edit` is a special type indicating that the code block should edit by adding or replacing existing code in the file.
	`code_edit` must specify the fields code_original_file and code_original_reference which will replace code_original_reference with the content_value in the code_original_file as specified with the full script resource path.
	code_original_reference must exactly and fully match the code that is being replaced.
	code_original_reference must contain at least two lines of existing code before and after the region that will be changed to ensure accurate matching.
	Use multiple `code_edit` entries when different parts of the file should be replaced or added so the user has more control over what to apply.
	If only a couple of lines need to change, show those as an independent `code_edit`
	Include surrounding lines of code in `code_edit` and code_original_reference for context and to ensure correct replacement.
	
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
						"code_original_reference": {"type": "string"}
					},
					"required": ["response_content_type", "response_content_value"]
				}
			}
		},
		"required": ["response_title", "response_content"]
	}
	
func _get_history_array() -> Array:
	return _prepared_history
