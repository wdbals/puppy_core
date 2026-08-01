extends Camera2D
class_name Camera2DJuicy

var _shake_strength: float = 0.0

func _process(delta: float) -> void:
	if _shake_strength > 0.0:
		offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
		
		_shake_strength = lerpf(_shake_strength, 0.0, 10.0 * delta)
		
		if _shake_strength < 0.1:
			_shake_strength = 0.0
			offset = Vector2.ZERO

func apply_shake(strength: float = 5.0) -> void:
	_shake_strength = strength
