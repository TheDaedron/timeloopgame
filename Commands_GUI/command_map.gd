extends Control

signal map_button_pressed(index: int)

@export var mapButtons := []
@export var mapButtonsReady := false

func _ready():
	# Find all buttons
	mapButtons = [
		find_child("Map_Up"),
		find_child("Map_Down"),
		find_child("Map_Left"),
		find_child("Map_Right")
	]

	# DEBUG : Safety check to make sure all four buttons were found.
	if not mapButtons.size() == 4:
		print("[ERROR - Command_Map]: Map Button Size != 4")
		return

	# Loops through each button and formats & connects them.
	for i in range(mapButtons.size()):
		var mapButton = mapButtons[i]
		if mapButton:
			mapButton.mouse_default_cursor_shape = Control.CURSOR_ARROW
			mapButton.pressed.connect(func(): _connect_button_press(i))

	# Sets the mapButtonsReady varible to true
	mapButtonsReady = true

# Emits the map_button_pressed signal each time a button is pressed
func _connect_button_press(index: int):
	emit_signal("map_button_pressed", index)
