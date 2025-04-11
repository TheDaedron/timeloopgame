extends Node

@export var debug_mode: bool = true

enum LogLevel { INFO, WARNING, ERROR }
var color: String

func info(msg) -> void: 
	msg_log(msg, LogLevel.INFO)

func warning(msg) -> void: 
	msg_log(msg, LogLevel.WARNING)

func error(msg) -> void: 
	msg_log(msg, LogLevel.ERROR)

func msg_log(message: String, level: LogLevel) -> void:
	if not debug_mode:
		return

	var final_message = "[%s-%s]: %s" % [level_to_string(level), get_caller(), message]
	print_rich("[color=%s]%s[/color]" % [level_to_color(level), final_message])

func level_to_string(level: LogLevel) -> String:
	match level:
		LogLevel.INFO: return "INFO"
		LogLevel.WARNING: return "WARNING"
		LogLevel.ERROR: return "ERROR"
	return "UNKNOWN"

func  level_to_color(level: LogLevel) -> String:
	match level:
		LogLevel.INFO: return "white"
		LogLevel.WARNING: return "yellow"
		LogLevel.ERROR: return "red"
	return "gray"

func get_caller() -> String:
	var stack = get_stack()
	if stack.size() > 2:
		var caller = stack[3]
		var source = caller.get("source", "Unknown")
		var function = caller.get("function", "")
		return "%s:%s" % [str(source).get_file(), function]
	return "Unknown"
