extends Node
class_name ProductCatalog

@export var products_folder: String = "res://data/products"

var _by_id: Dictionary = {}

func _ready() -> void:
	reload()

func reload() -> void:
	_by_id.clear()

	var dir: DirAccess = DirAccess.open(products_folder)
	if dir == null:
		push_warning("ProductCatalog: no existe la carpeta: %s" % products_folder)
		return

	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".tres") and not file_name.ends_with(".res"):
			continue

		var path: String = "%s/%s" % [products_folder, file_name]
		var res: Resource = ResourceLoader.load(path)
		var product := res as ProductData
		if product == null:
			continue

		var pid: String = product.id.strip_edges()
		if pid == "":
			push_warning("ProductCatalog: producto sin id en: %s" % path)
			continue

		_by_id[pid] = product

	dir.list_dir_end()

func get_product(product_id: String) -> ProductData:
	var v: Variant = _by_id.get(product_id, null)
	return v as ProductData

func has_product(product_id: String) -> bool:
	return _by_id.has(product_id)

func all_products() -> Array[ProductData]:
	var out: Array[ProductData] = []
	for k in _by_id.keys():
		var v: Variant = _by_id[k]
		var p := v as ProductData
		if p != null:
			out.append(p)
	return out

