extends CharacterBody3D

@onready var camera = $Camera3D
@onready var ui = $DintHud

## The mouse sensitivity
@export var sensitivity: float = 0.001

## The max angle that the camera pitch won't go past
@export var pitch_clamp_angle: float = 90

@export_group("Movement")
## The speed while walking where inputs stop being added
@export var max_walk_input_speed: float = 4.0
## The speed where inputs stop being added
@export var max_input_speed: float = 8.0
## The rate at which the player will speed up while walking
@export var walk_acceleration: float = 36.0
## The rate at which the player will speed up while running
@export var run_acceleration: float = 70.0
## The rate at which the player will slow down while still
@export var deceleration: float = 48.0
## The strength the player jumps
@export var jump_strength: float = 4.4
## The divisor of the in air acceleration (air control)
@export var air_acceleration_div: float = 4.0

# Is the player walking
var walking: bool = false

@export_group("View Bob")
## Speed of the view bob
@export var bob_frequency: float = 2.0

## Height/Intensity of the view bob
@export var bob_up_amplitude: float = 0.01
@export var bob_side_amplitude: float = 0.03
@export var bob_return_strength: float = 8.0
# The current view bob amount/delta
var bob_amount: float = 0.0
# The starting position of the camera
@onready var camera_start_pos = $Camera3D.position

@onready var viewmodel_base = $Camera3D/ViewmodelDoodle
@onready var viewmodel = $Camera3D/ViewmodelDoodle/RixinGameRig

func _ready() -> void:
	# Setup for local client
	camera.current = is_multiplayer_authority()
	ui.ui_camera.current = is_multiplayer_authority()
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
	
	# View bob
	if is_on_floor() && velocity.length() > 0.1:
		bob_amount += delta * velocity.length() * float(is_on_floor())
		camera.position += view_bob(bob_amount)
		viewmodel.global_position = viewmodel_base.global_position - view_bob(bob_amount)
	else:
		camera.position = camera.position.lerp(camera_start_pos, delta * bob_return_strength)
		viewmodel.global_position = viewmodel.global_position.lerp(viewmodel_base.global_position, delta * bob_return_strength)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_rotate(event.relative * sensitivity)
	
	if event.is_action_pressed("move_walk"):
		walking = true
	elif event.is_action_released("move_walk"):
		walking = false
		
	if event.is_action_pressed("move_jump") && is_on_floor():
		velocity.y = jump_strength

## Move the player in a 2d direction vector and a given delta time
func move(in_dir: Vector2, delta: float) -> void:
	# Running or walking
	var max_speed := max_walk_input_speed if walking else max_input_speed
	var acceleration := run_acceleration if walking else walk_acceleration
	acceleration = acceleration if is_on_floor() else acceleration / air_acceleration_div
	
	# The movement direction and speed
	var direction := (transform.basis * Vector3(in_dir.x, 0, in_dir.y))
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

## Returns a bob position based on the bob time
func view_bob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_frequency) * bob_up_amplitude
	pos.x = cos(time * (bob_frequency / 2.0)) * (bob_side_amplitude / 2.0)
	return pos
