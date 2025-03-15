extends Node2D

## Tutorial for this part found at: https://kidscancode.org/godot_recipes/4.x/2d/grid_pathfinding/

@onready var line : Line2D = $"../Line2D"

@export var cell_size = Vector2i(32, 32)
@export var tile_map : TileMap

var astar_grid = AStarGrid2D.new()
var grid_size
var start : Vector2i = Vector2i.ZERO
var end : Vector2i

func _ready():
	initialize_grid()

func _physics_process(delta):
	end = Vector2i(get_local_mouse_position()) / cell_size
	update_path()

func _input(event):
	if event is InputEventMouseButton:
		# Add/remove wall
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var pos = Vector2i(event.position) / cell_size
			if astar_grid.is_in_boundsv(pos):
				astar_grid.set_point_solid(pos, not astar_grid.is_point_solid(pos))
			update_path()
			queue_redraw()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var pos = Vector2i(event.position) / cell_size
			if astar_grid.is_in_boundsv(pos):
				astar_grid.set_point_weight_scale(pos, astar_grid.get_point_weight_scale(pos) + 1)
			update_path()
			queue_redraw()

func _draw():
	draw_grid()
	fill_walls()
	draw_rect(Rect2(start * cell_size, cell_size), Color.GREEN_YELLOW)
	draw_rect(Rect2(end * cell_size, cell_size), Color.ORANGE_RED)

func initialize_grid() -> void:
	grid_size = Vector2i(get_viewport_rect().size) / cell_size
	astar_grid.size = grid_size
	astar_grid.cell_size = cell_size
	astar_grid.offset = cell_size / 2
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar_grid.update()

func draw_grid() -> void:
	for x in grid_size.x + 1:
		draw_line(Vector2(x * cell_size.x, 0),
			Vector2(x * cell_size.x, grid_size.y * cell_size.y),
			Color.DARK_GRAY, 2.0)
	for y in grid_size.y + 1:
		draw_line(Vector2(0, y * cell_size.y),
			Vector2(grid_size.x * cell_size.x, y * cell_size.y),
			Color.DARK_GRAY, 2.0)

func update_path() -> void:
	$Line2D.points = PackedVector2Array(astar_grid.get_point_path(start, end))

func fill_walls() -> void:
	for x in grid_size.x:
		for y in grid_size.y:
			if astar_grid.is_point_solid(Vector2i(x, y)):
				draw_rect(Rect2(x * cell_size.x, y * cell_size.y, cell_size.x, cell_size.y), Color.DARK_GRAY)
			if astar_grid.get_point_weight_scale(Vector2i(x, y)) > 1:
				draw_rect(Rect2(x * cell_size.x, y * cell_size.y, cell_size.x, cell_size.y), Color.LIGHT_GRAY)
