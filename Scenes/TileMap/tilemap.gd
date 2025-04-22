# tilemap.gd
extends Node2D

# Imports
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $Camera2D
@onready var path_visualizer: Line2D = $PathVisualizer

# Properties
var current_chunk: Vector2i:
	get:
		return _current_chunk
	set(value):
		_current_chunk = value
		update_map_chunk_display()
		update_map_button_visibility()

var _current_chunk: Vector2i = Vector2i(-1, -1) # Initialization as invalid
var last_player_chunk: Vector2i = Vector2i(-1, -1) # Initialization as invalid
var follow_player_mode := false
var player_chunk: Vector2i
var movement_path: Array = []

# Dependencies
var TileManager: Node
var GameManager: Node
var command_map: Node
var player: Node

#region Initialization
func _ready() -> void:
	ScriptManager.set_script_node("tilemap", self)
	TileManager = ScriptManager.get_script_node("TileManager", self)
	GameManager = ScriptManager.get_script_node("GameManager", self)
	command_map = ScriptManager.get_script_node("command_map", self)
	player = ScriptManager.get_script_node("player", self)
	SignalManager.connect_global("map_button_pressed", self, "handle_map_button_press")
	SignalManager.connect_global("movement_path_updated", self, "on_movement_path_updated")
	SignalManager.connect_global("scripts_ready", self, "on_scripts_ready")
	path_visualizer.clear_points()

func on_scripts_ready() -> void:
	current_chunk = player.get_player_tile() / TileManager.CHUNK_SIZE

	update_map_button_visibility()
	update_map_chunk_display()
#endregion

#region Map Chunk Display Handling
func handle_map_button_press(index: int) -> void:
	if index < 0 or index >= TileManager.MAP_DIRECTIONS.size():
		Debug.error("Invalid button index: %s" % [index])
		return

	current_chunk += TileManager.MAP_DIRECTIONS[index]

func update_map_button_visibility() -> void:
	var neighbors = TileManager.get_chunk_neighbors(current_chunk)
	command_map.mapButtons[0].visible = neighbors["up"]
	command_map.mapButtons[1].visible = neighbors["down"]
	command_map.mapButtons[2].visible = neighbors["left"]
	command_map.mapButtons[3].visible = neighbors["right"]

func update_map_chunk_display() -> void:
	camera.position = TileManager.get_chunk_center_position(current_chunk)
	
func on_player_moved() -> void:
	if not follow_player_mode:
		return

	player_chunk = player.get_player_tile() / TileManager.CHUNK_SIZE

	if player_chunk != last_player_chunk:
		current_chunk = player_chunk
		last_player_chunk = player_chunk
		update_map_chunk_display()
#endregion

#region Path Visualizer
func on_movement_path_updated():
	movement_path = GameManager.movement_path
	update_path_visualizer()

func update_path_visualizer() -> void:
	if not path_visualizer:
		Debug.warning("PathVisualizer node is missing.")
		return

	path_visualizer.clear_points()

	for point in movement_path:
		var world_position = Vector2(point) + Vector2(TileManager.TILE_SIZE) / 2
		path_visualizer.add_point(world_position)
#endregion
