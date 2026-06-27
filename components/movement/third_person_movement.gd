class_name ThirdPersonMovementComponent extends IMovementComponent

func _physics_process(delta: float) -> void:
	if not body or not orientation_node: return

	# 1. Gravedad
	if not body.is_on_floor():
		body.velocity.y -= gravedad * delta

	# 2. Input de movimiento
	input_dir = Input.get_vector("izquierda", "derecha", "adelante", "atras")
	if Input.is_action_just_pressed("sprintar"): velocidad_maxima *= 2
	elif Input.is_action_just_released("sprintar"): velocidad_maxima /= 2
	
	# Obtener dirección plana (sin Y) basada en el nodo de orientación
	var forward = orientation_node.global_basis.z
	var right = orientation_node.global_basis.x
	forward.y = 0; right.y = 0
	
	var direccion: Vector3 = (forward * input_dir.y + right * input_dir.x).normalized()
	var velocidad_actual: float = velocidad_retroceso if input_dir.y > 0.0 else velocidad_maxima

	# 3. Aplicar Aceleración o Fricción
	if direccion != Vector3.ZERO:
		body.velocity.x = move_toward(body.velocity.x, direccion.x * velocidad_actual, aceleracion * delta)
		body.velocity.z = move_toward(body.velocity.z, direccion.z * velocidad_actual, aceleracion * delta)
	else:
		body.velocity.x = move_toward(body.velocity.x, 0.0, friccion * delta)
		body.velocity.z = move_toward(body.velocity.z, 0.0, friccion * delta)

	body.move_and_slide()
