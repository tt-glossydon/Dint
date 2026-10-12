extends Node3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@export var sensitivity: float = 0.001


@onready var body = $DintBody3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	body.move(input)
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		body.mouse_rotate(event.relative * sensitivity)
		
