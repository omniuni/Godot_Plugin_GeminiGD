@tool
extends GeminiToolBase
class_name ToolProjectStructure

func get_tool_name() -> String:
	return "project_structure"

func get_tool_description() -> String:
	return "Returns the file and directory structure of the Godot project within res://. Requires a 'filter' argument specifying a file extension or '' for all files. An argument must be supplied."

func get_cost() -> int:
	return 1

func requires_arguments() -> bool:
	return true

func get_missing_arguments_error() -> String:
	return "The 'filter' argument is required for tool 'project_structure'. Provide a file extension (e.g. 'gd', 'tscn') or an empty string '' to list all files."

func get_parameters_schema() -> Dictionary:
	return {
		"type": "OBJECT",
		"properties": {
			"filter": {
				"type": "STRING",
				"description": "File extension to filter by or '' for all files. An argument must be provided."
			}
		},
		"required": ["filter"]
	}

func validate_arguments(args: Dictionary) -> Dictionary:
	if not args.has("filter") or args["filter"] == null or typeof(args["filter"]) != TYPE_STRING:
		return {"valid": false, "error": get_missing_arguments_error()}
	return {"valid": true, "error": ""}

func execute(args: Dictionary) -> Dictionary:
	var filter_ext: String = args.get("filter", "").strip_edges().to_lower()
	if filter_ext.begins_with("."):
		filter_ext = filter_ext.substr(1)

	var treat_addons_as_project = ProjectSettings.get_setting("gemini_gd/advanced/treat_addons_as_project", false)

	var files: Array[String] = []
	_scan_directory("res://", filter_ext, files, treat_addons_as_project)

	var tree_representation = _build_tree_string(files)

	return {
		"filter_applied": filter_ext if not filter_ext.is_empty() else "all",
		"file_count": files.size(),
		"project_tree": tree_representation
	}

func _scan_directory(path: String, filter_ext: String, result: Array[String], treat_addons: bool) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path = path.path_join(file_name)
			if dir.current_is_dir():
				if file_name != ".godot" and file_name != ".git" and file_name != ".import":
					if file_name != "addons" or treat_addons:
						_scan_directory(full_path, filter_ext, result, treat_addons)
			else:
				if filter_ext.is_empty():
					result.append(full_path)
				else:
					if file_name.get_extension().to_lower() == filter_ext:
						result.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

func _build_tree_string(files: Array[String]) -> String:
	if files.is_empty():
		return "(No matching files found)"
	files.sort()
	var lines: Array[String] = ["res://"]
	for file_path in files:
		var rel_path = file_path.trim_prefix("res://")
		lines.append("  " + rel_path)
	return "\n".join(lines)
