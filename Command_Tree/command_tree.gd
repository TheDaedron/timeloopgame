extends Tree

var tree_sprite_sheet = preload("res://Sprites/_sheet_window_19.png")

var root_item: TreeItem  # Root node of the tree
var drop_position = Vector2.ZERO
var drop_target: TreeItem = null
var drop_type = ""  # Can be "above", "on", "below"

func _ready():
	# Create a nine-slice background
	var tree_slice_bg = create_nine_slice_background(tree_sprite_sheet)

	# Apply it to a custom theme
	var theme = Theme.new()
	theme.set_stylebox("panel", "Tree", tree_slice_bg)  # Set as Tree's background
	
	# Assign theme to the Tree
	self.theme = theme

	# Configure Tree into the correct mode
	self.set_hide_root(true)
	self.set_select_mode(Tree.SELECT_MULTI)  # Allow multiple selection
	self.set_drop_mode_flags(Tree.DROP_MODE_ON_ITEM | Tree.DROP_MODE_INBETWEEN)
	self.item_edited.connect(_on_item_edited)

	# === B) Populate the tree ===
	root_item = self.create_item()  # Invisible root (since hide_root is true)

	# Add folders
	for i in range(3):
		_add_folder("Folder " + str(i+1))

	# Add commands
	#for i in range(10):
	#	_add_command("Command " + str(i+1))

func _gui_input(event):
	# Update visuals while dragging
	if event is InputEventMouseMotion:
		queue_redraw()

func _draw():
	# Draw a white line if dragging between items
	if drop_target and drop_type in ["above", "below"]:
		var item_rect = get_item_area_rect(drop_target, 0)  # Get item's rect in column 0
		var line_y = item_rect.position.y if drop_type == "above" else item_rect.position.y + item_rect.size.y
		draw_line(Vector2(item_rect.position.x, line_y), Vector2(item_rect.position.x + item_rect.size.x, line_y), Color(1, 1, 1), 2)

# === FUNCTIONS ===
func _add_folder(name: String):
	var folder = root_item.create_child()
	folder.set_text(0, name)
	folder.set_editable(0, true)
	folder.set_meta("type", "folder")

	# Load icon if exists
	var folder_icon = load("res://Sprites/folder_icon.png") if ResourceLoader.exists("res://Sprites/folder_icon.png") else null
	if folder_icon:
		folder.set_icon(0, folder_icon)

func _add_command(name: String):
	var command = root_item.create_child()
	command.set_text(0, name)
	command.set_editable(0, false)  # Commands should not be renamed
	command.set_meta("type", "command")
	
	# Load icon if exists
	var command_icon = load("res://Sprites/command_icon.png") if ResourceLoader.exists("res://Sprites/command_icon.png") else null
	if command_icon:
		command.set_icon(0, command_icon)

func _on_item_edited():
	var item = get_edited()
	if item and item.get_meta("type", "") == "folder":
		print("[INFO] Folder renamed to:", item.get_text(0))

# === DRAG AND DROP FUNCTIONALITY ===
func _get_selected_items() -> Array:
	var selected_items = []
	var item = get_next_selected(null)  # Get first selected item

	while item:
		selected_items.append(item)
		item = get_next_selected(item)  # Get next selected item

	return selected_items

func _get_drag_data(position):
	var selected_items = _get_selected_items()
	if selected_items.is_empty():
		return null  # Prevent dragging if nothing is selected

	# Return multiple selected items as drag data
	return {
		"items": selected_items,  # Store all selected items
	}

func _can_drop_data(position, data):
	if not (data is Dictionary) or "items" not in data:
		return false
	
	var items_to_move = data["items"]
	var target = get_item_at_position(position)

	if not target or target == root_item:
		drop_target = null
		drop_type = ""
		return false

	# Get the rectangle area of the target item
	var item_rect = get_item_area_rect(target, 0)  # Column 0 (main text column)
	var mid_y = item_rect.position.y + (item_rect.size.y / 2)

	# Determine drop type
	if position.y < mid_y - 5:
		drop_type = "above"
	elif position.y > mid_y + 5:
		drop_type = "below"
	else:
		drop_type = "on"

	drop_target = target
	drop_position = Vector2(item_rect.position.x, mid_y)

	queue_redraw()  # Redraw to update the UI

	for item in items_to_move:
		if item == target:
			return false  # Prevent dropping on itself

		# Allow reordering within same parent
		if item.get_meta("type") == "command" and target.get_meta("type") == "command":
			if item.get_parent() != target.get_parent():
				return false
			return true

		if item.get_meta("type") == "folder" and target.get_meta("type") == "folder":
			if item.get_parent() != target.get_parent():
				return false
			return true

		# Allow moving a command into a folder
		if item.get_meta("type") == "command" and target.get_meta("type") == "folder":
			return true

	return false

func _drop_data(position, data):
	print("\n=== _drop_data() CALLED ===")

	if not (data is Dictionary) or "items" not in data:
		print("[ERROR] Invalid drag data!")
		return

	var items_to_move: Array = data["items"]
	var target: TreeItem = get_item_at_position(position)

	if not target or target == root_item:
		print("[ERROR] Invalid drop target!")
		return
	
	if not _can_drop_data(position, data):
		print("[ERROR] Drop not allowed!")
		return

	# Determine the new parent (either for reordering or moving into a folder)
	var new_parent = target.get_parent() if target.get_meta("type") == "command" else target
	var target_index = target.get_index()  # Get index of the target item

	# Reverse the array to maintain order when reinserting
	items_to_move.reverse()

	for item_to_move in items_to_move:
		if item_to_move == target:
			continue  # Skip if trying to move onto itself

		var old_parent = item_to_move.get_parent()
		var old_index = item_to_move.get_index()

		# Ensure we are not causing a circular structure
		if old_parent == new_parent and old_index == target_index:
			continue  # No need to move if already in place

		# Copy item properties before deleting it
		var new_item = new_parent.create_child()
		new_item.set_text(0, item_to_move.get_text(0))
		new_item.set_meta("type", item_to_move.get_meta("type"))
		new_item.set_editable(0, item_to_move.is_editable(0))

		# Copy icon if available
		if item_to_move.get_icon(0):
			new_item.set_icon(0, item_to_move.get_icon(0))

		# Remove old item
		item_to_move.free()

		# Reinsert the new item at the correct position
		var children = []
		var child = new_parent.get_first_child()
		while child:
			children.append(child)
			child = child.get_next()

		# Sort items to place the new item at the correct index
		children.sort_custom(func(a, b): return a.get_index() < b.get_index())

		# Reorder children in parent
		for i in range(children.size()):
			if children[i] == new_item:
				children.remove_at(i)
				children.insert(target_index, new_item)
				break

		# Refresh the tree by reassigning children
		for child1 in children:
			new_parent.remove_child(child1)
			new_parent.add_child(child1)

	queue_redraw()
	print("[SUCCESS] Items reordered or moved successfully!")

# === GRAPHICS ===
func create_nine_slice_background(texture: Texture2D) -> StyleBoxTexture:
	var stylebox = StyleBoxTexture.new()
	stylebox.texture = texture
	
	# Define the size of the fixed borders (adjust these values)
	stylebox.region_rect = Rect2(Vector2.ZERO, Vector2(48 ,48))

	# Set 9-slice borders using content margins
	stylebox.set_expand_margin(SIDE_LEFT, 0)
	stylebox.set_expand_margin(SIDE_RIGHT, 0)
	stylebox.set_expand_margin(SIDE_TOP, 0)
	stylebox.set_expand_margin(SIDE_BOTTOM, 0)

	# Set texture margins (These prevent top/bottom stretching)
	stylebox.set_texture_margin(SIDE_LEFT, 8)
	stylebox.set_texture_margin(SIDE_RIGHT, 8)
	stylebox.set_texture_margin(SIDE_TOP, 8)
	stylebox.set_texture_margin(SIDE_BOTTOM, 8)

	# Allow the center to stretch
	stylebox.draw_center = true

	return stylebox
