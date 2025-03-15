extends Node2D

@onready var player: Node2D = $"../Player"

func _process(delta):
	if player and player.has_method("get_current_path") and not player.get_current_path().is_empty():
		queue_redraw()

func _draw():
	if not player or not player.has_method("get_current_path"):
		return
	
	var path = player.get_current_path()
	if path.is_empty():
		return
	
	# Convert path to local coordinates for correct drawing
	var local_path: PackedVector2Array = []
	for point in path:
		local_path.append(to_local(point))
	
	draw_polyline(local_path, Color.RED, 2.0)
