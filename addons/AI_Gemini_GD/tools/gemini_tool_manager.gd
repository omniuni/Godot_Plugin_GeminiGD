@tool
extends RefCounted
class_name GeminiToolManager

const SETTING_ALLOW_TOOL_USE = "gemini_gd/tools/allow_tool_use"
const SETTING_TOOL_ALLOWANCE = "gemini_gd/tools/tool_use_allowance"
const SETTING_ENABLE_PROJECT_STRUCTURE = "gemini_gd/tools/enable_tool_project_structure"
const SETTING_ENABLE_CHECK_SYNTAX = "gemini_gd/tools/enable_tool_check_syntax"
const SETTING_ENABLE_ADDONS_DIRECTORY = "gemini_gd/tools/enable_tool_addons_directory"
const SETTING_BEHAVIOR_DEBUG = "gemini_gd/debugging/behavior_debugging"
const SETTING_REQUEST_DEBUG = "gemini_gd/debugging/request_debugging"

var _tools: Dictionary = {}
var _max_allowance: int = 30
var _allowance_remaining: int = 30
var _allowance_used: int = 0
var _last_tool_name: String = ""
var _last_tool_args: Dictionary = {}

func _init() -> void:
	_load_settings()
	_register_default_tools()

func _load_settings() -> void:
	_max_allowance = ProjectSettings.get_setting(SETTING_TOOL_ALLOWANCE, 30)
	if _max_allowance < 1:
		_max_allowance = 30
	_allowance_remaining = _max_allowance
	_allowance_used = 0

func _register_default_tools() -> void:
	if ProjectSettings.get_setting(SETTING_ENABLE_PROJECT_STRUCTURE, true):
		register_tool(ToolProjectStructure.new())
	if ProjectSettings.get_setting(SETTING_ENABLE_CHECK_SYNTAX, true):
		register_tool(ToolCheckSyntax.new())
	if ProjectSettings.get_setting(SETTING_ENABLE_ADDONS_DIRECTORY, true):
		register_tool(ToolAddonsDirectory.new())

static func get_tool_counts() -> Dictionary:
	var total = 3
	var enabled = 0
	if ProjectSettings.get_setting(SETTING_ENABLE_PROJECT_STRUCTURE, true):
		enabled += 1
	if ProjectSettings.get_setting(SETTING_ENABLE_CHECK_SYNTAX, true):
		enabled += 1
	if ProjectSettings.get_setting(SETTING_ENABLE_ADDONS_DIRECTORY, true):
		enabled += 1
	return {"enabled": enabled, "total": total}

func register_tool(tool: GeminiToolBase) -> void:
	_tools[tool.get_tool_name()] = tool

func is_tool_use_allowed() -> bool:
	return ProjectSettings.get_setting(SETTING_ALLOW_TOOL_USE, true)

func get_max_allowance() -> int:
	return _max_allowance

func get_allowance_remaining() -> int:
	return _allowance_remaining

func get_allowance_used() -> int:
	return _allowance_used

func has_allowance() -> bool:
	return _allowance_remaining > 0

func get_tool(tool_name: String) -> GeminiToolBase:
	return _tools.get(tool_name, null)

func get_tool_declarations() -> Array:
	if not is_tool_use_allowed() or not has_allowance():
		return []
	var declarations = []
	for tool_name in _tools:
		var tool: GeminiToolBase = _tools[tool_name]
		declarations.append(tool.get_declaration())
	if declarations.is_empty():
		return []
	return [{"functionDeclarations": declarations}]

func execute_tool(tool_name: String, args: Dictionary) -> Dictionary:
	_log("[GeminiToolManager] Requested tool: '" + tool_name + "' with args: " + str(args))

	if not _tools.has(tool_name):
		var err_msg = "Error: Tool '" + tool_name + "' is not recognized or is disabled."
		_log("[GeminiToolManager] " + err_msg)
		return {"error": err_msg}

	var tool: GeminiToolBase = _tools[tool_name]

	# Safeguard: Missing arguments
	var validation = tool.validate_arguments(args)
	if not validation["valid"]:
		var err_msg: String = validation["error"]
		_log("[GeminiToolManager] Safeguard blocked (missing arguments): " + err_msg)
		return {"error": err_msg}

	# Safeguard: Prevent calling the same tool twice in a row with the same arguments
	if tool_name == _last_tool_name and _are_args_equal(args, _last_tool_args):
		var err_msg = "Safeguard: Tool '" + tool_name + "' was just executed with identical arguments. Do not repeat the same tool call with identical arguments."
		_log("[GeminiToolManager] Safeguard blocked (duplicate call): " + err_msg)
		return {"error": err_msg}

	# Check allowance
	var cost = tool.get_cost()
	if _allowance_remaining < cost:
		var err_msg = "Tool allowance exhausted. Cannot execute tool '" + tool_name + "' (cost " + str(cost) + ", remaining " + str(_allowance_remaining) + ")."
		_log("[GeminiToolManager] " + err_msg)
		return {"error": err_msg}

	# Record last call
	_last_tool_name = tool_name
	_last_tool_args = args.duplicate(true)

	# Deduct cost
	_allowance_remaining -= cost
	_allowance_used += cost

	# Execute
	var result = tool.execute(args)
	if ProjectSettings.get_setting(SETTING_REQUEST_DEBUG, false):
		_log("[GeminiToolManager] Tool '" + tool_name + "' completed. Result: " + str(result))
	else:
		_log("[GeminiToolManager] Tool '" + tool_name + "' completed.")
	_log("[GeminiToolManager] Tool allowance remaining: " + str(_allowance_remaining) + " / " + str(_max_allowance))

	return result

func _are_args_equal(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for k in a:
		if not b.has(k):
			return false
		if a[k] != b[k]:
			return false
	return true

# Instructions, Allowance Status and Warnings configuration
func get_tool_system_instructions() -> String:
	return """
	You have access to tools to inspect and navigate the Godot project and help answer queries.
	Total Tool Allowance: """ + str(_max_allowance) + """
	Current Tool Allowance Remaining: """ + str(_allowance_remaining) + """
	Use tools when needed to explore the project structure, inspect files, or verify implementations.
	Only call tools when necessary. Each tool has an allowance cost.
	When you have sufficient information to answer the user request, finish by generating your final formatted response.
	"""

func get_turn_statement() -> String:
	var msg = "TOOL USE STATUS: Remaining tool use allowance is " + str(_allowance_remaining) + " out of " + str(_max_allowance) + "."
	var warning = get_warning_statement()
	if not warning.is_empty():
		msg += " " + warning
	return msg

func get_warning_statement() -> String:
	if _allowance_remaining <= 0:
		return get_exhausted_instruction()
	elif _allowance_remaining <= int(_max_allowance / 5.0):
		return get_warning_one_fifth()
	elif _allowance_remaining <= int(_max_allowance / 3.0):
		return get_warning_one_third()
	return ""

func get_warning_one_third() -> String:
	return "TOOL USE WARNING: You have 1/3 or less of your tool use allowance remaining (" + str(_allowance_remaining) + " remaining). Use remaining tool calls judiciously and prepare your final response."

func get_warning_one_fifth() -> String:
	return "TOOL USE URGENT WARNING: You have 1/5 or less of your tool use allowance remaining (" + str(_allowance_remaining) + " remaining). Conclude tool usage promptly and generate the final response."

func get_exhausted_instruction() -> String:
	return "TOOL USE ALLOWANCE EXHAUSTED: You have reached the maximum tool allowance. Do not call any further tools. You must now generate your final formatted response immediately based on the gathered information."

func _log(msg: String) -> void:
	if ProjectSettings.get_setting(SETTING_BEHAVIOR_DEBUG, false):
		print(msg)
