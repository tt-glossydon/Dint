@tool
extends Control

var _sim_points: PackedFloat32Array

var spring: ValueSpring

const DELTA: float = 1 / 90.0
const SIMTIME: float = 3.0
const PTCOUNT: float = SIMTIME / DELTA


func update(target: ValueSpring):
	if spring == null:
		spring = ValueSpring.new()

	if target == null:
		_sim_points.clear()
		queue_redraw()
		return

	spring.frequency = target.frequency
	spring.damping = target.damping
	spring.response = target.response
	spring._calculate_coefficients()
	spring.reset_spring(2.0)

	_sim_points.clear()

	var sim_time: float = 0
	while sim_time <= SIMTIME:
		_sim_points.append(spring.update(DELTA, 0.0))
		sim_time += DELTA

	queue_redraw()


func _draw() -> void:
	var center = size.y / 2
	var max = size.y / 2 - size.y / 8

	var line_col = get_theme_color("accent_color", "Editor")

	if !has_theme_stylebox_override("panel"):
		self.add_theme_stylebox_override("panel", get_theme_stylebox("TextureRegionPreviewBG", "EditorStyles"))

	for i in range(_sim_points.size() - 1):
		var pos: Vector2
		pos.x = i / PTCOUNT * size.x
		pos.y = _sim_points[i] * 0.5 * max + center

		var pos_next: Vector2
		pos_next.x = (i + 1) / PTCOUNT * size.x
		pos_next.y = _sim_points[i + 1] * 0.5 * max + center

		pos.y = clampf(pos.y, 0, size.y)
		pos_next.y = clampf(pos_next.y, 0, size.y)

		draw_line(pos, pos_next, line_col, 2.0, true)
