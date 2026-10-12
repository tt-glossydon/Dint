extends CharacterBody3D

@onready var camera = $Camera3D

## The max angle that the camera pitch won't go past
@export var pitch_clamp_angle: float = 90

@export_group("Movement")
## The speed while walking where inputs stop being added
@export var max_walk_input_speed: float = 4.0
## The speed while running where inputs stop being added
@export var max_run_input_speed: float = 8.0
## The rate at which the player will speed up while walking
@export var walk_acceleration: float = 36.0
## The rate at which the player will speed up while running
@export var run_acceleration: float = 70.0
## The rate at which the player will slow down while still
@export var deceleration: float = 48.0

# Is the player running/sprinting
var running: bool = false

func _physics_process(delta: float) -> void:
	# Fall
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	
## Move the player in a 2d direction vector and a given delta time
func move(in_dir: Vector2, delta: float) -> void:
	# Running or walking
	var max_speed := max_run_input_speed if running else max_walk_input_speed
	var acceleration := run_acceleration if running else walk_acceleration
	
	# The movement direction and speed
	var direction := (transform.basis * Vector3(in_dir.x, 0, in_dir.y)).normalized()
	var target := direction * max_speed
	var rate := acceleration if direction != Vector3.ZERO else deceleration

	# The new velocity
	var tmp_velocity := Vector3(velocity.x, 0, velocity.z)
	tmp_velocity = tmp_velocity.move_toward(target, rate * delta)
	tmp_velocity = tmp_velocity.limit_length(max_speed)

	velocity.x = tmp_velocity.x
	velocity.z = tmp_velocity.z
	
## Rotate the player and camera
func mouse_rotate(rot: Vector2) -> void:
	rotate_y(-rot.x)
	camera.rotate_x(-rot.y)
	camera.rotation.x = clamp(
		camera.rotation.x, 
		deg_to_rad(-pitch_clamp_angle), 
		deg_to_rad(pitch_clamp_angle))
