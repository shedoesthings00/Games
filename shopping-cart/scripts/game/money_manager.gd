extends Node
class_name MoneyManager

signal money_changed(new_amount: float)

@export var starting_money: float = 50.0

var money: float = 0.0

func _ready() -> void:
	money = starting_money
	money_changed.emit(money)

func can_pay(amount: float) -> bool:
	return money >= amount

func pay(amount: float) -> bool:
	if amount < 0.0:
		return false
	if not can_pay(amount):
		return false
	money -= amount
	money_changed.emit(money)
	return true

func add(amount: float) -> void:
	money += amount
	money_changed.emit(money)

