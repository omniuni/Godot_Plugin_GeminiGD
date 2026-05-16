@tool
extends MarginContainer
class_name UiHeader

@onready var label: Label = $Label
@onready var btn_copy: Button = $ButtonCopy

func _ready() -> void:
	btn_copy.hide()
	btn_copy.pressed.connect(_on_copy_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	btn_copy.show()

func _on_mouse_exited() -> void:
	btn_copy.hide()
	
func set_value(header: String):
	label.text = header
	
func get_value() -> String:
	return label.text

func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(label.text)
	btn_copy.text = "Copied!"
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(btn_copy):
		btn_copy.text = "Copy"
