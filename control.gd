extends Control

@onready var tree: Tree = $Tree
@onready var add_folder_btn: Button = $Button_Container/Add_Folder
@onready var add_command_btn: Button = $Button_Container/Add_Command

var root_item: TreeItem
var drag_start_pos = Vector2()
var is_dragging: bool

func _ready():
	# Configure Tree properties.
	tree.set_hide_root(true)
	tree.scroll_vertical_enabled = true
	tree.set_select_mode(Tree.SELECT_MULTI)  # Enable multi selection
	tree.set_drop_mode_flags(Tree.DROP_MODE_ON_ITEM | Tree.DROP_MODE_INBETWEEN)

	# Connect Tree signals
	tree.gui_input.connect(_on_tree_gui_input.bind())
	tree.item_edited.connect(_on_item_edited)

	# Connect button signals.
	add_folder_btn.pressed.connect(_on_add_folder_pressed)
	add_command_btn.pressed.connect(_on_add_command_pressed)

	# Create root folder
	root_item = tree.create_item()
	root_item.set_text(0, "Root")
	root_item.set_meta("type", "folder")  # Metadata to distinguish folders

func _on_tree_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_start_pos = event.position
			is_dragging = false
		else:
			is_dragging = false  # Reset drag when releasing
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not is_dragging and drag_start_pos.distance_to(event.position) > 10:  # Drag threshold
			is_dragging = true
			var drag_data = _get_drag_data(event.position)
			if drag_data:
				tree.set_drag_preview(Label.new())  # Placeholder preview

func _add_folder(name: String, parent: TreeItem = null):
	var folder = (parent if parent else root_item).create_child()
	folder.set_text(0, name)
	folder.set_editable(0, true)
	folder.set_meta("type", "folder")  # Metadata to distinguish folders
	folder.set_icon(0, preload("res://Sprites/MissingTexture.png"))

func _add_command(name: String, parent: TreeItem):
	if not parent: return
	var command = parent.create_child()
	command.set_text(0, name)
	command.set_editable(0, false)
	command.set_meta("type", "command")  # Metadata to distinguish commands
	command.set_icon(0, preload("res://Sprites/MissingTexture.png"))

func _on_item_edited():
	var item = tree.get_edited()
	if item:
		print("Renamed item to:", item.get_text(0))

func _on_add_folder_pressed():
	var selected_item: TreeItem = tree.get_selected()  # Get single selected item

	# If no valid folder is selected, default to root
	if selected_item == null or (selected_item.has_meta("type") and selected_item.get_meta("type") == "command"):
		selected_item = root_item

	# Prevent adding a folder inside a command
	if selected_item.has_meta("type") and selected_item.get_meta("type") == "command":
		print("[ERROR] Cannot add a folder inside a command!")
		return  # Stop execution
	
	print("[INFO] Adding folder under:", selected_item.get_text(0))
	_add_folder("New Folder", selected_item)

func _on_add_command_pressed():
	var selected_item: TreeItem = tree.get_selected()  # Get single selected item

	# If no valid folder is selected, default to root
	if selected_item == null or (selected_item.has_meta("type") and selected_item.get_meta("type") == "command"):
		selected_item = root_item

	# Ensure only folders can contain commands
	if selected_item.has_meta("type") and selected_item.get_meta("type") == "folder":
		print("[INFO] Adding command under:", selected_item.get_text(0))
		_add_command("New Command", selected_item)
	else:
		print("[ERROR] Cannot add command outside a folder!")

# === DRAG AND DROP METHODS ===
var drag_preview: Control  # Store preview reference to update position

func _get_drag_data(position):
	print("\n=== _get_drag_data() CALLED ===")

	var item = tree.get_selected()
	if not item:
		print("[ERROR] No item selected, dragging failed.")
		return null
	
	if item == root_item:
		print("[INFO] Root item selected, cannot be dragged.")
		return null

	print("[DEBUG] Dragging started for item:", item.get_text(0))
	print("[DEBUG] Item Metadata:", item.get_meta("type", "NONE"))

	# === Create a Drag Preview ===
	drag_preview = Label.new()
	drag_preview.text = item.get_text(0)
	drag_preview.add_theme_font_size_override("font_size", 16)
	drag_preview.add_theme_color_override("font_color", Color.WHITE)
	drag_preview.add_theme_constant_override("outline_size", 2)
	drag_preview.add_theme_color_override("font_outline_color", Color.BLACK)
	drag_preview.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)

	# Attach preview to the UI and ensure it updates with the mouse
	tree.add_child(drag_preview)
	drag_preview.z_index = 100  # Ensure it's on top
	tree.set_drag_preview(drag_preview)

	# Start tracking the preview movement
	set_process(true)

	# Return drag data
	var drag_data = {
		"item": item,
		"text": item.get_text(0),
		"type": item.get_meta("type"),
		"preview": drag_preview  # Store preview reference for cleanup
	}

	print("[DEBUG] Drag Data Created:", drag_data)
	print("===========================\n")
	
	return drag_data

func _can_drop_data(position, data):
	print("\n=== _can_drop_data() CALLED ===")

	if not (data is Dictionary):
		print("[ERROR] Drag data is missing or corrupt!")
		return false

	if "item" not in data or "type" not in data:
		print("[ERROR] Drag data does not contain necessary keys!")
		return false

	var target = tree.get_item_at_position(position)
	
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
	print("\n=== _drop_data() CALLED ===")
	print("[DEBUG] Drop Position:", position)
	
	if not (data is Dictionary):
		print("[ERROR] Drop data is invalid! Expected a Dictionary.")
		return
	
	# Ensure that the required data exists
	if "item" not in data or "text" not in data or "type" not in data:
		print("[ERROR] Drop data is missing necessary keys!")
		print("[DEBUG] Received Data:", data)
		return
	
	# Retrieve item and target
	var item_to_move: TreeItem = data["item"]
	var target: TreeItem = tree.get_item_at_position(position)

	print("[DEBUG] Item to Move:", item_to_move.get_text(0) if item_to_move else "None")
	print("[DEBUG] Target Item:", target.get_text(0) if target else "None")

	# Validate item and target
	if not item_to_move:
		print("[ERROR] The item to move is NULL. Drop action canceled.")
		return

	if not target:
		print("[ERROR] No valid drop target found at the given position.")
		return

	# Ensure we are not moving into itself
	if target == item_to_move:
		print("[ERROR] Cannot drop an item onto itself!")
		return
	
	# Validate drop conditions
	if not _can_drop_data(position, data):
		print("[ERROR] Drop conditions are not met. Drop action canceled.")
		return

	# Perform reparenting
	print("[INFO] Moving item", item_to_move.get_text(0), "under", target.get_text(0))
	item_to_move.reparent(target)
	tree.update()

	print("[SUCCESS] Item moved successfully!")
	print("================================\n")

func _is_descendant(item: TreeItem, target: TreeItem) -> bool:
	var parent = target
	while parent:
		if parent == item:
			return true
		parent = parent.get_parent()
	return false
