class_name GameOptionData
extends Resource

## Data resource representing configuration and metadata for a Pokémon game.

@export var id: String = ""
@export var name: String = ""
@export var generation: int = 1
@export var region: String = ""
@export var max_pokedex_number: int = 151
@export var is_supported: bool = false
@export var versions: Array[String] = []
@export var release_year: int = 2000
@export var hall_of_fame_capacity: int = 6
@export var sprite_style: String = "gen3"
@export var icon: Texture2D


func get_display_text() -> String:
	return "Gen %d - %s" % [generation, name]
