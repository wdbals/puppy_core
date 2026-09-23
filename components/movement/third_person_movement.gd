class_name ThirdPersonMovementComponent
extends IMovementComponent


func _physics_process(delta: float) -> void:
	if not body or not orientation_node:
		return

	if not body.is_on_floor():
		body.velocity.y -= gravity * delta

	input_direction = Input.get_vector(
		move_left_action,
		move_right_action,
		move_forward_action,
		move_backward_action
	)
	var speed_multiplier := 2.0 if Input.is_action_pressed(sprint_action) else 1.0

	var forward := orientation_node.global_basis.z
	var right := orientation_node.global_basis.x
	forward.y = 0.0
	right.y = 0.0

	var direction := (forward * input_direction.y + right * input_direction.x).normalized()
	var base_speed := backward_speed if input_direction.y > 0.0 else maximum_speed
	var current_speed := base_speed * speed_multiplier

	if direction != Vector3.ZERO:
		body.velocity.x = move_toward(body.velocity.x, direction.x * current_speed, acceleration * delta)
		body.velocity.z = move_toward(body.velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		body.velocity.x = move_toward(body.velocity.x, 0.0, friction * delta)
		body.velocity.z = move_toward(body.velocity.z, 0.0, friction * delta)

	body.move_and_slide()
