class_name Movement
extends Node

@export var max_speed := 275.0
@export var acceleration := 600.0
@export var deceleration := 800.0

var current_velocity := Vector2.ZERO


func get_movement(delta: float, direction: Vector2 = Vector2.ZERO) -> Vector2:
	if direction != Vector2.ZERO:
		var target_velocity := direction * max_speed
		current_velocity = current_velocity.move_toward(target_velocity, acceleration * delta)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration * delta)
	return current_velocity


## Restricts the current velocity to the given maximum length.
func cap_velocity(limit: float) -> void:
	current_velocity = current_velocity.limit_length(limit)
