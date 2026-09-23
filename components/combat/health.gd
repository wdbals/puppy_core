class_name Health
extends Resource
## Reusable health resource with per-owner runtime state.

signal died
signal health_changed(health_left: float)

@export var max_health := 100.0

var _current_health: float:
	set(value):
		_current_health = value
		health_changed.emit(_current_health)
		if _current_health <= 0.0:
			died.emit()


func initialize() -> void:
	_current_health = max_health


func increase_health(amount: float) -> void:
	_current_health = clampf(_current_health + amount, 0.0, max_health)


func take_damage(amount: float) -> void:
	_current_health = clampf(_current_health - amount, 0.0, max_health)


func get_current_health() -> float:
	return _current_health


func get_health_percentage() -> float:
	if is_zero_approx(max_health):
		return 0.0
	return _current_health / max_health


func is_dead() -> bool:
	return _current_health <= 0.0
