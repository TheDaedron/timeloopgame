extends Control

var button_sprite_sheet = preload("res://Sprites/_sheet_window_28.png")

var command_tree

func _ready() -> void:
	ScriptManager.set_script_node("command_gui", self)
	command_tree = ScriptManager.get_script_node("command_tree", self)
	SignalManager.connect_global("scripts_ready", self, "on_scripts_ready")

func on_scripts_ready() -> void:
	# Create a nine-slice background from a sprite sheet
	var button_slice_bg = create_nine_slice_background(button_sprite_sheet)

	# Apply the custom theme to each Button object in the scene
	var theme = Theme.new()
	theme.set_stylebox("normal", "Button", button_slice_bg)
	theme.set_stylebox("hover", "Button", button_slice_bg)

	# Find and apply theme to all buttons in the scene
	var guiButtons = [
		find_child("Move_Up"),
		find_child("Move_Down"),
		find_child("Move_Left"),
		find_child("Move_Right"),
		find_child("Action_Speak"),
		find_child("Action_Interact"),
		find_child("Action_Attack")
	]

	for i in guiButtons.size():
		var guiButton = guiButtons[i]
		guiButton.theme = theme
		guiButton.mouse_default_cursor_shape = Control.CURSOR_ARROW
		guiButton.focus_mode = Control.FOCUS_NONE
		guiButton.pressed.connect( func():
			handle_button_press(i)
		)

func handle_button_press(index: int) -> void:
	var command_name : String
	var metadata_name : String

	match index:
		0: 
			command_name = "Move Up"
			metadata_name = "move_up"
		1: 
			command_name = "Move Down"
			metadata_name = "move_down"
		2: 
			command_name = "Move Left"
			metadata_name = "move_left"
		3: 
			command_name = "Move Right"
			metadata_name = "move_right"
		4: 
			command_name = "Speak"
			metadata_name = "speak"
		5: 
			command_name = "Interact"
			metadata_name = "interact"
		6: 
			command_name = "Attack"
			metadata_name = "attack"
		_:
			Debug.error("Invalid button index: %s" % [index])

	command_tree.add_command(command_name, metadata_name)

# === GRAPHICS ===
func create_nine_slice_background(texture: Texture2D) -> StyleBoxTexture:
	var stylebox = StyleBoxTexture.new()
	stylebox.texture = texture
	
	# Define the size of the fixed borders
	stylebox.region_rect = Rect2(Vector2.ZERO, Vector2(48 ,48))

	# Set 9-slice borders using content margins
	stylebox.set_expand_margin(SIDE_LEFT, 0)
	stylebox.set_expand_margin(SIDE_RIGHT, 0)
	stylebox.set_expand_margin(SIDE_TOP, 0)
	stylebox.set_expand_margin(SIDE_BOTTOM, 0)

	# Set texture margins (These prevent top/bottom stretching)
	stylebox.set_texture_margin(SIDE_LEFT, 8)
	stylebox.set_texture_margin(SIDE_RIGHT, 8)
	stylebox.set_texture_margin(SIDE_TOP, 8)
	stylebox.set_texture_margin(SIDE_BOTTOM, 8)

	# Allow the center to stretch
	stylebox.draw_center = true

	return stylebox
