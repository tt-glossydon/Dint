@tool
extends Control

var _target: ValueSpring


func setup(target: ValueSpring):
	if _target != null:
		_target.disconnect("changed", _changed)
	_target = target
	if _target != null:
		_target.connect("changed", _changed)
		_changed()


func _changed():
	$MarginContainer/CurvePreview.update(_target)
