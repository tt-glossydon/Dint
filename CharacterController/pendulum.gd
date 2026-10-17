extends Node3D

@export var anchor : Node3D
@export var dist : float:
	set(to_what):
		dist = clampf(to_what, 3, 15)

@export var angle : float = 0.0
@export var wish_dir : float = 1
@export var angular_velocity : float = 25.0
@export var angular_acceleration : float = 10.0
@export var y_rotation : float = 0.0

func _process(delta:float):
	# Perform acceleration
	angular_velocity += (angular_acceleration*delta)*wish_dir
	angle += (angular_velocity*delta)
	
	# Invert directionality of wish_dir
	if (wish_dir > 0 and angle > 0) or (wish_dir < 0 and angle < 0):
		wish_dir = -wish_dir
	
	# Vector-based calculations
	var pendulum_dir : Vector3 = Vector3.DOWN
	var pendulum_side := anchor.global_basis.x
	
	pendulum_dir = pendulum_dir.rotated(pendulum_side, deg_to_rad(angle))
	
	# Application of all calculations
	global_position = anchor.global_position + ((pendulum_dir.rotated(Vector3.UP, y_rotation))*dist)
	global_rotation.y = y_rotation
