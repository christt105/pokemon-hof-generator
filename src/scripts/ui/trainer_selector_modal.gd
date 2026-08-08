class_name TrainerSelectorModal
extends CanvasLayer

## Full-screen modal overlay wrapper for the trainer selector panel.

signal trainer_chosen(texture: Texture2D)

@export var backdrop: ColorRect
@export var close_button: Button
@export var trainer_selector: PanelContainer


func _ready() -> void:
	close_button.pressed.connect(close_modal)
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	if trainer_selector != null and trainer_selector.has_signal("trainer_chosen"):
		trainer_selector.connect("trainer_chosen", _on_trainer_chosen)
	visible = false


func open_modal() -> void:
	visible = true


func close_modal() -> void:
	visible = false


func _on_trainer_chosen(texture: Texture2D) -> void:
	trainer_chosen.emit(texture)
	close_modal()


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_modal()
