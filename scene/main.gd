class_name Main extends Panel

#var openai_api_key = "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"

@onready var safe_margin_container : MarginContainer = %SafeMarginContainer
@onready var chat : Chat = %Chat
@onready var sidebar : Sidebar = %Sidebar
@onready var config : Config = %Config
@onready var toast : Toast = %Toast
@onready var virtual_margin_container = %VirtualMarginContainer

func _ready():
	get_tree().root.size_changed.connect(
		func():
			var window : Window = get_tree().root
			var safe_margin : Rect2i = DisplayServer.get_display_safe_area()
			
			if window.position.x < safe_margin.position.x:
				safe_margin_container.add_theme_constant_override("margin_left",safe_margin.position.x - window.position.x)
			if window.position.y < safe_margin.position.y:
				safe_margin_container.add_theme_constant_override("margin_top",safe_margin.position.y - window.position.y)
			if window.position.x + window.size.x > safe_margin.end.x:
				safe_margin_container.add_theme_constant_override("margin_right",window.position.x + window.size.x - safe_margin.end.x)
			if window.position.y + window.size.y > safe_margin.end.y:
				safe_margin_container.add_theme_constant_override("margin_bottom",window.position.y + window.size.y - safe_margin.end.y)
	)
	get_tree().root.size_changed.emit()

func _process(_delta):
	if OS.has_feature("mobile") and DisplayServer.virtual_keyboard_get_height() != 0:
		var window : Window = get_tree().root
		virtual_margin_container.add_theme_constant_override("margin_bottom",DisplayServer.virtual_keyboard_get_height() / (config.config_data.scale / 1.14))

func send_message(_data : Dictionary,_success_callback : Callable,_error_callback : Callable = Callable()) -> HTTPRequest:
	var http_request : HTTPRequest = HTTPRequest.new()
	http_request.timeout = 120
	http_request.request_completed.connect(
		func(_result : int, _response_code : int, _headers : PackedStringArray, _body : PackedByteArray):
			if _result != HTTPRequest.RESULT_SUCCESS:
				if _error_callback.is_null() == false:
					_error_callback.call(_result,"")
			else:
				var data = JSON.parse_string(_body.get_string_from_utf8())
				if data == null and _error_callback.is_null() == false:
					_error_callback.call(_result,"")
				elif _success_callback.is_null() == false:
					_success_callback.call(data)
			http_request.queue_free()
	)
	add_child(http_request)
	
	var headers = ["Content-Type: application/json"]
	var request_body : PackedByteArray = JSON.stringify(_data).to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
	var error : int = http_request.request_raw(config.config_data.ip,headers,HTTPClient.METHOD_POST,request_body)
	if error != OK:
		if _error_callback.is_null() == false:
			_error_callback.call(0)
		return null
	return http_request

@onready var disclaimers_panel = %DisclaimersPanel
func _on_accept_button_pressed():
	disclaimers_panel.hide()
