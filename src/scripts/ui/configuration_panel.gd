class_name ConfigurationPanel
extends PanelContainer

## Main configuration panel containing game selector, trainer info (name and sprite),
## and 6 Pokemon party slots.

signal game_changed(game_id: String)
signal trainer_changed(trainer_name: String, trainer_sprite: Texture2D)
signal party_slot_changed(slot_index: int, member_data: Dictionary)

const PARTY_SLOT_ITEM_SCENE = preload("uid://pf2qok72pjug")

@export var game_catalog: GameCatalogData
@export var game_options: Array[GameOptionData] = []
@export var game_option_button: OptionButton
@export var trainer_name_edit: LineEdit
@export var trainer_preview_rect: TextureRect
@export var select_trainer_button: Button
@export var upload_custom_button: Button
@export var slots_container: VBoxContainer
@export var trainer_selector_modal: CanvasLayer
@export var image_file_dialog: FileDialog

var _current_game_id: String = "emerald"
var _trainer_sprite: Texture2D
var _slot_items: Array = []


func _ready() -> void:
	_setup_game_options()
	_instantiate_party_slots()

	game_option_button.item_selected.connect(_on_game_selected)
	trainer_name_edit.text_changed.connect(_on_trainer_name_changed)
	select_trainer_button.pressed.connect(_on_select_trainer_pressed)
	upload_custom_button.pressed.connect(_on_upload_custom_pressed)
	if trainer_selector_modal != null and trainer_selector_modal.has_signal("trainer_chosen"):
		trainer_selector_modal.connect("trainer_chosen", _on_trainer_sprite_chosen)
	image_file_dialog.file_selected.connect(_on_file_selected)


func _setup_game_options() -> void:
	game_option_button.clear()
	game_options.clear()
	
	game_options = game_catalog.games
	
	for i in range(game_options.size()):
		var game_data := game_options[i]
		if game_data == null:
			continue
		game_option_button.add_item(game_data.get_display_text())
		game_option_button.set_item_metadata(i, game_data.id)
		game_option_button.set_item_disabled(i, not game_data.is_supported)
		
	if game_option_button.item_count > 0:
		game_option_button.select(0)


func get_selected_game_data() -> GameOptionData:
	var selected_idx := game_option_button.selected
	if selected_idx >= 0 and selected_idx < game_options.size():
		return game_options[selected_idx]
	return null


func _instantiate_party_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	_slot_items.clear()
	
	for i in range(6):
		var slot_instance: Node = PARTY_SLOT_ITEM_SCENE.instantiate()
		slot_instance.set("slot_index", i)
		slots_container.add_child(slot_instance)
		if slot_instance.has_signal("slot_changed"):
			slot_instance.connect("slot_changed", _on_party_slot_changed)
		_slot_items.append(slot_instance)


func _on_game_selected(index: int) -> void:
	var game_id: String = game_option_button.get_item_metadata(index)
	_current_game_id = game_id
	game_changed.emit(game_id)


func _on_trainer_name_changed(_new_name: String) -> void:
	trainer_changed.emit(trainer_name_edit.text.strip_edges(), _trainer_sprite)


func _on_select_trainer_pressed() -> void:
	if trainer_selector_modal.has_method("open_modal"):
		trainer_selector_modal.open_modal()
	else:
		trainer_selector_modal.visible = true


func _on_upload_custom_pressed() -> void:
	image_file_dialog.popup_centered(Vector2i(700, 500))


func _on_trainer_sprite_chosen(texture: Texture2D) -> void:
	_trainer_sprite = texture
	trainer_preview_rect.texture = texture
	trainer_changed.emit(trainer_name_edit.text.strip_edges(), _trainer_sprite)


func _on_file_selected(path: String) -> void:
	var image := Image.load_from_file(path)
	if image != null and not image.is_empty():
		var texture := ImageTexture.create_from_image(image)
		_on_trainer_sprite_chosen(texture)


func _on_party_slot_changed(slot_idx: int, member_data: Dictionary) -> void:
	party_slot_changed.emit(slot_idx, member_data)


func is_valid() -> bool:
	if trainer_name_edit.text.strip_edges().is_empty():
		return false
	for slot in _slot_items:
		if slot.has_method("has_pokemon") and slot.has_pokemon():
			return true
	return false


func get_party_members() -> Array[Dictionary]:
	var members: Array[Dictionary] = []
	for slot in _slot_items:
		if slot.has_method("has_pokemon") and slot.has_pokemon():
			members.append(slot.get_member_data())
	return members
