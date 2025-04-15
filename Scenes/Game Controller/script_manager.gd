# This script is what Godot refers to as a Singleton, or an Autoload. This is defined in Project > Project Settings > Globals.
# The main purpose of this script is for other scripts to create node references for themselves. This simplifies code by being able to reference any RequiredScript from any other script.

extends Node

signal scripts_ready()

# Need to update this array to account for any other script we want to add to the ScriptManager. Everything else should adapt accordingly.
# This will also function as a priority list of which functions are loaded first.
const REQUIRED_SCRIPTS = [
	"GameManager",
	"TileManager",
	"command_map",
	"command_tree",
	"command_gui",
	"player",
	"tilemap",
]

# Dictionary to store references to all initialized scripts and their nodes.
var set_scripts: Dictionary = {}

#region script setter/getter
# Registers a script with the ScriptManager
# Stores the script in the set_scripts dictionary and checks readiness
func set_script_node(script: String, node: Node) -> void:
	set_scripts[script] = node
	Debug.info("Script %s set" % [script])
	check_ready()

# Returns the script's node (Node) if the script exists in set_scripts dictionary
# Returns null and prints a warning if the script is not found
func get_script_node(script: String) -> Node:
	if set_scripts.has(script):
		return set_scripts[script]
	Debug.error("Script %s is not set." % [script])
	return null
#endregion

#region script ready checking
# Checks if all required scripts have been registered.
# If all are registered, it calls each script's all_ready() method (if it exists), and emits the `scripts_ready` signal.
func check_ready() -> void:
	if all_scripts_ready():
		for REQUIRED_SCRIPT in REQUIRED_SCRIPTS:
			var script = get_script_node(REQUIRED_SCRIPT)
			if script.has_method("all_ready"):
				script.all_ready()
			else:
				Debug.error("Script %s does not have an all_ready method." % [REQUIRED_SCRIPT])

		emit_signal("scripts_ready")

# Checks whether all required scripts listed in REQUIRED_SCRIPTS have been registered in the set_scripts dictionary.
func all_scripts_ready() -> bool:
	for REQUIRED_SCRIPT in REQUIRED_SCRIPTS:
		if not set_scripts.has(REQUIRED_SCRIPT):
			return false
	Debug.info("All scripts ready.")
	return true
#endregion

#region Global Signal Manager
# signals holds the most recent emitted value for a named global signal
var signals: Dictionary = {}

# listeners holds arrays of Callables for any global signal
var listeners: Dictionary = {}

# Emit a global signal (with optional data) that may be received immediately or later
func emit_global(signal_name: String, data = null) -> void:
	signals[signal_name] = data
	if listeners.has(signal_name):
		for listener in listeners[signal_name]:
			listener.call_func(data)

# Connect to a global signal; if the signal was already emitted, it triggers immediately
func connect_global(signal_name: String, method_name: String) -> void:
	if not listeners.has(signal_name):
		listeners[signal_name] = []

	var callable = Callable(self, method_name)
	listeners[signal_name].append(callable)

	# If signal was already emitted, call it immediately
	if signals.has(signal_name):
		callable.call(signals[signal_name])

#endregion
