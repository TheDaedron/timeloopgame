extends Node2D

@export var animationPlayer: AnimationPlayer

var tilemap: Node
var gameManager: Node
var tileManager: Node

var tile_size: Vector2i
var movement_path: Array

var move_commands = {
	"Move Up": [Vector2.UP, "Walk_Up"],
	"Move Down": [Vector2.DOWN, "Walk_Down"],
	"Move Left": [Vector2.LEFT, "Walk_Left"],
	"Move Right": [Vector2.RIGHT, "Walk_Right"]
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
	position = gameManager.player_start_pos
	
	tileManager.update_tile_darkness(get_player_tile())
	gameManager.command_given.connect(process_commands)
	gameManager.loop_finished.connect(on_loop_finished)

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
				Debug.error("Unknown command received: %s" % [command])

func try_move(direction: Vector2, animation_name: String) -> void:
	var target_tile = get_player_tile() + Vector2i(direction)

	if not tileManager.is_in_bounds(target_tile):
		Debug.warning("Target tile %s is out of bounds" % [target_tile])
		return

	var tile_data = tileManager.get_tile_data(target_tile)
	
	if tile_data.is_walkable:
		position += direction * Vector2(tile_size)
		if animationPlayer.current_animation != animation_name:
			animationPlayer.play(animation_name)
		tilemap.on_player_moved()
		Debug.trace("Player is on tile: %s" % [get_player_tile()])
	else:
		Debug.warning("Target tile %s is not walkable" % [target_tile])

func on_loop_finished() -> void:
	position = gameManager.player_start_pos

func get_player_tile() -> Vector2i:
	return Vector2i(position) / tile_size

func interact() -> void:
	print("Player is interacting")

func speak() -> void:
	print("Player is speaking")

func attack() -> void:
	print("Player is attacking")
