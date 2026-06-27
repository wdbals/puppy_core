class_name AnimationComponent extends Node

@export var movement: ThirdPersonMovementComponent
@export var anim_player: AnimationPlayer

func _process(delta: float) -> void:
	if not movement or not movement.body or not anim_player: return
	
	var vel_horizontal = Vector2(movement.body.velocity.x, movement.body.velocity.z).length()
	
	if vel_horizontal > 0.1:
		if anim_player.current_animation != "walk":
			anim_player.play("walk")
	else:
		if anim_player.current_animation != "idle":
			anim_player.speed_scale = 1.0
			anim_player.play("idle")
