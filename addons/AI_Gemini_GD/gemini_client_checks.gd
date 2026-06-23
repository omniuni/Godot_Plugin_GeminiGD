extends GeminiClientBase
class_name GeminiClientChecks

func prepare() -> void:
	
	pass
	
func _get_system_prompt():
	var engine_version = Engine.get_version_info().string
	return "
	This is a code assistant for Godot Engine, the Godot Game Engine.
	This is for Godot "+engine_version+". Check that the methods used are for version "+engine_version+"
	"
	pass
	
func _get_schema():
	return  {
		"type": "object",
		"properties": {
			"query_requires_context": {"type": "boolean"},
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
	return []
