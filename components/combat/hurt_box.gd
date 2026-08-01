extends Area2D
class_name HurtBox

@export var health: Health

signal damaged(damage_amount)

func _ready() -> void:
	if health:
		health = health.duplicate()
		health.initialize()

func attack(dmg: float) -> bool:
	if not health: 
		return false
	health.take_damage(dmg)
	damaged.emit(dmg)
	return true
