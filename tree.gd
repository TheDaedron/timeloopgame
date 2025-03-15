extends Tree

# === DRAG AND DROP METHODS ===

func _get_drag_data(position):
	print("\n=== _get_drag_data() CALLED ===")

	var item = get_selected()  # Use self instead of tree
	if not item:
		print("[ERROR] No item selected, dragging failed.")
		return null
	
	if item == get_root():
		print("[INFO] Root item selected, cannot be dragged.")
		return null

	print("[DEBUG] Dragging started for item:", item.get_text(0))
	print("[DEBUG] Item Metadata:", item.get_meta("type", "NONE"))
	
	# Check if tree is properly set up
	print("[DEBUG] Tree drop mode flags:", get_drop_mode_flags())

	# Check item hierarchy
	print("[DEBUG] Item's Parent:", item.get_parent())
	if item.get_parent():
		print("[DEBUG] Parent Text:", item.get_parent().get_text(0))

	# Create drag preview
	var preview = Label.new()
	preview.text = item.get_text(0)
	set_drag_preview(preview)  # Use self instead of tree

	# Return drag data
	var drag_data = {
		"item": item,
		"text": item.get_text(0),
		"type": item.get_meta("type")
	}

	print("[DEBUG] Drag Data Created:", drag_data)
	print("===========================\n")
		
	return drag_data

func _can_drop_data(position, data):
	print("\n=== _can_drop_data() CALLED ===")

	if not (data is Dictionary):
		print("[ERROR] Drag data is missing or corrupt!")
		return false

	if "item" not in data:
		print("[ERROR] Drag data does not contain 'item' key!")
		return false

	var target = get_item_at_position(position)  # Use self instead of tree
	
	if not target:
		print("[ERROR] No drop target found at position:", position)
		return false
	
	print("[DEBUG] Target Item Found:", target.get_text(0))
	print("[DEBUG] Target Item Metadata:", target.get_meta("type", "NONE"))

	var target_type = target.get_meta("type", "")
	var data_type = data["type"]

	if target == data["item"]:
		print("[ERROR] Cannot drop onto itself!")
		return false

	if target_type == "command":
		print("[ERROR] Cannot drop onto a command!")
		return false

	if _is_descendant(data["item"], target):
		print("[ERROR] Cannot drop onto a descendant!")
		return false

	if data_type == "folder" and target_type == "folder":
		print("[SUCCESS] Folder can be dropped into another folder!")
		return true  

	if data_type == "command" and target_type == "folder":
		print("[SUCCESS] Command can be dropped into a folder!")
		return true  

	print("[ERROR] Drop not allowed for this combination!")
	return false


func _drop_data(position, data):
	print("Attempting to drop item...")

	var target = get_item_at_position(position)  # Use self instead of tree
	
	if target and target != data["item"] and _can_drop_data(position, data):
		var item_to_move = data["item"]
		item_to_move.reparent(target)

		self.queue_redraw()
		print("Item successfully moved to:", target.get_text(0))
	else:
		print("Drop action failed")

func _is_descendant(item: TreeItem, target: TreeItem) -> bool:
	var parent = target
	while parent:
		if parent == item:
			return true
		parent = parent.get_parent()
	return false
