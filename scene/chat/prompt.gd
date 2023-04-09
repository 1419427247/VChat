class_name Prompt extends PanelContainer

@onready var option_button : OptionButton = $MarginContainer/HBoxContainer/OptionButton
@onready var text_edit = $MarginContainer/HBoxContainer/TextEdit

func get_role() -> String:
	return option_button.get_item_text(option_button.selected)

func get_content() -> String:
	return text_edit.text

func set_content(_value : String):
	text_edit.text = _value

func _on_button_pressed():
	queue_free()
