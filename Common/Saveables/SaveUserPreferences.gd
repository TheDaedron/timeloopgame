extends Resource

class_name SaveUserPreferences

## Tutorial to build the save/load user preferences feature found at : https://youtu.be/GPzdFzNq060
## I also stole a lot of code from the SavePlayer script.

@export_range(0, 1, 0.01) var master_audio_level : float
@export_range(0, 1, 0.01) var music_audio_level : float
@export_range(0, 1, 0.01) var sfx_audio_level : float

@export var fullscreen_checked : bool
@export var borderless_checked : bool
@export var vsync_checked : bool

## TODO: Create this.
#@export var action_events : Dictionary = {}

## This will put the save file location at AppData\Roaming\Godot\app_userdata\TimeLoopGame\.
const SAVE_DIR = "user://"
const SAVE_FILE_NAME = "UserPrefs.json"

func _ready():
	verify_save_directory(SAVE_DIR)

func save_file() -> void:
	save_data(SAVE_DIR + SAVE_FILE_NAME)

func load_file() -> void:
	load_data(SAVE_DIR + SAVE_FILE_NAME)

func verify_save_directory(path: String) -> void:
	DirAccess.make_dir_absolute(path)

func save_data(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if file == null:
		print(FileAccess.get_open_error())
		return
	
	var data = {
		"audio_levels" : {
			"master_audio_level" = master_audio_level,
			"music_audio_level" = music_audio_level,
			"sfx_audio_level" = sfx_audio_level
		},
		"video_options" : {
			"fullscreen_checked" = fullscreen_checked,
			"borderless_checked" = borderless_checked,
			"vsync_checked" = vsync_checked
		}
	}
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()

func load_data(path: String) -> void:
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file == null:
			print(FileAccess.get_open_error())
			return

		var content = file.get_as_text()
		file.close()

		var data = JSON.parse_string(content)

		if data == null:
			printerr("Cannot parse {path} as a json_string: ({content})")
			return
			
		master_audio_level = data.audio_levels.master_audio_level
		music_audio_level = data.audio_levels.music_audio_level
		sfx_audio_level = data.audio_levels.sfx_audio_level
		
		fullscreen_checked = data.video_options.fullscreen_checked
		borderless_checked = data.video_options.borderless_checked
		vsync_checked = data.video_options.vsync_checked

	else:
		printerr("Cannot open non-existent file at {path}!")
