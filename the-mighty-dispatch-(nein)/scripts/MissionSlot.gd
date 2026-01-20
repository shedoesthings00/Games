extends Panel

@export var mission_data: MissionData

@onready var mission_name_label: Label = $MissionName
@onready var drop_label: Label = $DropArea/Label
@onready var result_label: Label = $ResultLabel

var assigned_character: CharacterSlot = null


func _ready():
	if mission_data:
		mission_name_label.text = mission_data.mission_name
	result_label.text = ""


func _on_character_dropped(character: CharacterSlot):
	assigned_character = character
	drop_label.text = character.character_data.name
	result_label.text = ""


func _on_accept_button_pressed():
	if assigned_character == null:
		_fail("No hay personaje asignado")
		return

	var c := assigned_character.character_data
	var m := mission_data

	if c.strength < m.required_strength:
		_fail("Strength insuficiente")
		return

	if c.dexterity < m.required_dexterity:
		_fail("Dexterity insuficiente")
		return

	if c.constitution < m.required_constitution:
		_fail("Constitution insuficiente")
		return

	if c.intelligence < m.required_intelligence:
		_fail("Intelligence insuficiente")
		return

	if c.wisdom < m.required_wisdom:
		_fail("Wisdom insuficiente")
		return

	if c.charisma < m.required_charisma:
		_fail("Charisma insuficiente")
		return

	_success()


func _fail(reason: String) -> void:
	result_label.text = "❌ " + reason


func _success() -> void:
	result_label.text = "✅ Misión aceptada"
