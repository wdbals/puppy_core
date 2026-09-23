class_name Hitbox
extends Area2D
## Delivers HitData to overlapping HurtBox nodes.

signal hit_delivered(target_hurtbox: HurtBox, hit: HitData)

enum HitboxMode {
	CONTACT,
	MANUAL,
}

enum KnockbackDirection {
	FACING_DIRECTION,
	AWAY_FROM_HITBOX,
}

@export var mode: HitboxMode = HitboxMode.CONTACT
@export var damage_amount := 10.0
@export var knockback_force := 0.0
@export var knockback_direction: KnockbackDirection = KnockbackDirection.AWAY_FROM_HITBOX
@export var attack_cooldown := 0.5:
	set(value):
		attack_cooldown = maxf(value, 0.0)
		if _timer:
			_timer.wait_time = attack_cooldown

var _timer: Timer
var _hit_targets: Array[HurtBox] = []


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = attack_cooldown
	_timer.one_shot = true
	_timer.timeout.connect(_on_cooldown_finished)
	add_child(_timer)

	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)


func get_damage() -> float:
	return damage_amount


## Delivers a hit to every new HurtBox currently overlapping this area.
func attack() -> void:
	var hit_any_target := false
	for area in get_overlapping_areas():
		if area is HurtBox and _try_hit(area):
			hit_any_target = true

	if hit_any_target and _timer.is_stopped():
		_timer.start()


func reset_cooldown() -> void:
	_hit_targets.clear()
	if _timer:
		_timer.stop()


func activate() -> void:
	monitoring = true


func deactivate() -> void:
	monitoring = false


func _on_area_entered(area: Area2D) -> void:
	if mode == HitboxMode.MANUAL or not area is HurtBox:
		return
	if _try_hit(area) and _timer.is_stopped():
		_timer.start()


func _try_hit(target: HurtBox) -> bool:
	if target in _hit_targets:
		return false

	var hit := HitData.new(
		damage_amount,
		_calculate_knockback(target),
		self,
		target.global_position
	)
	if not target.receive_hit(hit):
		return false

	_hit_targets.append(target)
	hit_delivered.emit(target, hit)
	return true


func _calculate_knockback(target: HurtBox) -> Vector2:
	if is_zero_approx(knockback_force):
		return Vector2.ZERO

	var direction: Vector2
	match knockback_direction:
		KnockbackDirection.FACING_DIRECTION:
			direction = global_transform.x.normalized()
		KnockbackDirection.AWAY_FROM_HITBOX:
			direction = global_position.direction_to(target.global_position)
			if direction.is_zero_approx():
				direction = global_transform.x.normalized()

	return direction * knockback_force


func _on_cooldown_finished() -> void:
	_hit_targets.clear()
