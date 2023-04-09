class_name Config extends Panel

@export
var config_data : ConfigData

@export
var main : Main

@onready var theme_option_button : OptionButton = %ThemeOptionButton
@onready var font_size_spin_box : SpinBox = %FontSizeSpinBox
@onready var scale_spin_box = %ScaleSpinBox
@onready var ip_edit : LineEdit = %IPEdit
@onready var token_line_edit = %TokenLineEdit

func _ready():
	get_tree().root.size_changed.connect(
		func():
			scale_spin_box.value = float(get_window().size.x) / 375.0 / 1.14
	)
	
	_load()

func _process(delta):
	pass

func _save():
	config_data = ConfigData.new()
	config_data.theme_type = theme_option_button.get_selected()
	config_data.font_size = font_size_spin_box.value
	config_data.scale = float(get_window().size.x) / 375.0 / 1.14
	config_data.ip = ip_edit.text
	config_data.token = token_line_edit.text
	ResourceSaver.save(config_data,"user://config.tres")

func _load():
	if ResourceLoader.exists("user://config.tres") == false:
		_save()
	config_data = ResourceLoader.load("user://config.tres")
	theme_option_button.select(config_data.theme_type)
	match config_data.theme_type:
		ConfigData.ThemeType.DARK:
			main.theme = preload("res://asset/dark.tres")
		ConfigData.ThemeType.LIGHT:
			main.theme = preload("res://asset/light.tres")
		ConfigData.ThemeType.WIN95:
			main.theme = preload("res://asset/win95.tres")
	main.theme.default_font_size = config_data.font_size
	font_size_spin_box.value = (config_data.font_size)
	scale_spin_box.value = (config_data.scale)
#	get_window().content_scale_factor = config_data.scale / 1.14
	ip_edit.text = config_data.ip
	token_line_edit.text = config_data.token

func _on_get_token_button_pressed():
	var data : Dictionary = {
		"type" : "get_token_request_message",
		"content" : {
			"count" : 15
		}
	}
	main.send_message(
		data,
		Callable(func(_data : Dictionary):
			token_line_edit.text = _data["content"]["token"])
	)

func _on_theme_option_button_item_selected(_index : int):
	config_data.theme_type = _index
	match _index:
		ConfigData.ThemeType.DARK:
			main.theme = preload("res://asset/dark.tres")
		ConfigData.ThemeType.LIGHT:
			main.theme = preload("res://asset/light.tres")
		ConfigData.ThemeType.WIN95:
			main.theme = preload("res://asset/win95.tres")

func _on_font_size_spin_box_value_changed(_value : float):
	main.theme.default_font_size = _value
	
func _on_scale_spin_box_value_changed(_value : float):
	get_window().content_scale_factor = _value

func _on_ip_edit_text_changed(_new_text : String):
	config_data.ip = _new_text

func _on_reset_to_default_pressed():
	theme_option_button.select(ConfigData.ThemeType.LIGHT)
	font_size_spin_box.value = 24
	scale_spin_box.value = float(get_window().size.x) / 375.0 / 1.14
	ip_edit.text = "http://43.134.177.245:8080"
	_save()
	_load()

func _on_cancel_pressed():
	_save()
	hide()


