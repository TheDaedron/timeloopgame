extends Node2D

var tile_manager
var tile_size : int

func _ready() -> void:
	ScriptManager.connect("scripts_ready", all_ready)
	visible = false

func all_ready() -> void:
	tile_manager = ScriptManager.get_script_node("TileManager")
	tile_size = tile_manager.TILE_SIZE.x

func _process(_delta):
	if visible:
		queue_redraw()  # Continuously update overlay in real-time

func _input(event):
	if event.is_action_pressed("ui_debug_toggle"):
		visible = not visible

func _draw():
	if not visible:
		return

	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size

	for y in tile_manager.world_size.y:
		for x in tile_manager.world_size.x:
			var tile_pos = Vector2i(x, y)
			var tile_data = tile_manager.get_tile_data(tile_pos)
			if tile_data == null:
				printerr("[ERROR: Tile_Debug_Overlay]: Attempted access to tile_data that doesn't exist.")
				continue

			var screen_pos = tile_pos * tile_manager.TILE_SIZE
			
			# Darkness overlay
			var alpha = clamp(tile_data.tile_darkness / 100.0, 0, 1)
			var overlay_color = Color(0, 0, 0, alpha)
			draw_rect(Rect2(screen_pos, tile_manager.TILE_SIZE), overlay_color)
			
			# Non-walkable tile overlay
			if not tile_data.is_walkable:
				var blocked_color = Color(1, 0, 0, 0.3)
				draw_rect(Rect2(screen_pos, tile_manager.TILE_SIZE), blocked_color)

			draw_string(
				font,
				Vector2(screen_pos) + Vector2(0, tile_size / 2),
			 	str(tile_data.level),
				HORIZONTAL_ALIGNMENT_CENTER, 
				-1, 
				font_size,
				Color.WHITE
			)
			draw_string(
				font,
				Vector2(screen_pos) + Vector2(0, tile_size),
			 	str(tile_data.tile_darkness),
				HORIZONTAL_ALIGNMENT_CENTER, 
				-1, 
				font_size,
				Color.BLUE
			)
