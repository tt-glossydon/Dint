@icon("res://addons/value_spring/icons/SpringFollower2D.svg")
class_name SpringFollower2D
extends Node2D

@export var target: Node2D
@export var position_spring: ValueSpring
@export var rotation_spring: ValueSpring


func _ready() -> void:
	# Make sure we rotate in the closest direction
	rotation_spring.float_is_rotation = true
	reset()


func _process(delta: float) -> void:
	global_position = position_spring.update(delta, target.global_position)
	global_rotation = rotation_spring.update(delta, target.global_rotation)


func reset() -> void:
	position_spring.reset_spring(target.global_position)
	rotation_spring.reset_spring(target.global_rotation)
