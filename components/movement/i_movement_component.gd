class_name IMovementComponent
extends Node3D

@export var body: CharacterBody3D
@export var orientation_node: Node3D

@export_group("Movement Configuration")
@export var maximum_speed := 5.0
@export var backward_speed := 2.5
@export var acceleration := 15.0
@export var friction := 20.0

@export_group("Input Actions")
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var move_forward_action: StringName = &"move_forward"
@export var move_backward_action: StringName = &"move_backward"
@export var sprint_action: StringName = &"sprint"

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var input_direction := Vector2.ZERO


## Override this method in concrete movement components.
func _physics_process(_delta: float) -> void:
	push_error("IMovementComponent._physics_process() must be overridden")
