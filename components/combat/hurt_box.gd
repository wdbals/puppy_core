class_name HurtBox
extends Area2D
## Receives HitData and forwards damage to a Health resource.

signal damaged(hit: HitData)

@export var health: Health


func _ready() -> void:
	if health:
		health = health.duplicate()
		health.initialize()


func receive_hit(hit: HitData) -> bool:
	if not health or not hit:
		return false
	health.take_damage(hit.damage)
	damaged.emit(hit)
	return true
