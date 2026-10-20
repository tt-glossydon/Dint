@tool
@icon("res://addons/value_spring/icons/ValueSpring.svg")
class_name ValueSpring
extends Resource
## Used to animate a value in code using spring motion.
##
## The internal state of this resource holds the current velocity and value of
## a spring, which can be used to animate values procedurally. [br][br]
## Be sure to call [method reset_spring] before first attempting to use the spring,
## to ensure an appropriate starting value.

## Determines how quickly the system acts - essentially a "speed" setting.
@export var frequency: float = 3.0:
	set(f):
		frequency = maxf(0.001, f)
		if Engine.is_editor_hint() == false:
			_calculate_coefficients()
		changed.emit()
## Determines how much the system tries to slow the spring motion.
## Between 0 and 1, the spring motion will settle slowly.
## 1 will create a critical damping effect.
@export var damping: float = .5:
	set(d):
		damping = maxf(0.0, d)
		if Engine.is_editor_hint() == false:
			_calculate_coefficients()
		changed.emit()
## Determines how quickly and strongly the system responds to target changes.
@export var response: float = 0.:
	set(r):
		response = r
		if Engine.is_editor_hint() == false:
			_calculate_coefficients()
		changed.emit()
@export_group("Other")
## If the spring is being used to follow a rotation in 2D, will ensure
## the rotation tries to take the shortest route. Assumes the target value
## is in radians.
@export var float_is_rotation: bool = false

## Improves the look for very fast movements at the cost of some performance.
## Can cause issues on Quaternions.
@export var use_pole_matching: bool = false

var _previousValue: Variant
var _currentValue: Variant
var _velocity: Variant
var _w: float
var _d: float
var _k1: float
var _k2: float
var _k3: float
# If the target is a Color we store it internally as a Vector4 so we can
# do the spring calculation in OKHSL space instead
var _is_color: bool = false


func _init(p_initial: Variant = 0.0, p_frequency: float = 3.0, p_damping: float = 0.5, p_response: float = 1.25, p_float_is_rotation: bool = false) -> void:
	_currentValue = p_initial
	_previousValue = p_initial
	frequency = p_frequency
	damping = p_damping
	response = p_response
	float_is_rotation = p_float_is_rotation


## Resets the spring to a new starting value, and the velocity to zero.
## If not called, the starting value will be a [code]float[/code] set to [code]0.0[/code].
func reset_spring(start_value: Variant = _get_default()):
	_is_color = false

	if typeof(start_value) == TYPE_COLOR:
		var col := start_value as Color
		_currentValue = Vector4(col.ok_hsl_h, col.ok_hsl_s, col.ok_hsl_l, col.a)
		_is_color = true
	else:
		_currentValue = start_value

	_previousValue = _currentValue
	_velocity = _get_default()
	_calculate_coefficients()


## Calculate the new spring value given the set target value.
func update(delta: float, target: Variant, target_velocity: Variant = null) -> Variant:
	if (typeof(target) != typeof(_currentValue) and _is_color == false) or (_is_color and typeof(target) != TYPE_COLOR):
		push_error("The ValueSpring's target must be of the same type as it's last value! Use reset_spring() first if you really want to change the value type.")
		reset_spring(target)
		return

	# Convert to HSL
	if typeof(target) == TYPE_COLOR:
		var diff = fmod(target.ok_hsl_h - _currentValue.x, 1.0)
		var target_hue = clampf(fmod(2 * diff, 1.0) - diff, 0.0, 1.0)
		target = Vector4(target_hue, target.ok_hsl_s, target.ok_hsl_l, target.a)

	# Ensure we use the closest rotation
	if typeof(target) == TYPE_QUATERNION:
		target = _normalize_quat_target(target)

	if typeof(target) == TYPE_FLOAT and float_is_rotation:
		target = _currentValue + angle_difference(_currentValue, target)

	if target_velocity == null:
		target_velocity = (target - _previousValue) / delta
		_previousValue = target

	var k2 := _k2
	var k1 := _k1

	# Pole matching
	if use_pole_matching and _w * delta >= damping:
		var t1 = exp(-damping * _w * delta)
		var alpha = 2 * t1
		if damping <= 1:
			alpha *= cos(delta * _d)
		else:
			alpha *= cosh(delta * _d)
		var beta = t1 * t1
		var t2 = delta / (1.0 + beta - alpha)
		k1 = (1.0 - beta) * t2
		k2 = delta * t2

	_currentValue += delta * _velocity
	_velocity = (k2 * _velocity + delta * (target + _k3 * target_velocity - _currentValue)) / (k2 + delta * k1)

	if typeof(_currentValue) == TYPE_QUATERNION:
		return _currentValue.normalized()

	if _is_color:
		_currentValue.x = clampf(_currentValue.x, 0.0, 1.0)
		_currentValue.y = clampf(_currentValue.y, 0.0, 1.0)
		_currentValue.z = clampf(_currentValue.z, 0.0, 1.0)
		_currentValue.w = clampf(_currentValue.w, 0.0, 1.0)
		return Color.from_ok_hsl(_currentValue.x, _currentValue.y, _currentValue.z, _currentValue.w)

	return _currentValue


## Returns default starting values for valid spring types.
func _get_default() -> Variant:
	match typeof(_currentValue):
		TYPE_FLOAT:
			return 0.0
		TYPE_INT:
			return 0
		TYPE_VECTOR2:
			return Vector2.ZERO
		TYPE_VECTOR2I:
			return Vector2i.ZERO
		TYPE_VECTOR3:
			return Vector3.ZERO
		TYPE_VECTOR3I:
			return Vector3i.ZERO
		TYPE_VECTOR4:
			return Vector4.ZERO
		TYPE_VECTOR4I:
			return Vector4i.ZERO
		TYPE_QUATERNION:
			return Quaternion.IDENTITY
	return null


func _calculate_coefficients() -> void:
	_w = TAU * frequency
	_d = _w * sqrt(absf(damping * damping - 1))
	_k1 = damping / (PI * frequency)
	_k2 = 1.0 / (_w * _w)
	_k3 = response * damping / _w


func _normalize_quat_target(target: Quaternion) -> Quaternion:
	if _currentValue.dot(target) >= 0:
		return target

	target.x *= -1
	target.y *= -1
	target.z *= -1
	target.w *= -1
	return target
