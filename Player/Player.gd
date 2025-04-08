extends Node2D

@export var animationPlayer: AnimationPlayer

var tilemap: Node
var gameManager: Node
var tileManager: Node

var tile_size: Vector2i

var move_commands = {
	"move_up": [Vector2.UP, "Walk_Up"],
	"move_down": [Vector2.DOWN, "Walk_Down"],
	"move_left": [Vector2.LEFT, "Walk_Left"],
	"move_right": [Vector2.RIGHT, "Walk_Right"]
}

func _ready() -> void:
	ScriptManager.set_script_node("player", self)
	animationPlayer = find_child("AnimationPlayer")
	animationPlayer.play("Walk_Down")

func all_ready() -> void:
	gameManager = ScriptManager.get_script_node("GameManager")
	tileManager = ScriptManager.get_script_node("TileManager")
	tilemap = ScriptManager.get_script_node("tilemap")
	
	tile_size = tileManager.TILE_SIZE
	tileManager.update_tile_darkness(get_player_tile())
	gameManager.command_given.connect(process_commands)

func process_commands(command: String) -> void:
	if move_commands.has(command):
		var dir_anim = move_commands[command]
		try_move(dir_anim[0], dir_anim[1])
		tileManager.update_tile_darkness(get_player_tile())
	else:
		match command:
			"interact":
				interact()
			"speak":
				speak()
			"attack":
				attack()
			_:
				print("[WARNING] Unknown command received: ", command)

func try_move(direction: Vector2, animation_name: String) -> void:
	var target_tile = get_player_tile() + Vector2i(direction)

	if not tileManager.is_in_bounds(target_tile):
		print("[INFO - Player]: Target tile is out of bounds")
		return

	var tile_data = tileManager.get_tile_data(target_tile)
	
	if tile_data.is_walkable:
		position += direction * Vector2(tile_size)
		if animationPlayer.current_animation != animation_name:
			animationPlayer.play(animation_name)
		tilemap.on_player_moved()
		print("[INFO - Player]: Player is on tile: ", get_player_tile())
	else:
		print("[INFO - Player]: Target tile %s is not walkable" % target_tile)

func get_player_tile() -> Vector2i:
	return Vector2i(position) / tile_size

func interact() -> void:
	print("Player is interacting")

func speak() -> void:
	print("Player is speaking")

func attack() -> void:
	print("Player is attacking")
