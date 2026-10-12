extends CharacterBody3D

@onready var camera = $Camera3D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

func move(in_dir: Vector2) -> void:
	var direction := (transform.basis * Vector3(in_dir.x, 0, in_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x
		velocity.z = direction.z
	else:
		velocity.x = move_toward(velocity.x, 0, 1)
		velocity.z = move_toward(velocity.z, 0, 1)
	
func mouse_rotate(rot: Vector2) -> void:
	rotate_y(-rot.x)
	camera.rotate_x(-rot.y)
