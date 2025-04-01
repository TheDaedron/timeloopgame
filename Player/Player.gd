extends Node2D

@export var animationPlayer: AnimationPlayer

var tilemap
var gameManager
var tileManager

func _ready() -> void:
	SystemManager._set_system("player", self)
	animationPlayer = find_child("AnimationPlayer")
	animationPlayer.play("Walk_Down")

func _all_ready() -> void:
	gameManager = SystemManager.get_system("GameManager")
	tileManager = SystemManager.get_system("TileManager")
	tilemap = SystemManager.get_system("tilemap")

	gameManager.command_given.connect(_process_commands)

func _process(_delta):
	if SystemManager.all_systems_ready():
		tileManager.update_tile_darkness(get_player_tile())

func _process_commands(command: String) -> void:
	match command:
		"move_up":
			_try_move(Vector2.UP, "Walk_Up")
		"move_down":
			_try_move(Vector2.DOWN, "Walk_Down")
		"move_left":
			_try_move(Vector2.LEFT, "Walk_Left")
		"move_right":
			_try_move(Vector2.RIGHT, "Walk_Right")
		"interact":
			_interact()
		"speak":
			_speak()
		"attack":
			_attack()
		_:
			print("[WARNING] Unknown command received: ", command)

func _try_move(direction: Vector2, animation_name: String) -> void:
	var target_tile = get_player_tile() + Vector2i(direction)

	if not tileManager.is_in_bounds(target_tile):
		print("[INFO - Player]: Target tile is out of bounds")
		return

	var tile_data = tileManager.get_tile_data(target_tile)
	
	if tile_data.is_walkable:
		position += direction * Vector2(tilemap.tile_size)
		if animationPlayer.current_animation != animation_name:
			animationPlayer.play(animation_name)
		tilemap.on_player_moved()
		print("[INFO - Player]: Player is on tile: ", get_player_tile())
	else:
		print("[INFO - Player]: Target tile %s is not walkable" % target_tile)

func is_tile_within_bounds(tile: Vector2i) -> bool:
	return (
		tile.x >= 0 and 
		tile.x < tilemap.chunk_size.x * tilemap.world_size.x and
		tile.y >= 0 and 
		tile.y < tilemap.chunk_size.y * tilemap.world_size.y
	)

func get_player_tile() -> Vector2i:
	return Vector2i(position) / tilemap.tile_size

func _interact() -> void:
	print("Player is interacting")

func _speak() -> void:
	print("Player is speaking")

func _attack() -> void:
	print("Player is attacking")
