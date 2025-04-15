extends Node

const COMMAND_DELAY = 0.25  # 0.25 seconds delay between commands

signal command_given(command: String)
signal movement_path_updated
signal loop_finished

var command_tree
var root_item: TreeItem
var player_start_pos: Vector2i = Vector2i(1920.0, 1440.0)

var commands = []  # Store command names
var movement_path = []  # Points along the movement path

var move_commands = {
	"Move Up": [Vector2.UP],
	"Move Down": [Vector2.DOWN],
	"Move Left": [Vector2.LEFT],
	"Move Right": [Vector2.RIGHT]
}

func _ready() -> void:
	ScriptManager.set_script_node("GameManager", self)

func all_ready() -> void:
	command_tree = ScriptManager.get_script_node("command_tree")
	command_tree.tree_changed.connect(on_command_tree_changed)

func _input(event):
	if event.is_action_pressed("ui_accept"):  # "Enter" key in default Godot input map
		load_and_execute_commands()

func load_and_execute_commands() -> void:
	get_commands_from_tree()
	execute_commands_with_delay()

func on_command_tree_changed() -> void:
	Debug.trace("Command tree changed! Rebuilding movement path...")
	movement_path.clear()
	get_commands_from_tree()
	emit_signal("movement_path_updated")

func get_commands_from_tree():
	commands.clear()

	root_item = command_tree.get_root()
	if root_item:
		Debug.trace("Root item found: %s" % [root_item.get_text(0)])
		movement_path.clear()
		movement_path.append(player_start_pos)

		traverse_tree(root_item, player_start_pos)

		Debug.trace("Finished building movement path. Total points: %d" % [movement_path.size()])
	else:
		Debug.warning("Root item is null!")

func traverse_tree(item: TreeItem, current_position: Vector2) -> Vector2:
	while item:
		var metadata = item.get_metadata(0)
		if typeof(metadata) == TYPE_DICTIONARY and metadata.has("command_name"):
			var command_name = metadata["command_name"]
			var count = metadata.get("repeat_count", 1)
			var command_type = metadata.get("command_type", "")

			for i in range(count):
				commands.append(command_name)
				Debug.trace("Added command: %s (type: %s)" % [command_name, command_type])

				if move_commands.has(command_name):
					var dir_move = move_commands[command_name][0]
					current_position += dir_move * 32
					movement_path.append(current_position)
					Debug.trace("New movement position: %s" % [current_position])

		if item.get_first_child():
			current_position = traverse_tree(item.get_first_child(), current_position)

		item = item.get_next()

	return current_position


func execute_commands_with_delay() -> void:
	if commands.is_empty():
		Debug.error("Commands is empty.")
		return

	run_commands()

# Coroutine for delayed execution
func run_commands() -> void:
	if commands.is_empty():
		Debug.warning("No commands to execute.")
		return
	
	for command in commands:
		emit_signal("command_given", command)
		await get_tree().create_timer(COMMAND_DELAY).timeout
	
	# After running all commands, loop!
	Debug.info("Command sequence finished. Restarting...")
	
	emit_signal("loop_finished")
	await get_tree().create_timer(1.0).timeout  # (optional small pause before restarting)

	load_and_execute_commands()  # restart the whole flow
