extends GeminiClientBase
class_name GeminiClientChecks

var _current_file = ""
var _current_content = ""
var _explicit_files: Array = []

func set_explicit_files(files: Array) -> void:
	_explicit_files = files

func prepare() -> void:
	EditorInterface.save_all_scenes()
	var instance_script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var active_script = instance_script_editor.get_current_script()
	if active_script:
		_current_file = active_script.resource_path
		_current_content = active_script.source_code
	else:
		_current_file = ""
		_current_content = ""
		
	var summary = "=== GEMINI CLIENT CHECKS DEBUG SUMMARY ===\n"
	summary += "Model URL: " + _url + "\n"
	summary += "Active Script File: " + (_current_file if not _current_file.is_empty() else "None") + "\n"
	if not _explicit_files.is_empty():
		summary += "Explicitly Added Files:\n"
		for f in _explicit_files:
			summary += "  - " + str(f) + "\n"
	summary += "=========================================="
	_log(summary)
	pass
	
func _get_system_prompt():
	var engine_version = Engine.get_version_info().string
	return "
	This is a code assistant for Godot Engine, the Godot Game Engine.
	This is for Godot "+engine_version+". Check that the methods used are for version "+engine_version+"
	The goal is NOT to answer the prompt or question, only to determine what is necessary to answer most effectively.
	
	If the prompt or question can be answered with general knowledge, `query_requires_context` is `false`.
	This includes cases where there is a general request such as what engine-level function is best for a purpose or where to find a standard feature.
	
	If it appears that the query or prompt is referring specifically to a file or scene that is open and active,
	then `query_requires_active_files` is `true` and all active files will be provided as context.
	
	If only the one active file is required, and no other open or active files, `query_requires_only_current` is true.
	
	`query_requires_file_scan` is true when the query may require general project context, not just what is open.
	If `query_requires_file_scan` is true, a list of `file_scan_search_terms` must be returned.
	
	`file_scan_search_terms` should include specific short key words, phrases, functions, or variables
	that can be used to determine what files will be provided as context. Files with any of these terms
	matched will be submitted as context to answer the prompt.
	"
	pass
	
func _get_schema():
	return  {
		"type": "object",
		"properties": {
			"query_requires_context": {"type": "boolean"},
			"query_requires_only_current": {"type": "boolean"},
			"query_requires_active_files": {"type": "boolean"},
			"query_requires_file_scan": {"type": "boolean"},
			"file_scan_search_terms": {
				"type": "array",
				"items": {
					"type": "string"
				}
			}
		},
		"required": ["query_requires_context", "query_requires_active_files","query_requires_file_scan","file_scan_search_terms"]
	}
	
func _get_history_array():
	var history = []
	if not _current_file.is_empty():
		history.append({
			"user": "Active Script Resource: " + _current_file + "\nContents:\n" + _current_content + "\n"
		})
	for file_path in _explicit_files:
		if file_path is String and file_path != _current_file and FileAccess.file_exists(file_path):
			var ext = file_path.get_extension().to_lower()
			if ext in ["png", "jpg", "jpeg", "webp", "svg"]:
				history.append({
					"user": "Explicit Image Resource: " + file_path
				})
			else:
				var content = FileAccess.get_file_as_string(file_path)
				history.append({
					"user": "Explicit File Resource: " + file_path + "\nContents:\n" + content + "\n"
				})
	return history
