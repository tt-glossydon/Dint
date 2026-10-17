extends Control

@export var player_camera: Camera3D

@onready var ui_camera = $SubViewportContainer/SubViewport/Camera3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float)  -> void:
	ui_camera.global_transform = player_camera.global_transform
	ui_camera.fov = player_camera.fov
	ui_camera.near = player_camera.near
	ui_camera.far = player_camera.far
	
