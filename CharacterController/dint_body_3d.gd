extends CharacterBody3D
class_name SurvivorBody3D

signal toggle_light(to_what:bool)

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
## The speed the survivor is moving at, zero being idle and one being their maximum speed.
@export var current_speed_anim_factor : float = 0.0:
	set(to_what):
		current_speed_anim_factor = clampf(to_what, 0.0, 1.0)

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

@export_group("Viewmodel")

@export var viewmodel_spring : ValueSpring
@onready var viewmodel_sway_dir : Vector3 = Vector3.ZERO:
	set(to_what):
		viewmodel_sway_dir = Vector3(clampf(to_what.x, -2, 2), clampf(to_what.y, -2, 2), to_what.z)
@onready var viewmodel_pull_interp_factor : float = 0.0:
	set(to_what):
		viewmodel_pull_interp_factor = clampf(to_what, 0.0, 1.0)

@export var viewmodel_recoil_spring : ValueSpring
@onready var viewmodel_recoil : Vector2 = Vector2.ZERO

@export var viewmodel_jump_spring : ValueSpring
@onready var viewmodel_jump_displacement : float = 0.0

@export var cam_land_spring : ValueSpring
@onready var cam_land_displacement : float = 0.0
@onready var cam_land_jeopardy_timer : float = 0.0:
	set(to_what):
		cam_land_jeopardy_timer = maxf(to_what, 0.0)

@export_group("Light")
## Whether the flashlight is on or not.
@export var light_on : bool = true:
	set(to_what):
		if to_what != light_on:
			light_on = to_what
			for light in lights_to_toggle:
				light.visible = to_what
## The lights to toggle on or off.
@export var lights_to_toggle : Array[Light3D]

@export var ammo : int = 8

func _enter_tree() -> void:
	print(int(str(name)))
	$MultiplayerSynchronizer.set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	viewmodel_spring._previousValue = Vector2.ZERO
	viewmodel_spring._currentValue = Vector2.ZERO
	viewmodel_spring.reset_spring(Vector2.ZERO)
	viewmodel_recoil_spring.reset_spring(Vector2.ZERO)
	viewmodel_jump_spring.reset_spring(0.0)
	cam_land_spring.reset_spring(0.0)
	
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
	
	var prev_velocity := velocity
	var was_aerial := !is_on_floor()
	
	# Fall
	if not is_on_floor():
		velocity += (get_gravity()*4.0) * delta
		was_aerial = true
	
	mouse_rotate(
		Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), 
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)) * sensitivity * 40.0)
	
	move_and_slide()
	
	# View bob
	bob_offset = view_bob(bob_amount)
	#print(cam_land_displacement)
	if is_on_floor() and was_aerial:
		var clamped_velo_displacement := clampf(inverse_lerp(0.0, -60, prev_velocity.y), 0.0, 1.0)
		viewmodel_jump_displacement = viewmodel_jump_spring.update(delta, lerpf(-0.1, -2.0, clamped_velo_displacement), lerpf(1.0, 2.0, clamped_velo_displacement))
		#cam_land_spring.reset_spring(0.0)
		if !cam_land_jeopardy_timer:
			cam_land_spring.update(delta, lerpf(0.005, 3.0, clamped_velo_displacement), lerpf(0.5, 3.0, clamped_velo_displacement))
			cam_land_jeopardy_timer = 0.05
	if is_on_floor() && (velocity*Vector3(1, 0, 1)).length() > 0.1:
		# Multiplying by a flat Vector3 ignores vertical speed
		bob_interp_factor += (delta*0.75) * (velocity*Vector3(1, 0, 1)).length() * float(is_on_floor())
		bob_amount += delta * (velocity*Vector3(1, 0, 1)).length() * float(is_on_floor())
		camera.position = (camera_start_pos+Vector3(0, cam_land_displacement, 0)) + ((bob_offset*5)*bob_interp_factor)*current_speed_anim_factor
		viewmodel.global_position = viewmodel_base.global_position - (((camera.global_basis.x * bob_offset.x) + (camera.global_basis.y * bob_offset.y))*bob_interp_factor)
	else:
		bob_interp_factor -= delta
		camera.position = camera.position.lerp((camera_start_pos+Vector3(0, cam_land_displacement, 0)), delta * bob_return_strength) - Vector3(0, cam_land_displacement, 0)
		viewmodel.global_position = viewmodel.global_position.lerp(viewmodel_base.global_position, delta * bob_return_strength)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_rotate(event.relative * sensitivity)
		
	if event.is_action_pressed("move_jump") && is_on_floor():
		velocity.y = jump_strength
		viewmodel_jump_displacement = viewmodel_jump_spring.update(get_process_delta_time(), -0.64, -2.0)
	if event.is_action_pressed("move_walk"):
		walking = true
	elif event.is_action_released("move_walk"):
		walking = false
	elif event.is_action_pressed("Shoot"):
		weapon_fire.rpc()
	elif event.is_action_pressed("Reload"):
		weapon_reload.rpc()
	elif event.is_action_pressed("toggle_light"):
		toggle_light.emit(!light_on)
		get_window().set_input_as_handled()
		pass

func _process(delta:float) -> void:
	cam_land_jeopardy_timer -= delta
	await RenderingServer.frame_pre_draw
	var dir_vec2 = viewmodel_spring.update(delta, Vector2(viewmodel_sway_dir.x, viewmodel_sway_dir.y), -Vector2(viewmodel_sway_dir.x, viewmodel_sway_dir.y)*8.0)
	viewmodel_sway_dir = Vector3(dir_vec2.x, dir_vec2.y, 0)
	viewmodel_recoil = viewmodel_recoil_spring.update(delta, viewmodel_recoil*0.6, -viewmodel_recoil*5)
	viewmodel_jump_displacement = viewmodel_jump_spring.update(delta, 0.0, 1.0)
	cam_land_displacement = cam_land_spring.update(delta, 0.0, 0.005)
	vm_sway.rotation.y = (-viewmodel_sway_dir.x*14) + viewmodel_recoil.x
	vm_sway.rotation.x = (-viewmodel_sway_dir.y*14) + viewmodel_recoil.y + viewmodel_jump_displacement
	vm_sway.rotation.z = (viewmodel_sway_dir.x*17) * camera.global_basis.z.y
	vm_sway.position = vm_sway.position.lerp(Vector3.ZERO.lerp(Vector3(0, -0.085, 0.05), viewmodel_pull_interp_factor), delta*3) + Vector3(0, -camera.rotation.x*0.001, 0)

## Move the player in a 2d direction vector and a given delta time
func move(in_dir: Vector2, delta: float) -> void:
	# Running or walking
	var max_speed := max_walk_input_speed if walking else max_input_speed
	var acceleration := run_acceleration if walking else walk_acceleration
	acceleration = acceleration if is_on_floor() else acceleration / air_acceleration_div
	
	# The movement direction and speed
	var direction := (transform.basis * Vector3(in_dir.x, 0, in_dir.y))
	var target := direction * max_speed
	var rate := (acceleration + (cam_land_displacement*50.0*int(!walking))) if !direction.is_zero_approx() else deceleration
	rate = rate if is_on_floor() or !direction.is_zero_approx() else rate / air_acceleration_div
	if walking and !is_on_floor() and !direction.is_zero_approx():
		rate /= 2.0
	
	var vec_movement_speed_factor := (get_position_delta() - get_platform_velocity()) / delta
	var len_movement_speed_factor := vec_movement_speed_factor.length()
	var len_movement_speed_factor_clamped := clampf(inverse_lerp(0.0, max_input_speed, len_movement_speed_factor), 0.0, 1.0)
	current_speed_anim_factor = len_movement_speed_factor_clamped
	
	# The new velocity
	var tmp_velocity := Vector3(velocity.x, 0, velocity.z)
	tmp_velocity = tmp_velocity.move_toward(target, rate * delta)
	tmp_velocity = tmp_velocity.limit_length(max_input_speed)
	
	velocity.x = tmp_velocity.x
	velocity.z = tmp_velocity.z
	
	viewmodel_pull_interp_factor = move_toward(viewmodel_pull_interp_factor, in_dir.length()*len_movement_speed_factor_clamped, delta*3)
	

## Rotate the player and camera
func mouse_rotate(rot: Vector2) -> void:
	rotate_y(-rot.x)
	camera.rotate_x(-rot.y)
	if is_equal_approx(camera.rotation.x + rot.y, deg_to_rad(pitch_clamp_angle)) or is_equal_approx(camera.rotation.x + rot.y, deg_to_rad(-pitch_clamp_angle)):
		rot *= Vector2(1, 0)
	# Variant, cannot be strictly typed. A limitation of ValueSpring's flexibility.
	var dir_vec2 = viewmodel_spring.update(get_process_delta_time(), Vector2(viewmodel_sway_dir.x, viewmodel_sway_dir.y), rot)
	if dir_vec2 == null:
		viewmodel_spring._previousValue = Vector2.ZERO
		viewmodel_spring._currentValue = Vector2.ZERO
		viewmodel_spring.reset_spring(Vector2.ZERO)
		dir_vec2 = Vector2.ZERO
	viewmodel_sway_dir = Vector3(dir_vec2.x, dir_vec2.y, 0)
	camera.rotation.x = clampf(
		camera.rotation.x,
		deg_to_rad(-pitch_clamp_angle),
		deg_to_rad(pitch_clamp_angle))

func recoil_viewmodel() -> void:
	var vec := Vector2(randf_range(-0.5, 0.3), randf_range(0.86, 1.75))
	viewmodel_recoil = viewmodel_recoil_spring.update(get_process_delta_time()*6, vec*0.2, vec)

## Returns a bob position based on the bob time
func view_bob(time: float) -> Vector3:
	var pos := Vector3.ZERO
	pos.y = sin(time * bob_frequency) * bob_up_amplitude
	pos.x = cos(time * (bob_frequency / 2.0)) * (bob_side_amplitude / 2.0)
	return pos

func _on_toggle_light(to_what:bool) -> void:
	light_on = to_what

@rpc("any_peer", "call_local", "reliable")
func weapon_fire() -> void:
	if multiplayer.is_server():
		multicast_weapon_fire()

@rpc("authority", "call_local", "reliable")
func multicast_weapon_fire() -> void:
	if animtree_vm.get("parameters/Transition/current_state") == "Idle":
		if ammo:
			ammo -= 1
			if is_multiplayer_authority():
				animtree_vm.set("parameters/OS_Shoot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				animtree_vm.set("parameters/OS_ShootAdd/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				get_window().set_input_as_handled()
		else:
			weapon_reload.rpc()

@rpc("any_peer", "call_local", "reliable")
func weapon_reload() -> void:
	if multiplayer.is_server():
		multicast_weapon_reload()

@rpc("authority", "call_local", "reliable")
func multicast_weapon_reload() -> void:
	if animtree_vm.get("parameters/Transition/current_state") == "Idle":
		if ammo < 8:
			ammo = 8
			if is_multiplayer_authority():
				animtree_vm.set("parameters/Transition/transition_request", "Reload")
				get_window().set_input_as_handled()
		
