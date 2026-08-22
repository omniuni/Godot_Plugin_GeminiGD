@tool
extends RefCounted
class_name GeminiToolBase

func get_tool_name() -> String:
	return ""

func get_tool_description() -> String:
	return ""

func get_parameters_schema() -> Dictionary:
	return {}

func get_cost() -> int:
	return 1

func requires_arguments() -> bool:
	return false

func get_missing_arguments_error() -> String:
	return "Tool '" + get_tool_name() + "' requires arguments but none were provided."

func get_declaration() -> Dictionary:
	return {
		"name": get_tool_name(),
		"description": get_tool_description(),
		"parameters": get_parameters_schema()
	}

func validate_arguments(args: Dictionary) -> Dictionary:
	if requires_arguments():
		if args.is_empty():
			return {"valid": false, "error": get_missing_arguments_error()}
	return {"valid": true, "error": ""}

func execute(args: Dictionary) -> Dictionary:
	return {}
