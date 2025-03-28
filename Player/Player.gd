extends Node2D

@onready var tilemap = get_node("/root/Main/SubViewportContainer/SubViewport/ChunkView/TileMap")
@onready var main = get_node("/root/Main")

func _ready():
	if main:
		main.command_given.connect(_process_commands)
		print("[INFO - Player]: main found.")
	else:
		print("[ERROR - Player]: main not found.")
	if tilemap:
		print("[INFO - Player]: tilemap found.")
	else:
		print("[ERROR - Player]: tilemap not found.")

func _process_commands(command: String):
	match command:
		"move_up":
			if tilemap.player_tile.y > 0:
				move(Vector2.UP)
		"move_down":
			if tilemap.player_tile.y < tilemap.chunk_size.y * tilemap.world_size.y  - 1:
				move(Vector2.DOWN)
		"move_left":
			if tilemap.player_tile.x > 0:
				move(Vector2.LEFT)
		"move_right":
			if tilemap.player_tile.x < tilemap.chunk_size.x * tilemap.world_size.x - 1:
				move(Vector2.RIGHT)
		"interact":
			interact()
		"speak":
			speak()
		"attack":
			attack()

func move(direction: Vector2):
	position += direction * 32
	var direction_name = ""
	match direction:
		Vector2.UP: direction_name = "up"
		Vector2.DOWN: direction_name = "down"
		Vector2.LEFT: direction_name = "left"
		Vector2.RIGHT: direction_name = "right"
		_: direction_name = "Unknown"

	tilemap.on_player_moved()
	print("Player is on tile: ", tilemap.player_tile)

func interact():
	print("Player is interacting")

func speak():
	print("Player is speaking")

func attack():
	print("Player is attacking")
