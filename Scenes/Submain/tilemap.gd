extends Node2D

@onready var tile_map_layer: TileMapLayer = $"TileMapLayer"
@onready var debug_line: Line2D = $DebugLine

@export var chunk_size: Vector2i = Vector2i(24, 18) # Each chunk is 24x18 tiles
@export var world_size: Vector2i = Vector2i(4, 4)   # 4x4 chunks
@export var tile_layer: int = 0  # Specify the TileMap layer index

var chunks = {} # Stores tiles by chunk
var current_chunk = Vector2i(2, 2) # The active chunk

var buttons: Array = []

func set_buttons(button_list: Array):
	buttons = button_list

func _ready():
	load_chunks()
	update_chunk_display()

	_update_button_visibility()
	#draw_chunk_test_line()

func load_chunks():
	"""Organizes all tiles into chunk-based storage."""
	chunks.clear()
	
	var used_cells = tile_map_layer.get_used_cells()

	for cell in used_cells:
		var chunk_pos = Vector2i(cell.x / chunk_size.x, cell.y / chunk_size.y)

		if chunk_pos not in chunks:
			chunks[chunk_pos] = []

		var source_id = tile_map_layer.get_cell_source_id(cell)
		var atlas_coords = tile_map_layer.get_cell_atlas_coords(cell)

		chunks[chunk_pos].append({
			"position": cell,
			"source_id": source_id,
			"atlas_coords": atlas_coords
		})

	print("Chunks Loaded:", chunks.keys())  # Debugging output

func update_chunk_display():
	"""Clears the TileMapLayer and displays only the active chunk."""
	tile_map_layer.clear()

	if current_chunk in chunks:
		var chunk_origin = current_chunk * chunk_size
		
		for tile_data in chunks[current_chunk]:
			var local_pos = tile_data["position"] - chunk_origin  # shift so tiles start at (0,0)
			tile_map_layer.set_cell(local_pos, tile_data["source_id"], tile_data["atlas_coords"])

	print("Displaying Chunk:", current_chunk)  # Debugging output

#region Handling Command_Map Button Presses
func _handle_button_press(index: int):
	var command_name : String
	var map_direction : Vector2i

	match index:
		0: 
			command_name = "Map Up"
			map_direction = Vector2i(0 , -1)
		1: 
			command_name = "Map Down"
			map_direction = Vector2i(0 , 1)
		2: 
			command_name = "Map Left"
			map_direction = Vector2i(-1 , 0)
		3: 
			command_name = "Map Right"
			map_direction = Vector2i(1 , 0)
		_:
			print("[ERROR] Invalid button index:", index)

	var new_chunk = current_chunk + map_direction

	# Clamp movement so it stays within world bounds
	if new_chunk.x >= 0 and new_chunk.x < world_size.x and new_chunk.y >= 0 and new_chunk.y < world_size.y:
		current_chunk = new_chunk
		update_chunk_display()
		_update_button_visibility()
		draw_chunk_test_line()

	print("[INFO] Changed chunk to: ", current_chunk, "| Command: ", command_name)

func _update_button_visibility():
	if buttons.size() < 4:
		return  # Safety check

	buttons[0].visible = current_chunk.y > 0 # Up
	buttons[1].visible = current_chunk.y < world_size.y - 1 # Down
	buttons[2].visible = current_chunk.x > 0 # Left
	buttons[3].visible = current_chunk.x < world_size.x - 1 # Right
#endregion

func draw_debug_line_in_first_chunk():
	debug_line.clear_points()

	if not tile_map_layer.tile_set:
		print("[ERROR] TileSet is missing on tile_map_layer")
		return

	var tile_size = tile_map_layer.tile_set.get_tile_size()
	if tile_size == Vector2i.ZERO:
		print("[WARNING] Tile size is (0, 0), cannot draw debug line.")
		return

	var points: Array[Vector2i] = []

	# Diagonal line from top-left to bottom-right of chunk (0, 0)
	for i in range(chunk_size.x):
		var tile_coords = Vector2i(i, i)
		var local_pos = tile_coords * tile_size  # Convert tile coords to pixel coords
		points.append(local_pos)

	debug_line.points = points
	debug_line.visible = true

func draw_chunk_test_line():
	debug_line.clear_points()

	if not tile_map_layer.tile_set:
		print("[ERROR] TileSet is missing on tile_map_layer")
		return

	var tile_size = tile_map_layer.tile_set.get_tile_size()
	if tile_size == Vector2i.ZERO:
		print("[WARNING] Tile size is (0, 0), cannot draw debug line.")
		return

	var points: Array[Vector2i] = []
	var chunk_origin = current_chunk * chunk_size

	print("--- Drawing Chunk Debug Line (for chunk:", current_chunk, ") ---")

	# Loop through all chunks, but only draw points that fall within current_chunk
	for y in range(world_size.y):
		for x in range(world_size.x):
			var chunk_pos = Vector2i(x, y)

			# Skip chunks that aren't the current one
			if chunk_pos != current_chunk:
				continue

			chunk_origin = chunk_pos * chunk_size
			var center_tile = chunk_origin + chunk_size / 2
			var local_pos = (center_tile - chunk_origin) * tile_size  # Align to local (0,0)

			points.append(local_pos)
			print("Chunk", chunk_pos, "-> local center pixel:", local_pos)

	debug_line.points = points
	debug_line.visible = true
