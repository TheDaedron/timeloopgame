extends Node
class_name TileManager

const LIGHT_RADIUS = 3      # tiles are fully lit if distance <= 3
const MAX_LIGHT_DISTANCE = 8  # beyond this, darkness is 100

var tilemap
var player
var world_size
var tile_data_grid: Array = []

func _ready() -> void:
	SystemManager._set_system("TileManager", self)

func _all_ready() -> void:
	tilemap = SystemManager.get_system("tilemap")

	world_size = tilemap.chunk_size * tilemap.world_size
	
	generate_random_map_json(world_size, "user://random_test_map.json")
	
	tile_data_grid = load_from_json("user://random_test_map.json")

func get_tile_data(pos: Vector2i) -> TileProperties:
	if not is_in_bounds(pos):
		push_warning("Requested tile out of bounds: " + str(pos))
		return null
	return tile_data_grid[pos.y][pos.x]

func update_tile_darkness(player_tile: Vector2i) -> void:
	for y in tile_data_grid.size():
		for x in tile_data_grid[y].size():
			var tile = tile_data_grid[y][x]
			var tile_pos = Vector2i(x, y)
			var distance = tile_pos.distance_to(player_tile)
			
			if distance <= LIGHT_RADIUS:
				tile.tile_darkness = 0
			elif distance >= MAX_LIGHT_DISTANCE:
				tile.tile_darkness = 100
			else:
				tile.tile_darkness = int((distance - LIGHT_RADIUS) / (MAX_LIGHT_DISTANCE - LIGHT_RADIUS) * 100)

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < world_size.x and pos.y < world_size.y

func generate_random_map_json(size: Vector2i, path: String) -> void:
	var tile_list = []

	for y in size.y:
		for x in size.x:
			randomize()
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
	file.store_string(JSON.stringify(full_data, "\t"))
	print("Random map JSON generated at: ", path)

func load_from_json(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
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

func save_to_json(path: String):
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
	file.store_string(JSON.stringify(full_data, "\t"))
