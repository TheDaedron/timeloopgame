extends Control

var drag_preview = null
var previous_parent = null  # Store the old parent before dragging

func _ready():
	add_to_group("command_items")  # Lets folders recognize this as a valid drop target

func _get_drag_data(_position):
	previous_parent = get_parent()  # Save the parent before dragging
	drag_preview = Label.new()
	drag_preview.text = $VBoxContainer/CommandLabel.text
	set_drag_preview(drag_preview)
	return self  # Send this CommandItem as drag data

# ✅ Allow swapping positions within the same container
func _can_drop_data(_position, data):
	return data is Control and data.is_in_group("command_items")

func _drop_data(_position, data):
	var parent = get_parent()
	var current_index = parent.get_children().find(self)
	var dragged_index = parent.get_children().find(data)

	if current_index != dragged_index:
		parent.move_child(data, current_index)  # Swap positions

	# ✅ Notify the previous folder to resize when an item moves out
	if previous_parent and previous_parent.has_method("adjust_folder_size"):
		previous_parent.adjust_folder_size()

	# ✅ Notify the new parent (folder or list) to resize
	if parent and parent.has_method("adjust_folder_size"):
		parent.adjust_folder_size()
