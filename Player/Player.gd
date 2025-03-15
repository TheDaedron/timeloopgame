extends Node2D

@onready var tile_map: TileMap = $"../Tilemap"

var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i] = []
var target_position: Vector2
var is_moving: bool = false
var speed: float = 100.0  # Adjust movement speed

func _ready():
	# Initialize A* Grid
	astar_grid = AStarGrid2D.new()
	
	# FIX: Properly align the AStar grid with the TileMap
	var used_rect = tile_map.get_used_rect()
	astar_grid.region = used_rect
	astar_grid.cell_size = Vector2i(16, 16)  # Ensure this matches the tile size
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar_grid.offset = used_rect.position  # <<< This is the key fix!

	astar_grid.update()

	# Mark non-walkable tiles
	for tile_pos in tile_map.get_used_cells(0):
		var tile_data = tile_map.get_cell_tile_data(0, tile_pos)
		if tile_data == null or tile_data.get_custom_data("walkable") == false:
			astar_grid.set_point_solid(tile_pos)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var start_pos = tile_map.local_to_map(global_position)
		var end_pos = tile_map.local_to_map(get_global_mouse_position())

		var id_path = astar_grid.get_id_path(start_pos, end_pos)
		if id_path.size() > 1:
			id_path.pop_front()  # Avoid redundant first position
			current_id_path = id_path
			is_moving = true
			update_target_position()

func update_target_position():
	if not current_id_path.is_empty():
		target_position = tile_map.map_to_local(current_id_path.front()) + (astar_grid.cell_size / 2)
	else:
		is_moving = false

func _physics_process(delta):
	if is_moving and not current_id_path.is_empty():
		global_position = global_position.move_toward(target_position, speed * delta)

		if global_position.distance_to(target_position) < 1.0:  # Avoid float precision errors
			current_id_path.pop_front()
			update_target_position()
