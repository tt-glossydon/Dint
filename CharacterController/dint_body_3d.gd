extends CharacterBody3D

@onready var camera = $Camera3D

## The mouse sensitivity
@export var sensitivity: float = 0.001

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
var running: bool = true

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	camera.current = is_multiplayer_authority()
	set_physics_process(is_multiplayer_authority())
	set_process_unhandled_input(is_multiplayer_authority())
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	move(input, delta)
	
	# Fall
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	mouse_rotate(
		Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), 
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)) * sensitivity * 40.0)
	
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_rotate(event.relative * sensitivity)
	
	if event.is_action_pressed("move_sprint"):
		running = false
	elif event.is_action_released("move_sprint"):
		running = true

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
