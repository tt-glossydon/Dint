extends Node3D
class_name InteractivePrompt3D
## A class for making various things interactive.

signal interacted_with(body:CharacterBody3D)

## The text prompt to present when this instance is close enough to the player for interaction.
@export var prompt : String = "Interact"
## The distance between this and the player, in meters, at which this interaction prompt is available.
@export_range(1.0, 5.0, 0.1) var distance : float = 3.0
## The amount of time, in seconds, before interaction is available between interactions.
@export_range(0.333, 10.0) var interaction_cooldown_period : float = 0.333
## The amount of time, in seconds, before interaction is available. Zero is available.
@onready var interaction_cooldown_remaining : float = 0.0:
	set(to_what):
		interaction_cooldown_remaining = maxf(to_what, 0.0)

func _ready():
	add_to_group(&"Interactive")
	set_process(false)

func _process(_delta:float) -> void:
	interaction_cooldown_remaining -= _delta
	if !interaction_cooldown_remaining:
		set_process(false)

## Method to be invoked for interaction to happen. Body is implicitly supposed to be a player.
@rpc("any_peer", "call_local", "reliable")
func interact_with(body:CharacterBody3D):
	if interaction_cooldown_remaining:
		return
	if !is_multiplayer_authority():
		return
	interaction_cooldown_remaining = interaction_cooldown_period
	set_process(true)
	if body.global_position.distance_to(global_position) > distance:
		return
	interacted_with.emit(body)
	print("Interacted with! Timer set to: [" + str(interaction_cooldown_period) + "] seconds.")
