extends Node

@export var debug_mode: bool = true
@export var debug_threshold: int = 1

enum LogLevel { TRACE, INFO, WARNING, ERROR }
var color: String

const LEVEL_NAMES = {
	LogLevel.TRACE: "TRACE",
	LogLevel.INFO: "INFO",
	LogLevel.WARNING: "WARNING",
	LogLevel.ERROR: "ERROR"
}

const LEVEL_COLORS = {
	LogLevel.TRACE: "gray",
	LogLevel.INFO: "white",
	LogLevel.WARNING: "yellow",
	LogLevel.ERROR: "red"
}

func trace(msg) -> void:
	msg_log(msg, LogLevel.TRACE)

func info(msg) -> void: 
	msg_log(msg, LogLevel.INFO)

func warning(msg) -> void: 
	msg_log(msg, LogLevel.WARNING)

func error(msg) -> void: 
	msg_log(msg, LogLevel.ERROR)

func msg_log(message: String, level: LogLevel) -> void:
	if not debug_mode or level < debug_threshold:
		return

	var final_message = "[%s-%s]: %s" % [level_to_string(level), get_caller(), message]
	print_rich("[color=%s]%s[/color]" % [level_to_color(level), final_message])

func level_to_string(level: LogLevel) -> String:
	return LEVEL_NAMES.get(level, "UNKNOWN")

func level_to_color(level: LogLevel) -> String:
	return LEVEL_COLORS.get(level, "gray")

func get_caller() -> String:
	var stack = get_stack()
	if stack.size() > 2:
		var caller = stack[3]
		# stack[0] = Debug.gd:get_caller INFO: this function
		# stack[1] = Debug.gd:msg_log INFO: the function that called this function
		# stack[2] = Debug.gd:(info/warning/error) INFO: So on, so forth
		# stack[3] = (script):(function that called)
		# stack[4+] = WARNING: Do not use - will break 
		var source = caller.get("source", "Unknown")
		var function = caller.get("function", "")
		return "%s:%s" % [str(source).get_file(), function]
	return "Unknown"
