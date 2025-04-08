extends Node

var commands = []  # Store command names

signal command_given(command: String)

var command_tree
var root_item: TreeItem

const COMMAND_DELAY = 0.25  # 0.25 seconds delay between commands

func _ready() -> void:
	ScriptManager.set_script_node("GameManager", self)

func all_ready() -> void:
	command_tree = ScriptManager.get_script_node("command_tree")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # "Enter" key in default Godot input map
		load_and_execute_commands()

func load_and_execute_commands():
	get_commands_from_tree()
	execute_commands_with_delay()

func get_commands_from_tree():
	commands.clear()
	
	if command_tree:
		root_item = command_tree.get_root()
		if root_item:
			print("Root item found: ", root_item.get_text(0))  # Print root item's text
			traverse_tree(root_item)
		else:
			print("Root item is null!")
	else:
		print("Tree is null!")

func traverse_tree(item: TreeItem) -> void:
	while item:
		var command_name = item.get_metadata(0)  # Assume metadata stores commands
		var metadata = item.get_metadata(0)  # Assuming metadata is stored in column 0
		print("Item: ", item.get_text(0), " | Metadata: ", metadata)
		if command_name:
			commands.append(command_name)
		if item.get_first_child():
			traverse_tree(item.get_first_child())
		item = item.get_next()

func execute_commands_with_delay() -> void:
	if commands.is_empty():
		print("Commands is empty.")
		return  # No commands to execute

	run_commands()  # Start command execution coroutine

# Coroutine for delayed execution
func run_commands() -> void:
	for command in commands:
		emit_signal("command_given", command)

		await get_tree().create_timer(COMMAND_DELAY).timeout  # Wait before next command
