class_name ConfigData extends Resource

enum ThemeType{
	DARK,
	LIGHT,
	WIN95,
}

@export
var theme_type : ThemeType

@export
var ip : String

@export
var font_size : int

@export
var token : String

@export
var scale : float
