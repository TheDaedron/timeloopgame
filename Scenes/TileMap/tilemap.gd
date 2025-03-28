extends Node2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $Camera2D
@onready var player = $Player

@onready var command_map: Node = get_node("/root/Main/Game_GUI/Command_Map")

@export var tile_size: Vector2i = Vector2i(32, 32) # Each tile is 32x32 pixels
@export var chunk_size: Vector2i = Vector2i(24, 18) # Each chunk is 24x18 tiles
@export var world_size: Vector2i = Vector2i(4, 4)   # 4x4 chunks

@export var player_tile: Vector2i

var chunks = {} # Stores tiles by chunk
var current_chunk = Vector2i(0, 0) # The active chunk
var chunk_center = Vector2i(384, 288)
var last_player_chunk: Vector2i = Vector2i(-1, -1)  # invalid default
var follow_player_mode := false

func _ready():
	_connect_to_command_map()
	_update_chunk_display()

func _update_chunk_display():
	var chunk_offset = current_chunk * chunk_size * tile_size
	camera.position = chunk_center + chunk_offset

	print("[INFO - TileMap]: Current Chunk: ", current_chunk)

#region Handling Command_Map
func _connect_to_command_map():
	if command_map:
		var waitTime = 0
		while not command_map.mapButtonsReady:
			await get_tree().create_timer(0.01).timeout
		command_map.map_button_pressed.connect(_handle_map_button_press)
		_update_map_button_visibility()
		print("[INFO - TileMap]: command_map found.")
	else:
		print("[ERROR - TileMap]: command_map not found.")

func _handle_map_button_press(index: int):
	if follow_player_mode:
		return

	var command_name : String
	var map_direction : Vector2i

	match index:
		0: map_direction = Vector2i(0 , -1)
		1: map_direction = Vector2i(0 , 1)
		2: map_direction = Vector2i(-1 , 0)
		3: map_direction = Vector2i(1 , 0)
		_: print("[ERROR - TileMap] Invalid button index:", index)

	var new_chunk = current_chunk + map_direction

	# Clamp movement so it stays within world bounds
	if new_chunk.x >= 0 and new_chunk.x < world_size.x and new_chunk.y >= 0 and new_chunk.y < world_size.y:
		current_chunk = new_chunk
		_update_chunk_display()
		_update_map_button_visibility()

func _update_map_button_visibility():
	if not command_map.mapButtons.size() == 4:
		print("[ERROR - TileMap]: Map Button Size != 4")
		return

	command_map.mapButtons[0].visible = current_chunk.y > 0 # Up
	command_map.mapButtons[1].visible = current_chunk.y < world_size.y - 1 # Down
	command_map.mapButtons[2].visible = current_chunk.x > 0 # Left
	command_map.mapButtons[3].visible = current_chunk.x < world_size.x - 1 # Right
#endregion

func on_player_moved():
	player_tile = player.position / Vector2(tile_size)

	if not follow_player_mode:
		return

	var player_chunk = player_tile / chunk_size

	if player_chunk != last_player_chunk:
		current_chunk = player_chunk
		last_player_chunk = player_chunk
		_update_chunk_display()
		
	# print("Player Chunk:", player_chunk)  # Debugging output
