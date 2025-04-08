extends Node
class_name TileManager

const LIGHT_RADIUS = 3      # tiles are fully lit if distance <= 3
const MAX_LIGHT_DISTANCE = 8  # beyond this, darkness is 100

const TILE_SIZE: Vector2i = Vector2i(32, 32) # Each tile is 32x32 pixels
const CHUNK_SIZE: Vector2i = Vector2i(24, 18) # Each chunk is 24x18 tiles
const NUM_CHUNKS: Vector2i = Vector2i(4, 4)   # 4x4 chunks

var chunk_center: Vector2i
var world_size: Vector2i
var tile_data_grid: Array = []
var astar := AStarGrid2D.new()

var tilemap
var player

func _ready() -> void:
	world_size = CHUNK_SIZE * NUM_CHUNKS
	chunk_center = Vector2i((TILE_SIZE * CHUNK_SIZE) / 2)
	
	ScriptManager.set_script_node("TileManager", self)

func all_ready() -> void:
	tilemap = ScriptManager.get_script_node("tilemap")
	
	generate_random_map_json(world_size, "user://random_test_map.json")
	
	tile_data_grid = load_from_json("user://random_test_map.json")
	
	initialize_astar()
	setup_astar_weights()

func get_tile_data(pos: Vector2i) -> TileProperties:
	if not is_in_bounds(pos):
		push_warning("Requested tile out of bounds: " + str(pos))
		return null
	return tile_data_grid[pos.y][pos.x]

func update_tile_darkness(player_tile: Vector2i) -> void:
	for y in tile_data_grid.size():
		for x in tile_data_grid[y].size():
			var tile = tile_data_grid[y][x]
			tile.tile_darkness = calculate_darkness(Vector2i(x, y), player_tile)

func calculate_darkness(tile_pos: Vector2i, player_pos: Vector2i) -> int:
	var distance = tile_pos.distance_to(player_pos)

	if distance <= LIGHT_RADIUS:
		return 0
	elif distance >= MAX_LIGHT_DISTANCE:
		return 100
	else:
		return int((distance - LIGHT_RADIUS) / (MAX_LIGHT_DISTANCE - LIGHT_RADIUS) * 100)

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < world_size.x and pos.y < world_size.y

func initialize_astar() -> void :
	astar.region = Rect2i(Vector2i.ZERO, world_size * TILE_SIZE)
	astar.cell_size = Vector2i(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()

func setup_astar_weights() -> void:
	for y in world_size.y:
		for x in world_size.x:
			var pos = Vector2i(x, y)
			var tile = tile_data_grid[y][x]

			if tile.is_walkable:
				var cost = max(1, tile.level)  # Ensure minimum cost of 1
				astar.set_point_weight_scale(pos, cost)
			else:
				astar.set_point_solid(pos, true)

func generate_random_map_json(size: Vector2i, path: String) -> void:
	var tile_list = []
	randomize()
	
	for y in size.y:
		for x in size.x:
			var randomNumber = randi_range(0, 100)
			
			var tile_data = {
				"x": x,
				"y": y,
				"is_walkable": true if randomNumber > 10 else false,
				"level": randomNumber
			}
			tile_list.append(tile_data)

	var full_data = {
		"size": [size.x, size.y],
		"tiles": tile_list
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(full_data, "\t"))
		print("Random map JSON generated at: ", path)
	else:
		push_error("Failed to open file for writing: " + path)

func load_from_json(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Could not open file: " + path)
		return []

	var json_text := file.get_as_text()
	var parsed : Variant = JSON.parse_string(json_text)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON format")
		return []

	var size = Vector2i(parsed.get("size", [0, 0])[0], parsed.get("size", [0, 0])[1])
	var new_grid: Array = []

	for y in size.y:
		var row = []
		for x in size.x:
			row.append(TileProperties.new())
		new_grid.append(row)

	for tile_dict in parsed["tiles"]:
		var x = tile_dict.get("x", 0)
		var y = tile_dict.get("y", 0)
		if y < new_grid.size() and x < new_grid[y].size():
			new_grid[y][x].from_dict(tile_dict)

	print("JSON loaded from: ", path)
	return new_grid

func _save_to_json(path: String) -> void:
	var tile_list = []
	for y in tile_data_grid.size():
		for x in tile_data_grid[y].size():
			var data = tile_data_grid[y][x].to_dict()
			data["x"] = x
			data["y"] = y
			tile_list.append(data)

	var full_data = {
		"size": [world_size.x, world_size.y],
		"tiles": tile_list
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(full_data, "\t"))
	else:
		push_error("Failed to open file for saving: " + path)
