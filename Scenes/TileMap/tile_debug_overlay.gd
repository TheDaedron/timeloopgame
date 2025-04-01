extends Node2D

@export var tile_size: int = 32

var tile_manager
var player

func _ready() -> void:
	SystemManager.connect("systems_ready", _all_ready)
	visible = false

func _all_ready() -> void:
	tile_manager = SystemManager.get_system("TileManager")

func _process(_delta):
	#if SystemManager.all_systems_ready():
	#	tile_manager = SystemManager.get_system("TileManager")
	queue_redraw()  # Continuously update overlay in real-time

func _input(event):
	if event.is_action_pressed("ui_debug_toggle"):
		print("ui_debug_toggle pressed")
		visible = not visible

func _draw():
	if tile_manager == null:
		return

	for y in tile_manager.world_size.y:
		for x in tile_manager.world_size.x:
			var tile_pos = Vector2i(x, y)
			var tile_data = tile_manager.get_tile_data(tile_pos)
			if tile_data == null:
				continue

			var screen_pos = tile_pos * tile_size
			var color = Color(0, 0, 0, 0) if tile_data.is_walkable else Color(1, 0, 0, 0.3)

			# Calculate overlay color with alpha based on tile_darkness (range 0 to 1)
			var alpha = clamp(tile_data.tile_darkness / 100.0, 0, 1)
			var overlay_color = Color(0, 0, 0, alpha)

			draw_rect(Rect2(screen_pos, Vector2(tile_size, tile_size)), overlay_color)
			
			# Draw semi-transparent tile box
			draw_rect(Rect2(screen_pos, Vector2(tile_size, tile_size)), color)

			# Draw level number (centered)
			var default_font = ThemeDB.fallback_font
			var default_font_size = ThemeDB.fallback_font_size

			draw_string(
				default_font,
				Vector2(screen_pos) + Vector2(0, tile_size / 2),
			 	str(tile_data.level),
				HORIZONTAL_ALIGNMENT_CENTER, 
				-1, 
				default_font_size,
				Color.WHITE
			)
			draw_string(
				default_font,
				Vector2(screen_pos) + Vector2(0, tile_size),
			 	str(tile_data.tile_darkness),
				HORIZONTAL_ALIGNMENT_CENTER, 
				-1, 
				default_font_size,
				Color.BLUE
			)
