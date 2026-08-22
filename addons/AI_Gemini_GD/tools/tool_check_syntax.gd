@tool
extends GeminiToolBase
class_name ToolCheckSyntax

const TEXT_EXTENSIONS = ["gd", "tscn", "tres", "json", "md", "txt", "cfg", "ini", "csv", "xml", "html", "shader", "gdshader"]
const BINARY_EXTENSIONS = ["png", "jpg", "jpeg", "webp", "svg", "ogg", "wav", "mp3", "ttf", "otf", "woff", "woff2", "res", "bin", "uid", "import"]

func get_tool_name() -> String:
	return "check_syntax"

func get_tool_description() -> String:
	return "Checks syntax, errors, and lint warnings for specified files and/or files matching search terms in the project. Returns matched files and any syntax errors or lint warnings found. At least one of 'specific_files' or 'search_terms' must be provided."

func get_cost() -> int:
	return 2

func get_parameters_schema() -> Dictionary:
	return {
		"type": "OBJECT",
		"properties": {
			"extension_filter": {
				"type": "STRING",
				"description": "File extension to filter by (e.g. 'gd', 'json', 'tscn', or '' for any text files). Must be provided."
			},
			"specific_files": {
				"type": "ARRAY",
				"items": {
					"type": "STRING"
				},
				"description": "Array of specific file paths (e.g. ['res://player.gd']). Can be empty if search_terms are provided."
			},
			"search_terms": {
				"type": "ARRAY",
				"items": {
					"type": "STRING"
				},
				"description": "Array of search strings to search inside file contents. Each string must be more than 3 characters. Can be empty if specific_files are provided."
			}
		},
		"required": ["extension_filter", "specific_files", "search_terms"]
	}

func validate_arguments(args: Dictionary) -> Dictionary:
	if not args.has("extension_filter") or not (args["extension_filter"] is String):
		return {"valid": false, "error": "Missing or invalid 'extension_filter' parameter (must be string)."}
	if not args.has("specific_files") or not (args["specific_files"] is Array):
		return {"valid": false, "error": "Missing or invalid 'specific_files' parameter (must be array)."}
	if not args.has("search_terms") or not (args["search_terms"] is Array):
		return {"valid": false, "error": "Missing or invalid 'search_terms' parameter (must be array)."}

	var specific_files: Array = args["specific_files"]
	var search_terms: Array = args["search_terms"]

	# Filter valid search terms (> 3 characters)
	var valid_search_terms = []
	for term in search_terms:
		if term is String and term.strip_edges().length() > 3:
			valid_search_terms.append(term.strip_edges())

	if specific_files.is_empty() and valid_search_terms.is_empty():
		return {
			"valid": false,
			"error": "At least one of 'specific_files' or 'search_terms' (with terms longer than 3 characters) must be non-empty."
		}

	return {"valid": true, "error": ""}

func execute(args: Dictionary) -> Dictionary:
	var ext_filter: String = args.get("extension_filter", "").strip_edges().to_lower()
	if ext_filter.begins_with("."):
		ext_filter = ext_filter.substr(1)

	var specific_files: Array = args.get("specific_files", [])
	var search_terms_raw: Array = args.get("search_terms", [])
	var treat_addons_as_project = ProjectSettings.get_setting("gemini_gd/advanced/treat_addons_as_project", false)
	
	var valid_search_terms: Array[String] = []
	for term in search_terms_raw:
		if term is String:
			var t = term.strip_edges()
			if t.length() > 3:
				valid_search_terms.append(t.to_lower())

	var matched_files: Dictionary = {}

	# 1. Process specific files
	for f in specific_files:
		if f is String:
			var path = f.strip_edges()
			if not path.begins_with("res://"):
				path = "res://" + path.trim_prefix("/")
			if FileAccess.file_exists(path):
				var file_ext = path.get_extension().to_lower()
				if ext_filter.is_empty() or file_ext == ext_filter:
					matched_files[path] = true

	# 2. Process search terms across project files
	if not valid_search_terms.is_empty():
		var all_files: Array[String] = []
		_collect_files("res://", all_files, ext_filter, treat_addons_as_project)
		for file_path in all_files:
			if matched_files.has(file_path):
				continue
			var file_ext = file_path.get_extension().to_lower()
			if file_ext in BINARY_EXTENSIONS:
				continue
			var content = FileAccess.get_file_as_string(file_path)
			var content_lower = content.to_lower()
			for term in valid_search_terms:
				if term in content_lower:
					matched_files[file_path] = true
					break

	# 3. Check syntax and lint for all matched files
	var results: Array[Dictionary] = []
	for file_path in matched_files.keys():
		var file_report = _check_file_syntax_and_lint(file_path)
		results.append(file_report)

	return {
		"total_matched_files": results.size(),
		"files_checked": results,
		"guidance": "Note: Do not assume the user wants pre-existing warnings or errors fixed unless requested. Alert the user that they can be addressed if desired. If any warnings/errors relate to newly suggested code, explain how to resolve them."
	}

func _collect_files(dir_path: String, out_list: Array[String], ext_filter: String, treat_addons: bool) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path = dir_path.path_join(file_name)
			if dir.current_is_dir():
				if file_name != ".godot" and file_name != ".git":
					if file_name != "addons" or treat_addons:
						_collect_files(full_path, out_list, ext_filter, treat_addons)
			else:
				var ext = file_name.get_extension().to_lower()
				if ext_filter.is_empty():
					if ext in TEXT_EXTENSIONS:
						out_list.append(full_path)
				else:
					if ext == ext_filter:
						out_list.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

func _check_file_syntax_and_lint(file_path: String) -> Dictionary:
	var ext = file_path.get_extension().to_lower()
	var report = {
		"file_path": file_path,
		"extension": ext,
		"valid": true,
		"errors": [],
		"warnings": []
	}

	if not FileAccess.file_exists(file_path):
		report["valid"] = false
		report["errors"].append("File not found on disk.")
		return report

	if ext in BINARY_EXTENSIONS:
		report["warnings"].append("Binary asset file (skipped text syntax/lint analysis).")
		return report

	var content = FileAccess.get_file_as_string(file_path)

	if ext == "gd":
		_check_gdscript(file_path, content, report)
	elif ext == "json":
		_check_json(content, report)
	elif ext == "tscn" or ext == "tres":
		_check_scene_resource(file_path, content, report)
	else:
		# Generic text file check
		if content.is_empty():
			report["warnings"].append("File is empty.")

	return report

func _check_gdscript(file_path: String, content: String, report: Dictionary) -> void:
	# Avoid global class_name collision when checking in-memory script
	var sanitized_code = _sanitize_gdscript_for_checking(content)
	var script = GDScript.new()
	script.source_code = sanitized_code
	var reload_err = script.reload()
	if reload_err != OK:
		report["valid"] = false
		report["errors"].append("GDScript syntax/compile error (Code " + str(reload_err) + ").")

	# Linting checks
	var lines = content.split("\n")
	var has_mixed_tabs_spaces = false
	for i in range(lines.size()):
		var line = lines[i]
		var line_num = i + 1
		
		if line.begins_with(" ") and "\t" in line.left(line.length() - line.strip_edges(true, false).length()):
			has_mixed_tabs_spaces = true

		if line.strip_edges().begins_with("print(") or line.strip_edges().begins_with("print_debug("):
			report["warnings"].append("Line " + str(line_num) + ": Stray print statement found.")

	if has_mixed_tabs_spaces:
		report["warnings"].append("Mixed tabs and spaces indentation detected.")

func _sanitize_gdscript_for_checking(content: String) -> String:
	var lines = content.split("\n")
	for i in range(lines.size()):
		var trimmed = lines[i].strip_edges()
		if trimmed.begins_with("class_name "):
			lines[i] = "# " + lines[i]
	return "\n".join(lines)

func _check_json(content: String, report: Dictionary) -> void:
	var json = JSON.new()
	var err = json.parse(content)
	if err != OK:
		report["valid"] = false
		report["errors"].append("JSON parse error at line " + str(json.get_error_line()) + ": " + json.get_error_message())

func _check_scene_resource(file_path: String, content: String, report: Dictionary) -> void:
	if not content.begins_with("[gd_scene") and not content.begins_with("[gd_resource"):
		report["warnings"].append("File header does not begin with standard [gd_scene] or [gd_resource] header.")
	if not ResourceLoader.exists(file_path):
		report["warnings"].append("Resource cannot be resolved by ResourceLoader.")
