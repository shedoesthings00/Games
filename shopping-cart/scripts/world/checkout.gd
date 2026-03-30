extends Area3D
class_name Checkout

@export var catalog_path: NodePath
@export var missions_manager_path: NodePath
@export var money_manager_path: NodePath
@export var feedback_path: NodePath

@onready var catalog: ProductCatalog = get_node_or_null(catalog_path) as ProductCatalog
@onready var missions_manager: MissionsManager = get_node_or_null(missions_manager_path) as MissionsManager
@onready var money_manager: MoneyManager = get_node_or_null(money_manager_path) as MoneyManager
@onready var feedback: PickupFeedback = get_node_or_null(feedback_path) as PickupFeedback

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if missions_manager == null or money_manager == null:
		return

	var completed: Array[Mission] = missions_manager.completed_missions()
	if completed.is_empty():
		if feedback != null:
			feedback.show_message("No hay misiones completas para cobrar")
		return

	var inv_v: Variant = body.get("inventory")
	var inv := inv_v as Inventory

	var total_paid: float = 0.0
	var paid_count: int = 0
	for m: Mission in completed:
		var total: float = _compute_total_for_mission(m)
		if total <= 0.0:
			continue
		if not money_manager.can_pay(total):
			break

		if not money_manager.pay(total):
			break

		# Consume inventario (si existe) según lo requerido.
		if inv != null:
			for pid: String in m.all_product_ids():
				var qty: int = m.required_qty(pid)
				if qty > 0:
					inv.consume(pid, qty)

		missions_manager.remove_mission(m)
		total_paid += total
		paid_count += 1

	if feedback != null:
		if paid_count > 0:
			feedback.show_message("Cobradas %d misiones: € %.2f" % [paid_count, total_paid])
		else:
			feedback.show_message("No tienes dinero suficiente")

func _compute_total_for_mission(m: Mission) -> float:
	var sum: float = 0.0
	for pid: String in m.all_product_ids():
		var qty: int = m.required_qty(pid)
		if qty <= 0:
			continue
		var price: float = 1.0
		if catalog != null:
			var p: ProductData = catalog.get_product(pid)
			if p != null:
				price = p.price
		sum += price * float(qty)
	return sum

