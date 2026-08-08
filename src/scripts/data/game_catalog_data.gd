class_name GameCatalogData
extends Resource

## Catalog containing the available game option resources.

@export var games: Array[GameOptionData] = []


func get_game_by_id(id: String) -> GameOptionData:
	for game in games:
		if game != null and game.id == id:
			return game
	return null
