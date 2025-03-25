extends Control

var buttons := []
@onready var tilemap = get_node("/root/Main/TileMap")

func _ready():
	# Find all buttons
	buttons = [
		find_child("Map_Up"),
		find_child("Map_Down"),
		find_child("Map_Left"),
		find_child("Map_Right")
	]
	
	for i in range(buttons.size()):
		var button = buttons[i]
		if button:
			button.mouse_default_cursor_shape = Control.CURSOR_ARROW
			button.pressed.connect(func(): _handle_button_press(i))
	
	# Pass buttons to the tilemap for visibility control
	if tilemap and tilemap.has_method("set_buttons"):
		tilemap.set_buttons(buttons)

func _handle_button_press(index: int):
	if tilemap and tilemap.has_method("_handle_button_press"):
		tilemap._handle_button_press(index)
	else:
		print("[ERROR] TileMap scene not connected or missing method.")
