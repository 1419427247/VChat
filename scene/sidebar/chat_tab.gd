class_name ChatTab extends Button

@export
var main : Main

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _pressed():
	var chat_data : ChatData
	if ResourceLoader.exists("user://chat/" + text + ".tres") == false:
		chat_data = ChatData.new()
		chat_data.title = text
	else:
		chat_data = ResourceLoader.load("user://chat/" + text + ".tres")
	main.chat.load_data(chat_data)
	main.sidebar.hide()

func _on_remove_button_pressed():
	DirAccess.remove_absolute("user://chat/" + text + ".tres")
	queue_free()
