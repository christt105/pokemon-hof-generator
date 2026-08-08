class_name PartySlotItem
extends PanelContainer

## Represents a single Pokemon slot in the party configuration layout.

signal slot_changed(slot_index: int, member_data: Dictionary)

@export var slot_label: Label
@export var clear_button: Button
@export var pokemon_search_edit: LineEdit
@export var form_option_button: OptionButton
@export var sprite_preview: TextureRect
@export var nickname_edit: LineEdit
@export var level_spin_box: SpinBox
@export var gender_option_button: OptionButton

var slot_index: int = 0:
	set(value):
		slot_index = value
		if is_inside_tree() and slot_label != null:
			slot_label.text = "Slot #%d" % (slot_index + 1)


func _ready() -> void:
	slot_label.text = "Slot #%d" % (slot_index + 1)
	_populate_gender_options()

	clear_button.pressed.connect(clear_slot)
	pokemon_search_edit.text_changed.connect(func(_text: String) -> void: _notify_change())
	form_option_button.item_selected.connect(func(_idx: int) -> void: _notify_change())
	nickname_edit.text_changed.connect(func(_text: String) -> void: _notify_change())
	level_spin_box.value_changed.connect(func(_val: float) -> void: _notify_change())
	gender_option_button.item_selected.connect(func(_idx: int) -> void: _notify_change())


func _populate_gender_options() -> void:
	gender_option_button.clear()
	gender_option_button.add_item("♂")
	gender_option_button.add_item("♀")
	gender_option_button.add_item("⚪")


func clear_slot() -> void:
	pokemon_search_edit.text = ""
	nickname_edit.text = ""
	level_spin_box.value = 50
	gender_option_button.selected = 0
	form_option_button.visible = false
	sprite_preview.texture = null
	_notify_change()


func set_sprite(texture: Texture2D) -> void:
	sprite_preview.texture = texture


func has_pokemon() -> bool:
	return not pokemon_search_edit.text.strip_edges().is_empty()


func get_member_data() -> Dictionary:
	var gender_str := "M"
	match gender_option_button.selected:
		0:
			gender_str = "M"
		1:
			gender_str = "F"
		2:
			gender_str = "N"

	return {
		"slot_index": slot_index,
		"species_name": pokemon_search_edit.text.strip_edges(),
		"nickname": nickname_edit.text.strip_edges(),
		"level": int(level_spin_box.value),
		"gender": gender_str,
		"form": form_option_button.get_item_text(form_option_button.selected) if form_option_button.visible and form_option_button.selected >= 0 else "",
		"sprite": sprite_preview.texture,
	}


func _notify_change() -> void:
	slot_changed.emit(slot_index, get_member_data())
