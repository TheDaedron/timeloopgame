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
	"tilemap",
	"player",
]

# Dictionary to store references to all initialized scripts and their nodes.
var set_scripts: Dictionary = {}

#region script setter/getter
# Registers a script with the ScriptManager
# Stores the script in the set_scripts dictionary and checks readiness
func set_script_node(script: String, node: Node) -> void:
	set_scripts[script] = node
	check_ready()

# Returns the script's node (Node) if the script exists in set_scripts dictionary
# Returns null and prints a warning if the script is not found
func get_script_node(script: String) -> Node:
	if set_scripts.has(script):
		return set_scripts[script]
	printerr("[Warning - scriptManager]: script '%s' is not set." % script)
	return null
#endregion

# Checks if all required scripts have been registered.
# If all are registered, it calls each script's all_ready() method (if it exists), and emits the `scripts_ready` signal.
func check_ready() -> void:
	if all_scripts_ready():
		for REQUIRED_SCRIPT in REQUIRED_SCRIPTS:
			var script = get_script_node(REQUIRED_SCRIPT)
			if script.has_method("all_ready"):
				script.all_ready()
			else:
				printerr("[Warning - ScriptManager]: script '%s' does not have an all_ready method." % REQUIRED_SCRIPT)

		emit_signal("scripts_ready")

# Checks whether all required scripts listed in REQUIRED_SCRIPTS have been registered in the set_scripts dictionary.
func all_scripts_ready() -> bool:
	for REQUIRED_SCRIPT in REQUIRED_SCRIPTS:
		if not set_scripts.has(REQUIRED_SCRIPT):
			return false
	return true
