extends Control

signal pickup_pressed(product_id: String)

@onready var title_label: Label = %TitleLabel
@onready var products_list: ItemList = %ProductsList
@onready var pickup_button: Button = %PickupButton
@onready var hint_label: Label = %HintLabel
@onready var progress: ProgressBar = %PickupProgress

var _catalog: ProductCatalog
var _current_shelf: Shelf
var _selected_product_id: String = ""

func _ready() -> void:
	visible = false
	progress.visible = false
	progress.value = 0.0

	pickup_button.pressed.connect(_on_pickup_pressed)
	products_list.item_selected.connect(_on_item_selected)

func set_catalog(catalog: ProductCatalog) -> void:
	_catalog = catalog

func open_for_shelf(shelf: Shelf) -> void:
	_current_shelf = shelf
	_selected_product_id = ""
	visible = true

	title_label.text = "Estantería"
	hint_label.text = "Elige un producto"
	_refresh_list()

func close() -> void:
	visible = false
	_current_shelf = null
	_selected_product_id = ""
	products_list.clear()
	progress.visible = false
	progress.value = 0.0

func set_pickup_enabled(enabled: bool) -> void:
	pickup_button.disabled = not enabled
	# ItemList no tiene propiedad `disabled` en Godot 4.
	# Para bloquear interacción durante la recogida, ignoramos input.
	products_list.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

func show_progress(p: float) -> void:
	progress.visible = true
	progress.value = clampf(p, 0.0, 1.0) * 100.0

func hide_progress() -> void:
	progress.visible = false
	progress.value = 0.0

func get_selected_product_id() -> String:
	return _selected_product_id

func _refresh_list() -> void:
	products_list.clear()
	if _current_shelf == null:
		return

	var ids: PackedStringArray = _current_shelf.product_ids
	for i in ids.size():
		var pid: String = ids[i]
		var name: String = pid
		var icon: Texture2D = null
		var tag: String = ""
		if _catalog != null:
			var p: ProductData = _catalog.get_product(pid)
			if p != null:
				name = p.display_name
				icon = p.icon
				tag = "(lento)" if p.pickup_time >= 0.9 else "(rápido)"

		var idx: int = products_list.add_item("%s %s" % [name, tag], icon)
		products_list.set_item_metadata(idx, pid)

	if products_list.item_count > 0:
		products_list.select(0)
		_on_item_selected(0)

func _on_item_selected(index: int) -> void:
	var meta: Variant = products_list.get_item_metadata(index)
	_selected_product_id = str(meta)

func _on_pickup_pressed() -> void:
	if _selected_product_id.strip_edges() == "":
		return
	pickup_pressed.emit(_selected_product_id)
