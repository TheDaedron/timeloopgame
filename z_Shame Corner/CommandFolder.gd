extends Control

@onready var collapse_button = $VBoxContainer/HBoxContainer/CollapseButton
@onready var folder_contents = $VBoxContainer/FolderContents

var is_collapsed = false

func _ready():
	collapse_button.pressed.connect(toggle_folder)

func toggle_folder():
	is_collapsed = !is_collapsed
	folder_contents.visible = not is_collapsed
	collapse_button.text = "▶" if is_collapsed else "▼"

	adjust_folder_size()
	notify_parent_to_recalculate()

# Allow `CommandItems` to be dropped inside the folder
func _can_drop_data(_position, data):
	return data is Control and data.is_in_group("command_items")

# ✅ Handle `CommandItem` drop and trigger auto-resize
func _drop_data(_position, data):
	if folder_contents and data.get_parent():
		var old_parent = data.get_parent()
		old_parent.remove_child(data)  # Remove from old parent
		folder_contents.add_child(data)  # Move to this folder

		# Ensure folders resize dynamically
		adjust_folder_size()
		if old_parent.has_method("adjust_folder_size"):
			old_parent.adjust_folder_size()

# Automatically adjust the folder height
func adjust_folder_size():
	await get_tree().process_frame  # Allow UI updates before recalculating

	# Get the height of all commands inside `FolderContents`
	var new_height = folder_contents.get_combined_minimum_size().y

	# Set the folder's minimum height dynamically
	folder_contents.custom_minimum_size.y = new_height

	# If collapsed, keep the minimum height at zero
	if is_collapsed:
		folder_contents.custom_minimum_size.y = 0

	# Ensure the parent container updates
	notify_parent_to_recalculate()

# Tell `CommandContainer` to update layout when folders change
func notify_parent_to_recalculate():
	var parent = get_parent()
	if parent is VBoxContainer:
		parent.queue_sort()  # Forces layout recalculation
		parent.queue_redraw()  # Ensures a proper visual update
