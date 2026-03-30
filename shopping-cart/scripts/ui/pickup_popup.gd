extends Control
class_name PickupPopup

@onready var label: Label = $Label

func show_text(text_value: String) -> void:
	label.text = text_value
	visible = true

	var tween: Tween = create_tween()
	modulate.a = 0.0
	position.y = 24.0
	tween.tween_property(self, "modulate:a", 1.0, 0.08)
	tween.tween_property(self, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.35)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	await tween.finished
	visible = false

