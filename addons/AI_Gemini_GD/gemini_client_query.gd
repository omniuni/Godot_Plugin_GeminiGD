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
	print('got history!')
	_history = history
	print(str(history))
	pass

#AIDO: Finish migrating from gemini_client.gd
func prepare() -> void:
	EditorInterface.save_all_scenes()
	
	#AIDO: Construct the parts array for the user message
	
	#AIDO: if _prepare_context is false, done preparing.
	
	#AIDO: if _prepare_only_current is true, get the active script, and only add that and return
	
	#AIDO: if _prepare_active_files is true, get all the active files and scenes, and add them
	
	#AIDO: if _prepare_scan is true, get a list of ALL .tscn, .cfg, .gd, .json, .txt, and image files in the project directory
	# unless a file has already been added in _prepare_active_files, check the file name, location, and content (for text files) to see if it contains any of the _prepare_scan_terms
	# if the file matches the scan terms, include the file and its content as a user message
	
	#AIDO: cache this array of user parts
	
	var instance_script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var active_script = instance_script_editor.get_current_script()
	var active_scene = EditorInterface.get_edited_scene_root()
	var open_scripts = instance_script_editor.get_open_scripts()
	var open_scenes_paths = EditorInterface.get_open_scenes()
	var open_scenes = []
	for path in open_scenes_paths:
		var scene = load(path)
		if scene:
			open_scenes.append(scene)
			
			
	
	
			
	pass

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
	
#AIDO: assemble the history by looping over the history provided (see gemini_client.gd for old implementation)
# and then add the user parts from the prepare() function
func _get_history_array():
	return []
