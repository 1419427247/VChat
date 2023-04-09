class_name Sidebar extends Button

const CHAT_TAB : PackedScene = preload("res://scene/sidebar/chat_tab.tscn")

@onready var tab_v_box_container : VBoxContainer = %TabVBoxContainer

@export
var main : Main
func _ready():
	refresh()
		
func refresh():
	for child in tab_v_box_container.get_children():
		child.queue_free()
	DirAccess.make_dir_recursive_absolute("user://chat")
	var files : PackedStringArray = DirAccess.get_files_at("user://chat/")
	for file_name in files:
		file_name = file_name.replace(".tres","")
		var chat_tab : ChatTab = CHAT_TAB.instantiate()
		chat_tab.main = main
		chat_tab.text = file_name
		tab_v_box_container.add_child(chat_tab)
		
func _process(delta):
	pass

func _on_config_button_pressed():
	main.config.show()

func _on_exit_button_pressed():
	get_tree().quit()

func _pressed():
	hide()

func _on_new_chat_button_pressed():
	var chat_tab : ChatTab = CHAT_TAB.instantiate()
	chat_tab.main = main
	chat_tab.text = str("未命名",randi())
	tab_v_box_container.add_child(chat_tab)

