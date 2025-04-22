#tile_manager.gd
extends Node

# Constants
const LIGHT_RADIUS: int = 2
const MAX_LIGHT_DISTANCE: int = 4
const TILE_SIZE: Vector2i = Vector2i(32, 32)
const CHUNK_SIZE: Vector2i = Vector2i(24, 18)
const NUM_CHUNKS: Vector2i = Vector2i(4, 4)

const MAP_DIRECTIONS = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]

# Properties
var chunk_center: Vector2i
var world_size: Vector2i
var tile_data_grid: Array = []

#region Initialization
func _ready() -> void:
	world_size = CHUNK_SIZE * NUM_CHUNKS
	chunk_center = Vector2i((TILE_SIZE * CHUNK_SIZE) / 2)
	
	ScriptManager.set_script_node("TileManager", self)

	generate_random_map_json(world_size, "user://random_test_map.json")
	tile_data_grid = load_from_json("user://random_test_map.json")
#endregion


#region Tile Data Access
func get_tile_data(pos: Vector2i) -> TileProperties:
	if not is_in_bounds(pos):
		Debug.warning("Requested tile out of bounds: %s" % [pos])
		return null
	return tile_data_grid[pos.y][pos.x]

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < world_size.x and pos.y < world_size.y
#endregion

#region Darkness & Lighting

# Updates all tiles' darkness based on the player's position
func update_tile_darkness(player_tile: Vector2i) -> void:
	for y in tile_data_grid.size():
		for x in tile_data_grid[y].size():
			var tile = tile_data_grid[y][x]
			var tile_pos = Vector2i(x, y)
			var darkness = calculate_darkness(tile_pos, player_tile)
			tile.tile_darkness = darkness
	SignalManager.emit_global("tile_properties_changed")

# Calculates darkness as an integer percentage based on distance from player
func calculate_darkness(tile_pos: Vector2i, player_pos: Vector2i) -> int:
	var distance = tile_pos.distance_to(player_pos)

	if distance <= LIGHT_RADIUS:
		return 0
	elif distance >= MAX_LIGHT_DISTANCE:
		return 100
	else:
		var scaled = int((distance - LIGHT_RADIUS) / (MAX_LIGHT_DISTANCE - LIGHT_RADIUS) * 100)
		return scaled
#endregion


#region Chunk Utilities
func get_chunk_offset(chunk: Vector2i) -> Vector2i:
	return chunk * CHUNK_SIZE * TILE_SIZE

func get_chunk_center_position(chunk: Vector2i) -> Vector2:
	return chunk_center + get_chunk_offset(chunk)

func get_chunk_neighbors(chunk: Vector2i) -> Dictionary:
	return {
		"up": chunk.y > 0,
		"down": chunk.y < NUM_CHUNKS.y - 1,
		"left": chunk.x > 0,
		"right": chunk.x < NUM_CHUNKS.x - 1
	}
#endregion

#region File Management
func generate_random_map_json(size: Vector2i, path: String) -> void:
	var tile_list = []
	randomize()
	
	for y in size.y:
		for x in size.x:
			var randomNumber = randi_range(0, 100)
			
			var tile_data = {
				"x": x,
				"y": y,
				"is_walkable": false if randomNumber > 90 else true,
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
		Debug.info("Random map generated at: %s" % [path])
	else:
		Debug.error("Failed to open file for writing: %s" % [path])

func load_from_json(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		Debug.error("Could not find file: %s" % [path])
		return []

	var json_text := file.get_as_text()
	var parsed : Variant = JSON.parse_string(json_text)

	if typeof(parsed) != TYPE_DICTIONARY:
		Debug.error("Invalid JSON format.")
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

	Debug.info("JSON loaded from: %s" % [path])
	return new_grid

func save_to_json(path: String) -> void:
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
		Debug.error("Failed to open file for saving: %s" % [path])
#endregion
