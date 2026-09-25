class_name HitData3D
extends RefCounted
## Runtime description of a 3D combat hit.

var damage: float
var knockback: Vector3
var source: Node3D
var hit_position: Vector3


func _init(
	damage_value: float,
	knockback_value: Vector3 = Vector3.ZERO,
	source_node: Node3D = null,
	position: Vector3 = Vector3.ZERO
) -> void:
	damage = damage_value
	knockback = knockback_value
	source = source_node
	hit_position = position
