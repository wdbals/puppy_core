extends Resource
class_name Health

signal died
signal health_changed(health_left: float)

@export var MAX_HEALTH := 100

var _current_health : float:
	set(hp):
		_current_health = hp
		health_changed.emit(_current_health)
		if _current_health <= 0:
			died.emit()

func initialize() -> void:
	_current_health = MAX_HEALTH

func increased_health(hp: float):
	_current_health = clamp(_current_health + hp, 0, MAX_HEALTH)

func take_damage(hp: float):
	_current_health = clamp(_current_health - hp, 0, MAX_HEALTH)

func get_health_percentage() -> float:
	return _current_health / MAX_HEALTH

func is_dead() -> bool:
	return _current_health <= 0
