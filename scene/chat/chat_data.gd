class_name ChatData extends Resource

@export
var title : String

@export
var system_prompt : String = "你是一个可爱的人工智能小助手，每个回复都会发送可爱表情"

@export
var temperature : float = 1.0

@export
var prompt_array : PackedStringArray

@export
var bubble_array : PackedStringArray
