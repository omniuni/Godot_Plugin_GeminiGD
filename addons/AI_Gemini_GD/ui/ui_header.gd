@tool
extends MarginContainer
class_name UiHeader

@onready var label: RichTextLabel = $Label
@onready var btn_copy: Button = $ButtonCopy

var _value: String = ""

func _ready() -> void:
	btn_copy.hide()
	btn_copy.pressed.connect(_on_copy_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if label:
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		_sync_font_sizes()
		if not _value.is_empty():
			label.text = _value

func _sync_font_sizes() -> void:
	if not is_instance_valid(label):
		return
	var base_size: int = 0
	if label.has_theme_font_size_override("normal_font_size"):
		base_size = label.get_theme_font_size("normal_font_size")
	elif label.has_theme_font_size("normal_font_size"):
		base_size = label.get_theme_font_size("normal_font_size")
	
	if base_size > 0:
		label.add_theme_font_size_override("normal_font_size", base_size)
		label.add_theme_font_size_override("bold_font_size", base_size)
		label.add_theme_font_size_override("italics_font_size", base_size)
		label.add_theme_font_size_override("bold_italics_font_size", base_size)
		label.add_theme_font_size_override("mono_font_size", base_size)

func _on_mouse_entered() -> void:
	btn_copy.show()

func _on_mouse_exited() -> void:
	btn_copy.hide()
	
func set_value(header: String) -> void:
	_value = header
	if label:
		label.text = header
	
func get_value() -> String:
	return _value if not _value.is_empty() else (label.text if label else "")

func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(get_value())
	btn_copy.text = "Copied!"
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(btn_copy):
		btn_copy.text = "Copy"
