class_name TrainerCatalogFamilyData
extends Resource

@export var category: String
@export var display_name: String
@export var key: String
@export var variants: Array[TrainerSpriteData]

func _init(_category: String = "", _display_name: String = "", _key: String = "", _variants: Array[TrainerSpriteData] = []) -> void:
	category = _category
	display_name = _display_name
	key = _key
	variants = _variants
