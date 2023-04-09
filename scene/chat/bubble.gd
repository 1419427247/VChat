class_name Bubble extends Container

const USER : String = "user"
const ASSISTANT : String = "assistant"

@onready var label  :Label = %Label
@onready var head_texture_rect = %HeadTextureRect

@export
var main : Main

@export
var role : String = USER

func get_role() -> String:
	return role

func get_content() -> String:
	return label.text

func add_content(_value : String,_duration : float = 0.0):
	label.text += _value
	if _duration > 0:
		var tween : Tween = create_tween()
		label.visible_characters = label.get_total_character_count() - _value.length()
		tween.tween_property(label,"visible_characters",label.get_total_character_count(),_duration)

func _ready():
	if role == USER:
		layout_direction = Control.LAYOUT_DIRECTION_LTR
	else:
		layout_direction = Control.LAYOUT_DIRECTION_RTL
		head_texture_rect.texture = preload("res://icon_128.png")

func _on_delete_button_pressed():
	queue_free()

func _on_copy_button_pressed():
	DisplayServer.clipboard_set(label.text)
	main.toast.make_text("已将内容复制到剪切板")
