extends Node

# Stores the mapping between script names and their corresponding node instances
var set_scripts: Dictionary = {}

# Queues get requests for scripts that haven't been registered yet
var get_queue: Dictionary = {}

# Flags to control readiness checking
var readiness_check_queued: bool = false
var readiness_already_fired: bool = false

# Registers a node for a script name
func set_script_node(script: String, node: Node) -> void:
	set_scripts[script] = node
	Debug.info("Script %s set." % [script])

	# Check if there are queued requests for this script
	if get_queue.has(script):
		Debug.trace("Fulfilling queued get requests for %s" % [script])

		for request in get_queue[script]:
			var target = request.target
			var property = request.property

			if is_instance_valid(target):
				Debug.trace("Assigning %s to %s.%s" % [script, target, property])
				var success := false

				# Safer assignment - checks if the method exists
				if target.has_method("set"):
					target.set(property, node)
					success = true

				if success:
					Debug.trace("Assigned successfully.")
				else:
					Debug.warning("Could not assign property %s on %s" % [property, target])
			else:
				Debug.warning("Target object is no longer valid. Skipping.")

		# Clean up after fulfilling queued requests
		get_queue.erase(script)
	else:
		Debug.trace("No queued gets for %s" % [script])
		
	check_ready()

# Returns the node for a given script, or queues the assignment if not ready yet
func get_script_node(script: String, target: Object) -> Node:
	if set_scripts.has(script):
		var node = set_scripts[script]
		var success := false

		if is_instance_valid(target):
			# Try to assign the node directly to a property on the target with the same name as the script
			target.set(script, node)
			Debug.trace("Script %s is ready. Assigned directly to %s.%s" % [script, target, script])
			success = true

		if not success:
			Debug.warning("Script %s is ready, but assignment to %s.%s failed" % [script, target, script])

		return node

	# Not ready yet - store the assignment for later
	Debug.trace("Script %s not ready. Queuing assignment to %s.%s" % [script, target, script])

	if not get_queue.has(script):
		get_queue[script] = []

	get_queue[script].append({
		"target": target,
		"property": script
	})

	check_ready()
	return null

# Schedules a check to determine if all scripts have been set
func check_ready():
	if readiness_already_fired or readiness_check_queued:
		return

	readiness_check_queued = true
	await get_tree().process_frame  # Wait until the next frame
	readiness_check_queued = false

	# Assume all scripts are ready if nothing new was added
	all_scripts_ready()

# Called once when all _ready calls are presumed complete
func all_scripts_ready():
	if readiness_already_fired:
		return

	Debug.info("All _ready calls complete. Emitting global 'scripts_ready' signal.")
	readiness_already_fired = true
	SignalManager.emit_global("scripts_ready")
