extends Panel

## Visual trainer picker: search + category filter over a grid of family
## thumbnails (one per character/class, redraws collapsed), then a variant
## strip to pick the exact sprite once a family is selected.

signal trainer_chosen(texture: Texture2D)

const TRAINER_CATALOG = preload("uid://b3e1ol1ebde30")

# How many icons to load per frame while filling FamilyList. Keeps a fresh
# search/filter from blocking the (single-threaded, web-exported) UI thread.
const ICONS_PER_FRAME := 60

@onready var search_edit: LineEdit = $VBoxContainer/Toolbar/SearchEdit
@onready var category_option: OptionButton = $VBoxContainer/Toolbar/CategoryOption
@onready var family_list: ItemList = $VBoxContainer/FamilyList
@onready var variant_row: HBoxContainer = $VBoxContainer/PreviewPanel/PreviewBox/VariantScroll/VariantRow
@onready var preview_texture: TextureRect = $VBoxContainer/PreviewPanel/PreviewBox/PreviewHeader/PreviewTexture
@onready var name_label: Label = $VBoxContainer/PreviewPanel/PreviewBox/PreviewHeader/PreviewLabels/NameLabel
@onready var credit_label: Label = $VBoxContainer/PreviewPanel/PreviewBox/PreviewHeader/PreviewLabels/CreditLabel
@onready var confirm_button: Button = $VBoxContainer/PreviewPanel/PreviewBox/ConfirmButton

var _all_families: Array[TrainerCatalogFamilyData] = []
var _visible_families: Array[TrainerCatalogFamilyData] = []
var _selected_family: TrainerCatalogFamilyData
var _selected_variant: TrainerSpriteData
var _variant_button_group := ButtonGroup.new()
var _fill_token := 0  # bumped on every new filter so a stale batched fill bails out


func _ready() -> void:
	if TRAINER_CATALOG != null:
		_all_families = TRAINER_CATALOG.families
	else:
		printerr("ConfiguratorPanel: TRAINER_CATALOG not found - run tools/sync_trainer_sprites.gd once to generate it")
	_populate_category_options()

	search_edit.text_changed.connect(func(_new_text: String) -> void: _refresh_family_list())
	category_option.item_selected.connect(func(_index: int) -> void: _refresh_family_list())
	family_list.item_selected.connect(_on_family_item_selected)
	confirm_button.pressed.connect(_on_confirm_pressed)

	_refresh_family_list()


func _populate_category_options() -> void:
	category_option.add_item("Todos (%d)" % _all_families.size())
	category_option.set_item_metadata(0, "")
	for category: String in TrainerCatalogData.CATEGORY_ORDER:
		var count := 0
		for family: TrainerCatalogFamilyData in _all_families:
			if family.category == category:
				count += 1
		category_option.add_item("%s (%d)" % [TrainerCatalogData.CATEGORY_LABELS[category], count])
		category_option.set_item_metadata(category_option.item_count - 1, category)


func _refresh_family_list() -> void:
	_fill_token += 1
	var token := _fill_token

	var query := search_edit.text.strip_edges().to_lower()
	var category: String = category_option.get_selected_metadata() if category_option.selected >= 0 else ""

	_visible_families = _all_families.filter(func(family: TrainerCatalogFamilyData) -> bool:
		if category != "" and family.category != category:
			return false
		if query != "" and not family.display_name.to_lower().contains(query):
			return false
		return true
	)

	family_list.clear()
	_fill_family_list_batched(token)


func _fill_family_list_batched(token: int) -> void:
	var index := 0
	while index < _visible_families.size():
		if token != _fill_token:
			return  # a newer search/filter change superseded this fill
		var batch_end: int = mini(index + ICONS_PER_FRAME, _visible_families.size())
		for i in range(index, batch_end):
			var family: TrainerCatalogFamilyData = _visible_families[i]
			var cover: TrainerSpriteData = family.variants[0]
			var texture: Texture2D = cover.sprite
			var item_index := family_list.add_item(family.display_name, texture)
			family_list.set_item_metadata(item_index, i)
			if family.variants.size() > 1:
				family_list.set_item_tooltip(item_index, "%d variants" % family.variants.size())
		index = batch_end
		if index < _visible_families.size():
			await get_tree().process_frame


func _on_family_item_selected(item_index: int) -> void:
	var family_index: int = family_list.get_item_metadata(item_index)
	_selected_family = _visible_families[family_index]
	_populate_variant_row()


func _populate_variant_row() -> void:
	for child: Node in variant_row.get_children():
		child.queue_free()

	for variant: TrainerSpriteData in _selected_family.variants:
		var button := TextureButton.new()
		button.texture_normal = variant.sprite
		button.ignore_texture_size = true
		button.custom_minimum_size = Vector2(48, 48)
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.tooltip_text = variant.display_name
		button.toggle_mode = true
		button.button_group = _variant_button_group
		button.pressed.connect(_select_variant.bind(variant))
		variant_row.add_child(button)

	if _selected_family.variants.size() > 0:
		var first_button: TextureButton = variant_row.get_child(0)
		first_button.button_pressed = true
		_select_variant(_selected_family.variants[0])


func _select_variant(variant: TrainerSpriteData) -> void:
	_selected_variant = variant
	var texture: Texture2D = variant.sprite
	preview_texture.texture = texture
	name_label.text = variant.display_name
	credit_label.text = ("Sprite: %s" % variant.credit) if variant.credit != "" else "Sprite: Pokémon Showdown"
	confirm_button.disabled = false


func _on_confirm_pressed() -> void:
	trainer_chosen.emit(preview_texture.texture)
