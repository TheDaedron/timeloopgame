extends Control

@onready var command_tree: Tree = $"../Command_Tree"
var button_sprite_sheet = preload("res://Sprites/_sheet_window_28.png")

func _ready():
	# Create a nine-slice background from a sprite sheet
	var button_slice_bg = create_nine_slice_background(button_sprite_sheet)

	# Apply the custom theme to each Button object in the scene
	var theme = Theme.new()
	theme.set_stylebox("normal", "Button", button_slice_bg)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())  # Remove focus outline
	theme.set_stylebox("hover", "Button", button_slice_bg)  # Ensure hover matches normal

	# Find and apply theme to all buttons in the scene
	var buttons = [
		find_child("Move_Up"),
		find_child("Move_Down"),
		find_child("Move_Left"),
		find_child("Move_Right"),
		find_child("Action_Speak"),
		find_child("Action_Interact"),
		find_child("Action_Attack")
	]

	for i in range(buttons.size()):
		var button = buttons[i]
		if button:
			button.theme = theme
			button.mouse_default_cursor_shape = Control.CURSOR_ARROW  # Ensure no unexpected cursor changes
			button.pressed.connect(func(): _handle_button_press(i))

func _handle_button_press(index: int):
	var command_name : String
	var metadata_name : String
	
	if not command_tree:
		print("[ERROR] Command Tree not found!")
		return

	var root = command_tree.get_root()
	if not root:
		print("[ERROR] Command Tree root not found!")
		return

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
			print("[ERROR] Invalid button index:", index)

	var new_command = root.create_child()
	new_command.set_text(0, command_name)
	new_command.set_editable(0, false)
	new_command.set_meta("type", "command")
	new_command.set_metadata(0, metadata_name)

	print("[INFO] Added command:", command_name)

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
