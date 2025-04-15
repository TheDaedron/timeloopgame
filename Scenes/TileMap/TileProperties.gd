extends Resource
class_name TileProperties

var is_walkable: bool = true
var level: int = 0
var tile_darkness: int = 100

func to_dict() -> Dictionary:
	return {
		"is_walkable": is_walkable,
		"level": level,
		"tile_darkness": tile_darkness
	}

func from_dict(data: Dictionary) -> TileProperties:
	is_walkable = data.get("is_walkable", true)
	level = data.get("level", 0)
	tile_darkness = data.get("tile_darkness", 100)
	return self
