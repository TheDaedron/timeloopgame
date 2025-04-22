extends Node2D

# Properties
@export var show_debug_info := false

var font := ThemeDB.fallback_font
var font_size := ThemeDB.fallback_font_size
var tile_size: int

# Dependencies
var TileManager: Node

func _ready() -> void:
	TileManager = ScriptManager.get_script_node("TileManager", self)
	SignalManager.connect_global("scripts_ready", self, "on_scripts_ready")
	SignalManager.connect_global("tile_properties_changed", self, "on_tile_properties_changed")

func on_scripts_ready() -> void:
	tile_size = TileManager.TILE_SIZE.x
	queue_redraw()

func on_tile_properties_changed() -> void:
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_debug_toggle"):
		show_debug_info = not show_debug_info
		queue_redraw()

func _draw() -> void:
	for y in TileManager.world_size.y:
		for x in TileManager.world_size.x:
			draw_tile(Vector2i(x, y))

func draw_tile(tile_pos: Vector2i) -> void:
	var tile_data = TileManager.get_tile_data(tile_pos)
	if tile_data == null:
		Debug.error("Missing tile_data at %s" % tile_pos)
		return

	var screen_pos = tile_pos * TileManager.TILE_SIZE
	
	draw_darkness_overlay(screen_pos, tile_data)
	draw_blocked_overlay(screen_pos, tile_data)
	
	if show_debug_info:
		draw_debug_level_info(screen_pos, tile_data)
		draw_debug_darkness_info(screen_pos, tile_data)

func draw_darkness_overlay(screen_pos: Vector2i, tile_data) -> void:
	var alpha = clamp(tile_data.tile_darkness / 100.0, 0.0, 1.0)
	var overlay_color = Color(0, 0, 0, alpha)
	draw_rect(Rect2(screen_pos, TileManager.TILE_SIZE), overlay_color)

func draw_blocked_overlay(screen_pos: Vector2i, tile_data) -> void:
	if not tile_data.is_walkable and tile_data.tile_darkness < 90:
		var blocked_color = Color(1, 0, 0, 0.3)
		draw_rect(Rect2(screen_pos, TileManager.TILE_SIZE), blocked_color)

func draw_debug_level_info(screen_pos: Vector2i, tile_data) -> void:
	draw_string(
		font,
		Vector2(screen_pos) + Vector2(0, tile_size / 2),
		str(tile_data.level),
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		font_size,
		Color.WHITE
	)

func draw_debug_darkness_info(screen_pos: Vector2i, tile_data) -> void:
	draw_string(
		font,
		Vector2(screen_pos) + Vector2(0, tile_size),
		str(tile_data.tile_darkness),
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		font_size,
		Color.BLUE
	)
