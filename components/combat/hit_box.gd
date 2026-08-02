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

var _timer: Timer
# NUEVO: Lista para recordar a quién ya le hicimos daño
var _hit_targets: Array[Area2D] = [] 

func _ready() -> void:
	_timer = Timer.new()
	self.add_child(_timer)
	_timer.wait_time = attack_cooldown
	_timer.one_shot = true
	# Cuando termine el cooldown, olvidamos a quién golpeamos
	_timer.timeout.connect(_on_cooldown_finished) 
	
	monitoring = true
	monitorable = false
	
	area_entered.connect(_on_area_entered)

func get_damage() -> int:
	return _damage_amount

## Recomendado para usar en modo MANUAL
func attack() -> void:
	var hit_anyone = false
	
	for area in self.get_overlapping_areas():
		# Solo hacemos daño si es HurtBox y NO está en la lista
		if area is HurtBox and area not in _hit_targets:
			area.attack(_damage_amount)
			_hit_targets.append(area) # Lo registramos
			hit_anyone = true
			
	if hit_anyone:
		hit_delivered.emit()
		if _timer.is_stopped():
			_timer.start()

func _on_area_entered(area: Area2D) -> void:
	if mode == HitboxMode.MANUAL: 
		return
		
	# Misma lógica para el modo CONTACTO
	if area is HurtBox and area not in _hit_targets:
		area.attack(_damage_amount)
		_hit_targets.append(area)
		hit_delivered.emit()
		
		if _timer.is_stopped():
			_timer.start()

func reset_cooldown() -> void:
	_hit_targets.clear() # Vaciamos la lista manualmente
	if _timer:
		_timer.stop()

func _on_cooldown_finished() -> void:
	_hit_targets.clear()

func activate() -> void:
	monitoring = true

func deactivate() -> void:
	monitoring = false
