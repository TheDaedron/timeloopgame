extends Control

@onready var scroll_container = $ScrollContainer
@onready var command_container = $ScrollContainer/HBoxContainer/CommandContainer

@onready var add_command_button = $ButtonContainer/AddCommand
@onready var add_folder_button = $ButtonContainer/AddFolder

var command_scene = preload("res://GUI_Command/CommandItem.tscn")  # Path to CommandItem scene
var folder_scene = preload("res://GUI_Command/CommandFolder.tscn")  # Path to CommandFolder scene
var command_count = 0
var folder_count = 0

func _ready():
	# Force scrollbar to always start at the top
	scroll_container.scroll_vertical = 0

	# Connects the buttons to a function.
	add_command_button.pressed.connect(add_command)
	add_folder_button.pressed.connect(add_folder)

func add_command(parent_container=null):
	command_count += 1  # Increment the counter
	var new_command = command_scene.instantiate()
	
	# Update the label text inside the new command
	var label = new_command.get_node("VBoxContainer/CommandLabel")
	label.text = "Item " + str(command_count)

	if parent_container:
		parent_container.add_child(new_command)  # Add inside a folder
	else:
		command_container.add_child(new_command)  # Add to main list

func add_folder():
	folder_count += 1
	var new_folder = folder_scene.instantiate()

	var label = new_folder.get_node("VBoxContainer/HBoxContainer/FolderLabel")
	label.text = "Folder " + str(folder_count)

	command_container.add_child(new_folder)
