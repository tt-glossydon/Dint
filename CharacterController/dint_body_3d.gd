extends CharacterBody3D

@onready var camera := $Camera3D as Camera3D
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
var bob_offset: Vector3 = Vector3.ZERO
var bob_interp_factor: float = 0.0:
	set(to_what):
		bob_interp_factor = clampf(to_what, 0.0, 1.0)
# The starting position of the camera
@onready var camera_start_pos := camera.position as Vector3

@onready var vm_sway := $Camera3D/VM_Sway as Node3D
@onready var viewmodel_base := $Camera3D/SurvivorRigVM_Test as Node3D
@onready var viewmodel := $Camera3D/SurvivorRigVM_Test/rig as Node3D

# We can probably remove this later, since it's a bit screwy.
@onready var animtree_vm : AnimationTree = $AnimationTree as AnimationTree
@onready var animtree_3p : AnimationTree

@export var viewmodel_spring : ValueSpring
@onready var viewmodel_sway_dir : Vector3 = Vector3.ZERO:
	set(to_what):
		viewmodel_sway_dir = Vector3(clampf(to_what.x, -2, 2), clampf(to_what.y, -2, 2), to_what.z)
@onready var viewmodel_pull_interp_factor : float = 0.0:
	set(to_what):
		viewmodel_pull_interp_factor = clampf(to_what, 0.0, 1.0)

@export var viewmodel_recoil_spring : ValueSpring
@onready var viewmodel_recoil : Vector2 = Vector2.ZERO

var ammo : int = 8

func _ready() -> void:
	viewmodel_spring._previousValue = Vector2.ZERO
	viewmodel_spring._currentValue = Vector2.ZERO
	viewmodel_spring.reset_spring(Vector2.ZERO)
	viewmodel_recoil_spring.reset_spring(Vector2.ZERO)
	
	ui.player_camera = camera
	
	# Setup for local client
	camera.current = is_multiplayer_authority()
	ui.ui_camera.current = is_multiplayer_authority()
	set_physics_process(is_multiplayer_authority())
	set_process_unhandled_input(is_multiplayer_authority())
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	move(input, delta)
	
	# Fall
	if not is_on_floor():
		velocity += (get_gravity()*4.0) * delta
	
	mouse_rotate(
		Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), 
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)) * sensitivity * 40.0)
	
	move_and_slide()
	
	# View bob
	bob_offset = view_bob(bob_amount)
	if is_on_floor() && (velocity*Vector3(1, 0, 1)).length() > 0.1:
		# Multiplying by a flat Vector3 ignores vertical speed
		bob_interp_factor += (delta*0.75) * (velocity*Vector3(1, 0, 1)).length() * float(is_on_floor())
		bob_amount += delta * (velocity*Vector3(1, 0, 1)).length() * float(is_on_floor())
		camera.position += bob_offset*bob_interp_factor
		viewmodel.global_position = viewmodel_base.global_position - (((camera.global_basis.x * bob_offset.x) + (camera.global_basis.y * bob_offset.y))*bob_interp_factor)
	else:
		bob_interp_factor -= delta
		camera.position = camera.position.lerp(camera_start_pos, delta * bob_return_strength)
		viewmodel.global_position = viewmodel.global_position.lerp(viewmodel_base.global_position, delta * bob_return_strength)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_rotate(event.relative * sensitivity)
		
	if event.is_action_pressed("move_jump") && is_on_floor():
		velocity.y = jump_strength
	if event.is_action_pressed("move_walk"):
		walking = true
	elif event.is_action_released("move_walk"):
		walking = false
	elif event.is_action_pressed("Shoot"):
		if animtree_vm.get("parameters/Transition/current_state") == "Idle":
			if ammo:
				animtree_vm.set("parameters/OS_Shoot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				animtree_vm.set("parameters/OS_ShootAdd/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				ammo -= 1
			else:
				animtree_vm.set("parameters/Transition/transition_request", "Reload")
				set_deferred("ammo", 8)
	elif event.is_action_pressed("Reload"):
		if animtree_vm.get("parameters/Transition/current_state") == "Idle":
			if ammo < 8:
				animtree_vm.set("parameters/Transition/transition_request", "Reload")
				set_deferred("ammo", 8)

func _process(delta:float) -> void:
	var dir_vec2 = viewmodel_spring.update(delta, Vector2(viewmodel_sway_dir.x, viewmodel_sway_dir.y), -Vector2(viewmodel_sway_dir.x, viewmodel_sway_dir.y)*8.0)
	viewmodel_sway_dir = Vector3(dir_vec2.x, dir_vec2.y, 0)
	viewmodel_recoil = viewmodel_recoil_spring.update(get_process_delta_time(), viewmodel_recoil*0.6, -viewmodel_recoil*5)
	vm_sway.rotation.y = (-viewmodel_sway_dir.x*14) + viewmodel_recoil.x
	vm_sway.rotation.x = (-viewmodel_sway_dir.y*14) + viewmodel_recoil.y
	vm_sway.rotation.z = (viewmodel_sway_dir.x*17) * camera.global_basis.z.y
	vm_sway.position = vm_sway.position.lerp(Vector3.ZERO.lerp(Vector3(0, -0.085, 0.05), viewmodel_pull_interp_factor), delta*3)

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
	
	viewmodel_pull_interp_factor = move_toward(viewmodel_pull_interp_factor, in_dir.length(), delta*3)
	

## Rotate the player and camera
func mouse_rotate(rot: Vector2) -> void:
	rotate_y(-rot.x)
	camera.rotate_x(-rot.y)
	if is_equal_approx(camera.rotation.x + rot.y, deg_to_rad(pitch_clamp_angle)) or is_equal_approx(camera.rotation.x + rot.y, deg_to_rad(-pitch_clamp_angle)):
		rot *= Vector2(1, 0)
	var dir_vec2 = viewmodel_spring.update(get_process_delta_time(), Vector2(viewmodel_sway_dir.x, viewmodel_sway_dir.y), rot)
	if dir_vec2 == null:
		viewmodel_spring._previousValue = Vector2.ZERO
		viewmodel_spring._currentValue = Vector2.ZERO
		viewmodel_spring.reset_spring(Vector2.ZERO)
		dir_vec2 = Vector2.ZERO
	viewmodel_sway_dir = Vector3(dir_vec2.x, dir_vec2.y, 0)
	#print(viewmodel_sway_dir)
	camera.rotation.x = clampf(
		camera.rotation.x,
		deg_to_rad(-pitch_clamp_angle),
		deg_to_rad(pitch_clamp_angle))

func recoil_viewmodel() -> void:
	print("Joe")
	var vec := Vector2(randf_range(-1.0, 0.5), randf_range(0.86, 1.75))
	viewmodel_recoil = viewmodel_recoil_spring.update(get_process_delta_time()*6, vec*0.2, vec)

## Returns a bob position based on the bob time
func view_bob(time: float) -> Vector3:
	var pos := Vector3.ZERO
	pos.y = sin(time * bob_frequency) * bob_up_amplitude
	pos.x = cos(time * (bob_frequency / 2.0)) * (bob_side_amplitude / 2.0)
	return pos
