# This script is what Godot refers to as a Singleton, or an Autoload. This is defined in Project > Project Settings > Globals.
# The main purpose of this script is for other scripts to create node references for themselves. This simplifies code by being able to reference any Required script from any other script.

extends Node

signal systems_ready()

# Need to update this array to account for any other system we want to add to the SystemManager. Everything else should adapt accordingly.
# This will also function as a priority list of which functions are loaded first.
const REQUIRED_SYSTEMS = [
	"GameManager",
	"TileManager",
	"command_map",
	"command_tree",
	"command_gui",
	"tilemap",
	"player"
]

# Dictionary to store references to all initialized systems.
var set_systems: Dictionary = {}

#region System setter/getter
# Registers a system with the SystemManager.
# Takes the system name as a String and the corresponding node.
# Stores the system in the set_systems dictionary and checks readiness.
func _set_system(system: String, node: Node) -> void:
#	print("Setting system: ", system)
	set_systems[system] = node
	_check_ready()

# Retrieves a registered system node by its name.
# Returns null and prints a warning if the system is not found.
func get_system(system: String) -> Node:
	if set_systems.has(system):
		return set_systems[system]
	printerr("[Warning - SystemManager]: System '%s' is not set." % system)
	return null
#endregion

# Checks if all required systems have been registered.
# If all are present, it calls each system's _all_ready() method (if it exists), and emits the `systems_ready` signal.
func _check_ready() -> void:
	if all_systems_ready():
		#print("[INFO - SystemManager]: All systems registered.")

		for REQUIRED_SYSTEM in REQUIRED_SYSTEMS:
			var system = get_system(REQUIRED_SYSTEM)
			if system.has_method("_all_ready"):
				system._all_ready()
			else:
				printerr("[Warning - SystemManager]: System '%s' does not have an _all_ready method." % REQUIRED_SYSTEM)

		emit_signal("systems_ready")

# Checks whether all required systems listed in REQUIRED_SYSTEMS have been registered in the set_systems dictionary.
func all_systems_ready() -> bool:
	for REQUIRED_SYSTEM in REQUIRED_SYSTEMS:
		if not set_systems.has(REQUIRED_SYSTEM):
			return false
	return true
