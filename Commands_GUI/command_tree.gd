extends Tree

var tree_sprite_sheet = preload("res://Sprites/_sheet_window_19.png")

var root_item: TreeItem  # Root node of the tree
var drop_position = Vector2.ZERO
var drop_target: TreeItem = null
var drop_type = ""  # Can be "above", "on", "below"
var last_command_item: TreeItem = null
var last_command_count: int = 1

func _ready() -> void:
	ScriptManager.set_script_node("command_tree", self)
	SignalManager.connect_global("scripts_ready", self, "on_scripts_ready")

# Set up the tree UI (theme and behavior)
func on_scripts_ready() -> void:
	# Create a nine-slice background from a sprite sheet
	var tree_slice_bg = create_nine_slice_background(tree_sprite_sheet)

	# Apply the custom theme to the Tree
	var theme = Theme.new()
	theme.set_stylebox("panel", "Tree", tree_slice_bg)  # Assigning as Tree background
	
	self.theme = theme  # Set the theme

	# Configure tree properties
	hide_root = true
	select_mode = Tree.SELECT_MULTI
	drop_mode_flags = Tree.DROP_MODE_ON_ITEM | Tree.DROP_MODE_INBETWEEN
	item_edited.connect(on_item_edited)

	# Create the root item (invisible since hide_root is true)
	root_item = self.create_item()
	root_item.set_meta("type", "root")

	# Populate the tree with folders
	for i in range(3):
		add_folder("Folder " + str(i + 1))

func _gui_input(event):
	# Update visuals while dragging
	if event is InputEventMouseMotion:
		queue_redraw()

func _draw():
	# Draw a white line if dragging between items
	if drop_target and drop_type in ["above", "below"]:
		var item_rect = get_item_area_rect(drop_target, 0)  # Get item's rect in column 0
		var line_y = item_rect.position.y if drop_type == "above" else item_rect.position.y + item_rect.size.y
		draw_line(Vector2(item_rect.position.x, line_y), Vector2(item_rect.position.x + item_rect.size.x, line_y), Color.WHITE, 2)

# === FUNCTIONS ===
func add_folder(name: String) -> void:
	var folder = root_item.create_child()
	setup_item(folder, name, "folder", true, "res://Sprites/folder_icon.png")
	
	SignalManager.emit_global("tree_changed")

func add_command(name: String, metadata: String) -> void:
	if last_command_item and last_command_item.get_text(0).begins_with(name):
		last_command_count += 1
		last_command_item.set_text(0, "%s x%d" % [name, last_command_count])
		var meta = last_command_item.get_metadata(0)
		meta["repeat_count"] = last_command_count
		last_command_item.set_metadata(0, meta)
	else:
		last_command_item = root_item.create_child()
		last_command_count = 1
		setup_item(last_command_item, name, "command", false, "res://Sprites/command_icon.png", metadata)
		# Override metadata to be a dictionary:
		last_command_item.set_metadata(0, {
			"command_name": name,
			"repeat_count": 1
		})
		
	SignalManager.emit_global("tree_changed")

func setup_item(item: TreeItem, name: String, type: String, editable: bool, icon_path: String, metadata: String = "") -> void:
	item.set_text(0, name)
	item.set_meta("type", type)
	item.set_editable(0, editable)
	if metadata:
		item.set_metadata(0, metadata)
	if ResourceLoader.exists(icon_path):
		item.set_icon(0, load(icon_path))

func on_item_edited():
	var item = get_edited()
	if item and item.get_meta("type", "") == "folder":
		Debug.info("Folder renamed to: %s" % [item.get_text(0)])

# Helper function to check if `potential_child` is a descendant of `parent_item`
func is_descendant(parent_item: TreeItem, potential_child: TreeItem) -> bool:
	while potential_child:
		if potential_child == parent_item:
			return true
		potential_child = potential_child.get_parent()
	return false

# === DRAG AND DROP FUNCTIONALITY ===
func get_selected_items() -> Array:
	var items := []
	var item = get_next_selected(null)
	while item:
		items.append(item)
		item = get_next_selected(item)
	return items

func _get_drag_data(position):
	var items = get_selected_items()
	return {"items": items} if items else null

func _can_drop_data(position, data):
	if typeof(data) != TYPE_DICTIONARY or "items" not in data:
		return false

	var items_to_move = data["items"]
	var target = get_item_at_position(position)

	# If hovering empty space, allow dropping on root
	if not target:
		drop_target = root_item
		drop_type = "on"
		queue_redraw()
		return true  # Allow drop to root

	# Ignore if target is root (not visible)
	if target == root_item:
		return false

	# Now it's safe to use get_item_area_rect
	var rect = get_item_area_rect(target, 0)
	var mid_y = rect.position.y + rect.size.y / 2
	drop_type = "above" if position.y < mid_y - 5 else "below" if position.y > mid_y + 5 else "on"
	drop_target = target
	drop_position = Vector2(rect.position.x, mid_y)

	queue_redraw()

	# Prevent self-drop or cyclic move
	for item in items_to_move:
		if item == target or is_descendant(item, target):
			return false

	var item_type = items_to_move[0].get_meta("type", "")
	var target_type = target.get_meta("type", "")
	var valid_drops = {
		"command": ["folder", "command"],
		"folder": ["folder"]
	}

	return target_type in valid_drops.get(item_type, [])

func _drop_data(position, data):
	if typeof(data) != TYPE_DICTIONARY or "items" not in data:
		return

	var items_to_move = data["items"]
	var copy
	var target = get_item_at_position(position)
	if not target:
		target = root_item

	if not _can_drop_data(position, data):
		return

	var new_parent = target.get_parent() if target.get_meta("type") == "command" else target
	new_parent = new_parent if new_parent else root_item
	var target_index = target.get_index()

	items_to_move.reverse()  # Maintain correct insertion order

	for item in items_to_move:
		if item == target:
			continue
		copy = new_parent.create_child()
		setup_item(copy, item.get_text(0), item.get_meta("type"), item.is_editable(0), "")
		copy.set_metadata(0, item.get_metadata(0))
		if item.get_icon(0):
			copy.set_icon(0, item.get_icon(0))
		item.free()

	# Resort children
	sort_children(new_parent, copy, target_index)
	queue_redraw()
	SignalManager.emit_global("tree_changed")

func sort_children(parent: TreeItem, moved_item: TreeItem, index: int) -> void:
	var children = []
	var child = parent.get_first_child()
	while child:
		children.append(child)
		child = child.get_next()

	children.erase(moved_item)
	children.insert(index, moved_item)

	for c in children:
		parent.remove_child(c)
		parent.add_child(c)

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
