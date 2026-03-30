extends PanelContainer

@onready var label: Label = %MoneyLabel

var _money: MoneyManager

func _ready() -> void:
	_money = get_tree().current_scene.find_child("MoneyManager", true, false) as MoneyManager
	if _money != null:
		_money.money_changed.connect(_on_money_changed)
	_on_money_changed(_money.money if _money != null else 0.0)

func _on_money_changed(amount: float) -> void:
	# Formato simple (EUR). Si quieres otra moneda, lo cambiamos.
	label.text = "€ %.2f" % amount

