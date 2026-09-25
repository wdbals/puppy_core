class_name HurtBox3D
extends Area3D
## Receives HitData3D and forwards damage to a Health resource.

signal damaged(hit: HitData3D)

@export var health: Health


func _ready() -> void:
	if health:
		health = health.duplicate()
		health.initialize()


func receive_hit(hit: HitData3D) -> bool:
	if not health or not hit:
		return false
	health.take_damage(hit.damage)
	damaged.emit(hit)
	return true
