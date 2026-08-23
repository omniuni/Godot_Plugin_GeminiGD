@tool
extends MarginContainer
class_name UiListItemNumeric

@onready var label: RichTextLabel = $Label
@onready var btn_copy: Button = $ButtonCopy

var _value: String = ""
var _index: int = -1

func _ready() -> void:
	btn_copy.hide()
	btn_copy.pressed.connect(_on_copy_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if label:
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		if not _value.is_empty():
			set_value(_value, _index)

func _on_mouse_entered() -> void:
	btn_copy.show()

func _on_mouse_exited() -> void:
	btn_copy.hide()

func get_value() -> String:
	return _value if not _value.is_empty() else (label.text if label else "")

func set_value(text_content: String, index: int = -1) -> void:
	_value = text_content
	_index = index
	if label:
		var has_num_prefix = false
		if index > 0:
			var prefix1 = str(index) + "."
			var prefix2 = str(index) + ")"
			var stripped = text_content.strip_edges()
			if stripped.begins_with(prefix1) or stripped.begins_with(prefix2) or stripped.begins_with("[b]" + prefix1) or stripped.begins_with("[b]" + prefix2):
				has_num_prefix = true
		if index > 0 and not has_num_prefix:
			label.text = str(index) + ". " + text_content
		else:
			label.text = text_content

func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(get_value())
	btn_copy.text = "Copied!"
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(btn_copy):
		btn_copy.text = "Copy"
