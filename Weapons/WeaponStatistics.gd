extends Resource
class_name WeaponStats

enum Action {
	SEMI_AUTO,
	AUTO,
	MANUAL
}

@export var weapon_name : String = ""

@export var sway_multiplier : Vector2 = Vector2.ONE

@export_group("Recoil")
## Recoil in two axes (horizontal and vertical).[br]
## Sorted as (min h, max h, min v, max v).
@export var recoil_viewmodel : Vector4


@export_group("Ammo")

var ammo: int = 8

@export_range(1, 999) var ammo_reserve : int = 64
## Magazine capacity for the weapon.
@export_range(1, 250) var mag_cap : int = 8
## Whether the weapon can have a full magazine and one round in the chamber.
@export var can_top_off : bool = true
## How many rounds will be fired per-shot. Hard-limited to ranges [1, 16].
@export_range(1, 16, 1.0) var rounds_per_shot : int = 1
## How fast the bullet(s) will travel, in meters per-second.
@export_range(60, 2000, 5, "prefer_slider") var bullet_velocity : float = 250

@export_group("Damage")
## Affects how damage from each bullet is calculated at-range.[br][br]
## Domain is distance, value is damage.
@export var damage_curve : Curve
## The total number of bodies that can be struck with a bullet.[br][br]
## Hard-limited to ranges [1, 5].
@export_range(1, 5, 1.0) var max_hits : int = 2
## Affects how the damage multiplier for each bullet which strikes the torso is calculated at-range.[br][br]
## Domain is distance, value is multiplier.
@export var torso_multiplier_curve : Curve
## Affects how the damage multiplier for each bullet which strikes the head is calculated at-range.[br][br]
## Domain is distance, value is multiplier.
@export var head_multiplier_curve : Curve

@export_group("Operation")
## Rounds per-minute.[br][br]
## Affects when the action of the weapon can be re-engaged.
@export var rpm : float = 500.
## Whether this weapon has an attached optic or not.
@export var has_scope : bool = false
## The action of the weapon.
@export var action : Action
## How much time it takes to reload the weapon when the magazine is not empty, in seconds.
@export var reload_time_tactical : float = 1.5
## How much time it takes to reload the weapon when the magazine is empty, in seconds.
@export var reload_time_empty : float = 2.0
## How much time it takes to reload the weapon when the magazine is not empty, in seconds.[br][br]
## The weapon is held as forward as possible during the reload to preserve visibility.
@export var reload_time_forward_tactical : float = 2.5
## How much time it takes to reload the weapon when the magazine is empty, in seconds.[br][br]
## The weapon is held as forward as possible during the reload to preserve visibility.
@export var reload_time_forward_empty : float = 3.0

@export_group("")
