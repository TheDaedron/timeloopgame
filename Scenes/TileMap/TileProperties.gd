extends Resource
class_name TileProperties

# Backing variables
var _is_walkable: bool = true
var _level: int = 0
var _tile_darkness: int = 100

# Properties with setters
var is_walkable: bool:
	get: 
		return _is_walkable
	set(value):
		if _is_walkable != value:
			_is_walkable = value

var level: int:
	get: return _level
	set(value):
		if _level != value:
			_level = value

var tile_darkness: int:
	get: return _tile_darkness
	set(value):
		if _tile_darkness != value:
			_tile_darkness = value


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
