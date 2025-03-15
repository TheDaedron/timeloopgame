extends Control

@onready var command_tree: Tree = $"../Command_Tree"  # Adjust path if needed

func _ready():
	# Manually find buttons in case of scene structure differences
	var move_up = find_child("Move_Up")
	var move_down = find_child("Move_Down")
	var move_left = find_child("Move_Left")
	var move_right = find_child("Move_Right")
	var speak = find_child("Action_Speak")
	var interact = find_child("Action_Interact")
	var attack = find_child("Action_Attack")

	# Ensure buttons exist before connecting
	if move_up: move_up.pressed.connect(func(): _add_command("Move Up"))
	if move_down: move_down.pressed.connect(func(): _add_command("Move Down"))
	if move_left: move_left.pressed.connect(func(): _add_command("Move Left"))
	if move_right: move_right.pressed.connect(func(): _add_command("Move Right"))
	if speak: speak.pressed.connect(func(): _add_command("Speak"))
	if interact: interact.pressed.connect(func(): _add_command("Interact"))
	if attack: attack.pressed.connect(func(): _add_command("Attack"))

func _add_command(command_name: String):
	if not command_tree:
		print("[ERROR] Command Tree not found!")
		return

	var root = command_tree.get_root()
	if not root:
		print("[ERROR] Command Tree root not found!")
		return

	var new_command = root.create_child()
	new_command.set_text(0, command_name)
	new_command.set_editable(0, false)
	new_command.set_meta("type", "command")

	print("[INFO] Added command:", command_name)
