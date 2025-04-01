extends Control

signal map_button_pressed(index: int)

@onready var mapButtons := [
	$Map_Up,
	$Map_Down,
	$Map_Left,
	$Map_Right
]

func _ready():
	SystemManager._set_system("command_map", self)

func _all_ready():
	# Loops through each button and formats & connects them.
	for i in mapButtons.size():
		var mapButton = mapButtons[i]
		mapButton.mouse_default_cursor_shape = Control.CURSOR_ARROW
		mapButton.focus_mode = Control.FOCUS_NONE
		mapButton.pressed.connect(func():
			emit_signal("map_button_pressed", i)
		)
