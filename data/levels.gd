class_name LevelCatalog
extends RefCounted


static func get_level(level_id: int) -> Dictionary:
	for level in all():
		if int(level.id) == level_id:
			return level
	return {}


static func all() -> Array:
	return [
		{
			"id": 1,
			"book_key": "book_genesis",
			"name_key": "level_creation",
			"verse_key": "verse_genesis_1_1",
			"reference_key": "ref_genesis_1_1",
			"width": 8,
			"height": 8,
			"moves": 25,
			"pieces": ["sun", "moon", "earth", "time", "stars"],
			"goals": {"sun": 12, "earth": 12, "moon": 10},
			"playable": true,
		},
		{
			"id": 2,
			"book_key": "book_genesis",
			"name_key": "level_garden",
			"playable": false,
		},
		{
			"id": 3,
			"book_key": "book_genesis",
			"name_key": "level_flood",
			"playable": false,
		},
		{
			"id": 4,
			"book_key": "book_genesis",
			"name_key": "level_promise",
			"playable": false,
		},
		{
			"id": 5,
			"book_key": "book_genesis",
			"name_key": "level_joseph",
			"playable": false,
		},
	]
