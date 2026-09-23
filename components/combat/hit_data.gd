class_name HitData
extends RefCounted
## Runtime description of a combat hit.

var damage: float
var knockback: Vector2
var source: Node2D
var hit_position: Vector2


func _init(
	damage_value: float,
	knockback_value: Vector2 = Vector2.ZERO,
	source_node: Node2D = null,
	position: Vector2 = Vector2.ZERO
) -> void:
	damage = damage_value
	knockback = knockback_value
	source = source_node
	hit_position = position
