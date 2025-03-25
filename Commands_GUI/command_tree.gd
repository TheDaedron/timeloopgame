extends Tree

var tree_sprite_sheet = preload("res://Sprites/_sheet_window_19.png")

var root_item: TreeItem  # Root node of the tree
var drop_position = Vector2.ZERO
var drop_target: TreeItem = null
var drop_type = ""  # Can be "above", "on", "below"

var history = []  # Stores tree states for undo/redo

# Set up the tree UI (theme and behavior)
func _ready():
	# Create a nine-slice background from a sprite sheet
	var tree_slice_bg = create_nine_slice_background(tree_sprite_sheet)

	# Apply the custom theme to the Tree
	var theme = Theme.new()
	theme.set_stylebox("panel", "Tree", tree_slice_bg)  # Assigning as Tree background
	
	self.theme = theme  # Set the theme

	# Configure tree properties
	self.set_hide_root(true)  # Hide the root item
	self.set_select_mode(Tree.SELECT_MULTI)  # Enable multiple selection
	self.set_drop_mode_flags(Tree.DROP_MODE_ON_ITEM | Tree.DROP_MODE_INBETWEEN)
	self.item_edited.connect(_on_item_edited)

	# Create the root item (invisible since hide_root is true)
	root_item = self.create_item()
	root_item.set_meta("type", "root")

	# Populate the tree with folders
	for i in range(3):
		_add_folder("Folder " + str(i + 1))

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

# Expand/Collapse Animation
func _toggle_expand(item: TreeItem):
	var tween = get_tree().create_tween()
	tween.tween_property(item, "modulate:a", 0.5, 0.15).set_trans(Tween.TRANS_CUBIC)
	item.collapsed = !item.collapsed
	tween.tween_property(item, "modulate:a", 1.0, 0.15)

# Undo/Redo System
func save_state():
	history.append(get_tree_structure_as_dict())

func undo():
	if history.is_empty():
		return
	var last_state = history.pop_back()
	restore_tree_from_dict(last_state)

func get_tree_structure_as_dict():
	var data = []
	var child = root_item.get_first_child()
	while child:
		data.append({ "name": child.get_text(0), "type": child.get_meta("type"), "collapsed": child.collapsed })
		child = child.get_next()
		return data

func restore_tree_from_dict(data):
	root_item.clear_children()
	for entry in data:
		if entry["type"] == "folder":
			var folder = _add_folder(entry["name"])
			folder.collapsed = entry["collapsed"]
		else:
			_add_command(entry["name"])

# Helper function to check if `potential_child` is a descendant of `parent_item`
func _is_descendant(parent_item: TreeItem, potential_child: TreeItem) -> bool:
	var current = potential_child
	while current:
		if current == parent_item:
			return true  # A circular move detected
		current = current.get_parent()
	return false  # Safe move

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

	# === Allow dropping to the root when hovering over an empty space ===
	if not target:
		drop_target = root_item
		drop_type = "on"
		queue_redraw()
		return true

	if target == root_item:
		return false

	# Get item rectangle area
	var item_rect = get_item_area_rect(target, 0)
	var mid_y = item_rect.position.y + (item_rect.size.y / 2)

	# Determine drop position type
	drop_type = "above" if position.y < mid_y - 5 else "below" if position.y > mid_y + 5 else "on"
	drop_target = target
	drop_position = Vector2(item_rect.position.x, mid_y)

	# Redraw only if necessary
	if drop_target != target:
		queue_redraw()

	# Prevent self-drop and circular parent-child relations
	for item in items_to_move:
		if item == target or _is_descendant(item, target):
			return false

	# Drop rules based on item type
	var item_type = items_to_move[0].get_meta("type", "")
	var target_type = target.get_meta("type", "")

	var valid_drops = {
		"command": ["folder", "command"],  # Commands can be moved into folders or reordered within commands
		"folder": ["folder"]  # Folders can only be reordered with folders
	}

	return target_type in valid_drops.get(item_type, [])

func _drop_data(position, data):
	if not (data is Dictionary) or "items" not in data:
		return

	var items_to_move: Array = data["items"]
	var target: TreeItem = get_item_at_position(position)

	# === NEW: If dropped on an empty space, move to root ===
	if not target:
		target = root_item

	if not target or target == root_item:
		print("[INFO] Moving item(s) to root")

	if not _can_drop_data(position, data):
		return

	# Determine new parent (root if dropping in empty space)
	var new_parent = target.get_parent() if target.get_meta("type") == "command" else target
	if new_parent == root_item:
		new_parent = root_item  # Ensure root is assigned correctly

	var target_index = target.get_index()  # Target's position

	# Reverse to maintain order
	items_to_move.reverse()

	for item_to_move in items_to_move:
		if item_to_move == target:
			continue  # Skip if moving onto itself

		var old_parent = item_to_move.get_parent()
		var old_index = item_to_move.get_index()

		# Prevent unnecessary moves
		if old_parent == new_parent and old_index == target_index:
			continue

		# Copy properties before deleting old item
		var new_item = new_parent.create_child()
		new_item.set_text(0, item_to_move.get_text(0))
		new_item.set_meta("type", item_to_move.get_meta("type"))
		new_item.set_editable(0, item_to_move.is_editable(0))
		new_item.set_metadata(0, item_to_move.get_metadata(0))

		# Copy icon if available
		if item_to_move.get_icon(0):
			new_item.set_icon(0, item_to_move.get_icon(0))

		# Remove old item
		item_to_move.free()

		# Sort and reinsert
		var children = []
		var child = new_parent.get_first_child()
		while child:
			children.append(child)
			child = child.get_next()

		children.sort_custom(func(a, b): return a.get_index() < b.get_index())

		for i in range(children.size()):
			if children[i] == new_item:
				children.remove_at(i)
				children.insert(target_index, new_item)
				break

		# Refresh tree hierarchy
		for child1 in children:
			new_parent.remove_child(child1)
			new_parent.add_child(child1)

	queue_redraw()

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
