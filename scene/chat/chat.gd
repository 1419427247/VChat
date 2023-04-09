class_name Chat extends Panel

const PROMPT_PACKED_SCENE : PackedScene = preload("res://scene/chat/prompt.tscn")
const BUBBLE_PACKED_SCENE : PackedScene = preload("res://scene/chat/bubble.tscn")

@export
var main : Main

@onready var titel_line_edit = %TitelLineEdit
@onready var config_panel_container : PanelContainer = %ConfigPanelContainer
@onready var system_message_text_edit = %SystemMessageTextEdit
@onready var temperature_h_slider = %TemperatureHSlider
@onready var frequency_penalty_h_slider = %FrequencyPenaltyHSlider
@onready var presence_penalty_h_slider = %PresencePenaltyHSlider



@onready var prompt_v_box_container = %PromptVBoxContainer
@onready var prompt_scroll_container = %PromptScrollContainer

@onready var input_text_edit = %InputTextEdit
@onready var bubble_scroll_container : ScrollContainer = %BubbleScrollContainer
@onready var bubble_v_box_container : VBoxContainer = %BubbleVBoxContainer


func _ready():
	var files : PackedStringArray = DirAccess.get_files_at("user://chat/")
	if files.size() > 0:
		var chat_data = ResourceLoader.load("user://chat/" + files[0])
		load_data(chat_data)

var key : String
var response_bubble : Bubble

func push_bubble(_text : String,_rule : String) -> Bubble:
	var bubble : Bubble
	bubble = BUBBLE_PACKED_SCENE.instantiate()
	bubble.role = _rule
	bubble.main = main
	bubble_v_box_container.add_child(bubble)
	bubble.add_content(_text)
	slide_to_bottom()
	return bubble

func set_title(_value : String):
	titel_line_edit.text = _value

func get_title() -> String:
	return titel_line_edit.text

func save_data() -> ChatData:
	var chat_data = ChatData.new()
	chat_data.title = titel_line_edit.text
	chat_data.system_prompt = system_message_text_edit.text
	chat_data.temperature = temperature_h_slider.value
	for prompt in prompt_v_box_container.get_children():
		if prompt is Prompt:
			chat_data.prompt_array.append(prompt.get_content())
	for bubble in bubble_v_box_container.get_children():
		if bubble is Bubble:
			chat_data.bubble_array.append(JSON.stringify({
				"role" : bubble.get_role(),
				"content" : bubble.get_content()
			}))
	ResourceSaver.save(chat_data,"user://chat/" + titel_line_edit.text + ".tres")
	main.sidebar.refresh()
	return chat_data

func load_data(_value : ChatData) -> void:
	key = ""
	response_bubble = null
	for child in bubble_v_box_container.get_children():
		child.queue_free()
	for child in prompt_v_box_container.get_children():
		child.queue_free()
	titel_line_edit.text = _value.title
	system_message_text_edit.text = _value.system_prompt
	temperature_h_slider.value = _value.temperature
	for prompt_string in _value.prompt_array:
		var prompt : Prompt = PROMPT_PACKED_SCENE.instantiate()
		prompt_v_box_container.add_child(prompt)
		prompt.add_content(prompt_string)
	
	for bubble_string in _value.bubble_array:
		var bubble_dictionary : Dictionary = JSON.parse_string(bubble_string)
		push_bubble(bubble_dictionary["content"],bubble_dictionary["role"])
	slide_to_bottom()
	
func _on_config_button_pressed():
	if config_panel_container.visible == true:
		config_panel_container.hide()
	else:
		config_panel_container.show()

func _on_more_button_pressed():
	main.sidebar.show()
	save_data()

func _on_new_prompt_button_pressed():
	var prompt : Prompt = PROMPT_PACKED_SCENE.instantiate()
	prompt_v_box_container.add_child(prompt)
	slide_to_bottom()
	save_data()

func _on_send_button_pressed():
	if input_text_edit.text == "":
		main.toast.make_text("请输入消息哦")
		return
	if key != "":
		main.toast.make_text("等回复完了再发新的消息哦")
		return
	main.toast.make_text("正在回复中，请等一会哦")
	var total_character_length : int = 0
	var system_message : Dictionary = {
		"role" : "system",
		"content" : system_message_text_edit.text
	}
	var prompt_message_array : Array[Dictionary]
	var bubble_message_array : Array[Dictionary]
	var user_message : Dictionary = {
		"role" : "user",
		"content" : input_text_edit.text
	}
	var data = {
		"type": "chat_with_ai_request_message",
		"content" : {
			"token": main.config.config_data.token,
			"temperature" : temperature_h_slider.value,
			"frequency_penalty" : frequency_penalty_h_slider.value,
			"presence_penalty" : presence_penalty_h_slider.value,
			"messages" : [],
		}
	}
	for prompt in prompt_v_box_container.get_children():
		var content : String = prompt.get_content()
		total_character_length += content.length()
		prompt_message_array.append({
			"role" : prompt.get_role(),
			"content" : content
		})

	for i in range(4):
		if bubble_v_box_container.get_child_count() > i:
			var bubble : Bubble = bubble_v_box_container.get_child(bubble_v_box_container.get_child_count() - i - 1)
			if bubble.get_content() == "":
				continue
			bubble_message_array.append({
				"role" : bubble.get_role(),
				"content" : bubble.get_content()
			})
		else:
			break
	
	var messages : Array[Dictionary]

	if user_message["content"].length() <= 1024:
		messages.append(user_message)
		total_character_length += user_message["content"].length()
	else:
		main.toast.make_text("超出字數限制" + str(user_message["content"].length()) + "/1024")
		return
	
	if total_character_length + system_message["content"].length() <= 1024:
		total_character_length += system_message["content"].length()

		for bubble_message in bubble_message_array:
			if total_character_length + bubble_message["content"].length() <= 1024:
				messages.append(bubble_message)
				total_character_length += bubble_message["content"].length()
			else:
				break
	
		for prompt_message in prompt_message_array:
			if total_character_length + prompt_message["content"].length() <= 1024:
				messages.append(prompt_message)
				total_character_length += prompt_message["content"].length()
			else:
				break
		messages.append(system_message)
		messages.reverse()
	
	data["content"]["messages"] = messages
	input_text_edit.text = ""
	push_bubble(user_message["content"],Bubble.USER)
	save_data()
	
	response_bubble = push_bubble("",Bubble.ASSISTANT)
	main.send_message(
		data,
		Callable(
			func(_data : Dictionary):
				if response_bubble == null:
					return
				if _data.get("type","") == "error_response_message":
					response_bubble.add_content(_data.get("content",{}).get("text","服务器错误"))
				if _data.get("type","") == "chat_with_ai_response_message":
					key = _data.get("content",{}).get("key","")
				),
		Callable(
			func(_result : int,_text : String):
				if response_bubble == null:
					return
				match _result:
					0:
						response_bubble.add_content(_text)
					HTTPRequest.RESULT_CANT_CONNECT:
						response_bubble.add_content("连接时请求失败")
					HTTPRequest.RESULT_CANT_RESOLVE:
						response_bubble.add_content("无法解析主机名")
					HTTPRequest.RESULT_CONNECTION_ERROR:
						response_bubble.add_content("连接时请求失败")
					HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
						response_bubble.add_content("TLS握手失败")
					HTTPRequest.RESULT_NO_RESPONSE:
						response_bubble.add_content("服务器无响应")
					HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
						response_bubble.add_content("响应体大小超出限制")
					HTTPRequest.RESULT_REQUEST_FAILED:
						response_bubble.add_content("请求失败")
					HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
						response_bubble.add_content("无法打开下载文件")
					HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
						response_bubble.add_content("下载文件写入错误")
					HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
						response_bubble.add_content("重定向次数超出限制")
					HTTPRequest.RESULT_TIMEOUT:
						response_bubble.add_content("请求超时")
				response_bubble = null),
	)

func _on_bottom_button_pressed():
	slide_to_bottom()
	
func slide_to_bottom() -> void:
	var tween : Tween = create_tween()
	tween.tween_property(bubble_scroll_container,"scroll_vertical",bubble_scroll_container.get_v_scroll_bar().max_value,0.5)

func _on_input_text_edit_text_set():
	var tween : Tween = create_tween()
	tween.tween_property(input_text_edit,"custom_minimum_size:y",32 + (clampi(input_text_edit.get_line_count(),1,2) - 1) * 96,0.3)

func _on_input_text_edit_text_changed():
	var tween : Tween = create_tween()
	tween.tween_property(input_text_edit,"custom_minimum_size:y",32 + (clampi(input_text_edit.get_line_count(),1,2) - 1) * 96,0.3)


func _on_submit_config_button_pressed():
	save_data()
	config_panel_container.hide()


func _on_timer_timeout():
	if key.is_empty() == false:
		var data = {
			"type" : "get_chat_request_message",
			"content" : {
				"key" = key
			}
		}
		main.send_message(data,
			(func(_data : Dictionary):
				if _data.get("type",) == "get_chat_response_message":
					if response_bubble == null:
						key = ""
						return
					if _data["content"]["messages"].is_empty():
						return
					var str = ""
					for message in _data["content"]["messages"]:
						var value = message["choices"][0]["delta"].get("content","")
						str += value
						if message["choices"][0].get("finish_reason",null) != null:
							key = ""
					response_bubble.add_content(str,3)
					main.chat.slide_to_bottom()
				else:
					main.toast.make_text(str(_data.get("content","Error")))
					key = ""
					response_bubble = null
				pass),
			(func(_result : int,_text : String):
				key = ""
				response_bubble = null
				pass)
		)


func _on_stop_button_pressed():
	key = ""
