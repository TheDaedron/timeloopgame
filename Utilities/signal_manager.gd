extends Node

#region Global Signal Manager
# signals holds the most recent emitted value for a named global signal
var signals: Dictionary = {}

# listeners holds arrays of Callables for any global signal
var listeners: Dictionary = {}

# Emit a global signal (with optional data) that may be received immediately or later
func emit_global(signal_name: String, data = null) -> void:
	var result : Variant
	
	if data == null:
		Debug.trace("Emitting signal: %s" % [signal_name])
	else:
		Debug.trace("Emitting signal: %s with data: %s" % [signal_name, data])
	signals[signal_name] = data

	if listeners.has(signal_name):
		Debug.trace("Listeners found for signal: %s" % [signal_name])
		for listener in listeners[signal_name]:
			Debug.trace("Listener: %s" % [listener])
			if listener.is_valid():
				Debug.trace("Listener is valid. Calling...")
				if data == null:
					result = listener.call()
				else:
					result = listener.call(data)
					if result != null:
						Debug.trace("Call result: %s" % [result])
			else:
				Debug.error("Listener is NOT valid!")

	else:
		Debug.error("No listeners registered for signal: %s" % [signal_name])

# Connect to a global signal; if the signal was already emitted, it triggers immediately
func connect_global(signal_name: String, target: Object, method_name: String) -> void:
	var result : Variant
	
	Debug.trace("Connecting to signal: %s with method: %s on target: %s" % [signal_name, method_name,target])

	if not listeners.has(signal_name):
		listeners[signal_name] = []

	var callable = Callable(target, method_name)
	if callable in listeners[signal_name]:
		Debug.trace("Already connected. Skipping.")
		return

	listeners[signal_name].append(callable)
	Debug.trace("Connected successfully.")

	if signals.has(signal_name):
		Debug.trace("Signal was already emitted previously. Calling immediately with stored data: %s" % [signals[signal_name]])
		if callable.is_valid():
			if signals[signal_name] == null:
				result = callable.call()
			else:
				result = callable.call(signals[signal_name])
				Debug.trace("Immediate call result: %s" % [result])
		else:
			Debug.error("Callable is invalid!")
#endregion
