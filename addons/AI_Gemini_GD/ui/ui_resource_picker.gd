@tool
extends EditorResourcePicker
class_name UiResourcePicker

func _set_create_options(_menu_node: Object) -> void:
	# Overriding with empty body suppresses all "New [Resource]" creation options
	pass
