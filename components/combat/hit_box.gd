extends Area2D
class_name Hitbox

signal hit_delivered

enum HitboxMode {
	## Daño automático al entrar en contacto
	CONTACT,
	## Daño invocado por código a múltiples objetivos dentro
	MANUAL
}

@export var mode: HitboxMode = HitboxMode.CONTACT
@export var _damage_amount: int = 10
@export var attack_cooldown: float = 0.5:
	set(time):
		attack_cooldown = time
		if _timer: _timer.wait_time = time
@export var can_fail := true

var _can_attack = true
var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	self.add_child(_timer)
	_timer.wait_time = attack_cooldown
	_timer.one_shot = true
	_timer.timeout.connect(func(): _can_attack = true)
	
	monitoring = true
	monitorable = false
	
	area_entered.connect(_on_area_entered)

func get_damage() -> int:
	return _damage_amount

## Recomendado para usar en modo MANUAL
func attack() -> void:
	if not _can_attack: return
	
	var hit_anyone = false
	
	for area in self.get_overlapping_areas():
		if area is HurtBox:
			area.attack(_damage_amount)
			hit_anyone = true
			
	
	if hit_anyone:
		hit_delivered.emit()
		_can_attack = false
		_timer.start()

func _on_area_entered(area: Area2D) -> void:
	if mode == HitboxMode.MANUAL: 
		return
		
	if not _can_attack: 
		return
	
	if area is HurtBox:
		area.attack(_damage_amount)
		hit_delivered.emit()
		_can_attack = false
		_timer.start()

func reset_cooldown() -> void:
	_can_attack = true
	if _timer:
		_timer.stop()

func activate() -> void:
	monitoring = true

func deactivate() -> void:
	monitoring = false
