class_name Toast extends PanelContainer

@onready 
var toast_label : Label = %ToastLabel

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


var _tween : Tween
func make_text(_value : String,_duration : float = 3.0) -> void:
	show()
	toast_label.text = _value
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(_duration)
	_tween.tween_callback(hide)
