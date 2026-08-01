extends Node
class_name Movement

@export var MAX_SPEED := 275.0
@export var ACCEL := 600.0
@export var DESACCEL := 800.0

var _speed := 0.0
var current_velocity := Vector2.ZERO

func get_movement(delta: float, direction: Vector2 = Vector2.ZERO) -> Vector2:
	if direction != Vector2.ZERO:
		var target_velocity = direction * MAX_SPEED
		current_velocity = current_velocity.move_toward(target_velocity, ACCEL * delta)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, DESACCEL * delta)
		
	return current_velocity

## Fuerza a la velocidad actual a no superar un límite específico
func cap_velocity(limit: float) -> void:
	current_velocity = current_velocity.limit_length(limit)
