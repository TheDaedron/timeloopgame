extends Node2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $Camera2D

var tile_size: Vector2i
var chunk_size: Vector2i
var num_chunks: Vector2i
var chunk_center: Vector2i

# This can probably be calulated at all_ready
var current_chunk = Vector2i(0, 0) # The active chunk

var last_player_chunk: Vector2i = Vector2i(-1, -1)  # invalid default
var follow_player_mode := false

var Tile_Manager : Node
var command_map: Node
var player : Node

func _ready() -> void:
	ScriptManager.set_script_node("tilemap", self)

func all_ready() -> void:
	Tile_Manager = ScriptManager.get_script_node("TileManager")
	command_map = ScriptManager.get_script_node("command_map")
	player = ScriptManager.get_script_node("player")
	
	tile_size = Tile_Manager.TILE_SIZE
	chunk_size = Tile_Manager.CHUNK_SIZE
	num_chunks = Tile_Manager.NUM_CHUNKS
	chunk_center = Tile_Manager.chunk_center
	
	connect_to_command_map()
	update_chunk_display()

func update_chunk_display() -> void:
	var chunk_offset = current_chunk * chunk_size * tile_size
	camera.position = chunk_center + chunk_offset

#region Handling Command_Map
func connect_to_command_map() -> void:
		command_map.map_button_pressed.connect(handle_map_button_press)
		update_map_button_visibility()

func handle_map_button_press(index: int):
	var map_direction : Vector2i

	match index:
		0: map_direction = Vector2i.UP
		1: map_direction = Vector2i.DOWN
		2: map_direction = Vector2i.LEFT
		3: map_direction = Vector2i.RIGHT
		_: Debug.error("Invalid button index: %s" % [index])

	var new_chunk = current_chunk + map_direction

	current_chunk = new_chunk
	update_chunk_display()
	update_map_button_visibility()

func update_map_button_visibility() -> void:
	command_map.mapButtons[0].visible = current_chunk.y > 0 # Up
	command_map.mapButtons[1].visible = current_chunk.y < num_chunks.y - 1 # Down
	command_map.mapButtons[2].visible = current_chunk.x > 0 # Left
	command_map.mapButtons[3].visible = current_chunk.x < num_chunks.x - 1 # Right
#endregion

func on_player_moved() -> void:
	if not follow_player_mode:
		return

	var player_chunk = player.player_tile / chunk_size

	if player_chunk != last_player_chunk:
		current_chunk = player_chunk
		last_player_chunk = player_chunk
		update_chunk_display()
