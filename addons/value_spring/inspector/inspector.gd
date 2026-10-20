extends EditorInspectorPlugin

var PreviewScene = preload("res://addons/value_spring/inspector/curve_preview.tscn")


func _can_handle(object: Object) -> bool:
	return object is ValueSpring


func _parse_begin(object: Object) -> void:
	var preview = PreviewScene.instantiate()
	preview.setup(object)
	add_custom_control(preview)
