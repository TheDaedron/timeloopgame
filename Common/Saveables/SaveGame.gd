extends Node

class_name SaveGame

## Tutorial to build the save/load game feature found at : https://youtu.be/mI4HfyBdV-k

## This will put the save file location at AppData\Roaming\Godot\app_userdata\bunnybunny\saves, also makes a readable version within Godot.
const SAVE_DIR = "user://saves/"
const SAVE_FILE_NAME = "save001.json"
const SECURITY_KEY = "BunnyBunny69"

#var player : SavePlayer = preload("res://Scenes/Common/Saveables/SavePlayer.tres")
#var inventory : SaveInventory = preload("res://Scenes/Common/Saveables/SaveInventory.tres")
#var map_data : SaveMapData = preload("res://Scenes/Common/Saveables/SaveMapData.tres")

func _ready():
	verify_save_directory(SAVE_DIR)
	
	save_data(SAVE_DIR + SAVE_FILE_NAME)
	load_data(SAVE_DIR + SAVE_FILE_NAME)

func verify_save_directory(path: String) -> void:
	DirAccess.make_dir_absolute(path)

func save_data(path: String) -> void:
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, SECURITY_KEY)
	
	if file == null:
		print(FileAccess.get_open_error())
		return
	
	var data = {
		"save_player" : {
#			"level": player.level,
#			"experience": player.experience,
#			"double_jump_unlocked": player.double_jump_unlocked
		},
		"save_inventory" : {
#			"heart_item": inventory.heart_item
		}
	}
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()

func load_data(path: String) -> void:
	if FileAccess.file_exists(path):
		var file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, SECURITY_KEY)
		if file == null:
			print(FileAccess.get_open_error())
			return

		var content = file.get_as_text()
		file.close()

		var data = JSON.parse_string(content)

		if data == null:
			printerr("Cannot parse {path} as a json_string: ({content})")
			return

#		player.level = data.save_player.level
#		player.experience = data.save_player.experience
#		player.double_jump_unlocked = data.save_player.double_jump_unlocked

	else:
		printerr("Cannot open non-existent file at {path}!")
