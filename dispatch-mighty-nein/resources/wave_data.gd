class_name WaveData
extends Resource
## Recurso que define una oleada/misión: briefing, requisitos y recompensas.

@export var wave_index: int = 0
@export var briefing: String = ""
@export var difficulty: int = 1  ## 1=Easy, 2=Medium, 3=High
## Tipo de misión para habilidades que hacen match (ej. "investigation", "combat", "stealth")
@export var mission_type: String = ""

## Requisitos por stat: nombre del stat -> valor mínimo deseado (no se muestran al jugador)
@export var requirements: Dictionary = {}  ## e.g. {"combat": 20, "intellect": 15}
## Texto narrativo de lo que pide la misión (sin números): ej. "Alguien que piense y alguien rápido"
@export var requirements_description: String = ""

@export var xp_reward: int = 10
@export var gold_reward: int = 5

func get_required_total() -> int:
	var total := 0
	for v in requirements.values():
		total += int(v)
	return total
