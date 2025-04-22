extends Control

@onready var mapButtons := [
	$Map_Up,
	$Map_Down,
	$Map_Left,
	$Map_Right
]

func _ready():
	ScriptManager.set_script_node("command_map", self)
	SignalManager.connect_global("scripts_ready", self, "on_scripts_ready")

func on_scripts_ready() -> void:
	# Loops through each button and formats & connects them.
	for i in mapButtons.size():
		var mapButton = mapButtons[i]
		mapButton.mouse_default_cursor_shape = Control.CURSOR_ARROW
		mapButton.focus_mode = Control.FOCUS_NONE
		mapButton.pressed.connect(func():
			SignalManager.emit_global("map_button_pressed", i)
		)
