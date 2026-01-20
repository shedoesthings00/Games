extends Control
class_name CharacterSlot

@export var character_data: CharacterData

@onready var portrait = $VBoxContainer/Portrait
@onready var name_label = $VBoxContainer/Name

func _ready():
	if character_data:
		name_label.text = character_data.name
		portrait.texture = character_data.portrait

func _get_drag_data(_at_position):
	var preview := TextureRect.new()
	preview.texture = character_data.portrait
	preview.custom_minimum_size = Vector2(64, 64)
	set_drag_preview(preview)

	return self
