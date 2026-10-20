@icon("res://addons/value_spring/icons/SpringFollower3D.svg")
class_name SpringFollower3D
extends Node3D

@export var target: Node3D
@export var position_spring: ValueSpring
@export var rotation_spring: ValueSpring


func _ready() -> void:
	reset()


func _process(delta: float) -> void:
	global_position = position_spring.update(delta, target.global_position)
	var new_rot: Quaternion = rotation_spring.update(delta, target.global_basis.get_rotation_quaternion())
	global_basis = Basis(new_rot)


func reset() -> void:
	position_spring.reset_spring(target.global_position)
	rotation_spring.reset_spring(target.global_basis.get_rotation_quaternion())
