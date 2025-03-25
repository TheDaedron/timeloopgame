extends Node2D

var speed = 1000

func move(direction: Vector2):
	position += direction * speed * get_process_delta_time()
	var direction_name = ""
	match direction:
		Vector2.UP: direction_name = "up"
		Vector2.DOWN: direction_name = "down"
		Vector2.LEFT: direction_name = "left"
		Vector2.RIGHT: direction_name = "right"
		_: direction_name = "Unknown"

	print("Player is moving ", direction_name)

func interact():
	print("Player is interacting")

func speak():
	print("Player is speaking")

func attack():
	print("Player is attacking")
