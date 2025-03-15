extends VBoxContainer

var border_color := Color(1, 0, 0, 1)  # Red color for visibility
var border_width := 2  # Thickness of the border

func _ready():
	queue_redraw()  # Ensure it draws immediately

func _draw():
	var size = get_size()
	draw_rect(Rect2(Vector2.ZERO, size), border_color, false, border_width)
