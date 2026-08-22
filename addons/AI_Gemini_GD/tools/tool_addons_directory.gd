@tool
extends GeminiToolBase
class_name ToolAddonsDirectory

func get_tool_name() -> String:
	return "addons_directory"

func get_tool_description() -> String:
	return "Retrieves information about installed addons in the Godot project. Gemini SHOULD use this tool to discover and inspect addon/plugin configurations, scripts, and documentation to assist with answering queries. When called with no arguments, returns a list of available addons with metadata from plugin.cfg. When 'search' is provided, searches inside addon files and returns matching file contents. Addon files are read-only and for reference/documentation only."

func get_cost() -> int:
	return 2

func get_parameters_schema() -> Dictionary:
	return {
		"type": "OBJECT",
		"properties": {
			"search_in": {
				"type": "ARRAY",
				"items": {
					"type": "STRING"
				},
				"description": "Optional list of addon names/folders to search in (e.g. ['dialogic']). If empty or omitted, searches all addons."
			},
			"search": {
				"type": "ARRAY",
				"items": {
					"type": "STRING"
				},
				"description": "Optional list of search terms to find in addon file contents. If empty or omitted, returns general list and metadata of all addons."
			}
		},
		"required": []
	}

func validate_arguments(args: Dictionary) -> Dictionary:
	if args.has("search_in") and not (args["search_in"] is Array):
		return {"valid": false, "error": "Parameter 'search_in' must be an array of strings if provided."}
	if args.has("search") and not (args["search"] is Array):
		return {"valid": false, "error": "Parameter 'search' must be an array of strings if provided."}
	return {"valid": true, "error": ""}

func execute(args: Dictionary) -> Dictionary:
	var search_in: Array = args.get("search_in", [])
	var search_terms_raw: Array = args.get("search", [])

	var search_terms: Array[String] = []
	for term in search_terms_raw:
		if term is String:
			var t = term.strip_edges()
			if not t.is_empty():
				search_terms.append(t.to_lower())

	var target_addons: Array[String] = []
	for a in search_in:
		if a is String:
			var name = a.strip_edges()
			if not name.is_empty():
				target_addons.append(name.to_lower())

	var addons_base = "res://addons"
	if not DirAccess.dir_exists_absolute(addons_base):
		return {
			"addons_found": 0,
			"addons": [],
			"message": "No res://addons/ directory found in the project."
		}

	# If no search terms, return overview of all addons
	if search_terms.is_empty():
		var addons_list: Array[Dictionary] = []
		var dir = DirAccess.open(addons_base)
		if dir:
			dir.list_dir_begin()
			var folder_name = dir.get_next()
			while folder_name != "":
				if dir.current_is_dir() and folder_name != "." and folder_name != ".." and folder_name != ".godot":
					var cfg_path = addons_base.path_join(folder_name).path_join("plugin.cfg")
					var addon_info = _read_plugin_cfg(folder_name, cfg_path)
					addons_list.append(addon_info)
				folder_name = dir.get_next()
			dir.list_dir_end()

		return {
			"addons_found": addons_list.size(),
			"addons": addons_list,
			"reminder": "Note: Addon files are read-only and provided for reference and documentation only."
		}

	# Search mode: search inside addon files
	var matched_files: Array[Dictionary] = []
	var dir = DirAccess.open(addons_base)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and folder_name != "." and folder_name != ".." and folder_name != ".godot":
				if target_addons.is_empty() or folder_name.to_lower() in target_addons:
					var addon_path = addons_base.path_join(folder_name)
					_search_addon_files(folder_name, addon_path, search_terms, matched_files)
			folder_name = dir.get_next()
		dir.list_dir_end()

	return {
		"search_terms": search_terms,
		"target_addons": target_addons if not target_addons.is_empty() else "all",
		"matched_file_count": matched_files.size(),
		"matched_files": matched_files,
		"reminder": "Note: Addon files are read-only and provided for reference and documentation only. Do not propose modifying addon files."
	}

func _read_plugin_cfg(addon_folder: String, cfg_path: String) -> Dictionary:
	var info = {
		"folder": addon_folder,
		"path": "res://addons/" + addon_folder,
		"has_plugin_cfg": false,
		"name": addon_folder,
		"description": "",
		"author": "",
		"version": "",
		"script": ""
	}

	if FileAccess.file_exists(cfg_path):
		var config = ConfigFile.new()
		var err = config.load(cfg_path)
		if err == OK:
			info["has_plugin_cfg"] = true
			info["name"] = config.get_value("plugin", "name", addon_folder)
			info["description"] = config.get_value("plugin", "description", "")
			info["author"] = config.get_value("plugin", "author", "")
			info["version"] = config.get_value("plugin", "version", "")
			info["script"] = config.get_value("plugin", "script", "")

	return info

func _search_addon_files(addon_name: String, path: String, search_terms: Array[String], out_files: Array[Dictionary]) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path = path.path_join(file_name)
			if dir.current_is_dir():
				if file_name != ".godot" and file_name != ".git":
					_search_addon_files(addon_name, full_path, search_terms, out_files)
			else:
				var ext = file_name.get_extension().to_lower()
				if ext in ["gd", "cfg", "json", "md", "txt", "tscn"]:
					var content = FileAccess.get_file_as_string(full_path)
					var content_lower = content.to_lower()
					var matched = false
					for term in search_terms:
						if term in content_lower:
							matched = true
							break
					if matched:
						out_files.append({
							"addon": addon_name,
							"file_path": full_path,
							"content": content
						})
		file_name = dir.get_next()
	dir.list_dir_end()
