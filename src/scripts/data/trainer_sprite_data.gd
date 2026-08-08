class_name TrainerSpriteData
extends Resource

@export var display_name: String
@export var sprite: Texture2D
@export var credit: String

func _init(_display_name: String = "", _sprite: Texture2D = null, _credit: String = "") -> void:
	display_name = _display_name
	sprite = _sprite
	credit = _credit
